import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/explore_datasource_providers.dart';
import '../../data/repositories/explore_repository_impl.dart';
import '../../domain/entities/explore_results.dart';
import '../../domain/repositories/explore_repository.dart';

part 'explore_providers.g.dart';

/// Returns the ABSTRACT type — consumers never see the impl (CLAUDE.md §5.3).
@Riverpod(keepAlive: true)
ExploreRepository exploreRepository(Ref ref) =>
    ExploreRepositoryImpl(ref.watch(exploreRemoteDataSourceProvider));

/// The empty-query discovery content: live matches, recent teams, players to
/// follow.
///
/// A plain async provider rather than a method on [ExploreController],
/// because browse is a pure read with no imperative actions and no race to
/// defeat. Keeping it here also keeps the controller's `build()` free of the
/// state mutation that kicking it off from there would require — which
/// Riverpod rejects outright ("a provider rebuilt while the previous build
/// was still pending").
///
/// Refresh with `ref.invalidate(exploreBrowseProvider)`.
@riverpod
Future<ExploreBrowse> exploreBrowse(Ref ref) async {
  final res = await ref.watch(exploreRepositoryProvider).browse();
  // AsyncValue carries the error; rethrowing the Failure keeps it typed so
  // the screen can still branch on NetworkFailure vs ServerFailure.
  return res.fold((failure) => throw failure, (browse) => browse);
}
