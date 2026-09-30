/// Standardized sizing foundation for controls, touch targets, and visual primitives.
abstract final class Sizing {
  /// Minimum accessible interaction target (48x48 dp Android, 44x44 pt iOS).
  static const minimumTapTarget = 48.0;

  // Control heights
  /// Compact control visual height (40.0). Retains >= 48.0 interaction target.
  static const controlCompactHeight = 40.0;

  /// Standard control visual height (48.0).
  static const controlHeight = 48.0;

  /// Prominent/large primary CTA height (52.0).
  static const controlLargeHeight = 52.0;

  // Icon sizing
  static const iconSmall = 16.0;
  static const iconMedium = 20.0;
  static const iconLarge = 24.0;

  // Avatar sizing
  static const avatarSmall = 28.0;
  static const avatarMedium = 40.0;
  static const avatarLarge = 56.0;
}
