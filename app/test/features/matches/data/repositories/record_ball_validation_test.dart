import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:matchday/features/matches/data/repositories/matches_repository_impl.dart';
import 'package:matchday/features/matches/data/datasources/match_requests_remote_datasource.dart';
import 'package:matchday/features/matches/data/datasources/format_presets_remote_datasource.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements MatchesRemoteDataSource {}

class _MockRequests extends Mock implements MatchRequestsRemoteDataSource {}

class _MockPresets extends Mock implements FormatPresetsRemoteDataSource {}

/// Guards the extras wire format at the repository boundary.
///
/// A wide is a penalty against the bowling side: nothing off it reaches the
/// batter's score, including runs the batters run. The scoring screen used to
/// send those runs as `runsScored`, which kept the TEAM total right while
/// inflating the batter and understating extras — a wrong scorecard behind a
/// right-looking scoreboard. `applyBall` rejects that shape too; this is the
/// fail-fast half so the user gets a sentence instead of a 422.
void main() {
  late _MockRemote remote;
  late MatchesRepositoryImpl repo;

  BallDraft draft({
    required BallKind kind,
    int runsScored = 0,
    int extras = 0,
  }) =>
      BallDraft(
        matchId: const MatchId('m1'),
        inningsNumber: 1,
        isLegalDelivery: kind != BallKind.wide && kind != BallKind.noBall,
        ballKind: kind,
        runsScored: runsScored,
        extras: extras,
        batsmanId: 'mp1',
        nonStrikerId: 'mp2',
        bowlerId: 'mp3',
        // Every real draft carries the local engine's answer — the server has
        // no engine of its own and stores these verbatim (design doc D10), so
        // the repository refuses a draft without one. The values here stand in
        // for whatever `applyBall` returned; these tests are about the wire
        // shape of the delivery, not about the arithmetic.
        computed: const ComputedDelivery(
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

  setUp(() {
    remote = _MockRemote();
    repo = MatchesRepositoryImpl(remote, _MockRequests(), _MockPresets());
  });

  Future<Failure?> failureFor(BallDraft d) async {
    final result = await repo.recordBall(d);
    return result.getLeft().toNullable();
  }

  // The two wide rules — "runs off a wide are never the batter's" and "a wide
  // must carry its 1-run penalty" — used to be asserted here, against a copy of
  // them in this repository. That copy is gone: both engines enforce them, and
  // both are held to the same golden vectors
  // (`supabase/functions/_shared/scoring/vectors.json`, categories `wide`).
  //
  // Re-adding them here would recreate the duplication this workstream exists
  // to remove, and a repository copy could drift from the engines silently.
  // The bye / leg-bye rule below stays because NEITHER engine has it — see the
  // comment at its guard in matches_repository_impl.dart.

  test('bye runs on the batter are rejected', () async {
    final failure = await failureFor(
      draft(kind: BallKind.bye, runsScored: 1, extras: 1),
    );

    expect(failure, isA<ValidationFailure>());
    verifyNever(() => remote.recordBall(any()));
  });

  test('a wide carrying everything in extras is accepted', () async {
    // 1 penalty + 2 run = 3 extras, nothing to the batter.
    when(() => remote.recordBall(any())).thenAnswer(
      (_) async => throw StateError('reached the wire — shape was accepted'),
    );

    final failure = await failureFor(draft(kind: BallKind.wide, extras: 3));

    // It got past validation; the StateError proves the call was attempted.
    expect(failure, isA<UnknownFailure>());
    verify(() => remote.recordBall(any())).called(1);
  });

  test('a draft that never ran the engine is refused before the wire', () async {
    // Guards D10 at the repository boundary: the server stores what the device
    // computed and computes nothing itself, so an uncomputed draft is
    // unrecordable rather than merely incomplete.
    final failure = await failureFor(
      const BallDraft(
        matchId: MatchId('m1'),
        inningsNumber: 1,
        isLegalDelivery: true,
        ballKind: BallKind.legal,
        runsScored: 1,
        batsmanId: 'mp1',
        nonStrikerId: 'mp2',
        bowlerId: 'mp3',
      ),
    );

    expect(failure, isA<ValidationFailure>());
    verifyNever(() => remote.recordBall(any()));
  });

  test('the engine answer and the idempotency key reach the wire', () async {
    when(() => remote.recordBall(any())).thenAnswer(
      (_) async => throw StateError('reached the wire — shape was accepted'),
    );

    await failureFor(draft(kind: BallKind.legal, runsScored: 1).copyWith(
      opId: 'op-abc',
    ));

    final sent = verify(() => remote.recordBall(captureAny())).captured.single
        as Map<String, dynamic>;
    // Without this key a retry after a dropped connection records the
    // delivery twice — the exact failure the offline queue makes likely.
    expect(sent['p_idempotency_key'], 'op-abc');
    expect(sent['p_over_number'], 0);
    expect(sent['p_ball_in_over'], 1);
    expect(sent['p_striker_after'], 'mp1');
    expect(sent['p_bowler_after'], 'mp3');
    expect(sent['p_innings_ended'], isFalse);
    // The optimistic-lock guard is gone (D12: one writer per innings).
    expect(sent.containsKey('p_expected_version'), isFalse);
  });

  test('a no-ball still credits runs off the bat', () async {
    when(() => remote.recordBall(any())).thenAnswer(
      (_) async => throw StateError('reached the wire — shape was accepted'),
    );

    final failure = await failureFor(
      draft(kind: BallKind.noBall, runsScored: 4, extras: 1),
    );

    expect(failure, isA<UnknownFailure>());
    final sent = verify(() => remote.recordBall(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(sent['p_runs_scored'], 4);
    expect(sent['p_extras'], 1);
  });
}
