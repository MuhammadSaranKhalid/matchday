// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'format_preset_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FormatPresetDto _$FormatPresetDtoFromJson(Map<String, dynamic> json) =>
    _FormatPresetDto(
      id: json['id'] as String,
      label: json['label'] as String,
      config: json['config'] as Map<String, dynamic>,
      defaultScoringMode: json['default_scoring_mode'] as String?,
    );

Map<String, dynamic> _$FormatPresetDtoToJson(_FormatPresetDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'config': instance.config,
      'default_scoring_mode': instance.defaultScoringMode,
    };
