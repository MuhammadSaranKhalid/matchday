#!/usr/bin/env python3
from pathlib import Path
import re, sys

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()

def path(rel):
    p=ROOT/rel
    if not p.exists():
        raise SystemExit(f'Missing expected file: {rel}')
    return p

def read(rel): return path(rel).read_text()
def write(rel,s): path(rel).write_text(s)

def ensure_import(s, anchor, imp):
    if imp in s: return s
    if anchor not in s: raise SystemExit(f'Import anchor missing for {imp}: {anchor}')
    return s.replace(anchor, anchor+imp, 1)

def replace_required(s, old, new, label):
    if old in s: return s.replace(old,new,1)
    if new in s: return s
    raise SystemExit(f'Expected block not found: {label}')

def replace_all_required(s, old, new, label):
    if old in s: return s.replace(old,new)
    if new in s: return s
    raise SystemExit(f'Expected text not found: {label}')

# ---- Matches: challenges_providers.dart
rel='lib/features/matches/presentation/providers/challenges_providers.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=s.replace("  // `myTeamsProvider` is a Stream; await the first event rather than reading\n  // `.value`, which would be empty on the first frame and silently produce an\n  // empty queue.\n", "  // Memberships are a one-shot scoped read; no permanent team stream is kept.\n")
s=replace_required(s,
"  final teams = await ref.watch(myTeamsProvider.future);\n",
"  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n  final teams = [for (final membership in memberships) membership.team];\n",
'challenges my teams')
write(rel,s)

# completed_match_providers.dart
rel='lib/features/matches/presentation/providers/completed_match_providers.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=replace_required(s,
"  final myTeams = await ref.watch(myTeamsProvider.future);\n  final myTeamIds = myTeams.map((t) => t.id.value).toSet();\n",
"  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n  final myTeamIds = memberships.map((m) => m.team.id.value).toSet();\n",
'completed memberships')
write(rel,s)

# match_detail_provider.dart
rel='lib/features/matches/presentation/providers/match_detail_provider.dart'; s=read(rel)
s=s.replace("import '../../../../core/supabase/supabase_client_provider.dart';\n",'')
s=s.replace("import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=replace_required(s,
"  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;\n  final teams = await ref.watch(myTeamsProvider.future);\n\n  final pvTeams = pvTeamsFromTeams(teams, userId: userId);\n",
"  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n\n  final pvTeams = pvTeamsFromMemberships(memberships);\n",
'match detail memberships')
write(rel,s)

# match_pool_providers.dart
rel='lib/features/matches/presentation/providers/match_pool_providers.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
for label in ['open pool','my pool','my challenges']:
    old="  final myTeams = (await ref.watch(myTeamsProvider.future));\n" if label!='my challenges' else "  final myTeams = await ref.watch(myTeamsProvider.future);\n"
    new="  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n  final myTeams = [for (final membership in memberships) membership.team];\n"
    if old in s: s=s.replace(old,new,1)
    else:
        # Already migrated block may exist more than once; continue.
        pass
s=replace_required(s,
"  final roles = await ref.watch(myTeamRolesProvider.future);\n  return roles.values.any((r) => r.isStaff);\n",
"  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n  return memberships.any((m) => m.relationship.canSendChallenge);\n",
'viewer manages team')
s=s.replace("  // 2026-09-10: was `teams.any((t) => t.isManagedBy(userId))`, which read the\n  // dead `teams.managers` array. Same rule (\"only team managers can post\n  // challenges or apply to play\"), asked of the role ladder.\n", "  // Challenge authority comes from the canonical membership relationship.\n")
write(rel,s)

# match_start_providers.dart
rel='lib/features/matches/presentation/providers/match_start_providers.dart'; s=read(rel)
s=s.replace("import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
write(rel,s)

# matches_board_providers.dart
rel='lib/features/matches/presentation/providers/matches_board_providers.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=replace_all_required(s,
"  final myTeams = await ref.watch(myTeamsProvider.future);\n",
"  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n  final myTeams = [for (final membership in memberships) membership.team];\n",
'matches board memberships')
write(rel,s)

