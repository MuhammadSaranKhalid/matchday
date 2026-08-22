import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../controllers/scoring_controller.dart';
import '../providers/matches_providers.dart';
import '../state/scoring_state.dart';
import '../widgets/scoring/scoring_action_bar.dart';
import '../widgets/scoring/scoring_actions.dart';
import '../widgets/scoring/scoring_board.dart';
import '../widgets/scoring/scoring_notices.dart';
import '../widgets/scoring/scoring_top_bar.dart';

// =============================================================================
// ScoringScreen — live ball-by-ball scorer.
// =============================================================================
// THE RULE FOR THIS SCREEN
//
//   The screen arranges. Everything that renders lives in widgets/scoring/,
//   everything that decides lives in ScoringController or ScoringState, and
//   everything that HAPPENS lives in ScoringActions.
//
// So this file contains exactly two things: the AsyncValue switch, and the
// widget tree that orders the pieces. No cricket rules, no sheets, no
// dialogs, no dispatch, no repository access.
//
// It is stated here because it was not obvious before: this file once held
// 3,300 lines of all of the above, and a wide-attribution bug that corrupted
// scorecards survived inside it precisely because nothing in a widget method
// can be unit-tested.
//
// FOLLOWING ONE TAP
//
//   this file        which callback a control fires
//   scoring_actions  what that callback DOES (sheet, dialog, then the write)
//   scoring_controller  the write itself
//
// Three hops, three files. It was five until 2026-08-22, when the four
// single-method action handler classes were inlined into scoring_actions.
//
// WHERE THINGS LIVE
//
//   state/scoring_state.dart             derived state + the cricket rules
//   controllers/scoring_controller.dart  the writes
//   widgets/scoring/scoring_actions.dart   what every control DOES
//   widgets/scoring/scoring_action_bar.dart the control surface + its gating
//   widgets/scoring/scoring_board.dart      the read-out (score, batters, log)
//   widgets/scoring/pad/                    the run pad, extras keys, and pad buttons
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
  late final ScoringActions _actions = ScoringActions(
    ref: ref,
    matchId: widget.matchId,
    inningsNumber: widget.inningsNumber,
    onToast: _flashToast,
    onUndoFlash: _flashUndo,
  );

  bool _undoFlash = false;
  String? _toast;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

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

    ref.listen(
      scoringControllerProvider(widget.matchId, widget.inningsNumber),
      (prev, next) {
        final state = next.value;
        if (state != null) {
          _actions.maybePromptOpeningBowler(context, state);
          _actions.maybeRouteOnInningsEnd(context, state);
        }
      },
    );

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

    // Team name for the read-only notice.
    final battingTeam = ref.watch(teamProvider(s.battingTeamId.value)).value;

    // Leaving mid-innings is almost always a mis-swipe: an Android back
    // gesture or an iOS edge-swipe on a phone being held one-handed at a
    // ground. Nothing else in the app guards a route, but nothing else in the
    // app is a live ledger someone is mid-way through writing.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _actions.handleClose(context, s);
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
                    matchType: s.match.matchType,
                    onClose: () => _actions.handleClose(context, s),
                    menuActions: [
                      ScoringMenuAction.viewScorecard,
                      if (s.canScore && s.bowlerSet)
                        ScoringMenuAction.changeBowler,
                    ],
                    onMenuAction: (a) => _actions.handleMenuAction(context, a),
                    onUndo: () => _actions.undo(context),
                    // NOT gated on `hasPending`. It used to be, on the
                    // reasoning that an unwritten delivery has nothing to
                    // undo — but the repository has always handled exactly
                    // that case by discarding the queued write, and the gate
                    // meant nothing could ever reach it. When writes stop
                    // landing, `pendingCount` never returns to zero, so undo
                    // was disabled permanently at the moment it was needed
                    // most: out of coverage, having just mis-tapped.
                    canUndo: s.canScore && s.balls.isNotEmpty,
                    undoFlash: _undoFlash,
                  ),
                  Scoreboard(state: s),
                  BattersAndBowler(
                    state: s,
                    onTapBowler: () => _actions.promptBowler(
                      context,
                      s,
                      opening: false,
                    ),
                  ),
                  if (s.freeHitActive) const FreeHitBanner(),
                  const SizedBox(height: 6),
                  Expanded(
                    child: BallLog(
                      balls: s.balls,
                      nameOf: s.nameOf,
                      matchPlayers: s.matchPlayers,
                    ),
                  ),
                  ScoringActionBar(
                    state: s,
                    battingTeamName: battingTeam?.name,
                    onRun: (runs) => _actions.run(context, runs),
                    onWicket: () => _actions.openWicket(context, s),
                    onExtra: (kind) => _actions.openExtras(context, s, kind),
                    onSelectBowler: () => _actions.promptBowler(
                      context,
                      s,
                      opening: s.balls.isEmpty,
                    ),
                    onSelectBatter: () => _actions.promptBatter(context, s),
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
}
