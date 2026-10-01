import 'package:flutter/material.dart';

import '../foundation/radii.dart';
import '../theme/app_theme.dart';

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
    final scheme = context.colorScheme;
    final status = context.statusColors;
    final textTokens = context.textTokens;

    final effectiveShowDot = showDot ?? (tone == StatusTone.live);

    final (bg, fg, border) = switch (tone) {
      StatusTone.neutral => (
          status.neutralSurface,
          status.neutral,
          Border.all(color: scheme.outlineVariant),
        ),
      StatusTone.ink => (
          scheme.primary,
          scheme.onPrimary,
          null,
        ),
      StatusTone.live || StatusTone.destructive => (
          status.liveSurface,
          status.live,
          Border.all(color: status.liveBorder),
        ),
      StatusTone.success => (
          status.successSurface,
          status.success,
          Border.all(color: status.successBorder),
        ),
      StatusTone.warning => (
          status.warningSurface,
          status.warning,
          Border.all(color: status.warningBorder),
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
            style: textTokens.eyebrow.copyWith(
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
