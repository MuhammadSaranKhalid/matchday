import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/innings_summary.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
import 'matches_providers.dart';

part 'matches_feed_providers.g.dart';

/// Models a displayable live match card with live innings state and team metadata.
class PublicLiveMatchItem {
  const PublicLiveMatchItem({
    required this.match,
    this.teamA,
    this.teamB,
    this.scoreA = '—',
    this.scoreB = '—',
    this.need = 'Match in progress',
    this.rate = '',
    this.scorerName,
  });

  final Match match;
  final Team? teamA;
  final Team? teamB;
  final String scoreA;
  final String scoreB;
  final String need;
  final String rate;
  final String? scorerName;
}

/// Models a displayable upcoming fixture card.
class PublicUpcomingMatchItem {
  const PublicUpcomingMatchItem({
    required this.match,
    this.teamA,
    this.teamB,
    required this.whenFormatted,
    required this.contextLabel,
    required this.venue,
    this.isToday = false,
  });

  final Match match;
  final Team? teamA;
  final Team? teamB;
  final String whenFormatted;
  final String contextLabel;
  final String venue;
  final bool isToday;
}

/// Models a displayable past match result card.
class PublicRecentMatchItem {
  const PublicRecentMatchItem({
    required this.match,
    this.teamA,
    this.teamB,
    this.scoreA = '—',
    this.scoreB = '—',
    required this.resultSummary,
    required this.contextLabel,
  });

  final Match match;
  final Team? teamA;
  final Team? teamB;
  final String scoreA;
  final String scoreB;
  final String resultSummary;
  final String contextLabel;
}

/// Models an open pool challenge broadcast item.
class OpenMatchPoolItem {
  const OpenMatchPoolItem({
    required this.request,
    this.fromTeam,
    required this.formatLabel,
    required this.venue,
    required this.shareCode,
    required this.timeLabel,
  });

  final MatchRequest request;
  final Team? fromTeam;
  final String formatLabel;
  final String venue;
  final String shareCode;
  final String timeLabel;
}

/// Aggregated state container for the main Matches Tab.
class MatchesFeedState {
  const MatchesFeedState({
    this.live = const [],
    this.upcoming = const [],
    this.recent = const [],
    this.openPool = const [],
  });

  final List<PublicLiveMatchItem> live;
  final List<PublicUpcomingMatchItem> upcoming;
  final List<PublicRecentMatchItem> recent;
  final List<OpenMatchPoolItem> openPool;

  int get liveCount => live.length;
  int get upcomingCount => upcoming.length;
  int get recentCount => recent.length;
  int get poolCount => openPool.length;
}

