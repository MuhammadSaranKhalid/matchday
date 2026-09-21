import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/scoring/scorecard.dart';
import 'cm_atoms.dart';

/// The Card tab for ONE innings: batting, extras, total, who did not bat,
/// bowling, fall of wickets, partnerships.
///
/// Name and dismissal share one flexible column that truncates at the name,
/// never at the figures — R · B · 4s · 6s · SR are fixed-width and always
/// visible, because a scorecard whose numbers move is not a scorecard.
class CmCardTab extends StatelessWidget {
  const CmCardTab({required this.card, required this.teamColor, super.key});

  final InningsCard card;
  final Color teamColor;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 13, 16, 32),
    children: [
      CmPanel(
        children: [
          const CmTableHeader(
            cells: [
              (text: 'Batting', width: null),
              (text: 'R', width: 26),
              (text: 'B', width: 26),
              (text: '4', width: 20),
              (text: '6', width: 20),
              (text: 'SR', width: 40),
            ],
          ),
          for (final b in card.batting.where((b) => b.batted))
            _BattingRow(line: b),
          _ExtrasRow(extras: card.extras),
          _TotalRow(card: card),
        ],
      ),
      if (card.didNotBat.isNotEmpty) ...[
        const SizedBox(height: 11),
        _DidNotBat(names: card.didNotBat),
      ],
      if (card.bowling.isNotEmpty) ...[
        const SizedBox(height: 11),
        CmPanel(
          children: [
            const CmTableHeader(
              cells: [
                (text: 'Bowling', width: null),
                (text: 'O', width: 34),
                (text: 'M', width: 20),
                (text: 'R', width: 26),
                (text: 'W', width: 20),
                (text: 'Econ', width: 40),
              ],
            ),
            for (final b in card.bowling) _BowlingRow(line: b),
          ],
        ),
      ],
      if (card.fallOfWickets.isNotEmpty) ...[
        const SizedBox(height: 11),
        CmPanel(
          children: [
            const CmTableHeader(
              cells: [(text: 'Fall of wickets', width: null)],
            ),
            for (final (i, w) in card.fallOfWickets.indexed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border:
                      i == card.fallOfWickets.length - 1
                          ? null
                          : const Border(
                            bottom: BorderSide(color: CkColors.hairline),
                          ),
                ),
                // Wicket number and over stay in fixed outer columns so
                // the sequence reads as a column of scores even when a
                // name truncates.
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      child: Text(
                        '${w.number}',
                        style: CmText.figure(
                          size: 10,
                          weight: FontWeight.w600,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                    CmFigureCell('${w.number}-${w.score}', width: 52),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        w.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CmText.name(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: CkColors.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CmFigureCell(
                      w.overs.toStringAsFixed(1),
                      width: 32,
                      size: 10,
                      weight: FontWeight.w600,
                      color: CkColors.muted,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
      if (card.partnerships.isNotEmpty) ...[
        const SizedBox(height: 11),
        const CmSectionHeading('Partnerships'),
        const SizedBox(height: 11),
        _Partnerships(card: card, teamColor: teamColor),
      ],
    ],
  );
}

class _BattingRow extends StatelessWidget {
  const _BattingRow({required this.line});

  final BattingLine line;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: CkColors.hairline)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CmText.name(size: 13.5),
              ),
              const SizedBox(height: 1),
              Text(
                line.dismissal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.body(
                  fontSize: 11,
                  color: line.isOut ? CkColors.muted : CkColors.ink2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CmFigureCell('${line.runs}', width: 26),
        CmFigureCell(
          '${line.balls}',
          width: 26,
          size: 11,
          weight: FontWeight.w600,
          color: CkColors.ink2,
        ),
        CmFigureCell(
          '${line.fours}',
          width: 20,
          size: 11,
          weight: FontWeight.w600,
          color: CkColors.ink2,
        ),
        CmFigureCell(
          '${line.sixes}',
          width: 20,
          size: 11,
          weight: FontWeight.w600,
          color: CkColors.ink2,
        ),
        CmFigureCell(
          line.strikeRate.toStringAsFixed(1),
          width: 40,
          size: 11,
          weight: FontWeight.w600,
          color: CkColors.ink2,
        ),
      ],
    ),
  );
}

class _BowlingRow extends StatelessWidget {
  const _BowlingRow({required this.line});

  final BowlingLine line;

  @override
  Widget build(BuildContext context) {
    // A maiden and an expensive spell are marked in mono footnotes, not
    // colour — economy already says it.
    final notes = [
      if (line.maidens > 0)
        '${line.maidens} maiden${line.maidens == 1 ? '' : 's'}',
      if (line.dots > 0) '${line.dots} dots',
      if (line.wides > 0 || line.noBalls > 0)
        '${line.wides}w ${line.noBalls}nb',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CmText.name(size: 13.5),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CmText.label(
                      size: 9,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          CmFigureCell(
            line.oversLabel,
            width: 34,
            size: 11,
            weight: FontWeight.w600,
            color: CkColors.ink2,
          ),
          CmFigureCell(
            '${line.maidens}',
            width: 20,
            size: 11,
            weight: FontWeight.w600,
            color: CkColors.ink2,
          ),
          CmFigureCell(
            '${line.runs}',
            width: 26,
            size: 11,
            weight: FontWeight.w600,
            color: CkColors.ink2,
          ),
          CmFigureCell('${line.wickets}', width: 20),
          CmFigureCell(
            line.economy.toStringAsFixed(2),
            width: 40,
            size: 11,
            weight: FontWeight.w600,
            color: CkColors.ink2,
          ),
        ],
      ),
    );
  }
}

class _ExtrasRow extends StatelessWidget {
  const _ExtrasRow({required this.extras});

  final ExtrasBreakdown extras;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: CkColors.hairline)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 52,
          child: Text('EXTRAS', style: CmText.label(size: 9)),
        ),
        Expanded(
          child: Text(
            extras.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CmText.figure(
              size: 10,
              weight: FontWeight.w600,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CmFigureCell('${extras.total}', width: 26),
      ],
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.card});

  final InningsCard card;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    color: CkColors.paper,
    child: Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            'TOTAL',
            style: CmText.label(size: 9, color: CkColors.ink),
          ),
        ),
        Expanded(
          child: Text(
            '${card.oversLabel} ov · RR ${card.runRate.toStringAsFixed(2)}',
            style: CmText.figure(
              size: 10,
              weight: FontWeight.w600,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${card.totalRuns}/${card.wickets}',
          style: CmText.figure(size: 14),
        ),
      ],
    ),
  );
}

