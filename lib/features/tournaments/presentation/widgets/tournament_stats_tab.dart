import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_leader.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 15, right — the Stats tab.
///
/// "One segmented switch over two identical leaderboards." Batting and bowling
/// share a component because they are the same shape of question; only the two
/// numeric columns are relabelled. Zero red — a leaderboard is a record, not
/// a live thing.
class TournamentStatsTab extends ConsumerStatefulWidget {
  const TournamentStatsTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentStatsTab> createState() => _TournamentStatsTabState();
}

class _TournamentStatsTabState extends ConsumerState<TournamentStatsTab> {
  bool _bowling = false;

  @override
  Widget build(BuildContext context) {
    final boards =
        ref.watch(tournamentLeaderboardsProvider(widget.tournament.id));

    return switch (boards) {
      AsyncLoading() =>
        const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      AsyncError(:final error) => _StatsMessage(
          title: 'Stats did not load',
          body: '$error',
          onRetry: () => ref.invalidate(
            tournamentLeaderboardsProvider(widget.tournament.id),
          ),
        ),
      AsyncData(value: final data) => _body(data),
    };
  }

  Widget _body(TournamentLeaderboards data) {
    final rows = _bowling ? data.bowling : data.batting;

    if (data.isEmpty) {
      return const _StatsMessage(
        title: 'No stats yet',
        body: 'The orange and purple caps are filled in ball by ball. They '
            'appear here as soon as the first match is scored.',
      );
    }

    final best = data.bestBowlingFigures;

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async =>
          ref.invalidate(tournamentLeaderboardsProvider(widget.tournament.id)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _Segmented(
              left: 'Orange Cap · Runs',
              right: 'Purple Cap · Wickets',
              rightSelected: _bowling,
              onChanged: (v) => setState(() => _bowling = v),
            ),
          ),
          _LeaderHeader(bowling: _bowling),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 34),
              child: Center(
                child: Text(
                  _bowling
                      ? 'No wickets have fallen to a bowler yet.'
                      : 'No runs off the bat yet.',
                  style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                ),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++)
              _LeaderRow(rank: i + 1, leader: rows[i], bowling: _bowling),

          // The asterisk is explained once, at the foot of the list it applies
          // to — a guest who scored the runs still gets counted.
          if (rows.any((r) => r.isUnclaimed))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                '* Unclaimed guest player on team roster.',
                style: CkType.body(fontSize: 11, color: CkColors.muted),
              ),
            ),

          if (best != null) ...[
            const SizedBox(height: 18),
            _BestFigures(leader: best),
          ],
        ],
      ),
    );
  }
}

/// The segmented switch: paper2 track, white selected pill with a soft lift.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;

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
          Expanded(
            child: _SegmentButton(
              label: left,
              selected: !rightSelected,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: right,
              selected: rightSelected,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? CkColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
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
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.display(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? CkColors.ink : CkColors.muted,
          ),
        ),
      ),
    );
  }
}

class _LeaderHeader extends StatelessWidget {
  const _LeaderHeader({required this.bowling});

  final bool bowling;

  @override
  Widget build(BuildContext context) {
    TextStyle style() => CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: CkColors.muted,
        );

    return Container(
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
          SizedBox(width: 22, child: Text('#', style: style())),
          Expanded(child: Text(bowling ? 'BOWLER' : 'BATTER', style: style())),
          SizedBox(
            width: 46,
            child: Text(
              bowling ? 'WKTS' : 'RUNS',
              textAlign: TextAlign.right,
              style: style(),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              bowling ? 'ECON' : 'SR',
              textAlign: TextAlign.right,
              style: style(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.leader,
    required this.bowling,
  });

  final int rank;
  final TournamentLeader leader;
  final bool bowling;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: CkType.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                // Only the cap holder is inked; the chasing pack recedes.
                color: rank == 1 ? CkColors.ink : CkColors.muted,
              ),
            ),
          ),
          _PlayerCrest(leader: leader),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  leader.isUnclaimed
                      ? '*${leader.displayName}'
                      : leader.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      CkType.display(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (leader.teamName case final team?)
                  Text(
                    team,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 10.5, color: CkColors.muted),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${leader.primaryValue}',
              textAlign: TextAlign.right,
              style: CkType.mono(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              bowling
                  ? leader.rateValue.toStringAsFixed(2)
                  : leader.rateValue.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: CkType.mono(
                fontSize: 12,
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

/// A guest keeps a dashed ring and an amber asterisk — present, counted, and
/// visibly not a registered account.
class _PlayerCrest extends StatelessWidget {
  const _PlayerCrest({required this.leader});

  final TournamentLeader leader;

  @override
  Widget build(BuildContext context) {
    final crest = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        shape: BoxShape.circle,
        border: Border.all(
          color: leader.isUnclaimed ? CkColors.soft : CkColors.line,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        leader.monogram,
        style: CkType.display(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: leader.isUnclaimed ? CkColors.muted : CkColors.ink,
        ),
      ),
    );

    if (!leader.isUnclaimed) return crest;

    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          crest,
          Positioned(
            top: -3,
            right: -2,
            child: Text(
              '*',
              style: CkType.display(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CkColors.amberInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Best bowling figures · Naseem Shah · 5/14" (artboard 15).
class _BestFigures extends StatelessWidget {
  const _BestFigures({required this.leader});

  final TournamentLeader leader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.line),
        ),
        child: Row(
          children: [
            _PlayerCrest(leader: leader),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BEST BOWLING FIGURES',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    leader.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (leader.teamName case final team?)
                    Text(
                      team,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              leader.bestFigures,
              style: CkType.mono(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsMessage extends StatelessWidget {
  const _StatsMessage({required this.title, required this.body, this.onRetry});

  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard_outlined, size: 30, color: CkColors.soft),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12.5,
                height: 1.55,
                color: CkColors.muted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CkColors.line),
                  foregroundColor: CkColors.ink,
                ),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
