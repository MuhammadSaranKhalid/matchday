import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/match.dart';
import '../controllers/match_start_controller.dart';
import '../widgets/match_start/match_start_atoms.dart';
import '../widgets/match_start/match_start_header.dart';
import '../widgets/match_start/match_start_layout.dart';

/// Two-phone Match Start screen.
///
/// A routing shell: it watches [matchStartControllerProvider], maps the
/// [AsyncValue] to error / loading / redirect / data, and delegates the whole
/// data UI to [MatchStartLayout].
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
          AsyncError(:final error) => _ErrorView(message: failureMessageOf(error)),
          // Terminal status wins over the setup phase: an abandoned match
          // never advances `start_phase`, so without this the screen would
          // strand the user on a Start button that can only error.
          AsyncData(:final value) when _terminalRoute(value.match) != null =>
            _Redirect(location: _terminalRoute(value.match)!),
          // The match went live on the other phone (or was already live when
          // we arrived) — hand over to the scoring screen.
          AsyncData(:final value) when value.phase == MatchStartPhase.live =>
            _Redirect(location: '/matches/$matchId/score'),
          AsyncData(:final value) =>
            MatchStartLayout(matchId: matchId, state: value),
          _ => const MatchStartLoader(),
        },
      ),
    );
  }

  /// Where a match that is no longer in setup belongs, or null while it is
  /// still on its way to the first ball.
  String? _terminalRoute(Match match) => switch (match.status) {
        MatchStatus.completed ||
        MatchStatus.abandoned ||
        MatchStatus.walkover =>
          '/matches/$matchId/result',
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

/// Navigates away once, on the first frame after the match leaves setup —
/// either because it went live or because it reached a terminal status.
///
/// A widget rather than a post-frame callback in `build` so the redirect
/// fires exactly once: it is only inserted when the condition holds, and
/// `initState` runs once per insertion.
class _Redirect extends StatefulWidget {
  const _Redirect({required this.location});

  final String location;

  @override
  State<_Redirect> createState() => _RedirectState();
}

class _RedirectState extends State<_Redirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(widget.location);
    });
  }

  @override
  Widget build(BuildContext context) => const MatchStartLoader();
}
