import 'package:flutter/material.dart';

/// Semantic content-width constraints for adaptive Matchday layouts.
///
/// Prevents form fields, readable text, and input groups from stretching
/// to fill full desktop width. Always wrap form screens with [ContentWidth]
/// using an appropriate [ContentConstraint] value.
///
/// Reference: https://docs.flutter.dev/ui/adaptive-responsive/best-practices
abstract final class ContentConstraint {
  /// Narrow — form fields, registration, settings rows.
  ///
  /// Keeps inputs comfortably readable at ~ iPhone-to-small-tablet width.
  static const double form = 480;

  /// Moderate — readable body text, settings groups, information panels.
  static const double readable = 640;

  /// Wide — detail panels, two-column side-by-side content.
  static const double detail = 840;

  /// Unconstrained — dashboards, scoreboards, bracket grids, charts.
  ///
  /// Use only when the content benefits from the full available width.
  static const double dashboard = double.infinity;
}

/// Constrains its child to [maxWidth], centered horizontally.
///
/// On [WindowClass.compact] windows this is effectively a no-op because
/// the window is already narrower than most constraint values.
///
/// ```dart
/// ContentWidth(
///   maxWidth: ContentConstraint.form,
///   child: CreateTeamForm(),
/// )
/// ```
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (maxWidth == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
