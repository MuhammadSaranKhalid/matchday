import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/match_pool_repository_impl.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_pool_application.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/repositories/match_pool_repository.dart';
import 'matches_feed_providers.dart';

part 'match_pool_providers.g.dart';

// ─── Repositories ───────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
MatchPoolRepository matchPoolRepository(Ref ref) {
  return MatchPoolRepositoryImpl(
    requestsDataSource: ref.watch(matchRequestsRemoteDataSourceProvider),
  );
}

// ─── Presentation Providers ──────────────────────────────────────────────────

String _formatMatchTime(DateTime dt) {
  final now = DateTime.now();
  final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final tomorrow = now.add(const Duration(days: 1));
  final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;

  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  final timeStr = '$hour:$min $ampm';

  if (isToday) return 'Today · $timeStr';
  if (isTomorrow) return 'Tomorrow · $timeStr';

  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final dow = days[dt.weekday - 1];
  final mon = months[dt.month - 1];
  return '$dow, $mon ${dt.day} · $timeStr';
}

/// Open match pool challenges from other teams, mapped with team metadata.
@riverpod
Future<List<OpenMatchPoolItem>> openMatchPool(Ref ref) async {
  final repo = ref.watch(matchPoolRepositoryProvider);
  final myTeams = (await ref.watch(myTeamsProvider.future));
  final myTeamIds = myTeams.map((t) => t.id.value).toSet();

  final result = await repo.getOpenPoolChallenges();
  final challenges = result.fold<List<MatchRequest>>(
    (failure) => throw Exception(failure.message),
    (list) => list,
  );

  // Filter out any broadcasts hosted by the user's own teams
  final otherTeamChallenges = challenges
      .where((c) => !myTeamIds.contains(c.fromTeamId.value))
      .toList();

  final items = <OpenMatchPoolItem>[];
  for (final req in otherTeamChallenges) {
    final fromTeam = await ref.watch(teamProvider(req.fromTeamId.value).future);
    items.add(
      OpenMatchPoolItem(
        request: req,
        fromTeam: fromTeam,
        formatLabel: '${req.proposedFormat?.oversPerInnings ?? 20} Overs · ${req.proposedFormat?.ballType.wire.toUpperCase() ?? 'TAPE'}',
        venue: req.proposedVenue ?? 'Lahore Ground',
        shareCode: req.shareCode ?? '—',
        timeLabel: req.proposedStartTime != null
            ? _formatMatchTime(req.proposedStartTime!)
            : 'Flexible',
      ),
    );
  }

  return items;
}

/// Active match pool challenges hosted by user's own teams.
@riverpod
Future<List<OpenMatchPoolItem>> myPoolRequests(Ref ref) async {
  final repo = ref.watch(matchPoolRepositoryProvider);
  final myTeams = (await ref.watch(myTeamsProvider.future));
  final myTeamIds = myTeams.map((t) => t.id).toSet();

  final result = await repo.getMyPoolBroadcasts(myTeamIds: myTeamIds);
  final challenges = result.fold<List<MatchRequest>>(
    (failure) => throw Exception(failure.message),
    (list) => list,
  );

  final items = <OpenMatchPoolItem>[];
  for (final req in challenges) {
    final fromTeam = await ref.watch(teamProvider(req.fromTeamId.value).future);
    items.add(
      OpenMatchPoolItem(
        request: req,
        fromTeam: fromTeam,
        formatLabel: '${req.proposedFormat?.oversPerInnings ?? 20} Overs · ${req.proposedFormat?.ballType.wire.toUpperCase() ?? 'TAPE'}',
        venue: req.proposedVenue ?? 'Lahore Ground',
        shareCode: req.shareCode ?? '—',
        timeLabel: req.proposedStartTime != null
            ? _formatMatchTime(req.proposedStartTime!)
            : 'Flexible',
      ),
    );
  }

  return items;
}

/// Applications for a specific match pool challenge.
@riverpod
Future<List<MatchPoolApplication>> challengePoolApplications(
  Ref ref,
  String requestId,
) async {
  final repo = ref.watch(matchPoolRepositoryProvider);
  final result = await repo.listPoolApplications(MatchRequestId(requestId));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (apps) => apps,
  );
}

/// The Pool board's facets — `Pool.dc.html` artboard 01.
///
/// Four, and only four. The board is a place to scan, not a query builder, so
/// the facets cover the two axes a captain actually chooses between (what the
/// ball is made of, and whether it is happening today) rather than every
/// column the row has.
enum PoolFacet {
  all('All'),
  tapeBall('Tape-ball'),
  leather('Leather'),
  today('Today');

  const PoolFacet(this.label);

  /// Rendered uppercase by the chip; stored cased for readability.
  final String label;
}

/// Selected facet on the Pool board.
@riverpod
class OpenMatchPoolFilter extends _$OpenMatchPoolFilter {
  @override
  PoolFacet build() => PoolFacet.all;

  void setFilter(PoolFacet facet) => state = facet;
}

/// The board's contents — open challenges narrowed by the selected facet.
@riverpod
Future<List<OpenMatchPoolItem>> filteredOpenMatchPool(Ref ref) async {
  final items = await ref.watch(openMatchPoolProvider.future);
  final facet = ref.watch(openMatchPoolFilterProvider);

  return switch (facet) {
    PoolFacet.all => items,
    PoolFacet.tapeBall =>
      items.where((i) => i.ballType == MatchBallType.tape).toList(),
    PoolFacet.leather =>
      items.where((i) => i.ballType == MatchBallType.leather).toList(),
    PoolFacet.today => items.where((i) {
        final start = i.startTime;
        if (start == null) return false;
        final now = DateTime.now();
        return start.year == now.year &&
            start.month == now.month &&
            start.day == now.day;
      }).toList(),
  };
}

/// Whether the viewer manages a team, and so may post or apply.
///
/// False puts the board behind artboard 05's paper gate: still readable, but
/// no card is actionable. Membership alone is not enough — the design says
/// "only team managers can post challenges or apply to play".
@riverpod
Future<bool> viewerManagesTeam(Ref ref) async {
  final userId = ref.watch(currentUserStreamProvider).value?.id.value;
  if (userId == null) return false;
  final teams = await ref.watch(myTeamsProvider.future);
  return teams.any((t) => t.isManagedBy(userId));
}
