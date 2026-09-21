import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/completed_match_view.dart';
import 'cm_atoms.dart';

/// The result card: both innings, then one band of colour stating the outcome.
///
/// The two sides are told apart by weight and position, never by hue — the
/// winner is ink at 700, the other ink2 at 600. Green is spent once here and
/// nowhere else on the screen, so a tie (which lights neither side) reads as
/// genuinely level rather than as a quiet loss.
class CmResultCard extends StatelessWidget {
  const CmResultCard({required this.view, super.key});

  final CompletedMatchView view;

  @override
  Widget build(BuildContext context) {
    final (bandColor, bandInk) = switch (view.tone) {
      ResultTone.won => (CkColors.greenSurface, CkColors.greenInk),
      ResultTone.tied => (CkColors.cream, CkColors.amberInk),
      ResultTone.none => (CkColors.paper2, CkColors.ink2),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CmPanel(
          children: [
            for (final (i, s) in view.sides.indexed)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  13,
                  i == 0 ? 11 : 6,
                  13,
                  i == 0 ? 6 : 11,
                ),
                child: _SideRow(side: s),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: bandColor,
                border: const Border(top: BorderSide(color: CkColors.hairline)),
              ),
              child: Text(
                view.sentence,
                style: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: bandInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          view.metaLine.toUpperCase(),
          style: CmText.label(size: 9.5).copyWith(letterSpacing: 9.5 * 0.07),
        ),
      ],
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({required this.side});

  final CompletedSide side;

  @override
  Widget build(BuildContext context) {
    final weight = side.won ? FontWeight.w700 : FontWeight.w600;
    final ink = side.won ? CkColors.ink : CkColors.ink2;

    return Row(
      children: [
        CmCrest(side.color, size: 20, text: side.short),
        const SizedBox(width: 9),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  side.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CmText.name(size: 15, weight: weight, color: ink),
                ),
              ),
              // The viewer's own side is marked in mono grey, not colour —
              // colour on this screen means "won", and "yours" is not "won".
              if (side.isYou) ...[
                const SizedBox(width: 5),
                Text('YOU', style: CmText.label(size: 9, color: CkColors.soft)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 9),
        if (side.batted) ...[
          Text(
            side.scoreLabel,
            style: CmText.figure(size: 16, weight: weight, color: ink),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 36,
            child: Text(
              side.oversLabel ?? '',
              textAlign: TextAlign.right,
              style: CmText.figure(
                size: 10,
                weight: FontWeight.w600,
                color: CkColors.muted,
              ),
            ),
          ),
        ] else
          // Never 0/0: a side that never batted was not bowled out for nothing.
          Text(
            'Did not bat',
            style: CmText.name(
              size: 12,
              weight: FontWeight.w500,
              color: CkColors.muted,
            ),
          ),
      ],
    );
  }
}
