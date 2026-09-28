/// Canonical link factory for deep linking and sharing.
/// Centralizes URL schemes across the app.
class AppLinks {
  const AppLinks._();

  static const String baseDomain = 'https://joinmatchday.com';

  /// Link to a specific post: https://joinmatchday.com/posts/:id
  static String post(String postId) => '$baseDomain/posts/$postId';

  /// Link to a user profile: https://joinmatchday.com/u/:username
  static String profile(String username) => '$baseDomain/u/$username';

  /// Link to a team profile: https://joinmatchday.com/teams/:id
  static String team(String teamId) => '$baseDomain/teams/$teamId';

  /// Link to a tournament: https://joinmatchday.com/tournaments/:id
  static String tournament(String tournamentId) => '$baseDomain/tournaments/$tournamentId';

  /// Link to a match: https://joinmatchday.com/matches/:id
  static String match(String matchId) => '$baseDomain/matches/$matchId';
}
