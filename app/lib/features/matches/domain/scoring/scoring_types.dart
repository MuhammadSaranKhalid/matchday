// Data in / data out for the scoring engine.
//
// These mirror `supabase/functions/_shared/scoring/types.ts` field for field,
// deliberately. The engine is the one piece of logic that exists twice — once
// in TypeScript on the server (the authority) and once here — so the shapes
// either match exactly or the shared golden vectors cannot drive both.
//
// They are NOT the domain entities. `Ball`, `MatchInningsState` and friends
// carry ids, timestamps and persistence concerns the engine has no business
// knowing about; mapping between the two is the caller's job, at the edge.
// Keeping the engine's contract minimal is what makes it a pure function.
//
// `BallKind` / `WicketType` ARE reused from the entity layer: their `wire`
// values are already the exact strings the TS engine speaks, and a third
// definition of the same enum would be one more thing to drift.
library;

import '../entities/ball.dart';

/// The current, authoritative state of one innings — as read from
/// `match_innings_state`.
class EngineInningsState {
  const EngineInningsState({
    this.strikerId,
    this.nonStrikerId,
    this.bowlerId,
    this.legalBallCount = 0,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalExtras = 0,
    this.isAllOut = false,
    this.isDeclared = false,
    this.target,
    this.version = 1,
  });

  final String? strikerId;
  final String? nonStrikerId;
  final String? bowlerId;
  final int legalBallCount;
  final int totalRuns;
  final int totalWickets;
  final int totalExtras;
  final bool isAllOut;
  final bool isDeclared;
  final int? target;
  final int version;
}

/// The match format. The engine reads every knob here so it can enforce the
/// rules of any format, not just a 20-over game.
class EngineFormat {
  const EngineFormat({
    this.oversPerInnings = 20,
    this.playersPerTeam = 11,
    this.ballsPerOver = 6,
    this.endChangeBalls,
    this.maxOversPerBowler = 4,
    this.inningsPerSide = 1,
    this.ballType = 'leather',
    this.wicketsToAllOut,
  });

  /// 0 = unlimited (Test / first-class).
  final int oversPerInnings;
  final int playersPerTeam;

  /// 6 standard; 5 (The Hundred / last-man-stands); 8 (indoor).
  final int ballsPerOver;

  /// Balls between END changes (strike swaps). Defaults to [ballsPerOver];
  /// The Hundred uses 10 — ends change every two 5-ball sets.
  final int? endChangeBalls;

  /// 0 = unlimited.
  final int maxOversPerBowler;

  /// 1 limited-overs; 2 Test / first-class.
  final int inningsPerSide;
  final String ballType;

  /// Wickets that end the innings. Defaults to `playersPerTeam - 1` when
  /// unset; 0 disables the all-out check (bespoke models like indoor pairs).
  final int? wicketsToAllOut;
}

/// The raw delivery the scorer recorded.
class EngineBallInput {
  const EngineBallInput({
    this.isLegalDelivery = true,
    this.ballKind = BallKind.legal,
    this.runsScored = 0,
    this.extras = 0,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.batsmanId,
    this.nonStrikerId,
    this.bowlerId,
    this.fielderId,
    this.commentary,
  });

  final bool isLegalDelivery;
  final BallKind ballKind;
  final int runsScored;
  final int extras;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String? batsmanId;
  final String? nonStrikerId;
  final String? bowlerId;
  final String? fielderId;
  final String? commentary;
}

/// Everything the engine needs that is not on the innings row.
class EngineContext {
  const EngineContext({this.prevNonWideKind, this.bowlerLegalBalls = 0});

  /// Kind of the most recent NON-wide delivery in this innings, or null for
  /// the first. Drives free-hit derivation — intervening wides do not consume
  /// a free hit, which is why this skips them rather than reading the last
  /// ball outright.
  final BallKind? prevNonWideKind;

  /// Legal balls the current bowler has already bowled this innings, BEFORE
  /// this delivery. Drives the per-bowler over cap.
  final int bowlerLegalBalls;
}

/// The fully-computed `balls` row to insert.
class ComputedBall {
  const ComputedBall({
    required this.overNumber,
    required this.ballInOver,
    required this.isFreeHit,
    required this.isLegalDelivery,
    required this.ballKind,
    required this.runsScored,
    required this.extras,
    required this.isWicket,
    this.wicketType,
    this.dismissedPlayerId,
    this.batsmanId,
    this.nonStrikerId,
    this.bowlerId,
    this.fielderId,
    this.commentary,
  });

  final int overNumber;

  /// 1-based within the over for legal deliveries; **0 for wides and
  /// no-balls**, which is a sentinel meaning "this one did not count", not a
  /// ball number. Display code must not print it as one.
  final int ballInOver;

  final bool isFreeHit;
  final bool isLegalDelivery;
  final BallKind ballKind;
  final int runsScored;
  final int extras;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String? batsmanId;
  final String? nonStrikerId;
  final String? bowlerId;
  final String? fielderId;
  final String? commentary;
}

/// The new `match_innings_state` values to write.
class NewInningsState {
  const NewInningsState({
    required this.legalBallCount,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalExtras,
    this.strikerId,
    this.nonStrikerId,
    this.bowlerId,
  });

  final int legalBallCount;
  final int totalRuns;
  final int totalWickets;
  final int totalExtras;
  final String? strikerId;
  final String? nonStrikerId;
  final String? bowlerId;
}

/// Why an innings ended — the primary reason, by the precedence in the engine.
enum InningsEndReason {
  allOut('all_out'),
  overs('overs'),
  target('target'),
  declared('declared');

  const InningsEndReason(this.wire);
  final String wire;
}

class InningsEvents {
  const InningsEvents({
    required this.overEnded,
    required this.allOut,
    required this.oversComplete,
    required this.targetReached,
    required this.inningsEnded,
    this.inningsEndReason,
  });

  /// A set/over boundary was reached, so a new bowler is owed. Distinct from
  /// an end change — in The Hundred these are not the same ball.
  final bool overEnded;
  final bool allOut;
  final bool oversComplete;
  final bool targetReached;
  final bool inningsEnded;
  final InningsEndReason? inningsEndReason;
}

/// A rejection from the engine. [code] is stable and matches the TypeScript
/// engine's codes exactly — the vectors assert on it.
class EngineError {
  const EngineError(this.code, this.message);
  final String code;
  final String message;
}

/// The outcome of applying one delivery: either a rejection, or the ball, the
/// new innings state, and what it triggered.
class BallResult {
  const BallResult.ok({
    required ComputedBall this.ball,
    required NewInningsState this.newState,
    required InningsEvents this.events,
  }) : ok = true,
       error = null;

  const BallResult.failure(EngineError this.error)
    : ok = false,
      ball = null,
      newState = null,
      events = null;

  final bool ok;
  final EngineError? error;
  final ComputedBall? ball;
  final NewInningsState? newState;
  final InningsEvents? events;
}
