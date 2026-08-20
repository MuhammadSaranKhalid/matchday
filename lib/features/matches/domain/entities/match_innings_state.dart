import 'package:equatable/equatable.dart';

import 'match.dart';
import 'match_player.dart';

/// The live, scorer-mutated state for one innings of one match.
///
/// Backed by the `match_innings_state` table. One row per
/// (matchId, inningsNumber). Carries:
///
///   • the on-field trio (striker, non-striker, bowler) as match_player
///     ids — unclaimed players are first-class;
///   • denormalised running totals (legal balls bowled, runs, wickets,
///     extras) — the scoreboard reads these directly, no aggregate over
///     balls per render;
///   • the optimistic-lock `version` counter — record_ball passes the
///     last-seen value back to the RPC, which rejects with 40001 if a
///     co-scorer has advanced the row in the meantime.
///
/// Distinct from [Match]: [Match] is the metadata row (teams, format,
/// status, captains). Live scoring writes go here, not there, so
/// spectators reading match metadata don't contend with the scorer.
class MatchInningsState extends Equatable {
  const MatchInningsState({
    required this.matchId,
    required this.inningsNumber,
    required this.version,
    required this.updatedAt,
    this.strikerId,
    this.nonStrikerId,
    this.bowlerId,
    this.legalBallCount = 0,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalExtras = 0,
    this.isDeclared = false,
    this.isAllOut = false,
    this.target,
  });

  /// Which match this innings belongs to.
  final MatchId matchId;

  /// 1, 2, 3 (super-over), or 4 (rare — Tests / declared chase).
  final int inningsNumber;

  /// Match-player-id of the on-strike batter. NULL between innings,
  /// after a wicket until the next batter is picked, or pre-toss.
  final MatchPlayerId? strikerId;

  /// Match-player-id of the off-strike batter.
  final MatchPlayerId? nonStrikerId;

  /// Match-player-id of the current bowler. NULL at the end of every
  /// over until the next bowler is picked.
  final MatchPlayerId? bowlerId;

  /// Number of legal deliveries bowled in this innings. Divides by 6 to
  /// get completed overs; modulo 6 gives the ball in the current over.
  /// Derived from the ledger but materialised here so the scoreboard
  /// (and record_ball) doesn't have to SUM-scan balls.
  final int legalBallCount;

  /// Team total runs for this innings (batter runs + extras).
  final int totalRuns;

  /// Wickets fallen this innings.
  final int totalWickets;

  /// Extras (wides, no-balls, byes, leg-byes, penalty) for this innings.
  final int totalExtras;

  /// True once the batting captain declared (Tests / multi-day).
  final bool isDeclared;

  /// True when the 10th wicket has fallen.
  final bool isAllOut;

  /// Chase target. NULL for innings 1; set for the chase once the
  /// first-innings result is final.
  final int? target;

  /// Optimistic-concurrency counter. Bumped on every write by the
  /// scoring RPCs (record_ball, undo_last_ball, start_innings,
  /// submit_match_openers). Pass back into record_ball as
  /// p_expected_version to detect co-scorer races.
  final int version;

  final DateTime updatedAt;

  /// A copy with fields replaced.
  ///
  /// The three on-field ids need explicit `clear*` flags rather than plain
  /// nullable parameters: null is a MEANINGFUL value for each of them — a
  /// wicket clears the striker, the end of an over clears the bowler — and
  /// `id ?? this.id` cannot express "set this to null" at all. Without the
  /// flags a projected wicket would silently keep the dismissed batter at the
  /// crease.
  MatchInningsState copyWith({
    MatchPlayerId? strikerId,
    bool clearStriker = false,
    MatchPlayerId? nonStrikerId,
    bool clearNonStriker = false,
    MatchPlayerId? bowlerId,
    bool clearBowler = false,
    int? legalBallCount,
    int? totalRuns,
    int? totalWickets,
    int? totalExtras,
    bool? isDeclared,
    bool? isAllOut,
    int? target,
    int? version,
    DateTime? updatedAt,
  }) =>
      MatchInningsState(
        matchId: matchId,
        inningsNumber: inningsNumber,
        version: version ?? this.version,
        updatedAt: updatedAt ?? this.updatedAt,
        strikerId: clearStriker ? null : (strikerId ?? this.strikerId),
        nonStrikerId:
            clearNonStriker ? null : (nonStrikerId ?? this.nonStrikerId),
        bowlerId: clearBowler ? null : (bowlerId ?? this.bowlerId),
        legalBallCount: legalBallCount ?? this.legalBallCount,
        totalRuns: totalRuns ?? this.totalRuns,
        totalWickets: totalWickets ?? this.totalWickets,
        totalExtras: totalExtras ?? this.totalExtras,
        isDeclared: isDeclared ?? this.isDeclared,
        isAllOut: isAllOut ?? this.isAllOut,
        target: target ?? this.target,
      );

  /// Completed overs as a decimal number — 19 + 4/6 ≈ 19.67. Useful for
  /// NRR / target calculations.
  double get oversDecimal => legalBallCount / 6.0;

  /// Cricket-overs notation — "19.4" means 19 complete overs and 4
  /// legal deliveries in the 20th.
  String get oversText {
    final completed = legalBallCount ~/ 6;
    final inOver = legalBallCount % 6;
    return '$completed.$inOver';
  }

  /// True when no more legal deliveries can be added — all-out or
  /// declared.
  bool get isClosed => isAllOut || isDeclared;

  @override
  List<Object?> get props => [
        matchId,
        inningsNumber,
        strikerId,
        nonStrikerId,
        bowlerId,
        legalBallCount,
        totalRuns,
        totalWickets,
        totalExtras,
        isDeclared,
        isAllOut,
        target,
        version,
        updatedAt,
      ];
}
