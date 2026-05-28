import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/start_innings.dart';
import '../../domain/usecases/undo_last_ball.dart';
import '../providers/matches_providers.dart';
import '../widgets/ball_pill.dart';

/// Live ball-by-ball scorer. Drives the deployed `record_ball` /
/// `undo_last_ball` / `start_innings` RPCs against the broadcast-backed
/// `match:<id>:balls` stream.
///
/// Implements the Scoring Cases v1 subset:
///   * Run pad: 0 / 1 / 2 / 3 / 4 / 6 / W
///   * Extras row: Wide / No-ball / Bye / Leg-bye  (inline run drawer)
///   * Case 01 wicket sheet (10 dismissal types)
///   * Case 10 new-batter sheet (after a wicket)
///   * Case 09 over-end bowler sheet
///   * Case 07 free-hit banner (derived from previous ball)
///   * Pick-opening-bowler sheet at ball 1 (no innings yet)
///   * Undo last ball
///
/// Deferred to v2: caught fielder picker, run-out details, boundary
/// confirm, innings-break takeover, match-end takeovers, rain pause,
/// edit-ball, co-scoring.
class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

enum _Drawer { none, wide, noBall, bye, legBye }

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  _Drawer _drawer = _Drawer.none;
  bool _busy = false;
  bool _bowlerPromptShown = false;

  @override
  Widget build(BuildContext context) {
    final liveMatchAsync = ref.watch(liveMatchProvider(widget.matchId));
    final match = liveMatchAsync.value;
    if (match == null) {
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator(color: CkColors.ink)),
      );
    }
    final inningsNumber = match.currentInnings ?? 1;
    final ballsAsync =
        ref.watch(liveBallsProvider(widget.matchId, inningsNumber));
    final balls = ballsAsync.value ?? const <Ball>[];

    // Need-a-bowler gate: innings is live, but no ball recorded yet and no
    // current_bowler_id on the match — Match Start handed off without one.
    final bowlerMissing = match.startPhase == MatchStartPhase.live &&
        match.currentBowlerId == null &&
        balls.isEmpty;
    if (bowlerMissing && !_bowlerPromptShown) {
      _bowlerPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptOpeningBowler(match);
      });
    }

    final rosterA = ref.watch(rosterProvider(match.teamAId.value)).value ??
        const <RosterMember>[];
    final rosterB = ref.watch(rosterProvider(match.teamBId.value)).value ??
        const <RosterMember>[];
    final names = {
      for (final m in rosterA) m.member.playerId: m.displayName,
      for (final m in rosterB) m.member.playerId: m.displayName,
    };
    String nameOf(String? id) => id == null ? '—' : (names[id] ?? 'Player');

    final totals = _aggregate(balls);
    final lastBall = balls.isEmpty ? null : balls.last;
    final freeHit =
        lastBall != null && lastBall.ballKind == BallKind.noBall;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(match, inningsNumber, totals),
            if (freeHit) const _FreeHitBanner(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _scoreboard(match, totals),
                  const SizedBox(height: 10),
                  _players(match, balls, nameOf),
                  const SizedBox(height: 10),
                  _lastBallBanner(lastBall, nameOf),
                  if (_drawer != _Drawer.none) _extraDrawer(match),
                  _runPad(match, balls),
                  _extrasRow(),
                  _ballLog(balls, nameOf),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptOpeningBowler(Match match) async {
    final bowlingTeamId = _battingTeamId(match) == match.teamAId
        ? match.teamBId
        : match.teamAId;
    final roster = ref.read(rosterProvider(bowlingTeamId.value)).value ??
        const <RosterMember>[];
    final squad =
        bowlingTeamId == match.teamAId ? match.teamASquad : match.teamBSquad;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BowlerSheet(
        title: 'Pick opening bowler',
        roster: roster,
        squad: squad,
      ),
    );
    if (picked == null || !mounted) {
      _bowlerPromptShown = false;
      return;
    }
    await _onPickOpeningBowler(match, match.currentInnings ?? 1, picked);
  }

  // ─── Top bar + scoreboard ────────────────────────────────────────────────

  Widget _topBar(Match match, int inningsNumber, _Totals totals) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.close_rounded, color: CkColors.ink),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: CkColors.redSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('SCORING',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.red,
                )),
          ),
          const SizedBox(width: 8),
          Text(
            'INNINGS $inningsNumber · T${match.format.oversPerInnings}',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreboard(Match match, _Totals totals) {
    final overs = totals.legalBalls ~/ 6;
    final rem = totals.legalBalls % 6;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${totals.totalRuns}',
            style: CkType.display(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.025,
              color: CkColors.paper,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(
              '/${totals.wickets}',
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0x8CFDFAF4),
              ),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'OVERS',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: const Color(0xB3FDFAF4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$overs.$rem',
                style: CkType.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
              Text(
                '/${match.format.oversPerInnings}',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: const Color(0x80FDFAF4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _players(Match match, List<Ball> balls, String Function(String?) nameOf) {
    final batStats = _battersStats(balls);
    final striker = match.currentStrikerId;
    final nonStriker = match.currentNonStrikerId;
    final bowler = match.currentBowlerId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BatterCard(
                  name: nameOf(striker),
                  runs: batStats[striker]?.runs ?? 0,
                  balls: batStats[striker]?.balls ?? 0,
                  fours: batStats[striker]?.fours ?? 0,
                  sixes: batStats[striker]?.sixes ?? 0,
                  onStrike: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BatterCard(
                  name: nameOf(nonStriker),
                  runs: batStats[nonStriker]?.runs ?? 0,
                  balls: batStats[nonStriker]?.balls ?? 0,
                  fours: batStats[nonStriker]?.fours ?? 0,
                  sixes: batStats[nonStriker]?.sixes ?? 0,
                  onStrike: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BowlerCard(
            name: nameOf(bowler),
            overStrip: _thisOverStrip(balls),
          ),
        ],
      ),
    );
  }

  Widget _thisOverStrip(List<Ball> balls) {
    if (balls.isEmpty) return const SizedBox.shrink();
    final last = balls.last;
    final thisOver =
        balls.where((b) => b.overNumber == last.overNumber).toList();
    final slots = List.generate(6, (i) {
      if (i < thisOver.length) {
        return BallPill.fromBall(thisOver[i], size: 22);
      }
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CkColors.line, width: 1.5),
        ),
      );
    });
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          slots[i],
        ],
      ],
    );
  }

  Widget _lastBallBanner(Ball? last, String Function(String?) nameOf) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (last == null)
            const SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: Text('•',
                    style:
                        TextStyle(fontSize: 22, color: CkColors.muted)),
              ),
            )
          else
            BallPill.fromBall(last, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  last == null
                      ? 'NO BALLS YET'
                      : 'LAST · ${last.overNumber}.${last.ballInOver}',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.muted,
                  ),
                ),
                if (last != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _describe(last, nameOf),
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                          fontSize: 12, color: CkColors.ink2),
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: (last == null || _busy)
                ? null
                : () => _onUndo(last.matchId, last.inningsNumber),
            icon: const Icon(Icons.undo, size: 14),
            label: const Text('Undo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: CkColors.hairline),
              foregroundColor: CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _runPad(Match match, List<Ball> balls) {
    final canTap = !_busy && _drawer == _Drawer.none;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              for (final r in const [0, 1, 2, 3]) ...[
                Expanded(
                  child: _PadButton(
                    label: r == 0 ? '•' : '$r',
                    onTap: canTap ? () => _onRun(match, balls, r) : null,
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
                child: _PadButton(
                  label: '4',
                  big: true,
                  bg: CkColors.greenSoft,
                  fg: CkColors.green,
                  onTap: canTap ? () => _onRun(match, balls, 4) : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _PadButton(
                  label: '6',
                  big: true,
                  bg: CkColors.ink,
                  fg: CkColors.paper,
                  onTap: canTap ? () => _onRun(match, balls, 6) : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _PadButton(
                  label: 'W',
                  big: true,
                  bg: CkColors.redSoft,
                  fg: CkColors.red,
                  onTap: canTap ? () => _onWicket(match, balls) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _extrasRow() {
    final canTap = !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          _extraPill('Wide', _Drawer.wide, canTap),
          const SizedBox(width: 6),
          _extraPill('No-ball', _Drawer.noBall, canTap),
          const SizedBox(width: 6),
          _extraPill('Bye', _Drawer.bye, canTap),
          const SizedBox(width: 6),
          _extraPill('Leg-bye', _Drawer.legBye, canTap),
        ],
      ),
    );
  }

  Widget _extraPill(String label, _Drawer drawer, bool canTap) {
    final on = _drawer == drawer;
    return Expanded(
      child: InkWell(
        onTap: !canTap
            ? null
            : () => setState(() => _drawer = on ? _Drawer.none : drawer),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? CkColors.ink : CkColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label.toUpperCase(),
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04,
              color: on ? CkColors.paper : CkColors.ink2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _extraDrawer(Match match) {
    final kind = switch (_drawer) {
      _Drawer.wide => BallKind.wide,
      _Drawer.noBall => BallKind.noBall,
      _Drawer.bye => BallKind.bye,
      _Drawer.legBye => BallKind.legBye,
      _Drawer.none => BallKind.legal,
    };
    final label = switch (_drawer) {
      _Drawer.wide => 'Wide',
      _Drawer.noBall => 'No-ball',
      _Drawer.bye => 'Bye',
      _Drawer.legBye => 'Leg-bye',
      _Drawer.none => '',
    };
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$label +'.toUpperCase(),
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.paper,
            ),
          ),
          const Spacer(),
          for (final n in const [1, 2, 3, 4, 5]) ...[
            _ExtraRunButton(
              label: '$n',
              onTap: _busy ? null : () => _onExtra(match, kind, n),
            ),
            if (n != 5) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _ballLog(List<Ball> balls, String Function(String?) nameOf) {
    if (balls.isEmpty) return const SizedBox.shrink();
    final reversed = balls.reversed.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text('BALL LOG',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.muted,
                    )),
                const Spacer(),
                Text('${balls.length} balls',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                      color: CkColors.muted,
                    )),
              ],
            ),
          ),
          for (var i = 0; i < reversed.length && i < 30; i++)
            _LogRow(b: reversed[i], desc: _describe(reversed[i], nameOf)),
        ],
      ),
    );
  }

  // ─── Action handlers ─────────────────────────────────────────────────────

  Future<void> _onRun(Match match, List<Ball> balls, int runs) async {
    await _submit(BallDraft(
      matchId: match.id,
      inningsNumber: match.currentInnings ?? 1,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runs,
      batsmanId: match.currentStrikerId,
      nonStrikerId: match.currentNonStrikerId,
      bowlerId: match.currentBowlerId,
    ));
  }

  Future<void> _onExtra(Match match, BallKind kind, int n) async {
    // Wide/No-ball: 1 penalty + (n-1) batter runs encoded as runs_scored.
    // Bye/Leg-bye: n runs all in extras, runs_scored stays 0.
    final isWideOrNb = kind == BallKind.wide || kind == BallKind.noBall;
    final runsScored = isWideOrNb ? (n - 1) : 0;
    final extras = isWideOrNb ? 1 : n;
    setState(() => _drawer = _Drawer.none);
    await _submit(BallDraft(
      matchId: match.id,
      inningsNumber: match.currentInnings ?? 1,
      isLegalDelivery: !isWideOrNb,
      ballKind: kind,
      runsScored: runsScored,
      extras: extras,
      batsmanId: match.currentStrikerId,
      nonStrikerId: match.currentNonStrikerId,
      bowlerId: match.currentBowlerId,
    ));
  }

  Future<void> _onWicket(Match match, List<Ball> balls) async {
    final picked = await showModalBottomSheet<WicketType>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _WicketTypeSheet(),
    );
    if (picked == null || !mounted) return;

    // New batter picker for everything except retired hurt (where the
    // dismissed player isn't replaced immediately).
    String? newBatterId;
    if (picked != WicketType.retiredHurt) {
      final battingTeamId = _battingTeamId(match);
      final battingRoster =
          ref.read(rosterProvider(battingTeamId.value)).value ??
              const <RosterMember>[];
      final usedIds = balls.map((b) => b.batsmanId).whereType<String>().toSet()
        ..add(match.currentStrikerId ?? '')
        ..add(match.currentNonStrikerId ?? '');
      newBatterId = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: CkColors.paper,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _NewBatterSheet(
          roster: battingRoster,
          squad: battingTeamId == match.teamAId
              ? match.teamASquad
              : match.teamBSquad,
          usedIds: usedIds,
        ),
      );
      if (newBatterId == null || !mounted) return;
    }

    await _submit(BallDraft(
      matchId: match.id,
      inningsNumber: match.currentInnings ?? 1,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      isWicket: true,
      wicketType: picked,
      batsmanId: match.currentStrikerId,
      nonStrikerId: match.currentNonStrikerId,
      bowlerId: match.currentBowlerId,
    ));

    // After recording, set the new batter as striker. The RPC doesn't take
    // it, so we patch the match row directly.
    if (newBatterId != null) {
      await ref.read(startInningsUseCaseProvider).call(StartInningsParams(
            matchId: match.id,
            inningsNumber: match.currentInnings ?? 1,
            strikerId: newBatterId,
            nonStrikerId: match.currentNonStrikerId ?? '',
            bowlerId: match.currentBowlerId ?? '',
          ));
    }
  }

  Future<void> _submit(BallDraft draft) async {
    setState(() => _busy = true);
    final result = await ref.read(recordBallUseCaseProvider).call(draft);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );

    // End-of-over → prompt for next bowler. legalBallsThisOver mod 6 == 0
    // and at least one legal ball delivered.
    final updatedBalls =
        ref.read(liveBallsProvider(draft.matchId.value, draft.inningsNumber)).value ??
            const <Ball>[];
    final lastOver = updatedBalls.isEmpty
        ? 0
        : updatedBalls.last.overNumber;
    final overLegal = updatedBalls
        .where((b) => b.overNumber == lastOver && b.isLegalDelivery)
        .length;
    if (overLegal == 6 && mounted) {
      // ignore: use_build_context_synchronously
      await _promptEndOfOverBowler();
    }
  }

  Future<void> _promptEndOfOverBowler() async {
    final match = ref.read(liveMatchProvider(widget.matchId)).value;
    if (match == null) return;
    final bowlingTeamId = _battingTeamId(match) == match.teamAId
        ? match.teamBId
        : match.teamAId;
    final roster = ref.read(rosterProvider(bowlingTeamId.value)).value ??
        const <RosterMember>[];
    final squad =
        bowlingTeamId == match.teamAId ? match.teamASquad : match.teamBSquad;
    final newBowlerId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BowlerSheet(
        title: 'Pick next bowler',
        roster: roster,
        squad: squad,
        excludeId: match.currentBowlerId,
      ),
    );
    if (newBowlerId == null || !mounted) return;
    await ref.read(startInningsUseCaseProvider).call(StartInningsParams(
          matchId: match.id,
          inningsNumber: match.currentInnings ?? 1,
          // Strike rotates at end of over: previous non-striker is on strike.
          strikerId: match.currentNonStrikerId ?? '',
          nonStrikerId: match.currentStrikerId ?? '',
          bowlerId: newBowlerId,
        ));
  }

  Future<void> _onPickOpeningBowler(
    Match match,
    int inningsNumber,
    String bowlerId,
  ) async {
    setState(() => _busy = true);
    final result = await ref.read(startInningsUseCaseProvider).call(
          StartInningsParams(
            matchId: match.id,
            inningsNumber: inningsNumber,
            strikerId: match.currentStrikerId ?? '',
            nonStrikerId: match.currentNonStrikerId ?? '',
            bowlerId: bowlerId,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );
  }

  Future<void> _onUndo(MatchId matchId, int inningsNumber) async {
    setState(() => _busy = true);
    final result = await ref.read(undoLastBallUseCaseProvider).call(
          UndoLastBallParams(matchId: matchId, inningsNumber: inningsNumber),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

TeamId _battingTeamId(Match match) {
  // Innings 1: toss decision drives it.
  final tossWon = match.tossWonBy;
  final tossDecision = match.tossDecision;
  if (tossWon != null && tossDecision != null) {
    final inn = match.currentInnings ?? 1;
    final batsFirst = tossDecision == TossDecision.bat
        ? tossWon
        : (tossWon == match.teamAId ? match.teamBId : match.teamAId);
    return inn == 1
        ? batsFirst
        : (batsFirst == match.teamAId ? match.teamBId : match.teamAId);
  }
  return match.teamAId;
}

class _Totals {
  const _Totals(this.totalRuns, this.wickets, this.legalBalls);
  final int totalRuns;
  final int wickets;
  final int legalBalls;
}

_Totals _aggregate(List<Ball> balls) {
  var runs = 0;
  var wkts = 0;
  var legal = 0;
  for (final b in balls) {
    runs += b.runsScored + b.extras;
    if (b.isWicket) wkts++;
    if (b.isLegalDelivery) legal++;
  }
  return _Totals(runs, wkts, legal);
}

class _BatStats {
  _BatStats();
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
}

Map<String?, _BatStats> _battersStats(List<Ball> balls) {
  final m = <String?, _BatStats>{};
  for (final b in balls) {
    final s = m.putIfAbsent(b.batsmanId, () => _BatStats());
    if (b.ballKind == BallKind.legal) {
      s.runs += b.runsScored;
      s.balls += 1;
      if (b.isFour) s.fours++;
      if (b.isSix) s.sixes++;
    } else if (b.ballKind == BallKind.noBall) {
      s.runs += b.runsScored; // no-ball bat runs go to the striker
    }
  }
  return m;
}

String _describe(Ball b, String Function(String?) nameOf) {
  if (b.isWicket) {
    return 'WICKET · ${b.wicketType?.label ?? ''} · ${nameOf(b.batsmanId)}';
  }
  switch (b.ballKind) {
    case BallKind.wide:
      return 'Wide${b.extras > 1 ? ' +${b.extras - 1}' : ''}';
    case BallKind.noBall:
      final off = b.runsScored == 0 ? '' : ' · ${b.runsScored} off bat';
      return 'No-ball$off';
    case BallKind.bye:
      return 'Byes ${b.extras}';
    case BallKind.legBye:
      return 'Leg-byes ${b.extras}';
    case BallKind.legal:
      if (b.runsScored == 0) return 'Dot';
      if (b.isFour) return 'Four';
      if (b.isSix) return 'Six';
      return '${b.runsScored} run${b.runsScored == 1 ? '' : 's'}';
  }
}

// ─── Inline widgets ─────────────────────────────────────────────────────────

class _BatterCard extends StatelessWidget {
  const _BatterCard({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.onStrike,
  });
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool onStrike;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: onStrike ? CkColors.surface : CkColors.paper2,
        border: Border.all(
          color: onStrike ? CkColors.ink : CkColors.hairline,
          width: onStrike ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: CkType.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onStrike)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: CkColors.redSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('•STRIKE',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.red,
                    )),
              ),
          ]),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$runs',
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(width: 4),
              Text('($balls)',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: CkColors.muted,
                  )),
              const Spacer(),
              if (fours > 0 || sixes > 0)
                Text(
                  '$fours×4 $sixes×6',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: CkColors.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BowlerCard extends StatelessWidget {
  const _BowlerCard({required this.name, required this.overStrip});
  final String name;
  final Widget overStrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _initials(name),
              style: CkType.display(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CkColors.paper,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          overStrip,
        ],
      ),
    );
  }

  String _initials(String name) {
    final words =
        name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '??';
    if (words.length == 1) return words.first.substring(0, 2).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.label,
    this.onTap,
    this.bg,
    this.fg,
    this.big = false,
  });
  final String label;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? fg;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: big ? 56 : 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg ?? CkColors.surface,
          border: bg == null
              ? Border.all(color: CkColors.hairline, width: 1)
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: CkType.display(
            fontSize: big ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: fg ?? CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _ExtraRunButton extends StatelessWidget {
  const _ExtraRunButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x1AFDFAF4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: CkType.display(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CkColors.paper,
            )),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.b, required this.desc});
  final Ball b;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${b.overNumber}.${b.ballInOver}',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
                color: CkColors.muted,
              ),
            ),
          ),
          BallPill.fromBall(b, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              desc,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 12, color: CkColors.ink2),
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
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CkColors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CkColors.ink,
              shape: BoxShape.circle,
            ),
            child: Text('FH',
                style: CkType.display(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: CkColors.paper,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Free hit · next ball',
                style: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                  color: CkColors.ink,
                )),
          ),
        ],
      ),
    );
  }
}

