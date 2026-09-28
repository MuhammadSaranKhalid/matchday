import 'package:meta/meta.dart';

/// A team's line in a tournament standings points table.
@immutable
class TournamentStanding {
  const TournamentStanding({
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
    this.rank = 0,
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
  final double oversFaced;
  final int runsConceded;
  final double oversBowled;
  final double netRunRate;
  final DateTime updatedAt;

  // Joined metadata for UI
  final String? teamName;
  final String? teamLogoUrl;
  final String? teamMonogram;
  final String? teamPrimaryColor;
  final int rank;

  String get formattedNrr {
    final sign = netRunRate > 0 ? '+' : '';
    return '$sign${netRunRate.toStringAsFixed(3)}';
  }

  TournamentStanding copyWith({
    String? tournamentId,
    String? teamId,
    String? groupId,
    int? matchesPlayed,
    int? wins,
    int? losses,
    int? ties,
    int? noResults,
    int? points,
    int? runsScored,
    double? oversFaced,
    int? runsConceded,
    double? oversBowled,
    double? netRunRate,
    DateTime? updatedAt,
    String? teamName,
    String? teamLogoUrl,
    String? teamMonogram,
    String? teamPrimaryColor,
    int? rank,
  }) =>
      TournamentStanding(
        tournamentId: tournamentId ?? this.tournamentId,
        teamId: teamId ?? this.teamId,
        groupId: groupId ?? this.groupId,
        matchesPlayed: matchesPlayed ?? this.matchesPlayed,
        wins: wins ?? this.wins,
        losses: losses ?? this.losses,
        ties: ties ?? this.ties,
        noResults: noResults ?? this.noResults,
        points: points ?? this.points,
        runsScored: runsScored ?? this.runsScored,
        oversFaced: oversFaced ?? this.oversFaced,
        runsConceded: runsConceded ?? this.runsConceded,
        oversBowled: oversBowled ?? this.oversBowled,
        netRunRate: netRunRate ?? this.netRunRate,
        updatedAt: updatedAt ?? this.updatedAt,
        teamName: teamName ?? this.teamName,
        teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
        teamMonogram: teamMonogram ?? this.teamMonogram,
        teamPrimaryColor: teamPrimaryColor ?? this.teamPrimaryColor,
        rank: rank ?? this.rank,
      );

  TournamentStanding copyWithRank(int newRank) => copyWith(rank: newRank);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentStanding &&
          other.tournamentId == tournamentId &&
          other.teamId == teamId &&
          other.points == points &&
          other.netRunRate == netRunRate &&
          other.matchesPlayed == matchesPlayed;

  @override
  int get hashCode => Object.hash(tournamentId, teamId, points, netRunRate);
}
