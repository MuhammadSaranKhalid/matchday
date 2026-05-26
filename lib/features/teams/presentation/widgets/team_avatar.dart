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

/// The team crest. Renders the uploaded logo when [logoUrl] is set; falls
/// back to a rounded square in the team's primary colour with the monogram
/// in paper text. [monogram] overrides the auto-derived value when set.
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({
    super.key,
    required this.name,
    this.primaryColor,
    this.logoUrl,
    this.monogram,
    this.size = 44,
    this.radius = 12,
  });

  final String name;
  final String? primaryColor;
  final String? logoUrl;

  /// 1–3 letter override. When null/blank, derived from [name].
  final String? monogram;

  final double size;
  final double radius;

  String get _mono {
    final override = monogram?.trim();
    if (override != null && override.isNotEmpty) {
      return override.toUpperCase();
    }
    return teamMonogram(name);
  }

  Widget _monoTile() {
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
        _mono,
        style: CkType.display(
          fontSize: size * 0.38,
          letterSpacing: -0.02,
          color: CkColors.paper,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) return _monoTile();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: CkColors.paper2,
        child: Image.network(
          logoUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _monoTile(),
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : _monoTile(),
        ),
      ),
    );
  }
}
