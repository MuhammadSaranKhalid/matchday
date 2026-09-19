import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/teams_datasource_providers.dart';
import '../../data/repositories/teams_repository_impl.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_search_result.dart';
import '../../domain/repositories/teams_repository.dart';

part 'teams_providers.g.dart';

@Riverpod(keepAlive: true)
TeamsRepository teamsRepository(Ref ref) => TeamsRepositoryImpl(
      remote: ref.watch(teamsRemoteDataSourceProvider),
    );

/// Scoped one-shot team profile read.
@riverpod
Future<Team?> team(Ref ref, String teamId) async {
  final result =
      await ref.watch(teamsRepositoryProvider).getTeam(TeamId(teamId));
  return result.fold(
    (failure) => throw FailureWrapper(failure),
    (value) => value,
  );
}

/// One-shot public/discoverable team list for selectors such as direct
/// challenges. This replaces the old permanent `allTeams` stream.
@riverpod
Future<List<Team>> discoverableTeams(Ref ref, String query) async {
  final repo = ref.watch(teamsRepositoryProvider);
  final q = query.trim();
  final search = await repo.searchTeams(
    query: q.isEmpty ? null : q,
    limit: 50,
  );
  final results = search.fold<List<TeamSearchResult>>(
    (failure) => throw FailureWrapper(failure),
    (value) => value,
  );
  if (results.isEmpty) return const [];

  final hydrated = await repo.getTeamsByIds(
    results.map((result) => result.teamId),
  );
  final byId = hydrated.fold<Map<String, Team>>(
    (failure) => throw FailureWrapper(failure),
    (value) => value,
  );

  return [
    for (final result in results)
      if (byId[result.teamId.value] case final team?) team,
  ];
}
