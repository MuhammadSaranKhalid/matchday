// Pure function: turn the composed real-data [TeamsListView] (teams + active
// matches) into the richer [MyTeamsView] shape the new screen consumes.
//
// Today's reality:
//   • Sections that have backend support — "You lead" (owner/manager), "You
//     play" (everyone else), and the "Today" hero card — are populated.
//   • Sections that DON'T have backend support yet — invites, following,
//     archived, pending, needsYou, suggested — stay empty. The view shape
//     short-circuits empty sections so the screen still looks intentional.
//
// When backends ship for the other sections, extend this adapter; the screen
// won't need to change.
import '../../../../core/theme/circk_theme.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/team.dart';
import '../widgets/my_teams/crest_palette.dart';
import '../widgets/team_avatar.dart';
import 'my_teams_view.dart';
import 'teams_list_view.dart';

/// Adapter from the existing real-data view to the new presentation shape.
///
/// [onAddPlayers] is called with the team id when the user taps the
/// "Add players" action on the first-team banner. Pass it from the screen
/// to wire navigation to `/teams/{id}/manage`.
MyTeamsView buildMyTeamsViewFromReal({
  required TeamsListView source,
  required String userId,
  void Function(String teamId)? onAddPlayers,
}) {
  final teams = source.teams;
  final activeMatches = source.activeMatches;

  // ── 1. Bucket teams by the signed-in user's relationship ────────────
  final captainBucket = <TeamRowVm>[];
  final playingBucket = <TeamRowVm>[];

  for (final team in teams) {
    final isOwner = team.ownerId == userId;
    final isManager = team.managers.contains(userId);
    final role = isOwner
        ? MyTeamsRole.captain
        : isManager
            ? MyTeamsRole.manager
            : MyTeamsRole.player;
    final row = TeamRowVm(
      crest: _crestFor(team),
      role: role,
      meta: team.city,
    );
    if (role == MyTeamsRole.captain || role == MyTeamsRole.manager) {
      captainBucket.add(row);
    } else {
      playingBucket.add(row);
    }
  }

  // ── 2. Pick the hero match: live > accepted > pending ───────────────
  TodayMatch? today;
  final picked = _pickHeroMatch(activeMatches);
  if (picked != null) {
    today = _buildTodayMatch(picked, teams, userId);
  }

  // ── 3. Detect the "first team · onboarding" case (matches the JSX
  //      `firstTeam` fixture). Triggered when the user has exactly one
  //      team, they own it, and there are no active matches yet.
  final isFirstTeam = teams.length == 1 &&
      teams.first.ownerId == userId &&
      activeMatches.isEmpty;

  String? subtitle;
  var needsYou = const <NeedsYouItem>[];
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
        meta: 'You · ${_relativeTime(team.createdAt)}',
      ),
    ];
    needsYou = [
      NeedsYouItem(
        role: MyTeamsRole.captain,
        tone: NeedsYouTone.amber,
        subTag: team.name.toUpperCase(),
        title: 'Add players to your roster',
        body:
            'You created this team ${_relativeTime(team.createdAt)}. Invite at least 6 players to start scoring matches.',
        actions: [
          NeedsYouAction(
            'Add players',
            onTap: onAddPlayers == null
                ? null
                : () => onAddPlayers(team.id.value),
          ),
          const NeedsYouAction('Later'),
        ],
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
    needsYou: needsYou,
    teams: TeamGroups(captain: captain, playing: playingBucket),
  );
}

/// Human-readable relative time — kept inline so the adapter has no
/// extra package dependency.
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
      mono: teamMonogram(team.name),
      name: team.name,
      city: team.city,
    );

TeamMatchEntry? _pickHeroMatch(List<TeamMatchEntry> active) {
  TeamMatchEntry? live;
  TeamMatchEntry? accepted;
  TeamMatchEntry? pending;
  for (final entry in active) {
    switch (entry.match.status) {
      case MatchStatus.live:
        live ??= entry;
      case MatchStatus.accepted:
        accepted ??= entry;
      case MatchStatus.pending:
        pending ??= entry;
      default:
        break;
    }
  }
  return live ?? accepted ?? pending;
}

TodayMatch _buildTodayMatch(
  TeamMatchEntry entry,
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
      : (accepted ? 'Ready to start' : (entry.incoming ? 'Incoming request' : 'Awaiting reply'));

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
