import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;
    final textTheme = context.textTheme;

    final effectiveAction = action ??
        (actionLabel != null && onAction != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(layout.controlRadius),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: layout.minimumTapTarget,
                      minHeight: layout.minimumTapTarget,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          actionLabel!,
                          style: textTheme.labelLarge?.copyWith(
                                fontSize: 13,
                                color: scheme.onSurface,
                              ) ??
                              TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null);

    return Padding(
      padding: padding ?? EdgeInsets.symmetric(vertical: layout.inlineGap),
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
                    style: textTokens.eyebrow.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.01,
                      ) ??
                      TextStyle(
                        fontFamily: 'Inter Tight',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
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
