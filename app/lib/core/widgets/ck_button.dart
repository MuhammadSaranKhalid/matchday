import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Legacy button variant enum.
///
/// Prefer [ActionButtonVariant] from `package:matchday/core/design_system/design_system.dart`.
enum CkButtonVariant { primary, secondary, ghost }

/// Backward compatibility wrapper for [ActionButton].
///
/// Use [ActionButton] directly for new code.
@Deprecated('Use ActionButton from package:matchday/core/design_system/design_system.dart')
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
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = busy ? null : onPressed;
    final child = busy
        ? _CkSpinner(color: _spinnerColor)
        : _CkLabel(label: label, icon: icon);

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
          style: TextButton.styleFrom(foregroundColor: Palette.red),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color get _spinnerColor =>
      variant == CkButtonVariant.primary ? Palette.paper : Palette.ink;
}

class _CkLabel extends StatelessWidget {
  const _CkLabel({required this.label, this.icon});

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon!,
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _CkSpinner extends StatelessWidget {
  const _CkSpinner({required this.color});

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
