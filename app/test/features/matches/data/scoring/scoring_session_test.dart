// The scoring write path, end to end on the device.
//
// The distinction everything here turns on: did the server never hear us, or
// did it hear us and say no? Those looked the same for as long as the data
// source translated every failure into `ServerException`, and the consequences
// were not the same — a rejected op left queued stalled every delivery behind
// it for the rest of the match, holding the unsaved count above zero, which
// disables undo.
//
// Real SQLite rather than a mocked local data source: the claims here are
// about what survives in the write-ahead log, and a durability claim asserted
// against a mock is not asserted at all.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/matches/data/datasources/matches_local_datasource.dart';
import 'package:matchday/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:matchday/features/matches/data/models/ball_draft_payload.dart';
import 'package:matchday/features/matches/data/models/ball_dto.dart';
import 'package:matchday/features/matches/data/scoring/scoring_session.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_room_snapshot.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../scoring_fixtures.dart';

class _MockRepo extends Mock implements MatchesRepository {}

class _MockRemote extends Mock implements MatchesRemoteDataSource {}

RecordBallResult _accepted({
  String id = 'server-1',
  int seq = 1,
  int runs = 1,
}) => RecordBallResult(
  ball: BallDto(
    ballId: id,
    matchId: kMatchId,
    inningsNumber: 1,
    seq: seq,
    overNumber: 0,
    ballInOver: seq,
    runsScored: runs,
    batsmanId: 'mp1',
    nonStrikerId: 'mp2',
    bowlerId: 'mp9',
  ),
  innings: null,
);