@riverpod
Future<MatchesFeedState> matchesFeed(Ref ref) async {
  // 1. Fetch public matches via domain use case
  final matchesResult = await ref.watch(listMyMatchesUseCaseProvider)();
  final allMatches = matchesResult.fold<List<Match>>(
    (_) => const [],
    (list) => list,
  );

  // 2. Fetch all challenges / open pool requests via domain use case
  final challengesResult = await ref.watch(listMyMatchChallengesUseCaseProvider)();
  final allChallenges = challengesResult.fold<List<MatchRequest>>(
    (_) => const [],
    (list) => list,
  );

  // 3. Collect unique team IDs
  final teamIds = <String>{};
  for (final m in allMatches) {
    teamIds.add(m.teamAId.value);
    teamIds.add(m.teamBId.value);
  }
  for (final c in allChallenges) {
    teamIds.add(c.fromTeamId.value);
    if (c.toTeamId != null) teamIds.add(c.toTeamId!.value);
  }

  // 4. Resolve teams
  final teamsRepo = ref.watch(teamsRepositoryProvider);
  final teamsById = <String, Team>{};
  if (teamIds.isNotEmpty) {
    await Future.wait(
      teamIds.map((id) async {
        final res = await teamsRepo.getTeam(TeamId(id));
        final team = res.fold((_) => null, (t) => t);
        if (team != null) teamsById[id] = team;
      }),
    );
  }

  // 5. Partition matches
  final liveMatches = allMatches.where((m) => m.status.isLive || m.status == MatchStatus.toss).toList();
  final upcomingMatches = allMatches.where((m) => m.status.isUpcoming).toList();
  final pastMatches = allMatches.where((m) => m.status.isPast).toList();

  // Innings for past matches via domain use case
  Map<MatchId, List<InningsSummary>> inningsByMatch = const {};
  if (pastMatches.isNotEmpty) {
    final res = await ref
        .watch(listInningsForMatchesUseCaseProvider)(pastMatches.map((m) => m.id));
    inningsByMatch = res.fold((_) => const {}, (map) => map);
  }

  // Map Live Items
  final liveItems = [
    for (final m in liveMatches)
      PublicLiveMatchItem(
        match: m,
        teamA: teamsById[m.teamAId.value],
        teamB: teamsById[m.teamBId.value],
        scoreA: m.tossWonBy != null ? 'Innings in progress' : 'Toss underway',
        scoreB: '—',
        need: m.status == MatchStatus.toss ? 'Toss completed · Lineups locking' : 'Match live',
        rate: m.format.oversPerInnings > 0 ? '${m.format.oversPerInnings} Overs Match' : 'Live Friendly',
      ),
  ];

  // Map Upcoming Items
  final now = DateTime.now();
  final upcomingItems = [
    for (final m in upcomingMatches)
      PublicUpcomingMatchItem(
        match: m,
        teamA: teamsById[m.teamAId.value],
        teamB: teamsById[m.teamBId.value],
        whenFormatted: m.scheduledStartTime != null
            ? _formatMatchTime(m.scheduledStartTime!)
            : 'Scheduled',
        contextLabel: m.format.oversPerInnings > 0
            ? '${m.format.oversPerInnings} Overs · ${m.format.ballType.wire.toUpperCase()}'
            : 'Friendly Fixture',
        venue: m.venue?.ground ?? 'Ground TBD',
        isToday: m.scheduledStartTime != null && _isSameDay(m.scheduledStartTime!, now),
      ),
  ];

  // Map Recent Items
  final recentItems = [
    for (final m in pastMatches)
      PublicRecentMatchItem(
        match: m,
        teamA: teamsById[m.teamAId.value],
        teamB: teamsById[m.teamBId.value],
        scoreA: _scoreLabel(inningsByMatch[m.id], 1),
        scoreB: _scoreLabel(inningsByMatch[m.id], 2),
        resultSummary: m.resultDescription ?? 'Match concluded',
        contextLabel: m.format.oversPerInnings > 0
            ? '${m.format.oversPerInnings} Overs · Final'
            : 'Match Result',
      ),
  ];

  // Map Open Pool Items (strictly open matchmaking broadcast pool with no target team)
  final openPoolRequests = allChallenges
      .where((c) => c.status == MatchRequestStatus.pending && c.toTeamId == null)
      .toList();
  final poolItems = [
    for (final req in openPoolRequests)
      OpenMatchPoolItem(
        request: req,
        fromTeam: teamsById[req.fromTeamId.value],
        formatLabel: '${req.proposedFormat?.oversPerInnings ?? 20} Overs · ${req.proposedFormat?.ballType.wire.toUpperCase() ?? 'TAPE'}',
        venue: req.proposedVenue ?? 'Lahore Ground',
        shareCode: req.shareCode ?? '—',
        timeLabel: req.proposedStartTime != null
            ? _formatMatchTime(req.proposedStartTime!)
            : 'Today',
      ),
  ];

  return MatchesFeedState(
    live: liveItems,
    upcoming: upcomingItems,
    recent: recentItems,
    openPool: poolItems,
  );
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatMatchTime(DateTime dt) {
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '$hour:$min $ampm';
}

String _scoreLabel(List<InningsSummary>? summaries, int inningsNum) {
  if (summaries == null || summaries.isEmpty) return '—';
  final match = summaries.where((s) => s.inningsNumber == inningsNum).firstOrNull;
  if (match == null) return '—';
  final overs = match.legalBallsFaced ~/ 6;
  final balls = match.legalBallsFaced % 6;
  final oversStr = '$overs.$balls';
  return '${match.totalRuns}/${match.totalWickets} ($oversStr)';
}
