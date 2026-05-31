import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../providers/matches_providers.dart';

// =============================================================================
// ScoringScreen — design-faithful live ball-by-ball scorer.
// =============================================================================
// Drives the deployed `record_ball` / `undo_last_ball` / `start_innings` RPCs.
// Layout + interactions track the design bundle's Scoring.html /
// scoring-sheets.jsx pixel-by-pixel:
//
//   • Top bar (close · SCORING chip + match meta · More)
//   • Ink scoreboard card (runs/wickets + overs + need + CRR/RRR)
//   • Striker / non-striker cards with red on-strike dot
//   • Bowler strip with last 6-ball dots
//   • Free-hit banner (when the last non-wide ball was a no-ball)
//   • Last-ball card with Undo (flashes cream on undo)
//   • Run pad: row 1 [0, 1, 2, 3] · row 2 [4 (green-soft), 6 (ink), W (red-soft)]
//   • Extras row: Wide / No-ball / Bye / Leg-bye (cream pills)
//   • Ball log (latest item highlighted cream)
//   • Toast at bottom for free-hit / wicket pings
//   • Bottom sheets: ExtrasSheet · WicketSheet (multi-stage) · NewBowlerSheet
//
// Setup / Match Start is NOT this screen — it's its own route. The need-a-
// bowler prompt at innings 1 ball 1 still fires here.
// =============================================================================

const _bowlerBadgeColor = Color(0xFF1A6A2E); // oklch(0.36 0.10 148)
const _freeHitBorder = Color(0xFFD9B96B); // oklch(0.85 0.10 80)
const _freeHitText = Color(0xFF4B3514); // oklch(0.32 0.10 80)

