import 'package:flutter/material.dart';

import '../actions/action_button.dart';
import '../../theme/app_theme.dart';

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

  /// Convenience factory to construct [EmptyState] directly from an [IconData].
  factory EmptyState.fromIconData({
    Key? key,
    required String title,
    IconData? icon,
    IconData? iconData,
    EmptyStateKind kind = EmptyStateKind.firstRun,
    String? description,
    StateAction? primaryAction,
    StateAction? secondaryAction,
  }) {
    assert(icon != null || iconData != null, 'Either icon or iconData must be provided');
    return EmptyState(
      key: key,
      title: title,
      kind: kind,
      icon: Icon(icon ?? iconData!),
      description: description,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
    );
  }

  final String title;
  final EmptyStateKind kind;
  final Widget? icon;
  final String? description;
  final StateAction? primaryAction;
  final StateAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;
    final textTheme = context.textTheme;

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

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: status.neutralSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: IconTheme.merge(
                    data: IconThemeData(size: iconSize, color: scheme.onSurfaceVariant),
                    child: icon!,
                  ),
                ),
                SizedBox(height: layout.cardPadding),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                      fontSize: titleSize,
                      fontWeight: titleWeight,
                      color: scheme.onSurface,
                      letterSpacing: -0.01,
                    ) ??
                    TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: titleSize,
                      fontWeight: titleWeight,
                      color: scheme.onSurface,
                      letterSpacing: -0.01,
                    ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                SizedBox(height: layout.inlineGap),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                        fontSize: 13.5,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ) ??
                      TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (primaryAction != null || secondaryAction != null) ...[
                SizedBox(height: layout.sectionGap),
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
                  SizedBox(height: layout.inlineGap),
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

/// A scrollable container for state widgets (empty, error) that ensures
/// [RefreshIndicator] can activate even when the content does not naturally
/// exceed the viewport.
class ScrollableStateRegion extends StatelessWidget {
  const ScrollableStateRegion({
    super.key,
    required this.child,
    this.padding,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: physics,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}
