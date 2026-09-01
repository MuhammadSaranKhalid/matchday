// The fold that replaced five hand-written patch paths.
//
// The regression this file exists to pin is the over that came out numbered
// 8.1 8.2 8.3 8.4 8.2 8.3 8.4. It happened because the confirmed innings row
// was adopted while later deliveries were still queued, rewinding the ball
// count they had already moved past — and `over_number` / `ball_in_over` are
// derived from that count. The score stayed right the whole time, which is
// why it survived a season of use before anyone noticed.
//
// Replay cannot produce it: a newer base and the remaining queue are folded
// together, never merged.
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/scoring_projection.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_replay.dart';

import '../../scoring_fixtures.dart';

ScoringProjection project({
  int legalBallCount = 0,
  int totalRuns = 0,
  List<Ball> confirmed = const [],
  List<PendingScoringOp> pending = const [],
}) =>
    replayScoring(
      match: match(),
      innings: innings(
        legalBallCount: legalBallCount,
        totalRuns: totalRuns,
      ),
      balls: confirmed,
      matchPlayers: lineup(),
      canScore: true,
      pending: pending,
    );

void main() {
  test('an empty queue projects the confirmed state unchanged', () {
    final p = project(legalBallCount: 3, totalRuns: 7);

    expect(p.innings!.legalBallCount, 3);
    expect(p.innings!.totalRuns, 7);
    expect(p.balls, isEmpty);
    expect(p.pendingCount, 0);
  });

  test('a queued delivery advances the score and the ball list', () {
    final p = project(
      legalBallCount: 3,
      totalRuns: 7,
      pending: [PendingBall(opId: 'op-1', draft: draft(runs: 4))],
    );

    expect(p.innings!.legalBallCount, 4);
    expect(p.innings!.totalRuns, 11);
    expect(p.balls, hasLength(1));
    expect(p.pendingCount, 1);
  });

  test('queued deliveries take consecutive positions in the over', () {
    // Four balls already bowled in over 8, three more queued behind them.
    final p = project(
      legalBallCount: 8 * 6 + 4,
      totalRuns: 60,
      pending: [
        for (var i = 1; i <= 3; i++)
          PendingBall(opId: 'op-$i', draft: draft(runs: 1)),
      ],
    );

    expect(
      p.balls.map((b) => '${b.overNumber}.${b.ballInOver}'),
      ['8.5', '8.6', '9.1'],
      reason: 'no position may be issued twice',
    );
  });

  test('the same queue over a NEWER base does not reissue a position', () {
    // The exact shape of the 8.2/8.3/8.4 bug: the server confirms the first of
    // three queued deliveries, so the base moves forward by one while two are
    // still owed. Under patching, the count rewound and 8.5 was handed out
    // twice. Under replay the two remaining simply land after it.
    final before = project(
      legalBallCount: 8 * 6 + 4,
      pending: [
        for (var i = 1; i <= 3; i++)
          PendingBall(opId: 'op-$i', draft: draft(runs: 1)),
      ],
    );

    final after = replayScoring(
      match: match(),
      innings: innings(legalBallCount: 8 * 6 + 5, totalRuns: 1),
      balls: [ball(id: 'server-1', seq: 53, overNumber: 8, ballInOver: 5)],
      matchPlayers: lineup(),
      canScore: true,
      pending: [
        for (var i = 2; i <= 3; i++)
          PendingBall(opId: 'op-$i', draft: draft(runs: 1)),
      ],
    );

    expect(before.balls.map((b) => '${b.overNumber}.${b.ballInOver}'),
        ['8.5', '8.6', '9.1']);
    expect(after.balls.map((b) => '${b.overNumber}.${b.ballInOver}'),
        ['8.5', '8.6', '9.1'],
        reason: 'the same seven deliveries, one of them now confirmed');
    expect(after.pendingCount, 2);
  });

  test('removing the last queued delivery restores the previous score', () {
    final queue = [
      PendingBall(opId: 'op-1', draft: draft(runs: 4)),
      PendingBall(opId: 'op-2', draft: draft(runs: 6)),
    ];

    final withBoth = project(legalBallCount: 3, totalRuns: 7, pending: queue);
    final undone =
        project(legalBallCount: 3, totalRuns: 7, pending: [queue.first]);

    expect(withBoth.innings!.totalRuns, 17);
    expect(undone.innings!.totalRuns, 11,
        reason: 'recounted by the fold, never subtracted back out');
    expect(undone.balls, hasLength(1));
    expect(undone.pendingCount, 1);
  });

  test('a queued trio change is visible before the server has it', () {
    final p = project(
      pending: [
        const PendingTrio(
          opId: 'op-1',
          strikerId: 'mp3',
          nonStrikerId: 'mp2',
          bowlerId: 'mp10',
        ),
      ],
    );

    expect(p.innings!.strikerId!.value, 'mp3');
    expect(p.innings!.bowlerId!.value, 'mp10');
    expect(p.pendingCount, 1);
  });

  test('every queued delivery carries the answer that will reach the wire', () {
    final p = project(
      legalBallCount: 2,
      pending: [PendingBall(opId: 'op-1', draft: draft(runs: 1))],
    );

    final computed = p.computedByOpId['op-1']!;
    expect(computed.overNumber, 0);
    expect(computed.ballInOver, 3);
    expect(computed.ballsPerOver, 6);
    expect(computed.strikerAfter, 'mp2', reason: 'a single rotates the strike');
    expect(computed.nonStrikerAfter, 'mp1');
  });

  test('a delivery the engine cannot place is dropped, not fatal', () {
    // A wicket with no wicket type is the engine's own rejection case.
    final p = project(
      pending: [
        PendingBall(
          opId: 'bad',
          draft: BallDraft(
            matchId: draft().matchId,
            inningsNumber: 1,
            isLegalDelivery: true,
            ballKind: BallKind.legal,
            isWicket: true,
          ),
        ),
        PendingBall(opId: 'good', draft: draft(runs: 2)),
      ],
    );

    expect(p.rejectedOpIds, ['bad']);
    expect(p.balls, hasLength(1), reason: 'the good one still lands');
    expect(p.innings!.totalRuns, 2);
    expect(p.pendingCount, 1);
  });

  test('a free hit survives an intervening wide across the queue', () {
    final p = project(
      pending: [
        PendingBall(
          opId: 'nb',
          draft: BallDraft(
            matchId: draft().matchId,
            inningsNumber: 1,
            isLegalDelivery: false,
            ballKind: BallKind.noBall,
            extras: 1,
            batsmanId: 'mp1',
            nonStrikerId: 'mp2',
            bowlerId: 'mp9',
          ),
        ),
        PendingBall(
          opId: 'wd',
          draft: BallDraft(
            matchId: draft().matchId,
            inningsNumber: 1,
            isLegalDelivery: false,
            ballKind: BallKind.wide,
            extras: 1,
            batsmanId: 'mp1',
            nonStrikerId: 'mp2',
            bowlerId: 'mp9',
          ),
        ),
        PendingBall(opId: 'fh', draft: draft(runs: 1)),
      ],
    );

    expect(p.computedByOpId['fh']!.isFreeHit, isTrue,
        reason: 'a wide does not consume the free hit');
  });
}