# my_matches_providers.dart
rel='lib/features/matches/presentation/providers/my_matches_providers.dart'; s=read(rel)
s=s.replace("import '../../../teams/domain/entities/team_member.dart';\n", "import '../../../teams/domain/entities/team_relationship.dart';\n")
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=s.replace("  // `myTeamsProvider` is a Stream. Reading `.value` before its first event\n  // yields an empty list, and myTeamIds feeds BOTH the request filters and the\n  // captain/manager role detection below — so on the first frame every row lost\n  // its role line and the request lists came back empty. Await the first event\n  // instead; the provider is still watched, so later emissions recompute this.\n", "  // Current memberships are fetched once and carry both the team and the\n  // canonical multi-role-aware relationship used below.\n")
s=replace_required(s,
"  final teams = await ref.watch(myTeamsProvider.future);\n  final myTeamIds = {for (final t in teams) t.id.value};\n",
"  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n  final teams = [for (final membership in memberships) membership.team];\n  final myTeamIds = {for (final membership in memberships) membership.team.id.value};\n",
'my matches teams')
s=replace_required(s,
"  final teamsById = <String, Team>{for (final t in teams) t.id.value: t};\n  final myRoles = await ref.watch(myTeamRolesProvider.future);\n",
"  final teamsById = <String, Team>{for (final t in teams) t.id.value: t};\n  final myRoles = <String, TeamRelationship>{\n    for (final membership in memberships)\n      membership.team.id.value: membership.relationship,\n  };\n",
'my matches roles')
s=s.replace('Map<String, MemberRole> myRoles','Map<String, TeamRelationship> myRoles')
write(rel,s)

# applicant_detail_screen.dart
rel='lib/features/matches/presentation/screens/applicant_detail_screen.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
write(rel,s)

# challenge_detail_screen.dart
rel='lib/features/matches/presentation/screens/challenge_detail_screen.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/domain/entities/team.dart';\n", "import '../../../teams/domain/entities/team_membership.dart';\n")
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=replace_required(s,
"    final myTeams = ref.watch(myTeamsProvider).value ?? const <Team>[];\n    final viewerIsSender = myTeams.any((t) => t.id == req.fromTeamId);\n",
"    final memberships =\n        ref.watch(currentUserTeamMembershipsProvider).value ??\n            const <TeamMembership>[];\n    final actingTeams = [\n      for (final membership in memberships)\n        if (membership.relationship.canSendChallenge) membership.team,\n    ];\n    final viewerIsSender = actingTeams.any((t) => t.id == req.fromTeamId);\n",
'challenge detail sender teams')
s=replace_required(s,
"    final myAppliedTeamIds = myTeams.map((t) => t.id).toSet();\n",
"    final myAppliedTeamIds = actingTeams.map((t) => t.id).toSet();\n",
'challenge detail applied teams')
s=replace_required(s,
"    final myTeams = ref.read(myTeamsProvider).value ?? const <Team>[];\n    final eligibleTeams =\n        myTeams.where((t) => t.id != req.fromTeamId).toList();\n",
"    final memberships =\n        ref.read(currentUserTeamMembershipsProvider).value ??\n            const <TeamMembership>[];\n    final eligibleTeams = [\n      for (final membership in memberships)\n        if (membership.relationship.canSendChallenge &&\n            membership.team.id != req.fromTeamId)\n          membership.team,\n    ];\n",
'challenge detail eligible teams')
write(rel,s)

