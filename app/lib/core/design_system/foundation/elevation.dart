import 'package:flutter/material.dart';

/// Matchday elevation system.
///
/// Intentionally minimal — Matchday is a flat design language.
/// Only three levels are defined; do not add more without a documented
/// reason why the existing levels are insufficient.
///
/// Usage:
/// ```dart
/// decoration: BoxDecoration(
///   boxShadow: Elevation.raised,
/// )
/// ```
abstract final class Elevation {
  /// No shadow — flat surface (default for most components).
  static const List<BoxShadow> none = [];

  /// Subtle card lift — for elevated cards and tappable surfaces.
  ///
  /// Equivalent to Material elevation 1.
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x0D000000), // ~5% black
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  /// Overlay shadow — modals, bottom sheets, floating action elements.
  ///
  /// Equivalent to Material elevation 3.
  static const List<BoxShadow> overlay = [
    BoxShadow(
      color: Color(0x1A000000), // ~10% black
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];
}
