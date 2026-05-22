import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';

part 'match_dto.freezed.dart';
part 'match_dto.g.dart';

/// Wire-format `matches` row. `format` and `venue` are jsonb blobs.
@freezed
abstract class MatchDto with _$MatchDto {
  const factory MatchDto({
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'team_a_id') required String teamAId,
    @JsonKey(name: 'team_b_id') required String teamBId,
    @JsonKey(name: 'team_a_squad') @Default(<String>[]) List<String> teamASquad,
    @JsonKey(name: 'team_b_squad') @Default(<String>[]) List<String> teamBSquad,
    @JsonKey(name: 'team_a_captain') String? teamACaptain,
    @JsonKey(name: 'team_b_captain') String? teamBCaptain,
    @JsonKey(name: 'team_a_keeper') String? teamAKeeper,
    @JsonKey(name: 'team_b_keeper') String? teamBKeeper,
    required Map<String, dynamic> format,
    Map<String, dynamic>? venue,
    @JsonKey(name: 'scheduled_start_time') String? scheduledStartTime,
    Map<String, dynamic>? result,
    @Default('pending') String status,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _MatchDto;

  const MatchDto._();

  factory MatchDto.fromJson(Map<String, dynamic> json) =>
      _$MatchDtoFromJson(json);

  Match toEntity() => Match(
        id: MatchId(matchId),
        teamAId: TeamId(teamAId),
        teamBId: TeamId(teamBId),
        teamASquad: teamASquad,
        teamBSquad: teamBSquad,
        teamACaptain: teamACaptain,
        teamBCaptain: teamBCaptain,
        teamAKeeper: teamAKeeper,
        teamBKeeper: teamBKeeper,
        format: MatchFormat(
          oversPerInnings: (format['overs_per_innings'] as num?)?.toInt() ?? 0,
          playersPerTeam: (format['players_per_team'] as num?)?.toInt() ?? 11,
          ballType: MatchBallType.fromWire(format['ball_type'] as String?),
          maxOversPerBowler:
              (format['max_overs_per_bowler'] as num?)?.toInt() ?? 0,
        ),
        venue: venue == null
            ? null
            : Venue(
                ground: venue!['ground'] as String? ?? '',
                city: venue!['city'] as String?,
              ),
        scheduledStartTime: scheduledStartTime == null
            ? null
            : DateTime.tryParse(scheduledStartTime!),
        resultDescription: result?['description'] as String?,
        status: MatchStatus.fromWire(status),
        createdBy: createdBy,
        createdAt: DateTime.parse(createdAt),
      );
}
