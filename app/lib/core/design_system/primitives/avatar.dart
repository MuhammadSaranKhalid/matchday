import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../foundation/palette.dart';

/// Tone styling for avatar initials fallback.
enum AvatarTone {
  paper,
  ink,
  accent,
}

/// Standardized user or entity avatar primitive.
///
/// Handles remote image loading with memory-safe thumbnail caching and degrades
/// gracefully to a typographic initials monogram fallback when image is unavailable.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.mono,
    this.imageUrl,
    this.size = 36.0,
    this.tone = AvatarTone.paper,
    this.background,
    this.foreground,
  });

  /// 1-2 character initials monogram.
  final String mono;

  /// Optional remote image URL.
  final String? imageUrl;

  /// Visual diameter of the avatar.
  final double size;

  /// Semantic tone of the monogram fallback.
  final AvatarTone tone;

  /// Custom background override.
  final Color? background;

  /// Custom foreground/monogram override.
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      AvatarTone.ink => (
          background ?? Palette.ink,
          foreground ?? Palette.paper,
          null,
        ),
      AvatarTone.accent => (
          background ?? Palette.cream,
          foreground ?? Palette.amberInk,
          Border.all(color: Palette.creamBorder),
        ),
      AvatarTone.paper => (
          background ?? Palette.paper2,
          foreground ?? Palette.ink2,
          Border.all(color: Palette.hairline),
        ),
    };

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: background != null ? null : border,
      ),
      child: Text(
        mono,
        style: TextStyle(
          fontFamily: 'Inter Tight',
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      final memW = (size * MediaQuery.devicePixelRatioOf(context)).round();
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: memW,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      );
    }

    return fallback;
  }
}
