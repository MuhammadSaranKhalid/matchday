import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/radii.dart';
import '../foundation/spacing.dart';
import '../primitives/action_button.dart';

/// Launches a standardized confirmation dialog whose button hierarchy encodes
/// reversibility.
///
/// A reversible action (e.g. archive) confirms with a standard primary button.
/// A permanent one (e.g. leave squad, delete tournament) confirms with a
/// destructive treatment.
/// Cancel is always an explicit full-width secondary button that restates the
/// safe outcome.
Future<bool> showConfirmationDialog(
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
    builder: (ctx) => ConfirmationDialog(
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

/// Standardized confirmation dialog widget.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.emphasis,
    this.bodyTail,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
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
        borderRadius: BorderRadius.circular(Radii.modal),
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
                size: 20,
                color: destructive ? Palette.redInk : Palette.ink2,
              ),
            ),
            const SizedBox(height: Spacing.sm),
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
            const SizedBox(height: Spacing.xs),
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
            const SizedBox(height: Spacing.lg),
            ActionButton(
              label: confirmLabel,
              variant: destructive
                  ? ActionButtonVariant.destructive
                  : ActionButtonVariant.primary,
              size: ControlSize.standard,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: Spacing.xs),
            ActionButton.secondary(
              label: cancelLabel,
              size: ControlSize.standard,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
