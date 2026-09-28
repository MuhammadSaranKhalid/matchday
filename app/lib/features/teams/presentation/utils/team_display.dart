import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';

Color parseHexColor(String? hex, {Color fallback = CkColors.ink}) {
  if (hex == null) return fallback;
  var h = hex.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  return value == null ? fallback : Color(value);
}

String teamCrestMonogram(String name, {String? override, int maxLetters = 3}) {
  final trimmed = override?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return _clamp(trimmed.toUpperCase(), maxLetters);
  }

  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '–';

  if (!RegExp(r'^[A-Za-z]').hasMatch(words.first)) {
    return _clamp(words.first.characters.take(1).toString(), maxLetters);
  }

  if (words.length == 1) {
    final w = words.first;
    return _clamp(
      (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase(),
      maxLetters,
    );
  }
  return _clamp(
    words.take(3).map((w) => w[0]).join().toUpperCase(),
    maxLetters,
  );
}

String _clamp(String s, int max) => s.length <= max ? s : s.substring(0, max);

String hexOf(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

String teamMonogram(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '–';
  if (words.length == 1) {
    final w = words.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (words.first[0] + words.elementAt(1)[0]).toUpperCase();
}
