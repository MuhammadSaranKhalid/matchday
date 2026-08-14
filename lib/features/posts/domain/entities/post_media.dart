// One image attached to a post. Pure Dart (Domain).
//
// Resize-before-upload means a single stored file per image; this carries the
// public URL plus the metadata we persist alongside it: a BlurHash string (for
// the instant placeholder) and the stored pixel dimensions (to reserve the
// layout box before the image loads).
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_media.freezed.dart';

@freezed
abstract class PostMedia with _$PostMedia {
  const factory PostMedia({
    required String url,
    required String blurhash,
    required int width,
    required int height,
  }) = _PostMedia;

  const PostMedia._();

  /// width / height; falls back to square if dimensions are missing.
  double get aspectRatio =>
      (width <= 0 || height <= 0) ? 1.0 : width / height;
}
