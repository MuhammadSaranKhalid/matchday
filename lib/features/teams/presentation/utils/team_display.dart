import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';

/// Parse a `#RRGGBB` (or `RRGGBB`) hex string into a [Color]. Falls back to
/// [fallback] on anything malformed.
Color parseHexColor(String? hex, {Color fallback = CkColors.ink}) {
  if (hex == null) return fallback;
  var h = hex.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  return value == null ? fallback : Color(value);
}

/// Crest letters for a team, honouring an owner's `logo_monogram` [override].
///
/// Most teams never upload a logo, so this is the common rendering, not a
/// loading state. Derivation:
///   • 1 word    → first 2 letters   (Ravens → RA)
///   • 2–3 words → initials          (Lahore Lions → LL, Dera Sports Stars → DSS)
///   • 4+ words  → first 3 initials
///   • non-Latin → first grapheme only
///
/// [maxLetters] trims the result for small discs — at 22px three letters is a
/// smudge, so the crest asks for one.
String teamCrestMonogram(String name, {String? override, int maxLetters = 3}) {
  final trimmed = override?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return _clamp(trimmed.toUpperCase(), maxLetters);
  }

  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '–';

  // Non-Latin scripts carry no useful initial beyond the first character —
  // stacking three Urdu or Devanagari graphemes reads as noise.
  if (!RegExp(r'^[A-Za-z]').hasMatch(words.first)) {
    return _clamp(words.first.characters.take(1).toString(), maxLetters);
  }

  if (words.length == 1) {
    final w = words.first;
    return _clamp((w.length >= 2 ? w.substring(0, 2) : w).toUpperCase(), maxLetters);
  }
  return _clamp(
    words.take(3).map((w) => w[0]).join().toUpperCase(),
    maxLetters,
  );
}

String _clamp(String s, int max) => s.length <= max ? s : s.substring(0, max);

/// Inverse of [parseHexColor] — `#RRGGBB` for a [Color]. Crest call sites
/// take the stored wire format so a row that never parsed the colour can
/// still pass one through.
String hexOf(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

/// Two-letter monogram from a team name. Used where a fixed-width short label
/// is expected (score rows, match boards) — the crest uses
/// [teamCrestMonogram], which can return three.
String teamMonogram(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '–';
  if (words.length == 1) {
    final w = words.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (words.first[0] + words.elementAt(1)[0]).toUpperCase();
}
