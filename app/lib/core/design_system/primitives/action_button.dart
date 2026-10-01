import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Style variants for [ActionButton].
enum ActionButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
}

/// Standardized control sizes.
enum ControlSize {
  /// Visual height: 40.0. Maintains >= 48.0 interaction target.
  compact,

  /// Visual height: 48.0. Standard interactive control.
  standard,

  /// Visual height: 52.0. Prominent primary CTA.
  large,
}

/// Standardized button primitive for all application actions.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ActionButtonVariant.primary,
    this.size = ControlSize.standard,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  const ActionButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = ControlSize.standard,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = ActionButtonVariant.secondary;

  const ActionButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = ControlSize.standard,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = ActionButtonVariant.ghost;

  const ActionButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.size = ControlSize.standard,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = ActionButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final ActionButtonVariant variant;
  final ControlSize size;
  final Widget? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final effectiveOnPressed = loading ? null : onPressed;
    final visualHeight = switch (size) {
      ControlSize.compact => layout.controlCompactHeight,
      ControlSize.standard => layout.controlHeight,
      ControlSize.large => layout.controlLargeHeight,
    };

    final spinnerColor = switch (variant) {
      ActionButtonVariant.primary => scheme.onPrimary,
      ActionButtonVariant.destructive => status.live,
      _ => scheme.onSurface,
    };

    final content = loading
        ? _ButtonSpinner(color: spinnerColor)
        : _ButtonLabel(label: label, icon: icon, size: size);

    final buttonStyle = _resolveStyle(context, visualHeight);

    Widget button = switch (variant) {
      ActionButtonVariant.primary ||
      ActionButtonVariant.destructive =>
        FilledButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: content,
        ),
      ActionButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: content,
        ),
      ActionButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: content,
        ),
    };

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  ButtonStyle _resolveStyle(BuildContext context, double visualHeight) {
    final layout = context.layout;
    final scheme = context.colorScheme;

    final (fontSize, letterSpacing) = switch (size) {
      ControlSize.compact => (13.0, -0.1),
      ControlSize.standard => (15.0, -0.15),
      ControlSize.large => (16.0, -0.16),
    };

    final horizontalPadding = switch (size) {
      ControlSize.compact => 12.0,
      ControlSize.standard => 16.0,
      ControlSize.large => 20.0,
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(layout.controlRadius),
    );

    final textStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: letterSpacing,
    );

    final minSize = Size(
      expand ? double.infinity : layout.minimumTapTarget,
      visualHeight,
    );

    return switch (variant) {
      ActionButtonVariant.primary => FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.9),
          elevation: 0,
          minimumSize: minSize,
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: shape,
          textStyle: textStyle,
        ),
      ActionButtonVariant.secondary => OutlinedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          disabledBackgroundColor: scheme.surface.withValues(alpha: 0.5),
          disabledForegroundColor: scheme.outline,
          elevation: 0,
          minimumSize: minSize,
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          side: BorderSide(color: scheme.outline),
          shape: shape,
          textStyle: textStyle,
        ),
      ActionButtonVariant.ghost => TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          disabledForegroundColor: scheme.outline,
          elevation: 0,
          minimumSize: minSize,
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: shape,
          textStyle: textStyle,
        ),
      ActionButtonVariant.destructive => FilledButton.styleFrom(
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
          disabledBackgroundColor: scheme.errorContainer.withValues(alpha: 0.4),
          disabledForegroundColor: scheme.onErrorContainer.withValues(alpha: 0.4),
          elevation: 0,
          minimumSize: minSize,
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          side: BorderSide(color: scheme.error.withValues(alpha: 0.25)),
          shape: shape,
          textStyle: textStyle,
        ),
    };
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.label,
    required this.icon,
    required this.size,
  });

  final String label;
  final Widget? icon;
  final ControlSize size;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);

    final gap = size == ControlSize.compact ? 6.0 : 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon!,
        SizedBox(width: gap),
        Text(label),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: color,
      ),
    );
  }
}