class _DidNotBat extends StatelessWidget {
  const _DidNotBat({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('DID NOT BAT', style: CmText.label(size: 9)),
      const SizedBox(height: 4),
      Text(
        names.join(', '),
        style: CkType.body(fontSize: 12.5, height: 1.5, color: CkColors.ink2),
      ),
    ],
  );
}

/// Each stand is one bar: length is runs, the split is who made them. Anchored
/// to the score it started at, so a collapse reads as a cliff rather than as a
/// list of numbers.
class _Partnerships extends StatelessWidget {
  const _Partnerships({required this.card, required this.teamColor});

  final InningsCard card;
  final Color teamColor;

  @override
  Widget build(BuildContext context) {
    final max = card.partnerships
        .map((p) => p.runs)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return CmPanel(
      children: [
        for (final (i, p) in card.partnerships.indexed)
          Container(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
            decoration: BoxDecoration(
              border:
                  i == card.partnerships.length - 1
                      ? null
                      : const Border(
                        bottom: BorderSide(color: CkColors.hairline),
                      ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        _ordinal(p.wicketNumber),
                        style: CmText.figure(
                          size: 10,
                          weight: FontWeight.w700,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${p.strikerName} · ${p.nonStrikerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CkColors.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.runs} (${p.balls})',
                      style: CmText.figure(size: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _PartnershipBar(p: p, max: max, color: teamColor),
                const SizedBox(height: 5),
                Text(
                  p.label,
                  style: CmText.label(
                    size: 9,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }
}

class _PartnershipBar extends StatelessWidget {
  const _PartnershipBar({
    required this.p,
    required this.max,
    required this.color,
  });

  final Partnership p;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = (p.strikerRuns + p.nonStrikerRuns).clamp(1, 1 << 30);
    final strikerShare = p.strikerRuns / total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * (p.runs / max).clamp(0.06, 1.0);
        return SizedBox(
          height: 10,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: const Radius.circular(3),
                  // An unbroken stand has an open right edge — nobody ended it.
                  right: Radius.circular(p.unbroken ? 0 : 3),
                ),
                border:
                    p.unbroken
                        ? Border(
                          top: BorderSide(color: color.withValues(alpha: 0.5)),
                          left: BorderSide(color: color.withValues(alpha: 0.5)),
                          bottom: BorderSide(
                            color: color.withValues(alpha: 0.5),
                          ),
                        )
                        : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Expanded(
                    flex: (strikerShare * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: color),
                  ),
                  Expanded(
                    flex: ((1 - strikerShare) * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: color.withValues(alpha: 0.28)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
