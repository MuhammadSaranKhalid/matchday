import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/match.dart';
import '../../state/match_start_state.dart';

/// Minimal back-arrow + title bar. Used by the screen's error state, where
/// there is no [MatchStartState] to build the full header from.
class MatchStartTopBar extends StatelessWidget {
  const MatchStartTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed:
                () =>
                    context.canPop()
                        ? context.pop()
                        : context.go('/my/matches'),
            icon: const Icon(Icons.arrow_back, color: CkColors.ink),
          ),
          Text(title, style: CkType.display(fontSize: 18)),
        ],
      ),
    );
  }
}

/// Match Start App Bar matching the Stitch "Match hub" header.
class MatchStartHeader extends StatelessWidget {
  const MatchStartHeader({super.key, required this.state});

  final MatchStartState state;

  @override
  Widget build(BuildContext context) {
    final isLineup =
        state.phase == MatchStartPhase.lineup ||
        state.phase == MatchStartPhase.ready;

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5F0),
        border: Border(bottom: BorderSide(color: Color(0xFFE8E3DA))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Navigation to Match Hub
          GestureDetector(
            onTap:
                () =>
                    context.canPop()
                        ? context.pop()
                        : context.go('/my/matches'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF24231F),
                ),
                const SizedBox(width: 8),
                Text(
                  'Match hub',
                  style: CkType.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF24231F),
                  ),
                ),
              ],
            ),
          ),

          // Ready Indicator Pill with Pulse
          if (isLineup)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EA),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFD1E7D5)),
              ),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF4E7D58),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
