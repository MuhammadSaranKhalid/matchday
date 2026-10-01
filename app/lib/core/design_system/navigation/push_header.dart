import 'package:flutter/material.dart';

import '../components/actions/action_icon_button.dart';
import '../theme/app_theme.dart';

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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    final effectiveActions = actions ?? (action != null ? [action!] : null);

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
        children: [
          ActionIconButton.fromIconData(
            Icons.arrow_back,
            variant: ActionIconButtonVariant.subtle,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),
          SizedBox(width: layout.compactCardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ) ??
                        TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
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
