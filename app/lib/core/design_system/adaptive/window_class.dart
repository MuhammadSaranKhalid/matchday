import 'package:flutter/material.dart';

/// Canonical window size classifications for Matchday adaptive layout.
///
/// Layout decisions are made from the available window width, never from
/// a device-type guess. Use [WindowClass.of] at screen level for navigation
/// decisions, or [LayoutBuilder] for local widget-level constraints.
///
/// Boundary values are Matchday product decisions and may evolve.
/// Do NOT scatter raw `if (width > 600)` checks across feature code —
/// always delegate to this classification.
///
/// Reference: https://docs.flutter.dev/ui/adaptive-responsive/general
enum WindowClass {
  /// Width < 600dp — phone layout.
  ///
  /// Use [NavigationBar] (bottom). Single-column content.
  compact,

  /// 600dp ≤ width < 840dp — tablet / narrow desktop.
  ///
  /// [NavigationRail] may replace bottom bar. Content may use a mild
  /// max-width constraint. Two-column content is possible but optional.
  medium,

  /// Width ≥ 840dp — wide desktop / large tablet.
  ///
  /// [NavigationRail] or side drawer. Multi-column content encouraged.
  /// Always apply [ContentConstraint] to form and readable content.
  /// Width ≥ 840dp — wide desktop / large tablet.
  ///
  /// [NavigationRail] or side drawer. Multi-column content encouraged.
  /// Always apply [ContentConstraint] to form and readable content.
  expanded;

  /// Returns the [WindowClass] for the current window width.
  static WindowClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return WindowClass.compact;
    if (width < 840) return WindowClass.medium;
    return WindowClass.expanded;
  }

  /// True when the window is phone-sized.
  bool get isCompact => this == WindowClass.compact;

  /// True when the window is tablet-width or wider.
  bool get isMediumOrWider => index >= WindowClass.medium.index;

  /// True when the window is full desktop / large tablet width.
  bool get isExpanded => this == WindowClass.expanded;
}

/// Resolves [WindowClass] from the nearest [MediaQuery] ancestor.
///
/// Call inside a widget's `build` method to get the current window class.
/// The result is stable for a given widget subtree unless the window is resized.
extension WindowClassContext on BuildContext {
  WindowClass get windowClass => WindowClass.of(this);
}
