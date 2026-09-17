import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/place_facet.dart';
import '../entities/player_skills.dart';
import '../entities/roster_member.dart';
import '../entities/team.dart';
import '../entities/team_claim_request.dart';
import '../entities/team_invite.dart';
import '../entities/team_join_request.dart';
import '../entities/team_member.dart';
import '../entities/team_search_result.dart';
import '../entities/user_team_affiliation.dart';
import '../value_objects/jersey_number.dart';
import '../value_objects/player_display_name.dart';
import '../value_objects/team_name.dart';

/// Online-only teams contract. Reads stream from Supabase realtime; writes
/// go straight to the server.
abstract class TeamsRepository {
  // ─── Reads ─────────────────────────────────────────────────────────────
  Stream<List<Team>> watchMyTeams(String userId);

  /// The signed-in user's rung on every team they belong to, keyed by team id.
  ///
  /// The one place authority is answered on the client. Added 2026-09-10 to
  /// replace `Team.isManagedBy`, which read a `teams.managers` array that no
  /// longer exists — and which could not see a captain at all.
  Stream<Map<String, MemberRole>> watchMyTeamRoles(String userId);

  /// All teams the signed-in user can see (for picking an opponent).
  Stream<List<Team>> watchAllTeams();
  Stream<Team?> watchTeam(TeamId id);
  Future<Either<Failure, Team?>> getTeam(TeamId id);
  Stream<List<RosterMember>> watchRoster(TeamId teamId);
  Stream<List<UserTeamAffiliation>> watchUserAffiliatedTeams(String userId);

  /// Pending team invites sent to players.
  Future<Either<Failure, List<TeamInvite>>> getTeamPendingInvites(String teamId);

  /// Pending team invite for the current user for a specific team.
  Future<Either<Failure, TeamInvite?>> getMyPendingInviteForTeam(String teamId);

  /// Accepts a team invite, atomically adding the user to the roster.
  Future<Either<Failure, Unit>> acceptTeamInvite(String inviteId);

  /// Declines a team invite.
  Future<Either<Failure, Unit>> declineTeamInvite(String inviteId);

  /// Pending claim requests for offline player spots.
  Future<Either<Failure, List<TeamClaimRequest>>> getTeamPendingClaimRequests(String teamId);

  /// Pending player join requests.
  Future<Either<Failure, List<TeamJoinRequest>>> getTeamPendingJoinRequests(String teamId);

  // ─── Writes ────────────────────────────────────────────────────────────
  Future<Either<Failure, Team>> createTeam({
    required TeamName name,
    required TeamType type,
    TeamPrivacy privacy,
    String? description,
    String? homeGround,
    String? city,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
    CrestKind crestKind = CrestKind.monogram,
    // Structured geo, all optional. Mirrors the location jsonb contract in
    // docs/search-feature-design.md §7. The "where you play" wizard step that
    // populates these is a follow-up ticket; today's wizard leaves them null
    // and a team's coord comes from the 0611 backfill (owner's profile).
    String? label,
    String? district,
    String? province,
    String? postcode,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
  });

  /// Updates an existing team's details.
  Future<Either<Failure, Team>> updateTeam({
    required TeamId teamId,
    TeamName? name,
    TeamType? type,
    TeamPrivacy? privacy,
    String? description,
    String? homeGround,
    String? city,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
    String? district,
    String? province,
    String? postcode,
    String? countryCode,
  });

  /// Archives or restores a team by moving `teams.status`.
  ///
  /// Archiving is reversible and deliberately not a delete: the page stays
  /// visible as a record, but posting, joining and following stop. Only a
  /// manager can call it (RLS `teams_update_managers`).
  Future<Either<Failure, Team>> setTeamStatus({
    required TeamId teamId,
    required TeamStatus status,
  });

  /// The signed-in player leaves the squad.
  ///
  /// Goes through the `leave_team()` RPC rather than a direct delete — the
  /// team_members RLS policy denies self-writes so a player cannot promote
  /// themselves, and the RPC constrains the change to
  /// `status='inactive' + left_at=now()`.
  Future<Either<Failure, Unit>> leaveTeam(MembershipId membershipId);

