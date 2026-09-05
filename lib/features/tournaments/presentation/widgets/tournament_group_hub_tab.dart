import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_standing.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 13b — the Group + Knockout hub.
///
/// The missing format: two groups feeding a bracket. Overview answers one
/// question — **who is currently going where** — so the group table and the
/// crossover projection sit on the same screen, and the bracket keeps its own
/// tab.
class TournamentGroupHubTab extends ConsumerStatefulWidget {
  const TournamentGroupHubTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentGroupHubTab> createState() =>
      _TournamentGroupHubTabState();
}

class _TournamentGroupHubTabState extends ConsumerState<TournamentGroupHubTab> {
  String? _group;

  @override
  Widget build(BuildContext context) {
    final standings =
        ref.watch(tournamentStandingsStreamProvider(widget.tournament.id));
    final board =
        ref.watch(tournamentLiveBoardProvider(widget.tournament.id)).value ??
            const <TournamentLiveMatch>[];

    return standings.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '$e',
            textAlign: TextAlign.center,
            style: CkType.body(fontSize: 12.5, color: CkColors.muted),
          ),
        ),
      ),
      data: (rows) => _body(rows, board),
    );
  }

  Widget _body(List<TournamentStanding> rows, List<TournamentLiveMatch> board) {
    final groups = rows
        .map((r) => r.groupId)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Text(
            'Groups appear once the organiser has drawn them.',
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 12.5,
              height: 1.55,
              color: CkColors.muted,
            ),
          ),
        ),
      );
    }

    final selected = _group ?? groups.first;
    final inGroup = rows.where((r) => r.groupId == selected).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    final played = board.where((m) => m.isFinished).length;
    final rounds = board.map((m) => m.round).whereType<String>().toSet().length;
    final roundsDone = board.isEmpty || rounds == 0
        ? 0
        : ((played / board.length) * rounds).ceil();

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'GROUP STAGE',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: CkColors.muted,
                  ),
                ),
              ),
              if (rounds > 0)
                Text(
                  'Round $roundsDone of $rounds',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                    color: CkColors.muted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _GroupSwitch(
          groups: groups,
          selected: selected,
          onChanged: (g) => setState(() => _group = g),
        ),
        const SizedBox(height: 4),
        _GroupTable(rows: inGroup),
        const _Eyebrow(label: 'Playoff projection'),
        _Projection(standings: rows, groups: groups, board: board),
      ],
    );
  }
}

class _GroupSwitch extends StatelessWidget {
  const _GroupSwitch({
    required this.groups,
    required this.selected,
    required this.onChanged,
  });

