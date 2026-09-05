import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../providers/tournaments_providers.dart';
import 'ck_pulse_dot.dart';

/// Artboard 12 — the Fixtures tab.
///
/// Every fixture-row state on one screen: completed, live, upcoming, walkover,
/// abandoned. **Grouping switches between round and date without changing the
/// row** — the row is the component, the grouping is only a header.
class TournamentFixturesTab extends ConsumerStatefulWidget {
  const TournamentFixturesTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentFixturesTab> createState() =>
      _TournamentFixturesTabState();
}

enum _Grouping { round, date }

class _TournamentFixturesTabState extends ConsumerState<TournamentFixturesTab> {
  _Grouping _grouping = _Grouping.round;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(tournamentLiveBoardProvider(widget.tournament.id));

    return switch (board) {
      AsyncLoading() =>
        const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
          ),
        ),
      AsyncData(value: final fixtures) => _body(fixtures),
    };
  }

  Widget _body(List<TournamentLiveMatch> fixtures) {
    if (fixtures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_note_outlined,
                size: 30,
                color: CkColors.soft,
              ),
              const SizedBox(height: 12),
              Text(
                'No fixtures yet',
                style:
                    CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Fixtures appear here the moment the organiser locks the draw.',
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 12.5,
                  height: 1.55,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _grouping == _Grouping.round
        ? _byRound(fixtures)
        : _byDate(fixtures);

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async =>
          ref.invalidate(tournamentLiveBoardProvider(widget.tournament.id)),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _GroupingToggle(
                grouping: _grouping,
                onChanged: (g) => setState(() => _grouping = g),
              ),
            ),
          ),
          for (final group in groups) ...[
            // Day headers are sticky mono — the canvas is explicit about it,
            // and on a 31-match cup it is what keeps the scroll legible.
            SliverPersistentHeader(
              pinned: true,
              delegate: _GroupHeader(label: group.label),
            ),
            SliverList.builder(
              itemCount: group.fixtures.length,
              itemBuilder: (_, i) => _FixtureCard(
                match: group.fixtures[i],
                onTap: () =>
                    context.push('/matches/${group.fixtures[i].matchId}'),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  List<({String label, List<TournamentLiveMatch> fixtures})> _byRound(
    List<TournamentLiveMatch> fixtures,
  ) {
    final map = <String, List<TournamentLiveMatch>>{};
    for (final f in fixtures) {
      map.putIfAbsent(f.round ?? 'Fixtures', () => []).add(f);
    }
    return [
      for (final entry in map.entries)
        (
          // "Round of 16 · complete" / "Quarter-Finals · today"
          label: '${entry.key}${_roundSuffix(entry.value)}',
          fixtures: entry.value,
        ),
    ];
  }

  static String _roundSuffix(List<TournamentLiveMatch> fixtures) {
    if (fixtures.every((f) => f.isFinished)) return ' · complete';
    if (fixtures.any((f) => f.isLive)) return ' · live';
    if (fixtures.any(
      (f) => DateUtils.isSameDay(f.scheduledStartTime, DateTime.now()),
    )) {
      return ' · today';
    }
    return '';
  }

  List<({String label, List<TournamentLiveMatch> fixtures})> _byDate(
    List<TournamentLiveMatch> fixtures,
  ) {
    final sorted = [...fixtures]
      ..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
    final map = <String, List<TournamentLiveMatch>>{};
    for (final f in sorted) {
      final day = DateUtils.isSameDay(f.scheduledStartTime, DateTime.now())
          ? 'Today'
          : DateFormat('EEE d MMM').format(f.scheduledStartTime);
      map.putIfAbsent(day, () => []).add(f);
    }
    return [
      for (final entry in map.entries)
        (label: entry.key, fixtures: entry.value),
    ];
  }
}

class _GroupingToggle extends StatelessWidget {
  const _GroupingToggle({required this.grouping, required this.onChanged});

  final _Grouping grouping;
  final ValueChanged<_Grouping> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final g in _Grouping.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(g),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        grouping == g ? CkColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: grouping == g
                        ? const [
                            BoxShadow(
                              color: Color(0x0A281E0F),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    g == _Grouping.round ? 'By round' : 'By date',
                    textAlign: TextAlign.center,
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: grouping == g ? CkColors.ink : CkColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends SliverPersistentHeaderDelegate {
  const _GroupHeader({required this.label});

  final String label;

  @override
  double get minExtent => 32;
  @override
  double get maxExtent => 32;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      height: 32,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CkColors.paper2,
        border: Border(
          top: BorderSide(color: CkColors.hairline),
          bottom: BorderSide(color: CkColors.line),
        ),
      ),
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

  @override
  bool shouldRebuild(covariant _GroupHeader old) => old.label != label;
}

/// One row, five states. The shape never changes — only what the trailing
/// slot and the two side lines say.
class _FixtureCard extends StatelessWidget {
  const _FixtureCard({required this.match, required this.onTap});

  final TournamentLiveMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      if (match.round case final r?) r,
                      match.venue,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Trailing(match: match),
              ],
            ),
            const SizedBox(height: 8),
            _Side(match: match, teamId: match.teamAId, feederSlot: 'A'),
            const SizedBox(height: 5),
            _Side(match: match, teamId: match.teamBId, feederSlot: 'B'),
            if (match.status == 'no_result' || match.status == 'abandoned') ...[
              const SizedBox(height: 6),
              Text(
                'No result · points split 1–1',
                style: CkType.body(fontSize: 11, color: CkColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.match});

  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context) {
    if (match.status == 'live' || match.status == 'super_over') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CkColors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          match.status == 'super_over' ? 'SUPER OVER' : 'LIVE',
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
            color: Colors.white,
          ),
        ),
      );
    }

    final label = switch (match.status) {
      'walkover' => 'WALKOVER',
      'abandoned' => 'ABANDONED',
      'no_result' => 'NO RESULT',
      'tied' => 'TIED',
      _ when match.isFinished =>
        match.resultDescription ?? 'Result recorded',
      _ => DateUtils.isSameDay(match.scheduledStartTime, DateTime.now())
          ? 'Today · ${DateFormat('h:mm a').format(match.scheduledStartTime)}'
          : DateFormat('EEE d MMM · h:mm a').format(match.scheduledStartTime),
    };

    final isChip = const {'walkover', 'abandoned', 'no_result', 'tied'}
        .contains(match.status);

    if (!isChip) {
      return Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: CkType.body(fontSize: 11, color: CkColors.muted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CkColors.line),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: CkColors.ink2,
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.match,
    required this.teamId,
    required this.feederSlot,
  });

  final TournamentLiveMatch match;
  final String? teamId;
  final String feederSlot;

  @override
  Widget build(BuildContext context) {
    final line = match.lineFor(teamId);
    final lines = [...match.inningsLines]
      ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final latest = lines.isEmpty ? null : lines.last;
    final striking = (match.status == 'live' || match.status == 'super_over') &&
        line != null &&
        line.inningsNumber == latest?.inningsNumber;

    // An unresolved knockout slot names its route, not a blank — "Winner of
    // Quarter-Final 1" reads as a fixture waiting, not as missing data.
    final unresolved = teamId == null;
    final name = unresolved
        ? 'Winner of ${match.round == null ? 'the previous round' : _feederOf(match.round!, feederSlot)}'
        : match.displayNameFor(teamId);

    final won = match.winnerId != null && match.winnerId == teamId;
    final lost = match.winnerId != null && teamId != null && !won;

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13.5,
              fontWeight: won || striking ? FontWeight.w700 : FontWeight.w600,
              color: unresolved || lost ? CkColors.muted : CkColors.ink,
            ),
          ),
        ),
        if (match.status == 'walkover') ...[
          Text(
            won ? 'Awarded' : 'Did not arrive',
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ] else if (line != null) ...[
          if (striking) ...[const CkPulseDot(), const SizedBox(width: 6)],
          Text(
            line.scoreText,
            style: CkType.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: striking
                  ? CkColors.red
                  : won
                      ? CkColors.ink
                      : CkColors.muted,
            ),
          ),
        ],
      ],
    );
  }

  /// "Quarter-Final 1" for slot A of "Semi-Final 1", and 2 for slot B — the
  /// standard bracket feed, stated rather than drawn.
  static String _feederOf(String round, String slot) {
    final n = RegExp(r'(\d+)$').firstMatch(round)?.group(1);
    if (n == null) return 'the previous round';
    final index = int.parse(n);
    final feeder = slot == 'A' ? index * 2 - 1 : index * 2;
    final previous = round.toLowerCase().contains('final') &&
            !round.toLowerCase().contains('semi') &&
            !round.toLowerCase().contains('quarter')
        ? 'Semi-Final'
        : round.toLowerCase().contains('semi')
            ? 'Quarter-Final'
            : 'Match';
    return '$previous $feeder';
  }
}
