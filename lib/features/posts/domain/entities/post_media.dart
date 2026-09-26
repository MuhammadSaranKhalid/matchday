import 'package:equatable/equatable.dart';

import 'media_variant.dart';

enum PostMediaStatus {
  awaitingUpload,
  uploaded,
  processingFeed,
  feedReady,
  optimizing,
  optimized,
  uploadFailed,
  processingFailed,
  optimizationFailed,
}

/// First-class image media attached to a post.
/// Pure Dart (Domain).
class PostMedia extends Equatable {
  const PostMedia({
    required this.mediaId,
    required this.postId,
    required this.position,
    required this.width,
    required this.height,
    this.blurhash,
    this.status = PostMediaStatus.feedReady,
    this.variants = const {},
  });

  final String mediaId;
  final String postId;
  final int position;
  final int width;
  final int height;
  final String? blurhash;
  final PostMediaStatus status;
  final Map<int, MediaVariant> variants;

  double get aspectRatio =>
      (width <= 0 || height <= 0) ? 1.0 : width / height;

  /// High-resolution / fallback URL (preferring 2048, 1080, or largest available variant).
  String get url {
    if (variants.containsKey(2048)) return variants[2048]!.url;
    if (variants.containsKey(1080)) return variants[1080]!.url;
    if (variants.isNotEmpty) {
      final sortedKeys = variants.keys.toList()..sort();
      return variants[sortedKeys.last]!.url;
    }
    return '';
  }

  Map<int, String> get variantUrls => {
        for (final entry in variants.entries) entry.key: entry.value.url,
      };

  /// Selects the smallest available variant with width >= [requiredPhysicalWidth].
  /// Falls back to the highest available variant if none is large enough, or 1080.
  MediaVariant? selectVariant(int requiredPhysicalWidth) {
    if (variants.isEmpty) return null;

    final sortedKeys = variants.keys.toList()..sort();

    // Smallest variant >= requiredPhysicalWidth
    for (final widthKey in sortedKeys) {
      if (widthKey >= requiredPhysicalWidth) {
        return variants[widthKey];
      }
    }

    // Fall back to largest available variant
    return variants[sortedKeys.last];
  }

  @override
  List<Object?> get props => [
        mediaId,
        postId,
        position,
        width,
        height,
        blurhash,
        status,
        variants,
      ];
}
