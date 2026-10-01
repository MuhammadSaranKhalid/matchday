/// Matchday border-width system.
///
/// Three semantic levels cover all interactive states in the design language.
/// Reference these constants wherever a border width is needed rather than
/// using raw numeric literals.
///
/// Usage:
/// ```dart
/// BorderSide(color: scheme.outline, width: Borders.standard)
/// ```
abstract final class Borders {
  /// Hairline — dividers, section separators, subtle structural lines (1.0dp).
  static const double hairline = 1.0;

  /// Standard — interactive control borders, card outlines (1.5dp).
  ///
  /// Used for inputs, chips, cards, and unselected segmented tabs.
  static const double standard = 1.5;

  /// Emphasized — selected state rings, focused controls (2.0dp).
  ///
  /// Use to visually differentiate a selected or focused control from
  /// its siblings without changing color alone.
  static const double emphasized = 2.0;
}
