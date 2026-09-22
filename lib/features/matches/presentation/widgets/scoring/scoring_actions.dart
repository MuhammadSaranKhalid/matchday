// Everything the scoring screen DOES, as opposed to everything it shows.
//
// ── WHY THIS IS ONE FILE ─────────────────────────────────────────────────────
//
// This was a facade over four handler classes — one each for bowlers, wickets,
// extras and dialogs. Each was a class whose entire substance was a constructor
// taking (controller, dispatch, onToast) and one or two methods, so answering
// "what happens when I tap Wicket?" meant opening the screen, this file, the
// wicket handler, the controller and the state. Five files for one tap, and
// four of the five hops were ceremony.
//
// They are inlined here. The split that DOES earn its keep is kept: the screen
// arranges, this file decides what a control does, the controller performs the
// write. Three files, each of which is about one thing.
//
// Note deliberately not folded further: this does NOT go back into
// scoring_screen.dart. That file once held 3,300 lines of rendering and
// behaviour together, and a wide-attribution bug that corrupted scorecards
// survived in it precisely because nothing inside a widget method can be
// reached by a test. Behaviour stays out of the widget tree.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/ball.dart';
import '../../../domain/entities/match.dart';
import '../../controllers/scoring_controller.dart';
import '../../providers/matches_providers.dart';
import '../../state/scoring_state.dart';
import 'ball_chip.dart';
import 'extras_sheet.dart';
import 'new_bowler_sheet.dart';
import 'scoring_top_bar.dart';
import 'sheet_kit.dart';
import 'wicket_sheet.dart';

class ScoringActions {
  ScoringActions({
    required WidgetRef ref,
    required String matchId,
    required int inningsNumber,
    required void Function(String message) onToast,
    required VoidCallback onUndoFlash,
  }) : _ref = ref,
       _matchId = matchId,
       _inningsNumber = inningsNumber,
       _onToast = onToast,
       _onUndoFlash = onUndoFlash;

  final WidgetRef _ref;
  final String _matchId;
  final int _inningsNumber;
  final void Function(String message) _onToast;
  final VoidCallback _onUndoFlash;

  /// The innings-end route fires once.
  bool _inningsEndRouted = false;

  /// The opening-bowler sheet offers itself once, unless it is dismissed.
  bool _openingBowlerPromptShown = false;

  ScoringController get _controller =>
      _ref.read(scoringControllerProvider(_matchId, _inningsNumber).notifier);

  ScoringState? get _state =>
      _ref.read(scoringControllerProvider(_matchId, _inningsNumber)).value;

  // ── Lifecycle prompts ────────────────────────────────────────────────────

