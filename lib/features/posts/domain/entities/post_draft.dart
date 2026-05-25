// Computed draft the composer hands the repository to create a post.
// Pure Dart; `dart:io` is permitted in Domain (Rule 1 allows dart:*).
//
// A [ProcessedPhoto] is the output of the photo pipeline: an already
// cropped + resized (≤1080px WebP) file, plus its BlurHash and dimensions
// computed on-device. The repository uploads the file and persists the
// metadata.
import 'dart:io';

import 'post.dart';

class ProcessedPhoto {
  const ProcessedPhoto({
    required this.file,
    required this.blurhash,
    required this.width,
    required this.height,
  });

  final File file;
  final String blurhash;
  final int width;
  final int height;
}

class PostDraft {
  const PostDraft({
    this.text,
    this.photos = const [],
    this.authorContext = PostAuthorContext.personal,
    this.contextEntityId,
  });

  final String? text;
  final List<ProcessedPhoto> photos;
  final PostAuthorContext authorContext;
  final String? contextEntityId;

  bool get hasPhotos => photos.isNotEmpty;
}
