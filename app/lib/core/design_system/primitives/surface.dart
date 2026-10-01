import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Content density for [Surface] padding.
enum SurfaceDensity {
  /// 12.0 padding
  compact,

  /// 16.0 padding
  standard,

  /// 20.0 padding
  comfortable,
}

/// Visual style variants for [Surface].
enum SurfaceVariant {
  /// Plain surface background without border.
  plain,

  /// Clean surface background with standard 1px border.
  outlined,

  /// Subtle tinted background (paper2).
  subtle,

  /// Elevated card with subtle shadow.
  raised,

  /// Cream tinted accent surface.
  accent,
}

/// Standardized card and container chrome primitive.
///
/// Owns background fill, border, corner radius, padding density, and tap ink
/// effects without dictating inner domain layout or fixed dimensions.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.density = SurfaceDensity.standard,
    this.variant = SurfaceVariant.outlined,
    this.radius,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.clipBehavior = Clip.antiAlias,
    this.width,
    this.height,
  });

  final Widget child;
  final SurfaceDensity density;
  final SurfaceVariant variant;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Clip clipBehavior;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final effectiveRadius = radius ?? layout.cardRadius;
    final borderRadius = BorderRadius.circular(effectiveRadius);

    final effectivePadding = padding ??
        switch (density) {
          SurfaceDensity.compact => EdgeInsets.all(layout.compactCardPadding),
          SurfaceDensity.standard => EdgeInsets.all(layout.cardPadding),
          SurfaceDensity.comfortable =>
            EdgeInsets.all(layout.comfortableCardPadding),
        };

    final (bg, border, shadow) = switch (variant) {
      SurfaceVariant.plain => (
          scheme.surface,
          null,
          null,
        ),
      SurfaceVariant.outlined => (
          scheme.surface,
          Border.all(color: scheme.outline),
          null,
        ),
      SurfaceVariant.subtle => (
          status.neutralSurface,
          Border.all(color: scheme.outlineVariant),
          null,
        ),
      SurfaceVariant.raised => (
          scheme.surface,
          Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          const [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
      SurfaceVariant.accent => (
          status.cream,
          Border.all(color: status.creamBorder),
          null,
        ),
    };

    Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadow,
      ),
      clipBehavior: clipBehavior,
      child: content,
    );
  }
}