  /// Offers the opening-bowler sheet if the innings requires one.
  void maybePromptOpeningBowler(BuildContext context, ScoringState s) {
    if (_openingBowlerPromptShown) return;
    if (!s.canScore) return;
    if (s.match.startPhase != MatchStartPhase.live) return;
    if (!s.needsOpeningBowler) return;
    if (s.matchPlayers.isEmpty) return;

    _openingBowlerPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) promptBowler(context, s, opening: true);
    });
  }

  void maybeRouteOnInningsEnd(BuildContext context, ScoringState s) {
    if (_inningsEndRouted || !s.inningsOver) return;
    if (!s.isTerminal) return;
    _inningsEndRouted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/matches/$_matchId/result');
    });
  }

  Future<String?> startChase({
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
    required int target,
  }) async {
    final result = await _ref
        .read(matchesRepositoryProvider)
        .startInnings(
          matchId: MatchId(_matchId),
          inningsNumber: 2,
          strikerId: strikerId,
          nonStrikerId: nonStrikerId,
          bowlerId: bowlerId,
          target: target,
        );
    return result.fold((failure) => failure.message, (_) => null);
  }

  // ── Deliveries ───────────────────────────────────────────────────────────

  Future<void> run(BuildContext context, int runs) =>
      _recordDelivery(context, () => _controller.recordRun(runs));

  /// Opens the extras sheet and commits the selected extra runs.
  Future<void> openExtras(
    BuildContext context,
    ScoringState s,
    BallKind kind,
  ) async {
    final result = await showModalBottomSheet<ExtraResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder: (_) => ExtrasSheet(kind: kind, overs: s.overText),
    );
    if (result == null || !context.mounted) return;

    await _recordDelivery(
      context,
      () => _controller.recordExtra(kind: result.kind, runs: result.runs),
    );
    if (result.freeHit && context.mounted) {
      _onToast('Free hit — next ball');
    }
  }

  /// Opens the wicket sheet and coordinates the dismissal workflow.
  Future<void> openWicket(BuildContext context, ScoringState s) async {
    final result = await showModalBottomSheet<WicketResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder:
          (_) => WicketSheet(
            overs: s.overText,
            totalRuns: s.totalRuns,
            totalWickets: s.totalWickets,
            strikerName: s.strikerName,
            nonStrikerName: s.nonStrikerName,
            bowlerName: s.bowlerName,
            fielders: _sheetPeople(s.fieldingXi),
            bench: _sheetPeople(s.availableBatters),
            freeHit: s.freeHitActive,
          ),
    );
    if (result == null || !context.mounted) return;
    await _commitWicket(context, s, result);
  }

  Future<void> _commitWicket(
    BuildContext context,
    ScoringState before,
    WicketResult r,
  ) async {
    final dismissedId =
        r.whoOutNonStriker
            ? before.innings?.nonStrikerId?.value
            : before.innings?.strikerId?.value;

    final recorded = await _recordDelivery(
      context,
      () => _controller.recordWicket(
        type: r.type,
        runsBefore: r.runsBefore,
        dismissedMatchPlayerId: dismissedId,
        fielderMatchPlayerId: r.fielderMatchPlayerId,
      ),
    );
    if (!recorded || !context.mounted) return;

    final newWicketCount = before.totalWickets + 1;
    _onToast('$newWicketCount down');

    // If an incoming batter was chosen, bring them into the vacated end.
    if (r.nextBatterMatchPlayerId != null) {
      await _dispatch(
        context,
        () => _controller.bringInBatter(
          r.nextBatterMatchPlayerId!,
          forNonStriker: r.whoOutNonStriker,
        ),
      );
    }
  }

  Future<bool> _recordDelivery(
    BuildContext context,
    Future<dynamic> Function() action,
  ) async {
    final ok = await _dispatch(context, action);
    final s = _state;
    if (ok && context.mounted && s != null) {
      await _maybePromptNextBowler(context, s);
    }
    return ok;
  }

  // ── Bowler selection ─────────────────────────────────────────────────────

  /// Prompts for the next bowler after a completed over.
  Future<void> _maybePromptNextBowler(
    BuildContext context,
    ScoringState s,
  ) async {
    if (s.inningsOver || s.bowlerSet || s.balls.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (context.mounted) await promptBowler(context, s, opening: false);
  }

  /// Opens the bowler selection bottom sheet.
  Future<void> promptBowler(
    BuildContext context,
    ScoringState s, {
    required bool opening,
  }) async {
    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      isDismissible: !opening,
      enableDrag: !opening,
      builder:
          (_) => NewBowlerSheet(
            overNumber: opening ? 0 : s.legalBalls ~/ s.ballsPerOver,
            justBowled: opening ? null : s.lastOverBowlerName,
            people: _sheetPeople(opening ? s.fieldingXi : s.availableBowlers),
            title: opening ? 'Pick opening bowler' : 'Next bowler?',
            kicker: opening ? 'INNINGS $_inningsNumber' : null,
          ),
    );
    if (pick == null) {
      if (opening) _openingBowlerPromptShown = false;
      return;
    }
    if (!context.mounted) return;
    await _dispatch(context, () => _controller.setBowler(pick));
  }

  // ── Batter selection ─────────────────────────────────────────────────────

  /// Opens the incoming-batter picker for whichever end a wicket emptied.
  ///
  /// Reachable two ways: chosen inside the wicket sheet at the moment of the
  /// dismissal, or from the pad's gate afterwards if that step was skipped or
  /// the sheet was dismissed. The second route did not exist, which is how a
  /// delivery came to be recorded against an empty end.
  Future<void> promptBatter(BuildContext context, ScoringState s) async {
    final bench = s.availableBatters;
    if (bench.isEmpty) return;

    // Whichever end the wicket emptied is the one being refilled.
    final forNonStriker = (s.innings?.nonStrikerId?.value ?? '').isEmpty;

    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder:
          (_) => NewBowlerSheet(
            overNumber: s.legalBalls ~/ s.ballsPerOver,
            justBowled: null,
            people: _sheetPeople(bench),
            title: 'Next batter in?',
            kicker: '${s.totalWickets} DOWN',
            subtitle: 'Pick who comes to the crease.',
          ),
    );
    if (pick == null || !context.mounted) return;
    await _dispatch(
      context,
      () => _controller.bringInBatter(pick, forNonStriker: forNonStriker),
    );
  }

  List<SheetPerson> _sheetPeople(List<ScoringPerson> people) => [
    for (final p in people)
      SheetPerson(id: p.matchPlayerId, name: p.name, photoUrl: p.photoUrl),
  ];

  // ── Undo & dialogs ───────────────────────────────────────────────────────

  /// Confirms and executes an undo of the last recorded ball.
  Future<void> undo(BuildContext context) async {
    final s = _state;
    if (s == null) return;
    final last = s.lastBall;
    if (last == null) return;
    if (!await _confirmUndo(context, last)) return;
    if (!context.mounted) return;

    if (await _dispatch(context, _controller.undoLastBall)) {
      _onUndoFlash();
    }
  }

  Future<bool> _confirmUndo(BuildContext context, Ball last) async {
    final over = '${last.overNumber}.${last.ballInOver}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: CkColors.paper,
            title: Text('Undo this ball?', style: CkType.display(fontSize: 18)),
            content: Text(
              'Removes $over — ${describeBall(last)} — from the scorecard and '
              'rewinds the score. This cannot be redone.',
              style: CkType.body(
                fontSize: 13,
                height: 1.45,
                color: CkColors.ink2,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Keep it',
                  style: CkType.body(fontSize: 14, color: CkColors.muted),
                ),
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

  /// Confirms whether the user wants to leave an active match.
  Future<void> handleClose(BuildContext context, ScoringState s) async {
    if (await _confirmLeave(context, s) && context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<bool> _confirmLeave(BuildContext context, ScoringState s) async {
    final scoringInProgress = s.canScore && !s.inningsOver;
    if (!scoringInProgress) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: CkColors.paper,
            title: Text('Stop scoring?', style: CkType.display(fontSize: 18)),
            content: Text(
              'The innings is still in progress at ${s.overText} overs. Nothing '
              'is lost — every ball is already saved — but nobody is scoring '
              'until you or another scorer comes back.',
              style: CkType.body(
                fontSize: 13,
                height: 1.45,
                color: CkColors.ink2,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Keep scoring',
                  style: CkType.body(fontSize: 14, color: CkColors.muted),
                ),
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

  // ── Overflow menu ────────────────────────────────────────────────────────

  void handleMenuAction(BuildContext context, ScoringMenuAction action) {
    switch (action) {
      case ScoringMenuAction.viewScorecard:
        context.push('/matches/$_matchId/scorecard');
      case ScoringMenuAction.changeBowler:
        final s = _state;
        if (s != null) unawaited(promptBowler(context, s, opening: false));
    }
  }

  // ── Plumbing ─────────────────────────────────────────────────────────────

  /// Run one controller action, surfacing a failure as a snackbar.
  ///
  /// Returns whether it succeeded, so callers can decide what follows — the
  /// next-bowler prompt after a delivery, the flash after an undo.
  Future<bool> _dispatch(
    BuildContext context,
    Future<dynamic> Function() action,
  ) async {
    final dynamic result = await action();
    if (result is Either<Failure, Unit>) {
      if (!context.mounted) return result.isRight();
      return result.fold((f) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.message)));
        return false;
      }, (_) => true);
    }
    return true;
  }
}
