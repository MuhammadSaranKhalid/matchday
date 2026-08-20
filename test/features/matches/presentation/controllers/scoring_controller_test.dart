// Applying the write reply instead of waiting for the broadcast.
//
// `record-ball` answers with the ball it wrote and the innings row that
// resulted. Both used to be discarded (`.map((_) => unit)`), so the scoreboard
// only moved when the realtime broadcast made a SECOND trip back from the
// server. That second trip was most of why a tap felt slow.
//
// The overlay these tests cover is not a prediction — every value in it came
// from the same engine that owns the scorecard. What has to hold is the
// reconciliation: it may never roll the screen backwards, and it must retire
// itself once the streams carry the same data.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/controllers/scoring_controller.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchesRepo extends Mock implements MatchesRepository {}

const _matchId = 'm1';
const _teamA = TeamId('a');
const _teamB = TeamId('b');

Match _match() => Match(
      id: const MatchId(_matchId),
      teamAId: _teamA,
      teamBId: _teamB,
      format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
      ),
      status: MatchStatus.live,
      createdBy: 'capA',
      createdAt: DateTime(2026),
      teamACaptain: 'capA',
      teamBCaptain: 'capB',
      tossWonBy: _teamA,
      tossDecision: TossDecision.bat,
      startPhase: MatchStartPhase.live,
    );

List<MatchPlayer> _lineup() => const [
      MatchPlayer(
        id: MatchPlayerId('mp1'),
        matchId: MatchId(_matchId),
        teamSide: MatchTeamSide.a,
        profileId: 'p1',
        displayName: 'Striker',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp2'),
        matchId: MatchId(_matchId),
        teamSide: MatchTeamSide.a,
        profileId: 'p2',
        displayName: 'Non-striker',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp9'),
        matchId: MatchId(_matchId),
        teamSide: MatchTeamSide.b,
        profileId: 'p9',
        displayName: 'Bowler',
      ),
    ];

MatchInningsState _innings({required int version, int runs = 0}) =>
    MatchInningsState(
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      version: version,
      updatedAt: DateTime(2026),
      strikerId: const MatchPlayerId('mp1'),
      nonStrikerId: const MatchPlayerId('mp2'),
      bowlerId: const MatchPlayerId('mp9'),
      totalRuns: runs,
      legalBallCount: runs == 0 ? 0 : 1,
    );

var _seq = 0;

/// A no-ball, so the NEXT delivery is a free hit. The engine derives that from
/// the ball log rather than being told, which is why the test builds one.
Ball _noBall() => Ball(
      id: BallId('nb${++_seq}'),
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      seq: _seq,
      overNumber: 0,
      ballInOver: 0,
      isLegalDelivery: false,
      ballKind: BallKind.noBall,
      runsScored: 0,
      extras: 1,
      isWicket: false,
      isFreeHit: false,
      bowlerId: 'mp9',
    );

Ball _ball({int runs = 4, String? id}) => Ball(
      id: BallId(id ?? 'b${++_seq}'),
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      seq: _seq,
      overNumber: 0,
      ballInOver: 1,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runs,
      extras: 0,
      isWicket: false,
      isFreeHit: false,
      batsmanId: 'mp1',
      bowlerId: 'mp9',
    );