# challenge_send_screen.dart
rel='lib/features/matches/presentation/screens/challenge_send_screen.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/domain/entities/team.dart';\n", "import '../../../teams/domain/entities/team_relationship.dart';\n")
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=re.sub(r"/// Per-row role on the team-pick step\.[\s\S]*?enum _MyTeamRole \{ captain, viceCaptain, manager \}\n\n", "", s, count=1)
s=replace_required(s,
"    final mineAsync = ref.watch(myTeamsProvider);\n",
"    final mineAsync = ref.watch(currentUserTeamMembershipsProvider);\n",
'challenge send memberships provider')
s=replace_required(s,
"      data: (mine) {\n        if (mine.isEmpty) {\n",
"      data: (memberships) {\n        final mine = memberships\n            .where((membership) => membership.relationship.canSendChallenge)\n            .toList(growable: false);\n        if (mine.isEmpty) {\n",
'challenge send eligible memberships')
s=s.replace("              'You need to manage a team to issue a challenge. Create or '\n              'join one first.',", "              'You need to own or manage a team to issue a challenge. Create '\n              'one or ask an owner to appoint you as manager.',")
s=replace_required(s,
"        if (mine.length == 1) {\n          onSingle(mine.single);\n",
"        if (mine.length == 1) {\n          onSingle(mine.single.team);\n",
'challenge send single')
s=s.replace("                'You captain ${_countLabel(mine.length)}. Issue the challenge '\n                \"as one of them — your XI options come from this squad later.\",", "                'You manage ${_countLabel(mine.length)}. Issue the challenge '\n                \"as one of them — your XI options come from this squad later.\",")
s=replace_required(s,
"            for (final t in mine)\n              Padding(\n                padding: const EdgeInsets.only(bottom: 8),\n                child: _MyTeamRow(\n                  team: t,\n                  role: _MyTeamRole.captain,\n                  disabledNote: null,\n                  selected: selected?.id == t.id,\n                  onTap: () => onPick(t),\n                ),\n              ),\n",
"            for (final membership in mine)\n              Padding(\n                padding: const EdgeInsets.only(bottom: 8),\n                child: _MyTeamRow(\n                  team: membership.team,\n                  role: membership.relationship,\n                  disabledNote: null,\n                  selected: selected?.id == membership.team.id,\n                  onTap: () => onPick(membership.team),\n                ),\n              ),\n",
'challenge send team rows')
s=s.replace("                  \"Manager-only teams can’t initiate challenges. Get the \"\n                  'captain to send it, or ask them to promote you.',", "                  \"Captain-only membership can’t initiate challenges. The team \"\n                  'owner or a manager can send one.',")
s=s.replace('final _MyTeamRole role;','final TeamRelationship role;')
s=s.replace('final _MyTeamRole role;','final TeamRelationship role;')
s=replace_required(s,
"    final (label, bg, fg) = switch (role) {\n      _MyTeamRole.captain => ('CAPTAIN', CkColors.red, CkColors.paper),\n      _MyTeamRole.viceCaptain =>\n        ('VICE-CAPTAIN', CkColors.cream, CkColors.ink2),\n      _MyTeamRole.manager => ('MANAGER', CkColors.paper2, CkColors.ink2),\n    };\n",
"    final (label, bg, fg) = switch (role) {\n      TeamRelationship.owner => ('OWNER', CkColors.red, CkColors.paper),\n      TeamRelationship.manager =>\n        ('MANAGER', CkColors.paper2, CkColors.ink2),\n      TeamRelationship.captain =>\n        ('CAPTAIN', CkColors.cream, CkColors.ink2),\n      TeamRelationship.player =>\n        ('PLAYER', CkColors.paper2, CkColors.ink2),\n      TeamRelationship.none => ('MEMBER', CkColors.paper2, CkColors.ink2),\n    };\n",
'challenge send role pill')
s=replace_required(s,
"    final all = ref.watch(allTeamsProvider).value ?? const <Team>[];\n",
"    final all =\n        ref.watch(discoverableTeamsProvider(query)).value ?? const <Team>[];\n",
'challenge send discoverable teams')
write(rel,s)

# innings_break_screen.dart
rel='lib/features/matches/presentation/screens/innings_break_screen.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/domain/entities/roster_member.dart';\n", "import '../../../teams/domain/entities/team_membership.dart';\n")
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=replace_required(s,
"    final myRoles = ref.watch(myTeamRolesProvider).value ?? const {};\n    final canSetup = battingTeam != null &&\n        currentUserId != null &&\n        (myRoles[battingTeamId.value]?.hasMatchAuthority ?? false);\n",
"    final memberships =\n        ref.watch(currentUserTeamMembershipsProvider).value ??\n            const <TeamMembership>[];\n    final canSetup = battingTeam != null &&\n        currentUserId != null &&\n        memberships.any(\n          (membership) =>\n              membership.team.id == battingTeamId &&\n              membership.relationship.hasMatchAuthority,\n        );\n",
'innings break authority')
write(rel,s)

