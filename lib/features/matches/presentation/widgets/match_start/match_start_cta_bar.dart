import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_button.dart';
import '../../../domain/entities/match.dart';
import '../../controllers/match_start_controller.dart';
import '../../state/match_start_state.dart';

/// The pinned bottom action bar.
///
/// This is the only place in the flow that dispatches a write, surfaces a
/// [Failure] to the user, or navigates on success — the stages above it stay
/// purely presentational.
class MatchStartCtaBar extends ConsumerWidget {
  const MatchStartCtaBar({
    super.key,
    required this.matchId,
    required this.state,
  });

  final String matchId;
  final MatchStartState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.phase == MatchStartPhase.live) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: _button(context, ref),
    );
  }

  MatchStartController _controller(WidgetRef ref) =>
      ref.read(matchStartControllerProvider(matchId).notifier);

  Widget _button(BuildContext context, WidgetRef ref) {
    switch (state.phase) {
      case MatchStartPhase.toss:
        return CkButton(
          label: 'Continue → lineup',
          busy: state.isBusy,
          onPressed: state.viewerCanAct && state.isTossReady
              ? () => _run(context, _controller(ref).submitToss)
              : null,
        );

      case MatchStartPhase.lineup:
        if (!state.isViewerBattingCaptain) {
          return const CkButton(
            label: 'Waiting on the batting captain…',
            onPressed: null,
          );
        }
        return CkButton(
          label: 'Submit openers',
          busy: state.isBusy,
          onPressed: state.isLineupReady
              ? () => _run(context, _controller(ref).submitOpeners)
              : null,
        );

      case MatchStartPhase.ready:
        if (!state.isViewerBattingCaptain) {
          return const CkButton(
            label: 'Waiting for the batting captain to tap Start…',
            onPressed: null,
          );
        }
        return CkButton(
          label: 'Start match — first ball',
          busy: state.isBusy,
          onPressed: () => _run(
            context,
            _controller(ref).startMatchNow,
            onSuccess: () => context.go('/matches/$matchId/score'),
          ),
        );

      case MatchStartPhase.live:
        return const SizedBox.shrink();
    }
  }

  /// Await a controller write, then either report the failure or run
  /// [onSuccess]. Guards `context` across the await.
  Future<void> _run(
    BuildContext context,
    Future<Either<Failure, Unit>> Function() action, {
    VoidCallback? onSuccess,
  }) async {
    final result = await action();
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => onSuccess?.call(),
    );
  }
}
