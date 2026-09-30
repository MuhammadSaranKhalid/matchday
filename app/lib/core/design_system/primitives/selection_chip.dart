import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/radii.dart';
import '../foundation/sizing.dart';

/// Standardized interactive filter chip primitive.
///
/// Used for tab filtering, category selection, and toggles (e.g. All, Following,
/// T20, Nearby). Enforces accessible interaction targets (>= 48x48 dp).
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
    final bg = selected ? Palette.ink : Palette.paper;
    final fg = selected ? Palette.paper : Palette.ink;
    final border = selected ? null : Border.all(color: Palette.line);

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
                    ? Palette.paper.withValues(alpha: 0.2)
                    : Palette.paper2,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Sizing.minimumTapTarget,
            minHeight: Sizing.minimumTapTarget,
          ),
          child: Center(
            child: pillContent,
          ),
        ),
      ),
    );
  }
}
