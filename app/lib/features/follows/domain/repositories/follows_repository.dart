import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/follow.dart';
import '../entities/follow_counts.dart';
import '../entities/follow_direction.dart';
import '../entities/follow_list_entry.dart';

/// Contract for the follows feature. Online-only per CLAUDE.md §1 constraint.
///
/// All three methods accept a [FollowTarget] so callers never deal with raw
/// strings — the polymorphism lives in the domain layer.
abstract class FollowsRepository {
  /// Follow a [target]. Returns the created [Follow] entity on success.
  ///
  /// May return [AuthFailure] if the user is not signed in, or
  /// [ServerFailure] for unexpected Supabase errors.
  Future<Either<Failure, Follow>> follow(FollowTarget target);

  /// Unfollow a [target]. Returns [unit] on success (or if the row was already
  /// absent — RLS will silently no-op a delete that matches nothing).
  Future<Either<Failure, Unit>> unfollow(FollowTarget target);

  /// Whether the signed-in user wants notifications about [target].
  ///
  /// Backed by `notification_mutes`, so it is only meaningful for
  /// a target the user actually follows; returns false when there is no row.
  Future<Either<Failure, bool>> areNotificationsEnabled(FollowTarget target);

  /// Turns notifications about [target] on or off. Requires an existing
  /// follow row — returns [NotFoundFailure] when the user does not follow
  /// [target].
  Future<Either<Failure, Unit>> setNotificationsEnabled(
    FollowTarget target, {
    required bool enabled,
  });

  /// Returns true if the signed-in user currently follows [target].
  Future<Either<Failure, bool>> isFollowing(FollowTarget target);

  /// Team ids the signed-in user follows. Drives the Matches board's
  /// "For you" cut, which is defined as a followed team playing, or a
  /// tournament you are in.
  Future<Either<Failure, List<String>>> listFollowedTeamIds();

  /// Returns a paginated list of a user's followers or following accounts.
  ///
  /// [userId]    — the profile being inspected (NOT necessarily the signed-in
  ///               user; the list is public per the follows RLS policy).
  /// [direction] — [FollowDirection.followers] to list people who follow
  ///               [userId]; [FollowDirection.following] for accounts [userId]
  ///               follows.
  /// [limit]     — max entries per page (default 100).
  /// [offset]    — zero-based page offset for pagination.
  ///
  /// The `you_follow` / `they_follow_you` flags in each entry are relative to
  /// the SIGNED-IN user (computed server-side by the edge function).
  Future<Either<Failure, List<FollowListEntry>>> getFollowList(
    UserId userId,
    FollowDirection direction, {
    int limit = 100,
    int offset = 0,
  });

  /// Returns the followers and following counts for [userId].
  ///
  /// Counts only user-to-user follows (target_type = 'user'), matching what
  /// the profile header displays. Team / tournament follows are excluded.
  Future<Either<Failure, FollowCounts>> getFollowCounts(UserId userId);
}
