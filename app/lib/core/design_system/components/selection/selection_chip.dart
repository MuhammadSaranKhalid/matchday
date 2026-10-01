import 'package:flutter/material.dart';

import '../../foundation/radii.dart';
import '../../theme/app_theme.dart';

/// Standardized interactive filter chip primitive.
///
/// Used for independent filter facets, category selection, and optional
/// multi-select filtering (e.g. T20, 40 Overs, Weekend, Nearby).
/// Do NOT use for mutually exclusive primary screen views; use [SegmentedControl] instead.
/// Enforces accessible interaction targets (>= 48x48 dp).
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    this.onPressed,
    this.icon,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final Widget? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final bg = selected ? scheme.primary : scheme.surface;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    final border = selected ? null : Border.all(color: scheme.outline);

    final pillContent = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: fg,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.surface.withValues(alpha: 0.2)
                    : status.neutralSurface,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      selected: selected,
      button: true,
      label: '$label${count != null ? ', $count' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: layout.minimumTapTarget,
              minHeight: layout.minimumTapTarget,
            ),
            child: Center(
              child: pillContent,
            ),
          ),
        ),
      ),
    );
  }
}
