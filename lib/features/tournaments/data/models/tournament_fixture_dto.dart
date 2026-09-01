import '../../../matches/domain/entities/match.dart';
import '../../../teams/domain/entities/team.dart';

/// Wire-format DTO for a match row belonging to a tournament.
class TournamentFixtureDto {
  const TournamentFixtureDto({
    required this.matchId,
    required this.teamAId,
    required this.teamBId,
    required this.status,
    required this.createdAt,
    this.venue,
    this.scheduledStartTime,
    this.actualStartTime,
    this.round,
    this.bracketRoundNumber,
    this.bracketMatchNumber,
    this.prevMatchAId,
    this.prevMatchBId,
    this.format = const {},
    this.createdBy,
  });

  final String matchId;
  final String teamAId;
  final String teamBId;
  final String status;
  final String? venue;
  final String? scheduledStartTime;
  final String? actualStartTime;
  final String? round;
  final int? bracketRoundNumber;
  final int? bracketMatchNumber;
  final String? prevMatchAId;
  final String? prevMatchBId;
  final Map<String, dynamic> format;
  final String? createdBy;
  final String createdAt;

  factory TournamentFixtureDto.fromJson(Map<String, dynamic> json) {
    return TournamentFixtureDto(
      matchId: (json['match_id'] ?? json['id'] ?? '').toString(),
      teamAId: (json['team_a_id'] ?? '').toString(),
      teamBId: (json['team_b_id'] ?? '').toString(),
      status: json['status'] as String? ?? 'scheduled',
      venue: json['venue'] as String?,
      scheduledStartTime: json['scheduled_start_time'] as String?,
      actualStartTime: json['actual_start_time'] as String?,
      round: json['round'] as String?,
      bracketRoundNumber: json['bracket_round_number'] as int?,
      bracketMatchNumber: json['bracket_match_number'] as int?,
      prevMatchAId: json['prev_match_a_id'] as String?,
      prevMatchBId: json['prev_match_b_id'] as String?,
      format: (json['format'] as Map<String, dynamic>?) ??
          (json['rules_config'] as Map<String, dynamic>?) ??
          const {},
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  Match toEntity() {
    DateTime? parseDate(String? s) => s == null ? null : DateTime.tryParse(s);

    return Match(
      id: MatchId(matchId),
      teamAId: TeamId(teamAId),
      teamBId: TeamId(teamBId),
      venue: venue != null ? Venue(ground: venue!) : null,
      scheduledStartTime: parseDate(scheduledStartTime),
      actualStartTime: parseDate(actualStartTime),
      round: round,
      bracketRoundNumber: bracketRoundNumber,
      bracketMatchNumber: bracketMatchNumber,
      prevMatchAId: prevMatchAId,
      prevMatchBId: prevMatchBId,
      status: MatchStatus.fromWire(status),
      matchType: MatchType.tournament,
      format: MatchFormat(
        oversPerInnings: (format['max_overs'] as num?)?.toInt() ??
            (format['overs_per_innings'] as num?)?.toInt() ??
            20,
        playersPerTeam: (format['players_per_team'] as num?)?.toInt() ?? 11,
        ballType: MatchBallType.fromWire(format['ball_type'] as String?),
        maxOversPerBowler: (format['max_overs_per_bowler'] as num?)?.toInt() ?? 4,
      ),
      createdBy: createdBy ?? '',
      createdAt: DateTime.parse(createdAt),
    );
  }
}
