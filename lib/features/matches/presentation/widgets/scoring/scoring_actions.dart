// Everything the scoring screen DOES, as opposed to everything it shows.
//
// Refactored into modular, dedicated action handlers:
//   - WicketActionHandler: wicket modal & dismissal flow
//   - ExtrasActionHandler: extra deliveries & penalty splits
//   - BowlerActionHandler: opening & over-change bowler prompts
//   - MatchDialogHandler: undo & leave confirmations
//
// This class acts as the lightweight facade connecting the UI to these handlers.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/ball.dart';
import '../../../domain/entities/match.dart';
import '../../controllers/scoring_controller.dart';
import '../../state/scoring_state.dart';
import 'actions/handlers/bowler_action_handler.dart';
import 'actions/handlers/extras_action_handler.dart';
import 'actions/handlers/match_dialog_handler.dart';
import 'actions/handlers/wicket_action_handler.dart';
import 'scoring_top_bar.dart';

class ScoringActions {
  ScoringActions({
    required WidgetRef ref,
    required String matchId,
    required int inningsNumber,
    required void Function(String message) onToast,
    required VoidCallback onUndoFlash,
  })  : _ref = ref,
        _matchId = matchId,
        _inningsNumber = inningsNumber,
        _onToast = onToast,
        _onUndoFlash = onUndoFlash {
    _wicketHandler = WicketActionHandler(
      controller: _controller,
      onToast: _onToast,
      dispatch: _dispatch,
    );
    _extrasHandler = ExtrasActionHandler(
      controller: _controller,
      onToast: _onToast,
    );
    _bowlerHandler = BowlerActionHandler(
      controller: _controller,
      inningsNumber: _inningsNumber,
      dispatch: _dispatch,
    );
    _dialogHandler = MatchDialogHandler(
      controller: _controller,
      onUndoFlash: _onUndoFlash,
      dispatch: _dispatch,
    );
  }

  final WidgetRef _ref;
  final String _matchId;
  final int _inningsNumber;
  final void Function(String message) _onToast;
  final VoidCallback _onUndoFlash;

  late final WicketActionHandler _wicketHandler;
  late final ExtrasActionHandler _extrasHandler;
  late final BowlerActionHandler _bowlerHandler;
  late final MatchDialogHandler _dialogHandler;

  /// The innings-end route fires once.
  bool _inningsEndRouted = false;

  ScoringController get _controller => _ref.read(
        scoringControllerProvider(_matchId, _inningsNumber).notifier,
      );

  ScoringState? get _state =>
      _ref.read(scoringControllerProvider(_matchId, _inningsNumber)).value;

  // ── Lifecycle prompts ────────────────────────────────────────────────────

  void maybePromptOpeningBowler(BuildContext context, ScoringState s) =>
      _bowlerHandler.maybePromptOpeningBowler(context, s);

  void maybeRouteOnInningsEnd(BuildContext context, ScoringState s) {
    if (_inningsEndRouted || !s.inningsOver) return;
    _inningsEndRouted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(_postInningsRoute(s.match));
    });
  }

  String _postInningsRoute(Match match) {
    switch (match.status) {
      case MatchStatus.completed:
      case MatchStatus.abandoned:
      case MatchStatus.walkover:
        return '/matches/$_matchId/result';
      case MatchStatus.inningsBreak:
        return '/matches/$_matchId/innings-break';
      default:
        final perSide =
            match.format.inningsPerSide <= 0 ? 1 : match.format.inningsPerSide;
        final isFinalInnings = _inningsNumber >= perSide * 2;
        return isFinalInnings
            ? '/matches/$_matchId/result'
            : '/matches/$_matchId/innings-break';
    }
  }

  // ── Deliveries ───────────────────────────────────────────────────────────

  Future<void> run(BuildContext context, int runs) =>
      _recordDelivery(context, () => _controller.recordRun(runs));

  Future<void> openExtras(
    BuildContext context,
    ScoringState s,
    BallKind kind,
  ) =>
      _extrasHandler.openExtras(
        context,
        s,
        kind,
        recordDelivery: _recordDelivery,
      );

  Future<void> openWicket(BuildContext context, ScoringState s) =>
      _wicketHandler.openWicket(
        context,
        s,
        recordDelivery: _recordDelivery,
      );

  Future<bool> _recordDelivery(
    BuildContext context,
    Future<dynamic> Function() action,
  ) async {
    final ok = await _dispatch(context, action);
    final s = _state;
    if (ok && context.mounted && s != null) {
      await _bowlerHandler.maybePromptNextBowler(context, s);
    }
    return ok;
  }

  // ── Undo & Dialogs ───────────────────────────────────────────────────────

  Future<void> undo(BuildContext context) async {
    final s = _state;
    if (s != null) await _dialogHandler.undo(context, s);
  }

  Future<void> promptBowler(
    BuildContext context,
    ScoringState s, {
    required bool opening,
  }) =>
      _bowlerHandler.promptBowler(context, s, opening: opening);

  Future<void> handleClose(BuildContext context, ScoringState s) =>
      _dialogHandler.handleClose(context, s);

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

  Future<bool> _dispatch(
    BuildContext context,
    Future<dynamic> Function() action,
  ) async {
    final dynamic result = await action();
    if (result is Either<Failure, Unit>) {
      if (!context.mounted) return result.isRight();
      return result.fold(
        (f) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message)));
          return false;
        },
        (_) => true,
      );
    }
    return true;
  }
}
