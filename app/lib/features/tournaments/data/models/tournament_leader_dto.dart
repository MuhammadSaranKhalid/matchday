import '../../domain/entities/tournament_leader.dart';

/// Wire shape of one `tournament_batting_leaderboard` / `..._bowling_...` row.
class TournamentLeaderDto {
  const TournamentLeaderDto(this._row, {required this.batting});

  final Map<String, dynamic> _row;
  final bool batting;

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;

  static double _double(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  TournamentLeader toEntity() => TournamentLeader(
        playerKey: _row['player_key'] as String? ?? '',
        displayName: _row['display_name'] as String? ?? 'Unknown',
        teamName: _row['team_name'] as String?,
        teamMonogram: _row['team_monogram'] as String?,
        isUnclaimed: _row['is_unclaimed'] as bool? ?? false,
        primaryValue: _int(_row[batting ? 'runs' : 'wickets']),
        rateValue: _double(_row[batting ? 'strike_rate' : 'economy']),
        innings: _int(_row['innings']),
        ballsFaced: _int(_row['balls_faced']),
        fours: _int(_row['fours']),
        sixes: _int(_row['sixes']),
        highScore: _int(_row['high_score']),
        runsConceded: _int(_row['runs_conceded']),
        bestWickets: _int(_row['best_wickets']),
        bestRuns: _int(_row['best_runs']),
      );
}
