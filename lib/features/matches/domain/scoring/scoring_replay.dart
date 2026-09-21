// Confirmed state + queued writes → what the scorer sees.
//
// This is the fold that replaced five hand-written patch paths (append on tap,
// remove on undo, swap on settle, remove on refusal, refetch on error). Each
// of those had to leave the state consistent on its own, and they disagreed:
// adopting the server's innings row mid-queue rewound the ball count while
// later taps had already moved past it, and an over came out numbered
// 8.1 8.2 8.3 8.4 8.2 8.3 8.4. The score stayed right, which is why it took a
// while to see.
//
// There is nothing to keep in agreement here. Anything changes — a tap, an
// accepted write, a refusal, a fresh read — and the projection is thrown away
// and rebuilt from the confirmed base and the log. The arithmetic is the
// engine's, applied once per queued delivery, exactly as the server would have
// applied it. No reversal arithmetic exists to get wrong.
//
// Pure and total, like the engine it calls. No I/O, no clock, no randomness.
library;

import '../entities/ball.dart';
import '../entities/match.dart';
import '../entities/match_innings_state.dart';
import '../entities/match_player.dart';
import '../entities/scoring_projection.dart';
import 'scoring_adapter.dart';
import 'scoring_engine.dart';
import 'scoring_rules.dart';
import 'scoring_types.dart';

/// Marks a ball that exists only on this device.
///
/// Kept because a stable id per queued delivery keeps widget keys stable
/// across replays, and because a `local:` id in a log line says immediately
/// that the server has not seen it. NOTHING parses it back apart: the queue
/// itself answers "is this sent yet", not the shape of an id.
const kProvisionalBallPrefix = 'local:';

BallId provisionalBallId(String opId) => BallId('$kProvisionalBallPrefix$opId');

/// Fold [pending] over the confirmed state.
ScoringProjection replayScoring({
  required Match match,
  required MatchInningsState? innings,
  required List<Ball> balls,
  required List<MatchPlayer> matchPlayers,
  required bool canScore,
  required List<PendingScoringOp> pending,
}) {
  final format = engineFormatFrom(match.format);

  var projected = innings;
  final projectedBalls = [...balls];
  final computed = <String, ComputedDelivery>{};
  final rejected = <String>[];
  var pendingCount = 0;

  for (final op in pending) {
    switch (op) {
      case PendingTrio(
        :final strikerId,
        :final nonStrikerId,
        :final bowlerId,
        :final target,
      ):
        projected = projected?.copyWith(
          strikerId: MatchPlayerId(strikerId),
          nonStrikerId: MatchPlayerId(nonStrikerId),
          bowlerId: MatchPlayerId(bowlerId),
          target: target,
        );
        pendingCount += 1;

      case PendingBall(:final draft):
        final result = applyBall(
          engineStateFrom(projected),
          format,
          engineInputFrom(draft),
          engineContextFrom(
            balls: projectedBalls,
            bowlerId: projected?.bowlerId?.value,
          ),
        );

        // A delivery that was legal when tapped stays legal, so this is close
        // to unreachable. It is still not allowed to abort the fold: dropping
        // the one op and carrying on shows the scorer every OTHER delivery
        // they entered, which is strictly better than showing them none.
        if (!result.ok) {
          rejected.add(op.opId);
          continue;
        }

        final ball = result.ball!;
        final next = result.newState!;
        final events = result.events!;

        projectedBalls.add(
          Ball(
            id: provisionalBallId(op.opId),
            matchId: match.id,
            inningsNumber: draft.inningsNumber,
            seq: (projectedBalls.isEmpty ? 0 : projectedBalls.last.seq) + 1,
            overNumber: ball.overNumber,
            ballInOver: ball.ballInOver,
            isLegalDelivery: ball.isLegalDelivery,
            ballKind: ball.ballKind,
            runsScored: ball.runsScored,
            extras: ball.extras,
            isWicket: ball.isWicket,
            isFreeHit: ball.isFreeHit,
            wicketType: ball.wicketType,
            dismissedPlayerId: ball.dismissedPlayerId,
            batsmanId: ball.batsmanId,
            nonStrikerId: ball.nonStrikerId,
            bowlerId: ball.bowlerId,
            fielderId: ball.fielderId,
            commentary: ball.commentary,
          ),
        );

        projected = _advance(projected, next, events);

        // Everything the server needs and cannot work out for itself. Derived
        // HERE rather than at tap time, so it always describes the delivery as
        // the screen currently shows it.
        computed[op.opId] = ComputedDelivery(
          overNumber: ball.overNumber,
          ballInOver: ball.ballInOver,
          isFreeHit: ball.isFreeHit,
          inningsEnded: events.inningsEnded,
          isAllOut: events.allOut,
          ballsPerOver: format.ballsPerOver,
          strikerAfter: next.strikerId,
          nonStrikerAfter: next.nonStrikerId,
          bowlerAfter: next.bowlerId,
          isBowlerCredited: creditedToBowler(ball.wicketType),
        );
        pendingCount += 1;
    }
  }

  return ScoringProjection(
    match: match,
    innings: projected,
    balls: projectedBalls,
    matchPlayers: matchPlayers,
    canScore: canScore,
    pendingCount: pendingCount,
    computedByOpId: computed,
    rejectedOpIds: rejected,
  );
}

/// Carry the engine's new innings values onto the row.
///
/// `version` is deliberately left at the confirmed value. It is the server's
/// counter, no longer used as a write lock, and incrementing it locally would
/// make the row unequal to itself on every replay for no gain.
MatchInningsState? _advance(
  MatchInningsState? current,
  NewInningsState next,
  InningsEvents events,
) => current?.copyWith(
  legalBallCount: next.legalBallCount,
  totalRuns: next.totalRuns,
  totalWickets: next.totalWickets,
  totalExtras: next.totalExtras,
  strikerId: next.strikerId == null ? null : MatchPlayerId(next.strikerId!),
  clearStriker: next.strikerId == null,
  nonStrikerId:
      next.nonStrikerId == null ? null : MatchPlayerId(next.nonStrikerId!),
  clearNonStriker: next.nonStrikerId == null,
  bowlerId: next.bowlerId == null ? null : MatchPlayerId(next.bowlerId!),
  clearBowler: next.bowlerId == null,
  isAllOut: events.allOut || current.isAllOut,
);
