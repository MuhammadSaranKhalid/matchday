// The cricket rules that are not the ball engine.
//
// `scoring_engine.dart` answers "what does this delivery do to the innings" and
// is held to the golden vectors in lockstep with the TypeScript engine. This
// file holds the rules that read the ball log AFTER the fact — a batter's
// figures, a bowler's spell — plus the one rule that runs before it: how a
// sheet's single "how many runs" number splits between the batter's score and
// the extras column.
//
// These all used to live on `ScoringState`, in `presentation/state/`. They are
// laws of cricket, not view state: what counts as a ball faced does not change
// because the screen changed. They moved here so that a rule change is a
// domain edit, and so the widgets can be read without the rules in the way.
library;

import 'package:equatable/equatable.dart';

import '../entities/ball.dart';

/// A batter's contribution so far this innings.
class BatterStats extends Equatable {
  const BatterStats({
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
  });

  final int runs;
  final int balls;
  final int fours;
  final int sixes;

  double get strikeRate => balls > 0 ? (runs * 100.0) / balls : 0.0;

  static const none = BatterStats();

  @override
  List<Object?> get props => [runs, balls, fours, sixes];
}

/// A bowler's spell so far this innings.
class BowlerSpell extends Equatable {
  const BowlerSpell({
    this.overs = 0,
    this.ballsThisOver = 0,
    this.maidens = 0,
    this.runs = 0,
    this.wickets = 0,
  });

  final int overs;
  final int ballsThisOver;
  final int maidens;
  final int runs;
  final int wickets;

  double get economy => (overs + (ballsThisOver / 6.0)) > 0
      ? runs / (overs + (ballsThisOver / 6.0))
      : 0.0;

  static const none = BowlerSpell();

  @override
  List<Object?> get props => [overs, ballsThisOver, maidens, runs, wickets];
}

/// Current partnership stats between the two active batters.
class PartnershipStats extends Equatable {
  const PartnershipStats({
    this.runs = 0,
    this.balls = 0,
  });

  final int runs;
  final int balls;

  static const none = PartnershipStats();

  @override
  List<Object?> get props => [runs, balls];
}

/// How a delivery's runs split between the batter's score and the extras
/// column.
///
/// This is the rule the wide bug lived in. A wide is a penalty against the
/// bowling side: nothing off it ever reaches the batter, including runs the
/// batters then run. A no-ball carries a 1-run penalty but runs off the bat
/// are the batter's. Byes and leg-byes are all extras.
({int runsScored, int extras}) splitExtraRuns(BallKind kind, int runs) =>
    switch (kind) {
      BallKind.wide => (runsScored: 0, extras: 1 + runs),
      BallKind.noBall => (runsScored: runs, extras: 1),
      BallKind.bye || BallKind.legBye => (runsScored: 0, extras: runs),
      BallKind.legal => (runsScored: runs, extras: 0),
    };

/// Whether a dismissal is credited to the bowler. Run-outs and the like are
/// not.
bool creditedToBowler(WicketType? kind) => switch (kind) {
      null => false,
      WicketType.runOut ||
      WicketType.obstructing ||
      WicketType.handledBall ||
      WicketType.retiredHurt ||
      WicketType.timedOut =>
        false,
      _ => true,
    };

/// [matchPlayerId]'s figures from the deliveries they faced.
BatterStats batterStatsFor(List<Ball> balls, String? matchPlayerId) {
  if (matchPlayerId == null) return BatterStats.none;
  var runs = 0, faced = 0, fours = 0, sixes = 0;
  for (final b in balls) {
    if (b.batsmanId != matchPlayerId) continue;
    runs += b.runsScored;
    if (b.isLegalDelivery &&
        b.ballKind != BallKind.bye &&
        b.ballKind != BallKind.legBye) {
      faced += 1;
    }
    if (b.ballKind == BallKind.legal && b.runsScored == 4) fours += 1;
    if (b.ballKind == BallKind.legal && b.runsScored == 6) sixes += 1;
  }
  return BatterStats(runs: runs, balls: faced, fours: fours, sixes: sixes);
}

/// [matchPlayerId]'s spell from the deliveries they bowled.
BowlerSpell bowlerSpellFor(
  List<Ball> balls,
  String? matchPlayerId, {
  required int ballsPerOver,
}) {
  if (matchPlayerId == null) return BowlerSpell.none;
  var legal = 0, conceded = 0, wickets = 0;

  final overRuns = <int, int>{};
  final overLegals = <int, int>{};

  for (final b in balls) {
    if (b.bowlerId != matchPlayerId) continue;
    if (b.isLegalDelivery) {
      legal += 1;
      overLegals[b.overNumber] = (overLegals[b.overNumber] ?? 0) + 1;
    }
    // Byes and leg-byes are not charged to the bowler.
    final chargeable =
        b.ballKind != BallKind.bye && b.ballKind != BallKind.legBye;
    final r = b.runsScored + (chargeable ? b.extras : 0);
    conceded += r;
    overRuns[b.overNumber] = (overRuns[b.overNumber] ?? 0) + r;
    if (b.isWicket && creditedToBowler(b.wicketType)) wickets += 1;
  }

  var maidens = 0;
  for (final entry in overLegals.entries) {
    if (entry.value >= ballsPerOver && (overRuns[entry.key] ?? 0) == 0) {
      maidens += 1;
    }
  }

  return BowlerSpell(
    overs: legal ~/ ballsPerOver,
    ballsThisOver: legal % ballsPerOver,
    maidens: maidens,
    runs: conceded,
    wickets: wickets,
  );
}

/// Current partnership stats between the two active batters.
PartnershipStats currentPartnershipFor(
  List<Ball> balls,
  String? strikerId,
  String? nonStrikerId,
) {
  if (strikerId == null || nonStrikerId == null) return PartnershipStats.none;
  var runs = 0, legalCount = 0;
  for (final b in balls.reversed) {
    if (b.isWicket) break;
    runs += b.totalRuns;
    if (b.isLegalDelivery) legalCount += 1;
  }
  return PartnershipStats(runs: runs, balls: legalCount);
}
