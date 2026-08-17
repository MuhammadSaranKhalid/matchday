import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/domain/entities/team.dart';

String matchStartShortTeamName(Team? t) {
  if (t == null) return '??';
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  final letters = t.name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join();
  return letters.isEmpty ? '??' : letters.toUpperCase();
}

Color matchStartTeamColor(String? hex) {
  if (hex == null || hex.isEmpty) return CkColors.muted;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(0xFF000000 | n);
  } else if (cleaned.length == 8) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(n);
  }
  return CkColors.muted;
}
