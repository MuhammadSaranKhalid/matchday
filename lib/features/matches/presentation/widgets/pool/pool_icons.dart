import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Pool board's icon set, transcribed verbatim from `Pool.dc.html`
/// (artboards 01–05).
///
/// Unlike [V2Svg] these keep each glyph's own viewBox and its baked stroke /
/// fill colours, because the design draws several of them mixed-mode (the
/// verified tick is a cream disc with an ink check) and at viewBoxes other
/// than 24. Every one of these has exactly one role on the board, so the
/// colour is part of the icon rather than a parameter.
abstract final class PoolIcons {
  /// Card meta — proposed start time.
  static const String clock =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">'
      '<circle cx="8" cy="8" r="6" stroke="#8A8170" stroke-width="1.3"/>'
      '<path d="M8 5v3l2 1.3" stroke="#8A8170" stroke-width="1.3" stroke-linecap="round"/>'
      '</svg>';

  /// Card meta — proposed ground.
  static const String pin =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">'
      '<path d="M8 2c2.3 0 4 1.7 4 4 0 2.8-4 7-4 7S4 8.8 4 6c0-2.3 1.7-4 4-4z" stroke="#8A8170" stroke-width="1.3"/>'
      '<circle cx="8" cy="6" r="1.4" fill="#8A8170"/>'
      '</svg>';

  /// Beside a verified team's name on a challenge card.
  static const String verified =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 14">'
      '<circle cx="7" cy="7" r="7" fill="#F4ECDD"/>'
      '<path d="M4 7l2 2 4-4.2" stroke="#29251E" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// Empty state — a quiet megaphone on seam cream.
  static const String silentBoard =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" fill="none">'
      '<path d="M3 7v4l8 3V4L3 7z" stroke="#29251E" stroke-width="1.3" stroke-linejoin="round"/>'
      '<path d="M3 7H2.2v4H3" stroke="#29251E" stroke-width="1.3"/>'
      '<path d="M12 6.6c1.4.6 1.4 4.2 0 4.8" stroke="#29251E" stroke-width="1.3" stroke-linecap="round"/>'
      '</svg>';

  /// Empty state — the share-code row's leading tile.
  static const String shareCode =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">'
      '<rect x="2.5" y="2.5" width="11" height="11" rx="2" stroke="#4A4339" stroke-width="1.2"/>'
      '<path d="M5 6h6M5 8.3h6M5 10.6h3.5" stroke="#4A4339" stroke-width="1.2" stroke-linecap="round"/>'
      '</svg>';

  /// Error state — a parted connector. Calm, not alarming.
  static const String disconnected =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">'
      '<path d="M4 17V9a2 2 0 0 1 2-2h5" stroke="#8A8170" stroke-width="1.4" stroke-linecap="round"/>'
      '<path d="M20 7v8a2 2 0 0 1-2 2h-5" stroke="#8A8170" stroke-width="1.4" stroke-linecap="round"/>'
      '<path d="M8 20l-3-3 3-3M16 4l3 3-3 3" stroke="#8A8170" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// Error state — inside the ink Retry button, so it is drawn in paper.
  static const String retry =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">'
      '<path d="M13 8a5 5 0 1 1-1.5-3.5" stroke="#FBFAF6" stroke-width="1.5" stroke-linecap="round"/>'
      '<path d="M13 2.5V5h-2.5" stroke="#FBFAF6" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// No-team gate — a padlock on the cream banner.
  static const String locked =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" fill="none">'
      '<rect x="3" y="8" width="12" height="8" rx="2" stroke="#29251E" stroke-width="1.3"/>'
      '<path d="M6 8V6a3 3 0 0 1 6 0v2" stroke="#29251E" stroke-width="1.3"/>'
      '</svg>';
}

/// Renders one of [PoolIcons] at [size], preserving its own viewBox.
class PoolIcon extends StatelessWidget {
  const PoolIcon(this.svg, {super.key, required this.size});

  final String svg;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(svg, width: size, height: size);
}
