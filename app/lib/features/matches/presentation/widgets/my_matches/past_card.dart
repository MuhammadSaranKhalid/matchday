import 'package:flutter/material.dart';

import '../../../../../core/design_system/design_system.dart';
import '../../state/my_matches_view.dart';

/// A Past-tab result — `My Matches.dc.html` artboards 08 / 09 / 10.
///
/// The result **sentence** is the hero, not the chip: "Lions won by 24 runs"
/// says more than a green `WON` ever can, and the chip beside it is only the
/// one-word summary. The losing side's name and score drop to onSurfaceVariant
/// so the board can be read down the left edge without parsing numbers.
class PastCard extends StatelessWidget {
  const PastCard({super.key, required this.v, required this.onTap});

  final MyMatchPast v;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(layout.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.cardRadius),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head(context),
              if (v.showScores) ...[
                _scoreRow(
                  context,
                  short: v.homeShort,
                  color: v.homeColor,
                  name: v.homeName,
                  runs: v.homeRuns,
                  wkts: v.homeWkts,
                  overs: v.homeOvers,
                  isYou: v.mineIsHome,
                  won: v.homeWon,
                  padding: EdgeInsets.fromLTRB(
                    layout.inlineGap,
                    layout.inlineGap - 3,
                    layout.inlineGap,
                    4,
                  ),
                ),
                _scoreRow(
                  context,
                  short: v.awayShort,
                  color: v.awayColor,
                  name: v.awayName,
                  runs: v.awayRuns,
                  wkts: v.awayWkts,
                  overs: v.awayOvers,
                  isYou: !v.mineIsHome,
                  won: !v.homeWon,
                  padding: EdgeInsets.fromLTRB(
                    layout.inlineGap,
                    4,
                    layout.inlineGap,
                    layout.inlineGap - 1,
                  ),
                ),
              ],
              if ((v.note ?? '').isNotEmpty) _note(context),
              if (v.mine.trim().isNotEmpty) _personal(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _head(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final textTokens = context.textTokens;

    final tone = switch (v.result) {
      'Won' => StatusTone.success,
      'Tied' => StatusTone.warning,
      _ => StatusTone.neutral,
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
        layout.inlineGap,
        layout.inlineGap - 1,
        layout.inlineGap,
        layout.inlineGap - 3,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
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
                  style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  v.metaLine.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTokens.mono.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.07,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(
            label: v.result.toUpperCase(),
            tone: tone,
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(
    BuildContext context, {
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
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final textTokens = context.textTokens;

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
              style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
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
                      style: textTokens.mono.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                fontSize: 14.5,
                fontWeight: dim ? FontWeight.w500 : FontWeight.w600,
                color: dim ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            // Em-dashes rather than a fabricated 0/0 when innings are missing.
            overs.isEmpty && runs == 0 && wkts == 0 ? '—/—' : '$runs/$wkts',
            style: textTokens.mono.copyWith(
              fontSize: 15,
              fontWeight: dim ? FontWeight.w600 : FontWeight.w700,
              letterSpacing: 0,
              color: dim ? scheme.onSurfaceVariant : scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              overs,
              textAlign: TextAlign.right,
              style: textTokens.mono.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Says why a number is missing, rather than leaving a blank to interpret.
  Widget _note(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: layout.inlineGap,
        vertical: layout.inlineGap - 3,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Text(
        v.note!.toUpperCase(),
        style: textTokens.mono.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// "YOU: 78 (52)". The design reserves this band so the row does not need
  /// re-laying-out when per-player aggregates land.
  Widget _personal(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: layout.inlineGap,
        vertical: layout.inlineGap - 4,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Text(
        v.mine.toUpperCase(),
        style: textTokens.mono.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
