import 'package:flutter/painting.dart';

/// Hex string ("#RRGGBB", "RRGGBB", "RRGGBBAA") → Color, with [fallback]
/// returned for any null/empty/malformed input.
///
/// The teams schema stores `team_colors->>'primary'` as a free-text hex so
/// input is untrusted. Used by both the inbox row crest and the thread
/// header crest — extracted here to avoid the duplicated-function-with-
/// drift-risk pattern flagged in the 2026-06-07 review.
Color parseHexColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return fallback;
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(v);
}
