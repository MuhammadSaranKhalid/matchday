import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user.dart';

/// A single entry in a followers or following list.
///
/// Returned by [FollowsRepository.getFollowList]. Each entry carries enough
/// profile data to render an avatar + name row, plus the mutual-follow flags
/// needed to render "follows you back" / "mutual" badges without a second
/// request.
class FollowListEntry extends Equatable {
  const FollowListEntry({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.youFollow,
    required this.theyFollowYou,
  });

  final UserId userId;
  final String displayName;
  final String username;
  final String? avatarUrl;

  /// True if the current signed-in user follows this person.
  final bool youFollow;

  /// True if this person follows the current signed-in user.
  final bool theyFollowYou;

  /// Convenience: both parties follow each other.
  bool get isMutual => youFollow && theyFollowYou;

  @override
  List<Object?> get props => [
        userId,
        displayName,
        username,
        avatarUrl,
        youFollow,
        theyFollowYou,
      ];
}
