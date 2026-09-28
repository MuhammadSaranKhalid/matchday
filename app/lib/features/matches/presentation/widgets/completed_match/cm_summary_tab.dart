import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/scoring/scorecard.dart';
import '../../state/completed_match_view.dart';
import 'cm_atoms.dart';

/// The Summary tab: who did the damage, and the two facts about the day that
/// are not in any table.
///
/// There is no Player of the Match card. `matches.player_of_the_match_id`
/// exists in the schema but nothing writes it, so the card would print an
/// empty slab on every match ever played — and this screen's rule is that a
/// panel which can only ever be blank is not drawn. Awarding a POTM needs its
/// own flow at match end; when that ships, the card goes above Top performers.
class CmSummaryTab extends StatelessWidget {
  const CmSummaryTab({required this.view, super.key});

  final CompletedMatchView view;

  @override
  Widget build(BuildContext context) {
    final batting = _topBatting(view.innings);
    final bowling = _topBowling(view.innings);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 32),
      children: [
        if (batting.isNotEmpty || bowling.isNotEmpty) ...[
          const CmSectionHeading('Top performers'),
          const SizedBox(height: 11),
        ],
        if (batting.isNotEmpty)
          CmPanel(
            children: [
              const CmTableHeader(
                cells: [
                  (text: 'Batting', width: null),
                  (text: 'R (B)', width: 54),
                  (text: 'SR', width: 38),
                ],
              ),
              for (final (i, b) in batting.indexed)
                _PerformerRow(
                  color: _sideColor(view, b.side),
                  name: b.line.name,
                  primary: '${b.line.runs} (${b.line.balls})',
                  primaryWidth: 54,
                  secondary: b.line.strikeRate.toStringAsFixed(1),
                  last: i == batting.length - 1,
                ),
            ],
          ),
        if (bowling.isNotEmpty) ...[
          const SizedBox(height: 11),
          CmPanel(
            children: [
              const CmTableHeader(
                cells: [
                  (text: 'Bowling', width: null),
                  (text: 'W-R', width: 44),
                  (text: 'Econ', width: 38),
                ],
              ),
              for (final (i, b) in bowling.indexed)
                _PerformerRow(
                  color: _sideColor(view, b.side),
                  name: b.line.name,
                  primary: '${b.line.wickets}-${b.line.runs}',
                  primaryWidth: 44,
                  secondary: b.line.economy.toStringAsFixed(2),
                  last: i == bowling.length - 1,
                ),
            ],
          ),
        ],
        if (view.tossLine != null || view.squadsLine != null) ...[
          const SizedBox(height: 11),
          CmPanel(
            background: CkColors.paper,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (view.tossLine != null)
                      _MetaRow(label: 'Toss', value: view.tossLine!),
                    if (view.tossLine != null && view.squadsLine != null)
                      const SizedBox(height: 5),
                    if (view.squadsLine != null)
                      _MetaRow(label: 'Squads', value: view.squadsLine!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static Color _sideColor(CompletedMatchView v, String side) =>
      v.sides
          .where((s) => s.sideLetter == side)
          .map((s) => s.color)
          .firstOrNull ??
      CkColors.soft;
}

/// The two best innings and the two best spells across BOTH sides — a summary
/// of the match, not of one team.
List<({BattingLine line, String side})> _topBatting(List<InningsCard> innings) {
  final all = [
    for (final i in innings)
      for (final b in i.batting)
        if (b.batted) (line: b, side: i.battingTeamSide),
  ]..sort((x, y) => y.line.runs.compareTo(x.line.runs));
  return all.take(2).toList();
}

List<({BowlingLine line, String side})> _topBowling(List<InningsCard> innings) {
  final all = [
    for (final i in innings)
      for (final b in i.bowling)
        // The bowling side is the other one.
        (line: b, side: i.battingTeamSide == 'a' ? 'b' : 'a'),
  ]..sort((x, y) {
    final byWickets = y.line.wickets.compareTo(x.line.wickets);
    return byWickets != 0 ? byWickets : x.line.runs.compareTo(y.line.runs);
  });
  return all.where((b) => b.line.legalBalls > 0).take(2).toList();
}

class _PerformerRow extends StatelessWidget {
  const _PerformerRow({
    required this.color,
    required this.name,
    required this.primary,
    required this.primaryWidth,
    required this.secondary,
    required this.last,
  });

  final Color color;
  final String name;
  final String primary;
  final double primaryWidth;
  final String secondary;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      border:
          last
              ? null
              : const Border(bottom: BorderSide(color: CkColors.hairline)),
    ),
    child: Row(
      children: [
        CmCrest(color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CmText.name(),
          ),
        ),
        const SizedBox(width: 9),
        CmFigureCell(primary, width: primaryWidth),
        const SizedBox(width: 9),
        CmFigureCell(
          secondary,
          width: 38,
          size: 11,
          weight: FontWeight.w600,
          color: CkColors.ink2,
        ),
      ],
    ),
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 56,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(label.toUpperCase(), style: CmText.label(size: 9)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          value,
          style: CkType.body(fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}
