import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/sizing.dart';

/// Style variants for [ActionIconButton].
enum ActionIconButtonVariant {
  standard,
  outlined,
  subtle,
}

/// Standardized icon button primitive for navigation and header actions.
///
/// Owns accessible tap targets (>= 48x48 dp) while preserving compact visual
/// affordance (36x36 dp).
class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = ActionIconButtonVariant.standard,
    this.tooltip,
    this.size = 36.0,
  });

  const ActionIconButton.outlined({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 36.0,
  }) : variant = ActionIconButtonVariant.outlined;

  const ActionIconButton.subtle({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 36.0,
  }) : variant = ActionIconButtonVariant.subtle;

  /// The icon to display. Can be [IconData] or any [Widget].
  final dynamic icon;

  final VoidCallback? onPressed;
  final ActionIconButtonVariant variant;
  final String? tooltip;

  /// Visual diameter of the button container (default: 36.0).
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (variant) {
      ActionIconButtonVariant.standard => (
          Colors.transparent,
          null,
          Palette.ink,
        ),
      ActionIconButtonVariant.outlined => (
          Palette.paper,
          Border.all(color: Palette.line),
          Palette.ink,
        ),
      ActionIconButtonVariant.subtle => (
          Palette.paper2,
          null,
          Palette.ink,
        ),
    };

    final iconWidget = icon is IconData
        ? Icon(icon as IconData, size: 20, color: fg)
        : (icon as Widget);

    final visualContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: iconWidget,
    );

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(
          Sizing.minimumTapTarget,
          Sizing.minimumTapTarget,
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.zero,
      ),
      icon: visualContainer,
    );
  }
}
