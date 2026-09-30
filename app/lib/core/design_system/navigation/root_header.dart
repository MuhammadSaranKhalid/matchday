import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';

/// Standardized root navigation header used on top-level tabs (Home, Explore,
/// Matches, Messages, Profile).
class RootHeader extends StatelessWidget implements PreferredSizeWidget {
  const RootHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottomBorder = true,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool bottomBorder;

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: Palette.paper,
        border: bottomBorder
            ? const Border(bottom: BorderSide(color: Palette.hairline))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: Spacing.sm),
          ],
          Expanded(
            child: titleWidget ??
                Text(
                  title ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                    letterSpacing: -0.02,
                  ),
                ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
