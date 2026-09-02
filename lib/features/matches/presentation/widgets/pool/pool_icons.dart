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

  // ── Section C — host managing a challenge (artboards 12–19) ────────────

  /// My challenges — empty. The board's megaphone, muted onto paper-2.
  static const String silentBoardMuted =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" fill="none">'
      '<path d="M3 7v4l8 3V4L3 7z" stroke="#8A8170" stroke-width="1.3" stroke-linejoin="round"/>'
      '<path d="M3 7H2.2v4H3" stroke="#8A8170" stroke-width="1.3"/>'
      '<path d="M12 6.6c1.4.6 1.4 4.2 0 4.8" stroke="#8A8170" stroke-width="1.3" stroke-linecap="round"/>'
      '</svg>';

  /// Inside the ink "New challenge" button, so it is drawn in paper.
  static const String plusPaper =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 14" fill="none">'
      '<path d="M7 2v10M2 7h10" stroke="#FBFAF6" stroke-width="1.6" stroke-linecap="round"/>'
      '</svg>';

  /// Host detail — the header's share action.
  static const String share =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" fill="none">'
      '<circle cx="4.5" cy="9" r="2" stroke="#4A4339" stroke-width="1.4"/>'
      '<circle cx="13.5" cy="4.5" r="2" stroke="#4A4339" stroke-width="1.4"/>'
      '<circle cx="13.5" cy="13.5" r="2" stroke="#4A4339" stroke-width="1.4"/>'
      '<path d="M6.3 8l5.4-3M6.3 10l5.4 3" stroke="#4A4339" stroke-width="1.4"/>'
      '</svg>';

  /// Applicant row — "Review & decide" affordance.
  static const String chevronRightSoft =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 14" fill="none">'
      '<path d="M5 3l4 4-4 4" stroke="#B9B1A2" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// A settled applicant row, which expands rather than deciding.
  static const String chevronDownSoft =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 14" fill="none">'
      '<path d="M4 6l3 3 3-3" stroke="#B9B1A2" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// Accept sheet — the consequence that is good news.
  static const String consequenceGood =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="none">'
      '<path d="M4 10.5l3.5 3.5L16 6" stroke="#276B34" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// Accept sheet — the consequence that cannot be undone.
  static const String consequenceWarning =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="none">'
      '<path d="M10 3.5L18 16H2L10 3.5z" stroke="#B23A22" stroke-width="1.5" stroke-linejoin="round"/>'
      '<path d="M10 8v3.2" stroke="#B23A22" stroke-width="1.5" stroke-linecap="round"/>'
      '<circle cx="10" cy="13.4" r="0.8" fill="#B23A22"/>'
      '</svg>';

  // ── Section B — posting a challenge (artboards 06–11) ──────────────────

  /// The fork's Open card — the board's megaphone, in ink.
  static const String broadcast =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" fill="none">'
      '<path d="M3 7v4l8 3V4L3 7z" stroke="#29251E" stroke-width="1.3" stroke-linejoin="round"/>'
      '<path d="M3 7H2.2v4H3" stroke="#29251E" stroke-width="1.3"/>'
      '<path d="M12 6.6c1.4.6 1.4 4.2 0 4.8" stroke="#29251E" stroke-width="1.3" stroke-linecap="round"/>'
      '</svg>';

  /// The fork's Direct card — a target, for one known team.
  static const String target =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="none">'
      '<circle cx="10" cy="10" r="7.2" stroke="#4A4339" stroke-width="1.3"/>'
      '<circle cx="10" cy="10" r="3.4" stroke="#4A4339" stroke-width="1.3"/>'
      '<circle cx="10" cy="10" r="0.6" fill="#4A4339"/>'
      '</svg>';

  /// Filled tick on an ink disc — the fork's chosen card, and a picked player.
  static const String checkFilled =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 22 22">'
      '<circle cx="11" cy="11" r="9.5" fill="#29251E"/>'
      '<path d="M7 11l2.6 2.6L15 8" stroke="#FBFAF6" stroke-width="1.7" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// When & where — the "Pick" day chip.
  static const String calendar =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">'
      '<rect x="2.5" y="3.5" width="11" height="10" rx="1.5" stroke="#4A4339" stroke-width="1.2"/>'
      '<path d="M2.5 6h11M5.5 2v3M10.5 2v3" stroke="#4A4339" stroke-width="1.2" stroke-linecap="round"/>'
      '</svg>';

  /// When & where — the start-time field.
  static const String clockMuted =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">'
      '<circle cx="8" cy="8" r="6.3" stroke="#8A8170" stroke-width="1.2"/>'
      '<path d="M8 4.6v3.6l2.2 1.4" stroke="#8A8170" stroke-width="1.2" stroke-linecap="round"/>'
      '</svg>';

  /// When & where — the venue field. Ink, unlike the card's muted pin.
  static const String pinInk =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">'
      '<path d="M8 2c2.3 0 4 1.7 4 4 0 2.8-4 7-4 7S4 8.8 4 6c0-2.3 1.7-4 4-4z" stroke="#4A4339" stroke-width="1.3"/>'
      '<circle cx="8" cy="6" r="1.4" fill="#4A4339"/>'
      '</svg>';

  /// Success — the payoff mark, on the ink tile.
  static const String checkLarge =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">'
      '<path d="M5 12.5l4.5 4.5L19 7" stroke="#FBFAF6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  /// Success — Share, on the ink button.
  static const String sharePaper =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" fill="none">'
      '<circle cx="4.5" cy="9" r="2" stroke="#FBFAF6" stroke-width="1.4"/>'
      '<circle cx="13.5" cy="4.5" r="2" stroke="#FBFAF6" stroke-width="1.4"/>'
      '<circle cx="13.5" cy="13.5" r="2" stroke="#FBFAF6" stroke-width="1.4"/>'
      '<path d="M6.3 8l5.4-3M6.3 10l5.4 3" stroke="#FBFAF6" stroke-width="1.4"/>'
      '</svg>';

  /// Success — Copy, on the cream-bordered button.
  static const String copy =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" fill="none">'
      '<rect x="6" y="6" width="9" height="9" rx="2" stroke="#29251E" stroke-width="1.4"/>'
      '<path d="M12 6V4.5A1.5 1.5 0 0 0 10.5 3h-6A1.5 1.5 0 0 0 3 4.5v6A1.5 1.5 0 0 0 4.5 12H6" stroke="#29251E" stroke-width="1.4"/>'
      '</svg>';

  /// Withdraw sheet — on the red-soft tile.
  static const String discard =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">'
      '<path d="M5 7h14M9 7V5.5A1.5 1.5 0 0 1 10.5 4h3A1.5 1.5 0 0 1 15 5.5V7M7 7l1 12a1.5 1.5 0 0 0 1.5 1.4h5A1.5 1.5 0 0 0 16 19L17 7" stroke="#DC4D32" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>'
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
