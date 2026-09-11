import 'team.dart';
import 'team_member.dart';

/// The signed-in user's relationship to a team, and what it lets them do.
///
/// This file always claimed to be "the single domain source of truth". Before
/// 2026-09-10 it wasn't quite: it reconciled TWO sources — `teams.managers`
/// for authority and `TeamMember.role` for the on-field role — which meant a
/// captain classified as `captain` here held no powers anywhere, while
/// `_can_score_innings` in SQL happily let them score. One ladder, one source.
///
/// Every screen maps this to its own presentation vocabulary (`MyTeamsRole`,
/// `TeamPageViewer`); the decision itself lives here, and so do the
/// capabilities. See docs/team-roles-design.md.
///
/// The `can*` getters mirror the SQL predicates exactly:
///   * `is_team_manager()` → [canEditRoster] and friends (manager and above)
///   * `is_team_captain()` → [canPickXi] / [canScore]   (captain and above)
/// If you change one side, change the other in the same commit.
enum TeamRelationship {
  owner,
  manager,
  captain,
  player,

  /// Not affiliated — not on the roster (or the roster wasn't loaded).
  /// Presentation decides how to render this (stranger vs. private-stranger
  /// based on team privacy).
  none;

  // ---------------------------------------------------------------------------
  // Rungs
  // ---------------------------------------------------------------------------

  /// Staff: may run the club. Mirrors `is_team_manager()`.
  bool get isStaff => this == owner || this == manager;

  /// Match-day authority. Mirrors `is_team_captain()`.
  bool get hasMatchAuthority => isStaff || this == captain;

  /// On the roster in any capacity.
  bool get isMember => this != none;

  // ---------------------------------------------------------------------------
  // Capabilities — what each rung unlocks
  // ---------------------------------------------------------------------------

  /// Add, remove and edit players; open the Manage console at all.
  bool get canEditRoster => isStaff;

  /// Send invites and decide join requests.
  bool get canInvite => isStaff;

  /// Post as the team (`can_act_for_post_context` → `is_team_manager`).
  bool get canPostAsTeam => isStaff;

  /// Edit the team profile — name, crest, colours, ground, privacy.
  bool get canEditTeam => isStaff;

  /// Register the team for a tournament (`tournament_teams_insert_manager`).
  bool get canRegisterForTournament => isStaff;

  /// Send, accept, counter or cancel a challenge, and apply to the open pool.
  /// Gated on `is_team_manager` server-side, so a captain cannot create the
  /// match — this is the one place the ladder is intentionally NOT captain+.
  bool get canSendChallenge => isStaff;

  /// Pick the XI, run the toss, start the match.
  bool get canPickXi => hasMatchAuthority;

  /// Score this team's innings. The server also honours a per-match
  /// `match_officials` scorer appointment, which this cannot see — treat a
  /// `false` here as "not by rank", not as "definitely refused".
  bool get canScore => hasMatchAuthority;

  /// Appoint a scorer for a casual match.
  bool get canAppointScorer => hasMatchAuthority;

  /// Promote or demote a teammate. Managers may only move people between
  /// player and captain; the server enforces the full rule ("never grant a
  /// rung at or above your own") and is the authority.
  bool get canChangeRoles => isStaff;

  /// Create or remove other staff. Owner only — mirrors `set_team_member_role`
  /// rejecting a manager who tries to mint another manager.
  bool get canAppointStaff => this == owner;

  bool get canTransferOwnership => this == owner;
  bool get canDisband => this == owner;

  /// Leave voluntarily. The owner must transfer ownership first — `leave_team`
  /// raises 42501 for them.
  bool get canLeave => isMember && this != owner;

  /// Whether this rung may grant [target] to someone else. The single
  /// invariant, mirrored from `set_team_member_role`.
  bool canGrant(MemberRole target) => switch (this) {
        owner => target != MemberRole.owner,
        manager => target == MemberRole.player || target == MemberRole.captain,
        _ => false,
      };
}

extension TeamRelationshipX on Team {
  /// Classifies [userId]'s relationship to this team from their roster row.
  ///
  /// [rosterRole] is the user's highest membership role when known; pass null
  /// when the roster isn't loaded or the user isn't a member. There is no
  /// team-row fallback any more: `created_by` is history, not authority, so a
  /// creator who left must not read as the owner.
  TeamRelationship relationshipFor({
    required String? userId,
    MemberRole? rosterRole,
  }) {
    if (userId == null) return TeamRelationship.none;
    return switch (rosterRole) {
      MemberRole.owner => TeamRelationship.owner,
      MemberRole.manager => TeamRelationship.manager,
      MemberRole.captain => TeamRelationship.captain,
      MemberRole.player => TeamRelationship.player,
      // No roster row loaded means no claim. Guessing from `created_by` would
      // call a departed creator the owner.
      null => TeamRelationship.none,
    };
  }
}
