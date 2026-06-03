/// Inner SVG path data for the Match Challenge Flow icons, lifted verbatim
/// from `challenge-shared.jsx::PATHS`.
///
/// Rendered via `V2Svg` (lib/core/widgets/v2/v2_kit.dart) which wraps each
/// path string in a 24-viewBox SVG with stroke/fill applied at runtime.
abstract final class ChIcons {
  /// Chevron-left back arrow.
  static const back = '<path d="M15 18l-6-6 6-6"/>';

  /// Chevron-right next arrow.
  static const next = '<path d="M9 18l6-6-6-6"/>';

  /// Right-arrow with extender used inside the primary CTA.
  static const arrow = '<path d="M5 12h14M13 6l6 6-6 6"/>';

  /// Checkmark drawn as a path element so V2Svg's renderer handles it.
  static const check = '<path d="M20 6L9 17l-5-5"/>';

  static const search =
      '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>';

  static const pin =
      '<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>'
      '<circle cx="12" cy="10" r="3"/>';

  static const cal =
      '<rect x="3" y="5" width="18" height="16" rx="2"/>'
      '<path d="M3 10h18M8 3v4M16 3v4"/>';

  /// Wicket-keeper glove.
  static const glove =
      '<path d="M6 11V6.5a1.5 1.5 0 0 1 3 0V10m0 0V4.5a1.5 1.5 0 0 1 3 0V10m0-0.5V5.5a1.5 1.5 0 0 1 3 0V12m0-3.5a1.5 1.5 0 0 1 3 0V15a6 6 0 0 1-6 6h-2a6 6 0 0 1-5.2-3l-2.3-4a1.5 1.5 0 0 1 2.6-1.5L6 14"/>';

  static const copy =
      '<rect x="9" y="9" width="11" height="11" rx="2"/>'
      '<path d="M5 15V5a2 2 0 0 1 2-2h8"/>';

  static const share =
      '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/>'
      '<circle cx="18" cy="19" r="3"/>'
      '<path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>';

  /// Crossed-swords used as the vs glyph on the Sent preview card.
  static const swords =
      '<path d="M14.5 17.5 22 10l-2-2-7.5 7.5M9.5 6.5 2 14l2 2 7.5-7.5"/>';
}
