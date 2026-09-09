import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/my_matches_view.dart';

/// A Past-tab result — `My Matches.dc.html` artboards 08 / 09 / 10.
///
/// The result **sentence** is the hero, not the chip: "Lions won by 24 runs"
/// says more than a green `WON` ever can, and the chip beside it is only the
/// one-word summary. The losing side's name and score drop to ink-2 so the
/// board can be read down the left edge without parsing numbers.
class PastCard extends StatelessWidget {
  const PastCard({super.key, required this.v, required this.onTap});

  final MyMatchPast v;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head(),
              // A walkover was never bowled. Printing 0/0 would be a lie, so
              // the score block is replaced by the reason.
              if (v.showScores) ...[
                _scoreRow(
                  short: v.homeShort,
                  color: v.homeColor,
                  name: v.homeName,
                  runs: v.homeRuns,
                  wkts: v.homeWkts,
                  overs: v.homeOvers,
                  isYou: v.mineIsHome,
                  won: v.homeWon,
                  padding: const EdgeInsets.fromLTRB(13, 9, 13, 4),
                ),
                _scoreRow(
                  short: v.awayShort,
                  color: v.awayColor,
                  name: v.awayName,
                  runs: v.awayRuns,
                  wkts: v.awayWkts,
                  overs: v.awayOvers,
                  isYou: !v.mineIsHome,
                  won: !v.homeWon,
                  padding: const EdgeInsets.fromLTRB(13, 4, 13, 11),
                ),
              ],
              if ((v.note ?? '').isNotEmpty) _note(),
              if (v.mine.trim().isNotEmpty) _personal(),
            ],
          ),
        ),
      );

  Widget _head() => Container(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.sentence.isEmpty ? v.result : v.sentence,
                    style: CkType.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                      color: CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    v.metaLine.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.07,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _chip(),
          ],
        ),
      );

  /// Won is the only green on the board. Tied takes cream — it is a result,
  /// but not a win. Everything else is neutral: a walkover or an abandonment
  /// is not a defeat and must not be coloured like one.
  Widget _chip() {
    final (fg, bg, border) = switch (v.result) {
      'Won' => (CkColors.greenInk, CkColors.greenSurface, CkColors.greenBorder),
      'Tied' => (CkColors.amberInk, CkColors.cream, CkColors.creamBorder),
      _ => (CkColors.ink2, CkColors.paper2, CkColors.line),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border),
      ),
      child: Text(
        v.result.toUpperCase(),
        style: CkType.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.09,
          color: fg,
        ),
      ),
    );
  }

  Widget _scoreRow({
    required String short,
    required Color color,
    required String name,
    required int runs,
    required int wkts,
    required String overs,
    required bool isYou,
    required bool won,
    required EdgeInsets padding,
  }) {
    // A tie has no loser, so neither side dims.
    final dim = !won && v.result != 'Tied';
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              short.toUpperCase(),
              style: CkType.display(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: name,
                children: [
                  if (isYou)
                    TextSpan(
                      text: '  YOU',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: CkColors.soft,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 14.5,
                fontWeight: dim ? FontWeight.w500 : FontWeight.w600,
                color: dim ? CkColors.muted : CkColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            // Em-dashes rather than a fabricated 0/0 when innings are missing.
            overs.isEmpty && runs == 0 && wkts == 0 ? '—/—' : '$runs/$wkts',
            style: CkType.mono(
              fontSize: 15,
              fontWeight: dim ? FontWeight.w600 : FontWeight.w700,
              letterSpacing: 0,
              color: dim ? CkColors.ink2 : CkColors.ink,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          SizedBox(
            width: 34,
            child: Text(
              overs,
              textAlign: TextAlign.right,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                color: CkColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Says why a number is missing, rather than leaving a blank to interpret.
  Widget _note() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Text(
          v.note!.toUpperCase(),
          style: CkType.mono(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: CkColors.muted,
          ),
        ),
      );

  /// "YOU: 78 (52)". The design reserves this band so the row does not need
  /// re-laying-out when per-player aggregates land.
  Widget _personal() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(top: BorderSide(color: CkColors.line)),
        ),
        child: Text(
          v.mine.toUpperCase(),
          style: CkType.mono(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: CkColors.ink2,
          ),
        ),
      );
}
