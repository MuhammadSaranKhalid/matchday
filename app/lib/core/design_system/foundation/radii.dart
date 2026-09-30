/// Standardized corner radii foundation.
///
/// Encodes foundational scale (`xs` through `pill`) as well as semantic
/// defaults for controls, cards, modals, and hero elements.
abstract final class Radii {
  /// 4.0
  static const xs = 4.0;

  /// 8.0
  static const sm = 8.0;

  /// 14.0
  static const md = 14.0;

  /// 20.0
  static const lg = 20.0;

  /// 28.0
  static const xl = 28.0;

  /// 999.0 — fully rounded / capsule
  static const pill = 999.0;

  // Semantic radii
  static const control = md; // 14.0
  static const card = md;    // 14.0
  static const modal = lg;   // 20.0
  static const hero = lg;    // 20.0
}
