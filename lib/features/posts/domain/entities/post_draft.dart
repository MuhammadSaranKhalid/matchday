// Computed draft the composer hands the repository to create a post.
// Pure Dart; `dart:io` is permitted in Domain (Rule 1 allows dart:*).
//
// A [ProcessedPhoto] is the output of the photo pipeline: an already
// cropped + resized (≤1080px WebP) file, plus its BlurHash and dimensions
// computed on-device. The repository uploads the file and persists the
// metadata.
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'post.dart';

part 'post_draft.freezed.dart';

@freezed
abstract class ProcessedPhoto with _$ProcessedPhoto {
  const factory ProcessedPhoto({
    required File file,
    required String blurhash,
    required int width,
    required int height,
    /// True while the BlurHash is still being computed in the background — the
    /// composer shows a loading overlay on the thumbnail until it resolves.
    @Default(false) bool hashPending,
  }) = _ProcessedPhoto;
}

@freezed
abstract class PostDraft with _$PostDraft {
  const factory PostDraft({
    String? text,
    @Default([]) List<ProcessedPhoto> photos,
    @Default(PostAuthorContext.personal) PostAuthorContext authorContext,
    String? contextEntityId,
  }) = _PostDraft;

  const PostDraft._();

  bool get hasPhotos => photos.isNotEmpty;
}
