import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/follow.dart';
import '../providers/follows_providers.dart';

part 'follow_toggle_controller.g.dart';

/// Manages the follow/unfollow toggle for a single target.
///
/// The family key is `(targetTypeWire, targetId)` — plain strings to keep
/// Riverpod's family cache key serialisable without a custom [FollowTarget].
///
/// State: [AsyncValue<bool>]
///   AsyncLoading  — initial fetch or in-flight toggle
///   AsyncData(true)  — user is following
///   AsyncData(false) — user is not following
///   AsyncError  — initial fetch failed (widget should show a disabled button)
///
/// Bare `@riverpod` (autodispose) — the controller disposes when no widget
/// is subscribed, e.g. when the team page or profile page is popped.
@riverpod
class FollowToggle extends _$FollowToggle {
  @override
  Future<bool> build(String targetTypeWire, String targetId) {
    // Delegate to the isFollowing family provider so both share the same
    // cached result; invalidating isFollowingProvider below also works.
    return ref.watch(isFollowingProvider(targetTypeWire, targetId).future);
  }

  /// Toggle the follow state for the current target optimistically.
  ///
  /// 1. Read current state.
  /// 2. Flip state optimistically.
  /// 3. Call repo follow/unfollow.
  /// 4a. On success: keep optimistic state, invalidate the [isFollowing] cache.
  /// 4b. On failure: revert to previous state, set AsyncError.
  Future<void> toggle() async {
    final previous = state;
    final currentValue = state.value;
    if (currentValue == null) return; // Don't toggle during initial load.

    final optimistic = !currentValue;
    state = AsyncData(optimistic);

    final repo = ref.read(followsRepositoryProvider);
    final target = _targetFromWire(targetTypeWire, targetId);

    final result = optimistic
        ? await repo.follow(target)
        : await repo.unfollow(target);

    result.fold(
      (failure) {
        // Revert optimistic flip and surface the error.
        state = AsyncError(failure, StackTrace.current);
        // Restore the previous known-good state after a short delay so the
        // button doesn't stay stuck on the error state permanently.
        Future<void>.delayed(
          const Duration(milliseconds: 1500),
          () {
            if (state is AsyncError) state = previous;
          },
        );
      },
      (_) {
        // Confirm the optimistic state and bust the shared isFollowing cache
        // so any other consumer (e.g. a follower-count widget) refreshes.
        ref.invalidate(isFollowingProvider(targetTypeWire, targetId));
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helper — mirrors the one in follows_providers.dart.
// Kept local to avoid a circular import: controller → providers → controller.
// ---------------------------------------------------------------------------

FollowTarget _targetFromWire(String targetTypeWire, String targetId) {
  switch (targetTypeWire) {
    case 'user':
      return UserFollowTarget(UserId(targetId));
    case 'team':
      return TeamFollowTarget(TeamId(targetId));
    default:
      return TournamentFollowTarget(targetId);
  }
}
