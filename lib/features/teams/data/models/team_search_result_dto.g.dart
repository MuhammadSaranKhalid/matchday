// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_search_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamSearchResultDto _$TeamSearchResultDtoFromJson(Map<String, dynamic> json) =>
    _TeamSearchResultDto(
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      logoUrl: json['logo_url'] as String?,
      logoMonogram: json['logo_monogram'] as String?,
      teamColors: json['team_colors'] as Map<String, dynamic>?,
      isVerified: json['is_verified'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      foundedYear: (json['founded_year'] as num?)?.toInt(),
      teamType: json['team_type'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$TeamSearchResultDtoToJson(
  _TeamSearchResultDto instance,
) => <String, dynamic>{
  'team_id': instance.teamId,
  'team_name': instance.teamName,
  'logo_url': instance.logoUrl,
  'logo_monogram': instance.logoMonogram,
  'team_colors': instance.teamColors,
  'is_verified': instance.isVerified,
  'distance_km': instance.distanceKm,
  'founded_year': instance.foundedYear,
  'team_type': instance.teamType,
  'score': instance.score,
};
