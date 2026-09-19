import '../../domain/entities/team_membership.dart';

/// Minimal state for the My Teams screen.
///
/// The page owns only two concepts:
///   - teams the user can administer
///   - teams the user participates in without administrative authority
///
/// Matches, invites, discovery, follows, archived buckets and filters are not
/// part of this screen state.
class TeamsListState {
  const TeamsListState({
    required this.managed,
    required this.playing,
  });

  const TeamsListState.empty()
      : managed = const [],
        playing = const [];

  factory TeamsListState.fromMemberships(
    List<TeamMembership> memberships,
  ) {
    final managed = <TeamMembership>[];
    final playing = <TeamMembership>[];

    for (final membership in memberships) {
      if (membership.canManage) {
        managed.add(membership);
      } else {
        playing.add(membership);
      }
    }

    return TeamsListState(
      managed: List<TeamMembership>.unmodifiable(managed),
      playing: List<TeamMembership>.unmodifiable(playing),
    );
  }

  final List<TeamMembership> managed;
  final List<TeamMembership> playing;

  bool get isEmpty => managed.isEmpty && playing.isEmpty;
  int get count => managed.length + playing.length;
}
