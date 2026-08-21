import 'package:flutter/material.dart';
import 'package:matchday/features/matches/presentation/controllers/scoring_controller.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/sheet_kit.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/wicket_sheet.dart';

/// Handler for the multi-stage wicket sheet and subsequent dismissal commits.
class WicketActionHandler {
  const WicketActionHandler({
    required ScoringController controller,
    required void Function(String message) onToast,
    required Future<bool> Function(
      BuildContext context,
      Future<dynamic> Function() action,
    ) dispatch,
  })  : _controller = controller,
        _onToast = onToast,
        _dispatch = dispatch;

  final ScoringController _controller;
  final void Function(String message) _onToast;
  final Future<bool> Function(
    BuildContext context,
    Future<dynamic> Function() action,
  ) _dispatch;

  /// Opens the wicket sheet and coordinates the dismissal workflow.
  Future<void> openWicket(
    BuildContext context,
    ScoringState s, {
    required Future<bool> Function(
      BuildContext context,
      Future<dynamic> Function() action,
    ) recordDelivery,
  }) async {
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
    if (result == null || !context.mounted) return;
    await _commitWicket(context, s, result, recordDelivery: recordDelivery);
  }

  Future<void> _commitWicket(
    BuildContext context,
    ScoringState before,
    WicketResult r, {
    required Future<bool> Function(
      BuildContext context,
      Future<dynamic> Function() action,
    ) recordDelivery,
  }) async {
    final dismissedId = r.whoOutNonStriker
        ? before.innings?.nonStrikerId?.value
        : before.innings?.strikerId?.value;

    final recorded = await recordDelivery(
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

    // If incoming batter is provided, bring them into the vacated end
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

  List<SheetPerson> _people(List<ScoringPerson> people) => [
        for (final p in people)
          SheetPerson(id: p.matchPlayerId, name: p.name, photoUrl: p.photoUrl),
      ];
}
