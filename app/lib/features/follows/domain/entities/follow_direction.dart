/// Direction for a follow-list query: fetching a user's followers, or the
/// accounts they follow.
enum FollowDirection {
  followers('followers'),
  following('following');

  const FollowDirection(this.wire);

  /// Wire string sent in the edge-function request body.
  final String wire;
}
