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

/// The team crest: rounded square in the team's primary colour with the
/// monogram in white (paper on dark).
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({
    super.key,
    required this.name,
    this.primaryColor,
    this.size = 44,
    this.radius = 12,
  });

  final String name;
  final String? primaryColor;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bg = parseHexColor(primaryColor, fallback: CkColors.ink);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        teamMonogram(name),
        style: CkType.display(
          fontSize: size * 0.38,
          letterSpacing: -0.02,
          color: CkColors.paper,
        ),
      ),
    );
  }
}
