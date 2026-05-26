// Pure function: turn real-data (Team + roster + matches + viewer id) into a
// `TeamPageView` for the new Team Page presentation. Mirrors the shape the
// JSX CASES.* fixtures use.
//
// Today's reality — many sections have no backend signal and stay empty:
// W/L `record`, `form` (last-8), `stats`, `tournament` block, `actionQueue`
// (renders the "Inbox clear ✓" empty state). Hero / Squad / Matches /
// About populate from real data; the screen still looks intentional thanks
// to the body's section-level short-circuits.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../widgets/team_avatar.dart';
import '../widgets/team_page/tp_view.dart';

/// Adapter from real-data sources to the new presentation shape.
TeamPageView buildTeamPageViewFromReal({
  required Team team,
  required List<RosterMember> roster,
  required List<Match> matches,
  required String? viewerUserId,
}) {
  final viewer = _deriveViewer(team, roster, viewerUserId);

  // Map roster → TpPlayerRow list. The viewer's own row picks up the YOU pill
  // via `viewerPlayerId == row.id`.
  final squad = <TpPlayerRow>[];
  String? viewerPlayerId;
  for (final r in roster) {
    final m = r.member;
    if (viewerUserId != null &&
        m.playerType == PlayerType.claimed &&
        m.playerId == viewerUserId) {
      viewerPlayerId = m.id.value;
    }
    squad.add(TpPlayerRow(
      id: m.id.value,
      name: r.displayName,
      role: _mapRole(m.role),
      jersey: m.jerseyNumber ?? 0,
      bat: '—',
      bowl: '—',
      status: m.playerType == PlayerType.unclaimed
          ? TpPlayerStatus.unclaimed
          : TpPlayerStatus.app,
    ));
  }

  // Partition matches: pending/accepted → upcoming, completed → recent.
  // Won/lost data isn't stored yet → all recent entries render as "tie"
  // pills with a placeholder summary.
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
        upcoming.add(TpUpcomingMatch(
          dateDay: 'Soon',
          dateTime: '—',
          round: match.status.name.toUpperCase(),
          venue: match.venue?.ground ?? '',
          vs: 'Opponent',
        ));
      case MatchStatus.completed:
        recent.add(TpRecentMatch(
          date: 'Recent',
          us: team.name.length > 8 ? '${team.name.substring(0, 8)}…' : team.name,
          them: 'Opponent',
          result: TpFormResult.t,
          summary: match.resultDescription ?? 'Result pending',
        ));
      default:
        break;
    }
  }

  // Owner first-team detection (matches the My Teams adapter rule).
  final firstTeam = viewer == TeamPageViewer.owner &&
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
    verified: false, // no backend signal yet
    squad: squad,
    upcoming: upcoming,
    recent: recent,
    live: live,
    about: team.description ?? '',
    details: _buildDetails(team),
    managers: [
      TpManagerRow(name: _short(team.ownerId), role: 'Owner'),
      for (final m in team.managers)
        if (m != team.ownerId) TpManagerRow(name: _short(m), role: 'Manager'),
    ],
  );

  final tabs = _tabsFor(viewer, tpTeam);
  return TeamPageView(
    viewer: viewer,
    team: tpTeam,
    tabs: tabs,
    initialTab: tabs.first,
    viewerPlayerId: viewerPlayerId,
    banner: firstTeam
        ? TpInfoBanner(
            tone: TpInfoBannerTone.green,
            title: '${team.name} is live.',
            body: "You're the owner. Next: add your squad.",
            cta: 'Add players',
            icon: Icons.check_rounded,
          )
        : null,
    badges: live != null
        ? const [TpHeroBadge(label: 'Playing now', tone: TpHeroBadgeTone.red, pulse: true)]
        : const [],
  );
}

TeamPageViewer _deriveViewer(
    Team team, List<RosterMember> roster, String? userId) {
  if (userId == null) {
    return team.privacy == TeamPrivacy.private
        ? TeamPageViewer.strangerPrivate
        : TeamPageViewer.stranger;
  }
  if (team.ownerId == userId || team.managers.contains(userId)) {
    return TeamPageViewer.owner;
  }
  final mine = roster.firstWhere(
    (r) =>
        r.member.playerType == PlayerType.claimed &&
        r.member.playerId == userId,
    orElse: () => const _NoMember(),
  );
  if (mine is _NoMember) {
    return team.privacy == TeamPrivacy.private
        ? TeamPageViewer.strangerPrivate
        : TeamPageViewer.stranger;
  }
  if (mine.member.role == MemberRole.captain) return TeamPageViewer.captain;
  return TeamPageViewer.player;
}

List<TeamPageTab> _tabsFor(TeamPageViewer viewer, TpTeam team) {
  if (team.archived != null) {
    return [TeamPageTab.stats, TeamPageTab.recent, TeamPageTab.about];
  }
  switch (viewer) {
    case TeamPageViewer.owner:
      return [
        TeamPageTab.squad,
        TeamPageTab.matches,
        TeamPageTab.stats,
        TeamPageTab.manage,
        TeamPageTab.about,
      ];
    case TeamPageViewer.captain:
    case TeamPageViewer.player:
    case TeamPageViewer.following:
    case TeamPageViewer.stranger:
    case TeamPageViewer.strangerPrivate:
      return [
        TeamPageTab.squad,
        TeamPageTab.matches,
        TeamPageTab.stats,
        TeamPageTab.about,
      ];
  }
}

TpPlayerRole _mapRole(MemberRole r) {
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

List<TpDetailRow> _buildDetails(Team team) => [
      TpDetailRow('Type', team.type.wire),
      if (team.foundedYear != null)
        TpDetailRow('Founded', '${team.foundedYear}'),
      if (team.city != null && team.city!.isNotEmpty)
        TpDetailRow('City', team.city!),
      if (team.homeGround != null && team.homeGround!.isNotEmpty)
        TpDetailRow('Home ground', team.homeGround!),
      TpDetailRow('Privacy', team.privacy.wire),
      TpDetailRow('Members', '${team.managers.length + 1} listed'),
    ];

String _matchCtx(Match m) =>
    'T${m.format.oversPerInnings} · ${m.format.playersPerTeam}-A-SIDE';

/// Trim a long uid to a short display string when no profile-name lookup
/// exists yet. e.g. `f1e2d3c4-...` → `f1e2d3c4`.
String _short(String uid) =>
    uid.length <= 8 ? uid : uid.substring(0, 8);

class _NoMember implements RosterMember {
  const _NoMember();
  @override
  TeamMember get member => throw UnimplementedError();
  @override
  String get displayName => '';
  @override
  int get hashCode => 0;
  @override
  bool operator ==(Object other) => identical(this, other);
}
