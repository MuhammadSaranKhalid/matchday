import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../providers/teams_providers.dart';
import '../state/my_teams_view.dart';
import '../utils/team_display.dart';
import '../widgets/my_teams/crest_palette.dart';

part 'teams_list_controller.g.dart';

/// Builds the "My teams" screen's [MyTeamsView] directly from three sources —
/// the user's teams (local stream), their active matches (online), and the
/// cached teams used to resolve opponent crests — plus the signed-in user id
/// to bucket teams by relationship. The screen stays a pure renderer
/// (CLAUDE.md §5.3 / §6.6); there is no intermediate view shape or adapter.
///
/// The filter is local UI state held here (not in the widget): [setFilter]
/// re-derives the view from the cached base data without re-fetching.
@riverpod
class TeamsListController extends _$TeamsListController {
  MyTeamsFilter _filter = MyTeamsFilter.all;

  /// The unfiltered view from the last successful [build], kept so [setFilter]
  /// can re-derive synchronously without hitting the network again.
  MyTeamsView? _base;

  @override
  Future<MyTeamsView> build() async {
    // Teams + the opponent cache are the local sources — await their streams.
    final teams = await ref.watch(myTeamsProvider.future);
    final cached = await ref.watch(allTeamsProvider.future);
    // Await the user future (not .value) so build runs once with the resolved
    // id, instead of an extra pass with an empty id while the stream loads.
    final user = await ref.watch(currentUserStreamProvider.future);
    final userId = user?.id.value ?? '';
    // Roles come from team_member_roles now, not a column on the team. There
    // is no `created_by` fallback: that is history, and a creator who left
    // must not still read as the owner.
    final myRoles = await ref.watch(myTeamRolesProvider.future);

    // Matches are online-only. Call the repo directly and pattern-match the
    // Either so a failure/offline fetch yields no active matches instead of
    // erroring the whole view (the repo never throws). Reading the matches
    // repo provider keeps the seam to the matches feature (CLAUDE.md §6.6).
    final matchesResult =
        await ref.read(matchesRepositoryProvider).listMyMatches();
    final matches = switch (matchesResult) {
      Right(value: final v) => v,
      Left() => const <Match>[],
    };

    final base = _buildView(
      teams: teams,
      cached: cached,
      matches: matches,
      userId: userId,
      myRoles: myRoles,
    );
    _base = base;
    return _applyFilter(base, _filter);
  }

  /// Layer the local filter selection on top of the base view. Synchronous —
  /// no re-fetch; just re-derives from the cached [_base].
  void setFilter(MyTeamsFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    final base = _base;
    if (base != null) state = AsyncData(_applyFilter(base, filter));
  }

