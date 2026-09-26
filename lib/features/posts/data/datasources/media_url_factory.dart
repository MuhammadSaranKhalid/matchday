import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves immutable relative storage paths into absolute public HTTP URLs.
/// Enforces that the database stores only relative paths (e.g., `posts/.../v1/1080.webp`)
/// while the presentation/cache layer receives valid HTTP URLs.
class MediaUrlFactory {
  const MediaUrlFactory(this._supabase);

  final SupabaseClient _supabase;

  static const String _postMediaBucket = 'post-media';

  /// Resolves a post-media storage path into a public CDN/Storage HTTP URL.
  String postMedia(String storagePath) {
    if (storagePath.isEmpty) return '';
    if (storagePath.startsWith('http://') || storagePath.startsWith('https://')) {
      return storagePath;
    }
    final cleanPath =
        storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;
    return _supabase.storage.from(_postMediaBucket).getPublicUrl(cleanPath);
  }
}
