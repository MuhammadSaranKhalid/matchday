import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/explore_results.dart';
import '../providers/explore_providers.dart';

part 'explore_see_all_controller.g.dart';

/// Backs the single-category drill-down ("See all — Teams").
///
/// A plain [AsyncNotifier] family rather than a stateful Notifier: this
/// screen has a fixed query and category for its whole lifetime, so there is
/// no debounce and no race to defeat — the two things that forced
/// [ExploreController] to hand-roll its state.
@riverpod
class ExploreSeeAll extends _$ExploreSeeAll {
  /// The drill-down pulls a deeper page than the grouped view, which caps
  /// each group at a preview-sized handful.
  static const _limit = 50;

  @override
  Future<ExploreResults> build(String query, ExploreCategory category) async {
    final res = await ref.read(exploreRepositoryProvider).search(
          query,
          category: category,
          limit: _limit,
        );
    return res.fold(
      // AsyncNotifier surfaces errors through AsyncError; rethrowing the
      // Failure keeps it typed so the screen can still branch on it.
      (failure) => throw failure,
      (results) => results,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
