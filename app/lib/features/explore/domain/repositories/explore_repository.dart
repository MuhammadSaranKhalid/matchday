import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_results.dart';

/// Unified search + discovery across players, teams, matches and
/// tournaments.
///
/// Online-only, like every feature outside the messages exemption: both
/// methods hit the `search-all` edge function directly. There is no local
/// cache — a stale result list is worse than a spinner.
abstract class ExploreRepository {
  /// Text search. [query] must already be trimmed and >= 2 characters; the
  /// controller enforces that so a keystroke below the threshold never costs
  /// a round-trip.
  ///
  /// [category] narrows to one group for the "See all" drill-down; null
  /// returns every group. Defaulting to all is deliberate — NN/g's
  /// scoped-search finding is that a pre-selected scope makes users conclude
  /// the app has nothing.
  Future<Either<Failure, ExploreResults>> search(
    String query, {
    ExploreCategory? category,
    int? limit,
    Future<void>? cancelSignal,
  });

  /// The empty-query discovery state: live matches, open tournaments, recent
  /// teams, players to follow.
  Future<Either<Failure, ExploreBrowse>> browse();
}
