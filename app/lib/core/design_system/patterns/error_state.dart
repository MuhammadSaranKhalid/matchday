import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';
import '../primitives/action_button.dart';

/// Semantic classification of error states.
enum ErrorStateKind {
  generic,
  offline,
  permission,
}

/// Standardized error state pattern.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.description,
    this.kind = ErrorStateKind.generic,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.icon,
  });

  final String title;
  final String? description;
  final ErrorStateKind kind;
  final VoidCallback? onRetry;
  final String retryLabel;
  final dynamic icon;

  @override
  Widget build(BuildContext context) {
    final defaultIcon = switch (kind) {
      ErrorStateKind.generic => Icons.error_outline,
      ErrorStateKind.offline => Icons.wifi_off_outlined,
      ErrorStateKind.permission => Icons.lock_outline,
    };

    final iconWidget = icon is IconData
        ? Icon(icon as IconData, size: 28, color: Palette.redInk)
        : icon is Widget
            ? (icon as Widget)
            : Icon(defaultIcon, size: 28, color: Palette.redInk);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Palette.redSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.redBorder),
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                  letterSpacing: -0.01,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    height: 1.45,
                    color: Palette.muted,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: Spacing.lg),
                ActionButton(
                  label: retryLabel,
                  onPressed: onRetry,
                  size: ControlSize.compact,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
