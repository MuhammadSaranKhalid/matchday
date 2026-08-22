// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_batsman_stats_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchBatsmanStatsDto _$MatchBatsmanStatsDtoFromJson(
  Map<String, dynamic> json,
) => _MatchBatsmanStatsDto(
  inningsId: json['innings_id'] as String,
  playerId: json['player_id'] as String,
  battingPosition: (json['batting_position'] as num?)?.toInt(),
  runs: (json['runs'] as num?)?.toInt() ?? 0,
  ballsFaced: (json['balls_faced'] as num?)?.toInt() ?? 0,
  dots: (json['dots'] as num?)?.toInt() ?? 0,
  fours: (json['fours'] as num?)?.toInt() ?? 0,
  sixes: (json['sixes'] as num?)?.toInt() ?? 0,
  singles: (json['singles'] as num?)?.toInt() ?? 0,
  doubles: (json['doubles'] as num?)?.toInt() ?? 0,
  triples: (json['triples'] as num?)?.toInt() ?? 0,
  isOut: json['is_out'] as bool? ?? false,
  dismissalText: json['dismissal_text'] as String?,
  minutesBatted: (json['minutes_batted'] as num?)?.toInt(),
);

Map<String, dynamic> _$MatchBatsmanStatsDtoToJson(
  _MatchBatsmanStatsDto instance,
) => <String, dynamic>{
  'innings_id': instance.inningsId,
  'player_id': instance.playerId,
  'batting_position': instance.battingPosition,
  'runs': instance.runs,
  'balls_faced': instance.ballsFaced,
  'dots': instance.dots,
  'fours': instance.fours,
  'sixes': instance.sixes,
  'singles': instance.singles,
  'doubles': instance.doubles,
  'triples': instance.triples,
  'is_out': instance.isOut,
  'dismissal_text': instance.dismissalText,
  'minutes_batted': instance.minutesBatted,
};
