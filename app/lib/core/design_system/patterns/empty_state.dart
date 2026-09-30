import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';
import '../primitives/action_button.dart';

/// Semantic classification of empty states.
enum EmptyStateKind {
  /// Prominent onboarding or initial empty state with full CTA hierarchy.
  firstRun,

  /// Compact empty state embedded within a section or card container.
  section,

  /// Search or filter result empty state.
  filtered,

  /// Informational empty state without a primary CTA.
  passive,
}

/// Action model for empty and error state actions.
class StateAction {
  const StateAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? icon;
}

/// Standardized empty state pattern.
///
/// Encapsulates icon geometry, title/body typographic scale, action spacing,
/// and maximum line widths according to semantic [EmptyStateKind].
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.kind = EmptyStateKind.firstRun,
    this.icon,
    this.description,
    this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final EmptyStateKind kind;
  final dynamic icon;
  final String? description;
  final StateAction? primaryAction;
  final StateAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final (iconSize, iconBoxSize, titleSize, titleWeight, maxContentWidth) =
        switch (kind) {
      EmptyStateKind.firstRun => (
          32.0,
          64.0,
          19.0,
          FontWeight.w700,
          340.0,
        ),
      EmptyStateKind.section => (
          22.0,
          44.0,
          15.0,
          FontWeight.w600,
          280.0,
        ),
      EmptyStateKind.filtered => (
          24.0,
          48.0,
          16.0,
          FontWeight.w600,
          300.0,
        ),
      EmptyStateKind.passive => (
          24.0,
          48.0,
          15.0,
          FontWeight.w600,
          300.0,
        ),
    };

    final iconWidget = icon is IconData
        ? Icon(icon as IconData, size: iconSize, color: Palette.muted)
        : (icon as Widget?);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconWidget != null) ...[
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: Palette.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(color: Palette.hairline),
                  ),
                  alignment: Alignment.center,
                  child: iconWidget,
                ),
                const SizedBox(height: Spacing.md),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: titleSize,
                  fontWeight: titleWeight,
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
              if (primaryAction != null || secondaryAction != null) ...[
                const SizedBox(height: Spacing.lg),
                if (primaryAction != null)
                  ActionButton(
                    label: primaryAction!.label,
                    onPressed: primaryAction!.onPressed,
                    icon: primaryAction!.icon,
                    size: kind == EmptyStateKind.firstRun
                        ? ControlSize.standard
                        : ControlSize.compact,
                    expand: false,
                  ),
                if (secondaryAction != null) ...[
                  const SizedBox(height: Spacing.xs),
                  ActionButton.ghost(
                    label: secondaryAction!.label,
                    onPressed: secondaryAction!.onPressed,
                    icon: secondaryAction!.icon,
                    size: ControlSize.compact,
                    expand: false,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared layout region that vertically balances state widgets (empty, error, loading)
/// within available scrollable or full-page viewport space.
class StateRegion extends StatelessWidget {
  const StateRegion({
    super.key,
    required this.child,
    this.minHeight = 280.0,
  });

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : minHeight;

        return SizedBox(
          height: height,
          width: double.infinity,
          child: Center(
            child: child,
          ),
        );
      },
    );
  }
}
