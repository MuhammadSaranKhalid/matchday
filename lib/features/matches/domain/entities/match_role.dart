import 'match.dart';

/// What the current user does in a given match. Drives the role line on
/// the My Matches card ("Captain · pick XI", "On the XI · #7", "Optional").
///
/// Polymorphic player ids (claimed user_id OR unclaimed_id — see CLAUDE.md
/// §6.6) mean role inference is a `String` comparison against the captain
/// and squad fields, not an entity-based lookup.
enum MatchRoleKind {
  /// Captain of either team A or B.
  captain,

  /// In the playing XI (but not captain).
  xi,

  /// Assigned scorer for this match. v1 surface only — schema doesn't yet
  /// carry an explicit `scorer_id`, so this stays unreachable until the
  /// scorer flow lands.
  scoring,

  /// A friendly match the user is involved in (their team plays) but where
  /// they aren't captain, in the XI, or scoring. Optional attendance.
  optional,

  /// User is not on either side. Spectator. Cards in this state are typically
  /// filtered out of My Matches but we surface the enum so callers can
  /// disambiguate from `optional` when needed.
  spectator,
}

/// Resolve [userId]'s role on [match].
///
/// [userTeamIds] is the set of teams the user belongs to (either side).
/// [xiPlayerRefIds] is the set of `playerRefId`s present in the match's
/// playing XI — sourced from `matchPlayersProvider` by the caller. It is
/// optional because not every caller has the XI on hand (the deprecated
/// uuid[] columns on `matches` are gone; XI now lives in `match_players`).
/// Callers that omit it skip the XI-role branch and may report a player
/// as `optional` when they're actually in the XI.
///
/// If [userId] is empty, returns [MatchRoleKind.spectator].
MatchRoleKind roleOnMatch(
  Match match,
  String userId, {
  Set<String> userTeamIds = const {},
  Set<String> xiPlayerRefIds = const {},
  bool isScorer = false,
}) {
  if (userId.isEmpty) return MatchRoleKind.spectator;

  if (match.teamACaptain == userId || match.teamBCaptain == userId) {
    return MatchRoleKind.captain;
  }
  if (isScorer) {
    return MatchRoleKind.scoring;
  }
  if (xiPlayerRefIds.contains(userId)) {
    return MatchRoleKind.xi;
  }
  if (userTeamIds.contains(match.teamAId.value) ||
      userTeamIds.contains(match.teamBId.value)) {
    return MatchRoleKind.optional;
  }
  return MatchRoleKind.spectator;
}
