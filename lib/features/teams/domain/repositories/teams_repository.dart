import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/place_facet.dart';
import '../entities/player_skills.dart';
import '../entities/roster_member.dart';
import '../entities/team.dart';
import '../entities/team_member.dart';
import '../entities/team_search_result.dart';
import '../value_objects/jersey_number.dart';
import '../value_objects/player_display_name.dart';
import '../value_objects/team_name.dart';

/// Online-only teams contract. Reads stream from Supabase realtime; writes
/// go straight to the server.
abstract class TeamsRepository {
  // ─── Reads ─────────────────────────────────────────────────────────────
  Stream<List<Team>> watchMyTeams(String userId);

  /// All teams the signed-in user can see (for picking an opponent).
  Stream<List<Team>> watchAllTeams();
  Stream<Team?> watchTeam(TeamId id);
  Future<Either<Failure, Team?>> getTeam(TeamId id);
  Stream<List<RosterMember>> watchRoster(TeamId teamId);

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
    JerseyNumber? jerseyNumber,
    PlayingRole? playingRole,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
  });

  Future<Either<Failure, Unit>> removeMember(MembershipId id);

  /// Sets or clears (null) a jersey number. Fails if the number is already
  /// taken by another active member of the same team.
  Future<Either<Failure, Unit>> setJerseyNumber(
    MembershipId id,
    JerseyNumber? jersey,
  );

  /// Sets a member's role. Promoting to captain demotes the current captain
  /// (one captain per team).
  Future<Either<Failure, Unit>> setMemberRole(MembershipId id, MemberRole role);

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
