import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/radii.dart';

/// Semantic tones for [StatusBadge].
enum StatusTone {
  neutral,
  ink,
  live,
  success,
  warning,
  destructive,
}

/// Standardized informational badge primitive.
///
/// Used for non-interactive domain status markers (e.g. LIVE, FINAL, CAPTAIN,
/// OWNER, DRAFT, UPCOMING).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.showDot,
    this.pill = false,
  });

  final String label;
  final StatusTone tone;
  final Widget? icon;
  final bool? showDot;

  /// Whether to render with a capsule/pill radius instead of standard micro radius.
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final effectiveShowDot = showDot ?? (tone == StatusTone.live);

    final (bg, fg, border) = switch (tone) {
      StatusTone.neutral => (
          Palette.paper2,
          Palette.ink2,
          Border.all(color: Palette.hairline),
        ),
      StatusTone.ink => (
          Palette.ink,
          Palette.paper,
          null,
        ),
      StatusTone.live || StatusTone.destructive => (
          Palette.redSurface,
          Palette.redInk,
          Border.all(color: Palette.redBorder),
        ),
      StatusTone.success => (
          Palette.greenSurface,
          Palette.greenInk,
          Border.all(color: Palette.greenBorder),
        ),
      StatusTone.warning => (
          Palette.cream,
          Palette.amberInk,
          Border.all(color: Palette.creamBorder),
        ),
    };

    final borderRadius = BorderRadius.circular(pill ? Radii.pill : Radii.xs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (effectiveShowDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
