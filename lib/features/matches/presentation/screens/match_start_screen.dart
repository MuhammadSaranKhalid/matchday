import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/match.dart';
import '../controllers/match_start_controller.dart';
import '../state/match_start_state.dart';
import '../widgets/match_start/match_start_widgets.dart';

/// Two-phone Match Start. Toss → openers → Start. The opening bowler is
/// deferred to ball 1 in the scoring screen (matches the design intent +
/// the deployed `start_match_now` RPC, which doesn't ask for a bowler).
///
/// This screen is a thin UI shell. All form state lives in
/// [MatchStartController] via [MatchStartState]. All actions are dispatched
/// through the controller. The screen only handles navigation and snackbars.
class MatchStartScreen extends ConsumerWidget {
  const MatchStartScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchStartControllerProvider(matchId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncError(:final error) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MatchStartHeaderRow(
                    onBack: () => context.pop(), title: 'Match start'),
                const Spacer(),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      error is FailureWrapper
                          ? error.failure.message
                          : error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          AsyncData(:final value) when value.phase == MatchStartPhase.live =>
            Builder(builder: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/matches/${value.match.id.value}/score');
                }
              });
              return const Center(
                  child: CircularProgressIndicator(color: CkColors.ink));
            }),
          AsyncData(:final value) => _layout(context, ref, value),
          _ => const Center(
              child: CircularProgressIndicator(color: CkColors.ink),
            ),
        },
      ),
    );
  }

  Widget _layout(BuildContext context, WidgetRef ref, MatchStartState state) {
    final controller =
        ref.read(matchStartControllerProvider(matchId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MatchStartHeader(state: state, onBack: () => context.pop()),
        MatchStartPhonePill(state: state),
        Expanded(
          child: _body(state, controller),
        ),
        MatchStartCtaBar(
          state: state,
          builder: (s) => _ctaForStage(context, ref, s),
        ),
      ],
    );
  }

  Widget _body(MatchStartState state, MatchStartController controller) {
    switch (state.phase) {
      case MatchStartPhase.toss:
        return MatchStartStage1Toss(
          state: state,
          onPickWinner: controller.pickTossWinner,
          onPickDecision: controller.pickTossDecision,
        );
      case MatchStartPhase.lineup:
        return MatchStartStage2Lineup(
          state: state,
          onPickStriker: controller.pickStriker,
          onPickNonStriker: controller.pickNonStriker,
        );
      case MatchStartPhase.ready:
        return MatchStartStage3Ready(state: state);
      case MatchStartPhase.live:
        return const SizedBox.shrink();
    }
  }

  Widget _ctaForStage(
      BuildContext context, WidgetRef ref, MatchStartState state) {
    final controller =
        ref.read(matchStartControllerProvider(matchId).notifier);

    switch (state.phase) {
      case MatchStartPhase.toss:
        return CkButton(
          label: 'Continue → lineup',
          busy: state.isBusy,
          onPressed: state.viewerCanAct && state.isTossReady && !state.isBusy
              ? () => _submitToss(context, controller)
              : null,
        );
      case MatchStartPhase.lineup:
        if (state.viewerRole != MatchStartViewerRole.battingCaptain) {
          return const CkButton(
            label: 'Waiting on the batting captain…',
            onPressed: null,
          );
        }
        return CkButton(
          label: 'Submit openers',
          busy: state.isBusy,
          onPressed: state.isLineupReady && !state.isBusy
              ? () => _submitOpeners(context, controller)
              : null,
        );
      case MatchStartPhase.ready:
        if (state.viewerRole != MatchStartViewerRole.battingCaptain) {
          return const CkButton(
            label: 'Waiting for the batting captain to tap Start…',
            onPressed: null,
          );
        }
        return CkButton(
          label: 'Start match — first ball',
          busy: state.isBusy,
          onPressed: !state.isBusy
              ? () => _startMatch(context, controller)
              : null,
        );
      case MatchStartPhase.live:
        return const SizedBox.shrink();
    }
  }

  Future<void> _submitToss(
      BuildContext context, MatchStartController controller) async {
    final result = await controller.submitToss();
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {},
    );
  }

  Future<void> _submitOpeners(
      BuildContext context, MatchStartController controller) async {
    final result = await controller.submitOpeners();
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {},
    );
  }

  Future<void> _startMatch(
      BuildContext context, MatchStartController controller) async {
    final result = await controller.startMatchNow();
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => context.go('/matches/$matchId/score'),
    );
  }
}