  /// Uploads [bytes] (encoded as [extension], e.g. 'jpg'/'png'/'webp') to the
  /// `team-logos` bucket under `<teamId>/...`, patches the team row's
  /// `logo_url`, and returns the public URL. Existing logo for the team is
  /// overwritten.
  Future<Either<Failure, String>> uploadTeamLogo({
    required TeamId teamId,
    required List<int> bytes,
    required String extension,
  });

  /// Adds a player by name: creates an unclaimed_players row + a team_members
  /// row pointing at it (player_type = unclaimed). Jersey number is set on
  /// the membership row; playing-skill enums are stashed in the unclaimed
  /// player's `player_profile` jsonb for display in the squad list.
  Future<Either<Failure, Unit>> addUnclaimedPlayer({
    required TeamId teamId,
    required PlayerDisplayName displayName,
    String? phoneNumber,
    JerseyNumber? jerseyNumber,
    PlayingRole? playingRole,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
  });

  /// Adds an existing registered Matchday user to the team roster.
  Future<Either<Failure, Unit>> addRegisteredPlayer({
    required TeamId teamId,
    required String userId,
    JerseyNumber? jerseyNumber,
    MemberRole role = MemberRole.player,
  });

  /// Searches registered users by name / username for roster inclusion.
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsers(String query);

  Future<Either<Failure, Unit>> removeMember(MembershipId id);

  /// Sets or clears (null) a jersey number. Fails if the number is already
  /// taken by another active member of the same team.
  Future<Either<Failure, Unit>> setJerseyNumber(
    MembershipId id,
    JerseyNumber? jersey,
  );

  /// Sets a member's role. Promoting to captain demotes the incumbent in the
  /// same transaction (one captain per team, enforced by a unique index).
  ///
  /// Returns an [AuthFailure] when the caller's own rung is too low — the
  /// server rule is "you may never act on, or grant, a rung at or above your
  /// own", so a manager cannot mint another manager or touch the owner.
  Future<Either<Failure, Unit>> setMemberRole(MembershipId id, MemberRole role);

  /// Hands the team to another active member. Owner only.
  ///
  /// The outgoing owner becomes a manager. This is the only way ownership
  /// moves: [setMemberRole] rejects `MemberRole.owner`, and both `leave_team`
  /// and self-demotion refuse while the caller still owns the team.
  Future<Either<Failure, Unit>> transferOwnership(
    TeamId teamId,
    String newOwnerId,
  );

  /// Sends an invitation to a registered Matchday player.
  Future<Either<Failure, Unit>> sendTeamInvite({
    required String teamId,
    required String inviteeId,
    String? message,
    MemberRole role = MemberRole.player,
    int? jerseyNumber,
  });

  /// Cancels an in-flight team invite.
  Future<Either<Failure, Unit>> cancelTeamInvite(String inviteId);

  /// Accepts a roster claim request, binding the player's account.
  Future<Either<Failure, Unit>> acceptClaimRequest(String requestId);

  /// Declines a roster claim request.
  Future<Either<Failure, Unit>> declineClaimRequest(String requestId);

  /// Requests to join a team squad.
  Future<Either<Failure, Unit>> requestToJoinTeam({
    required String teamId,
    MemberRole role = MemberRole.player,
    String? message,
  });

  /// Accepts a player's join request, adding them to the roster.
  Future<Either<Failure, Unit>> acceptJoinRequest(String requestId);

  /// Declines a player's join request.
  Future<Either<Failure, Unit>> declineJoinRequest(String requestId);

  // ─── Search & discovery ────────────────────────────────────────────────

  /// Discovery search. Behaviour switches on which inputs are non-null
  /// (docs/search-feature-design.md §9.1):
  ///   • [query] only           → name search (trigram, word_similarity)
  ///   • [lat]+[lng] only       → near-me browse (hard radius)
  ///   • [query]+center         → blended (relevance × distance decay)
  ///   • none                   → browse (verified + recent)
  /// [countryCode] defaults server-side to the caller's profile country;
  /// pass it explicitly to override.
  Future<Either<Failure, List<TeamSearchResult>>> searchTeams({
    String? query,
    double? lat,
    double? lng,
    double? radiusKm,
    double? scaleKm,
    String? countryCode,
    int? limit,
  });

  /// City chips for the search filter row. Cap is top-100; chips are sorted
  /// by team count desc. Country defaults server-side to the caller's
  /// profile country.
  Future<Either<Failure, List<PlaceFacet>>> teamPlaceFacets({
    String? countryCode,
  });
}
