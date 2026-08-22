// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_bowler_stats_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchBowlerStatsDto _$MatchBowlerStatsDtoFromJson(Map<String, dynamic> json) =>
    _MatchBowlerStatsDto(
      inningsId: json['innings_id'] as String,
      playerId: json['player_id'] as String,
      bowlingPosition: (json['bowling_position'] as num?)?.toInt(),
      legalBallsBowled: (json['legal_balls_bowled'] as num?)?.toInt() ?? 0,
      maidens: (json['maidens'] as num?)?.toInt() ?? 0,
      runsConceded: (json['runs_conceded'] as num?)?.toInt() ?? 0,
      wickets: (json['wickets'] as num?)?.toInt() ?? 0,
      widesConceded: (json['wides_conceded'] as num?)?.toInt() ?? 0,
      noBallsConceded: (json['no_balls_conceded'] as num?)?.toInt() ?? 0,
      dotBallsBowled: (json['dot_balls_bowled'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MatchBowlerStatsDtoToJson(
  _MatchBowlerStatsDto instance,
) => <String, dynamic>{
  'innings_id': instance.inningsId,
  'player_id': instance.playerId,
  'bowling_position': instance.bowlingPosition,
  'legal_balls_bowled': instance.legalBallsBowled,
  'maidens': instance.maidens,
  'runs_conceded': instance.runsConceded,
  'wickets': instance.wickets,
  'wides_conceded': instance.widesConceded,
  'no_balls_conceded': instance.noBallsConceded,
  'dot_balls_bowled': instance.dotBallsBowled,
};