  final List<String> groups;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final g in groups) ...[
            GestureDetector(
              onTap: () => onChanged(g),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: g == selected ? 6 : 6.5,
                ),
                decoration: BoxDecoration(
                  color: g == selected ? CkColors.paper2 : CkColors.paper,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: g == selected ? CkColors.ink : CkColors.line,
                    width: g == selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  'Group $g',
                  style: CkType.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: g == selected ? CkColors.ink : CkColors.ink2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

/// A compact group table — Pos / Team / P W L Pts NRR — with the same 2px ink
/// cut-line the league standings use.
class _GroupTable extends StatelessWidget {
  const _GroupTable({required this.rows});

  final List<TournamentStanding> rows;

  static const _advance = 2;

  @override
  Widget build(BuildContext context) {
    TextStyle head() => CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: CkColors.muted,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: CkColors.paper2,
            border: Border(
              top: BorderSide(color: CkColors.hairline),
              bottom: BorderSide(color: CkColors.line),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 26, child: Text('POS', style: head())),
              Expanded(child: Text('TEAM', style: head())),
              SizedBox(
                width: 26,
                child: Text('P', textAlign: TextAlign.right, style: head()),
              ),
              SizedBox(
                width: 26,
                child: Text('W', textAlign: TextAlign.right, style: head()),
              ),
              SizedBox(
                width: 26,
                child: Text('L', textAlign: TextAlign.right, style: head()),
              ),
              SizedBox(
                width: 34,
                child: Text('PTS', textAlign: TextAlign.right, style: head()),
              ),
              SizedBox(
                width: 52,
                child: Text('NRR', textAlign: TextAlign.right, style: head()),
              ),
            ],
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          _GroupRow(position: i + 1, standing: rows[i]),
          if (i + 1 == _advance && rows.length > _advance)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(child: Container(height: 2, color: CkColors.ink)),
                  const SizedBox(width: 9),
                  Text(
                    'TOP $_advance ADVANCE TO SEMI-FINALS',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.position, required this.standing});

  final int position;
  final TournamentStanding standing;

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
  Widget build(BuildContext context) {
    TextStyle num() =>
        CkType.mono(fontSize: 12.5, fontWeight: FontWeight.w700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$position',
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CkColors.muted,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              _monogram,
              style: CkType.display(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              standing.teamName ?? 'Team',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text('${standing.matchesPlayed}',
                textAlign: TextAlign.right, style: num()),
          ),
          SizedBox(
            width: 26,
            child: Text('${standing.wins}',
                textAlign: TextAlign.right, style: num()),
          ),
          SizedBox(
            width: 26,
            child: Text('${standing.losses}',
                textAlign: TextAlign.right, style: num()),
          ),
          SizedBox(
            width: 34,
            child: Text('${standing.points}',
                textAlign: TextAlign.right, style: num()),
          ),
          SizedBox(
            width: 52,
            child: Text(
              standing.formattedNrr,
              textAlign: TextAlign.right,
              style: CkType.mono(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: CkColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The crossover projection.
///
/// Rows are labelled **position first, team second** — "1st A · Lahore Lions"
/// — so the card stays readable before qualification is settled, and the name
/// stays grey until it is mathematically certain.
class _Projection extends StatelessWidget {
  const _Projection({
    required this.standings,
    required this.groups,
    required this.board,
  });

  final List<TournamentStanding> standings;
  final List<String> groups;
  final List<TournamentLiveMatch> board;

  /// The team currently in [position] of [group], and whether that placing can
  /// still change. Certain only when the group has no unplayed fixture left.
  ({String? name, bool certain}) _slot(String group, int position) {
    final rows = standings.where((s) => s.groupId == group).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    if (rows.length < position) return (name: null, certain: false);

    final remaining = board.where((m) => !m.isFinished).isNotEmpty;
    return (name: rows[position - 1].teamName, certain: !remaining);
  }

  @override
  Widget build(BuildContext context) {
    if (groups.length < 2) return const SizedBox.shrink();
    final a = groups[0];
    final b = groups[1];

    final firstUnplayed = board.where((m) => !m.isFinished).toList()
      ..sort((x, y) => x.scheduledStartTime.compareTo(y.scheduledStartTime));
    final when = firstUnplayed.isEmpty
        ? null
        : DateFormat('EEE d MMM').format(firstUnplayed.first.scheduledStartTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (when != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                color: CkColors.paper2,
                child: Text(
                  'PROJECTION · $when'.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: CkColors.muted,
                  ),
                ),
              ),
            _ProjectionRow(
              label: 'SF1',
              top: (position: '1st $a', slot: _slot(a, 1)),
              bottom: (position: '2nd $b', slot: _slot(b, 2)),
            ),
            _ProjectionRow(
              label: 'SF2',
              top: (position: '1st $b', slot: _slot(b, 1)),
              bottom: (position: '2nd $a', slot: _slot(a, 2)),
            ),
            const _ProjectionRow(
              label: 'F',
              top: (
                position: 'Winner SF1',
                slot: (name: null, certain: false),
              ),
              bottom: (
                position: 'Winner SF2',
                slot: (name: null, certain: false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
              child: Text(
                'Projection, not a fixture — recalculated after every group '
                'result. Names stay grey until qualification is '
                'mathematically certain.',
                style: CkType.body(
                  fontSize: 11,
                  height: 1.45,
                  color: CkColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({
    required this.label,
    required this.top,
    required this.bottom,
  });

  final String label;
  final ({String position, ({String? name, bool certain}) slot}) top;
  final ({String position, ({String? name, bool certain}) slot}) bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              label,
              style: CkType.mono(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Slot(position: top.position, slot: top.slot),
                const SizedBox(height: 5),
                _Slot(position: bottom.position, slot: bottom.slot),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.position, required this.slot});

  final String position;
  final ({String? name, bool certain}) slot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Position first, team second — the card has to read before the group
        // is decided, and the position is the part that is already true.
        SizedBox(
          width: 66,
          child: Text(
            position.toUpperCase(),
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            slot.name ?? 'To be decided',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: slot.certain ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: CkColors.muted,
        ),
      ),
    );
  }
}
