import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_relationship.dart';
import '../providers/teams_providers.dart';
import '../utils/team_display.dart';
import '../widgets/team_page/tp_atoms.dart';
import '../widgets/team_page/tp_view.dart';

/// Team page at `/teams/:teamId` — faithful realisation of the matchday
/// design's 10-case Team Page. The same `_TeamPageBody` handles every
/// viewer × state combination; only the [TeamPageView] shape differs.
class TeamPageScreen extends ConsumerWidget {
  const TeamPageScreen({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    // Narrow user with .select — String == is stable so unrelated user-stream
    // ticks won't rebuild this screen.
    final userId = ref.watch(
      currentUserStreamProvider.select((u) => u.value?.id.value),
    );

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (teamAsync) {
        AsyncData(value: final team?) => SafeArea(
          top: false,
          child: _LoadedBody(teamId: teamId, team: team, userId: userId),
        ),
        AsyncData(value: null) => _NotFound(onBack: () => context.pop()),
        AsyncError() => _NotFound(onBack: () => context.pop()),
        _ => const Center(
          child: CircularProgressIndicator(color: CkColors.ink),
        ),
      },
    );
  }
}

/// Isolates roster + matches subscriptions so they don't rebuild the outer
/// scaffold (loader/not-found chrome) on every stream tick. Also pre-filters
/// matches to just this team's so the adapter does proportional work.
class _LoadedBody extends ConsumerWidget {
  const _LoadedBody({
    required this.teamId,
    required this.team,
    required this.userId,
  });

  final String teamId;
  final Team team;
  final String? userId;

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

