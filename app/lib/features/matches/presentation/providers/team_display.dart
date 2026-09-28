import 'package:flutter/material.dart';

import '../../../teams/domain/entities/team.dart';

/// Crest monogram for a team, falling back to initials from the name and then
/// to [fallback]. Shared by every match surface so the same team never appears
/// as two different monograms on two screens.
String teamShort(Team? t, {required String fallback}) {
  if (t == null) return fallback;
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  final words = t.name.split(RegExp(r'\s+'));
  final letters =
      words.where((w) => w.isNotEmpty).take(3).map((w) => w[0]).join();
  return letters.isEmpty ? fallback : letters.toUpperCase();
}

/// Parses a stored `#RRGGBB` / `#AARRGGBB` team colour.
Color teamColor(String? hex, {required Color fallback}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(0xFF000000 | n);
  } else if (cleaned.length == 8) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(n);
  }
  return fallback;
}
