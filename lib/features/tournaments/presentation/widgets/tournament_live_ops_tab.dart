import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../providers/tournaments_providers.dart';
import 'ck_pulse_dot.dart';

/// Live Ops — the multi-ground dashboard (artboard 27).
///
/// Red is spent only on live scores and their pulse dots. The row that needs
/// action — a fixture with no scorer — is cream, because it is urgent rather
/// than dangerous.
class TournamentLiveOpsTab extends ConsumerStatefulWidget {
  const TournamentLiveOpsTab({
    super.key,
    required this.tournament,
    required this.onMatchActions,
    required this.onAssignScorer,
  });

  final Tournament tournament;
  final void Function(TournamentLiveMatch match) onMatchActions;
  final void Function(TournamentLiveMatch match) onAssignScorer;

  @override
  ConsumerState<TournamentLiveOpsTab> createState() =>
      _TournamentLiveOpsTabState();
}

class _TournamentLiveOpsTabState extends ConsumerState<TournamentLiveOpsTab> {
  DateTime _fetchedAt = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final onMatchActions = widget.onMatchActions;
    final onAssignScorer = widget.onAssignScorer;

    // Restamp whenever a fresh board lands.
    ref.listen(tournamentLiveBoardProvider(tournament.id), (_, next) {
      if (next.hasValue) _fetchedAt = DateTime.now();
    });

    final boardAsync = ref.watch(tournamentLiveBoardProvider(tournament.id));

    return boardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: '$e',
        onRetry: () => ref.invalidate(tournamentLiveBoardProvider(tournament.id)),
      ),
      data: (board) {
        if (board.isEmpty) {
          return const _NoFixturesState();
        }

        final live = board.where((m) => m.isLive).toList();
        final unscored = board.where((m) => m.needsScorer).toList();
        final played = board.where((m) => m.isFinished).length;

        // Before the first ball the board is a readiness checklist, not a
        // dashboard (artboard 27h).
        final anyStarted = board.any((m) => m.isLive || m.isFinished);

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(tournamentLiveBoardProvider(tournament.id)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (unscored.isNotEmpty)
                _ScorerAlertBanner(
                  count: unscored.length,
                  onFix: () => onAssignScorer(unscored.first),
                ),
              if (!anyStarted)
                _PreMatchdayReadiness(board: board)
              else ...[
                _SectionEyebrow(
                  label: live.isEmpty
                      ? '${board.length} fixtures'
                      : 'Today · ${live.length} ground${live.length == 1 ? '' : 's'}',
                  fetchedAt: _fetchedAt,
                ),
                const SizedBox(height: 8),
                for (final match in board) ...[
                  _GroundCard(
                    match: match,
                    onActions: () => onMatchActions(match),
                    onAssign: () => onAssignScorer(match),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 4),
              Text(
                'TOURNAMENT STATE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Played',
                      value: '$played / ${board.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Results pending',
                      value: '${board.length - played}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Alert banner ────────────────────────────────────────────────────────────

class _ScorerAlertBanner extends StatelessWidget {
  const _ScorerAlertBanner({required this.count, required this.onFix});

  final int count;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        child: InkWell(
          onTap: onFix,
          borderRadius: BorderRadius.circular(CkRadii.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CkRadii.sm),
              border: Border.all(color: CkColors.creamBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    count == 1
                        ? '1 MATCH HAS NO SCORER ASSIGNED'
                        : '$count MATCHES HAVE NO SCORER ASSIGNED',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.amberDark,
                    ),
                  ),
                ),
                Text(
                  'FIX',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.amberDark,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 14, color: CkColors.amberDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ground card ─────────────────────────────────────────────────────────────

class _GroundCard extends StatelessWidget {
  const _GroundCard({
    required this.match,
    required this.onActions,
    required this.onAssign,
  });

  final TournamentLiveMatch match;
  final VoidCallback onActions;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match.venue.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                    ),
                  ),
                ),
                _StatusPill(match: match),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 9, 13, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TeamScoreRow(match: match, teamId: match.teamAId),
                const SizedBox(height: 6),
                _TeamScoreRow(match: match, teamId: match.teamBId),
              ],
            ),
          ),
          Container(height: 1, color: CkColors.hairline),
          match.needsScorer
              ? _AssignScorerFooter(match: match, onAssign: onAssign)
              : _ScorerFooter(match: match, onActions: onActions),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.match});

  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    Color? border;

    if (match.isLive) {
      label = 'LIVE';
      bg = CkColors.red;
      fg = Colors.white;
    } else if (match.isFinished) {
      switch (match.status) {
        case 'walkover':
          label = 'WALKOVER';
          bg = CkColors.greenSurface;
          fg = CkColors.greenInk;
          border = CkColors.greenBorder;
        case 'no_result':
        case 'abandoned':
          label = match.status == 'abandoned' ? 'ABANDONED' : 'NO RESULT';
          bg = CkColors.redSurface;
          fg = CkColors.redInk;
          border = CkColors.redBorder;
        case 'tied':
          label = 'TIED';
          bg = CkColors.paper2;
          fg = CkColors.ink2;
          border = CkColors.line;
        default:
          label = 'DONE';
          bg = CkColors.greenSurface;
          fg = CkColors.greenInk;
          border = CkColors.greenBorder;
      }
    } else {
      final t = match.scheduledStartTime;
      label = '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
      bg = CkColors.paper2;
      fg = CkColors.ink2;
      border = CkColors.line;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: fg,
        ),
      ),
    );
  }
}

