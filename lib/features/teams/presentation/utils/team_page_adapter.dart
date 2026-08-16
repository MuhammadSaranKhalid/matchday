import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_relationship.dart';
import '../widgets/team_page/tp_view.dart';
import 'team_display.dart';

/// Real-data adapter — pure function turning real-data (Team + roster +
/// matches + viewer id) into a [TeamPageView] for the Team Page presentation.
TeamPageView buildTeamPageViewFromReal({
  required Team team,
  required List<RosterMember> roster,
  required List<Match> matches,
  required String? viewerUserId,
}) {
  final viewer = deriveViewer(team, roster, viewerUserId);

  // Resolve userId → display name from the roster
  final nameByUserId = <String, String>{
    for (final r in roster)
      if (r.member.playerType == PlayerType.claimed)
        r.member.playerId: r.displayName,
  };
  String resolveName(String uid) => nameByUserId[uid] ?? _short(uid);

  // Map roster → TpPlayerRow list.
  final squad = <TpPlayerRow>[];
  String? viewerPlayerId;
  for (final r in roster) {
    final m = r.member;
    if (viewerUserId != null &&
        m.playerType == PlayerType.claimed &&
        m.playerId == viewerUserId) {
      viewerPlayerId = m.id.value;
    }
    squad.add(
      TpPlayerRow(
        id: m.id.value,
        name: r.displayName,
        role: mapRole(m.role),
        jersey: m.jerseyNumber ?? 0,
        bat: '—',
        bowl: '—',
        photoUrl: r.profilePhotoUrl,
        username: r.username,
        status:
            m.playerType == PlayerType.unclaimed
                ? TpPlayerStatus.unclaimed
                : TpPlayerStatus.app,
      ),
    );
  }

  // Partition matches: pending/accepted → upcoming, completed → recent.
  final upcoming = <TpUpcomingMatch>[];
  final recent = <TpRecentMatch>[];
  TpLiveCard? live;
  for (final match in matches) {
    if (match.teamAId != team.id && match.teamBId != team.id) continue;
    switch (match.status) {
      case MatchStatus.live:
        live = TpLiveCard(
          ctx: _matchCtx(match),
          us: team.name,
          them: 'Opponent',
          usScore: 'Live now',
          themScore: '—',
          note: 'Tap below to watch.',
        );
      case MatchStatus.pending:
      case MatchStatus.accepted:
        upcoming.add(
          TpUpcomingMatch(
            dateDay: 'Soon',
            dateTime: '—',
            round: match.status.name.toUpperCase(),
            venue: match.venue?.ground ?? '',
            vs: 'Opponent',
          ),
        );
      case MatchStatus.completed:
        recent.add(
          TpRecentMatch(
            date: 'Recent',
            us:
                team.name.length > 8
                    ? '${team.name.substring(0, 8)}…'
                    : team.name,
            them: 'Opponent',
            result: TpFormResult.t,
            summary: match.resultDescription ?? 'Result pending',
          ),
        );
      default:
        break;
    }
  }

  // Owner first-team detection
  final firstTeam =
      viewer == TeamPageViewer.owner &&
      roster.where((r) => r.member.playerType == PlayerType.claimed).length <=
          1 &&
      matches.isEmpty;

  final tpTeam = TpTeam(
    name: team.name,
    mono: team.logoMonogram?.toUpperCase() ?? teamMonogram(team.name),
    type: team.type.wire,
    city: team.city ?? '',
    area: '',
    primary: parseHexColor(team.primaryColor, fallback: CkColors.ink),
    privacy: team.privacy.wire,
    tagline: team.tagline,
    logoUrl: team.logoUrl,
    verified: false,
    squad: squad,
    upcoming: upcoming,
    recent: recent,
    live: live,
    about: team.description ?? '',
    details: buildDetails(team),
    managers: [
      TpManagerRow(name: resolveName(team.ownerId), role: 'Owner'),
      for (final m in team.managers)
        if (m != team.ownerId)
          TpManagerRow(name: resolveName(m), role: 'Manager'),
    ],
  );

  final tabs = tabsFor(viewer, tpTeam);
  return TeamPageView(
    viewer: viewer,
    team: tpTeam,
    tabs: tabs,
    initialTab: tabs.first,
    viewerPlayerId: viewerPlayerId,
    banner:
        firstTeam
            ? TpInfoBanner(
              tone: TpInfoBannerTone.green,
              title: '${team.name} is live.',
              body: "You're the owner. Next: build your squad in Team Management.",
              cta: 'Manage team',
              icon: Icons.check_rounded,
            )
            : null,
    badges:
        live != null
            ? const [
              TpHeroBadge(
                label: 'Playing now',
                tone: TpHeroBadgeTone.red,
                pulse: true,
              ),
            ]
            : const [],
  );
}

TeamPageViewer deriveViewer(
  Team team,
  List<RosterMember> roster,
  String? userId,
) {
  MemberRole? mineRole;
  for (final r in roster) {
    if (r.member.playerType == PlayerType.claimed &&
        r.member.playerId == userId) {
      mineRole = r.member.role;
      break;
    }
  }
  switch (team.relationshipFor(userId: userId, rosterRole: mineRole)) {
    case TeamRelationship.owner:
    case TeamRelationship.manager:
      return TeamPageViewer.owner;
    case TeamRelationship.captain:
      return TeamPageViewer.captain;
    case TeamRelationship.viceCaptain:
    case TeamRelationship.wicketKeeper:
    case TeamRelationship.player:
      return TeamPageViewer.player;
    case TeamRelationship.none:
      return team.privacy == TeamPrivacy.private
          ? TeamPageViewer.strangerPrivate
          : TeamPageViewer.stranger;
  }
}

List<TeamPageTab> tabsFor(TeamPageViewer viewer, TpTeam team) {
  if (team.archived != null) {
    return [
      TeamPageTab.posts,
      TeamPageTab.stats,
      TeamPageTab.recent,
      TeamPageTab.about,
    ];
  }
  return [
    TeamPageTab.posts,
    TeamPageTab.squad,
    TeamPageTab.matches,
    TeamPageTab.stats,
    TeamPageTab.about,
  ];
}

TpPlayerRole mapRole(MemberRole r) {
  switch (r) {
    case MemberRole.captain:
      return TpPlayerRole.captain;
    case MemberRole.viceCaptain:
      return TpPlayerRole.viceCaptain;
    case MemberRole.wicketKeeper:
      return TpPlayerRole.wicketKeeper;
    case MemberRole.player:
      return TpPlayerRole.player;
  }
}

List<TpDetailRow> buildDetails(Team team) => [
  TpDetailRow('Type', team.type.wire),
  if (team.foundedYear != null) TpDetailRow('Founded', '${team.foundedYear}'),
  if (team.city != null && team.city!.isNotEmpty)
    TpDetailRow('City', team.city!),
  if (team.homeGround != null && team.homeGround!.isNotEmpty)
    TpDetailRow('Home ground', team.homeGround!),
  TpDetailRow('Privacy', team.privacy.wire),
];

String _matchCtx(Match m) {
  if (m.format.oversPerInnings > 0) return '${m.format.oversPerInnings} ov';
  return 'Live';
}

String _short(String uid) {
  if (uid.length <= 8) return uid;
  return uid.substring(0, 8);
}
