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
    final actionVariant = switch (variant) {
      CkButtonVariant.primary => ActionButtonVariant.primary,
      CkButtonVariant.secondary => ActionButtonVariant.secondary,
      CkButtonVariant.ghost => ActionButtonVariant.ghost,
    };

    return ActionButton(
      label: label,
      onPressed: onPressed,
      variant: actionVariant,
      size: ControlSize.large,
      icon: icon,
      loading: busy,
      expand: expand,
    );
  }
}
