import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match_batsman_stats.dart';

part 'match_batsman_stats_dto.freezed.dart';
part 'match_batsman_stats_dto.g.dart';

@freezed
abstract class MatchBatsmanStatsDto with _$MatchBatsmanStatsDto {
  const factory MatchBatsmanStatsDto({
    @JsonKey(name: 'innings_id') required String inningsId,
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'batting_position') int? battingPosition,
    @JsonKey(name: 'runs') @Default(0) int runs,
    @JsonKey(name: 'balls_faced') @Default(0) int ballsFaced,
    @JsonKey(name: 'dots') @Default(0) int dots,
    @JsonKey(name: 'fours') @Default(0) int fours,
    @JsonKey(name: 'sixes') @Default(0) int sixes,
    @JsonKey(name: 'singles') @Default(0) int singles,
    @JsonKey(name: 'doubles') @Default(0) int doubles,
    @JsonKey(name: 'triples') @Default(0) int triples,
    @JsonKey(name: 'is_out') @Default(false) bool isOut,
    @JsonKey(name: 'dismissal_text') String? dismissalText,
    @JsonKey(name: 'minutes_batted') int? minutesBatted,
  }) = _MatchBatsmanStatsDto;

  const MatchBatsmanStatsDto._();

  factory MatchBatsmanStatsDto.fromJson(Map<String, dynamic> json) =>
      _$MatchBatsmanStatsDtoFromJson(json);

  MatchBatsmanStats toEntity() => MatchBatsmanStats(
        inningsId: inningsId,
        playerId: playerId,
        battingPosition: battingPosition,
        runs: runs,
        ballsFaced: ballsFaced,
        dots: dots,
        fours: fours,
        sixes: sixes,
        singles: singles,
        doubles: doubles,
        triples: triples,
        isOut: isOut,
        dismissalText: dismissalText,
        minutesBatted: minutesBatted,
      );
}
