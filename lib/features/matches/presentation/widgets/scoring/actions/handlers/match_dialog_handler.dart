import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/presentation/controllers/scoring_controller.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/ball_chip.dart';

/// Handler for match confirmation dialogs (Undo confirmation, Leave match confirmation).
class MatchDialogHandler {
  const MatchDialogHandler({
    required ScoringController controller,
    required VoidCallback onUndoFlash,
    required Future<bool> Function(
      BuildContext context,
      Future<dynamic> Function() action,
    ) dispatch,
  })  : _controller = controller,
        _onUndoFlash = onUndoFlash,
        _dispatch = dispatch;

  final ScoringController _controller;
  final VoidCallback _onUndoFlash;
  final Future<bool> Function(
    BuildContext context,
    Future<dynamic> Function() action,
  ) _dispatch;

  /// Confirms and executes an undo of the last recorded ball.
  Future<void> undo(BuildContext context, ScoringState s) async {
    final last = s.lastBall;
    if (last == null) return;
    if (!await confirmUndo(context, last)) return;
    if (!context.mounted) return;

    if (await _dispatch(context, _controller.undoLastBall)) {
      _onUndoFlash();
    }
  }

  /// Dialog confirming removal of [last].
  Future<bool> confirmUndo(BuildContext context, Ball last) async {
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

  /// Confirms whether the user wants to leave an active match.
  Future<void> handleClose(BuildContext context, ScoringState s) async {
    if (await confirmLeave(context, s) && context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  /// Dialog confirming leaving the match if scoring is in progress.
  Future<bool> confirmLeave(BuildContext context, ScoringState s) async {
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
}
