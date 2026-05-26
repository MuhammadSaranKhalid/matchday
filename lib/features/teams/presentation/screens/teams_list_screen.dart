import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/teams_list_controller.dart';
import '../state/my_teams_real_data_adapter.dart';
import '../state/my_teams_view.dart';
import '../widgets/my_teams/my_teams_body.dart';

/// "My teams" — the faithful Flutter realisation of the matchday v2 design
/// (`design/screens/MyTeams.jsx`). The screen renders the [MyTeamsBody]
/// driven by a [MyTeamsView] built from real provider data via
/// [buildMyTeamsViewFromReal]. Sections only appear when their data is
/// non-empty, so the same widget tree covers every state — empty, first
/// team, active player, today live, captain, manager, archived, …
class TeamsListScreen extends ConsumerStatefulWidget {
  const TeamsListScreen({super.key});

  @override
  ConsumerState<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends ConsumerState<TeamsListScreen> {
  MyTeamsFilter _filter = MyTeamsFilter.all;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(teamsListControllerProvider);
    final userId =
        ref.watch(currentUserStreamProvider).value?.id.value ?? '';

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: switch (view) {
          AsyncData(:final value) => RefreshIndicator(
              color: CkColors.ink,
              onRefresh: () =>
                  ref.read(teamsListControllerProvider.notifier).refresh(),
              child: MyTeamsBody(
                view: _applyFilter(
                  buildMyTeamsViewFromReal(
                    source: value,
                    userId: userId,
                    onAddPlayers: (teamId) =>
                        context.push('/teams/$teamId/manage'),
                  ),
                ),
                onBack: () => context.pop(),
                onSelectFilter: (f) => setState(() => _filter = f),
                onCreate: () => context.push('/teams/create'),
              ),
            ),
          AsyncError() => _ErrorState(onBack: () => context.pop()),
          _ => const Center(
              child: CircularProgressIndicator(color: CkColors.ink),
            ),
        },
      ),
    );
  }

  /// Layer the local filter selection on top of the base real-data view.
  /// The base view stays pure; this transformation is purely presentation.
  MyTeamsView _applyFilter(MyTeamsView base) => MyTeamsView(
        subtitle: base.subtitle,
        isEmpty: base.isEmpty,
        needsYou: base.needsYou,
        today: base.today,
        invites: base.invites,
        teams: _filterTeams(base.teams, _filter),
        following: _filter == MyTeamsFilter.following ||
                _filter == MyTeamsFilter.all
            ? base.following
            : const [],
        suggested: base.suggested,
        suggestedTitle: base.suggestedTitle,
        showCreateNudge: base.showCreateNudge,
        activeFilter: _filter,
      );

  TeamGroups _filterTeams(TeamGroups t, MyTeamsFilter f) {
    switch (f) {
      case MyTeamsFilter.all:
        return t;
      case MyTeamsFilter.playing:
        return TeamGroups(captain: t.captain, vc: t.vc, playing: t.playing);
      case MyTeamsFilter.managing:
        return TeamGroups(manage: t.manage, draft: t.draft, scorer: t.scorer);
      case MyTeamsFilter.following:
        // "following" lives on MyTeamsView, not TeamGroups. Suppress all
        // bucket sections so only Following is visible.
        return const TeamGroups();
      case MyTeamsFilter.archived:
        return TeamGroups(archived: t.archived);
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not load teams',
            style: CkType.body(fontSize: 14, color: CkColors.ink2),
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
    );
  }
}
