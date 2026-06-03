import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';

/// Playing-skill labels used by the Pick-XI roster rows. UI-only enum
/// (separate from the domain's `MemberRole`, which captures captaincy /
/// keeper / vice-captain hierarchy). Callers map their domain shape onto
/// these four values at the boundary.
enum ChPlayingRole {
  bat('BAT'),
  bow('BOW'),
  ar('AR'),
  wk('WK');

  const ChPlayingRole(this.label);
  final String label;
}

/// Color-coded BAT / BOW / AR / WK chip from `RolePill` in
/// `challenge-shared.jsx` (lines 275–286). 8.5pt mono with 0.08em tracking.
class ChRolePill extends StatelessWidget {
  const ChRolePill({super.key, required this.role});

  final ChPlayingRole role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      ChPlayingRole.bat => (CkColors.paper2, CkColors.ink2),
      ChPlayingRole.bow => (CkColors.cream, CkInk.amber),
      ChPlayingRole.ar => (CkColors.greenSoft, CkInk.green),
      ChPlayingRole.wk => (CkColors.red, CkColors.paper),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.label,
        style: CkType.mono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: fg,
        ),
      ),
    );
  }
}
