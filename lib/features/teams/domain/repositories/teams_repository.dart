import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/roster_member.dart';
import '../entities/team.dart';
import '../entities/team_member.dart';
import '../value_objects/jersey_number.dart';
import '../value_objects/player_display_name.dart';
import '../value_objects/team_name.dart';

/// Offline-first teams contract. Reads stream from the local DB; writes go
/// local-first then enqueue a pending op and nudge sync.
abstract class TeamsRepository {
  // ─── Reads (local) ─────────────────────────────────────────────────────
  Stream<List<Team>> watchMyTeams(String userId);

  /// All cached teams (for picking an opponent).
  Stream<List<Team>> watchAllTeams();
  Stream<Team?> watchTeam(TeamId id);
  Future<Either<Failure, Team?>> getTeam(TeamId id);
  Stream<List<RosterMember>> watchRoster(TeamId teamId);

  // ─── Writes (local-first) ──────────────────────────────────────────────
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
  });

  /// Adds a player by name: creates an unclaimed_players row + a team_members
  /// row pointing at it (player_type = unclaimed).
  Future<Either<Failure, Unit>> addUnclaimedPlayer({
    required TeamId teamId,
    required PlayerDisplayName displayName,
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
}
