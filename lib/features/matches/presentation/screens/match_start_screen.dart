import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/match.dart';
import '../controllers/match_start_controller.dart';
import '../state/match_start_state.dart';
import '../widgets/match_start/match_start_atoms.dart';
import '../widgets/match_start/match_start_header.dart';
import '../widgets/match_start/stage_lineup.dart';
import '../widgets/match_start/stage_toss.dart';

/// Two-phone Match Start screen.
///
/// Sets up pre-match details (Toss -> Openers) and automatically
/// transitions to the live scoring screen upon match commencement.
class MatchStartScreen extends ConsumerWidget {
  const MatchStartScreen({super.key, required this.matchId});

  final String matchId;

  void _handleRedirect(BuildContext context, MatchStartState state) {
    final terminal = _terminalRoute(state.match);
    if (terminal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(terminal);
      });
    } else if (state.phase == MatchStartPhase.live) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/matches/$matchId/score');
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(matchStartControllerProvider(matchId), (prev, next) {
      final state = next.value;
      if (state != null) _handleRedirect(context, state);
    });

    final async = ref.watch(matchStartControllerProvider(matchId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: async.when(
          data: (state) {
            if (_terminalRoute(state.match) != null ||
                state.phase == MatchStartPhase.live) {
              _handleRedirect(context, state);
              return const MatchStartLoader();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MatchStartHeader(state: state),
                Expanded(
                  child: switch (state.phase) {
                    MatchStartPhase.toss => MatchStartTossStage(
                      matchId: matchId,
                      state: state,
                    ),
                    MatchStartPhase.lineup || MatchStartPhase.ready =>
                      MatchStartLineupStage(matchId: matchId, state: state),
                    MatchStartPhase.live => const SizedBox.shrink(),
                  },
                ),
              ],
            );
          },
          loading: () => const MatchStartLoader(),
          error: (error, _) => _ErrorView(message: failureMessageOf(error)),
        ),
      ),
    );
  }

  /// Where a match that is no longer in setup belongs, or null while it is
  /// still on its way to the first ball.
  String? _terminalRoute(Match match) => switch (match.status) {
    MatchStatus.completed ||
    MatchStatus.abandoned ||
    MatchStatus.walkover => '/matches/$matchId/result',
    // Innings 2 setup has its own screen until phase 3 unifies them.
    MatchStatus.inningsBreak => '/matches/$matchId/innings-break',
    _ => null,
  };
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MatchStartTopBar(title: 'Match start'),
        const Spacer(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
