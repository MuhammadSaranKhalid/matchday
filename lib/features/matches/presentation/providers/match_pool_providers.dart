import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../teams/presentation/providers/teams_providers.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/match_pool_repository_impl.dart';
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
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '$hour:$min $ampm';
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
Future<List<OpenMatchPoolItem>> myPoolBroadcasts(Ref ref) async {
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

/// Selected format filter for the Open Match Pool screen.
@riverpod
class OpenMatchPoolFilter extends _$OpenMatchPoolFilter {
  @override
  String build() => 'All';

  void setFilter(String filter) => state = filter;
}

/// Filtered open match pool items strictly derived from domain & filter state.
@riverpod
Future<List<OpenMatchPoolItem>> filteredOpenMatchPool(Ref ref) async {
  final items = await ref.watch(openMatchPoolProvider.future);
  final filter = ref.watch(openMatchPoolFilterProvider);

  if (filter == 'All') return items;

  return items.where((item) {
    if (filter == 'Tape Ball') {
      return item.formatLabel.toUpperCase().contains('TAPE');
    }
    if (filter == 'Leather') {
      return item.formatLabel.toUpperCase().contains('LEATHER');
    }
    if (filter == '20 Overs') {
      return item.formatLabel.contains('20');
    }
    if (filter == '10 Overs') {
      return item.formatLabel.contains('10');
    }
    return true;
  }).toList();
}