    return _TeamPageBody(
      teamId: teamId,
      view: buildTeamPageViewFromReal(
        team: team,
        roster: rosterAsync.value ?? const [],
        matches: matchesForTeam,
        viewerUserId: userId,
      ),
      onBack: () => context.pop(),
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

// ---------------------------------------------------------------------------
// Real-data adapter — pure function turning real-data (Team + roster +
// matches + viewer id) into a `TeamPageView` for the Team Page presentation.
// Mirrors the shape the JSX CASES.* fixtures use.
//
// Today's reality — many sections have no backend signal and stay empty:
// W/L `record`, `form` (last-8), `stats`, `tournament` block, `actionQueue`
// (renders the "Inbox clear ✓" empty state). Hero / Squad / Matches /
// About populate from real data; the screen still looks intentional thanks
// to the body's section-level short-circuits.
// ---------------------------------------------------------------------------

/// Adapter from real-data sources to the new presentation shape.
TeamPageView buildTeamPageViewFromReal({
  required Team team,
  required List<RosterMember> roster,
  required List<Match> matches,
  required String? viewerUserId,
}) {
  final viewer = _deriveViewer(team, roster, viewerUserId);

  // Resolve userId → display name from the roster (claimed members carry a
  // resolved name). Lets owner/manager rows show a real name instead of a
  // raw UUID prefix; falls back to the trimmed uid only when unresolved.
  final nameByUserId = <String, String>{
    for (final r in roster)
      if (r.member.playerType == PlayerType.claimed)
        r.member.playerId: r.displayName,
  };
  String resolveName(String uid) => nameByUserId[uid] ?? _short(uid);

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
    squad.add(
      TpPlayerRow(
        id: m.id.value,
        name: r.displayName,
        role: _mapRole(m.role),
        jersey: m.jerseyNumber ?? 0,
        bat: '—',
        bowl: '—',
        status:
            m.playerType == PlayerType.unclaimed
                ? TpPlayerStatus.unclaimed
                : TpPlayerStatus.app,
      ),
    );
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

  // Owner first-team detection (matches the My Teams adapter rule).
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
    verified: false, // no backend signal yet
    squad: squad,
    upcoming: upcoming,
    recent: recent,
    live: live,
    about: team.description ?? '',
    details: _buildDetails(team),
    managers: [
      TpManagerRow(name: resolveName(team.ownerId), role: 'Owner'),
      for (final m in team.managers)
        if (m != team.ownerId)
          TpManagerRow(name: resolveName(m), role: 'Manager'),
    ],
  );

  final tabs = _tabsFor(viewer, tpTeam);
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
              body: "You're the owner. Next: add your squad.",
              cta: 'Add players',
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

TeamPageViewer _deriveViewer(
  Team team,
  List<RosterMember> roster,
  String? userId,
) {
  // The user's claimed roster role, if they're on the roster.
  MemberRole? mineRole;
  for (final r in roster) {
    if (r.member.playerType == PlayerType.claimed &&
        r.member.playerId == userId) {
      mineRole = r.member.role;
      break;
    }
  }
  // Relationship decision lives in the domain; this screen maps it to the
  // viewer enum (and applies privacy to the "not affiliated" case).
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
  if (team.foundedYear != null) TpDetailRow('Founded', '${team.foundedYear}'),
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
String _short(String uid) => uid.length <= 8 ? uid : uid.substring(0, 8);

// ---------------------------------------------------------------------------
// Body — hero + optional live/info banner + sticky tabs + active tab body.
// Local `_active` state; everything else flows from the [TeamPageView] in.
// ---------------------------------------------------------------------------

/// The full Team Page — hero + optional live/info banner + sticky tabs +
/// active tab body. Local `_active` state; everything else flows from the
/// [TeamPageView] in.
class _TeamPageBody extends StatefulWidget {
  const _TeamPageBody({required this.teamId, required this.view, this.onBack});

  final String teamId;

  final TeamPageView view;
  final VoidCallback? onBack;

  @override
  State<_TeamPageBody> createState() => _TeamPageBodyState();
}

class _TeamPageBodyState extends State<_TeamPageBody> {
  late TeamPageTab _active;

  @override
  void initState() {
    super.initState();
    _active = widget.view.initialTab;
  }

  @override
  void didUpdateWidget(_TeamPageBody old) {
    super.didUpdateWidget(old);
    // If the tab set changes underneath us (e.g. the team flips between
    // archived / active), snap back to the new initial.
    if (!widget.view.tabs.contains(_active)) {
      _active = widget.view.initialTab;
    }
  }

  Widget _bodyTab() {
    switch (_active) {
      case TeamPageTab.squad:
        return _SquadTab(
          teamId: widget.teamId,
          team: widget.view.team,
          viewer: widget.view.viewer,
          viewerPlayerId: widget.view.viewerPlayerId,
        );
      case TeamPageTab.matches:
        return _MatchesTab(team: widget.view.team);
      case TeamPageTab.stats:
        return _StatsTab(team: widget.view.team);
      case TeamPageTab.about:
        return _AboutTab(team: widget.view.team);
      case TeamPageTab.manage:
        return _ManageTab(team: widget.view.team);
      case TeamPageTab.recent:
        // "Recent" archived alias — render MatchesTab against a copy of the
        // team that has no upcoming list (so only the Recent section shows).
        return _MatchesTab(team: _withoutUpcoming(widget.view.team));
    }
  }

  TpTeam _withoutUpcoming(TpTeam t) => TpTeam(
    name: t.name,
    mono: t.mono,
    type: t.type,
    city: t.city,
    area: t.area,
    primary: t.primary,
    privacy: t.privacy,
    tagline: t.tagline,
    logoUrl: t.logoUrl,
    verified: t.verified,
    archived: t.archived,
    record: t.record,
    form: t.form,
    live: t.live,
    tournament: t.tournament,
    upcoming: const [],
    recent: t.recent,
    stats: t.stats,
    squad: t.squad,
    maxSize: t.maxSize,
    actionQueue: t.actionQueue,
    about: t.about,
    details: t.details,
    managers: t.managers,
  );

  int? _tabBadge(TeamPageTab t) {
    final v = widget.view;
    if (t == TeamPageTab.manage && v.team.actionQueue.isNotEmpty) {
      return v.team.actionQueue.length;
    }
    if (t == TeamPageTab.recent && v.team.recent.isNotEmpty) {
      return v.team.recent.length;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final items = [
      for (final t in v.tabs)
        TpTabItem(id: t, label: _tpTabLabel(t), badge: _tabBadge(t)),
    ];
    return ColoredBox(
      color: CkColors.paper,
      child: Column(
        children: [
          _Hero(
            teamId: widget.teamId,
            team: v.team,
            viewer: v.viewer,
            badges: v.badges,
            onBack: widget.onBack,
          ),
          if (v.team.live != null) _LiveBanner(data: v.team.live!),
          if (v.banner != null) _InfoBanner(banner: v.banner!),
          _Tabs(
            items: items,
            active: _active,
            onSelect: (t) => setState(() => _active = t),
          ),
          Expanded(child: _bodyTab()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — primary-color background with cricket-ground motif, status bar
// overlay, back/share/dots icons, crest tile + name + tagline, optional
// badges row, optional W/L strip, action row. Archived teams render in a
// muted brown to signal read-only.
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({
    required this.teamId,
    required this.team,
    required this.viewer,
    required this.badges,
    this.onBack,
  });

  final String teamId;
  final TpTeam team;
  final TeamPageViewer viewer;
  final List<TpHeroBadge> badges;
  final VoidCallback? onBack;

  Color get _heroColor =>
      team.archived != null ? const Color(0xFF6A6356) : team.primary;

  @override
  Widget build(BuildContext context) {
    final dim = team.archived != null;
    final color = _heroColor;
    return ColoredBox(
      color: color,
      child: Stack(
        children: [
          // Cricket-ground motif painted at the top-right corner.
          Positioned(
            right: -30,
            top: -10,
            child: Opacity(
              opacity: 0.10,
              child: CustomPaint(
                size: const Size(320, 200),
                painter: _PitchMotif(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TpStatusBar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TpIconBtn(
                        icon: Icons.chevron_left,
                        onColor: true,
                        onTap: onBack,
                      ),
                      const Row(
                        children: [
                          TpIconBtn(icon: Icons.ios_share, onColor: true),
                          SizedBox(width: 6),
                          TpIconBtn(icon: Icons.more_horiz, onColor: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _Identity(team: team, heroColor: color, dim: dim),
                ),
                if (badges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: _BadgesRow(badges: badges),
                  ),
                if (team.record != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _RecordStrip(record: team.record!),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: _ActionRow(
                    teamId: teamId,
                    viewer: viewer,
                    team: team,
                    heroColor: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.team,
    required this.heroColor,
    required this.dim,
  });
  final TpTeam team;
  final Color heroColor;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _HeroCrest(team: team, heroColor: heroColor),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${team.type.toUpperCase()} · '
                      '${team.area.toUpperCase()}, ${team.city.toUpperCase()}',
                      style: tpMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    if (team.verified && !dim) const TpVerifiedTick(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  team.name,
                  style: CkType.display(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                if (team.tagline != null &&
                    team.tagline!.trim().isNotEmpty &&
                    !dim) ...[
                  const SizedBox(height: 6),
                  Text(
                    '“${team.tagline}”',
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.01,
                      color: Colors.white.withValues(alpha: 0.85),
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCrest extends StatelessWidget {
  const _HeroCrest({required this.team, required this.heroColor});
  final TpTeam team;
  final Color heroColor;

  Widget _mono() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      team.mono,
      style: CkType.display(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: heroColor,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final url = team.logoUrl;
    if (url == null || url.isEmpty) return _mono();
    final memW = (72 * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 72,
        height: 72,
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          memCacheWidth: memW,
          errorWidget: (_, __, ___) => _mono(),
          placeholder: (_, __) => _mono(),
        ),
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.badges});
  final List<TpHeroBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final b in badges) _Badge(badge: b)],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});
  final TpHeroBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color:
            badge.tone == TpHeroBadgeTone.red
                ? CkColors.red
                : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.pulse) ...[const TpLivePulse(), const SizedBox(width: 5)],
          Text(
            badge.label.toUpperCase(),
            style: tpMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordStrip extends StatelessWidget {
  const _RecordStrip({required this.record});
  final TpRecord record;

  @override
  Widget build(BuildContext context) {
    final cells = <(String, String)>[
      ('PLAYED', '${record.played}'),
      ('WON', '${record.won}'),
      ('LOST', '${record.lost}'),
      ('WIN %', '${record.winPct}'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border:
                        i == 0
                            ? null
                            : Border(
                              left: BorderSide(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cells[i].$2,
                        style: CkType.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cells[i].$1,
                        style: tpMono(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PitchMotif extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: size.width * 0.95,
        height: size.height * 0.85,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: size.width * 0.55,
        height: size.height * 0.5,
      ),
      paint,
    );
    canvas.drawRect(Rect.fromCenter(center: c, width: 16, height: 60), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------------------------------------------------------------------------
// Action row — adapts to viewer and team state. Lives inside the hero —
// primary button = white fill / hero-color text; ghost = transparent with
// translucent white border + white text. Archived teams override to a
// single "Read-only archive" + share button row.
// ---------------------------------------------------------------------------

class _ActionRow extends ConsumerWidget {
  const _ActionRow({
    required this.teamId,
    required this.viewer,
    required this.team,
    required this.heroColor,
  });

  final String teamId;
  final TeamPageViewer viewer;
  final TpTeam team;
  final Color heroColor;

  List<_Action> _actionsFor(WidgetRef ref) {
    if (team.archived != null) {
      return const [
        _Action(label: 'Read-only archive', icon: Icons.access_time),
        _Action(icon: Icons.ios_share, iconOnly: true),
      ];
    }
    switch (viewer) {
      case TeamPageViewer.owner:
        return [
          _Action(
            label: 'Manage',
            icon: Icons.dashboard_outlined,
            primary: true,
            badge: team.actionQueue.isEmpty ? null : team.actionQueue.length,
          ),
          const _Action(label: 'Post as team', icon: Icons.add),
        ];
      case TeamPageViewer.captain:
        return const [
          _Action(
            label: 'Captain inbox',
            icon: Icons.email_outlined,
            primary: true,
            badge: 3,
          ),
          _Action(label: 'Lineup', icon: Icons.format_list_bulleted),
        ];
      case TeamPageViewer.player:
        return const [
          _Action(
            label: 'Team chat',
            icon: Icons.chat_bubble_outline,
            primary: true,
          ),
          _Action(label: 'My stats', icon: Icons.bar_chart),
        ];
      case TeamPageViewer.following:
        // Reachable today via the same path as `stranger` once the user
        // taps Follow — kept distinct so the right-hand action differs
        // ("Notify" instead of "Request to join"). The primary button
        // still flips Follow ↔ Following based on the live state.
        return [
          _followAction(ref),
          const _Action(label: 'Notify', icon: Icons.notifications_none),
        ];
      case TeamPageViewer.strangerPrivate:
        return const [
          _Action(label: 'Request to join', icon: Icons.add, primary: true),
        ];
      case TeamPageViewer.stranger:
        return [
          _followAction(ref),
          const _Action(label: 'Request to join'),
        ];
    }
  }

  /// The primary Follow / Following button driven by the toggle controller.
  /// Watches the live follow status for this team; on tap fires the
  /// optimistic toggle in the controller. The action.onTap closure goes
  /// through to `_ActionButton`'s GestureDetector.
  _Action _followAction(WidgetRef ref) {
    final following = ref.watch(
      followToggleProvider('team', teamId),
    );
    final isFollowing = following.value ?? false;
    return _Action(
      label: isFollowing ? 'Following' : 'Follow',
      icon: isFollowing ? Icons.check : Icons.add,
      primary: true,
      onTap: () => ref
          .read(followToggleProvider('team', teamId)
              .notifier)
          .toggle(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = _actionsFor(ref);
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _ActionButton(action: actions[i], heroColor: heroColor),
        ],
      ],
    );
  }
}

class _Action {
  const _Action({
    this.label,
    this.icon,
    this.primary = false,
    this.iconOnly = false,
    this.badge,
    this.onTap,
  });
  final String? label;
  final IconData? icon;
  final bool primary;
  final bool iconOnly;
  final int? badge;
  final VoidCallback? onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.heroColor});
  final _Action action;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    final primary = action.primary;
    final body = Container(
      height: 44,
      padding: EdgeInsets.symmetric(
        horizontal: action.iconOnly ? 14 : (primary ? 0 : 14),
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border:
            primary
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (action.icon != null)
            Icon(
              action.icon,
              size: 14,
              color: primary ? heroColor : Colors.white,
            ),
          if (action.icon != null && action.label != null)
            const SizedBox(width: 6),
          if (action.label != null)
            Text(
              action.label!,
              style: CkType.body(
                fontSize: 13,
                fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                color: primary ? heroColor : Colors.white,
              ),
            ),
          if (action.badge != null && action.badge! > 0) ...[
            const SizedBox(width: 6),
            _CountPill(count: action.badge!),
          ],
        ],
      ),
    );
    final tapped = action.onTap == null
        ? body
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: action.onTap,
            child: body,
          );
    if (primary || (!action.iconOnly && action.label != null)) {
      return Expanded(child: tapped);
    }
    return tapped;
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: CkColors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: CkType.display(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banners — inverted ink-on-paper live card + tinted info banner.
// ---------------------------------------------------------------------------

/// Inverted ink-on-paper live card. Overlaps the bottom of the hero by 12
/// via a negative top margin. Pulsing LIVE pill + score + chase note +
/// WATCH LIVE button.
class _LiveBanner extends StatelessWidget {
  const _LiveBanner({required this.data});
  final TpLiveCard data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 2, 6, 2),
                    decoration: BoxDecoration(
                      color: CkColors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TpLivePulse(),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE NOW',
                          style: tpMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      data.ctx,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tpMono(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LiveSide(
                      name: data.us,
                      score: data.usScore,
                      alignEnd: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'VS',
                      style: tpMono(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _LiveSide(
                      name: data.them,
                      score: data.themScore,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.note,
                        style: CkType.body(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'WATCH LIVE',
                        style: tpMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSide extends StatelessWidget {
  const _LiveSide({
    required this.name,
    required this.score,
    required this.alignEnd,
  });
  final String name;
  final String score;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.display(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: tpMono(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Tinted info banner — green / amber / red / gray. Circular icon, title +
/// body, optional CTA pill on the right.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.banner});
  final TpInfoBanner banner;

  ({Color bg, Color border, Color accent, Color ctaBg}) get _tones {
    switch (banner.tone) {
      case TpInfoBannerTone.green:
        return (
          bg: CkColors.greenSoft,
          border: CkColors.green.withValues(alpha: 0.35),
          accent: CkInk.green,
          ctaBg: CkColors.green,
        );
      case TpInfoBannerTone.amber:
        return (
          bg: CkColors.cream,
          border: CkColors.amber.withValues(alpha: 0.45),
          accent: CkInk.amber,
          ctaBg: CkColors.amber,
        );
      case TpInfoBannerTone.red:
        return (
          bg: CkColors.redSoft,
          border: CkColors.red.withValues(alpha: 0.35),
          accent: CkInk.red,
          ctaBg: CkColors.red,
        );
      case TpInfoBannerTone.gray:
        return (
          bg: CkColors.paper2,
          border: CkColors.hairline,
          accent: CkColors.ink,
          ctaBg: CkColors.ink,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tones;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: t.ctaBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                banner.icon ?? Icons.info_outline,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: CkType.display(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.01,
                      color: t.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    banner.body,
                    style: CkType.body(
                      fontSize: 12,
                      color: t.accent.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (banner.cta != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: t.ctaBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  banner.cta!,
                  style: CkType.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabs — sticky tab strip with equal-flex tabs, an ink underline under the
// active one, and an optional cream count badge.
// ---------------------------------------------------------------------------

@immutable
class TpTabItem {
  const TpTabItem({required this.id, required this.label, this.badge});
  final TeamPageTab id;
  final String label;
  final int? badge;
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.items,
    required this.active,
    required this.onSelect,
  });

  final List<TpTabItem> items;
  final TeamPageTab active;
  final ValueChanged<TeamPageTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final t in items)
              Expanded(
                child: _Tab(
                  item: t,
                  isActive: t.id == active,
                  onTap: () => onSelect(t.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.isActive, required this.onTap});
  final TpTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? CkColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? CkColors.ink : CkColors.muted,
              ),
            ),
            if (item.badge != null && item.badge! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? CkColors.ink : CkColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.badge}',
                  style: tpMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isActive ? CkColors.paper : CkColors.ink2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Human label for a tab id. "Recent" is a separate alias used by archived
/// teams that don't have an Upcoming list.
String _tpTabLabel(TeamPageTab t) {
  switch (t) {
    case TeamPageTab.squad:
      return 'Squad';
    case TeamPageTab.matches:
      return 'Matches';
    case TeamPageTab.stats:
      return 'Stats';
    case TeamPageTab.about:
      return 'About';
    case TeamPageTab.manage:
      return 'Manage';
    case TeamPageTab.recent:
      return 'Recent';
  }
}

// ---------------------------------------------------------------------------
// Squad tab — three modes:
//   1. Owner with ≤1 member → onboarding panel ("It's just you so far" + 3 CTAs).
//   2. Private team viewed by stranger → lock gate + Request-to-join CTA.
//   3. Normal grouped roster (Captaincy & keeper / Players) with filter chips.
// ---------------------------------------------------------------------------

class _SquadTab extends StatelessWidget {
  const _SquadTab({
    required this.teamId,
    required this.team,
    required this.viewer,
    this.viewerPlayerId,
  });

  final String teamId;
  final TpTeam team;
  final TeamPageViewer viewer;
  final String? viewerPlayerId;

  bool get _canAddPlayers =>
      viewer == TeamPageViewer.owner || viewer == TeamPageViewer.captain;

  /// True when the viewer is the owner and the squad has no players besides
  /// the viewer themselves. The owner is not auto-rostered, so when no other
  /// players have been added, `team.squad` is empty (or contains only the
  /// owner if they later add themselves as a claimed member).
  bool get _isOwnerEmpty {
    if (viewer != TeamPageViewer.owner) return false;
    return team.squad.every((p) => p.id == viewerPlayerId);
  }
  bool get _privateGated =>
      team.privacy.toLowerCase().startsWith('private') &&
      (viewer == TeamPageViewer.stranger ||
          viewer == TeamPageViewer.strangerPrivate);

  @override
  Widget build(BuildContext context) {
    if (team.squad.isEmpty && !_isOwnerEmpty && !_privateGated) {
      return const TpEmptyTile(
        icon: Icons.groups_2_outlined,
        title: 'Squad still being built.',
        body: 'Players will appear here once they\'re added.',
      );
    }
    if (_privateGated) return _PrivateGate(team: team);
    if (_isOwnerEmpty) {
      return _OwnerOnboarding(
        teamId: teamId,
        team: team,
        viewerPlayerId: viewerPlayerId,
      );
    }

    final lead =
        team.squad
            .where(
              (p) =>
                  p.role == TpPlayerRole.captain ||
                  p.role == TpPlayerRole.viceCaptain ||
                  p.role == TpPlayerRole.wicketKeeper,
            )
            .toList();
    final players =
        team.squad.where((p) => p.role == TpPlayerRole.player).toList();

    final builders = <WidgetBuilder>[];
    if (_canAddPlayers) {
      builders.add(
        (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: _AddOption(
            primary: true,
            icon: Icons.person_add_alt_1,
            title: 'Add player',
            sub: 'Search registered, or add as unclaimed',
            onTap: () => ctx.push('/teams/$teamId/add-unclaimed'),
          ),
        ),
      );
    }
    builders.add((_) => _FilterChips());
    if (lead.isNotEmpty) {
      builders.add(
        (_) => TpSectionHeader(label: 'Captaincy & keeper', count: lead.length),
      );
      for (var i = 0; i < lead.length; i++) {
        final player = lead[i];
        final isFirst = i == 0;
        builders.add(
          (_) => TpPlayerRowWidget(
            player: player,
            primary: team.primary,
            isFirst: isFirst,
            viewerPlayerId: viewerPlayerId,
          ),
        );
      }
    }
    if (players.isNotEmpty) {
      builders.add(
        (_) => TpSectionHeader(label: 'Players', count: players.length),
      );
      for (var i = 0; i < players.length; i++) {
        final player = players[i];
        final isFirst = i == 0;
        builders.add(
          (_) => TpPlayerRowWidget(
            player: player,
            primary: team.primary,
            isFirst: isFirst,
            viewerPlayerId: viewerPlayerId,
          ),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 14),
      itemCount: builders.length,
      itemBuilder: (ctx, i) => builders[i](ctx),
    );
  }
}

class _FilterChips extends StatelessWidget {
  static const _labels = [
    'All',
    'Batters',
    'Bowlers',
    'All-rounders',
    'Keeper',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? CkColors.ink : CkColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: active ? null : Border.all(color: CkColors.hairline),
            ),
            alignment: Alignment.center,
            child: Text(
              _labels[i],
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
}

class _PrivateGate extends StatelessWidget {
  const _PrivateGate({required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    return TpEmptyTile(
      icon: Icons.lock_outline,
      title: 'Private squad',
      body:
          'Only members can see the roster. Request to join — the captain will review.',
      cta: 'Request to join',
      onCtaTap: () {},
    );
  }
}

class _OwnerOnboarding extends StatelessWidget {
  const _OwnerOnboarding({
    required this.teamId,
    required this.team,
    required this.viewerPlayerId,
  });
  final String teamId;
  final TpTeam team;
  final String? viewerPlayerId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        _DashedPanel(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CkColors.hairline),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_add_alt_1,
                  size: 28,
                  color: CkColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "It's just you so far.",
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  "Build ${team.name}'s squad — search registered "
                  'players, send SMS invites, or add unclaimed placeholders.',
                  textAlign: TextAlign.center,
                  style: CkType.body(
                    fontSize: 12,
                    color: CkColors.ink2,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _AddOption(
          primary: true,
          icon: Icons.search,
          title: 'Search registered players',
          sub: 'Pick from people already on MatchDay',
        ),
        const SizedBox(height: 8),
        const _AddOption(
          icon: Icons.mail_outline,
          title: 'Send SMS invite',
          sub: 'Phone number → download link',
        ),
        const SizedBox(height: 8),
        _AddOption(
          icon: Icons.person_outline,
          title: 'Add as unclaimed',
          sub: 'Just a name — they can claim later',
          onTap: () => context.push('/teams/$teamId/add-unclaimed'),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('YOU', style: tpMono()),
        ),
        const SizedBox(height: 8),
        if (team.squad.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: TpPlayerRowWidget(
              player: team.squad.first,
              primary: team.primary,
              isFirst: true,
              viewerPlayerId: viewerPlayerId,
            ),
          ),
      ],
    );
  }
}

class _DashedPanel extends StatelessWidget {
  const _DashedPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: CkColors.paper2,
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = CkColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.sub,
    this.primary = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String sub;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primary ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary ? CkColors.ink : CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  primary
                      ? Colors.white.withValues(alpha: 0.14)
                      : CkColors.paper2,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 14,
              color: primary ? CkColors.paper : CkColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                    color: primary ? CkColors.paper : CkColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: CkType.body(
                    fontSize: 11,
                    color:
                        primary
                            ? CkColors.paper.withValues(alpha: 0.72)
                            : CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            size: 14,
            color:
                primary
                    ? CkColors.paper.withValues(alpha: 0.6)
                    : CkColors.muted,
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Matches tab — Last-8 form strip + tournament gradient card + upcoming list
// + recent list with W/L/T pill. Empty state when both lists are absent.
// ---------------------------------------------------------------------------

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    if (team.upcoming.isEmpty && team.recent.isEmpty) {
      return const TpEmptyTile(
        icon: Icons.calendar_month,
        title: 'No matches yet',
        body: 'Schedule a friendly or register for a tournament.',
      );
    }
    final builders = <WidgetBuilder>[];
    if (team.form.isNotEmpty) {
      builders.add((_) => _FormStrip(form: team.form));
    }
    if (team.tournament != null) {
      builders.add(
        (_) => _TournamentCard(
          tournament: team.tournament!,
          primary: team.primary,
        ),
      );
    }
    if (team.upcoming.isNotEmpty) {
      builders.add(
        (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text('UPCOMING · ${team.upcoming.length}', style: tpMono()),
        ),
      );
      for (final m in team.upcoming) {
        builders.add((_) => _UpcomingRow(match: m));
      }
    }
    if (team.recent.isNotEmpty) {
      builders.add(
        (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Text('RECENT · ${team.recent.length}', style: tpMono()),
        ),
      );
      for (final m in team.recent) {
        builders.add((_) => _RecentRow(match: m));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 14),
      itemCount: builders.length,
      itemBuilder: (ctx, i) => builders[i](ctx),
    );
  }
}

class _FormStrip extends StatelessWidget {
  const _FormStrip({required this.form});
  final List<TpFormResult> form;

  Color _bg(TpFormResult r) {
    switch (r) {
      case TpFormResult.w:
        return CkColors.green;
      case TpFormResult.l:
        return CkColors.red;
      case TpFormResult.t:
        return CkColors.cream;
    }
  }

  Color _fg(TpFormResult r) =>
      r == TpFormResult.t ? CkColors.ink2 : Colors.white;

  String _label(TpFormResult r) {
    switch (r) {
      case TpFormResult.w:
        return 'W';
      case TpFormResult.l:
        return 'L';
      case TpFormResult.t:
        return 'T';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('LAST 8', style: tpMono()),
          ),
          Row(
            children: [
              for (var i = 0; i < form.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _bg(form[i]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _label(form[i]),
                    style: CkType.display(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _fg(form[i]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.tournament, required this.primary});
  final TpTournament tournament;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('IN TOURNAMENT', style: tpMono()),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, const Color(0xFF26201A)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.kind.toUpperCase(),
                  style: tpMono(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tournament.name,
                  style: CkType.display(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STAGE · ${tournament.stage.toUpperCase()}',
                        style: tpMono(fontSize: 9, color: Colors.white),
                      ),
                    ),
                    Text(
                      '${tournament.played}/${tournament.total} played',
                      style: CkType.body(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      '·',
                      style: CkType.body(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      tournament.next,
                      style: CkType.body(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.match});
  final TpUpcomingMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(match.dateDay.toUpperCase(), style: tpMono(fontSize: 9)),
                const SizedBox(height: 2),
                Text(
                  match.dateTime,
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${match.vs}',
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.round} · ${match.venue}',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
          if (match.live)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CkColors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TpLivePulse(),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: tpMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.match});
  final TpRecentMatch match;

  Color get _bg {
    switch (match.result) {
      case TpFormResult.w:
        return CkColors.green;
      case TpFormResult.l:
        return CkColors.red;
      case TpFormResult.t:
        return CkColors.cream;
    }
  }

  Color get _fg =>
      match.result == TpFormResult.t ? CkColors.ink2 : Colors.white;

  String get _letter {
    switch (match.result) {
      case TpFormResult.w:
        return 'W';
      case TpFormResult.l:
        return 'L';
      case TpFormResult.t:
        return 'T';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              _letter,
              style: CkType.display(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _fg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      match.us,
                      style: tpMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CkColors.ink,
                      ).copyWith(letterSpacing: 0),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'vs',
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        match.them,
                        overflow: TextOverflow.ellipsis,
                        style: tpMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink2,
                        ).copyWith(letterSpacing: 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.date} · ${match.summary}',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats tab — win-% hero number block + top performers list. Empty state
// when [TpTeam.stats] is null ("Stats unlock at first match").
// ---------------------------------------------------------------------------

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    final stats = team.stats;
    if (stats == null) {
      return const TpEmptyTile(
        icon: Icons.bar_chart,
        title: 'Stats unlock at first match',
        body:
            'Once you play your first match, win rates and top performers appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      children: [
        _WinPctCard(stats: stats),
        const SizedBox(height: 16),
        Text('TOP PERFORMERS · THIS SEASON', style: tpMono()),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < stats.top.length; i++)
                _PerformerRow(performer: stats.top[i], isFirst: i == 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _WinPctCard extends StatelessWidget {
  const _WinPctCard({required this.stats});
  final TpStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALL-TIME', style: tpMono()),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.winPct}',
                style: CkType.display(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.04,
                  height: 0.9,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 8),
                child: Text(
                  '%',
                  style: CkType.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CkColors.muted,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('WIN RATE', style: tpMono()),
                  const SizedBox(height: 2),
                  Text(
                    stats.trend,
                    style: tpMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CkColors.green,
                    ).copyWith(letterSpacing: 0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformerRow extends StatelessWidget {
  const _PerformerRow({required this.performer, required this.isFirst});
  final TpPerformer performer;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border:
            isFirst
                ? null
                : const Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              performer.kind,
              style: tpMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: CkColors.ink2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(performer.label, style: tpMono()),
                const SizedBox(height: 2),
                Text(
                  performer.name,
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  performer.detail,
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            performer.value,
            style: CkType.display(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About tab — optional disbanded callout (archived) + about prose + details
// table + managers list.
// ---------------------------------------------------------------------------

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      children: [
        if (team.archived != null) _DisbandedCallout(date: team.archived!),
        if (team.about.isNotEmpty) ...[
          Text('ABOUT', style: tpMono()),
          const SizedBox(height: 6),
          Text(
            team.about,
            style: CkType.body(
              fontSize: 14,
              color: CkColors.ink2,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (team.details.isNotEmpty) ...[
          Text('DETAILS', style: tpMono()),
          const SizedBox(height: 8),
          _DetailsTable(rows: team.details),
          const SizedBox(height: 18),
        ],
        if (team.managers.isNotEmpty) ...[
          Text('MANAGERS · ${team.managers.length}', style: tpMono()),
          const SizedBox(height: 8),
          _ManagersList(managers: team.managers),
        ],
      ],
    );
  }
}

class _DisbandedCallout extends StatelessWidget {
  const _DisbandedCallout({required this.date});
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: CustomPaint(
        painter: _AboutDashedPainter(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: CkColors.paper2,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISBANDED · ${date.toUpperCase()}',
                  style: tpMono(color: CkColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  "This team's record is preserved for historical "
                  'reference. Profile and stats are read-only.',
                  style: CkType.body(
                    fontSize: 12.5,
                    color: CkColors.ink2,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutDashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = CkColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DetailsTable extends StatelessWidget {
  const _DetailsTable({required this.rows});
  final List<TpDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border:
                    i == 0
                        ? null
                        : const Border(
                          top: BorderSide(color: CkColors.hairline),
                        ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(rows[i].label.toUpperCase(), style: tpMono()),
                  ),
                  Text(
                    rows[i].value,
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ManagersList extends StatelessWidget {
  const _ManagersList({required this.managers});
  final List<TpManagerRow> managers;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '–';
    if (parts.length == 1) {
      final first = parts.first;
      return first.length >= 2
          ? first.substring(0, 2).toUpperCase()
          : first.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < managers.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border:
                    i == 0
                        ? null
                        : const Border(
                          top: BorderSide(color: CkColors.hairline),
                        ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CkColors.paper2,
                      shape: BoxShape.circle,
                      border: Border.all(color: CkColors.hairline),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(managers[i].name),
                      style: CkType.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                        color: CkColors.ink2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          managers[i].name,
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.01,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          managers[i].role,
                          style: CkType.body(
                            fontSize: 11,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Manage tab — action queue with red/amber/ink left border + squad capacity
// bar (joined/invited/unclaimed) + 2×2 quick-grid of common owner actions.
// ---------------------------------------------------------------------------

class _ManageTab extends StatelessWidget {
  const _ManageTab({required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    final queue = team.actionQueue;
    final active =
        team.squad.where((p) => p.status == TpPlayerStatus.app).length;
    final invited =
        team.squad.where((p) => p.status == TpPlayerStatus.sms).length;
    final unclaimed =
        team.squad.where((p) => p.status == TpPlayerStatus.unclaimed).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        Text('ACTION QUEUE · ${queue.length}', style: tpMono()),
        const SizedBox(height: 8),
        if (queue.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            alignment: Alignment.center,
            child: Text(
              'Inbox clear. ✓',
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < queue.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _QueueRow(item: queue[i]),
              ],
            ],
          ),
        const SizedBox(height: 18),
        Text('SQUAD CAPACITY', style: tpMono()),
        const SizedBox(height: 8),
        _CapacityCard(
          total: team.squad.length,
          cap: team.maxSize,
          active: active,
          invited: invited,
          unclaimed: unclaimed,
        ),
        const SizedBox(height: 18),
        Text('QUICK', style: tpMono()),
        const SizedBox(height: 8),
        const _QuickGrid(),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item});
  final TpActionQueueItem item;

  Color get _accent {
    switch (item.tone) {
      case TpQueueTone.red:
        return CkColors.red;
      case TpQueueTone.amber:
        return CkColors.amber;
      case TpQueueTone.ink:
        return CkColors.ink;
    }
  }

  Color get _kindBg =>
      item.tone == TpQueueTone.red ? CkColors.redSoft : CkColors.cream;

  Color get _kindFg =>
      item.tone == TpQueueTone.red ? CkColors.red : CkColors.ink2;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: _accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _kindBg,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  item.kind,
                                  style: tpMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: _kindFg,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(item.when, style: tpMono(fontSize: 9)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: CkType.display(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.01,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.body,
                            style: CkType.body(
                              fontSize: 12,
                              color: CkColors.ink2,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SmallPillBtn(label: item.primary, primary: true),
                        const SizedBox(height: 4),
                        const _SmallPillBtn(label: 'Reject', primary: false),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallPillBtn extends StatelessWidget {
  const _SmallPillBtn({required this.label, required this.primary});
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: primary ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        label,
        style: CkType.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: primary ? CkColors.paper : CkColors.ink,
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({
    required this.total,
    required this.cap,
    required this.active,
    required this.invited,
    required this.unclaimed,
  });
  final int total;
  final int cap;
  final int active;
  final int invited;
  final int unclaimed;

  @override
  Widget build(BuildContext context) {
    final pct = cap == 0 ? 0 : ((total / cap) * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$total of $cap',
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
              const Spacer(),
              Text('$pct%', style: tpMono(fontSize: 9)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: active,
                    child: Container(color: CkColors.green),
                  ),
                  Expanded(
                    flex: invited,
                    child: Container(color: CkColors.amber),
                  ),
                  Expanded(
                    flex: unclaimed,
                    child: Container(color: CkColors.cream),
                  ),
                  Expanded(
                    flex: (cap - total).clamp(0, cap),
                    child: Container(color: CkColors.paper2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendDot(label: 'Joined', count: active, color: CkColors.green),
              _LegendDot(
                label: 'Invited',
                count: invited,
                color: CkColors.amber,
              ),
              _LegendDot(
                label: 'Unclaimed',
                count: unclaimed,
                color: CkColors.cream,
                bordered: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.count,
    required this.color,
    this.bordered = false,
  });
  final String label;
  final int count;
  final Color color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: bordered ? Border.all(color: CkColors.hairline) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label · $count',
          style: CkType.body(fontSize: 11, color: CkColors.ink2),
        ),
      ],
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.calendar_month, 'Schedule match'),
      (Icons.lock_outline, 'Lock playing XI'),
      (Icons.edit, 'Edit team'),
      (Icons.settings, 'Settings'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final item in items) _QuickBtn(icon: item.$1, label: item.$2),
      ],
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: CkColors.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.01,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