void main() {
  late _MockRepo repo;
  late _MockRemote remote;
  late AppDatabase db;
  late MatchesLocalDataSource local;

  setUpAll(() {
    registerFallbackValue(const MatchId(kMatchId));
  });

  setUp(() {
    repo = _MockRepo();
    remote = _MockRemote();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = MatchesLocalDataSourceImpl(db);
  });
  tearDown(() => db.close());

  void stubReads({
    MatchInningsState? state,
    List<Ball> balls = const [],
    bool canScore = true,
  }) {
    when(() => repo.getMatch(any())).thenAnswer((_) async => Right(match()));
    when(
      () => repo.getMatchInningsState(
        matchId: any(named: 'matchId'),
        inningsNumber: any(named: 'inningsNumber'),
      ),
    ).thenAnswer((_) async => Right(state ?? innings()));
    when(
      () => repo.listBalls(any(), any()),
    ).thenAnswer((_) async => Right(balls));
    when(
      () => repo.listMatchPlayers(any()),
    ).thenAnswer((_) async => Right(lineup()));
    when(
      () => repo.canScoreInnings(
        matchId: any(named: 'matchId'),
        inningsNumber: any(named: 'inningsNumber'),
      ),
    ).thenAnswer((_) async => Right(canScore));
  }

  Future<ScoringSession> open() async {
    final session = ScoringSession(
      repository: repo,
      remote: remote,
      local: local,
      matchId: kMatchId,
      inningsNumber: 1,
      retryDelay: const Duration(days: 1),
    );
    addTearDown(session.dispose);
    await session.load();
    return session;
  }

  Future<List<LocalScoringOp>> pending() =>
      local.pendingOps(matchId: kMatchId, inningsNumber: 1);
  Future<List<LocalScoringOp>> refused() =>
      local.refusedOps(matchId: kMatchId, inningsNumber: 1);

  group('recording a delivery', () {
    test('is on screen and durable before the server has answered', () async {
      stubReads();
      final blocked = Completer<RecordBallResult>();
      when(() => remote.recordBall(any())).thenAnswer((_) => blocked.future);

      final session = await open();
      final result = await session.record(draft(runs: 4));

      expect(result.isRight(), isTrue);
      expect(session.current!.balls, hasLength(1));
      expect(session.current!.innings!.totalRuns, 4);
      expect(session.current!.pendingCount, 1);
      expect(await pending(), hasLength(1));

      blocked.complete(_accepted());
    });

    test('bye runs on the batter are rejected', () async {
      stubReads();
      final session = await open();

      final result = await session.record(
        const BallDraft(
          matchId: MatchId(kMatchId),
          inningsNumber: 1,
          isLegalDelivery: true,
          ballKind: BallKind.bye,
          runsScored: 2,
          batsmanId: 'mp1',
          bowlerId: 'mp9',
        ),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await pending(), isEmpty);
      verifyNever(() => remote.recordBall(any()));
    });

    test('an illegal delivery is refused before it is queued', () async {
      stubReads();
      final session = await open();

      // A wicket with no wicket type — the engine's own rejection case.
      final result = await session.record(
        const BallDraft(
          matchId: MatchId(kMatchId),
          inningsNumber: 1,
          isLegalDelivery: true,
          ballKind: BallKind.legal,
          isWicket: true,
          batsmanId: 'mp1',
          bowlerId: 'mp9',
        ),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await pending(), isEmpty);
      verifyNever(() => remote.recordBall(any()));
    });

    test('a device that may not score this innings is refused', () async {
      stubReads(canScore: false);
      final session = await open();

      final result = await session.record(draft());

      expect(result.getLeft().toNullable(), isA<AuthFailure>());
      expect(await pending(), isEmpty);
    });

    test('the idempotency key and the engine answer reach the wire', () async {
      stubReads(state: innings(legalBallCount: 2));
      when(() => remote.recordBall(any())).thenAnswer((_) async => _accepted());

      final session = await open();
      await session.record(draft(runs: 1));
      await session.drain();

      final params =
          verify(() => remote.recordBall(captureAny())).captured.single
              as Map<String, dynamic>;

      expect(params['idempotency_key'], isNotEmpty);
      expect(params['p_idempotency_key'], params['idempotency_key']);
      expect(params['over_number'], 0);
      expect(params['ball_in_over'], 3);
      expect(
        params['striker_after'],
        'mp2',
        reason: 'a single rotates the strike',
      );
      expect(params['runs_scored'], 1);
    });
  });

  group('did the server hear us', () {
    test('a dropped connection keeps the delivery queued for retry', () async {
      stubReads();
      when(
        () => remote.recordBall(any()),
      ).thenThrow(NetworkException('offline'));

      final session = await open();
      final result = await session.record(draft());
      await session.drain();

      expect(
        result.isRight(),
        isTrue,
        reason: 'the log holds it; the scorer carries on',
      );
      expect(
        await pending(),
        hasLength(1),
        reason: 'the whole point of the write-ahead log',
      );
      expect((await pending()).single.attempts, 1);
      expect(session.current!.pendingCount, 1);
    });

    test('a refused delivery leaves the queue but stays readable', () async {
      stubReads();
      when(
        () => remote.recordBall(any()),
      ).thenThrow(ServerException('innings is closed'));

      final session = await open();
      await session.record(draft());
      await session.drain();

      expect(
        await pending(),
        isEmpty,
        reason: 'retrying a no produces another no',
      );
      expect(
        await refused(),
        hasLength(1),
        reason: 'design doc §19.3: never discard',
      );
      expect((await refused()).single.lastError, 'innings is closed');
      expect(
        session.current!.pendingCount,
        0,
        reason: 'a stuck count is what disables undo',
      );
    });

    test(
      'a refusal re-reads the server rather than keeping the guess',
      () async {
        stubReads();
        when(
          () => remote.recordBall(any()),
        ).thenThrow(ServerException('innings is closed'));

        final session = await open();
        await session.record(draft());
        await session.drain();

        // Once on load, once after the refusal.
        verify(() => repo.listBalls(any(), any())).called(2);
      },
    );

    test('one refused delivery does not stall the ones behind it', () async {
      stubReads();
      for (var i = 1; i <= 3; i++) {
        await local.appendOp(
          opId: 'op-$i',
          matchId: kMatchId,
          inningsNumber: 1,
          kind: 'ball',
          payload: ballDraftToWal(draft(runs: i)),
        );
      }
      when(() => remote.recordBall(any())).thenAnswer((inv) async {
        final params = inv.positionalArguments.first as Map<String, dynamic>;
        if (params['idempotency_key'] == 'op-2') {
          throw ServerException('that delivery breaks a rule');
        }
        return _accepted(id: 'server-${params['idempotency_key']}');
      });

      final session = await open();
      await session.drain();

      // op-1 and op-3 must both be ATTEMPTED. The bug this pins broke the loop
      // on op-2 and op-3 was never tried.
      verify(() => remote.recordBall(any())).called(3);
      expect((await refused()).map((o) => o.opId), ['op-2']);
      expect(
        await pending(),
        isEmpty,
        reason: 'op-1 and op-3 synced; op-2 is terminal',
      );
    });
  });

  group('restoring the queue', () {
    test('deliveries queued through an outage survive a restart', () async {
      stubReads();
      await local.appendOp(
        opId: 'op-1',
        matchId: kMatchId,
        inningsNumber: 1,
        kind: 'ball',
        payload: ballDraftToWal(draft(runs: 6)),
      );
      when(
        () => remote.recordBall(any()),
      ).thenThrow(NetworkException('still offline'));

      final session = await open();

      expect(session.current!.balls, hasLength(1));
      expect(session.current!.innings!.totalRuns, 6);
      expect(session.current!.pendingCount, 1);
    });

    test('a payload written by an older build is still sent', () async {
      // Pre-v2 rows stored the raw record-ball body rather than the draft.
      // They are deliveries somebody actually bowled; dropping them to
      // simplify the reader would lose real runs.
      stubReads();
      await local.appendOp(
        opId: 'legacy-1',
        matchId: kMatchId,
        inningsNumber: 1,
        kind: 'ball',
        payload: {
          'p_match_id': kMatchId,
          'p_innings_number': 1,
          'p_idempotency_key': 'legacy-1',
          'p_is_legal_delivery': true,
          'p_ball_type': 'legal',
          'p_runs_scored': 4,
          'p_extras': 0,
          'p_is_wicket': false,
          'p_batsman_id': 'mp1',
          'p_non_striker_id': 'mp2',
          'p_bowler_id': 'mp9',
        },
      );
      when(
        () => remote.recordBall(any()),
      ).thenAnswer((_) async => _accepted(runs: 4));

      final session = await open();
      expect(session.current!.innings!.totalRuns, 4);

      await session.drain();
      expect(await pending(), isEmpty);
    });

    test('an unreadable payload is discarded, not left blocking', () async {
      stubReads();
      await local.appendOp(
        opId: 'junk',
        matchId: kMatchId,
        inningsNumber: 1,
        kind: 'ball',
        payload: {'nothing': 'useful'},
      );

      final session = await open();

      expect(
        await pending(),
        isEmpty,
        reason: 'it can never be sent and never be replayed',
      );
      expect(session.current!.pendingCount, 0);
    });
  });

  group('undo', () {
    test('a queued delivery is removed without asking the server', () async {
      stubReads();
      when(
        () => remote.recordBall(any()),
      ).thenThrow(NetworkException('offline'));

      final session = await open();
      await session.record(draft(runs: 4));
      await session.drain();
      expect(session.current!.pendingCount, 1);

      final result = await session.undo();

      expect(result.isRight(), isTrue);
      expect(session.current!.balls, isEmpty);
      expect(session.current!.pendingCount, 0);
      expect(await pending(), isEmpty);
      verifyNever(
        () => remote.undoLastBall(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
        ),
      );
    });

    test('undoing a queued delivery does not erase the others', () async {
      stubReads();
      when(
        () => remote.recordBall(any()),
      ).thenThrow(NetworkException('offline'));

      final session = await open();
      await session.record(draft(runs: 1));
      await session.record(draft(runs: 4));
      await session.drain();

      await session.undo();

      expect(
        session.current!.balls,
        hasLength(1),
        reason: 'the server has seen neither; re-reading would lose both',
      );
      expect(session.current!.innings!.totalRuns, 1);
      expect(await pending(), hasLength(1));
    });

    test('a stored delivery is undone on the server', () async {
      stubReads(
        state: innings(legalBallCount: 1, totalRuns: 1),
        balls: [ball(id: 'server-1', seq: 1)],
      );
      when(
        () => remote.undoLastBall(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
        ),
      ).thenAnswer((_) async => true);

      final session = await open();
      final result = await session.undo();

      expect(result.isRight(), isTrue);
      verify(
        () => remote.undoLastBall(matchId: kMatchId, inningsNumber: 1),
      ).called(1);
    });

    test('there is nothing to undo on an empty innings', () async {
      stubReads();
      final session = await open();

      expect(
        (await session.undo()).getLeft().toNullable(),
        isA<ValidationFailure>(),
      );
    });
  });

  group('setting the on-field trio', () {
    test('a dropped connection keeps it queued and reads as success', () async {
      stubReads();
      when(
        () => remote.startInnings(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
          strikerId: any(named: 'strikerId'),
          nonStrikerId: any(named: 'nonStrikerId'),
          bowlerId: any(named: 'bowlerId'),
          target: any(named: 'target'),
        ),
      ).thenThrow(NetworkException('no route to host'));

      final session = await open();
      final result = await session.setTrio(
        strikerId: 'mp1',
        nonStrikerId: 'mp2',
        bowlerId: 'mp10',
      );

      expect(
        result.isRight(),
        isTrue,
        reason: 'the log holds it; the scorer carries on',
      );
      expect(await pending(), hasLength(1));
      expect(
        session.current!.innings!.bowlerId!.value,
        'mp10',
        reason: 'the change is visible before the server has it',
      );
    });

    test('a server refusal is surfaced, NOT reported as success', () async {
      stubReads();
      when(
        () => remote.startInnings(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
          strikerId: any(named: 'strikerId'),
          nonStrikerId: any(named: 'nonStrikerId'),
          bowlerId: any(named: 'bowlerId'),
          target: any(named: 'target'),
        ),
      ).thenThrow(ServerException('That innings has already started.'));

      final session = await open();
      final result = await session.setTrio(
        strikerId: 'mp1',
        nonStrikerId: 'mp2',
        bowlerId: 'mp10',
      );

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(await pending(), isEmpty);
      expect(
        await refused(),
        hasLength(1),
        reason: 'kept so the scorer can read what did not apply',
      );
    });

    test('the same player cannot take both ends', () async {
      stubReads();
      final session = await open();

      final result = await session.setTrio(
        strikerId: 'mp1',
        nonStrikerId: 'mp1',
        bowlerId: 'mp9',
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await pending(), isEmpty);
    });
  });

  group('remote confirmed-base reconciliation', () {
    late StreamController<MatchRoomSnapshot> roomChanges;
    late StreamController<List<Ball>> ballChanges;

    setUp(() {
      roomChanges = StreamController<MatchRoomSnapshot>.broadcast();
      ballChanges = StreamController<List<Ball>>.broadcast();
      when(
        () => repo.watchMatchRoom(any()),
      ).thenAnswer((_) => roomChanges.stream);
      when(
        () => repo.watchBalls(any(), any()),
      ).thenAnswer((_) => ballChanges.stream);
    });

    tearDown(() async {
      await roomChanges.close();
      await ballChanges.close();
    });

    test(
      'remote confirmed ball updates below a pending local operation',
      () async {
        stubReads();
        when(
          () => remote.recordBall(any()),
        ).thenThrow(NetworkException('offline'));
        final session = await open();
        await session.record(draft(runs: 4));
        await session.drain();

        ballChanges.add([ball(id: 'remote-1', seq: 1, runs: 1)]);
        await Future<void>.delayed(Duration.zero);

        expect(
          session.current!.balls.map((item) => item.id.value),
          contains('remote-1'),
        );
        expect(session.current!.pendingCount, 1);
        expect(session.current!.computedByOpId, isNotEmpty);
      },
    );

    test(
      'dedupes remote balls and adopts trio, participants, and permission',
      () async {
        stubReads();
        final session = await open();
        final remoteBall = ball(id: 'remote-1', seq: 1);
        ballChanges.add([remoteBall, remoteBall]);
        roomChanges.add(
          _room(
            revision: 2,
            state: innings(bowlerId: 'mp10'),
            players: [
              ...lineup(),
              const MatchPlayer(
                id: MatchPlayerId('guest'),
                matchId: MatchId(kMatchId),
                teamSide: MatchTeamSide.b,
                unclaimedId: 'guest-u',
                displayName: 'Guest Bowler',
                source: MatchPlayerSource.matchAdded,
              ),
            ],
            canScore: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(session.current!.balls, hasLength(1));
        expect(session.current!.innings!.bowlerId!.value, 'mp10');
        expect(
          session.current!.matchPlayers.any((p) => p.id.value == 'guest'),
          isTrue,
        );
        expect(session.current!.canScore, isFalse);
      },
    );

    test('dispose cancels remote subscriptions', () async {
      stubReads();
      final session = ScoringSession(
        repository: repo,
        remote: remote,
        local: local,
        matchId: kMatchId,
        inningsNumber: 1,
      );
      await session.load();
      expect(roomChanges.hasListener, isTrue);
      expect(ballChanges.hasListener, isTrue);

      session.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(roomChanges.hasListener, isFalse);
      expect(ballChanges.hasListener, isFalse);
    });
  });
}

MatchRoomSnapshot _room({
  required int revision,
  required MatchInningsState state,
  required List<MatchPlayer> players,
  required bool canScore,
}) => MatchRoomSnapshot(
  match: match(),
  revision: revision,
  participants: players,
  innings: state,
  capabilities: MatchRoomCapabilities(canScore: canScore),
  serverTime: DateTime(2026),
);
