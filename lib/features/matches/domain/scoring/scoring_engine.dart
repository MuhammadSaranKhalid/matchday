// The match scoring engine — the client-side half.
//
// [applyBall] is a PURE function: given the innings state, the format, the raw
// delivery and minimal context, it returns the computed ball, the new innings
// state, and the events it triggered. No I/O, no clock, no randomness.
//
// ── THIS CODE EXISTS TWICE ───────────────────────────────────────────────────
//
// The authority is `supabase/functions/_shared/scoring/engine.ts`, which runs
// server-side in the `record-ball` function and owns the scorecard. This is a
// behaviour-preserving port of it, so a delivery can be computed and shown on
// the scorer's device without waiting for a network round trip.
//
// The two are held together by `supabase/functions/_shared/scoring/vectors.json`
// — the shared golden vectors, executed by both the Deno suite and the Dart
// suite. That file is the specification. **A change to scoring rules is a
// change to the vectors first**: add the case, watch it fail in both languages,
// then make both pass. Editing one engine alone is how a scorecard silently
// stops matching the server's.
//
// Purity is not decoration here — it is what makes the vectors a complete
// specification. A pure total function is fully characterised by its
// input/output pairs. Introduce a clock, a random, or a read here and the
// parity argument collapses.
library;

import '../entities/ball.dart';
import 'scoring_types.dart';

/// Dismissals that stand on a free hit.
///
/// Mirrors the TypeScript engine's list and the `balls_free_hit_dismissal_check`
/// constraint on the balls table. All three must agree.
const _freeHitDismissals = {
  WicketType.runOut,
  WicketType.hitWicket,
  WicketType.obstructing,
  WicketType.handledBall,
};

/// Apply one delivery to an innings.
BallResult applyBall(
  EngineInningsState state,
  EngineFormat format,
  EngineBallInput input,
  EngineContext ctx,
) {
  final ballsPerOver = format.ballsPerOver > 0 ? format.ballsPerOver : 6;
  final runs = input.runsScored;
  final extras = input.extras;
  final isLegal = input.isLegalDelivery;

  // ── Validation ────────────────────────────────────────────────────────────
  if (input.isWicket && input.wicketType == null) {
    return const BallResult.failure(
      EngineError('wicket_type_required', 'A wicket needs a wicket type'),
    );
  }
  if (!input.isWicket && input.wicketType != null) {
    return const BallResult.failure(EngineError(
      'wicket_type_unexpected',
      'wicket_type must be null when this delivery is not a wicket',
    ));
  }
  if (runs < 0 || extras < 0) {
    return const BallResult.failure(
      EngineError('negative_runs', 'Runs and extras must be non-negative'),
    );
  }

  // A wide is a penalty against the bowling side: nothing off it ever reaches
  // the batter, including runs the batters then run. The client once sent a
  // wide's runs as `runsScored`, which kept the team total right but inflated
  // the batter's score and understated extras — a wrong scorecard behind a
  // right-looking scoreboard.
  if (input.ballKind == BallKind.wide && runs > 0) {
    return const BallResult.failure(EngineError(
      'wide_runs_to_batter',
      'Runs off a wide are extras — send them in `extras`, not `runsScored`',
    ));
  }
  if (input.ballKind == BallKind.wide && extras < 1) {
    return const BallResult.failure(EngineError(
      'wide_missing_penalty',
      'A wide must carry at least the 1-run penalty in `extras`',
    ));
  }

  // ── Bowler over cap ───────────────────────────────────────────────────────
  // At most maxOversPerBowler * ballsPerOver legal balls. 0 = no cap.
  if (isLegal &&
      format.maxOversPerBowler > 0 &&
      ctx.bowlerLegalBalls >= format.maxOversPerBowler * ballsPerOver) {
    return BallResult.failure(EngineError(
      'bowler_over_cap',
      'Bowler has reached the ${format.maxOversPerBowler}-over limit',
    ));
  }

  // ── Over / ball position, from the count BEFORE this ball ─────────────────
  final overNumber = state.legalBallCount ~/ ballsPerOver;
  final ballInOver = isLegal ? (state.legalBallCount % ballsPerOver) + 1 : 0;

  // ── Free hit: true iff the most recent non-wide delivery was a no-ball ────
  final isFreeHit = ctx.prevNonWideKind == BallKind.noBall;

  if (isFreeHit && input.isWicket) {
    if (!_freeHitDismissals.contains(input.wicketType)) {
      return const BallResult.failure(EngineError(
        'free_hit_dismissal',
        'On a free hit the batter can only be run out, hit wicket, '
            'obstructing, or handled ball',
      ));
    }
  }

  // ── Strike rotation ───────────────────────────────────────────────────────
  // The batters change ends when they physically RUN an odd number of runs.
  // That is every run except the automatic penalty on a wide or no-ball,
  // which is awarded, not run:
  //
  //   legal      ran = runsScored (off the bat) + extras (byes / leg-byes)
  //   wide       ran = extras - 1                (the 1 is the wide penalty)
  //   no-ball    ran = runsScored + extras - 1   (the 1 is the nb penalty)
  //
  // Boundaries fall out for free: 4 and 6 are even, so no swap.
  final penalty =
      (input.ballKind == BallKind.wide || input.ballKind == BallKind.noBall)
          ? 1
          : 0;
  final runsRun = runs + extras - penalty;

  final endChangeBalls =
      (format.endChangeBalls != null && format.endChangeBalls! > 0)
          ? format.endChangeBalls!
          : ballsPerOver;

  // `remainder`, NOT `%`. Dart's `%` is Euclidean and always non-negative;
  // JavaScript's keeps the sign of the dividend. `runsRun` reaches -1 on a
  // malformed no-ball carrying no penalty (runs 0, extras 0), and there the two
  // operators disagree: JS says no swap, Dart's `%` would say swap. Since the
  // TypeScript engine is the authority, this has to follow its arithmetic
  // exactly or the two engines silently rotate strike differently.
  var swap = runsRun.remainder(2) == 1;

  // A set/over boundary (a new bowler may come on) is every ballsPerOver. The
  // ENDS change every endChangeBalls — equal for normal cricket, but 10 for
  // The Hundred, which is two 5-ball sets per end.
  final overEnded = isLegal && (state.legalBallCount + 1) % ballsPerOver == 0;
  final endChanged = isLegal && (state.legalBallCount + 1) % endChangeBalls == 0;
  if (endChanged) swap = !swap;

  final newLegal = state.legalBallCount + (isLegal ? 1 : 0);
  final newTotalRuns = state.totalRuns + runs + extras;
  final newTotalWickets = state.totalWickets + (input.isWicket ? 1 : 0);
  final newStriker = input.isWicket
      ? null
      : (swap ? state.nonStrikerId : state.strikerId);
  final newNonStriker =
      (swap && !input.isWicket) ? state.strikerId : state.nonStrikerId;
  final newBowler = overEnded ? null : state.bowlerId;

  // ── Innings termination ───────────────────────────────────────────────────
  final t = evaluateTermination(
    format: format,
    legalBallCount: newLegal,
    totalRuns: newTotalRuns,
    totalWickets: newTotalWickets,
    target: state.target,
    isDeclared: state.isDeclared,
  );
  final allOut = t.allOut;
  final oversComplete = t.oversComplete;
  final targetReached = t.targetReached;
  final inningsEnded = t.ended;
  final reason = t.reason;

  return BallResult.ok(
    ball: ComputedBall(
      overNumber: overNumber,
      ballInOver: ballInOver,
      isFreeHit: isFreeHit,
      isLegalDelivery: isLegal,
      ballKind: input.ballKind,
      runsScored: runs,
      extras: extras,
      isWicket: input.isWicket,
      wicketType: input.wicketType,
      batsmanId: input.batsmanId,
      nonStrikerId: input.nonStrikerId,
      bowlerId: input.bowlerId,
      fielderId: input.fielderId,
      commentary: input.commentary,
    ),
    newState: NewInningsState(
      legalBallCount: newLegal,
      totalRuns: newTotalRuns,
      totalWickets: newTotalWickets,
      totalExtras: state.totalExtras + extras,
      strikerId: newStriker,
      nonStrikerId: newNonStriker,
      bowlerId: newBowler,
    ),
    events: InningsEvents(
      overEnded: overEnded,
      allOut: allOut,
      oversComplete: oversComplete,
      targetReached: targetReached,
      inningsEnded: inningsEnded,
      inningsEndReason: reason,
    ),
  );
}

