import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';
import '../primitives/action_icon_button.dart';

/// Standardized push navigation header.
///
/// Implements [PreferredSizeWidget] so it can be slotted directly into [Scaffold.appBar]
/// or used inside custom screen layouts.
class PushHeader extends StatelessWidget implements PreferredSizeWidget {
  const PushHeader({
    super.key,
    required this.title,
    this.onBack,
    this.action,
    this.actions,
    this.subtitle,
    this.bottomBorder = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? action;
  final List<Widget>? actions;
  final String? subtitle;
  final bool bottomBorder;

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final effectiveActions = actions ?? (action != null ? [action!] : null);

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
        children: [
          ActionIconButton.subtle(
            icon: Icons.arrow_back,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                    letterSpacing: -0.01,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (effectiveActions != null) ...effectiveActions,
        ],
      ),
    );
  }
}
