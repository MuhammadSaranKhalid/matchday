import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../utils/team_display.dart';

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
    final memW = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: CkColors.paper2,
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          memCacheWidth: memW,
          errorWidget: (_, __, ___) => _monoTile(),
          placeholder: (_, __) => _monoTile(),
        ),
      ),
    );
  }
}
