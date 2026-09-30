import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';
import '../primitives/action_button.dart';
import '../primitives/action_icon_button.dart';

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
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: const BoxDecoration(
        color: Palette.paper,
        border: Border(bottom: BorderSide(color: Palette.hairline)),
      ),
      child: Row(
        children: [
          ActionIconButton.subtle(
            icon: Icons.close,
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
            tooltip: 'Cancel',
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter Tight',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
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
