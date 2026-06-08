import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/follow.dart';

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

  /// Returns true if the signed-in user currently follows [target].
  Future<Either<Failure, bool>> isFollowing(FollowTarget target);
}
