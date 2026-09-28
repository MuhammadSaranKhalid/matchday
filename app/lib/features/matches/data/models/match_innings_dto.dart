import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings.dart';

part 'match_innings_dto.freezed.dart';
part 'match_innings_dto.g.dart';

@freezed
abstract class MatchInningsDto with _$MatchInningsDto {
  const factory MatchInningsDto({
    @JsonKey(name: 'innings_id') required String inningsId,
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'innings_number') required int inningsNumber,
    @JsonKey(name: 'batting_team_side') required String battingTeamSide,
    @JsonKey(name: 'bowling_team_side') required String bowlingTeamSide,
    @JsonKey(name: 'overs_allocated') @Default(20.0) double oversAllocated,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
  }) = _MatchInningsDto;

  const MatchInningsDto._();

  factory MatchInningsDto.fromJson(Map<String, dynamic> json) =>
      _$MatchInningsDtoFromJson(json);

  MatchInnings toEntity() => MatchInnings(
    inningsId: inningsId,
    matchId: MatchId(matchId),
    inningsNumber: inningsNumber,
    battingTeamSide: battingTeamSide,
    bowlingTeamSide: bowlingTeamSide,
    oversAllocated: oversAllocated,
    isCompleted: isCompleted,
    startTime: startTime == null ? null : DateTime.parse(startTime!),
    endTime: endTime == null ? null : DateTime.parse(endTime!),
  );
}
