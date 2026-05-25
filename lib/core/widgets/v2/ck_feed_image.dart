// Fast, cached image with an instant BlurHash placeholder. Feature-agnostic:
// takes only primitives (url + optional blurhash/aspect ratio), so it stays in
// the shared core kit without depending on any feature's domain.
//
// - Disk + memory cache via cached_network_image (re-scrolls are instant,
//   survives going offline).
// - Decoded at display size (`memCacheWidth = slotPx × devicePixelRatio`) so a
//   1080px photo never decodes full-res into a small slot — the main scroll-jank
//   fix.
// - BlurHash placeholder → "blur → sharp" fade instead of a grey box; falls
//   back to a neutral colour when absent.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import '../../theme/circk_theme.dart';

class CkFeedImage extends StatelessWidget {
  const CkFeedImage({
    super.key,
    required this.url,
    this.blurhash = '',
    this.aspectRatio = 1,
    this.fit = BoxFit.cover,
    this.useAspectRatio = true,
  });

  final String url;
  final String blurhash;
  final double aspectRatio;
  final BoxFit fit;

  /// When true, reserves space via [aspectRatio] (single-image layouts).
  /// Set false inside a fixed-size grid cell.
  final bool useAspectRatio;

  @override
  Widget build(BuildContext context) {
    final image = LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final memW = (w * dpr).round().clamp(1, 4096);
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: memW,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _error(),
        );
      },
    );
    if (!useAspectRatio) return image;
    return AspectRatio(aspectRatio: aspectRatio, child: image);
  }

  Widget _placeholder() {
    if (blurhash.isEmpty) return const ColoredBox(color: CkColors.paper2);
    return BlurHash(hash: blurhash);
  }

  Widget _error() => const ColoredBox(
        color: CkColors.paper2,
        child: Center(
          child: Icon(Icons.broken_image_outlined,
              color: CkColors.soft, size: 28),
        ),
      );
}