/// One side's line. The team currently batting is inked and, when the match is
/// live, its score carries the pulse; a completed innings recedes to muted.
class _TeamScoreRow extends StatelessWidget {
  const _TeamScoreRow({required this.match, required this.teamId});

  final TournamentLiveMatch match;
  final String? teamId;

  @override
  Widget build(BuildContext context) {
    final line = match.lineFor(teamId);
    final name = match.displayNameFor(teamId);

    // The live innings is the highest-numbered one that has a line.
    final latest = match.inningsLines.isEmpty
        ? null
        : match.inningsLines.reduce(
            (a, b) => b.inningsNumber > a.inningsNumber ? b : a,
          );
    final isStriking =
        match.isLive && line != null && line.inningsNumber == latest?.inningsNumber;

    final nameColor = match.isFinished
        ? (match.winnerId != null && match.winnerId == teamId
            ? CkColors.ink
            : CkColors.muted)
        : (isStriking || line == null ? CkColors.ink : CkColors.muted);

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13.5,
              fontWeight: isStriking ? FontWeight.w700 : FontWeight.w600,
              color: nameColor,
            ),
          ),
        ),
        if (line != null) ...[
          if (isStriking) ...[
            const CkPulseDot(),
            const SizedBox(width: 6),
          ],
          Text(
            line.scoreText,
            style: CkType.mono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: isStriking ? CkColors.red : CkColors.muted,
            ),
          ),
        ] else if (match.isLive)
          Text(
            'Yet to bat',
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
      ],
    );
  }
}

class _ScorerFooter extends StatelessWidget {
  const _ScorerFooter({required this.match, required this.onActions});

  final TournamentLiveMatch match;
  final VoidCallback onActions;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _staleness() {
    final last = match.lastBallAt;
    if (last == null) return match.isFinished ? 'Completed' : 'No balls yet';
    final d = DateTime.now().difference(last);
    if (d.inSeconds < 60) return 'Last ball ${d.inSeconds}s ago';
    if (d.inMinutes < 60) return 'Last ball ${d.inMinutes}m ago';
    if (d.inHours < 24) return 'Last ball ${d.inHours}h ago';
    return 'Last ball ${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final name = match.scorerName;

    return Container(
      color: CkColors.paper2,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CkColors.paper,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              name == null ? '—' : _initials(name),
              style: CkType.display(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name == null
                      ? (match.resultDescription ?? 'Result recorded')
                      : '$name · scoring',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  _staleness(),
                  style: CkType.body(fontSize: 10.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GhostChip(label: 'ACTIONS', onTap: onActions),
        ],
      ),
    );
  }
}

class _AssignScorerFooter extends StatelessWidget {
  const _AssignScorerFooter({required this.match, required this.onAssign});

  final TournamentLiveMatch match;
  final VoidCallback onAssign;

