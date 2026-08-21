import 'package:equatable/equatable.dart';

/// One match in Explore — a search hit or a card in the live rail.
///
/// A search projection over `matches` + both teams + the latest innings, not
/// the full [Match] entity (which carries squads, format, officials and the
/// start-phase machine that no list row renders).
class MatchResult extends Equatable {
  const MatchResult({
    required this.matchId,
    required this.status,
    this.venue,
    this.tournamentName,
    this.scheduledStartTime,
    this.actualStartTime,
    this.teamAId,
    this.teamAName,
    this.teamAColor,
    this.teamALogoUrl,
    this.teamBId,
    this.teamBName,
    this.teamBColor,
    this.teamBLogoUrl,
    this.inningsNumber,
    this.totalRuns,
    this.totalWickets,
    this.legalBallCount,
    this.target,
    this.battingTeamId,
  });

  final String matchId;

  /// Raw `match_status` value: scheduled · toss · live · innings_break ·
  /// super_over · completed · abandoned · rescheduled.
  final String status;

  final String? venue;
  final String? tournamentName;
  final DateTime? scheduledStartTime;
  final DateTime? actualStartTime;

  final String? teamAId;
  final String? teamAName;
  final String? teamAColor;
  final String? teamALogoUrl;

  final String? teamBId;
  final String? teamBName;
  final String? teamBColor;
  final String? teamBLogoUrl;

  // ── Latest innings ─────────────────────────────────────────────────────────
  final int? inningsNumber;
  final int? totalRuns;
  final int? totalWickets;
  final int? legalBallCount;
  final int? target;

  /// Which side the [totalRuns] belong to. Derived server-side from the toss
  /// (`match_innings_state` stores no batting-team column). Null until the
  /// toss is recorded — in which case there is no score to attribute anyway.
  final String? battingTeamId;

  /// Live in the "show a pulsing red pill" sense — includes the break states,
  /// because a match at innings break is still an in-progress match a
  /// spectator wants to open.
  bool get isLive =>
      status == 'live' || status == 'innings_break' || status == 'super_over';

  bool get isCompleted => status == 'completed';

  /// "127/4". Null when no innings has started.
  String? get scoreLine {
    if (totalRuns == null) return null;
    return '$totalRuns/${totalWickets ?? 0}';
  }

  /// "8.3" — cricket overs are `completed.ballsIntoOver`, six balls to an
  /// over, so this is integer division and remainder, never a decimal.
  String? get oversLine {
    final balls = legalBallCount;
    if (balls == null) return null;
    return '${balls ~/ 6}.${balls % 6}';
  }

  /// "Lahore Lions v Gulberg Giants", with a placeholder for a side that has
  /// not been decided yet (bracket matches await a previous result).
  String get title =>
      '${teamAName ?? 'TBD'} v ${teamBName ?? 'TBD'}';

  /// True when [teamAId] is the side currently batting, so the row can bold
  /// the right name. False when unknown — never guesses.
  bool get isTeamABatting =>
      battingTeamId != null && battingTeamId == teamAId;

  @override
  List<Object?> get props => [
        matchId,
        status,
        venue,
        tournamentName,
        scheduledStartTime,
        actualStartTime,
        teamAId,
        teamAName,
        teamAColor,
        teamALogoUrl,
        teamBId,
        teamBName,
        teamBColor,
        teamBLogoUrl,
        inningsNumber,
        totalRuns,
        totalWickets,
        legalBallCount,
        target,
        battingTeamId,
      ];
}
