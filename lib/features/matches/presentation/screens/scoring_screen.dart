import 'dart:async';

import 'package:fpdart/fpdart.dart' hide State;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../controllers/scoring_controller.dart';
import '../providers/matches_providers.dart';
import '../state/scoring_state.dart';
import '../widgets/scoring/ball_chip.dart';
import '../widgets/scoring/scoring_board.dart';
import '../widgets/scoring/scoring_controls.dart';
import '../widgets/scoring/scoring_notices.dart';
import '../widgets/scoring/extras_sheet.dart';
import '../widgets/scoring/wicket_sheet.dart';
import '../widgets/scoring/new_bowler_sheet.dart';
import '../widgets/scoring/sheet_kit.dart';
import '../widgets/scoring/scoring_top_bar.dart';

// =============================================================================
// ScoringScreen — live ball-by-ball scorer.
// =============================================================================
// THE RULE FOR THIS SCREEN
//
//   The screen composes and dispatches. Everything that renders lives in
//   widgets/scoring/. Everything that decides lives in ScoringController or
//   ScoringState.
//
// So this file contains exactly three things: the AsyncValue switch, the
// widget tree that arranges the pieces, and the handlers that turn a tap into
// a controller call. No cricket rules, no roster joins, no repository access,
// no layout beyond ordering.
//
// It is stated here because it was not obvious before: this file once held
// 3,300 lines of all of the above, and a wide-attribution bug that corrupted
// scorecards survived inside it precisely because nothing in a widget method
// can be unit-tested.
//
// WHERE THINGS LIVE
//
//   state/scoring_state.dart          derived state + the cricket rules
//   controllers/scoring_controller.dart  the six writes
//   widgets/scoring/scoring_board.dart      the read-out (score, batters, log)
//   widgets/scoring/scoring_controls.dart   the input surface (run pad, extras)
//   widgets/scoring/scoring_notices.dart    empty / blocked / transient states
//   widgets/scoring/scoring_top_bar.dart    header + overflow menu
//   widgets/scoring/*_sheet.dart            the three modals
//   widgets/scoring/sheet_kit.dart          chrome shared by those modals
//   widgets/scoring/ball_chip.dart          one delivery, as a pill
//
// Match Start is a separate route. The need-a-bowler prompt at ball 1 fires
// here, not there.
// =============================================================================

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
  bool _bowlerPromptShown = false;
  bool _undoFlash = false;
  bool _inningsEndRouted = false;
  String? _toast;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  // ─── id translation helpers ─────────────────────────────────────────────

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

  /// Where to go once the innings ends. Trusts the match status when the
  /// transition has already propagated; otherwise derives it from the innings
  /// count (the last innings ends the match → result, else → innings break).
  String _postInningsRoute(Match match) {
    switch (match.status) {
      case MatchStatus.completed:
      case MatchStatus.abandoned:
      case MatchStatus.walkover:
        return '/matches/${widget.matchId}/result';
      case MatchStatus.inningsBreak:
        return '/matches/${widget.matchId}/innings-break';
      default:
        final perSide =
            match.format.inningsPerSide <= 0 ? 1 : match.format.inningsPerSide;
        final isFinalInnings = widget.inningsNumber >= perSide * 2;
        return isFinalInnings
            ? '/matches/${widget.matchId}/result'
            : '/matches/${widget.matchId}/innings-break';
    }
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

    // Everything below comes from ScoringController. The derivations that
    // used to live here — the on-field trio, batter/bowler stats, free hit,
    // innings-over — are now pure getters on ScoringState, where they can be
    // unit-tested. This method only lays them out.
    final async = ref.watch(
      scoringControllerProvider(widget.matchId, widget.inningsNumber),
    );

    final ScoringState s;
    switch (async) {
      case AsyncError(:final error):
        return ScoringLoadFailure(
          message: failureMessageOf(error),
          onRetry: () => ref.invalidate(
            scoringControllerProvider(widget.matchId, widget.inningsNumber),
          ),
        );
      case AsyncData(:final value):
        s = value;
      default:
        return const ScoringLoading();
    }

    final match = s.match;
    final matchPlayers = s.matchPlayers;
    final balls = s.balls;
    final canScore = s.canScore;
    final bowlerSet = s.bowlerSet;
    final inningsOver = s.inningsOver;
    final freeHitActive = s.freeHitActive;
    final nameOf = s.nameOf;

    // Team name for the read-only notice.
    final battingTeam = ref
        .watch(teamProvider(s.battingTeamId.value))
        .value;

    // Need-a-bowler gate: only the scoring side is prompted, and only once the
    // lineup has arrived (a name-less picker is worse than none). The lineup
    // now carries its own names, so there is no second source to wait on.
    final dataReady = matchPlayers.isNotEmpty;
    if (canScore &&
        match.startPhase == MatchStartPhase.live &&
        s.needsOpeningBowler &&
        dataReady &&
        !_bowlerPromptShown) {
      _bowlerPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptBowler(s, opening: true);
      });
    }

    if (inningsOver && !_inningsEndRouted) {
      _inningsEndRouted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(_postInningsRoute(match));
      });
    }

    // Leaving mid-innings is almost always a mis-swipe: an Android back
    // gesture or an iOS edge-swipe on a phone being held one-handed at a
    // ground. Nothing else in the app guards a route, but nothing else in the
    // app is a live ledger someone is mid-way through writing.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave(s)) _leave();
      },
      child: Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Three bands, not one scroll view. The score is pinned at the
            // top and the run pad at the bottom because both used to scroll
            // away: once the ball log grew past a few overs, a scorer who
            // glanced at the log lost the score AND the pad, and had to
            // scroll back before the next delivery. Only the middle — who is
            // in, the last ball, the log — moves.
            Column(
              children: [
                ScoringTopBar(
                  matchType: match.matchType,
                  onClose: () => _handleClose(s),
                  menuActions: [
                    ScoringMenuAction.viewScorecard,
                    if (canScore && bowlerSet) ScoringMenuAction.changeBowler,
                  ],
                  onMenuAction: _handleMenuAction,
                ),
                Scoreboard(state: s),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        BattersAndBowler(state: s),
                        if (freeHitActive) const FreeHitBanner(),
                        LastBallCard(
                          last: s.lastBall,
                          nameOf: nameOf,
                          matchPlayers: matchPlayers,
                          undoFlash: _undoFlash,
                          // Undo still waits: there is nothing to undo until
                          // the delivery has actually reached the server.
                          canUndo: canScore && balls.isNotEmpty && !s.hasPending,
                          onUndo: _handleUndo,
                          busy: s.hasPending,
                        ),
                        BallLog(
                          balls: balls,
                          nameOf: nameOf,
                          matchPlayers: matchPlayers,
                        ),
                      ],
                    ),
                  ),
                ),
                // The control surface. Padded for the gesture bar because the
                // Scaffold's SafeArea deliberately does not cover the bottom.
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canScore) ...[
                        if (inningsOver)
                          const InningsCompleteNotice()
                        else if (bowlerSet) ...[
                          // Not gated on isBusy any more: the delivery is
                          // computed locally and painted before the write
                          // leaves, so the scorer keeps scoring while the
                          // previous ball is still in flight.
                          RunPad(
                            busy: false,
                            onRun: _handleRun,
                            onWicket: () => _openWicketSheet(s),
                          ),
                          ExtrasRow(
                            onExtra: (kind) => _openExtrasSheet(s, kind),
                          ),
                        ] else
                          SelectBowlerNotice(
                            isOpening: balls.isEmpty,
                            onSelect: () =>
                                _promptBowler(s, opening: balls.isEmpty),
                          ),
                      ] else
                        ReadOnlyScoringNotice(
                          battingTeamName: battingTeam?.name,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_toast != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
                child: Center(child: ScoringToast(message: _toast!)),
              ),
          ],
        ),
      ),
      ),
    );
  }

  // ─── action handlers ────────────────────────────────────────────────────

  ScoringController get _controller => ref.read(
        scoringControllerProvider(widget.matchId, widget.inningsNumber)
            .notifier,
      );

  /// Runs a delivery-recording action, then offers the next-bowler prompt if
  /// that ball completed an over. Undo deliberately does not go through here.
  Future<bool> _recordDelivery(
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    final ok = await _dispatch(action);
    if (ok && mounted) await _maybePromptNextBowler();
    return ok;
  }

  /// Standard run (0/1/2/3/4/6).
  Future<void> _handleRun(int runs) =>
      _recordDelivery(() => _controller.recordRun(runs));

  /// Extras committed from the bottom sheet. How the runs split between the
  /// batter and the extras column is the controller's rule, not this widget's.
  Future<void> _handleExtraCommit(ExtraResult result) async {
    await _recordDelivery(
      () => _controller.recordExtra(kind: result.kind, runs: result.runs),
    );
    if (result.freeHit && mounted) _flashToast('Free hit — next ball');
  }

  Future<void> _handleWicketCommit(WicketResult r) async {
    final wickets = ref
            .read(scoringControllerProvider(widget.matchId, widget.inningsNumber))
            .value
            ?.totalWickets ??
        0;

    final recorded = await _recordDelivery(
      () => _controller.recordWicket(
        type: r.type,
        runsBefore: r.runsBefore,
        fielderMatchPlayerId: r.fielderMatchPlayerId,
      ),
    );
    if (!recorded || !mounted) return;

    _flashToast('${wickets + 1} down');

    // All out ends the innings — the screen routes on, so no batter is owed.
    final after = ref
        .read(scoringControllerProvider(widget.matchId, widget.inningsNumber))
        .value;
    if (after == null || after.inningsOver) return;

    if (r.nextBatterMatchPlayerId != null) {
      await _dispatch(
        () => _controller.bringInBatter(r.nextBatterMatchPlayerId!),
      );
    }
  }

  Future<void> _handleUndo() async {
    // Undo deletes a delivery from the ledger and rewinds the score. It is the
    // most destructive control on the screen and sits one tap from the run
    // pad, on a phone held at a cricket ground — so it confirms, naming the
    // ball being removed so a mis-tap is obvious before it lands.
    final last = ref
        .read(scoringControllerProvider(widget.matchId, widget.inningsNumber))
        .value
        ?.lastBall;
    if (last == null) return;
    if (!await _confirmUndo(last)) return;
    if (!mounted) return;

    if (await _dispatch(_controller.undoLastBall)) _flashUndo();
  }

  /// Runs a controller action, surfacing any failure as a snackbar. Returns
  /// true when it succeeded.
  Future<bool> _dispatch(Future<Either<Failure, Unit>> Function() action) async {
    final result = await action();
    if (!mounted) return result.isRight();
    return result.fold(
      (f) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message)));
        return false;
      },
      (_) => true,
    );
  }

  /// After a completed over the server clears the bowler, so one is owed
  /// before the next delivery.
  Future<void> _maybePromptNextBowler() async {
    final s = ref
        .read(scoringControllerProvider(widget.matchId, widget.inningsNumber))
        .value;
    if (s == null || s.inningsOver || s.bowlerSet || s.balls.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) await _promptBowler(s, opening: false);
  }

  /// Confirms removal of [last]. Returns false if the user backs out.
  Future<bool> _confirmUndo(Ball last) async {
    final over = '${last.overNumber}.${last.ballInOver}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CkColors.paper,
        title: Text('Undo this ball?', style: CkType.display(fontSize: 18)),
        content: Text(
          'Removes $over — ${describeBall(last)} — from the scorecard and '
          'rewinds the score. This cannot be redone.',
          style: CkType.body(fontSize: 13, height: 1.45, color: CkColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Keep it',
                style: CkType.body(fontSize: 14, color: CkColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Undo ball',
              style: CkType.body(
                fontSize: 14,
                color: CkColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // ─── leaving / overflow ─────────────────────────────────────────────────

  /// Close tapped. Confirms first when an innings is in progress.
  Future<void> _handleClose(ScoringState s) async {
    if (await _confirmLeave(s)) _leave();
  }

  /// Pops back where the user came from, falling back to home only when this
  /// route was opened cold (a deep link or a push tap) and there is nothing to
  /// pop. The old close button always went to `/home`, which threw away the
  /// match-start stack a scorer had just walked through.
  void _leave() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// True when it is safe to leave. Silent once the innings is over or the
  /// viewer is a spectator — there is nothing in progress to lose.
  Future<bool> _confirmLeave(ScoringState s) async {
    final scoringInProgress = s.canScore && !s.inningsOver;
    if (!scoringInProgress) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CkColors.paper,
        title: Text('Stop scoring?', style: CkType.display(fontSize: 18)),
        content: Text(
          'The innings is still in progress at ${s.overText} overs. Nothing '
          'is lost — every ball is already saved — but nobody is scoring '
          'until you or another scorer comes back.',
          style: CkType.body(fontSize: 13, height: 1.45, color: CkColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Keep scoring',
                style: CkType.body(fontSize: 14, color: CkColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Leave',
              style: CkType.body(
                fontSize: 14,
                color: CkColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _handleMenuAction(ScoringMenuAction action) {
    switch (action) {
      case ScoringMenuAction.viewScorecard:
        context.push('/matches/${widget.matchId}/scorecard');
      case ScoringMenuAction.changeBowler:
        final s = ref
            .read(scoringControllerProvider(widget.matchId, widget.inningsNumber))
            .value;
        if (s != null) unawaited(_promptBowler(s, opening: false));
    }
  }

  // ─── sheets ─────────────────────────────────────────────────────────────

  Future<void> _openExtrasSheet(ScoringState s, BallKind kind) async {
    final result = await showModalBottomSheet<ExtraResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder: (_) => ExtrasSheet(kind: kind, overs: s.overText),
    );
    if (result != null && mounted) {
      await _handleExtraCommit(result);
    }
  }

  Future<void> _openWicketSheet(ScoringState s) async {
    final result = await showModalBottomSheet<WicketResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder: (_) => WicketSheet(
        overs: s.overText,
        totalRuns: s.totalRuns,
        totalWickets: s.totalWickets,
        strikerName: s.strikerName,
        nonStrikerName: s.nonStrikerName,
        bowlerName: s.bowlerName,
        fielders: _people(s.fieldingXi),
        bench: _people(s.availableBatters),
        freeHit: s.freeHitActive,
      ),
    );
    if (result != null && mounted) await _handleWicketCommit(result);
  }

  /// Bowler selection, for both the opening bowler and every over after it.
  ///
  /// The two used to be separate methods that each re-derived the bowling
  /// side, read its roster, and mapped match_players to names — the same
  /// sixty lines twice, and a third copy in the wicket sheet. All three now
  /// read squads off [ScoringState].
  Future<void> _promptBowler(ScoringState s, {required bool opening}) async {
    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      // The opening bowler is mandatory — nothing can be scored without one,
      // so that sheet cannot be dismissed. Later overs can be deferred.
      isDismissible: !opening,
      enableDrag: !opening,
      builder: (_) => NewBowlerSheet(
        overNumber: opening ? 0 : s.legalBalls ~/ s.ballsPerOver,
        justBowled: opening ? null : s.lastOverBowlerName,
        people: _people(opening ? s.fieldingXi : s.availableBowlers),
        title: opening ? 'Pick opening bowler' : 'Next bowler?',
        kicker: opening ? 'INNINGS ${widget.inningsNumber}' : null,
      ),
    );
    if (pick == null) {
      if (opening) _bowlerPromptShown = false;
      return;
    }
    if (!mounted) return;
    await _dispatch(() => _controller.setBowler(pick));
  }

  /// Adapts the state's squad lists to the sheet widgets' own person type,
  /// keeping the state layer free of widget imports.
  List<SheetPerson> _people(List<ScoringPerson> people) => [
        for (final p in people)
          SheetPerson(
            id: p.matchPlayerId,
            name: p.name,
            photoUrl: p.photoUrl,
          ),
      ];

}