# pv_v2_map.dart
rel='lib/features/matches/presentation/widgets/match_detail/pv_v2_map.dart'; s=read(rel)
s=s.replace("import '../../../../teams/domain/entities/team_relationship.dart';\n", "import '../../../../teams/domain/entities/team_membership.dart';\nimport '../../../../teams/domain/entities/team_relationship.dart';\n")
pattern=r"/// Map the user's teams[\s\S]*?List<PvTeam> pvTeamsFromTeams\(List<Team> teams, \{required String\? userId\}\) \{[\s\S]*?\n\}\n\nString _teamTypeLabel"
replacement="""/// Map the user's current memberships into the compact team cards.\n/// Authority comes from [TeamMembership.relationship], never from fields on\n/// the team profile itself.\nList<PvTeam> pvTeamsFromMemberships(List<TeamMembership> memberships) {\n  return [\n    for (final membership in memberships)\n      PvTeam(\n        id: membership.team.id.value,\n        crest: crestFromTeam(membership.team),\n        role: switch (membership.relationship) {\n          TeamRelationship.owner => 'owner',\n          TeamRelationship.manager => 'manager',\n          TeamRelationship.captain => 'captain',\n          TeamRelationship.player => 'player',\n          TeamRelationship.none => 'player',\n        },\n        subtitle: [\n          _teamTypeLabel(membership.team.type),\n          if (membership.team.city != null &&\n              membership.team.city!.isNotEmpty)\n            membership.team.city!,\n        ].join(' · '),\n      ),\n  ];\n}\n\nString _teamTypeLabel"""
s2,n=re.subn(pattern,replacement,s,count=1)
if n!=1 and 'pvTeamsFromMemberships' not in s: raise SystemExit('pv_v2_map block not found')
s=s2
write(rel,s)

# messages chat details roster provider import
rel='lib/features/messages/presentation/screens/chat_details_screen.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
write(rel,s)

# notifications: load specific team instead of global all teams
rel='lib/features/notifications/presentation/screens/notifications_screen.dart'; s=read(rel)
s=replace_required(s,
"    final allTeams = ref.watch(allTeamsProvider).value ?? const <Team>[];\n    final fromTeam = allTeams.cast<Team?>().firstWhere(\n      (t) => t!.id.value == _fromTeamId,\n      orElse: () => null,\n    );\n",
"    final fromTeam = _fromTeamId.isEmpty\n        ? null\n        : ref.watch(teamProvider(_fromTeamId)).value;\n",
'notification specific team')
write(rel,s)

