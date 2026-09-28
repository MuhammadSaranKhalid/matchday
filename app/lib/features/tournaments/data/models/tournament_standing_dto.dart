import '../../domain/entities/tournament_standing.dart';

/// Wire-format DTO for `public.tournament_standings` rows.
class TournamentStandingDto {
  const TournamentStandingDto({
    required this.tournamentId,
    required this.teamId,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.noResults,
    required this.points,
    required this.runsScored,
    required this.oversFaced,
    required this.runsConceded,
    required this.oversBowled,
    required this.netRunRate,
    required this.updatedAt,
    this.groupId,
    this.teamName,
    this.teamLogoUrl,
    this.teamMonogram,
    this.teamPrimaryColor,
  });

  final String tournamentId;
  final String teamId;
  final String? groupId;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int ties;
  final int noResults;
  final int points;
  final int runsScored;
  final num oversFaced;
  final int runsConceded;
  final num oversBowled;
  final num netRunRate;
  final String updatedAt;
  final String? teamName;
  final String? teamLogoUrl;
  final String? teamMonogram;
  final String? teamPrimaryColor;

  factory TournamentStandingDto.fromJson(Map<String, dynamic> json) {
    final teamJson = json['teams'] as Map<String, dynamic>?;
    final teamColors = teamJson?['team_colors'] as Map<String, dynamic>?;

    return TournamentStandingDto(
      tournamentId: json['tournament_id'] as String,
      teamId: json['team_id'] as String,
      groupId: json['group_id'] as String?,
      matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      ties: (json['ties'] as num?)?.toInt() ?? 0,
      noResults: (json['no_results'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      runsScored: (json['runs_scored'] as num?)?.toInt() ?? 0,
      oversFaced: json['overs_faced'] as num? ?? 0.0,
      runsConceded: (json['runs_conceded'] as num?)?.toInt() ?? 0,
      oversBowled: json['overs_bowled'] as num? ?? 0.0,
      netRunRate: json['net_run_rate'] as num? ?? 0.0,
      updatedAt: json['updated_at'] as String? ??
          DateTime.now().toIso8601String(),
      teamName: teamJson?['team_name'] as String?,
      teamLogoUrl: teamJson?['logo_url'] as String?,
      teamMonogram: teamJson?['logo_monogram'] as String?,
      teamPrimaryColor: teamColors?['primary'] as String?,
    );
  }

  TournamentStanding toEntity({int rank = 0}) {
    return TournamentStanding(
      tournamentId: tournamentId,
      teamId: teamId,
      groupId: groupId,
      matchesPlayed: matchesPlayed,
      wins: wins,
      losses: losses,
      ties: ties,
      noResults: noResults,
      points: points,
      runsScored: runsScored,
      oversFaced: oversFaced.toDouble(),
      runsConceded: runsConceded,
      oversBowled: oversBowled.toDouble(),
      netRunRate: netRunRate.toDouble(),
      updatedAt: DateTime.parse(updatedAt),
      teamName: teamName,
      teamLogoUrl: teamLogoUrl,
      teamMonogram: teamMonogram,
      teamPrimaryColor: teamPrimaryColor,
      rank: rank,
    );
  }
}
