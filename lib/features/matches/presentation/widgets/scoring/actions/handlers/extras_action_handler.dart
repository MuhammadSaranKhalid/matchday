import 'package:flutter/material.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/presentation/controllers/scoring_controller.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/extras_sheet.dart';

/// Handler for the extras sheet and extra delivery recording.
class ExtrasActionHandler {
  const ExtrasActionHandler({
    required ScoringController controller,
    required void Function(String message) onToast,
  })  : _controller = controller,
        _onToast = onToast;

  final ScoringController _controller;
  final void Function(String message) _onToast;

  /// Opens the extras sheet and commits the selected extra runs.
  Future<void> openExtras(
    BuildContext context,
    ScoringState s,
    BallKind kind, {
    required Future<bool> Function(
      BuildContext context,
      Future<dynamic> Function() action,
    ) recordDelivery,
  }) async {
    final result = await showModalBottomSheet<ExtraResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6B1A1810),
      isScrollControlled: true,
      builder: (_) => ExtrasSheet(kind: kind, overs: s.overText),
    );
    if (result == null || !context.mounted) return;

    await recordDelivery(
      context,
      () => _controller.recordExtra(kind: result.kind, runs: result.runs),
    );
    if (result.freeHit && context.mounted) {
      _onToast('Free hit — next ball');
    }
  }
}
