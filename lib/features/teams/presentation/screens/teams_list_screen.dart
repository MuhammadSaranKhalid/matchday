import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_push_nav.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_membership.dart';
import '../controllers/team_create_controller.dart';
import '../controllers/teams_list_controller.dart';
import '../providers/team_creation_draft_provider.dart';
import '../state/teams_list_state.dart';
import '../utils/team_creation_draft.dart';
import '../widgets/team_create/team_draft_card.dart';
import '../widgets/team_crest.dart';
import '../widgets/team_role_pill.dart';
import '../widgets/teams_list/teams_list_shimmer_skeleton.dart';

class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(teamsListControllerProvider);
    final draft = ref.watch(teamCreationDraftProvider).value;
    final hasDraft = hasTeamCreationDraft(draft);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _nav(context, ref),
            Expanded(
              child: switch (asyncState) {
                AsyncData(value: final state) => RefreshIndicator(
                    color: CkColors.ink,
                    onRefresh:
                        ref.read(teamsListControllerProvider.notifier).refresh,
                    child: _loadedBody(
                      context,
                      ref,
                      state,
                      draft: draft,
                      hasDraft: hasDraft,
                    ),
                  ),
                AsyncError() => _ErrorBody(
                    onRetry:
                        ref.read(teamsListControllerProvider.notifier).refresh,
                  ),
                AsyncLoading() => const TeamsListShimmerSkeleton(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(BuildContext context, WidgetRef ref) {
    return CkPushNav(
      title: 'My Teams',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      action: CkNavPill(
        label: 'Create',
        onTap: () => _openAndRefresh(
          context,
          ref,
          '/teams/create',
        ),
      ),
    );
  }

  Widget _loadedBody(
    BuildContext context,
    WidgetRef ref,
    TeamsListState state, {
    required Map<String, dynamic>? draft,
    required bool hasDraft,
  }) {
    if (state.isEmpty && !hasDraft) {
      return _EmptyBody(
        onCreate: () => _openAndRefresh(
          context,
          ref,
          '/teams/create',
        ),
        onFind: () => _openAndRefresh(
          context,
          ref,
          '/teams/search',
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (hasDraft)
          TeamDraftCard(
            draft: draft!,
            onResume: () => _openAndRefresh(
              context,
              ref,
              '/teams/create',
            ),
            onDiscard: () async {
              await ref
                  .read(teamCreateControllerProvider.notifier)
                  .reset();
              ref.invalidate(teamCreationDraftProvider);
            },
          ),
        if (state.managed.isNotEmpty) ...[
          const _SectionTitle('Teams you manage'),
          for (final membership in state.managed)
            _TeamRow(
              membership: membership,
              onTap: () => _openAndRefresh(
                context,
                ref,
                '/teams/${membership.team.id.value}/manage',
              ),
            ),
        ],
        if (state.playing.isNotEmpty) ...[
          const _SectionTitle('Teams you play for'),
          for (final membership in state.playing)
            _TeamRow(
              membership: membership,
              onTap: () => _openAndRefresh(
                context,
                ref,
                '/teams/${membership.team.id.value}',
              ),
            ),
        ],
        if (state.isEmpty && hasDraft)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: OutlinedButton(
              onPressed: () => _openAndRefresh(
                context,
                ref,
                '/teams/search',
              ),
              child: const Text(
                'Find a team you already play for',
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openAndRefresh(
    BuildContext context,
    WidgetRef ref,
    String location,
  ) async {
    await context.push(location);
    if (!context.mounted) {
      return;
    }

    await ref.read(teamsListControllerProvider.notifier).refresh();
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.onCreate,
    required this.onFind,
  });

  final Future<void> Function() onCreate;
  final Future<void> Function() onFind;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          children: [
            SizedBox(height: constraints.maxHeight * 0.24),
            Text(
              'No teams yet.',
              textAlign: TextAlign.center,
              style: CkType.display(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own side or find a team you already play for.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 14,
                height: 1.45,
                color: CkColors.ink2,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () async {
                await onCreate();
              },
              child: const Text('Create a team'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await onFind();
              },
              child: const Text('Find a team'),
            ),
            const SizedBox(height: 36),
          ],
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const SizedBox(height: 150),
        Text(
          'Could not load teams',
          textAlign: TextAlign.center,
          style: CkType.body(
            fontSize: 14,
            color: CkColors.ink2,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () async {
              await onRetry();
            },
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.membership,
    required this.onTap,
  });

  final TeamMembership membership;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final team = membership.team;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TeamCrest(
                  name: team.name,
                  primaryColor: team.primaryColor,
                  logoUrl: team.logoUrl,
                  monogram: team.logoMonogram,
                  crestKind: team.crestKind,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              team.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CkType.display(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (team.isVerified) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: CkColors.green,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _teamMeta(team),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CkType.mono(
                                fontSize: 10.5,
                                color: CkColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TeamRolePills(
                            roles: membership.member.roles,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: CkColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _teamMeta(Team team) {
    final ground = team.homeGround?.trim();
    if (ground != null && ground.isNotEmpty) {
      return ground;
    }

    return switch (team.type) {
      TeamType.club => 'Club',
      TeamType.village => 'Village team',
      TeamType.casual => 'Casual side',
      TeamType.corporate => 'Corporate team',
      TeamType.school => 'School team',
      TeamType.university => 'University team',
    };
  }
}
