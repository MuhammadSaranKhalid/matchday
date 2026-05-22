import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/ck_screen_scaffold.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../domain/entities/team.dart';
import '../providers/teams_providers.dart';
import '../widgets/team_avatar.dart';

/// The MATCH tab's landing for Phase 1: the user's teams + a create entry.
/// (Matches themselves arrive in F4+.)
class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(myTeamsProvider);

    return CkScreenScaffold(
      title: 'Teams',
      child: switch (teams) {
        AsyncData(:final value) when value.isEmpty => _Empty(),
        AsyncData(:final value) => _List(teams: value),
        AsyncError() => const Center(child: Text('Could not load teams')),
        _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      },
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.teams});
  final List<Team> teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeamIds = teams.map((t) => t.id).toSet();
    final active = (ref.watch(myMatchesProvider).value ?? const <Match>[])
        .where((m) =>
            m.status == MatchStatus.pending || m.status == MatchStatus.accepted)
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (active.isNotEmpty) ...[
                Text('Matches',
                    style: CkType.mono(fontSize: 11, color: CkColors.muted)),
                const SizedBox(height: 8),
                for (final m in active)
                  _RequestCard(match: m, incoming: myTeamIds.contains(m.teamBId)),
                const SizedBox(height: 18),
                Text('Your teams',
                    style: CkType.mono(fontSize: 11, color: CkColors.muted)),
                const SizedBox(height: 8),
              ],
              for (var i = 0; i < teams.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _TeamCard(team: teams[i]),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: CkButton(
            label: 'Create a team',
            icon: const Icon(Icons.add_rounded, size: 20, color: CkColors.paper),
            onPressed: () => context.push('/teams/create'),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.match, required this.incoming});
  final Match match;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final accepted = match.status == MatchStatus.accepted;
    final route = accepted
        ? '/matches/${match.id.value}/start'
        : '/matches/${match.id.value}/request';
    final title = accepted
        ? 'Ready to start'
        : (incoming ? 'Incoming request' : 'Awaiting reply');
    final icon = accepted
        ? Icons.play_circle_outline
        : (incoming ? Icons.mark_email_unread_outlined : Icons.schedule);
    final highlight = accepted || incoming;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight ? CkColors.cream : CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(
                color: highlight ? CkColors.creamBorder : CkColors.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: CkColors.ink2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: CkType.body(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'T${match.format.oversPerInnings} · ${match.format.playersPerTeam}-a-side'
                      '${match.venue != null ? ' · ${match.venue!.ground}' : ''}',
                      style: CkType.mono(fontSize: 10, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: CkColors.soft),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/teams/${team.id.value}'),
      borderRadius: BorderRadius.circular(CkRadii.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            TeamAvatar(name: team.name, primaryColor: team.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      style: CkType.display(fontSize: 16, letterSpacing: -0.01)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      team.type.name[0].toUpperCase() + team.type.name.substring(1),
                      if (team.city != null && team.city!.isNotEmpty) team.city!,
                    ].join(' · '),
                    style: CkType.mono(fontSize: 10, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: CkColors.soft),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 56, color: CkColors.soft),
            const SizedBox(height: 16),
            Text('No teams yet', style: CkType.display(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              'Create a team to build a roster and line up matches.',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 14, color: CkColors.muted),
            ),
            const SizedBox(height: 20),
            CkButton(
              label: 'Create a team',
              expand: false,
              icon: const Icon(Icons.add_rounded, size: 20, color: CkColors.paper),
              onPressed: () => context.push('/teams/create'),
            ),
          ],
        ),
      ),
    );
  }
}
