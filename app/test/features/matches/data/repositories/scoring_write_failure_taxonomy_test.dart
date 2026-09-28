// The distinction the scoring write path turns on: did the server never hear
// us, or did it hear us and say no?
//
// These looked the same for as long as the matches data source translated
// every failure into `ServerException`. The consequences were not the same:
// `startInnings` reported a rule violation to the scorer as SUCCESS, and both
// write paths left the rejected op queued, where the drain loop hit it,
// `break`ed, and stalled every delivery behind it for the rest of the match —
// with `pendingOpsCount` stuck above zero, which disables undo.
//
// Real SQLite rather than a mocked local data source: the claim under test is
// about what survives in the write-ahead log, and a durability claim asserted
// against a mock is not asserted at all.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/matches/data/datasources/format_presets_remote_datasource.dart';
import 'package:matchday/features/matches/data/datasources/match_requests_remote_datasource.dart';
import 'package:matchday/features/matches/data/datasources/matches_local_datasource.dart';
import 'package:matchday/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:matchday/features/matches/data/repositories/matches_repository_impl.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements MatchesRemoteDataSource {}

class _MockRequests extends Mock implements MatchRequestsRemoteDataSource {}

class _MockPresets extends Mock implements FormatPresetsRemoteDataSource {}

/// The drain loop discards the success value, so a stand-in is enough here —
/// building a full BallDto would assert nothing extra.
class _StubBallResult extends Mock implements RecordBallResult {}

const _match = 'm1';

void main() {
  late _MockRemote remote;
  late AppDatabase db;
  late MatchesLocalDataSource local;
  late MatchesRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = MatchesLocalDataSourceImpl(db);
    repo = MatchesRepositoryImpl(remote, _MockRequests(), _MockPresets(), local);
  });
  tearDown(() => db.close());

  Future<Either<Failure, Unit>> startInningsResult() => repo.startInnings(
        matchId: const MatchId(_match),
        inningsNumber: 1,
        strikerId: 'mp1',
        nonStrikerId: 'mp2',
        bowlerId: 'mp3',
      );

  BallDraft draft() => const BallDraft(
        matchId: MatchId(_match),
        inningsNumber: 1,
        isLegalDelivery: true,
        ballKind: BallKind.legal,
        runsScored: 1,
        batsmanId: 'mp1',
        nonStrikerId: 'mp2',
        bowlerId: 'mp3',
        opId: 'op-1',
        computed: ComputedDelivery(
          overNumber: 0,
          ballInOver: 1,
          isFreeHit: false,
          inningsEnded: false,
          isAllOut: false,
          ballsPerOver: 6,
          strikerAfter: 'mp1',
          nonStrikerAfter: 'mp2',
          bowlerAfter: 'mp3',
        ),
      );

  group('startInnings', () {
    test('a dropped connection keeps the op queued and reads as success',
        () async {
      when(() => remote.startInnings(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
            strikerId: any(named: 'strikerId'),
            nonStrikerId: any(named: 'nonStrikerId'),
            bowlerId: any(named: 'bowlerId'),
            target: any(named: 'target'),
          )).thenThrow(NetworkException('no route to host'));

      final result = await startInningsResult();

      expect(result.isRight(), isTrue,
          reason: 'the WAL holds it; the scorer carries on');
      final pending = await local.pendingOps(matchId: _match, inningsNumber: 1);
      expect(pending, hasLength(1));
      expect(pending.single.attempts, 1);
    });

    test('a server refusal is surfaced, NOT reported as success', () async {
      when(() => remote.startInnings(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
            strikerId: any(named: 'strikerId'),
            nonStrikerId: any(named: 'nonStrikerId'),
            bowlerId: any(named: 'bowlerId'),
            target: any(named: 'target'),
          )).thenThrow(ServerException('That innings has already started.'));

      final result = await startInningsResult();

      // The regression this file exists for: this used to return Right(unit).
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('a refused op leaves the queue but stays readable', () async {
      when(() => remote.startInnings(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
            strikerId: any(named: 'strikerId'),
            nonStrikerId: any(named: 'nonStrikerId'),
            bowlerId: any(named: 'bowlerId'),
            target: any(named: 'target'),
          )).thenThrow(ServerException('rule violation'));

      await startInningsResult();

      expect(await local.pendingOps(matchId: _match, inningsNumber: 1), isEmpty,
          reason: 'retrying a no produces another no');
      expect(await local.pendingOpsCount(matchId: _match, inningsNumber: 1), 0,
          reason: 'a stuck count is what disables undo');
      final refused = await local.refusedOps(matchId: _match, inningsNumber: 1);
      expect(refused, hasLength(1), reason: 'design doc §19.3: never discard');
      expect(refused.single.lastError, 'rule violation');
    });
  });

  group('recordBall', () {
    test('a dropped connection keeps the delivery queued for retry', () async {
      when(() => remote.recordBall(any()))
          .thenThrow(NetworkException('offline'));

      final result = await repo.recordBall(draft());

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      final pending = await local.pendingOps(matchId: _match, inningsNumber: 1);
      expect(pending, hasLength(1),
          reason: 'the whole point of the write-ahead log');
    });

    test('a refused delivery does not stay queued forever', () async {
      when(() => remote.recordBall(any()))
          .thenThrow(ServerException('innings is closed'));

      final result = await repo.recordBall(draft());

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(await local.pendingOps(matchId: _match, inningsNumber: 1), isEmpty);
      expect(
        await local.refusedOps(matchId: _match, inningsNumber: 1),
        hasLength(1),
      );
    });
  });

  group('the drain loop', () {
    test('one refused delivery does not stall the ones behind it', () async {
      // Three deliveries queued offline; the middle one is refused on sync.
      for (var i = 1; i <= 3; i++) {
        await local.appendOp(
          opId: 'op-$i',
          matchId: _match,
          inningsNumber: 1,
          kind: 'ball',
          payload: {'p_idempotency_key': 'op-$i', 'runs': i},
        );
      }
      when(() => remote.recordBall(any())).thenAnswer((inv) async {
        final params = inv.positionalArguments.first as Map<String, dynamic>;
        if (params['p_idempotency_key'] == 'op-2') {
          throw ServerException('that delivery breaks a rule');
        }
        return _StubBallResult();
      });

      // op-1 and op-3 must both be ATTEMPTED. Before the fix the loop broke on
      // op-2 and op-3 was never tried.
      await repo.syncPendingOps(matchId: _match, inningsNumber: 1);

      verify(() => remote.recordBall(any())).called(3);
      final refused = await local.refusedOps(matchId: _match, inningsNumber: 1);
      expect(refused.map((o) => o.opId), ['op-2']);
      expect(await local.pendingOps(matchId: _match, inningsNumber: 1), isEmpty,
          reason: 'op-1 and op-3 synced; op-2 is terminal');
    });
  });
}
