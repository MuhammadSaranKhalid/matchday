import 'package:flutter/material.dart';

import '../theme/circk_theme.dart';

/// The three button shapes used across Circk.
///
/// These are thin wrappers over the themed [FilledButton] / [OutlinedButton] /
/// [TextButton] (styled in [buildCirckTheme]) so call sites read by intent
/// rather than by Material widget name, and so a busy spinner is handled in
/// one place.
enum CkButtonVariant { primary, secondary, ghost }

class CkButton extends StatelessWidget {
  const CkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CkButtonVariant.primary,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  const CkButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
  }) : variant = CkButtonVariant.secondary;

  const CkButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
  }) : variant = CkButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final CkButtonVariant variant;
  final Widget? icon;

  /// When true the button is disabled and shows an inline spinner.
  final bool busy;

  /// When true the button stretches to fill its parent's width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = busy ? null : onPressed;
    final child = busy
        ? _Spinner(color: _spinnerColor)
        : _Label(label: label, icon: icon);

    final Widget button = switch (variant) {
      CkButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      CkButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      CkButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color get _spinnerColor =>
      variant == CkButtonVariant.primary ? CkColors.paper : CkColors.ink;
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.icon});

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon!,
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
    );
  }
}
