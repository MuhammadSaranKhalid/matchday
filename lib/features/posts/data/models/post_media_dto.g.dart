// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_media_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaVariantDto _$MediaVariantDtoFromJson(Map<String, dynamic> json) =>
    _MediaVariantDto(
      path: json['path'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'image/webp',
    );

Map<String, dynamic> _$MediaVariantDtoToJson(_MediaVariantDto instance) =>
    <String, dynamic>{
      'path': instance.path,
      'width': instance.width,
      'height': instance.height,
      'size_bytes': instance.sizeBytes,
      'mime_type': instance.mimeType,
    };

_PostMediaDto _$PostMediaDtoFromJson(Map<String, dynamic> json) =>
    _PostMediaDto(
      mediaId: json['media_id'] as String,
      postId: json['post_id'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 1080,
      height: (json['height'] as num?)?.toInt() ?? 1080,
      blurhash: json['blurhash'] as String?,
      status: json['status'] as String? ?? 'feed_ready',
      variants:
          json['variants'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$PostMediaDtoToJson(_PostMediaDto instance) =>
    <String, dynamic>{
      'media_id': instance.mediaId,
      'post_id': instance.postId,
      'position': instance.position,
      'width': instance.width,
      'height': instance.height,
      'blurhash': instance.blurhash,
      'status': instance.status,
      'variants': instance.variants,
    };
