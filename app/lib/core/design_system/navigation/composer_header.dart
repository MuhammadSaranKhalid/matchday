import 'package:flutter/material.dart';

import '../primitives/action_button.dart';
import '../primitives/action_icon_button.dart';
import '../theme/app_theme.dart';

/// Standardized composer navigation header (e.g. Create Post, New Message).
class ComposerHeader extends StatelessWidget implements PreferredSizeWidget {
  const ComposerHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.onClose,
    this.loading = false,
    this.canSubmit = true,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;
  final bool loading;
  final bool canSubmit;

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
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          ActionIconButton.fromIconData(
            Icons.close,
            variant: ActionIconButtonVariant.subtle,
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
            tooltip: 'Cancel',
          ),
          SizedBox(width: layout.compactCardPadding),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ) ??
                  TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
            ),
          ),
          SizedBox(width: layout.compactCardPadding),
          ActionButton(
            label: actionLabel,
            onPressed: canSubmit && !loading ? onAction : null,
            loading: loading,
            size: ControlSize.compact,
            expand: false,
          ),
        ],
      ),
    );
  }
}
