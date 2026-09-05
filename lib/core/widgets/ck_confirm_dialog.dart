import 'package:flutter/material.dart';

import '../theme/circk_theme.dart';

/// A confirmation whose button hierarchy encodes reversibility.
///
/// A reversible action (archive) confirms with a normal ink button — no
/// alarm, because nothing is lost. A permanent one (leave a squad) confirms
/// with a filled red button, which is the only filled red button in the app.
///
/// Cancel is never a bare text link: it is a full-width outline button of
/// equal size, and its label restates the safe outcome ("Keep it active",
/// "Stay in the squad") instead of saying "Cancel", so the two choices can be
/// compared without re-reading the body.
Future<bool> showCkConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,

  /// Sentence appended to [body] in ink, carrying the consequence that
  /// decides the answer ("You can restore it any time", "This can't be
  /// undone").
  String? emphasis,
  String? bodyTail,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: CkColors.ink.withValues(alpha: 0.42),
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
    final bodyStyle = CkType.body(
      fontSize: 13.5,
      height: 1.45,
      color: CkColors.ink2,
    );

    return Dialog(
      backgroundColor: CkColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CkRadii.lg),
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
                color: destructive ? CkColors.redSurface : CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(
                  color: destructive ? CkColors.redBorder : CkColors.line,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 19,
                color: destructive ? CkColors.redInk : CkColors.ink2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: CkType.display(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
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
                        color: CkColors.ink,
                      ),
                    ),
                  if (bodyTail != null) TextSpan(text: bodyTail),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _DialogButton(
              label: confirmLabel,
              filled: true,
              destructive: destructive,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            _DialogButton(
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

class _DialogButton extends StatelessWidget {
  const _DialogButton({
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
            ? CkColors.red
            : CkColors.ink;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(CkRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: Container(
          height: 46,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: filled ? null : Border.all(color: CkColors.line, width: 1.5),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: filled ? CkColors.paper : CkColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
