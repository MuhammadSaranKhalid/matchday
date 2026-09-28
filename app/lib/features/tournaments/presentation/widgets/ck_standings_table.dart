import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament_standing.dart';

/// One team's recent form and next fixture, derived from the fixture list by
/// the caller so the table stays a pure widget.
class StandingContext {
  const StandingContext({this.form = const [], this.nextFixture});

  /// Most recent last: 'W', 'L', 'T', 'N' (no result).
  final List<String> form;

  /// "v Cantt Lions, Sat" — what this team plays next.
  final String? nextFixture;
}

/// Artboard 14 — the Standings tab.
///
/// Two rules from the canvas drive the whole component:
///
///  * **The team column is pinned and the stats scroll under it.** Eight
///    columns do not fit 390pt, and a table you cannot identify a row in is
///    not a table.
///  * **The qualification cut-line is a 2px ink rule with a mono caption, not
///    a colour change.** Teams above and below the line are styled
///    identically — a green tint would say "these teams are safe", which is
///    false while matches remain.
class CkStandingsTable extends StatefulWidget {
  const CkStandingsTable({
    super.key,
    required this.standings,
    this.qualificationCutRank = 4,
    this.cutLabel,
    this.contextFor,
  });

  final List<TournamentStanding> standings;

  /// Rows after this rank sit below the line. Zero or negative hides it.
  final int qualificationCutRank;

  /// "Top 4 advance to semi-finals". Defaults from [qualificationCutRank].
  final String? cutLabel;

  /// Optional per-team form + next fixture for the expanded row.
  final StandingContext Function(TournamentStanding standing)? contextFor;

  @override
  State<CkStandingsTable> createState() => _CkStandingsTableState();
}

class _CkStandingsTableState extends State<CkStandingsTable> {
  /// One controller drives every row's stat pane, so the header and all rows
  /// stay in register when the pane is swiped.
  final _stats = ScrollController();
  String? _expandedTeamId;

  static const _teamColumnWidth = 148.0;

  /// P W L T NR Pts, then the three the footer promises on swipe.
  static const _columns = <({String label, double width})>[
    (label: 'P', width: 30),
    (label: 'W', width: 30),
    (label: 'L', width: 30),
    (label: 'T', width: 28),
    (label: 'NR', width: 34),
    (label: 'PTS', width: 40),
    (label: 'NRR', width: 62),
    (label: 'RF', width: 48),
    (label: 'RA', width: 48),
  ];

  @override
  void dispose() {
    _stats.dispose();
    super.dispose();
  }

  List<String> _valuesFor(TournamentStanding s) => [
        '${s.matchesPlayed}',
        '${s.wins}',
        '${s.losses}',
        '${s.ties}',
        '${s.noResults}',
        '${s.points}',
        s.formattedNrr,
        '${s.runsScored}',
        '${s.runsConceded}',
      ];

