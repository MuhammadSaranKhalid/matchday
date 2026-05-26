import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// Section subhead — mono uppercase label, optional accent color, optional
/// trailing `· N` count. Used between every section of the My Teams body.
class Subhead extends StatelessWidget {
  const Subhead(
    this.label, {
    super.key,
    this.accent,
    this.count,
  });

  /// Header text — rendered as-typed (the JSX source uses Title Case, not
  /// uppercase — the mono style font is what gives it the "label" feel).
  final String label;

  /// Color override for the label (e.g. red on "Invites · 2").
  final Color? accent;

  /// When non-null renders ` · N` next to the label in muted mono.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: accent ?? CkColors.muted,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '· $count',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.10,
                color: CkColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
