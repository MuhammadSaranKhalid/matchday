// Domain entities → engine inputs.
//
// The engine speaks a deliberately minimal contract (see scoring_types.dart):
// no ids beyond the on-field trio, no timestamps, no persistence. This file is
// the one place that translates the app's entities into it, so `applyBall`
// stays pure and the golden vectors stay a complete specification of it.
//
// Everything here is derivation, not rules. If a cricket decision creeps in, it
// belongs in the engine — and therefore in the vectors — not here.
library;

import '../entities/ball.dart';
import '../entities/match.dart';
import '../entities/match_innings_state.dart';
import 'scoring_types.dart';

/// The innings row as the engine sees it. A null row means the innings has not
/// been opened yet; the engine's zeroed defaults are the correct reading.
EngineInningsState engineStateFrom(MatchInningsState? innings) =>
    EngineInningsState(
      strikerId: innings?.strikerId?.value,
      nonStrikerId: innings?.nonStrikerId?.value,
      bowlerId: innings?.bowlerId?.value,
      legalBallCount: innings?.legalBallCount ?? 0,
      totalRuns: innings?.totalRuns ?? 0,
      totalWickets: innings?.totalWickets ?? 0,
      totalExtras: innings?.totalExtras ?? 0,
      isAllOut: innings?.isAllOut ?? false,
      isDeclared: innings?.isDeclared ?? false,
      target: innings?.target,
      version: innings?.version ?? 1,
    );

EngineFormat engineFormatFrom(MatchFormat f) => EngineFormat(
      oversPerInnings: f.oversPerInnings,
      playersPerTeam: f.playersPerTeam,
      ballsPerOver: f.ballsPerOver,
      endChangeBalls: f.endChangeBalls,
      maxOversPerBowler: f.maxOversPerBowler,
      inningsPerSide: f.inningsPerSide,
      ballType: f.ballType.name,
      wicketsToAllOut: f.wicketsToAllOut,
    );

/// The kind of the most recent NON-wide delivery, or null before the first.
///
/// Wides are skipped rather than simply reading the last ball: a wide does not
/// consume a free hit, so a no-ball followed by three wides still leaves the
/// next delivery a free hit.
BallKind? prevNonWideKind(List<Ball> balls) {
  for (final b in balls.reversed) {
    if (b.ballKind == BallKind.wide) continue;
    return b.ballKind;
  }
  return null;
}

/// Legal balls [bowlerId] has already bowled this innings. Drives the
/// per-bowler over cap. Illegal deliveries deliberately do not count.
int bowlerLegalBalls(List<Ball> balls, String? bowlerId) {
  if (bowlerId == null) return 0;
  var n = 0;
  for (final b in balls) {
    if (b.bowlerId == bowlerId && b.isLegalDelivery) n += 1;
  }
  return n;
}

EngineContext engineContextFrom({
  required List<Ball> balls,
  required String? bowlerId,
}) =>
    EngineContext(
      prevNonWideKind: prevNonWideKind(balls),
      bowlerLegalBalls: bowlerLegalBalls(balls, bowlerId),
    );

/// The delivery the scorer entered, as engine input.
EngineBallInput engineInputFrom(BallDraft d) => EngineBallInput(
      isLegalDelivery: d.isLegalDelivery,
      ballKind: d.ballKind,
      runsScored: d.runsScored,
      extras: d.extras,
      isWicket: d.isWicket,
      wicketType: d.wicketType,
      batsmanId: d.batsmanId,
      nonStrikerId: d.nonStrikerId,
      bowlerId: d.bowlerId,
      fielderId: d.fielderId,
      commentary: d.commentary,
    );
