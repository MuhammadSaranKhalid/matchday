import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/theme/circk_theme.dart';
import '../../../../domain/entities/roster_member.dart';
import '../../../../domain/entities/team.dart';
import '../../../../domain/entities/team_member.dart';
import '../../../../domain/entities/team_relationship.dart';
import '../../../utils/team_display.dart';
import '../../team_role_pill.dart';
import '../team_page_visuals.dart';

class TeamSquadTab extends StatelessWidget {
  const TeamSquadTab({
    super.key,
    required this.teamId,
    required this.team,
    required this.roster,
    required this.relationship,
    this.viewerMembershipId,
  });

  final String teamId;
  final Team team;
  final List<RosterMember> roster;
  final TeamRelationship relationship;
  final String? viewerMembershipId;

  bool get _ownerEmpty =>
      relationship == TeamRelationship.owner &&
      roster.every((entry) => entry.member.id.value == viewerMembershipId);

  @override
  Widget build(BuildContext context) {
    if (team.privacy == TeamPrivacy.private && relationship == TeamRelationship.none) {
      return const TeamPageEmptyTile(
        icon: Icons.lock_outline,
        title: 'Private squad',
        body: 'Only accepted team members can view the full squad.',
      );
    }
    if (roster.isEmpty) {
      return const TeamPageEmptyTile(
        icon: Icons.groups_2_outlined,
        title: 'Squad still being built.',
        body: "Players will appear here once they're added.",
      );
    }
    if (_ownerEmpty) {
      return _OwnerOnboarding(
        teamId: teamId,
        roster: roster,
        primary: parseHexColor(team.primaryColor, fallback: CkColors.ink),
      );
    }

    final leadership = roster.where((entry) {
      final member = entry.member;
      return member.isStaff || member.hasRole(MemberRole.captain);
    }).toList(growable: false);
    final players = roster
        .where((entry) => !leadership.contains(entry))
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      children: [
        const _FilterChips(),
        if (leadership.isNotEmpty) ...[
          TeamPageSectionHeader(
            label: 'Captaincy & management',
            count: leadership.length,
          ),
          for (final entry in leadership)
            _PlayerRow(
              entry: entry,
              isViewer: entry.member.id.value == viewerMembershipId,
            ),
        ],
        if (players.isNotEmpty) ...[
          TeamPageSectionHeader(label: 'Players', count: players.length),
          for (final entry in players)
            _PlayerRow(
              entry: entry,
              isViewer: entry.member.id.value == viewerMembershipId,
            ),
        ],
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();
  static const labels = ['All', 'Batters', 'Bowlers', 'All-rounders', 'Keeper'];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final active = index == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? CkColors.ink : CkColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: active ? null : Border.all(color: CkColors.hairline),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[index],
                style: CkType.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? CkColors.paper : CkColors.ink2,
                ),
              ),
            );
          },
        ),
      );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.entry, required this.isViewer});
  final RosterMember entry;
  final bool isViewer;

  @override
  Widget build(BuildContext context) {
    final member = entry.member;
    final unclaimed = member.playerType == PlayerType.unclaimed;
    return InkWell(
      onTap: !unclaimed && (entry.username?.isNotEmpty ?? false)
          ? () => context.push('/u/${entry.username}')
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                image: entry.profilePhotoUrl?.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(entry.profilePhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: entry.profilePhotoUrl?.isNotEmpty == true
                  ? null
                  : Text(
                      entry.displayName.isEmpty
                          ? '?'
                          : entry.displayName[0].toUpperCase(),
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isViewer) ...[
                        const SizedBox(width: 6),
                        _chip('YOU'),
                      ],
                      if (unclaimed) ...[
                        const SizedBox(width: 6),
                        _chip('UNCLAIMED'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (entry.username?.isNotEmpty ?? false) '@${entry.username}',
                      if (member.jerseyNumber != null) '#${member.jerseyNumber}',
                    ].join(' · '),
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TeamRolePills(roles: member.roles),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.mono(fontSize: 8.5, fontWeight: FontWeight.w700),
        ),
      );
}

class _OwnerOnboarding extends StatelessWidget {
  const _OwnerOnboarding({
    required this.teamId,
    required this.roster,
    required this.primary,
  });
  final String teamId;
  final List<RosterMember> roster;
  final Color primary;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CkColors.line),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_2_outlined, size: 34, color: CkColors.ink),
                const SizedBox(height: 12),
                Text(
                  "It's just you so far.",
                  textAlign: TextAlign.center,
                  style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your squad, add players, and assign roles in Team Management.',
                  textAlign: TextAlign.center,
                  style: CkType.body(fontSize: 12, color: CkColors.ink2, height: 1.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/teams/$teamId/manage'),
                  icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                  label: const Text('Manage Team & Squad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CkColors.ink,
                    foregroundColor: CkColors.paper,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          if (roster.isNotEmpty) ...[
            const TeamPageSectionHeader(label: 'You'),
            _PlayerRow(entry: roster.first, isViewer: true),
          ],
        ],
      );
}
