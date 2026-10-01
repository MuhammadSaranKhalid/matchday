import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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

  /// Convenience factory to construct an [ActionIconButton] directly from [IconData].
  factory ActionIconButton.fromIconData(
    IconData iconData, {
    Key? key,
    VoidCallback? onPressed,
    ActionIconButtonVariant variant = ActionIconButtonVariant.standard,
    String? tooltip,
    double size = 36.0,
    double iconSize = 20.0,
    Color? color,
  }) {
    return ActionIconButton(
      key: key,
      icon: Icon(iconData, size: iconSize, color: color),
      onPressed: onPressed,
      variant: variant,
      tooltip: tooltip,
      size: size,
    );
  }

  /// The icon widget to display. Must be strongly typed [Widget].
  final Widget icon;

  final VoidCallback? onPressed;
  final ActionIconButtonVariant variant;
  final String? tooltip;

  /// Visual diameter of the button container (default: 36.0).
  final double size;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final (bg, border, fg) = switch (variant) {
      ActionIconButtonVariant.standard => (
          Colors.transparent,
          null,
          scheme.onSurface,
        ),
      ActionIconButtonVariant.outlined => (
          scheme.surface,
          Border.all(color: scheme.outline),
          scheme.onSurface,
        ),
      ActionIconButtonVariant.subtle => (
          status.neutralSurface,
          null,
          scheme.onSurface,
        ),
    };

    final visualContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: IconTheme.merge(
        data: IconThemeData(color: fg, size: 20),
        child: icon,
      ),
    );

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: Size(
          layout.minimumTapTarget,
          layout.minimumTapTarget,
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.zero,
      ),
      icon: visualContainer,
    );
  }
}