class _WicketTypeSheet extends StatefulWidget {
  const _WicketTypeSheet();

  @override
  State<_WicketTypeSheet> createState() => _WicketTypeSheetState();
}

class _WicketTypeSheetState extends State<_WicketTypeSheet> {
  WicketType? _picked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('WICKET',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.red,
                  )),
              const SizedBox(height: 4),
              Text(
                'How was the batter out?',
                style: CkType.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in WicketType.values)
                    _WicketChip(
                      type: w,
                      selected: _picked == w,
                      onTap: () => setState(() => _picked = w),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              CkButton(
                label: 'Confirm wicket',
                onPressed: _picked == null
                    ? null
                    : () => Navigator.of(context).pop(_picked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WicketChip extends StatelessWidget {
  const _WicketChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });
  final WicketType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CkColors.redSoft : CkColors.paper2,
          border: Border.all(
              color: selected ? CkColors.red : CkColors.hairline, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(type.label,
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? CkColors.red : CkColors.ink,
            )),
      ),
    );
  }
}

class _NewBatterSheet extends StatelessWidget {
  const _NewBatterSheet({
    required this.roster,
    required this.squad,
    required this.usedIds,
  });
  final List<RosterMember> roster;
  final List<String> squad;
  final Set<String> usedIds;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final r in roster) r.member.playerId: r};
    final eligible =
        squad.where((id) => !usedIds.contains(id)).map((id) => byId[id]).whereType<RosterMember>().toList();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: CkColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('NEXT BATTER',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                )),
            const SizedBox(height: 4),
            Text(
              eligible.isEmpty ? 'No batters left.' : 'Send who in?',
              style: CkType.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
              ),
            ),
            const SizedBox(height: 12),
            for (final p in eligible)
              InkWell(
                onTap: () => Navigator.of(context).pop(p.member.playerId),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: CkColors.hairline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.displayName,
                          style: CkType.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (p.member.jerseyNumber != null)
                        Text('#${p.member.jerseyNumber}',
                            style: CkType.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.06,
                              color: CkColors.muted,
                            )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BowlerSheet extends StatelessWidget {
  const _BowlerSheet({
    required this.title,
    required this.roster,
    required this.squad,
    this.excludeId,
  });
  final String title;
  final List<RosterMember> roster;
  final List<String> squad;
  final String? excludeId;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final r in roster) r.member.playerId: r};
    final eligible =
        squad.where((id) => id != excludeId).map((id) => byId[id]).whereType<RosterMember>().toList();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: CkColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: CkType.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                )),
            const SizedBox(height: 12),
            for (final p in eligible)
              InkWell(
                onTap: () => Navigator.of(context).pop(p.member.playerId),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: CkColors.hairline)),
                  ),
                  child: Text(
                    p.displayName,
                    style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

