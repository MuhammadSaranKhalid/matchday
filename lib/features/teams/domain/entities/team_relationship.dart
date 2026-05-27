import 'team.dart';
import 'team_member.dart';

/// The signed-in user's relationship to a team — the single domain source of
/// truth that both the My Teams list and the Team Page derive from. Each
/// screen maps this to its own presentation enum (e.g. `MyTeamsRole`,
/// `TeamPageViewer`); the decision itself lives here, not in the controllers.
enum TeamRelationship {
  owner,
  manager,
  captain,
  viceCaptain,
  wicketKeeper,
  player,

  /// Not affiliated — the user owns/manages nothing here and isn't on the
  /// roster (or the roster wasn't loaded). Presentation decides how to render
  /// this (e.g. stranger vs. private-stranger based on team privacy).
  none,
}

extension TeamRelationshipX on Team {
  /// Classifies [userId]'s relationship to this team. [rosterRole] is the
  /// user's claimed roster role when known (Team Page passes it); pass null
  /// when the roster isn't loaded (My Teams) or the user isn't a roster member.
  ///
  /// Ownership/management take precedence over a roster role.
  TeamRelationship relationshipFor({
    required String? userId,
    MemberRole? rosterRole,
  }) {
    if (userId == null) return TeamRelationship.none;
    if (ownerId == userId) return TeamRelationship.owner;
    if (managers.contains(userId)) return TeamRelationship.manager;
    return switch (rosterRole) {
      MemberRole.captain => TeamRelationship.captain,
      MemberRole.viceCaptain => TeamRelationship.viceCaptain,
      MemberRole.wicketKeeper => TeamRelationship.wicketKeeper,
      MemberRole.player => TeamRelationship.player,
      null => TeamRelationship.none,
    };
  }
}
