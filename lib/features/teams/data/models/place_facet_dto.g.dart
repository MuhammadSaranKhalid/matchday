// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_facet_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaceFacetDto _$PlaceFacetDtoFromJson(Map<String, dynamic> json) =>
    _PlaceFacetDto(
      city: json['city'] as String,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      teamCount: (json['team_count'] as num).toInt(),
    );

Map<String, dynamic> _$PlaceFacetDtoToJson(_PlaceFacetDto instance) =>
    <String, dynamic>{
      'city': instance.city,
      'lat': instance.lat,
      'lng': instance.lng,
      'team_count': instance.teamCount,
    };
