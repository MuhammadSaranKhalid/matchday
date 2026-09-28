// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamResultDto _$TeamResultDtoFromJson(Map<String, dynamic> json) =>
    _TeamResultDto(
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      logoUrl: json['logo_url'] as String?,
      logoMonogram: json['logo_monogram'] as String?,
      teamColors: json['team_colors'] as Map<String, dynamic>?,
      location: json['location'] as Map<String, dynamic>?,
      isVerified: json['is_verified'] as bool? ?? false,
      foundedYear: (json['founded_year'] as num?)?.toInt(),
      teamType: json['team_type'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$TeamResultDtoToJson(_TeamResultDto instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'team_name': instance.teamName,
      'logo_url': instance.logoUrl,
      'logo_monogram': instance.logoMonogram,
      'team_colors': instance.teamColors,
      'location': instance.location,
      'is_verified': instance.isVerified,
      'founded_year': instance.foundedYear,
      'team_type': instance.teamType,
      'distance_km': instance.distanceKm,
      'score': instance.score,
    };
