import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../../domain/value_objects/team_name.dart';
import '../datasources/teams_remote_datasource.dart';

/// Online-only teams repository. Reads stream directly from Supabase realtime;
/// writes go straight to the server. The only place remote exceptions become
/// [Failure]s.
class TeamsRepositoryImpl implements TeamsRepository {
  TeamsRepositoryImpl({
    required TeamsRemoteDataSource remote,
    required SupabaseClient supabase,
    Uuid? uuid,
  })  : _remote = remote,
        _supabase = supabase,
        _uuid = uuid ?? const Uuid();

  final TeamsRemoteDataSource _remote;
  final SupabaseClient _supabase;
  final Uuid _uuid;

  String _requireUserId() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in user');
    return id;
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Stream<List<Team>> watchMyTeams(String userId) =>
      _remote.watchTeams().map((dtos) {
        final mine = dtos
            .map((d) => d.toEntity())
            .where((t) => t.ownerId == userId || t.managers.contains(userId))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return mine;
      });

  @override
  Stream<List<Team>> watchAllTeams() => _remote.watchTeams().map((dtos) {
        final all = dtos.map((d) => d.toEntity()).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return all;
      });

  @override
  Stream<Team?> watchTeam(TeamId id) => _remote.watchTeams().map((dtos) {
        for (final d in dtos) {
          if (d.teamId == id.value) return d.toEntity();
        }
        return null;
      });

  @override
  Future<Either<Failure, Team?>> getTeam(TeamId id) async {
    try {
      final dtos = await _remote.listTeams();
      for (final d in dtos) {
        if (d.teamId == id.value) return Right(d.toEntity());
      }
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<RosterMember>> watchRoster(TeamId teamId) {
    // Stream the members table; re-fetch the unclaimed-players table on each
    // tick to resolve display names. Acceptable trade-off for online-only:
    // renames to an unclaimed player won't reflect until the member stream
    // pings again (typically next edit or pull-to-refresh).
    return _remote.watchMembers().asyncMap((memberDtos) async {
      final teamMembers =
          memberDtos.where((m) => m.teamId == teamId.value).toList();
      final unclaimed = await _remote.listUnclaimed();
      final byId = {for (final u in unclaimed) u.unclaimedId: u};
      final roster = teamMembers
          .map((m) => RosterMember(
                member: m.toEntity(),
                displayName: byId[m.playerId]?.displayName ?? 'Unknown player',
              ))
          .toList()
        ..sort((a, b) => a.member.joinedAt.compareTo(b.member.joinedAt));
      return roster;
    });
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Team>> createTeam({
    required TeamName name,
    required TeamType type,
    TeamPrivacy privacy = TeamPrivacy.public,
    String? description,
    String? homeGround,
    String? city,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
  }) async {
    try {
      _requireUserId();
      final dto = await _remote.createTeam({
        'id': _uuid.v4(),
        'team_name': name.value,
        'team_type': type.wire,
        'privacy': privacy.wire,
        'description': description,
        'home_ground': homeGround,
        'city': city,
        'founded_year': foundedYear,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
      });
      return Right(dto.toEntity());
    } on StateError catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addUnclaimedPlayer({
    required TeamId teamId,
    required PlayerDisplayName displayName,
  }) async {
    try {
      _requireUserId();
      final unclaimedId = _uuid.v4();
      await _remote.createUnclaimed({
        'id': unclaimedId,
        'display_name': displayName.value,
      });
      await _remote.createMember({
        'id': _uuid.v4(),
        'team_id': teamId.value,
        'player_id': unclaimedId,
        'player_type': PlayerType.unclaimed.wire,
        'role': MemberRole.player.wire,
        'jersey_number': null,
      });
      return const Right(unit);
    } on StateError catch (e) {
      return Left(AuthFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMember(MembershipId id) async {
    try {
      await _remote.deleteMember(id.value);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setJerseyNumber(
    MembershipId id,
    JerseyNumber? jersey,
  ) async {
    try {
      // Server's partial-unique index is the authoritative check; the remote
      // translates code 23505 to "That jersey number is already taken".
      await _remote.updateMember(id.value, {
        'jersey_number': jersey?.value,
      });
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setMemberRole(
    MembershipId id,
    MemberRole role,
  ) async {
    try {
      // One captain per team: when promoting, demote the current captain
      // first. Two sequential remote calls — not atomic, but acceptable for
      // online-only (a Postgres function would be the next step if this needs
      // to be transactional).
      if (role == MemberRole.captain) {
        final target = await _findMember(id);
        if (target == null) {
          return const Left(NotFoundFailure('Member not found'));
        }
        final roster = (await _remote.listMembers())
            .where((m) => m.teamId == target.teamId.value)
            .map((m) => m.toEntity())
            .toList();
        for (final m in roster) {
          if (m.id != id && m.role == MemberRole.captain) {
            await _remote.updateMember(m.id.value, {
              'role': MemberRole.player.wire,
            });
          }
        }
      }
      await _remote.updateMember(id.value, {'role': role.wire});
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<TeamMember?> _findMember(MembershipId id) async {
    final members = await _remote.listMembers();
    for (final m in members) {
      if (m.membershipId == id.value) return m.toEntity();
    }
    return null;
  }
}