  @override
  Widget build(BuildContext context) {
    final rows = widget.standings;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        child: Center(
          child: Text(
            'The table fills in as results come in.',
            textAlign: TextAlign.center,
            style: CkType.body(fontSize: 12.5, color: CkColors.muted),
          ),
        ),
      );
    }

    final cut = widget.qualificationCutRank;
    final showCut = cut > 0 && cut < rows.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(controller: _stats, columns: _columns),
        for (var i = 0; i < rows.length; i++) ...[
          _Row(
            rank: i + 1,
            standing: rows[i],
            values: _valuesFor(rows[i]),
            columns: _columns,
            controller: _stats,
            expanded: _expandedTeamId == rows[i].teamId,
            onTap: () => setState(
              () => _expandedTeamId =
                  _expandedTeamId == rows[i].teamId ? null : rows[i].teamId,
            ),
            context: widget.contextFor?.call(rows[i]) ?? const StandingContext(),
          ),
          if (showCut && i + 1 == cut)
            _CutLine(
              label: widget.cutLabel ??
                  'Top $cut advance to the knockout stage',
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Swipe the stat pane for NRR, RF and RA.',
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.controller, required this.columns});

  final ScrollController controller;
  final List<({String label, double width})> columns;

  @override
  Widget build(BuildContext context) {
    TextStyle style() => CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: CkColors.muted,
        );

    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper2,
        border: Border(
          top: BorderSide(color: CkColors.hairline),
          bottom: BorderSide(color: CkColors.line),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              width: _CkStandingsTableState._teamColumnWidth - 16,
              child: Text('TEAM', style: style()),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: [
                  for (final c in columns)
                    SizedBox(
                      width: c.width,
                      child: Text(
                        c.label,
                        textAlign: TextAlign.right,
                        style: style(),
                      ),
                    ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.standing,
    required this.values,
    required this.columns,
    required this.controller,
    required this.expanded,
    required this.onTap,
    required this.context,
  });

  final int rank;
  final TournamentStanding standing;
  final List<String> values;
  final List<({String label, double width})> columns;
  final ScrollController controller;
  final bool expanded;
  final VoidCallback onTap;
  final StandingContext context;

  String get _monogram {
    final explicit = standing.teamMonogram?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit.toUpperCase();
    final name = standing.teamName ?? '';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.trim().padRight(2).substring(0, 2).trim().toUpperCase();
  }

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            color: expanded ? CkColors.paper2 : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    width: _CkStandingsTableState._teamColumnWidth - 16,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            '$rank',
                            // Identical above and below the cut — the rule is
                            // the line, not the colour.
                            style: CkType.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: CkColors.muted,
                            ),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: CkColors.paper2,
                            shape: BoxShape.circle,
                            border: Border.all(color: CkColors.line),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _monogram,
                            style: CkType.display(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            standing.teamName ?? 'Team',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.display(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: [
                        for (var i = 0; i < columns.length; i++)
                          SizedBox(
                            width: columns[i].width,
                            child: Text(
                              i < values.length ? values[i] : '',
                              textAlign: TextAlign.right,
                              style: CkType.mono(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                // Points carry the weight; the rest recede.
                                color: columns[i].label == 'PTS'
                                    ? CkColors.ink
                                    : CkColors.ink2,
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded) _Expanded(standing: standing, context: context),
        const Divider(height: 1, thickness: 1, color: CkColors.hairline),
      ],
    );
  }
}

/// The row opens onto the working behind the numbers — the NRR arithmetic in
/// full, so a manager can check the table rather than trust it.
class _Expanded extends StatelessWidget {
  const _Expanded({required this.standing, required this.context});

  final TournamentStanding standing;
  final StandingContext context;

  static String _rpo(int runs, double overs) =>
      overs <= 0 ? '—' : (runs / overs).toStringAsFixed(2);

  @override
  Widget build(BuildContext ctx) {
    return Container(
      color: CkColors.paper2,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(
            label: 'Runs scored',
            value: '${standing.runsScored} in '
                '${standing.oversFaced.toStringAsFixed(1)} '
                '(${_rpo(standing.runsScored, standing.oversFaced)} RPO)',
          ),
          _Line(
            label: 'Runs conceded',
            value: '${standing.runsConceded} in '
                '${standing.oversBowled.toStringAsFixed(1)} '
                '(${_rpo(standing.runsConceded, standing.oversBowled)} RPO)',
          ),
          _Line(label: 'Net run rate', value: standing.formattedNrr),
          if (context.form.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    'Form',
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ),
                for (final r in context.form) ...[
                  _FormPip(result: r),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            [
              'Tap the row again to collapse',
              if (context.nextFixture case final n?) 'next: $n',
            ].join(' · '),
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: CkType.body(fontSize: 12, color: CkColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: CkType.mono(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPip extends StatelessWidget {
  const _FormPip({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    // Green for a win, neutral for anything else — the only place on this tab
    // where a result is coloured, and it is a fact, not a projection.
    final win = result.toUpperCase() == 'W';
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: win ? CkColors.greenSurface : CkColors.paper,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: win ? CkColors.greenBorder : CkColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        result.toUpperCase(),
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: win ? CkColors.greenInk : CkColors.muted,
        ),
      ),
    );
  }
}

/// A 2px ink rule with a mono caption. Not a colour change.
class _CutLine extends StatelessWidget {
  const _CutLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: CkColors.ink)),
          const SizedBox(width: 9),
          Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
