import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/presentation/providers/teams_providers.dart';
import '../../../../teams/presentation/widgets/team_avatar.dart';
import '../../state/match_start_state.dart';

/// The "WHICH TEAM / WHICH ROLE / THIS PHONE" strip under the header. It is
/// what stops the two captains confusing each other's device.
///
/// Renders nothing for spectators — they have no side.
class MatchStartPhonePill extends ConsumerWidget {
  const MatchStartPhonePill({super.key, required this.state});

  final MatchStartState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (teamId, roleLabel) = switch (state.viewerRole) {
      MatchStartViewerRole.battingCaptain => (
          state.battingTeamId,
          'BATTING CAPTAIN',
        ),
      MatchStartViewerRole.bowlingCaptain => (
          state.bowlingTeamId,
          'BOWLING CAPTAIN',
        ),
      MatchStartViewerRole.spectator => (null, 'SPECTATOR'),
    };
    if (teamId == null) return const SizedBox.shrink();

    final team = ref.watch(teamProvider(teamId.value)).value;

    return Container(
      width: double.infinity,
      color: CkColors.paper2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          TeamAvatar(
            name: team?.name ?? '??',
            primaryColor: team?.primaryColor,
            logoUrl: team?.logoUrl,
            monogram: team?.logoMonogram,
            size: 20,
            radius: 5,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${team?.name.toUpperCase() ?? 'YOUR TEAM'} · $roleLabel · THIS PHONE',
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.ink2,
              ),
            ),
          ),
          if (state.match.tossDecision != null) ...[
            const SizedBox(width: 8),
            Text(
              'TOSS ✓',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