  /// Pull-to-refresh: re-run the composition (re-fetches the online matches).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ── Pure derivation ────────────────────────────────────────────────────────
// Folded in from the former my_teams_real_data_adapter. Kept as free functions
// so they stay Riverpod-free and exercised through the controller in tests.

/// One active match with its cross-feature data already resolved.
typedef _ActiveMatch = ({Match match, bool incoming, Team? opponent});

MyTeamsView _buildView({
  required List<Team> teams,
  required List<Team> cached,
  required List<Match> matches,
  required String userId,
  required Map<String, MemberRole> myRoles,
}) {
  // ── 0. Compose active matches (resolve opponent + incoming) ──────────
  final teamIds = teams.map((t) => t.id).toSet();
  final byId = {for (final t in [...teams, ...cached]) t.id: t};
  final activeMatches = matches.where((m) => m.isActive).map<_ActiveMatch>((m) {
    final iAmTeamA = teamIds.contains(m.teamAId);
    final incoming = !iAmTeamA && teamIds.contains(m.teamBId);
    final opponentId = iAmTeamA ? m.teamBId : m.teamAId;
    return (match: m, incoming: incoming, opponent: byId[opponentId]);
  }).toList();

  // ── 1. Bucket teams by the signed-in user's relationship ─────────────
  final captainBucket = <TeamRowVm>[];
  final playingBucket = <TeamRowVm>[];

  for (final team in teams) {
    // The relationship decision lives in the domain; this screen only maps it
    // to its presentation role + bucket. No roster on this screen, so every
    // non-owner/manager maps to `player`.
    final role = switch (myRoles[team.id.value]) {
      MemberRole.owner => MyTeamsRole.captain,
      MemberRole.manager => MyTeamsRole.manager,
      _ => MyTeamsRole.player,
    };
    final row = TeamRowVm(
      crest: _crestFor(team),
      role: role,
      teamId: team.id.value,
      meta: team.city,
    );
    if (role == MyTeamsRole.captain || role == MyTeamsRole.manager) {
      captainBucket.add(row);
    } else {
      playingBucket.add(row);
    }
  }

  // ── 2. Pick the hero match: accepted > pending ───────────────────────
  //      Live matches are deliberately NOT surfaced here — the My Teams
  //      hero shows what is coming up, not what is in progress.
  TodayMatch? today;
  final picked = _pickHeroMatch(activeMatches);
  if (picked != null) {
    today = _buildTodayMatch(picked, teams, userId);
  }

  // ── 3. Detect the "first team · onboarding" case. Triggered when the
  //      user has exactly one team, they own it, and there are no active
  //      matches yet.
  final isFirstTeam = teams.length == 1 &&
      (myRoles[teams.first.id.value]?.isStaff ?? false) &&
      activeMatches.isEmpty;

  String? subtitle;
  var captain = captainBucket;

  if (isFirstTeam) {
    final team = teams.first;
    subtitle = '1 team · onboarding';
    // Override the row meta so it reads "You · just created" instead of
    // the team's city.
    captain = [
      TeamRowVm(
        crest: captainBucket.first.crest,
        role: captainBucket.first.role,
        teamId: team.id.value,
        meta: 'You · ${_relativeTime(team.createdAt)}',
      ),
    ];
  } else {
    final total = captainBucket.length + playingBucket.length;
    if (total == 0) {
      subtitle = null;
    } else if (total == 1) {
      subtitle = '1 team';
    } else {
      subtitle = '$total teams';
    }
  }

  final total = captain.length + playingBucket.length;

  return MyTeamsView(
    subtitle: subtitle,
    isEmpty: total == 0 && activeMatches.isEmpty,
    today: today,
    teams: TeamGroups(captain: captain, playing: playingBucket),
  );
}

/// Layer a filter selection on top of a base view. Only the three
/// filter-sensitive fields change; `copyWith` carries the rest through.
MyTeamsView _applyFilter(MyTeamsView base, MyTeamsFilter filter) => base.copyWith(
      teams: _filterTeams(base.teams, filter),
      following: filter == MyTeamsFilter.following ||
              filter == MyTeamsFilter.all
          ? base.following
          : const [],
      activeFilter: filter,
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

/// Human-readable relative time — kept inline so there's no extra package
/// dependency.
String _relativeTime(DateTime then) {
  final diff = DateTime.now().difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
  return '${(diff.inDays / 30).floor()} months ago';
}

CrestStyle _crestFor(Team team) => CrestStyle(
      color: parseHexColor(team.primaryColor, fallback: CkColors.ink),
      mono: (team.logoMonogram?.trim().isNotEmpty ?? false)
          ? team.logoMonogram!.toUpperCase()
          : teamMonogram(team.name),
      name: team.name,
      city: team.city,
      logoUrl: team.logoUrl,
      crestKind: team.crestKind,
    );

_ActiveMatch? _pickHeroMatch(List<_ActiveMatch> active) {
  _ActiveMatch? accepted;
  _ActiveMatch? pending;
  for (final entry in active) {
    switch (entry.match.status) {
      case MatchStatus.accepted:
        accepted ??= entry;
      case MatchStatus.pending:
        pending ??= entry;
      default:
        break;
    }
  }
  return accepted ?? pending;
}

TodayMatch _buildTodayMatch(
  _ActiveMatch entry,
  List<Team> myTeams,
  String userId,
) {
  final myTeam = myTeams.cast<Team?>().firstWhere(
        (t) =>
            t != null &&
            (t.id == entry.match.teamAId || t.id == entry.match.teamBId),
        orElse: () => null,
      );
  final iAmTeamA = myTeam != null && myTeam.id == entry.match.teamAId;

  final myCrest = myTeam == null
      ? const CrestStyle(
          color: CkColors.ink, mono: '??', name: 'Your team', city: null)
      : _crestFor(myTeam);
  final oppCrest = entry.opponent == null
      ? const CrestStyle(
          color: CkColors.muted, mono: 'VS', name: 'Opponent', city: null)
      : _crestFor(entry.opponent!);

  final live = entry.match.status == MatchStatus.live;
  final accepted = entry.match.status == MatchStatus.accepted;
  final ctx =
      'T${entry.match.format.oversPerInnings} · ${entry.match.format.playersPerTeam}-A-SIDE';
  final venue = entry.match.venue?.ground.toUpperCase();
  final phrase = live
      ? null
      : (accepted
          ? 'Ready to start'
          : (entry.incoming ? 'Incoming request' : 'Awaiting reply'));

  return TodayMatch(
    a: iAmTeamA ? myCrest : oppCrest,
    b: iAmTeamA ? oppCrest : myCrest,
    live: live,
    ctx: ctx,
    when: phrase,
    note: live ? entry.match.resultDescription : null,
    venue: venue,
  );
}
