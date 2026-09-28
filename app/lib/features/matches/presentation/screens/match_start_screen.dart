import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/match.dart';
import '../controllers/match_room_controller.dart';
import '../state/match_room_state.dart';
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
  const MatchStartScreen({
    super.key,
    required this.matchId,
    required this.room,
  });

  final String matchId;
  final MatchRoomState room;

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
    final userId = ref.watch(currentUserIdProvider);
    final state = MatchStartState.fromRoom(room, userId: userId);

    if (_terminalRoute(state.match) != null ||
        state.phase == MatchStartPhase.live) {
      _handleRedirect(context, state);
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: SafeArea(child: MatchStartLoader()),
      );
    }

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MatchStartHeader(state: state),
            if (!room.isRealtimeConnected || room.nonBlockingError != null)
              MaterialBanner(
                content: Text(
                  !room.isRealtimeConnected
                      ? 'Reconnecting. The last confirmed match state is still shown.'
                      : 'Could not refresh. The last confirmed match state is still shown.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => ref
                        .read(matchRoomControllerProvider(matchId).notifier)
                        .refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            Expanded(
              child: switch (state.phase) {
                MatchStartPhase.toss => MatchStartTossStage(
                  matchId: matchId,
                  state: state,
                  room: room,
                ),
                MatchStartPhase.lineup || MatchStartPhase.ready =>
                  MatchStartLineupStage(
                    matchId: matchId,
                    state: state,
                    room: room,
                  ),
                MatchStartPhase.live => const SizedBox.shrink(),
              },
            ),
          ],
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
    MatchStatus.inningsBreak => '/matches/$matchId/score?innings=1',
    _ => null,
  };
}
