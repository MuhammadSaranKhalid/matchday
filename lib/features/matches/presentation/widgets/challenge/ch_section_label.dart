import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// Mono uppercase kicker shown above each section of a step body.
/// Mirrors `SectionLabel` in `challenge-shared.jsx` (lines 182–189):
/// 10pt mono · 0.10em tracking · muted · 9px bottom margin, with an optional
/// right-aligned plain hint.
class ChSectionLabel extends StatelessWidget {
  const ChSectionLabel(this.label, {super.key, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkColors.muted,
              ),
            ),
          ),
          if (hint != null && hint!.isNotEmpty)
            Text(
              hint!,
              style: CkType.body(fontSize: 11, color: CkColors.muted),
            ),
        ],
      ),
    );
  }
}
