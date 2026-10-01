import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      height: 56.0,
      padding: EdgeInsets.symmetric(horizontal: layout.screenGutter),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: bottomBorder
            ? Border(bottom: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: layout.compactCardPadding),
          ],
          Expanded(
            child: titleWidget ??
                Text(
                  title ?? '',
                  style: textTheme.titleLarge?.copyWith(
                        letterSpacing: -0.02,
                        color: scheme.onSurface,
                      ) ??
                      TextStyle(
                        fontFamily: 'Inter Tight',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
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
