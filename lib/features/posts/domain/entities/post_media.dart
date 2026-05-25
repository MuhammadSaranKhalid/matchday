// One image attached to a post. Pure Dart (Domain).
//
// Resize-before-upload means a single stored file per image; this carries the
// public URL plus the metadata we persist alongside it: a BlurHash string (for
// the instant placeholder) and the stored pixel dimensions (to reserve the
// layout box before the image loads).
class PostMedia {
  const PostMedia({
    required this.url,
    required this.blurhash,
    required this.width,
    required this.height,
  });

  final String url;
  final String blurhash;
  final int width;
  final int height;

  /// width / height; falls back to square if dimensions are missing.
  double get aspectRatio =>
      (width <= 0 || height <= 0) ? 1.0 : width / height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostMedia &&
          other.url == url &&
          other.blurhash == blurhash &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(url, blurhash, width, height);
}
