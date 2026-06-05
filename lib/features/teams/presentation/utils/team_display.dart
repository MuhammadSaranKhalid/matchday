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

/// Two-letter monogram from a team name.
String teamMonogram(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '–';
  if (words.length == 1) {
    final w = words.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (words.first[0] + words.elementAt(1)[0]).toUpperCase();
}
