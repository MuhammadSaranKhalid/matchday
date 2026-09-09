import 'package:equatable/equatable.dart';

import '../entities/ball.dart';
import '../entities/match_player.dart';
import '../entities/match_wicket.dart';

/// Derives a full innings card from the delivery ledger.
///
/// There are no aggregate stats tables — `match_batsman_stats` and
/// `match_bowler_stats` were dropped on 2026-09-06 because nothing had written
/// them since the SQL scoring engine was removed. Every number on the completed
/// match screen is computed here, from the same deliveries the scoring device
/// appended. That keeps one source of truth: if a figure looks wrong, the ball
/// that made it is in the Overs tab.
///
/// Pure Dart, no I/O — the same rule the scoring engine follows.
class InningsCard extends Equatable {
  const InningsCard({
    required this.inningsNumber,
    required this.battingTeamSide,
    required this.batting,
    required this.bowling,
    required this.extras,
    required this.fallOfWickets,
    required this.partnerships,
    required this.runsPerOver,
    required this.balls,
    required this.totalRuns,
    required this.wickets,
    required this.legalBalls,
    required this.ballsPerOver,
    this.didNotBat = const [],
  });

  final int inningsNumber;
  final String battingTeamSide;
  final List<BattingLine> batting;
  final List<BowlingLine> bowling;
  final ExtrasBreakdown extras;
  final List<FallOfWicket> fallOfWickets;
  final List<Partnership> partnerships;

  /// Index 0 = over 1. Drives the Manhattan and, cumulatively, the worm.
  final List<int> runsPerOver;

  /// The deliveries this card was built from, oldest-first. The Overs tab is
  /// another view of the same innings, and re-fetching them for it would read
  /// the whole ledger a second time.
  final List<Ball> balls;

  final int totalRuns;
  final int wickets;
  final int legalBalls;
  final int ballsPerOver;

  /// Named, in one line, under the batting card — the tail that never came in.
  final List<String> didNotBat;


  /// "15.1" — completed overs and the balls into the next.
  String get oversLabel =>
      '${legalBalls ~/ ballsPerOver}.${legalBalls % ballsPerOver}';

  double get runRate {
    if (legalBalls == 0) return 0;
    return totalRuns / (legalBalls / ballsPerOver);
  }

  /// Boundary and dot counts for the Stats tab. Derived from the lines rather
  /// than re-walked from the ledger so the tab can never disagree with the
  /// card printed one tab to its left.
  int get fours => batting.fold(0, (a, b) => a + b.fours);
  int get sixes => batting.fold(0, (a, b) => a + b.sixes);
  int get dots => bowling.fold(0, (a, b) => a + b.dots);

  /// Runs off the bat that were neither a four nor a six — the third band of
  /// "where the runs came from". Extras are shown separately, so they are not
  /// folded in here.
  int get runsInOnesAndTwos =>
      batting.fold(0, (a, b) => a + b.runs - b.fours * 4 - b.sixes * 6);

  /// Running total after each over — the worm.
  List<int> get cumulativeRuns {
    var running = 0;
    return [
      for (final o in runsPerOver) running += o,
    ];
  }

  @override
  List<Object?> get props => [inningsNumber, totalRuns, wickets, legalBalls];
}

class BattingLine extends Equatable {
  const BattingLine({
    required this.playerId,
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.isOut,
    required this.dismissal,
    this.batted = true,
  });

  final String playerId;
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;

  /// "c Ali b Khan", "b Khan", "run out (Ali)", "not out", "retired hurt".
  final String dismissal;

  /// False for a player who never faced a ball and was never dismissed.
  final bool batted;

  double get strikeRate => balls > 0 ? (runs * 100.0) / balls : 0;

  @override
  List<Object?> get props => [playerId, runs, balls, isOut];
}

class BowlingLine extends Equatable {
  const BowlingLine({
    required this.playerId,
    required this.name,
    required this.legalBalls,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.wides,
    required this.noBalls,
    required this.dots,
    required this.ballsPerOver,
  });

  final String playerId;
  final String name;
  final int legalBalls;
  final int maidens;
  final int runs;
  final int wickets;
  final int wides;
  final int noBalls;
  final int dots;
  final int ballsPerOver;

  String get oversLabel =>
      '${legalBalls ~/ ballsPerOver}.${legalBalls % ballsPerOver}';

  double get economy {
    if (legalBalls == 0) return 0;
    return runs / (legalBalls / ballsPerOver);
  }

  @override
  List<Object?> get props => [playerId, legalBalls, runs, wickets];
}

class ExtrasBreakdown extends Equatable {
  const ExtrasBreakdown({
    this.byes = 0,
    this.legByes = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.penalties = 0,
  });

