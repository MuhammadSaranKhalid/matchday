import 'package:equatable/equatable.dart';

/// Snapshot of a user's followers and following counts.
///
/// Retrieved via [FollowsRepository.getFollowCounts]. Does NOT include counts
/// for team or tournament follows — only person-to-person user follows, which
/// is what the profile header displays.
class FollowCounts extends Equatable {
  const FollowCounts({required this.followers, required this.following});

  final int followers;
  final int following;

  @override
  List<Object?> get props => [followers, following];
}
