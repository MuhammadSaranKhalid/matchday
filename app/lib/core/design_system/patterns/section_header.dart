import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';

/// Standardized section header pattern with optional eyebrow and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.action,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? eyebrow;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveAction = action ??
        (actionLabel != null && onAction != null
            ? GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Palette.ink,
                    ),
                  ),
                ),
              )
            : null);

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Palette.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                    letterSpacing: -0.01,
                  ),
                ),
              ],
            ),
          ),
          if (effectiveAction != null) effectiveAction,
        ],
      ),
    );
  }
}
