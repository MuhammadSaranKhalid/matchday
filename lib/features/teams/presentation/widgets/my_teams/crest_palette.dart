import 'package:flutter/painting.dart';

import '../../../../../core/theme/circk_theme.dart';

/// A team crest's render style: the background color, two-letter monogram,
/// full team name, and optional location subtitle. Carried inline on every
/// `TeamRowVm` / `TodayMatch` / `InviteEntry` so the render layer never has
/// to look up a global table.
class CrestStyle {
  const CrestStyle({
    required this.color,
    required this.mono,
    required this.name,
    this.city,
    this.logoUrl,
  });

  final Color color;

  /// 1–3 letter team monogram (e.g. "LL", "KE"). Falls back to this when
  /// [logoUrl] is missing or fails to load.
  final String mono;

  /// Full display name (e.g. "Lahore Lions").
  final String name;

  /// Location subtitle (e.g. "Lahore · Model Town"). Optional.
  final String? city;

  /// Public URL of the team's uploaded crest. When set, renderers should
  /// prefer the image and fall back to the monogram-on-color tile on error.
  final String? logoUrl;
}

/// The 14-team static palette used by the case fixtures (mirror of the JSX
/// `CRESTS` map in design/screens/MyTeams.jsx). For real-data teams the
/// adapter synthesises a `CrestStyle` on the fly from `team.primaryColor` +
/// `teamMonogram(team.name)` — this table is fixture-only.
abstract final class MyTeamsCrests {
  static const ll = CrestStyle(
    color: Color(0xFFE24A3F),
    mono: 'LL',
    name: 'Lahore Lions',
    city: 'Lahore · Model Town',
  );
  static const ke = CrestStyle(
    color: Color(0xFF4264A8),
    mono: 'KE',
    name: 'Karachi Eagles',
    city: 'Karachi · Defence',
  );
  static const mt = CrestStyle(
    color: Color(0xFF6F5A45),
    mono: 'MT',
    name: 'Multan Tigers',
    city: 'Multan · Cantt',
  );
  static const mk = CrestStyle(
    color: Color(0xFFA67432),
    mono: 'MK',
    name: 'Mohalla Kings',
    city: 'Karachi · Korangi',
  );
  static const kc = CrestStyle(
    color: Color(0xFF2E3E63),
    mono: 'KC',
    name: 'Karachi Cobras',
    city: 'Karachi · Clifton',
  );
  static const ob = CrestStyle(
    color: Color(0xFF4A4337),
    mono: 'OB',
    name: 'Old Boys XI',
    city: 'Lahore · Cantt',
  );
  static const dh = CrestStyle(
    color: Color(0xFF2E3E63),
    mono: 'DH',
    name: 'DHA United',
    city: 'Karachi · DHA',
  );
  static const gg = CrestStyle(
    color: Color(0xFF3F8255),
    mono: 'GG',
    name: 'Gulberg Greens',
    city: 'Lahore · Gulberg',
  );
  static const it = CrestStyle(
    color: Color(0xFF5E448E),
    mono: 'IT',
    name: 'Iqbal Town XI',
    city: 'Lahore · Iqbal Town',
  );
  static const pr = CrestStyle(
    color: Color(0xFFA13C28),
    mono: 'PR',
    name: 'PAF Roosters',
    city: 'Karachi · Faisal',
  );
  static const sc = CrestStyle(
    color: Color(0xFF6E2A22),
    mono: 'SC',
    name: 'Sherwani Cricket',
    city: 'Lahore · Cantt',
  );
  static const mq = CrestStyle(
    color: Color(0xFF2F5E6B),
    mono: 'MQ',
    name: 'Mohalla Quetta',
    city: 'Quetta',
  );
  static const rs = CrestStyle(
    color: Color(0xFF8C5A2A),
    mono: 'RS',
    name: 'Rawalpindi Stars',
    city: 'Rawalpindi',
  );
  static const kh = CrestStyle(
    color: Color(0xFF7B5A48),
    mono: 'KH',
    name: 'Khaaki XI',
    city: 'Lahore · Cantt',
  );

  static const Map<String, CrestStyle> byKey = {
    'LL': ll,
    'KE': ke,
    'MT': mt,
    'MK': mk,
    'KC': kc,
    'OB': ob,
    'DH': dh,
    'GG': gg,
    'IT': it,
    'PR': pr,
    'SC': sc,
    'MQ': mq,
    'RS': rs,
    'KH': kh,
  };

  /// Looks up by two-letter key. Falls back to a neutral muted crest.
  static CrestStyle resolve(String key) =>
      byKey[key] ??
      const CrestStyle(color: CkColors.muted, mono: '??', name: '—');
}

// teamMonogram lives in `team_avatar.dart` — not duplicated here. Import
// from there when you need to synthesise a `CrestStyle` from a real `Team`.
