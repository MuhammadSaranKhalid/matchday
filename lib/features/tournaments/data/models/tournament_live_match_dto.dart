import '../../domain/entities/tournament_live_match.dart';

/// Wire shape of one `tournament_live_board(...)` row.
///
/// Hand-rolled rather than freezed: the RPC returns a flat record whose only
/// nested field (`innings_lines`) is a jsonb array, and the mapping is a
/// straight read — codegen would add a build step for no gain.
class TournamentLiveMatchDto {
  const TournamentLiveMatchDto(this._row);

  final Map<String, dynamic> _row;

  factory TournamentLiveMatchDto.fromJson(Map<String, dynamic> json) =>
      TournamentLiveMatchDto(json);

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.tryParse(v as String)?.toLocal();

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;

  TournamentLiveMatch toEntity() {
    final rawLines = _row['innings_lines'];
    final lines = <LiveInningsLine>[];
    if (rawLines is List) {
      for (final entry in rawLines) {
        if (entry is! Map) continue;
        final line = Map<String, dynamic>.from(entry);
        lines.add(
          LiveInningsLine(
            inningsNumber: _int(line['innings_number']),
            battingTeamId: line['batting_team_id'] as String?,
            runs: _int(line['total_runs']),
            wickets: _int(line['total_wickets']),
            legalBalls: _int(line['legal_ball_count']),
          ),
        );
      }
    }

    final result = _row['result'];
    final resultMap = result is Map ? Map<String, dynamic>.from(result) : null;

    return TournamentLiveMatch(
      matchId: _row['match_id'] as String,
      venue: _row['venue'] as String? ?? 'Ground 1',
      status: _row['status'] as String? ?? 'scheduled',
      scheduledStartTime: _date(_row['scheduled_start_time']) ?? DateTime.now(),
      round: _row['round'] as String?,
      teamAId: _row['team_a_id'] as String?,
      teamAName: _row['team_a_name'] as String?,
      teamBId: _row['team_b_id'] as String?,
      teamBName: _row['team_b_name'] as String?,
      winnerId: _row['winner_id'] as String?,
      resultDescription:
          resultMap?['description'] as String? ?? resultMap?['summary'] as String?,
      scorerId: _row['scorer_id'] as String?,
      scorerName: _row['scorer_name'] as String?,
      lastBallAt: _date(_row['last_ball_at']),
      inningsLines: lines,
    );
  }
}
