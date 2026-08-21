import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/controllers/scoring_controller.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/new_bowler_sheet.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/sheet_kit.dart';

/// Handler for bowler selection prompts (opening bowler, over changes, manual changes).
class BowlerActionHandler {
  BowlerActionHandler({
    required ScoringController controller,
    required int inningsNumber,
    required Future<bool> Function(
      BuildContext context,
      Future<dynamic> Function() action,
    ) dispatch,
  })  : _controller = controller,
        _inningsNumber = inningsNumber,
        _dispatch = dispatch;

  final ScoringController _controller;
  final int _inningsNumber;
  final Future<bool> Function(
    BuildContext context,
    Future<dynamic> Function() action,
  ) _dispatch;

  bool _openingBowlerPromptShown = false;

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

  /// Prompts for the next bowler after a completed over.
  Future<void> maybePromptNextBowler(BuildContext context, ScoringState s) async {
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
      builder: (_) => NewBowlerSheet(
        overNumber: opening ? 0 : s.legalBalls ~/ s.ballsPerOver,
        justBowled: opening ? null : s.lastOverBowlerName,
        people: _people(opening ? s.fieldingXi : s.availableBowlers),
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

  List<SheetPerson> _people(List<ScoringPerson> people) => [
        for (final p in people)
          SheetPerson(id: p.matchPlayerId, name: p.name, photoUrl: p.photoUrl),
      ];
}