/// Whether an innings has ended, and why.
///
/// Extracted so the screen and the engine cannot answer it differently. They
/// used to: the scoring screen carried its own copy that guarded all-out on
/// `playersPerTeam > 0` instead of `wicketsToAllOut > 0` — which made a format
/// with all-out disabled (`wicketsToAllOut: 0`) read as over from the first
/// ball — and omitted the target and declaration cases entirely, so a chase
/// reaching its target did not register as finished on the client at all.
///
/// [applyBall] evaluates this against the state AFTER a delivery; the screen
/// evaluates it against the state as it currently stands. Same rule, two
/// moments — which is exactly why it must be one function.
InningsTermination evaluateTermination({
  required EngineFormat format,
  required int legalBallCount,
  required int totalRuns,
  required int totalWickets,
  required int? target,
  required bool isDeclared,
}) {
  final ballsPerOver = format.ballsPerOver > 0 ? format.ballsPerOver : 6;

  // wicketsToAllOut defaults to playersPerTeam - 1; a format can override it.
  // 0 disables the all-out check entirely (indoor pairs and similar), which is
  // why the guard is on the threshold and not on the squad size.
  final wicketsToAllOut = format.wicketsToAllOut ?? (format.playersPerTeam - 1);

  final allOut = wicketsToAllOut > 0 && totalWickets >= wicketsToAllOut;
  final oversComplete = format.oversPerInnings > 0 &&
      legalBallCount >= format.oversPerInnings * ballsPerOver;
  final targetReached = target != null && totalRuns >= target;
  final ended = allOut || oversComplete || targetReached || isDeclared;

  // Precedence: a chase won (target) beats all-out beats overs-exhausted beats
  // a standing declaration.
  final InningsEndReason? reason = targetReached
      ? InningsEndReason.target
      : allOut
          ? InningsEndReason.allOut
          : oversComplete
              ? InningsEndReason.overs
              : isDeclared
                  ? InningsEndReason.declared
                  : null;

  return InningsTermination(
    allOut: allOut,
    oversComplete: oversComplete,
    targetReached: targetReached,
    ended: ended,
    reason: reason,
  );
}

class InningsTermination {
  const InningsTermination({
    required this.allOut,
    required this.oversComplete,
    required this.targetReached,
    required this.ended,
    this.reason,
  });

  final bool allOut;
  final bool oversComplete;
  final bool targetReached;
  final bool ended;
  final InningsEndReason? reason;
}
