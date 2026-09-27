import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/media_variant.dart';
import '../../domain/entities/post_media.dart';
import '../datasources/media_url_factory.dart';

part 'post_media_dto.freezed.dart';
part 'post_media_dto.g.dart';

@freezed
abstract class MediaVariantDto with _$MediaVariantDto {
  const factory MediaVariantDto({
    required String path,
    required int width,
    required int height,
    @JsonKey(name: 'size_bytes') @Default(0) int sizeBytes,
    @JsonKey(name: 'mime_type') @Default('image/webp') String mimeType,
  }) = _MediaVariantDto;

  const MediaVariantDto._();

  factory MediaVariantDto.fromJson(Map<String, dynamic> json) {
    final size = json['size_bytes'] ??
        json['bytes'] ??
        json['sizeBytes'] ??
        0;
    final mime = json['mime_type'] ??
        json['mime'] ??
        json['mimeType'] ??
        'image/webp';
    return MediaVariantDto(
      path: json['path'] as String? ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      sizeBytes: (size as num?)?.toInt() ?? 0,
      mimeType: mime as String? ?? 'image/webp',
    );
  }

  MediaVariant toEntity([MediaUrlFactory? urlFactory]) => MediaVariant(
        path: path,
        url: urlFactory?.postMedia(path),
        width: width,
        height: height,
        sizeBytes: sizeBytes,
        mimeType: mimeType,
      );
}

@freezed
abstract class PostMediaDto with _$PostMediaDto {
  const factory PostMediaDto({
    @JsonKey(name: 'media_id') required String mediaId,
    @JsonKey(name: 'post_id') @Default('') String postId,
    @Default(0) int position,
    @Default(1080) int width,
    @Default(1080) int height,
    String? blurhash,
    @Default('feed_ready') String status,
    @Default(<String, dynamic>{}) Map<String, dynamic> variants,
  }) = _PostMediaDto;

  const PostMediaDto._();

  factory PostMediaDto.fromJson(Map<String, dynamic> json) =>
      _$PostMediaDtoFromJson(json);

  PostMedia toEntity([MediaUrlFactory? urlFactory]) {
    final parsedVariants = <int, MediaVariant>{};
    variants.forEach((key, value) {
      final widthKey = int.tryParse(key);
      if (widthKey != null && value is Map<String, dynamic>) {
        parsedVariants[widthKey] =
            MediaVariantDto.fromJson(value).toEntity(urlFactory);
      }
    });

    return PostMedia(
      mediaId: mediaId,
      postId: postId,
      position: position,
      width: width,
      height: height,
      blurhash: blurhash,
      status: _parseStatus(status),
      variants: parsedVariants,
    );
  }

  static PostMediaStatus _parseStatus(String s) => switch (s) {
        'awaiting_upload' => PostMediaStatus.awaitingUpload,
        'uploaded' => PostMediaStatus.uploaded,
        'processing_feed' => PostMediaStatus.processingFeed,
        'feed_ready' => PostMediaStatus.feedReady,
        'optimizing' => PostMediaStatus.optimizing,
        'optimized' => PostMediaStatus.optimized,
        'upload_failed' => PostMediaStatus.uploadFailed,
        'processing_failed' => PostMediaStatus.processingFailed,
        'optimization_failed' => PostMediaStatus.optimizationFailed,
        _ => PostMediaStatus.feedReady,
      };
}
