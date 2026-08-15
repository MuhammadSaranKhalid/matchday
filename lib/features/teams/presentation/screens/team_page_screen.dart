import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../domain/entities/team.dart';
import '../providers/teams_providers.dart';
import '../utils/team_page_adapter.dart';
import '../widgets/team_page/tp_page_body.dart';

/// Team page screen at `/teams/:teamId` — Clean Architecture entry point.
/// Watches riverpod providers, handles loading and not-found states, adapts
/// domain entities via [buildTeamPageViewFromReal], and renders [TeamPageBody].
class TeamPageScreen extends ConsumerWidget {
  const TeamPageScreen({super.key, required this.teamId});
  final String teamId;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/teams');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final userId = ref.watch(
      currentUserStreamProvider.select((u) => u.value?.id.value),
    );

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (teamAsync) {
        AsyncData(value: final team?) => SafeArea(
          top: false,
          child: _LoadedBody(
            teamId: teamId,
            team: team,
            userId: userId,
            onBack: () => _handleBack(context),
          ),
        ),
        AsyncData(value: null) => _NotFound(onBack: () => _handleBack(context)),
        AsyncError() => _NotFound(onBack: () => _handleBack(context)),
        _ => const Center(
          child: CircularProgressIndicator(color: CkColors.ink),
        ),
      },
    );
  }
}

/// Isolates roster and match stream subscriptions so they do not rebuild the
/// outer scaffold on every stream tick.
class _LoadedBody extends ConsumerWidget {
  const _LoadedBody({
    required this.teamId,
    required this.team,
    required this.userId,
    required this.onBack,
  });

  final String teamId;
  final Team team;
  final String? userId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(teamId));
    final matchesAsync = ref.watch(myMatchesProvider);
    final allMatches = matchesAsync.value ?? const [];
    final matchesForTeam =
        allMatches
            .where(
              (m) => m.teamAId.value == teamId || m.teamBId.value == teamId,
            )
            .toList();

    return TeamPageBody(
      teamId: teamId,
      view: buildTeamPageViewFromReal(
        team: team,
        roster: rosterAsync.value ?? const [],
        matches: matchesForTeam,
        viewerUserId: userId,
      ),
      onBack: onBack,
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
              style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
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
