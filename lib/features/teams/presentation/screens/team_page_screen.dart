import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../providers/teams_providers.dart';
import '../state/team_page_real_data_adapter.dart';
import '../widgets/team_page/tp_body.dart';

/// Team page at `/teams/:teamId` — faithful realisation of the matchday
/// design's 10-case Team Page. The same `TeamPageBody` handles every
/// viewer × state combination; only the [TeamPageView] shape differs.
class TeamPageScreen extends ConsumerWidget {
  const TeamPageScreen({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final rosterAsync = ref.watch(rosterProvider(teamId));
    final matchesAsync = ref.watch(myMatchesProvider);
    final userId =
        ref.watch(currentUserStreamProvider).value?.id.value;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (teamAsync) {
        AsyncData(value: final team?) => SafeArea(
            top: false,
            child: TeamPageBody(
              view: buildTeamPageViewFromReal(
                team: team,
                roster: rosterAsync.value ?? const [],
                matches: matchesAsync.value ?? const [],
                viewerUserId: userId,
              ),
              onBack: () => context.pop(),
            ),
          ),
        AsyncData(value: null) => _NotFound(onBack: () => context.pop()),
        AsyncError() => _NotFound(onBack: () => context.pop()),
        _ => const Center(
            child: CircularProgressIndicator(color: CkColors.ink)),
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Team not found',
              style: CkType.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Go back',
                  style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