void main() {
  late _MockMatchesRepo repo;

  setUpAll(() {
    registerFallbackValue(const MatchId(_matchId));
    registerFallbackValue(
      const BallDraft(
        matchId: MatchId(_matchId),
        inningsNumber: 1,
        isLegalDelivery: true,
        ballKind: BallKind.legal,
      ),
    );
  });

  setUp(() {
    repo = _MockMatchesRepo();
    _seq = 0;
  });

  ProviderContainer makeContainer({
    MatchInningsState? innings,
    List<Ball> balls = const [],
  }) {
    final container = ProviderContainer.test(
      overrides: [
        matchesRepositoryProvider.overrideWithValue(repo),
        liveMatchProvider(_matchId)
            .overrideWith((ref) => Stream.value(_match())),
        matchPlayersProvider(_matchId).overrideWith((ref) async => _lineup()),
        liveInningsStateProvider(_matchId, 1)
            .overrideWith((ref) => Stream.value(innings ?? _innings(version: 1))),
        liveBallsProvider(_matchId, 1).overrideWith((ref) => Stream.value(balls)),
        canScoreInningsProvider(_matchId, 1).overrideWith((ref) async => true),
      ],
    );
    addTearDown(container.dispose);
    container.listen(scoringControllerProvider(_matchId, 1), (_, __) {});
    return container;
  }

  Future<ScoringState> load(ProviderContainer c) =>
      c.read(scoringControllerProvider(_matchId, 1).future);

  ScoringController notifier(ProviderContainer c) =>
      c.read(scoringControllerProvider(_matchId, 1).notifier);

  group('the write reply', () {
    test('moves the score without waiting for the broadcast', () async {
      // The streams stay on the OLD state for the whole test — exactly the
      // window that used to show a stale scoreboard.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      final scored = _ball(runs: 4);
      when(() => repo.recordBall(any())).thenAnswer(
        (_) async => Right(BallOutcome(
          ball: scored,
          innings: _innings(version: 2, runs: 4),
        )),
      );

      await notifier(container).recordRun(4);
      final state = await load(container);

      expect(state.totalRuns, 4, reason: 'score should move on the reply');
      expect(state.balls.map((b) => b.id), contains(scored.id));
    });

    test('still works when the server does not return the innings row',
        () async {
      // An older deployment of the function has no `returning *`.
      //
      // This assertion changed with the local engine, and the change is the
      // point: the score used to sit at 0 until the broadcast carried the
      // innings row back. Now the local engine has already computed it, so the
      // score is correct regardless of what that deployment returns — the
      // server's row, when it comes, only confirms it.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      final scored = _ball(runs: 6);
      when(() => repo.recordBall(any()))
          .thenAnswer((_) async => Right(BallOutcome(ball: scored)));

      await notifier(container).recordRun(6);
      final state = await load(container);

      expect(state.balls.map((b) => b.id), contains(scored.id));
      expect(state.totalRuns, 6, reason: 'the local engine computed it');
    });
  });

  group('reconciliation', () {
    test('never rolls the screen backwards when the stream lags', () async {
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      when(() => repo.recordBall(any())).thenAnswer(
        (_) async => Right(BallOutcome(
          ball: _ball(runs: 4),
          innings: _innings(version: 5, runs: 4),
        )),
      );
      await notifier(container).recordRun(4);

      // A rebuild for an unrelated reason must not drop back to the stream's
      // older version — that would show the score jumping backwards.
      container.invalidate(canScoreInningsProvider(_matchId, 1));
      final state = await load(container);

      expect(state.totalRuns, 4);
      expect(state.innings?.version, 5);
    });

    test('does not duplicate the ball once the broadcast carries it',
        () async {
      final shared = _ball(runs: 4, id: 'same');
      final container = makeContainer(
        innings: _innings(version: 2, runs: 4),
        balls: [shared],
      );
      await load(container);

      when(() => repo.recordBall(any())).thenAnswer(
        (_) async => Right(BallOutcome(
          ball: shared,
          innings: _innings(version: 2, runs: 4),
        )),
      );
      await notifier(container).recordRun(4);
      final state = await load(container);

      expect(
        state.balls.where((b) => b.id == shared.id).length,
        1,
        reason: 'the reply and the broadcast are the same delivery',
      );
    });

    test('a failed write leaves the score untouched', () async {
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      when(() => repo.recordBall(any()))
          .thenAnswer((_) async => const Left(ServerFailure('boom')));

      final result = await notifier(container).recordRun(4);
      final state = await load(container);

      expect(result.isLeft(), isTrue);
      expect(state.totalRuns, 0);
      expect(state.balls, isEmpty);
      expect(state.isBusy, isFalse);
    });
  });

  group('local-first apply (Stage 1)', () {
    test('the score moves before the write completes', () async {
      // The whole point of Stage 1. The repo future is held open, so anything
      // on screen at this moment came from the local engine, not the server.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      final gate = Completer<Either<Failure, BallOutcome>>();
      when(() => repo.recordBall(any())).thenAnswer((_) => gate.future);

      final pending = notifier(container).recordRun(4);
      await Future<void>.delayed(Duration.zero);

      final mid = container.read(scoringControllerProvider(_matchId, 1)).value!;
      expect(mid.totalRuns, 4, reason: 'painted before the network answered');
      expect(mid.balls, hasLength(1));
      expect(mid.pendingCount, 1, reason: 'shown but unconfirmed');

      gate.complete(Right(BallOutcome(
        ball: _ball(runs: 4),
        innings: _innings(version: 2, runs: 4),
      )));
      await pending;

      final settled = await load(container);
      expect(settled.pendingCount, 0);
      expect(settled.totalRuns, 4);
    });

    test('strike rotation is applied locally, not awaited', () async {
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      final gate = Completer<Either<Failure, BallOutcome>>();
      when(() => repo.recordBall(any())).thenAnswer((_) => gate.future);

      final pending = notifier(container).recordRun(1);
      await Future<void>.delayed(Duration.zero);

      final mid = container.read(scoringControllerProvider(_matchId, 1)).value!;
      expect(mid.innings?.strikerId?.value, 'mp2', reason: 'odd run crosses');
      expect(mid.innings?.nonStrikerId?.value, 'mp1');

      gate.complete(Right(BallOutcome(
        ball: _ball(runs: 1),
        innings: _innings(version: 2, runs: 1),
      )));
      await pending;
    });

    test('a free-hit dismissal is refused without reaching the server',
        () async {
      // Defence in depth for the bug the wicket sheet also guards: after a
      // no-ball only a run-out (or hit wicket / obstructing / handled ball)
      // can dismiss. The local engine returns the same rejection the server
      // would, so the round trip is pure cost — and the scorer is told at
      // once instead of after a pause.
      final container = makeContainer(
        innings: _innings(version: 1),
        balls: [_noBall()],
      );
      await load(container);

      final result =
          await notifier(container).recordWicket(type: WicketType.bowled);

      expect(result.isLeft(), isTrue);
      verifyNever(() => repo.recordBall(any()));
      expect((await load(container)).balls, hasLength(1),
          reason: 'only the no-ball; nothing was appended');
    });

    test('a run-out on a free hit is allowed through', () async {
      final container = makeContainer(
        innings: _innings(version: 1),
        balls: [_noBall()],
      );
      await load(container);

      when(() => repo.recordBall(any())).thenAnswer(
        (_) async => Right(BallOutcome(ball: _ball(runs: 0))),
      );

      final result =
          await notifier(container).recordWicket(type: WicketType.runOut);

      expect(result.isRight(), isTrue);
      verify(() => repo.recordBall(any())).called(1);
    });

    test('a failed write takes the delivery back off the screen', () async {
      // Stage 1 has no local durability: a failed write genuinely loses the
      // delivery. What must not happen is the screen keeping a ball the
      // scorecard never received.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      when(() => repo.recordBall(any()))
          .thenAnswer((_) async => const Left(ServerFailure('offline')));

      final result = await notifier(container).recordRun(4);
      final state = await load(container);

      expect(result.isLeft(), isTrue);
      expect(state.balls, isEmpty, reason: 'rolled back');
      expect(state.totalRuns, 0);
      expect(state.pendingCount, 0);
    });

    test('writes reach the server in the order they were entered', () async {
      // Deliveries are sequential and the server holds an optimistic version
      // lock. Two entered inside one round trip must not race.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      final seen = <int>[];
      when(() => repo.recordBall(any())).thenAnswer((inv) async {
        final draft = inv.positionalArguments.first as BallDraft;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        seen.add(draft.runsScored);
        return Right(BallOutcome(ball: _ball(runs: draft.runsScored)));
      });

      final a = notifier(container).recordRun(1);
      final b = notifier(container).recordRun(2);
      await Future.wait([a, b]);

      expect(seen, [1, 2], reason: 'entered 1 then 2');
    });
  });

  group('undo', () {
    test('does not resurrect the ball the reply had applied', () async {
      // The overlay may still hold the very delivery undo removes. Without
      // clearing it, the ball reappears the moment the screen rebuilds.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      final scored = _ball(runs: 4);
      when(() => repo.recordBall(any())).thenAnswer(
        (_) async => Right(BallOutcome(
          ball: scored,
          innings: _innings(version: 2, runs: 4),
        )),
      );
      await notifier(container).recordRun(4);
      expect((await load(container)).balls, isNotEmpty);

      when(() => repo.undoLastBall(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
          )).thenAnswer((_) async => const Right(true));

      await notifier(container).undoLastBall();
      final state = await load(container);

      expect(state.balls, isEmpty);
      expect(state.totalRuns, 0);
    });
  });
}
