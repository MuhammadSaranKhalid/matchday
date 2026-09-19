import 'package:flutter/material.dart';

import '../../../../../../core/theme/circk_theme.dart';
import '../../../../domain/entities/roster_member.dart';
import '../../../../domain/entities/team.dart';
import '../../../../domain/entities/team_member.dart';
import '../team_page_visuals.dart';

class TeamAboutTab extends StatelessWidget {
  const TeamAboutTab({
    super.key,
    required this.team,
    required this.roster,
  });

  final Team team;
  final List<RosterMember> roster;

  @override
  Widget build(BuildContext context) {
    final staff = roster.where((entry) => entry.member.isStaff).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        if (team.description?.trim().isNotEmpty ?? false) ...[
          Text(
            'ABOUT',
            style: teamPageMono(),
          ),
          const SizedBox(height: 8),
          Text(
            team.description!,
            style: CkType.body(fontSize: 13, color: CkColors.ink2, height: 1.5),
          ),
          const SizedBox(height: 22),
        ],
        Text('DETAILS', style: teamPageMono()),
        const SizedBox(height: 8),
        _DetailsCard(
          rows: [
            ('Type', team.type.wire),
            if (team.foundedYear != null) ('Founded', '${team.foundedYear}'),
            if (team.city?.isNotEmpty ?? false) ('City', team.city!),
            if (team.homeGround?.isNotEmpty ?? false) ('Home ground', team.homeGround!),
            ('Privacy', team.privacy.wire),
            ('Squad capacity', '${team.maxSquadSize}'),
          ],
        ),
        if (staff.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('TEAM MANAGEMENT', style: teamPageMono()),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < staff.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: CkColors.hairline),
                  ListTile(
                    dense: true,
                    title: Text(
                      staff[i].displayName,
                      style: CkType.display(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      staff[i].member.hasRole(MemberRole.owner) ? 'Owner' : 'Manager',
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: CkColors.hairline),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                child: Row(
                  children: [
                    SizedBox(
                      width: 108,
                      child: Text(
                        rows[i].$1,
                        style: CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rows[i].$2,
                        style: CkType.body(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}
