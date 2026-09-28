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
    this.onStartMatch,
    this.onQuickPin,
    this.onReschedule,
    this.onStartSecondInnings,
    this.onAutoAssignScorers,
    this.onOpenScorer,
  });

  final Tournament tournament;
  final void Function(TournamentLiveMatch match) onMatchActions;
  final void Function(TournamentLiveMatch match) onAssignScorer;
  final void Function(TournamentLiveMatch match)? onStartMatch;
  final void Function(TournamentLiveMatch match)? onQuickPin;
  final void Function(TournamentLiveMatch match)? onReschedule;

  /// Artboard 27L — the innings-break card's single unblocking action.
  final void Function(TournamentLiveMatch match)? onStartSecondInnings;

  /// Artboard 27k — the banner's "Auto-assign >".
  final VoidCallback? onAutoAssignScorers;

  /// Artboard 27L — the live card's "Open Scorer".
  final void Function(TournamentLiveMatch match)? onOpenScorer;

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
        // Once a ground is under way the organiser's other queue is the
        // fixtures still waiting to start, so the second tile becomes
        // "Awaiting toss" (artboard 27L). Before the first ball there is
        // nothing to be awaiting yet, so it stays "Results pending"
        // (artboard 27k).
        final awaitingToss = board
            .where((m) => !m.isLive && !m.isFinished)
            .length;
        final anyLive = live.isNotEmpty;

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
                  onAutoAssign: widget.onAutoAssignScorers,
                ),
              if (!anyStarted)
                _MatchdayMorningBoard(
                  board: board,
                  onStartMatch: widget.onStartMatch,
                  onQuickPin: widget.onQuickPin,
                  onAssignScorer: onAssignScorer,
                  onReschedule: widget.onReschedule,
                  onMatchActions: onMatchActions,
                )
              else ...[
                _SectionEyebrow(
                  label: live.isEmpty
                      ? '${board.length} fixtures'
                      : 'Live now · ${live.length} '
                          'ground${live.length == 1 ? '' : 's'} active',
                  fetchedAt: _fetchedAt,
                ),
                const SizedBox(height: 8),
                for (final match in board) ...[
                  _GroundCard(
                    match: match,
                    onActions: () => onMatchActions(match),
                    onAssign: () => onAssignScorer(match),
                    onStartMatch: widget.onStartMatch == null
                        ? null
                        : () => widget.onStartMatch!(match),
                    onStartSecondInnings: widget.onStartSecondInnings == null
                        ? null
                        : () => widget.onStartSecondInnings!(match),
                    onOpenScorer: widget.onOpenScorer == null
                        ? null
                        : () => widget.onOpenScorer!(match),
                    maxOvers: tournament.maxOvers,
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
                      label: anyLive ? 'Awaiting toss' : 'Results pending',
                      value: anyLive
                          ? '$awaitingToss'
                          : '${board.length - played}',
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
  const _ScorerAlertBanner({
    required this.count,
    required this.onFix,
    this.onAutoAssign,
  });

  final int count;
  final VoidCallback onFix;

  /// Four unscored fixtures is a queue of four sheets; this collapses it to
  /// one tap (artboard 27k). Cream, because it is urgent, not dangerous.
  final VoidCallback? onAutoAssign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        child: InkWell(
          // One unscored fixture goes straight to its picker; a queue of them
          // is what auto-assign exists for.
          onTap: onAutoAssign == null || count < 2 ? onFix : onAutoAssign,
          onLongPress: onFix,
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
                  onAutoAssign == null || count < 2 ? 'FIX' : 'AUTO-ASSIGN',
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
    this.onStartMatch,
    this.onStartSecondInnings,
    this.onOpenScorer,
    this.maxOvers,
  });

  final TournamentLiveMatch match;
  final int? maxOvers;
  final VoidCallback onActions;
  final VoidCallback onAssign;
  final VoidCallback? onStartMatch;
  final VoidCallback? onStartSecondInnings;
  final VoidCallback? onOpenScorer;

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
                _TeamScoreRow(
                  match: match,
                  teamId: match.teamAId,
                  maxOvers: maxOvers,
                ),
                const SizedBox(height: 6),
                _TeamScoreRow(
                  match: match,
                  teamId: match.teamBId,
                  maxOvers: maxOvers,
                ),
              ],
            ),
          ),
          Container(height: 1, color: CkColors.hairline),
          match.needsScorer
              ? _AssignScorerFooter(match: match, onAssign: onAssign)
              : _ScorerFooter(
                  match: match,
                  onActions: onActions,
                  // A ball can only be recorded while play is on; at the
                  // break the card's action is Start 2nd Innings instead.
                  onOpenScorer: match.status == 'live' ||
                          match.status == 'super_over'
                      ? onOpenScorer
                      : null,
                ),
          // Artboard 27L: the innings-break card is the one that needs the
          // organiser, so it carries the single action that unblocks it.
          if (match.status == 'innings_break' &&
              onStartSecondInnings != null) ...[
            Container(height: 1, color: CkColors.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ElevatedButton(
                onPressed: onStartSecondInnings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CkColors.cream,
                  foregroundColor: CkColors.amberDark,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                    side: const BorderSide(color: CkColors.creamBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 17,
                      color: CkColors.amberDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Start 2nd Innings',
                      style: CkType.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: CkColors.amberDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!match.isLive && !match.isFinished && onStartMatch != null) ...[
            Container(height: 1, color: CkColors.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ElevatedButton(
                onPressed: onStartMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CkColors.ink,
                  foregroundColor: CkColors.paper,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_cricket, size: 15, color: CkColors.paper),
                    const SizedBox(width: 6),
                    Text(
                      'Start Match / Toss',
                      style: CkType.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: CkColors.paper,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.match});

  final TournamentLiveMatch match;

  static String _ordinal(int n) => switch (n) {
        1 => '1ST',
        2 => '2ND',
        3 => '3RD',
        _ => '${n}TH',
      };

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    Color? border;

    if (match.status == 'innings_break') {
      // Amber, not red: nothing is being scored, so the day's one red belongs
      // to the ground that IS live (artboard 27L).
      label = 'INNINGS BREAK';
      bg = CkColors.cream;
      fg = CkColors.amberInk;
      border = CkColors.creamBorder;
    } else if (match.status == 'super_over') {
      label = 'SUPER OVER';
      bg = CkColors.red;
      fg = Colors.white;
    } else if (match.isLive) {
      // "Live · 1st innings" — on a two-ground morning the innings is what
      // tells the organiser how long this ground still needs them.
      final innings = match.inningsLines.isEmpty
          ? null
          : match.inningsLines
              .map((l) => l.inningsNumber)
              .reduce((a, b) => a > b ? a : b);
      label = innings == null ? 'LIVE' : 'LIVE · ${_ordinal(innings)} INNINGS';
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
  const _TeamScoreRow({
    required this.match,
    required this.teamId,
    this.maxOvers,
  });

  final TournamentLiveMatch match;
  final String? teamId;
  final int? maxOvers;

  /// "Target 186 in 20" for the side that has not batted yet at the innings
  /// break. One more than the innings just completed, over the same number of
  /// overs — a display transform of numbers the engine already produced, not a
  /// re-derivation of the result.
  static String? _chaseLine(
    TournamentLiveMatch match,
    LiveInningsLine? latest, {
    int? overs,
  }) {
    if (match.status != 'innings_break' || latest == null) return null;
    final target = 'Target ${latest.runs + 1}';
    return overs == null ? target : '$target in $overs';
  }

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
    // The red + pulse belong to a ball actually being bowled. At an innings
    // break nothing is being scored, so the card keeps its ink (artboard 27L)
    // and the day's one red stays on the ground that is live.
    final isBeingScored = match.status == 'live' || match.status == 'super_over';
    final isStriking = isBeingScored &&
        line != null &&
        line.inningsNumber == latest?.inningsNumber;

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
            // At the break the side yet to bat has a target, which is the
            // more useful thing to show than "Yet to bat".
            _chaseLine(match, latest, overs: maxOvers) ?? 'Yet to bat',
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
      ],
    );
  }
}

class _ScorerFooter extends StatelessWidget {
  const _ScorerFooter({
    required this.match,
    required this.onActions,
    this.onOpenScorer,
  });

  final TournamentLiveMatch match;
  final VoidCallback onActions;

  /// Only offered while a ball can actually be recorded (artboard 27L).
  final VoidCallback? onOpenScorer;

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
          // Artboard 27L gives the live card two actions, not one: the board
          // answers "which ground needs me right now", and the answer is
          // usually "open the scorer", not "open a menu".
          if (onOpenScorer != null) ...[
            _GhostChip(label: 'OPEN SCORER', onTap: onOpenScorer!),
            const SizedBox(width: 6),
          ],
          _GhostChip(
            label: onOpenScorer == null ? 'ACTIONS' : 'MATCH OPS',
            onTap: onActions,
          ),
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

/// Artboard 27k — matchday morning, actionable.
///
/// Instead of a passive read-only checklist, this presents each scheduled
/// fixture as an interactive card with [Start Match / Toss], [Quick PIN],
/// and inline schedule editing.
class _MatchdayMorningBoard extends StatefulWidget {
  const _MatchdayMorningBoard({
    required this.board,
    required this.onStartMatch,
    required this.onQuickPin,
    required this.onAssignScorer,
    required this.onReschedule,
    required this.onMatchActions,
  });

  final List<TournamentLiveMatch> board;
  final void Function(TournamentLiveMatch match)? onStartMatch;
  final void Function(TournamentLiveMatch match)? onQuickPin;
  final void Function(TournamentLiveMatch match) onAssignScorer;
  final void Function(TournamentLiveMatch match)? onReschedule;
  final void Function(TournamentLiveMatch match) onMatchActions;

  @override
  State<_MatchdayMorningBoard> createState() => _MatchdayMorningBoardState();
}

class _MatchdayMorningBoardState extends State<_MatchdayMorningBoard> {
  /// Artboard 27k shows the first two fixtures in full and folds the rest
  /// behind "Show 2 more" — a matchday morning is about the next match, not
  /// the whole card.
  static const _initiallyShown = 2;
  bool _expanded = false;

  /// "13:30 · G2" — the two facts that tell the organiser when and where.
  static String _slot(TournamentLiveMatch m) {
    final t = m.scheduledStartTime;
    final time = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    return '$time · ${m.venue}';
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final onStartMatch = widget.onStartMatch;
    final onQuickPin = widget.onQuickPin;
    final onAssignScorer = widget.onAssignScorer;
    final onReschedule = widget.onReschedule;
    final onMatchActions = widget.onMatchActions;

    final withScorer = board.where((m) => m.scorerId != null).length;
    final totalGrounds = board.map((m) => m.venue).toSet().length;
    final visibleCount =
        _expanded ? board.length : board.length.clamp(0, _initiallyShown);
    final hidden = board.length - visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionEyebrow(label: 'Matchday readiness'),
        const SizedBox(height: 8),
        _ReadinessRow(
          done: true,
          title: '${board.length} fixtures scheduled',
          subtitle: '$totalGrounds ground${totalGrounds == 1 ? '' : 's'}',
        ),
        _ReadinessRow(
          done: withScorer == board.length,
          title: '$withScorer of ${board.length} scorers assigned',
          subtitle: withScorer == board.length
              ? 'Every ground is covered'
              : 'Assign before the first ball',
        ),
        const SizedBox(height: 14),

        // Section header for scheduled fixtures
        Row(
          children: [
            Expanded(
              child: Text(
                'FIXTURES · AWAITING TOSS',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: CkColors.muted,
                ),
              ),
            ),
            Text(
              '${board.length} matches',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Fixture Cards (Artboard 27k)
        for (var i = 0; i < visibleCount; i++) ...[
          _ScheduledMatchCard(
            matchIndex: i + 1,
            match: board[i],
            onStartMatch: () => onStartMatch?.call(board[i]),
            onQuickPin: () => onQuickPin?.call(board[i]),
            onAssign: () => onAssignScorer(board[i]),
            onReschedule: () => onReschedule?.call(board[i]),
            onActions: () => onMatchActions(board[i]),
          ),
          const SizedBox(height: 10),
        ],

        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      // Name the folded fixtures rather than just counting
                      // them, the way the artboard does.
                      board
                          .skip(visibleCount)
                          .map((m) => '${m.round ?? 'Match'} ${_slot(m)}')
                          .join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Show $hidden more',
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 4),

        // Bottom stats: Played 0 / N, Awaiting toss N
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAYED',
                      style: CkType.mono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.10,
                        color: CkColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0 / ${board.length}',
                      style: CkType.mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AWAITING TOSS',
                      style: CkType.mono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.10,
                        color: CkColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${board.length}',
                      style: CkType.mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Artboard 27h's closing line — the tab says what it will become, so
        // the empty dashboard reads as "not yet" rather than "broken".
        Text(
          'Live scores appear here on matchday',
          style: CkType.body(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: CkColors.ink2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Once the first scorer starts a match, this tab becomes the '
          'multi-ground dashboard.',
          style: CkType.body(
            fontSize: 11.5,
            height: 1.5,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ScheduledMatchCard extends StatelessWidget {
  const _ScheduledMatchCard({
    required this.matchIndex,
    required this.match,
    required this.onStartMatch,
    required this.onQuickPin,
    required this.onAssign,
    required this.onReschedule,
    required this.onActions,
  });

  final int matchIndex;
  final TournamentLiveMatch match;
  final VoidCallback onStartMatch;
  final VoidCallback onQuickPin;
  final VoidCallback onAssign;
  final VoidCallback onReschedule;
  final VoidCallback onActions;

  String _monogram(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.characters.first)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${match.scheduledStartTime.hour.toString().padLeft(2, '0')}:'
        '${match.scheduledStartTime.minute.toString().padLeft(2, '0')}';
    final label = match.round != null && match.round!.isNotEmpty
        ? match.round!
        : 'M$matchIndex';

    final teamA = match.teamAName ?? 'TBC';
    final teamB = match.teamBName ?? 'TBC';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: M1 · 09:00 · Ground 1 · Edit · Scheduled
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              color: CkColors.paper2,
              border: Border(bottom: BorderSide(color: CkColors.hairline)),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                    color: CkColors.ink,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$timeStr · ${match.venue}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.02,
                      color: CkColors.muted,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onReschedule,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 11, color: CkColors.ink),
                        const SizedBox(width: 3),
                        Text(
                          'Edit',
                          style: CkType.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06,
                            color: CkColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CkColors.paper,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Text(
                    'SCHEDULED',
                    style: CkType.mono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Matchup row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
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
                    _monogram(teamA),
                    style: CkType.mono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    teamA,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'v',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CkColors.soft,
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
                    _monogram(teamB),
                    style: CkType.mono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    teamB,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scorer Status Bar
          if (match.needsScorer) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: CkColors.cream,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CkColors.creamBorder),
              ),
              child: Row(
                children: [
                  Text(
                    'NO SCORER',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.amberDark,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onQuickPin,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: CkColors.creamBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dialpad, size: 12, color: CkColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            'QUICK PIN',
                            style: CkType.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.06,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onAssign,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: CkColors.ink),
                      ),
                      child: Text(
                        '+ Assign',
                        style: CkType.body(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CkColors.greenInk,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scorer: ${match.scorerName ?? 'Assigned'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: CkColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons: [Start Match / Toss] + [Actions ▾]
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onStartMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports_cricket, size: 16, color: CkColors.paper),
                        const SizedBox(width: 7),
                        Text(
                          'Start Match / Toss',
                          style: CkType.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CkColors.paper,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onActions,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CkColors.hairline),
                    backgroundColor: CkColors.paper,
                    elevation: 0,
                    minimumSize: const Size(90, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Actions',
                        style: CkType.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16, color: CkColors.ink),
                    ],
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