  String _startsIn() {
    final d = match.scheduledStartTime.difference(DateTime.now());
    if (d.isNegative) return 'Start time passed';
    if (d.inMinutes < 60) return 'Starts in ${d.inMinutes} minutes';
    if (d.inHours < 24) {
      return 'Starts in ${d.inHours} hour${d.inHours == 1 ? '' : 's'}';
    }
    return 'Starts in ${d.inDays} day${d.inDays == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.cream,
        border: Border(top: BorderSide(color: CkColors.creamBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CkColors.paper,
              shape: BoxShape.circle,
              border: Border.all(
                color: CkColors.creamBorder,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, size: 12, color: CkColors.amberInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NO SCORER ASSIGNED',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.amberDark,
                  ),
                ),
                Text(
                  _startsIn(),
                  style: CkType.body(fontSize: 10.5, color: CkColors.amberDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              onTap: onAssign,
              borderRadius: BorderRadius.circular(7),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Text(
                  'ASSIGN',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.paper,
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

class _GhostChip extends StatelessWidget {
  const _GhostChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: CkColors.line),
          ),
          child: Text(
            label,
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Supporting blocks ───────────────────────────────────────────────────────

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label, this.fetchedAt});

  final String label;

  /// When the board was last read. Drives the "Updated 8s ago" read-out, which
  /// is how an organiser tells a quiet ground from a stale screen.
  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
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
                letterSpacing: 0.12,
              ),
            ),
          ),
          if (fetchedAt != null) _UpdatedAgo(since: fetchedAt!),
        ],
      ),
    );
  }
}

/// Ticks on its own so the number stays honest without refetching the board.
class _UpdatedAgo extends StatefulWidget {
  const _UpdatedAgo({required this.since});

  final DateTime since;

  @override
  State<_UpdatedAgo> createState() => _UpdatedAgoState();
}

class _UpdatedAgoState extends State<_UpdatedAgo> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 5),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _label {
    final d = DateTime.now().difference(widget.since);
    if (d.inSeconds < 60) return 'Updated ${d.inSeconds}s ago';
    if (d.inMinutes < 60) return 'Updated ${d.inMinutes}m ago';
    return 'Updated ${d.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.refresh, size: 11, color: CkColors.muted),
        const SizedBox(width: 5),
        Text(
          _label.toUpperCase(),
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: CkType.mono(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Artboard 27h — the draw is locked but nobody has bowled yet. The tab is a
/// readiness checklist rather than an empty dashboard.
class _PreMatchdayReadiness extends StatelessWidget {
  const _PreMatchdayReadiness({required this.board});

  final List<TournamentLiveMatch> board;

  @override
  Widget build(BuildContext context) {
    final withScorer = board.where((m) => m.scorerId != null).length;
    final next = board.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionEyebrow(label: 'Matchday readiness'),
        const SizedBox(height: 8),
        _ReadinessRow(
          done: true,
          title: '${board.length} fixtures scheduled',
          subtitle: '${board.map((m) => m.venue).toSet().length} '
              'ground${board.map((m) => m.venue).toSet().length == 1 ? '' : 's'}',
        ),
        _ReadinessRow(
          done: withScorer == board.length,
          title: '$withScorer of ${board.length} scorers assigned',
          subtitle: withScorer == board.length
              ? 'Every ground is covered'
              : 'Assign before the first ball',
        ),
        const SizedBox(height: 14),
        Text(
          'FIRST FIXTURES',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 8),
        for (final m in next)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  '${m.scheduledStartTime.hour.toString().padLeft(2, '0')}:'
                  '${m.scheduledStartTime.minute.toString().padLeft(2, '0')}',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: CkColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${m.teamAName ?? 'TBC'} v ${m.teamBName ?? 'TBC'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 12.5, color: CkColors.ink2),
                  ),
                ),
                Text(
                  m.scorerName == null ? 'No scorer' : m.venue,
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: m.scorerName == null
                        ? CkColors.amberDark
                        : CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live scores appear here on matchday',
                style: CkType.display(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Once the first scorer starts a match, this tab becomes the '
                'multi-ground dashboard.',
                style: CkType.body(
                  fontSize: 12,
                  height: 1.5,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.done,
    required this.title,
    required this.subtitle,
  });

  final bool done;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: done ? CkColors.paper : CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(
          color: done ? CkColors.hairline : CkColors.creamBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? CkColors.greenInk : CkColors.amberInk,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: CkType.display(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: CkType.body(
                    fontSize: 11,
                    color: done ? CkColors.muted : CkColors.amberDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoFixturesState extends StatelessWidget {
  const _NoFixturesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No fixtures yet',
              style: CkType.display(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Generate the draw on the Fixtures tab. Live scores appear here '
              'once the first scorer starts a match.',
              style: CkType.body(
                fontSize: 12.5,
                height: 1.5,
                color: CkColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load the board',
              style: CkType.display(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: CkType.body(fontSize: 12, color: CkColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