  final int byes;
  final int legByes;
  final int wides;
  final int noBalls;
  final int penalties;

  int get total => byes + legByes + wides + noBalls + penalties;

  /// "b 4 · lb 2 · w 7 · nb 1" — only the kinds that actually occurred.
  String get label {
    final parts = <String>[
      if (byes > 0) 'b $byes',
      if (legByes > 0) 'lb $legByes',
      if (wides > 0) 'w $wides',
      if (noBalls > 0) 'nb $noBalls',
      if (penalties > 0) 'p $penalties',
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  @override
  List<Object?> get props => [byes, legByes, wides, noBalls, penalties];
}

class FallOfWicket extends Equatable {
  const FallOfWicket({
    required this.number,
    required this.score,
    required this.overs,
    required this.playerName,
  });

  final int number;
  final int score;
  final double overs;
  final String playerName;

  /// "1-12 (Ali, 2.3)" — the classic sequence.
  String get label =>
      '$number-$score ($playerName, ${overs.toStringAsFixed(1)})';

  @override
  List<Object?> get props => [number, score, overs];
}

/// A stand, anchored to the innings' own timeline: where it began, what it made
/// and which wicket ended it. Without a wagon wheel there is no geography to
/// hang partnerships on, so they hang on the score instead.
class Partnership extends Equatable {
  const Partnership({
    required this.wicketNumber,
    required this.runs,
    required this.balls,
    required this.startedAtScore,
    required this.strikerName,
    required this.strikerRuns,
    required this.nonStrikerName,
    required this.nonStrikerRuns,
    required this.unbroken,
    this.endedAtOvers,
  });

  /// The wicket that ended it — 1 for the opening stand. An unbroken stand
  /// carries the number it *would* have been.
  final int wicketNumber;
  final int runs;
  final int balls;
  final int startedAtScore;
  final String strikerName;
  final int strikerRuns;
  final String nonStrikerName;
  final int nonStrikerRuns;

  /// Drawn with an open right edge — nobody got them out.
  final bool unbroken;

  /// Overs at which the stand ended, null while unbroken.
  final double? endedAtOvers;

  /// Score the stand finished on.
  int get endedAtScore => startedAtScore + runs;

  /// "12 → 48 · ended 2-48 (6.1)" — anchored to the score, so a collapse
  /// reads as a cliff rather than as a list of numbers.
  String get label {
    final span = '$startedAtScore → $endedAtScore';
    if (unbroken) return '$span · unbroken';
    final at = endedAtOvers == null
        ? ''
        : ' (${endedAtOvers!.toStringAsFixed(1)})';
    return '$span · ended $wicketNumber-$endedAtScore$at';
  }

  @override
  List<Object?> get props => [wicketNumber, runs, balls, unbroken];
}

// ─── Derivation ─────────────────────────────────────────────────────────────

/// Build one innings card. [balls] must be this innings only, oldest first.
InningsCard buildInningsCard({
  required int inningsNumber,
  required String battingTeamSide,
  required List<Ball> balls,
  required List<MatchWicket> wickets,
  required List<MatchPlayer> squad,
  required int ballsPerOver,
}) {
  final nameOf = <String, String>{
    for (final p in squad) p.id.value: p.displayName,
  };
  String name(String? id) => id == null ? 'Unknown' : (nameOf[id] ?? 'Unknown');

  // ── Totals ────────────────────────────────────────────────────────────────
  var totalRuns = 0;
  var legalBalls = 0;
  final extrasByKind = <BallKind, int>{};
  for (final b in balls) {
    totalRuns += b.runsScored + b.extras;
    if (b.isLegalDelivery) legalBalls++;
    if (b.extras > 0 && b.ballKind != BallKind.legal) {
      extrasByKind[b.ballKind] = (extrasByKind[b.ballKind] ?? 0) + b.extras;
    }
  }

  final extras = ExtrasBreakdown(
    byes: extrasByKind[BallKind.bye] ?? 0,
    legByes: extrasByKind[BallKind.legBye] ?? 0,
    wides: extrasByKind[BallKind.wide] ?? 0,
    noBalls: extrasByKind[BallKind.noBall] ?? 0,
  );

  // ── Batting ───────────────────────────────────────────────────────────────
  // Order of appearance at the crease is the batting order the ledger knows;
  // match_players.battingOrder is only a plan and may never have been followed.
  final seen = <String>[];
  final runsBy = <String, int>{};
  final ballsBy = <String, int>{};
  final foursBy = <String, int>{};
  final sixesBy = <String, int>{};

  for (final b in balls) {
    final striker = b.batsmanId;
    if (striker == null) continue;
    if (!seen.contains(striker)) seen.add(striker);
    if (b.nonStrikerId != null && !seen.contains(b.nonStrikerId!)) {
      seen.add(b.nonStrikerId!);
    }
    runsBy[striker] = (runsBy[striker] ?? 0) + b.runsScored;
    // A wide is not a ball faced; everything else is.
    if (b.ballKind != BallKind.wide) {
      ballsBy[striker] = (ballsBy[striker] ?? 0) + 1;
    }
    if (b.runsScored == 4) foursBy[striker] = (foursBy[striker] ?? 0) + 1;
    if (b.runsScored == 6) sixesBy[striker] = (sixesBy[striker] ?? 0) + 1;
  }

  final wicketByPlayer = {for (final w in wickets) w.playerOutId: w};

  final batting = <BattingLine>[
    for (final id in seen)
      BattingLine(
        playerId: id,
        name: name(id),
        runs: runsBy[id] ?? 0,
        balls: ballsBy[id] ?? 0,
        fours: foursBy[id] ?? 0,
        sixes: sixesBy[id] ?? 0,
        isOut: wicketByPlayer.containsKey(id),
        dismissal: _dismissalText(wicketByPlayer[id], name),
      ),
  ];

  // Everyone in the squad on this side who never came in.
  final didNotBat = [
    for (final p in squad)
      if (!seen.contains(p.id.value) && p.teamSide.wire == battingTeamSide)
        p.displayName,
  ];

  // ── Bowling ───────────────────────────────────────────────────────────────
  final bowlOrder = <String>[];
  final bLegal = <String, int>{};
  final bRuns = <String, int>{};
  final bWkts = <String, int>{};
  final bWides = <String, int>{};
  final bNoBalls = <String, int>{};
  final bDots = <String, int>{};
  // Runs conceded per over, per bowler, so maidens can be counted.
  final overRuns = <String, Map<int, int>>{};

  for (final b in balls) {
    final id = b.bowlerId;
    if (id == null) continue;
    if (!bowlOrder.contains(id)) bowlOrder.add(id);
    if (b.isLegalDelivery) bLegal[id] = (bLegal[id] ?? 0) + 1;

    // Byes and leg-byes are not charged to the bowler; wides and no-balls are.
    final charged = b.runsScored +
        (b.ballKind == BallKind.bye || b.ballKind == BallKind.legBye
            ? 0
            : b.extras);
    bRuns[id] = (bRuns[id] ?? 0) + charged;

    if (b.ballKind == BallKind.wide) bWides[id] = (bWides[id] ?? 0) + 1;
    if (b.ballKind == BallKind.noBall) bNoBalls[id] = (bNoBalls[id] ?? 0) + 1;
    if (b.isLegalDelivery && b.runsScored == 0 && b.extras == 0) {
      bDots[id] = (bDots[id] ?? 0) + 1;
    }
    (overRuns[id] ??= {})[b.overNumber] =
        (overRuns[id]?[b.overNumber] ?? 0) + charged;
  }

  // A wicket counts to the bowler only when the dismissal credits one — a run
  // out does not.
  for (final w in wickets) {
    if (!w.isBowlerCredited) continue;
    final id = w.creditedBowlerId;
    if (id == null) continue;
    bWkts[id] = (bWkts[id] ?? 0) + 1;
  }

  final bowling = <BowlingLine>[
    for (final id in bowlOrder)
      BowlingLine(
        playerId: id,
        name: name(id),
        legalBalls: bLegal[id] ?? 0,
        // A maiden is a COMPLETE over that cost nothing.
        maidens: (overRuns[id] ?? {}).entries.where((e) {
          final legalInOver = balls
              .where((b) =>
                  b.bowlerId == id && b.overNumber == e.key && b.isLegalDelivery)
              .length;
          return e.value == 0 && legalInOver >= ballsPerOver;
        }).length,
        runs: bRuns[id] ?? 0,
        wickets: bWkts[id] ?? 0,
        wides: bWides[id] ?? 0,
        noBalls: bNoBalls[id] ?? 0,
        dots: bDots[id] ?? 0,
        ballsPerOver: ballsPerOver,
      ),
  ];

  // ── Fall of wickets ───────────────────────────────────────────────────────
  final fow = [
    for (final w in (wickets.toList()
      ..sort((a, b) => a.fallOfWicketNumber.compareTo(b.fallOfWicketNumber))))
      FallOfWicket(
        number: w.fallOfWicketNumber,
        score: w.fallOfWicketScore,
        overs: w.fallOfWicketOvers,
        playerName: name(w.playerOutId),
      ),
  ];

  // ── Runs per over ─────────────────────────────────────────────────────────
  final perOver = <int, int>{};
  for (final b in balls) {
    perOver[b.overNumber] = (perOver[b.overNumber] ?? 0) + b.runsScored + b.extras;
  }
  final maxOver = perOver.keys.isEmpty
      ? -1
      : perOver.keys.reduce((a, b) => a > b ? a : b);
  final runsPerOver = [for (var o = 0; o <= maxOver; o++) perOver[o] ?? 0];

  return InningsCard(
    inningsNumber: inningsNumber,
    battingTeamSide: battingTeamSide,
    batting: batting,
    bowling: bowling,
    extras: extras,
    fallOfWickets: fow,
    partnerships: _partnerships(balls, wickets, name),
    runsPerOver: runsPerOver,
    balls: balls,
    totalRuns: totalRuns,
    wickets: wickets.length,
    legalBalls: legalBalls,
    ballsPerOver: ballsPerOver,
    didNotBat: didNotBat,
  );
}

/// "c Ali b Khan" / "b Khan" / "run out (Ali)" / "lbw b Khan" / "not out".
String _dismissalText(MatchWicket? w, String Function(String?) name) {
  if (w == null) return 'not out';
  final bowler = name(w.creditedBowlerId);
  final fielder = w.primaryFielderId == null ? null : name(w.primaryFielderId);
  switch (w.dismissalKind) {
    case 'bowled':
      return 'b $bowler';
    case 'caught':
      return 'c ${fielder ?? '?'} b $bowler';
    case 'caught_and_bowled':
      return 'c & b $bowler';
    case 'lbw':
      return 'lbw b $bowler';
    case 'stumped':
      return 'st ${fielder ?? '?'} b $bowler';
    case 'run_out':
      return fielder == null ? 'run out' : 'run out ($fielder)';
    case 'hit_wicket':
      return 'hit wicket b $bowler';
    case 'retired_hurt':
      return 'retired hurt';
    case 'retired_out':
      return 'retired out';
    case 'obstructing_the_field':
      return 'obstructing the field';
    case 'timed_out':
      return 'timed out';
    case 'handled_the_ball':
      return 'handled the ball';
    default:
      return w.dismissalKind.replaceAll('_', ' ');
  }
}

/// Split the innings at each wicket. The runs a stand made are the difference
/// between the scores it began and ended at, which is what the fall-of-wickets
/// sequence already records.
List<Partnership> _partnerships(
  List<Ball> balls,
  List<MatchWicket> wickets,
  String Function(String?) name,
) {
  if (balls.isEmpty) return const [];
  final sorted = wickets.toList()
    ..sort((a, b) => a.fallOfWicketNumber.compareTo(b.fallOfWicketNumber));

  final out = <Partnership>[];
  var startScore = 0;
  var startIndex = 0;
  var running = 0;

  // Walk the ledger once, closing a stand each time the running total reaches
  // the next fall-of-wicket score.
  var w = 0;
  for (var i = 0; i < balls.length; i++) {
    running += balls[i].runsScored + balls[i].extras;
    final isEnd = w < sorted.length && balls[i].isWicket;
    if (!isEnd) continue;

    final segment = balls.sublist(startIndex, i + 1);
    out.add(_stand(
      wicketNumber: sorted[w].fallOfWicketNumber,
      segment: segment,
      startedAtScore: startScore,
      runs: running - startScore,
      unbroken: false,
      name: name,
      endedAtOvers: sorted[w].fallOfWicketOvers,
    ));
    startScore = running;
    startIndex = i + 1;
    w++;
  }

  // Whatever is left is unbroken — nobody got them out.
  if (startIndex < balls.length) {
    final segment = balls.sublist(startIndex);
    out.add(_stand(
      wicketNumber: out.length + 1,
      segment: segment,
      startedAtScore: startScore,
      runs: running - startScore,
      unbroken: true,
      name: name,
    ));
  }
  return out;
}

Partnership _stand({
  required int wicketNumber,
  required List<Ball> segment,
  required int startedAtScore,
  required int runs,
  required bool unbroken,
  required String Function(String?) name,
  double? endedAtOvers,
}) {
  final byPlayer = <String, int>{};
  for (final b in segment) {
    final id = b.batsmanId;
    if (id == null) continue;
    byPlayer[id] = (byPlayer[id] ?? 0) + b.runsScored;
  }
  final ids = byPlayer.keys.toList();
  return Partnership(
    wicketNumber: wicketNumber,
    runs: runs,
    balls: segment.where((b) => b.isLegalDelivery).length,
    startedAtScore: startedAtScore,
    strikerName: ids.isNotEmpty ? name(ids.first) : '—',
    strikerRuns: ids.isNotEmpty ? byPlayer[ids.first]! : 0,
    nonStrikerName: ids.length > 1 ? name(ids[1]) : '—',
    nonStrikerRuns: ids.length > 1 ? byPlayer[ids[1]]! : 0,
    unbroken: unbroken,
    endedAtOvers: endedAtOvers,
  );
}
