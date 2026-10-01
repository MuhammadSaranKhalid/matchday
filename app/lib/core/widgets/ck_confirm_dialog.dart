import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Legacy confirmation dialog facade.
///
/// Prefer [showConfirmationDialog] from `package:matchday/core/design_system/design_system.dart`.
@Deprecated('Use showConfirmationDialog from package:matchday/core/design_system/design_system.dart')
Future<bool> showCkConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  String? emphasis,
  String? bodyTail,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Palette.ink.withValues(alpha: 0.42),
    builder: (ctx) => _CkConfirmDialog(
      icon: icon,
      title: title,
      body: body,
      emphasis: emphasis,
      bodyTail: bodyTail,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class _CkConfirmDialog extends StatelessWidget {
  const _CkConfirmDialog({
    required this.icon,
    required this.title,
    required this.body,
    required this.emphasis,
    required this.bodyTail,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? emphasis;
  final String? bodyTail;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13.5,
      height: 1.45,
      color: Palette.ink2,
    );

    return Dialog(
      backgroundColor: Palette.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: destructive ? Palette.redSurface : Palette.paper2,
                shape: BoxShape.circle,
                border: Border.all(
                  color: destructive ? Palette.redBorder : Palette.line,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 19,
                color: destructive ? Palette.redInk : Palette.ink2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter Tight',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  TextSpan(text: body),
                  if (emphasis != null)
                    TextSpan(
                      text: emphasis,
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                  if (bodyTail != null) TextSpan(text: bodyTail),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _LegacyDialogButton(
              label: confirmLabel,
              filled: true,
              destructive: destructive,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            _LegacyDialogButton(
              label: cancelLabel,
              filled: false,
              destructive: false,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyDialogButton extends StatelessWidget {
  const _LegacyDialogButton({
    required this.label,
    required this.filled,
    required this.destructive,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = !filled
        ? Colors.transparent
        : destructive
            ? Palette.red
            : Palette.ink;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: Palette.line, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: filled ? Palette.paper : Palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}