# profile: replace old affiliation entity/provider with TeamMembership
rel='lib/features/profile/presentation/widgets/profile_view.dart'; s=read(rel)
s=s.replace("import '../../../teams/domain/entities/user_team_affiliation.dart';\n", "import '../../../teams/domain/entities/team_membership.dart';\nimport '../../../teams/domain/entities/team_member.dart';\n")
s=s.replace("import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=s.replace('userAffiliatedTeamsProvider(userId)','userTeamMembershipsProvider(userId)')
old_chip="""class _ChipStrip extends StatelessWidget {
  const _ChipStrip({
    required this.label,
    required this.teams,
    required this.main,
  });

  final String label;
  final List<UserTeamAffiliation> teams;
  final bool main;

  Color _parsePrimaryColor(String? hex) {
    if (hex == null || hex.isEmpty) return CkColors.ink;
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return CkColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: teams.map((t) {
              final crestBg = _parsePrimaryColor(t.primaryColor);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => context.push('/teams/${t.teamId}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: main ? CkColors.ink : CkColors.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: main ? null : Border.all(color: CkColors.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Crest / Monogram / Logo
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: crestBg,
                            shape: BoxShape.circle,
                          ),
                          child: t.logoUrl != null && t.logoUrl!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: t.logoUrl!,
                                    width: 18,
                                    height: 18,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Text(
                                      t.logoMonogram,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  t.logoMonogram,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.teamName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: main ? CkColors.paper : CkColors.ink,
                          ),
                        ),
                        if (!main && t.role != 'PLAYER') ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${t.role})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: main ? CkColors.paper.withValues(alpha: 0.7) : CkColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
"""
new_chip="""class _ChipStrip extends StatelessWidget {
  const _ChipStrip({
    required this.label,
    required this.teams,
    required this.main,
  });

  final String label;
  final List<TeamMembership> teams;
  final bool main;

  Color _parsePrimaryColor(String? hex) {
    if (hex == null || hex.isEmpty) return CkColors.ink;
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return CkColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: teams.map((membership) {
              final team = membership.team;
              final mono = team.logoMonogram ??
                  (team.name.isEmpty ? 'T' : team.name[0].toUpperCase());
              final crestBg = _parsePrimaryColor(team.primaryColor);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => context.push('/teams/${team.id.value}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: main ? CkColors.ink : CkColors.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: main ? null : Border.all(color: CkColors.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: crestBg,
                            shape: BoxShape.circle,
                          ),
                          child: team.logoUrl != null && team.logoUrl!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: team.logoUrl!,
                                    width: 18,
                                    height: 18,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Text(
                                      mono,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  mono,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          team.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: main ? CkColors.paper : CkColors.ink,
                          ),
                        ),
                        if (!main && membership.member.topRole != MemberRole.player) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${membership.member.topRole.label})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: main ? CkColors.paper.withValues(alpha: 0.7) : CkColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
"""
if old_chip in s:
    s=s.replace(old_chip,new_chip,1)
elif 'final List<TeamMembership> teams;' not in s:
    raise SystemExit('profile chip strip block not found')
write(rel,s)

# tournaments providers
rel='lib/features/tournaments/presentation/providers/tournaments_providers.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=replace_required(s,
"  final teams = await ref.watch(myTeamsProvider.future);\n  final ids = teams.map((t) => t.id.value).toList();\n",
"  final memberships =\n      await ref.watch(currentUserTeamMembershipsProvider.future);\n  final ids = memberships\n      .where((m) => m.relationship.canRegisterForTournament)\n      .map((m) => m.team.id.value)\n      .toList(growable: false);\n",
'my playing tournaments')
write(rel,s)

# tournament team registration sheet
rel='lib/features/tournaments/presentation/screens/team_registration_sheet.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=replace_required(s,
"    // Only teams the viewer actually runs. `myTeamsProvider` includes teams\n    // they merely play for, while `tournament_teams_insert_manager` demands\n    // is_team_manager — so before this filter (2026-09-10) a squad player\n    // could pick their team in the wizard and get a raw RLS denial at submit.\n    final myRoles = ref.watch(myTeamRolesProvider).value ?? const {};\n    final myTeamsAsync = ref.watch(myTeamsProvider).whenData(\n          (teams) => teams\n              .where((t) => myRoles[t.id.value]?.isStaff ?? false)\n              .toList(),\n        );\n",
"    // Tournament registration is a staff capability. Memberships carry the\n    // canonical relationship, so player/captain-only memberships never enter\n    // the selectable team list.\n    final myTeamsAsync = ref.watch(currentUserTeamMembershipsProvider).whenData(\n          (memberships) => memberships\n              .where((m) => m.relationship.canRegisterForTournament)\n              .map((m) => m.team)\n              .toList(growable: false),\n        );\n",
'tournament registration teams')
write(rel,s)

# tournament registration status
rel='lib/features/tournaments/presentation/screens/tournament_registration_status_screen.dart'; s=read(rel)
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n")
s=s.replace('final myTeamsAsync = ref.watch(myTeamsProvider);','final membershipsAsync = ref.watch(currentUserTeamMembershipsProvider);')
s=replace_required(s,
"              final myTeamIds = myTeamsAsync.value?.map((t) => t.id.value).toSet() ?? {};\n",
"              final myTeamIds = membershipsAsync.value\n                      ?.where((m) => m.relationship.canRegisterForTournament)\n                      .map((m) => m.team.id.value)\n                      .toSet() ??\n                  <String>{};\n",
'tournament status memberships')
write(rel,s)

