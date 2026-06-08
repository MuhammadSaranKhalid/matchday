import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../teams/domain/entities/team.dart';
import '../../data/datasources/follows_datasource_providers.dart';
import '../../data/repositories/follows_repository_impl.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_counts.dart';
import '../../domain/entities/follow_direction.dart';
import '../../domain/entities/follow_list_entry.dart';
import '../../domain/repositories/follows_repository.dart';

part 'follows_providers.g.dart';

/// The canonical [FollowsRepository] provider.
///
/// Returns the ABSTRACT type [FollowsRepository] — consumers never see the
/// implementation, per CLAUDE.md §5.3 DI rules.
@Riverpod(keepAlive: true)
FollowsRepository followsRepository(Ref ref) =>
    FollowsRepositoryImpl(ref.watch(followsRemoteDataSourceProvider));

/// Autodispose family that checks whether the signed-in user follows a target.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom [FollowTarget] object in the family key).
///
/// [targetTypeWire] ∈ {'user', 'team', 'tournament'}
/// [targetId]       — UUID of the target entity
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] and can render error copy without extra boilerplate.
@riverpod
Future<bool> isFollowing(
  Ref ref,
  String targetTypeWire,
  String targetId,
) async {
  final repo = ref.watch(followsRepositoryProvider);
  final target = _targetFromWire(targetTypeWire, targetId);
  final result = await repo.isFollowing(target);
  return result.fold((f) => throw FailureWrapper(f), (v) => v);
}

/// Autodispose family that fetches a user's followers or following list.
///
/// Parameters are raw strings so Riverpod can serialise the family cache key
/// cleanly (no custom wrapper types in the key).
///
/// [userId]    — UUID of the profile to inspect.
/// [direction] — wire string, either 'followers' or 'following'.
///
/// Defaults to 100 entries with offset 0. For pagination, call
/// [FollowsRepository.getFollowList] directly through the repository provider.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.
@riverpod
Future<List<FollowListEntry>> followList(
  Ref ref,
  String userId,
  String direction,
) async {
  final repo = ref.watch(followsRepositoryProvider);
  final result = await repo.getFollowList(
    UserId(userId),
    FollowDirection.values.firstWhere(
      (d) => d.wire == direction,
      orElse: () => FollowDirection.followers,
    ),
  );
  return result.fold((f) => throw FailureWrapper(f), (v) => v);
}

/// Autodispose family that fetches the followers and following counts for a
/// user profile.
///
/// [userId] — UUID of the profile to inspect.
///
/// Throws [FailureWrapper] on [Left] so the consuming widget receives an
/// [AsyncError] it can display without extra boilerplate.
@riverpod
Future<FollowCounts> followCounts(Ref ref, String userId) async {
  final repo = ref.watch(followsRepositoryProvider);
  final result = await repo.getFollowCounts(UserId(userId));
  return result.fold((f) => throw FailureWrapper(f), (v) => v);
}

// ---------------------------------------------------------------------------
// Internal helper — converts wire strings to the sealed domain [FollowTarget].
// Lives here rather than in the DTO to avoid pulling presentation into data.
// ---------------------------------------------------------------------------

FollowTarget _targetFromWire(String targetTypeWire, String targetId) {
  switch (targetTypeWire) {
    case 'user':
      return UserFollowTarget(UserId(targetId));
    case 'team':
      return TeamFollowTarget(TeamId(targetId));
    default:
      // Covers 'tournament' + any future target types.
      return TournamentFollowTarget(targetId);
  }
}
