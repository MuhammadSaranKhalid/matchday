// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamDto _$TeamDtoFromJson(Map<String, dynamic> json) => _TeamDto(
  teamId: json['team_id'] as String,
  createdBy: json['created_by'] as String?,
  teamName: json['team_name'] as String,
  teamType: json['team_type'] as String,
  description: json['description'] as String?,
  homeGround: json['home_ground'] as String?,
  location: json['location'] as Map<String, dynamic>?,
  foundedYear: (json['founded_year'] as num?)?.toInt(),
  teamColors: json['team_colors'] as Map<String, dynamic>?,
  privacy: json['privacy'] as String? ?? 'public',
  tagline: json['tagline'] as String?,
  logoUrl: json['logo_url'] as String?,
  logoMonogram: json['logo_monogram'] as String?,
  isVerified: json['is_verified'] as bool? ?? false,
  status: json['status'] as String? ?? 'active',
  maxSquadSize: (json['max_squad_size'] as num?)?.toInt() ?? 25,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$TeamDtoToJson(_TeamDto instance) => <String, dynamic>{
  'team_id': instance.teamId,
  'created_by': instance.createdBy,
  'team_name': instance.teamName,
  'team_type': instance.teamType,
  'description': instance.description,
  'home_ground': instance.homeGround,
  'location': instance.location,
  'founded_year': instance.foundedYear,
  'team_colors': instance.teamColors,
  'privacy': instance.privacy,
  'tagline': instance.tagline,
  'logo_url': instance.logoUrl,
  'logo_monogram': instance.logoMonogram,
  'is_verified': instance.isVerified,
  'status': instance.status,
  'max_squad_size': instance.maxSquadSize,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