class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({
    super.key,
    required this.matchId,
    this.inningsNumber = 1,
  });
  final String matchId;

  /// Which innings this screen is scoring. Innings 1 by default; the
  /// innings-break flow routes here with `?innings=2` for the chase.
  final int inningsNumber;

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  bool _busy = false;
  bool _bowlerPromptShown = false;
  bool _undoFlash = false;
  String? _toast;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  // ─── id translation helpers ─────────────────────────────────────────────

  String? _refIdOf(String? matchPlayerId, List<MatchPlayer> mps) {
    if (matchPlayerId == null) return null;
    for (final mp in mps) {
      if (mp.id.value == matchPlayerId) return mp.playerRefId;
    }
    return null;
  }

  // ─── ui helpers ─────────────────────────────────────────────────────────

  void _flashToast(String msg) {
    _toastTimer?.cancel();
    setState(() => _toast = msg);
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _flashUndo() {
    setState(() => _undoFlash = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _undoFlash = false);
    });
  }

  // ─── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Lifecycle navigation: record-ball flips the match to innings_break /
    // completed and broadcasts it; route to the matching screen.
    ref.listen(liveMatchProvider(widget.matchId), (prev, next) {
      switch (next.value?.status) {
        case MatchStatus.inningsBreak:
          context.go('/matches/${widget.matchId}/innings-break');
        case MatchStatus.completed:
        case MatchStatus.abandoned:
        case MatchStatus.walkover:
          context.go('/matches/${widget.matchId}/result');
        case _:
          break;
      }
    });

    final match = ref.watch(liveMatchProvider(widget.matchId)).value;
    if (match == null) {
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator(color: CkColors.ink)),
      );
    }
    final inningsState = ref
        .watch(liveInningsStateProvider(widget.matchId, widget.inningsNumber))
        .value;
    final matchPlayers =
        ref.watch(matchPlayersProvider(widget.matchId)).value ??
            const <MatchPlayer>[];
    final balls =
        ref.watch(liveBallsProvider(widget.matchId, widget.inningsNumber)).value ??
            const <Ball>[];
    final rosterA = ref.watch(rosterProvider(match.teamAId.value)).value ??
        const <RosterMember>[];
    final rosterB = ref.watch(rosterProvider(match.teamBId.value)).value ??
        const <RosterMember>[];

    // Need-a-bowler gate: live + no bowler + no ball yet + data ready.
    final dataReady = matchPlayers.isNotEmpty &&
        rosterA.isNotEmpty &&
        rosterB.isNotEmpty;
    final bowlerMissing = match.startPhase == MatchStartPhase.live &&
        inningsState?.bowlerId == null &&
        balls.isEmpty &&
        dataReady;
    if (bowlerMissing && !_bowlerPromptShown) {
      _bowlerPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptOpeningBowler(match, matchPlayers);
      });
    }

    // Names map keyed by player_ref_id — covers both rosters.
    final names = <String, String>{
      for (final m in rosterA) m.member.playerId: m.displayName,
      for (final m in rosterB) m.member.playerId: m.displayName,
    };
    String nameOf(String? refId) =>
        refId == null ? '—' : (names[refId] ?? 'Player');

    // Derived live data
    final strikerRef =
        _refIdOf(inningsState?.strikerId?.value, matchPlayers);
    final nonStrikerRef =
        _refIdOf(inningsState?.nonStrikerId?.value, matchPlayers);
    final bowlerRef = _refIdOf(inningsState?.bowlerId?.value, matchPlayers);

    final stats = _battersStats(balls);
    final strikerStats =
        stats[inningsState?.strikerId?.value] ?? const _BatStats(0, 0, 0, 0);
    final nonStrikerStats =
        stats[inningsState?.nonStrikerId?.value] ?? const _BatStats(0, 0, 0, 0);
    final bowlerStats =
        _bowlerStatsFor(inningsState?.bowlerId?.value, balls);

    final legalBalls = inningsState?.legalBallCount ?? 0;
    final overText = '${legalBalls ~/ 6}.${legalBalls % 6}';
    final totalRuns = inningsState?.totalRuns ?? 0;
    final totalWkts = inningsState?.totalWickets ?? 0;

    final formatOvers = match.format.oversPerInnings == 0
        ? 20
        : match.format.oversPerInnings;
    final ballsLeft = (formatOvers * 6) - legalBalls;
    final crr = legalBalls > 0 ? totalRuns / (legalBalls / 6) : 0;

    // Free-hit derivation: the next legal delivery after a no-ball is a
    // free hit; intervening wides do not consume it.
    final lastNonWide = balls.reversed
        .firstWhereOrNull((b) => b.ballKind != BallKind.wide);
    final freeHitActive =
        lastNonWide != null && lastNonWide.ballKind == BallKind.noBall;

    final lastBall = balls.isEmpty ? null : balls.last;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _topBar(context),
                      _scoreboard(
                        runs: totalRuns,
                        wickets: totalWkts,
                        overs: overText,
                        formatOvers: formatOvers,
                        ballsLeft: ballsLeft,
                        crr: crr,
                      ),
                      _battersAndBowler(
                        strikerName: nameOf(strikerRef),
                        nonStrikerName: nameOf(nonStrikerRef),
                        strikerStats: strikerStats,
                        nonStrikerStats: nonStrikerStats,
                        bowlerName: nameOf(bowlerRef),
                        bowlerInitials: _initials(nameOf(bowlerRef)),
                        bowlerStats: bowlerStats,
                        overChips:
                            _currentOverChips(balls, legalBalls),
                      ),
                      if (freeHitActive) const _FreeHitBanner(),
                      _LastBallCard(
                        last: lastBall,
                        nameOf: nameOf,
                        matchPlayers: matchPlayers,
                        undoFlash: _undoFlash,
                        canUndo: balls.isNotEmpty && !_busy,
                        onUndo: () => _handleUndo(match),
                      ),
                      _runPad(
                          match, balls, matchPlayers, inningsState),
                      _extrasRow(match, matchPlayers, inningsState),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ballLog(balls, nameOf, matchPlayers),
                ),
              ],
            ),
            if (_toast != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
                child: Center(child: _Toast(message: _toast!)),
              ),
          ],
        ),
      ),
    );
  }

  // ─── visual sections ────────────────────────────────────────────────────

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 22, color: CkColors.ink),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: CkColors.red,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'SCORING',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'FRIENDLY',
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.muted,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.more_horiz,
                    size: 14, color: CkColors.ink2),
                const SizedBox(width: 6),
                Text(
                  'More',
                  style: CkType.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreboard({
    required int runs,
    required int wickets,
    required String overs,
    required int formatOvers,
    required int ballsLeft,
    required num crr,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$runs',
                      style: CkType.display(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        color: CkColors.paper,
                      ),
                    ),
                    TextSpan(
                      text: '/$wickets',
                      style: CkType.display(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        color: const Color(0x8CFDFAF4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'OVERS',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                        color: const Color(0x8CFDFAF4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: overs,
                              style: CkType.display(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: CkColors.paper,
                              ),
                            ),
                            TextSpan(
                              text: ' /$formatOvers',
                              style: CkType.display(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0x80FDFAF4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BALLS',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.08,
                      color: const Color(0x8CFDFAF4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      '$ballsLeft',
                      style: CkType.display(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x1AFFFFFF)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'CRR ',
                    style: CkType.mono(
                      fontSize: 11,
                      color: const Color(0x8CFDFAF4),
                    ),
                  ),
                  Text(
                    crr.toStringAsFixed(2),
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CkColors.paper,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _battersAndBowler({
    required String strikerName,
    required String nonStrikerName,
    required _BatStats strikerStats,
    required _BatStats nonStrikerStats,
    required String bowlerName,
    required String bowlerInitials,
    required _BowlerStats bowlerStats,
    required List<_Chip> overChips,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _BatterCard(
                  name: strikerName,
                  stats: strikerStats,
                  onStrike: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BatterCard(
                  name: nonStrikerName,
                  stats: nonStrikerStats,
                  onStrike: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _bowlerBadgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    bowlerInitials,
                    style: CkType.display(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CkColors.paper,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bowlerName,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${bowlerStats.overs}.${bowlerStats.ballsThisOver} ov · ${bowlerStats.runs}r · ${bowlerStats.wickets}w',
                        style: CkType.mono(
                          fontSize: 10,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      i < overChips.length
                          ? _BallChip(
                              chip: overChips[i],
                              size: 22,
                            )
                          : _emptyBallSlot(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBallSlot() => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CkColors.line, width: 1.5, style: BorderStyle.solid),
        ),
      );

  Widget _runPad(
    Match match,
    List<Ball> balls,
    List<MatchPlayer> matchPlayers,
    MatchInningsState? inningsState,
  ) {
    final canTap = !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              for (final r in const [0, 1, 2, 3]) ...[
                Expanded(
                  child: _RunButton(
                    value: r,
                    big: false,
                    onTap: canTap
                        ? () => _handleRun(match, r, matchPlayers, inningsState)
                        : null,
                  ),
                ),
                if (r != 3) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _RunButton(
                  value: 4,
                  big: true,
                  onTap: canTap
                      ? () =>
                          _handleRun(match, 4, matchPlayers, inningsState)
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _RunButton(
                  value: 6,
                  big: true,
                  onTap: canTap
                      ? () =>
                          _handleRun(match, 6, matchPlayers, inningsState)
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WicketButton(
                  onTap: canTap
                      ? () => _openWicketSheet(
                          match, balls, matchPlayers, inningsState)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _extrasRow(
    Match match,
    List<MatchPlayer> matchPlayers,
    MatchInningsState? inningsState,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: _ExtraButton(
              label: 'Wide',
              onTap: () => _openExtrasSheet(
                  match, BallKind.wide, matchPlayers, inningsState),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ExtraButton(
              label: 'No-ball',
              onTap: () => _openExtrasSheet(
                  match, BallKind.noBall, matchPlayers, inningsState),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ExtraButton(
              label: 'Bye',
              onTap: () => _openExtrasSheet(
                  match, BallKind.bye, matchPlayers, inningsState),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ExtraButton(
              label: 'Leg-bye',
              onTap: () => _openExtrasSheet(
                  match, BallKind.legBye, matchPlayers, inningsState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ballLog(
    List<Ball> balls,
    String Function(String?) nameOf,
    List<MatchPlayer> matchPlayers,
  ) {
    final reversed = balls.reversed.toList();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CkColors.hairline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'BALL LOG',
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: CkColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${balls.length} balls',
                    style: CkType.mono(
                      fontSize: 10,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < reversed.length && i < 12; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _BallLogRow(
                  ball: reversed[i],
                  highlighted: i == 0,
                  description: _describeBall(
                    reversed[i],
                    nameOf,
                    matchPlayers,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── action handlers ────────────────────────────────────────────────────

  /// Standard run (0/1/2/3/4/6).
  Future<void> _handleRun(
    Match match,
    int runs,
    List<MatchPlayer> matchPlayers,
    MatchInningsState? inningsState,
  ) async {
    await _submit(BallDraft(
      matchId: match.id,
      inningsNumber: widget.inningsNumber,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runs,
      batsmanId: inningsState?.strikerId?.value,
      nonStrikerId: inningsState?.nonStrikerId?.value,
      bowlerId: inningsState?.bowlerId?.value,
      expectedVersion: inningsState?.version,
    ));
  }

  /// Extras committed from the bottom sheet.
  Future<void> _handleExtraCommit(
    Match match,
    _ExtraResult result,
    MatchInningsState? inningsState,
  ) async {
    final isWideOrNb = result.kind == BallKind.wide ||
        result.kind == BallKind.noBall;
    final runsScored = isWideOrNb ? result.runs : 0;
    final extras = isWideOrNb ? 1 : result.runs;
    await _submit(BallDraft(
      matchId: match.id,
      inningsNumber: widget.inningsNumber,
      isLegalDelivery: !isWideOrNb,
      ballKind: result.kind,
      runsScored: runsScored,
      extras: extras,
      batsmanId: inningsState?.strikerId?.value,
      nonStrikerId: inningsState?.nonStrikerId?.value,
      bowlerId: inningsState?.bowlerId?.value,
      expectedVersion: inningsState?.version,
    ));
    if (result.freeHit) _flashToast('Free hit — next ball');
  }

  Future<void> _handleWicketCommit(
    Match match,
    _WicketResult r,
    List<MatchPlayer> matchPlayers,
    MatchInningsState? inningsState,
  ) async {
    await _submit(BallDraft(
      matchId: match.id,
      inningsNumber: widget.inningsNumber,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: r.runsBefore,
      isWicket: true,
      wicketType: r.type,
      batsmanId: inningsState?.strikerId?.value,
      nonStrikerId: inningsState?.nonStrikerId?.value,
      bowlerId: inningsState?.bowlerId?.value,
      fielderId: r.fielderMatchPlayerId,
      expectedVersion: inningsState?.version,
    ));
    if (r.nextBatterMatchPlayerId != null && mounted) {
      // Re-open the innings with the new batter on strike.
      await ref.read(matchesRepositoryProvider).startInnings(
            matchId: match.id,
            inningsNumber: widget.inningsNumber,
            strikerId: r.nextBatterMatchPlayerId!,
            nonStrikerId: inningsState?.nonStrikerId?.value ?? '',
            bowlerId: inningsState?.bowlerId?.value ?? '',
          );
    }
    _flashToast('${(inningsState?.totalWickets ?? 0) + 1} down');
  }

  Future<void> _submit(BallDraft draft) async {
    setState(() => _busy = true);
    final result =
        await ref.read(matchesRepositoryProvider).recordBall(draft);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );

    // End-of-over → prompt for next bowler.
    final updatedBalls = ref
            .read(liveBallsProvider(draft.matchId.value, draft.inningsNumber))
            .value ??
        const <Ball>[];
    if (updatedBalls.isEmpty) return;
    final lastOver = updatedBalls.last.overNumber;
    final overLegal = updatedBalls
        .where((b) => b.overNumber == lastOver && b.isLegalDelivery)
        .length;
    if (overLegal == 6 && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) await _promptEndOfOverBowler();
    }
  }

  Future<void> _handleUndo(Match match) async {
    setState(() => _busy = true);
    final result =
        await ref.read(matchesRepositoryProvider).undoLastBall(
              matchId: match.id,
              inningsNumber: widget.inningsNumber,
            );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );
    _flashUndo();
  }

  // ─── sheets ─────────────────────────────────────────────────────────────

  Future<void> _openExtrasSheet(
    Match match,
    BallKind kind,
    List<MatchPlayer> matchPlayers,
    MatchInningsState? inningsState,
  ) async {
    final overText =
        '${(inningsState?.legalBallCount ?? 0) ~/ 6}.${(inningsState?.legalBallCount ?? 0) % 6}';
    final result = await showModalBottomSheet<_ExtraResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder: (_) => _ExtrasSheet(kind: kind, overs: overText),
    );
    if (result != null && mounted) {
      await _handleExtraCommit(match, result, inningsState);
    }
  }

  Future<void> _openWicketSheet(
    Match match,
    List<Ball> balls,
    List<MatchPlayer> matchPlayers,
    MatchInningsState? inningsState,
  ) async {
    final battingSide = _battingTeamSide(match);
    final fieldingSide =
        battingSide == MatchTeamSide.a ? MatchTeamSide.b : MatchTeamSide.a;

    final battingTeamId =
        battingSide == MatchTeamSide.a ? match.teamAId : match.teamBId;
    final fieldingTeamId =
        battingSide == MatchTeamSide.a ? match.teamBId : match.teamAId;

    final battingRoster =
        ref.read(rosterProvider(battingTeamId.value)).value ??
            const <RosterMember>[];
    final fieldingRoster =
        ref.read(rosterProvider(fieldingTeamId.value)).value ??
            const <RosterMember>[];

    final fieldingPeople = matchPlayers
        .where((p) => p.teamSide == fieldingSide)
        .map((p) {
          final name = fieldingRoster
                  .firstWhereOrNull(
                      (r) => r.member.playerId == p.playerRefId)
                  ?.displayName ??
              'Player';
          return _SheetPerson(id: p.id.value, name: name, role: '');
        })
        .toList();

    final used = <String>{};
    for (final b in balls) {
      if (b.batsmanId != null) used.add(b.batsmanId!);
    }
    if (inningsState?.strikerId != null) {
      used.add(inningsState!.strikerId!.value);
    }
    if (inningsState?.nonStrikerId != null) {
      used.add(inningsState!.nonStrikerId!.value);
    }
    final benchPeople = matchPlayers
        .where((p) =>
            p.teamSide == battingSide && !used.contains(p.id.value))
        .map((p) {
          final name = battingRoster
                  .firstWhereOrNull(
                      (r) => r.member.playerId == p.playerRefId)
                  ?.displayName ??
              'Player';
          return _SheetPerson(id: p.id.value, name: name, role: '');
        })
        .toList();

    final strikerName = battingRoster
            .firstWhereOrNull((r) =>
                r.member.playerId ==
                _refIdOf(inningsState?.strikerId?.value, matchPlayers))
            ?.displayName ??
        '—';
    final nonStrikerName = battingRoster
            .firstWhereOrNull((r) =>
                r.member.playerId ==
                _refIdOf(inningsState?.nonStrikerId?.value, matchPlayers))
            ?.displayName ??
        '—';
    final bowlerName = fieldingRoster
            .firstWhereOrNull((r) =>
                r.member.playerId ==
                _refIdOf(inningsState?.bowlerId?.value, matchPlayers))
            ?.displayName ??
        '—';

    final overText =
        '${(inningsState?.legalBallCount ?? 0) ~/ 6}.${(inningsState?.legalBallCount ?? 0) % 6}';

    final result = await showModalBottomSheet<_WicketResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder: (_) => _WicketSheet(
        overs: overText,
        totalRuns: inningsState?.totalRuns ?? 0,
        totalWickets: inningsState?.totalWickets ?? 0,
        strikerName: strikerName,
        nonStrikerName: nonStrikerName,
        bowlerName: bowlerName,
        fielders: fieldingPeople,
        bench: benchPeople,
      ),
    );
    if (result != null && mounted) {
      await _handleWicketCommit(match, result, matchPlayers, inningsState);
    }
  }

  Future<void> _promptEndOfOverBowler() async {
    final match = ref.read(liveMatchProvider(widget.matchId)).value;
    if (match == null) return;
    final matchPlayers =
        ref.read(matchPlayersProvider(widget.matchId)).value ??
            const <MatchPlayer>[];
    final inningsState = ref
        .read(liveInningsStateProvider(widget.matchId, widget.inningsNumber))
        .value;
    final battingSide = _battingTeamSide(match);
    final bowlingSide = battingSide == MatchTeamSide.a
        ? MatchTeamSide.b
        : MatchTeamSide.a;
    final bowlingTeamId =
        bowlingSide == MatchTeamSide.a ? match.teamAId : match.teamBId;
    final roster = ref.read(rosterProvider(bowlingTeamId.value)).value ??
        const <RosterMember>[];

    final currentBowlerMpId = inningsState?.bowlerId?.value;

    final bowlerPeople = matchPlayers
        .where((p) =>
            p.teamSide == bowlingSide && p.id.value != currentBowlerMpId)
        .map((p) {
          final name = roster
                  .firstWhereOrNull(
                      (r) => r.member.playerId == p.playerRefId)
                  ?.displayName ??
              'Player';
          return _SheetPerson(id: p.id.value, name: name, role: '');
        })
        .toList();
    final justBowledName = roster
            .firstWhereOrNull((r) =>
                r.member.playerId ==
                _refIdOf(currentBowlerMpId, matchPlayers))
            ?.displayName ??
        '—';

    final legalBalls = inningsState?.legalBallCount ?? 0;
    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder: (_) => _NewBowlerSheet(
        overNumber: legalBalls ~/ 6,
        justBowled: justBowledName,
        people: bowlerPeople,
      ),
    );
    if (pick == null || !mounted) return;
    await ref.read(matchesRepositoryProvider).startInnings(
          matchId: match.id,
          inningsNumber: widget.inningsNumber,
          // Strike rotates at end of over: previous non-striker is on strike.
          strikerId: inningsState?.nonStrikerId?.value ?? '',
          nonStrikerId: inningsState?.strikerId?.value ?? '',
          bowlerId: pick,
        );
  }

  Future<void> _promptOpeningBowler(
    Match match,
    List<MatchPlayer> matchPlayers,
  ) async {
    final battingSide = _battingTeamSide(match);
    final bowlingSide = battingSide == MatchTeamSide.a
        ? MatchTeamSide.b
        : MatchTeamSide.a;
    final bowlingTeamId =
        bowlingSide == MatchTeamSide.a ? match.teamAId : match.teamBId;
    final roster = ref.read(rosterProvider(bowlingTeamId.value)).value ??
        const <RosterMember>[];

    final bowlerPeople = matchPlayers
        .where((p) => p.teamSide == bowlingSide)
        .map((p) {
          final name = roster
                  .firstWhereOrNull(
                      (r) => r.member.playerId == p.playerRefId)
                  ?.displayName ??
              'Player';
          return _SheetPerson(id: p.id.value, name: name, role: '');
        })
        .toList();
    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _NewBowlerSheet(
        overNumber: 0,
        justBowled: null,
        people: bowlerPeople,
        title: 'Pick opening bowler',
        kicker: 'INNINGS ${widget.inningsNumber}',
      ),
    );
    if (pick == null) {
      _bowlerPromptShown = false;
      return;
    }
    final inningsState = ref
        .read(liveInningsStateProvider(widget.matchId, widget.inningsNumber))
        .value;
    setState(() => _busy = true);
    final result = await ref.read(matchesRepositoryProvider).startInnings(
          matchId: match.id,
          inningsNumber: widget.inningsNumber,
          strikerId: inningsState?.strikerId?.value ?? '',
          nonStrikerId: inningsState?.nonStrikerId?.value ?? '',
          bowlerId: pick,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );
  }

  // ─── derived helpers ────────────────────────────────────────────────────

  MatchTeamSide _battingTeamSide(Match match) {
    final t = _battingTeamId(match, widget.inningsNumber);
    return t == match.teamAId ? MatchTeamSide.a : MatchTeamSide.b;
  }

  List<_Chip> _currentOverChips(List<Ball> balls, int legalBalls) {
    if (balls.isEmpty) return const [];
    final currentOver = legalBalls ~/ 6;
    final inOver =
        balls.where((b) => b.overNumber == currentOver).toList();
    return inOver
        .map((b) => _Chip(label: _chipLabelFor(b), kind: _chipKindFor(b)))
        .toList();
  }

  String _initials(String name) {
    final words =
        name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length.clamp(0, 2)).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  String _describeBall(
    Ball b,
    String Function(String?) nameOf,
    List<MatchPlayer> matchPlayers,
  ) {
    if (b.isWicket) {
      final wt = b.wicketType?.wire ?? 'wicket';
      return 'WICKET · $wt';
    }
    switch (b.ballKind) {
      case BallKind.wide:
        return 'Wide${b.extras > 1 ? ' + ${b.extras - 1}' : ''}';
      case BallKind.noBall:
        return 'No-ball${b.runsScored > 0 ? ' · ${b.runsScored} off bat' : ''}';
      case BallKind.bye:
        return '${b.extras} bye${b.extras == 1 ? '' : 's'}';
      case BallKind.legBye:
        return '${b.extras} leg-bye${b.extras == 1 ? '' : 's'}';
      case BallKind.legal:
        if (b.runsScored == 0) return 'Dot ball';
        if (b.runsScored == 4) return 'Four!';
        if (b.runsScored == 6) return 'SIX!';
        return '${b.runsScored} run${b.runsScored == 1 ? '' : 's'}';
    }
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _BatterCard extends StatelessWidget {
  const _BatterCard({
    required this.name,
    required this.stats,
    required this.onStrike,
  });
  final String name;
  final _BatStats stats;
  final bool onStrike;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: onStrike ? CkColors.surface : CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onStrike ? CkColors.ink : CkColors.hairline,
          width: onStrike ? 1.5 : 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onStrike ? CkColors.ink : CkColors.ink2,
                      ),
                    ),
                  ),
                  if (onStrike)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '·STRIKE',
                        style: CkType.body(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.05,
                          color: CkColors.red,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${stats.runs}',
                    style: CkType.display(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${stats.balls})',
                    style: CkType.mono(
                      fontSize: 11,
                      color: CkColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${stats.fours}×4 ${stats.sixes}×6',
                    style: CkType.mono(
                      fontSize: 10,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onStrike)
            const Positioned(
              top: 0,
              right: 0,
              child: _StrikeDot(),
            ),
        ],
      ),
    );
  }
}

class _StrikeDot extends StatelessWidget {
  const _StrikeDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: CkColors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({
    required this.value,
    required this.big,
    required this.onTap,
  });
  final int value;
  final bool big;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFour = value == 4;
    final isSix = value == 6;
    final isDot = value == 0;

    final bg = isFour
        ? CkColors.greenSoft
        : isSix
            ? CkColors.ink
            : CkColors.surface;
    final fg = isSix
        ? CkColors.paper
        : isFour
            ? const Color(0xFF1F5828)
            : CkColors.ink;
    final label = isDot ? '•' : '$value';

    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      height: big ? 56 : 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: isSix
            ? null
            : Border.all(color: CkColors.hairline, width: 1),
        boxShadow: isSix
            ? const [
                BoxShadow(
                  color: Color(0x14281E0F),
                  blurRadius: 28,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: CkType.display(
          fontSize: big ? 24 : 22,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: -0.02,
        ),
      ),
    );

    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: box,
        ),
      ),
    );
  }
}

class _WicketButton extends StatelessWidget {
  const _WicketButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: CkColors.redSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              'W',
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CkColors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtraButton extends StatelessWidget {
  const _ExtraButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label.toUpperCase(),
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04,
              color: CkColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

class _LastBallCard extends StatelessWidget {
  const _LastBallCard({
    required this.last,
    required this.nameOf,
    required this.matchPlayers,
    required this.undoFlash,
    required this.canUndo,
    required this.onUndo,
  });
  final Ball? last;
  final String Function(String?) nameOf;
  final List<MatchPlayer> matchPlayers;
  final bool undoFlash;
  final bool canUndo;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final overLabel = last == null
        ? '—'
        : '${last!.overNumber}.${last!.ballInOver}';
    final desc = last == null
        ? 'No balls yet'
        : _shortDesc(last!);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: undoFlash ? CkColors.cream : CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          if (last != null)
            _BallChip(
              chip: _Chip(
                label: _labelFor(last!),
                kind: _kindFor(last!),
              ),
              size: 28,
            )
          else
            const SizedBox(width: 28, height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST BALL · $overLabel',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08,
                    color: CkColors.muted,
                  ),
                ),
                Text(
                  desc,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CkColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canUndo ? onUndo : null,
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: canUndo ? 1 : 0.4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CkColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.undo,
                          size: 12, color: CkColors.ink2),
                      const SizedBox(width: 5),
                      Text(
                        'Undo',
                        style: CkType.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink2,
                        ),
                      ),
                    ],
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

class _FreeHitBanner extends StatelessWidget {
  const _FreeHitBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _freeHitBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: CkColors.amber,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: CkColors.paper,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'FREE HIT',
                  style: CkType.mono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: CkColors.paper,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Next ball — only a run-out can dismiss.',
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _freeHitText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47141210),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        message,
        style: CkType.display(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: CkColors.paper,
        ),
      ),
    );
  }
}

class _BallLogRow extends StatelessWidget {
  const _BallLogRow({
    required this.ball,
    required this.highlighted,
    required this.description,
  });
  final Ball ball;
  final bool highlighted;
  final String description;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? CkColors.cream : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${ball.overNumber}.${ball.ballInOver}',
              style: CkType.mono(
                fontSize: 10,
                color: CkColors.muted,
              ),
            ),
          ),
          _BallChip(
            chip: _Chip(label: _labelFor(ball), kind: _kindFor(ball)),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(
                fontSize: 12,
                color: CkColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Ball chip — small colored ball pill
// =============================================================================

enum _ChipKind { dot, run, four, six, wkt, extra }

class _Chip {
  const _Chip({required this.label, required this.kind});
  final String label;
  final _ChipKind kind;
}

class _BallChip extends StatelessWidget {
  const _BallChip({required this.chip, required this.size});
  final _Chip chip;
  final double size;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    bool border = false;
    switch (chip.kind) {
      case _ChipKind.four:
        bg = CkColors.greenSoft;
        fg = const Color(0xFF1F5828);
        break;
      case _ChipKind.six:
        bg = CkColors.ink;
        fg = CkColors.paper;
        break;
      case _ChipKind.wkt:
        bg = CkColors.red;
        fg = Colors.white;
        break;
      case _ChipKind.extra:
        bg = CkColors.cream;
        fg = CkColors.ink2;
        break;
      case _ChipKind.dot:
        bg = CkColors.paper2;
        fg = CkColors.muted;
        border = true;
        break;
      case _ChipKind.run:
        bg = CkColors.paper2;
        fg = CkColors.ink;
        border = true;
        break;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border
            ? Border.all(color: CkColors.hairline, width: 1)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        chip.label,
        style: CkType.display(
          fontSize: size <= 22 ? 11 : 13,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: -0.02,
        ),
      ),
    );
  }
}

String _labelFor(Ball b) {
  if (b.isWicket) return 'W';
  if (b.ballKind == BallKind.wide) {
    return b.extras > 1 ? '${b.extras}wd' : 'wd';
  }
  if (b.ballKind == BallKind.noBall) {
    final t = 1 + b.runsScored;
    return t > 1 ? '${t}nb' : 'nb';
  }
  if (b.ballKind == BallKind.bye) return '${b.extras}b';
  if (b.ballKind == BallKind.legBye) return '${b.extras}lb';
  if (b.runsScored == 0) return '•';
  return '${b.runsScored}';
}

_ChipKind _kindFor(Ball b) {
  if (b.isWicket) return _ChipKind.wkt;
  if (b.ballKind == BallKind.wide ||
      b.ballKind == BallKind.noBall ||
      b.ballKind == BallKind.bye ||
      b.ballKind == BallKind.legBye) {
    return _ChipKind.extra;
  }
  if (b.runsScored == 4) return _ChipKind.four;
  if (b.runsScored == 6) return _ChipKind.six;
  if (b.runsScored == 0) return _ChipKind.dot;
  return _ChipKind.run;
}

String _chipLabelFor(Ball b) => _labelFor(b);
_ChipKind _chipKindFor(Ball b) => _kindFor(b);

String _shortDesc(Ball b) {
  if (b.isWicket) {
    return 'WICKET · ${b.wicketType?.wire ?? ''}';
  }
  switch (b.ballKind) {
    case BallKind.wide:
      return 'Wide${b.extras > 1 ? ' + ${b.extras - 1}' : ''}';
    case BallKind.noBall:
      return 'No-ball${b.runsScored > 0 ? ' · ${b.runsScored} off bat' : ''}';
    case BallKind.bye:
      return '${b.extras} bye${b.extras == 1 ? '' : 's'}';
    case BallKind.legBye:
      return '${b.extras} leg-bye${b.extras == 1 ? '' : 's'}';
    case BallKind.legal:
      if (b.runsScored == 0) return 'Dot ball';
      if (b.runsScored == 4) return 'Four!';
      if (b.runsScored == 6) return 'SIX!';
      return '${b.runsScored} run${b.runsScored == 1 ? '' : 's'}';
  }
}

// =============================================================================
// Sheets
// =============================================================================

class _SheetPerson {
  const _SheetPerson({
    required this.id,
    required this.name,
    this.role = '',
  });
  final String id; // match_player_id
  final String name;
  final String role;
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Color(0x38281E0F),
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            22 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2, bottom: 14),
                  decoration: BoxDecoration(
                    color: CkColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({
    required this.kicker,
    required this.title,
    this.subtitle,
    this.kickerColor,
  });
  final String kicker;
  final String title;
  final String? subtitle;
  final Color? kickerColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: kickerColor ?? CkColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: CkType.display(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitle!,
                style: CkType.body(
                  fontSize: 13,
                  color: CkColors.ink2,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: disabled
                ? CkColors.paper2
                : danger
                    ? CkColors.red
                    : CkColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: disabled ? CkColors.muted : CkColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.paper,
            border: Border.all(color: CkColors.hairline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
    this.tone = _ChoiceTone.ink,
  });
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final _ChoiceTone tone;
  @override
  Widget build(BuildContext context) {
    final accent =
        tone == _ChoiceTone.red ? CkColors.red : CkColors.ink;
    final activeBg =
        tone == _ChoiceTone.red ? CkColors.redSoft : CkColors.paper2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: active ? activeBg : CkColors.paper,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: active ? accent : CkColors.hairline,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: CkType.body(
                  fontSize: 11,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChoiceTone { ink, red }

class _RunChips extends StatelessWidget {
  const _RunChips({
    required this.value,
    required this.options,
    required this.onPick,
    this.accent = CkColors.ink,
  });
  final int value;
  final List<int> options;
  final ValueChanged<int> onPick;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: [
        for (final r in options)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onPick(r),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                decoration: BoxDecoration(
                  color: value == r ? accent : CkColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: value == r
                      ? null
                      : Border.all(color: CkColors.hairline),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$r',
                  style: CkType.display(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: value == r ? CkColors.paper : CkColors.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PersonGrid extends StatelessWidget {
  const _PersonGrid({
    required this.people,
    required this.value,
    required this.onPick,
  });
  final List<_SheetPerson> people;
  final String? value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 56,
      ),
      itemCount: people.length,
      itemBuilder: (_, i) {
        final p = people[i];
        final on = p.id == value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onPick(p.id),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: on ? CkColors.paper2 : CkColors.paper,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: on ? CkColors.ink : CkColors.hairline,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: on ? CkColors.ink : CkColors.paper2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _personInitials(p.name),
                      style: CkType.display(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: on ? CkColors.paper : CkColors.ink2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          p.role,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.mono(
                            fontSize: 8.5,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ),
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

String _personInitials(String name) {
  final words =
      name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return w.substring(0, w.length.clamp(0, 2)).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}

// ─── Extras sheet ─────────────────────────────────────────────────────────

class _ExtraResult {
  const _ExtraResult({
    required this.kind,
    required this.runs,
    required this.freeHit,
  });
  final BallKind kind;
  final int runs;
  final bool freeHit;
}

class _ExtrasSheet extends StatefulWidget {
  const _ExtrasSheet({required this.kind, required this.overs});
  final BallKind kind;
  final String overs;
  @override
  State<_ExtrasSheet> createState() => _ExtrasSheetState();
}

class _ExtrasSheetState extends State<_ExtrasSheet> {
  int _runs = 0;
  bool _freeHit = false;

  @override
  void initState() {
    super.initState();
    _runs = widget.kind == BallKind.noBall
        ? 0
        : widget.kind == BallKind.wide
            ? 0
            : 1;
    _freeHit = widget.kind == BallKind.noBall;
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final title = switch (kind) {
      BallKind.wide => 'Wide',
      BallKind.noBall => 'No-ball',
      BallKind.bye => 'Bye',
      BallKind.legBye => 'Leg-bye',
      BallKind.legal => 'Run',
    };
    final kicker = switch (kind) {
      BallKind.wide => 'WIDE BALL · ${widget.overs}',
      BallKind.noBall => 'NO-BALL · ${widget.overs}',
      BallKind.bye => 'BYE · ${widget.overs}',
      BallKind.legBye => 'LEG-BYE · ${widget.overs}',
      BallKind.legal => 'EXTRA · ${widget.overs}',
    };
    final sub = switch (kind) {
      BallKind.wide =>
        'One penalty run plus any runs taken. Re-bowled — striker keeps strike.',
      BallKind.noBall =>
        'One penalty plus runs off the bat. The next ball is a free hit.',
      BallKind.bye =>
        'Runs taken with no contact off the bat. Counts as a legal ball.',
      BallKind.legBye =>
        'Runs off the body, not the bat. Counts as a legal ball.',
      BallKind.legal => '',
    };
    final batRuns = kind == BallKind.noBall;
    final runLabel = batRuns
        ? 'RUNS OFF THE BAT'
        : kind == BallKind.wide
            ? 'EXTRA RUNS RUN'
            : 'RUNS TAKEN';
    final opts = switch (kind) {
      BallKind.wide => const [0, 1, 2, 4],
      BallKind.noBall => const [0, 1, 2, 4, 6],
      BallKind.bye || BallKind.legBye => const [1, 2, 3, 4],
      BallKind.legal => const [0, 1, 2, 3, 4, 6],
    };
    final penalty = (kind == BallKind.wide || kind == BallKind.noBall) ? 1 : 0;
    final total = penalty + _runs;

    return _Scrim(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHead(kicker: kicker, title: title, subtitle: sub),
            Text(
              runLabel,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 7),
            _RunChips(
              value: _runs,
              options: opts,
              onPick: (r) => setState(() => _runs = r),
            ),
            const SizedBox(height: 14),
            if (kind == BallKind.noBall)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _freeHit = !_freeHit),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _freeHit
                            ? CkColors.cream
                            : CkColors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _freeHit
                              ? _freeHitBorder
                              : CkColors.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: 40,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _freeHit
                                  ? CkColors.amber
                                  : CkColors.line,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  top: 2,
                                  left: _freeHit ? 18 : 2,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: CkColors.paper,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next ball is a free hit',
                                  style: CkType.display(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Only a run-out can dismiss on a free hit.',
                                  style: CkType.body(
                                    fontSize: 11,
                                    color: CkColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '${title.toUpperCase()}${_runs > 0 ? ' + $_runs' : ''}',
                    style: CkType.mono(
                      fontSize: 12,
                      letterSpacing: 0.06,
                      color: const Color(0xB3FDFAF4),
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '+$total ',
                          style: CkType.display(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: CkColors.paper,
                            letterSpacing: -0.03,
                          ),
                        ),
                        TextSpan(
                          text: total == 1 ? 'run' : 'runs',
                          style: CkType.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0x99FDFAF4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _PrimaryButton(
                    label: 'Add ${title.toLowerCase()}',
                    onTap: () => Navigator.of(context).pop(
                      _ExtraResult(
                        kind: kind,
                        runs: _runs,
                        freeHit: kind == BallKind.noBall ? _freeHit : false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wicket sheet (multi-stage) ──────────────────────────────────────────

class _WicketResult {
  const _WicketResult({
    required this.type,
    this.fielderMatchPlayerId,
    this.whoOutNonStriker = false,
    this.runsBefore = 0,
    this.nextBatterMatchPlayerId,
  });
  final WicketType type;
  final String? fielderMatchPlayerId;
  final bool whoOutNonStriker;
  final int runsBefore;
  final String? nextBatterMatchPlayerId;
}

enum _WicketStage { type, fielder, runout, batter }

class _WicketSheet extends StatefulWidget {
  const _WicketSheet({
    required this.overs,
    required this.totalRuns,
    required this.totalWickets,
    required this.strikerName,
    required this.nonStrikerName,
    required this.bowlerName,
    required this.fielders,
    required this.bench,
  });
  final String overs;
  final int totalRuns;
  final int totalWickets;
  final String strikerName;
  final String nonStrikerName;
  final String bowlerName;
  final List<_SheetPerson> fielders;
  final List<_SheetPerson> bench;
  @override
  State<_WicketSheet> createState() => _WicketSheetState();
}

class _WicketSheetState extends State<_WicketSheet> {
  _WicketStage _stage = _WicketStage.type;
  WicketType? _type;
  String? _fielderMpId;
  bool _whoOutNonStriker = false;
  int _runsBefore = 0;
  String? _nextBatterMpId;

  static const _types = [
    (WicketType.bowled, 'Bowled', 'Ball hits the stumps'),
    (WicketType.caught, 'Caught', 'Fielder takes the catch'),
    (WicketType.lbw, 'LBW', 'Leg before wicket'),
    (WicketType.runOut, 'Run out', 'Short of the crease'),
    (WicketType.stumped, 'Stumped', 'Keeper whips the bails'),
    (WicketType.hitWicket, 'Hit wkt', 'Disturbs own stumps'),
  ];

  bool get _needsFielder =>
      _type == WicketType.caught || _type == WicketType.stumped;
  bool get _isRunout => _type == WicketType.runOut;

  bool get _canProceed {
    switch (_stage) {
      case _WicketStage.type:
        return _type != null;
      case _WicketStage.fielder:
        return _fielderMpId != null;
      case _WicketStage.runout:
        return true;
      case _WicketStage.batter:
        return _nextBatterMpId != null || widget.bench.isEmpty;
    }
  }

  String get _ctaLabel {
    if (_stage == _WicketStage.batter) return 'Confirm wicket';
    if (_stage == _WicketStage.type) {
      if (_needsFielder) return 'Next · fielder';
      if (_isRunout) return 'Next · details';
    }
    return 'Next · batter';
  }

  void _next() {
    if (!_canProceed) return;
    if (_stage == _WicketStage.type) {
      if (_needsFielder) {
        setState(() => _stage = _WicketStage.fielder);
      } else if (_isRunout) {
        setState(() => _stage = _WicketStage.runout);
      } else {
        setState(() => _stage = _WicketStage.batter);
      }
      return;
    }
    if (_stage == _WicketStage.fielder ||
        _stage == _WicketStage.runout) {
      setState(() => _stage = _WicketStage.batter);
      return;
    }
    if (_stage == _WicketStage.batter) {
      Navigator.of(context).pop(
        _WicketResult(
          type: _type!,
          fielderMatchPlayerId: _fielderMpId,
          whoOutNonStriker: _isRunout && _whoOutNonStriker,
          runsBefore: _isRunout ? _runsBefore : 0,
          nextBatterMatchPlayerId: _nextBatterMpId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = [
      _WicketStage.type,
      if (_needsFielder) _WicketStage.fielder,
      if (_isRunout) _WicketStage.runout,
      _WicketStage.batter,
    ];
    final activeIdx = stages.indexOf(_stage);

    return _Scrim(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  for (var i = 0; i < stages.length; i++) ...[
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= activeIdx
                              ? CkColors.red
                              : CkColors.paper2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (i != stages.length - 1)
                      const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
            if (_stage == _WicketStage.type) ..._typeStage(),
            if (_stage == _WicketStage.fielder) ..._fielderStage(),
            if (_stage == _WicketStage.runout) ..._runoutStage(),
            if (_stage == _WicketStage.batter) ..._batterStage(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GhostButton(
                    label:
                        _stage == _WicketStage.type ? 'Cancel' : 'Back',
                    onTap: () {
                      if (_stage == _WicketStage.type) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _stage = _WicketStage.type);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _PrimaryButton(
                    label: _ctaLabel,
                    danger: true,
                    onTap: _canProceed ? _next : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _typeStage() => [
        _SheetHead(
          kicker:
              'WICKET · ${widget.overs} · ${widget.totalRuns}/${widget.totalWickets}',
          kickerColor: CkColors.red,
          title: 'How was the batter out?',
          subtitle:
              '${widget.strikerName} on strike · bowler ${widget.bowlerName}',
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.4,
          children: [
            for (final entry in _types)
              _ChoiceButton(
                title: entry.$2,
                subtitle: entry.$3,
                active: _type == entry.$1,
                onTap: () => setState(() => _type = entry.$1),
                tone: _ChoiceTone.red,
              ),
          ],
        ),
      ];

  List<Widget> _fielderStage() {
    final isStumped = _type == WicketType.stumped;
    return [
      _SheetHead(
        kicker: isStumped ? 'STUMPED BY' : 'CAUGHT BY',
        kickerColor: CkColors.red,
        title: isStumped ? 'Who stumped them?' : 'Who took the catch?',
        subtitle:
            '${widget.strikerName} · b ${widget.bowlerName}',
      ),
      _PersonGrid(
        people: widget.fielders,
        value: _fielderMpId,
        onPick: (id) => setState(() => _fielderMpId = id),
      ),
    ];
  }

  List<Widget> _runoutStage() {
    return [
      const _SheetHead(
        kicker: 'RUN OUT',
        kickerColor: CkColors.red,
        title: 'Run-out details',
        subtitle:
            'Which batter was out, and how many runs were completed first?',
      ),
      Text(
        'BATTER OUT',
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: _ChoiceButton(
              title: widget.strikerName,
              subtitle: 'STRIKER',
              active: !_whoOutNonStriker,
              onTap: () => setState(() => _whoOutNonStriker = false),
              tone: _ChoiceTone.red,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ChoiceButton(
              title: widget.nonStrikerName,
              subtitle: 'NON-STRIKER',
              active: _whoOutNonStriker,
              onTap: () => setState(() => _whoOutNonStriker = true),
              tone: _ChoiceTone.red,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'RUNS COMPLETED BEFORE',
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      _RunChips(
        value: _runsBefore,
        options: const [0, 1, 2, 3],
        accent: CkColors.red,
        onPick: (r) => setState(() => _runsBefore = r),
      ),
      const SizedBox(height: 16),
      Text(
        'THROWN / TAKEN BY · OPTIONAL',
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      _PersonGrid(
        people: widget.fielders,
        value: _fielderMpId,
        onPick: (id) => setState(() => _fielderMpId = id),
      ),
    ];
  }

  List<Widget> _batterStage() {
    return [
      _SheetHead(
        kicker: '${widget.totalWickets + 1} DOWN',
        kickerColor: CkColors.red,
        title: 'Who comes in?',
      ),
      if (widget.bench.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                "That's all out.",
                style: CkType.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No batters remain. The innings closes.',
                style: CkType.body(
                  fontSize: 12,
                  color: const Color(0xCCFDFAF4),
                ),
              ),
            ],
          ),
        )
      else
        _PersonGrid(
          people: widget.bench,
          value: _nextBatterMpId,
          onPick: (id) => setState(() => _nextBatterMpId = id),
        ),
    ];
  }
}

// ─── New bowler sheet ────────────────────────────────────────────────────

class _NewBowlerSheet extends StatefulWidget {
  const _NewBowlerSheet({
    required this.overNumber,
    required this.justBowled,
    required this.people,
    this.title = 'Next bowler?',
    this.kicker,
  });
  final int overNumber;
  final String? justBowled;
  final List<_SheetPerson> people;
  final String title;
  final String? kicker;
  @override
  State<_NewBowlerSheet> createState() => _NewBowlerSheetState();
}

class _NewBowlerSheetState extends State<_NewBowlerSheet> {
  String? _pick;
  @override
  Widget build(BuildContext context) {
    final kicker = widget.kicker ?? 'OVER ${widget.overNumber} COMPLETE';
    final sub = widget.justBowled == null
        ? 'Pick the player who will bowl the first over.'
        : '${widget.justBowled} can\'t bowl two overs in a row.';
    return _Scrim(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHead(
              kicker: kicker,
              title: widget.title,
              subtitle: sub,
            ),
            _PersonGrid(
              people: widget.people,
              value: _pick,
              onPick: (id) => setState(() => _pick = id),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _PrimaryButton(
                    label: 'Start over',
                    onTap: _pick == null
                        ? null
                        : () => Navigator.of(context).pop(_pick),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Top-level helpers
// =============================================================================

TeamId _battingTeamId(Match match, int inningsNumber) {
  final tossWon = match.tossWonBy;
  final tossDecision = match.tossDecision;
  if (tossWon != null && tossDecision != null) {
    final batsFirst = tossDecision == TossDecision.bat
        ? tossWon
        : (tossWon == match.teamAId ? match.teamBId : match.teamAId);
    return inningsNumber == 1
        ? batsFirst
        : (batsFirst == match.teamAId ? match.teamBId : match.teamAId);
  }
  return match.teamAId;
}

class _BatStats {
  const _BatStats(this.runs, this.balls, this.fours, this.sixes);
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
}

class _BowlerStats {
  const _BowlerStats({
    required this.overs,
    required this.ballsThisOver,
    required this.runs,
    required this.wickets,
  });
  final int overs;
  final int ballsThisOver;
  final int runs;
  final int wickets;
}

Map<String, _BatStats> _battersStats(List<Ball> balls) {
  final acc = <String, List<int>>{};
  for (final b in balls) {
    final id = b.batsmanId;
    if (id == null) continue;
    final cur = acc[id] ?? [0, 0, 0, 0];
    cur[0] += b.runsScored; // runs (off bat — exclude extras since bat doesn't score on extras except no-ball)
    if (b.isLegalDelivery && b.ballKind != BallKind.bye && b.ballKind != BallKind.legBye) {
      cur[1] += 1; // balls faced
    }
    if (b.runsScored == 4 && b.ballKind == BallKind.legal) cur[2] += 1;
    if (b.runsScored == 6 && b.ballKind == BallKind.legal) cur[3] += 1;
    acc[id] = cur;
  }
  return {
    for (final entry in acc.entries)
      entry.key: _BatStats(
        entry.value[0],
        entry.value[1],
        entry.value[2],
        entry.value[3],
      ),
  };
}

_BowlerStats _bowlerStatsFor(String? bowlerMpId, List<Ball> balls) {
  if (bowlerMpId == null) {
    return const _BowlerStats(
        overs: 0, ballsThisOver: 0, runs: 0, wickets: 0);
  }
  int legal = 0;
  int runs = 0;
  int wkts = 0;
  for (final b in balls) {
    if (b.bowlerId != bowlerMpId) continue;
    if (b.isLegalDelivery) legal += 1;
    runs += b.runsScored + b.extras;
    if (b.isWicket) wkts += 1;
  }
  return _BowlerStats(
    overs: legal ~/ 6,
    ballsThisOver: legal % 6,
    runs: runs,
    wickets: wkts,
  );
}

// Tiny helper for firstWhereOrNull without depending on collection package.
extension _FirstOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
