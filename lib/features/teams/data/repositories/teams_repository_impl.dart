import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/op_type.dart';
import '../../../../core/sync/pending_operations_datasource.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/unclaimed_player.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../../domain/value_objects/team_name.dart';
import '../datasources/teams_local_datasource.dart';

/// Offline-first teams repository (coordinator). Reads stream from local;
/// writes go local-first → enqueue pending op → fire-and-forget sync.
class TeamsRepositoryImpl implements TeamsRepository {
  TeamsRepositoryImpl({
    required TeamsLocalDataSource local,
    required PendingOperationsDataSource pendingOps,
    required SyncService syncService,
    required SupabaseClient supabase,
    Uuid? uuid,
  })  : _local = local,
        _pending = pendingOps,
        _sync = syncService,
        _supabase = supabase,
        _uuid = uuid ?? const Uuid();

  final TeamsLocalDataSource _local;
  final PendingOperationsDataSource _pending;
  final SyncService _sync;
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
      _local.watchMyTeams(userId).handleError(
            (Object e) => throw FailureWrapper(CacheFailure(e.toString())),
          );

  @override
  Stream<List<Team>> watchAllTeams() => _local.watchAllTeams().handleError(
        (Object e) => throw FailureWrapper(CacheFailure(e.toString())),
      );

  @override
  Stream<Team?> watchTeam(TeamId id) => _local.watchTeam(id.value).handleError(
        (Object e) => throw FailureWrapper(CacheFailure(e.toString())),
      );

  @override
  Stream<List<RosterMember>> watchRoster(TeamId teamId) =>
      _local.watchRoster(teamId.value).handleError(
            (Object e) => throw FailureWrapper(CacheFailure(e.toString())),
          );

  @override
  Future<Either<Failure, Team?>> getTeam(TeamId id) async {
    try {
      return Right(await _local.getTeam(id.value));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
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
      final userId = _requireUserId();
      final now = DateTime.now();
      final team = Team(
        id: TeamId(_uuid.v4()),
        ownerId: userId,
        name: name.value,
        type: type,
        privacy: privacy,
        managers: [userId],
        description: description,
        homeGround: homeGround,
        city: city,
        foundedYear: foundedYear,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        createdAt: now,
        updatedAt: now,
      );

      await _local.upsertTeam(team);
      await _pending.enqueue(
        opType: OpType.create,
        entityType: 'team',
        entityId: team.id.value,
        payload: {
          'id': team.id.value,
          'team_name': team.name,
          'team_type': team.type.wire,
          'privacy': team.privacy.wire,
          'description': team.description,
          'home_ground': team.homeGround,
          'city': team.city,
          'founded_year': team.foundedYear,
          'primary_color': team.primaryColor,
          'secondary_color': team.secondaryColor,
        },
      );
      unawaited(_sync.sync());
      return Right(team);
    } on StateError catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addUnclaimedPlayer({
    required TeamId teamId,
    required PlayerDisplayName displayName,
  }) async {
    try {
      final userId = _requireUserId();
      final now = DateTime.now();
      final unclaimed = UnclaimedPlayer(
        id: UnclaimedPlayerId(_uuid.v4()),
        displayName: displayName.value,
        addedBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final member = TeamMember(
        id: MembershipId(_uuid.v4()),
        teamId: teamId,
        playerId: unclaimed.id.value,
        playerType: PlayerType.unclaimed,
        role: MemberRole.player,
        addedBy: userId,
        joinedAt: now,
        updatedAt: now,
      );

      await _local.upsertUnclaimed(unclaimed);
      await _local.upsertMember(member);

      // FIFO: the unclaimed player must be pushed before the member row.
      await _pending.enqueue(
        opType: OpType.create,
        entityType: 'unclaimed_player',
        entityId: unclaimed.id.value,
        payload: {
          'id': unclaimed.id.value,
          'display_name': unclaimed.displayName,
        },
      );
      await _pending.enqueue(
        opType: OpType.create,
        entityType: 'team_member',
        entityId: member.id.value,
        payload: {
          'id': member.id.value,
          'team_id': teamId.value,
          'player_id': unclaimed.id.value,
          'player_type': member.playerType.wire,
          'role': member.role.wire,
          'jersey_number': null,
        },
      );
      unawaited(_sync.sync());
      return const Right(unit);
    } on StateError catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMember(MembershipId id) async {
    try {
      await _local.deleteMember(id.value);
      await _pending.enqueue(
        opType: OpType.delete,
        entityType: 'team_member',
        entityId: id.value,
      );
      unawaited(_sync.sync());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setJerseyNumber(
    MembershipId id,
    JerseyNumber? jersey,
  ) async {
    try {
      final member = await _local.getMember(id.value);
      if (member == null) {
        return const Left(NotFoundFailure('Member not found'));
      }
      // Local uniqueness pre-check (the DB partial index is the backstop).
      if (jersey != null) {
        final roster = await _local.getMembersForTeam(member.teamId.value);
        final clash = roster.any(
          (m) => m.id != id && m.jerseyNumber == jersey.value,
        );
        if (clash) {
          return Left(ValidationFailure('#${jersey.value} is already taken'));
        }
      }

      final updated = member.copyWith(
        jerseyNumber: jersey?.value,
        clearJersey: jersey == null,
        updatedAt: DateTime.now(),
      );
      await _local.upsertMember(updated);
      await _pending.enqueue(
        opType: OpType.update,
        entityType: 'team_member',
        entityId: id.value,
        payload: {'jersey_number': jersey?.value},
      );
      unawaited(_sync.sync());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setMemberRole(
    MembershipId id,
    MemberRole role,
  ) async {
    try {
      final member = await _local.getMember(id.value);
      if (member == null) {
        return const Left(NotFoundFailure('Member not found'));
      }

      // One captain per team: demote the current captain first.
      if (role == MemberRole.captain) {
        final roster = await _local.getMembersForTeam(member.teamId.value);
        for (final m in roster) {
          if (m.id != id && m.role == MemberRole.captain) {
            await _applyRole(m, MemberRole.player);
          }
        }
      }

      await _applyRole(member, role);
      unawaited(_sync.sync());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<void> _applyRole(TeamMember member, MemberRole role) async {
    await _local.upsertMember(member.copyWith(role: role, updatedAt: DateTime.now()));
    await _pending.enqueue(
      opType: OpType.update,
      entityType: 'team_member',
      entityId: member.id.value,
      payload: {'role': role.wire},
    );
  }
}
