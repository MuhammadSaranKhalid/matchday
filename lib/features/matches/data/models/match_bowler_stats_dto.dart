import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match_bowler_stats.dart';

part 'match_bowler_stats_dto.freezed.dart';
part 'match_bowler_stats_dto.g.dart';

@freezed
abstract class MatchBowlerStatsDto with _$MatchBowlerStatsDto {
  const factory MatchBowlerStatsDto({
    @JsonKey(name: 'innings_id') required String inningsId,
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'bowling_position') int? bowlingPosition,
    @JsonKey(name: 'legal_balls_bowled') @Default(0) int legalBallsBowled,
    @JsonKey(name: 'maidens') @Default(0) int maidens,
    @JsonKey(name: 'runs_conceded') @Default(0) int runsConceded,
    @JsonKey(name: 'wickets') @Default(0) int wickets,
    @JsonKey(name: 'wides_conceded') @Default(0) int widesConceded,
    @JsonKey(name: 'no_balls_conceded') @Default(0) int noBallsConceded,
    @JsonKey(name: 'dot_balls_bowled') @Default(0) int dotBallsBowled,
  }) = _MatchBowlerStatsDto;

  const MatchBowlerStatsDto._();

  factory MatchBowlerStatsDto.fromJson(Map<String, dynamic> json) =>
      _$MatchBowlerStatsDtoFromJson(json);

  MatchBowlerStats toEntity() => MatchBowlerStats(
        inningsId: inningsId,
        playerId: playerId,
        bowlingPosition: bowlingPosition,
        legalBallsBowled: legalBallsBowled,
        maidens: maidens,
        runsConceded: runsConceded,
        wickets: wickets,
        widesConceded: widesConceded,
        noBallsConceded: noBallsConceded,
        dotBallsBowled: dotBallsBowled,
      );
}