# tournament overview
rel='lib/features/tournaments/presentation/widgets/tournament_overview_tab.dart'; s=read(rel)
s=ensure_import(s, "import '../../../../core/theme/circk_theme.dart';\n", "import '../../../teams/domain/entities/team_membership.dart';\n")
s=ensure_import(s, "import '../../../teams/presentation/providers/teams_providers.dart';\n", "import '../../../teams/presentation/providers/team_membership_providers.dart';\n") if "import '../../../teams/presentation/providers/teams_providers.dart';\n" in s else s
# Some versions import via a different relative depth; add next to any teams provider import if needed.
if 'team_membership_providers.dart' not in s:
    m=re.search(r"import '([^']*teams/presentation/providers/teams_providers\.dart)';\n",s)
    if not m: raise SystemExit('overview teams provider import not found')
    imp=m.group(0); newimp=imp.replace('teams_providers.dart','team_membership_providers.dart')
    s=s.replace(imp,imp+newimp,1)
s=replace_required(s,
"    final myTeams = ref.watch(myTeamsProvider).value ?? const [];\n    final myReg = regs\n        .where((r) => myTeams.any((t) => t.id.value == r.teamId))\n        .firstOrNull;\n",
"    final memberships = ref.watch(currentUserTeamMembershipsProvider).value ??\n        const <TeamMembership>[];\n    final myReg = regs\n        .where(\n          (r) => memberships.any(\n            (m) =>\n                m.relationship.canRegisterForTournament &&\n                m.team.id.value == r.teamId,\n          ),\n        )\n        .firstOrNull;\n",
'tournament overview memberships')
write(rel,s)

# Global legacy identifier guard for the files this migration owns.
owned = [
'lib/features/matches/presentation/providers/challenges_providers.dart',
'lib/features/matches/presentation/providers/completed_match_providers.dart',
'lib/features/matches/presentation/providers/match_detail_provider.dart',
'lib/features/matches/presentation/providers/match_pool_providers.dart',
'lib/features/matches/presentation/providers/match_start_providers.dart',
'lib/features/matches/presentation/providers/matches_board_providers.dart',
'lib/features/matches/presentation/providers/my_matches_providers.dart',
'lib/features/matches/presentation/screens/applicant_detail_screen.dart',
'lib/features/matches/presentation/screens/challenge_detail_screen.dart',
'lib/features/matches/presentation/screens/challenge_send_screen.dart',
'lib/features/matches/presentation/screens/innings_break_screen.dart',
'lib/features/matches/presentation/widgets/match_detail/pv_v2_map.dart',
'lib/features/messages/presentation/screens/chat_details_screen.dart',
'lib/features/notifications/presentation/screens/notifications_screen.dart',
'lib/features/profile/presentation/widgets/profile_view.dart',
'lib/features/tournaments/presentation/providers/tournaments_providers.dart',
'lib/features/tournaments/presentation/screens/team_registration_sheet.dart',
'lib/features/tournaments/presentation/screens/tournament_registration_status_screen.dart',
'lib/features/tournaments/presentation/widgets/tournament_overview_tab.dart',
]
legacy=['myTeamsProvider','myTeamRolesProvider','allTeamsProvider','userAffiliatedTeamsProvider','UserTeamAffiliation','relationshipFor(','_MyTeamRole']
hits=[]
for rel in owned:
    txt=read(rel)
    for token in legacy:
        if token in txt: hits.append(f'{rel}: {token}')
if hits:
    raise SystemExit('Legacy references remain:\n'+'\n'.join(hits))

print('Team API consumer migration applied successfully.')
print(f'Updated {len(owned)} downstream files.')
print('Now run: dart run build_runner build && flutter analyze lib/')
