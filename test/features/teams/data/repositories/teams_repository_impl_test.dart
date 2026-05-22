import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/database/tables.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/core/sync/pending_operations_datasource.dart';
import 'package:novex_clean_arch/core/sync/sync_service.dart';
import 'package:novex_clean_arch/features/teams/data/datasources/teams_local_datasource.dart';
import 'package:novex_clean_arch/features/teams/data/repositories/teams_repository_impl.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team_member.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/unclaimed_player.dart';
import 'package:novex_clean_arch/features/teams/domain/value_objects/jersey_number.dart';
import 'package:novex_clean_arch/features/teams/domain/value_objects/player_display_name.dart';
import 'package:novex_clean_arch/features/teams/domain/value_objects/team_name.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class _MockLocal extends Mock implements TeamsLocalDataSource {}

class _MockPending extends Mock implements PendingOperationsDataSource {}

class _MockSync extends Mock implements SyncService {}

class _MockSupabase extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

TeamMember _member(String id, {MemberRole role = MemberRole.player, int? jersey}) =>
    TeamMember(
      id: MembershipId(id),
      teamId: const TeamId('t1'),
      playerId: 'p_$id',
      playerType: PlayerType.unclaimed,
      role: role,
      addedBy: 'u1',
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      jerseyNumber: jersey,
    );

void main() {
  late _MockLocal local;
  late _MockPending pending;
  late _MockSync sync;
  late _MockSupabase supabase;
  late _MockAuth auth;
  late _MockUser user;
  late TeamsRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(OpType.create);
    registerFallbackValue(_member('fallback'));
    registerFallbackValue(
      Team(
        id: const TeamId('fallback'),
        ownerId: 'u1',
        name: 'Fallback',
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        managers: const ['u1'],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      UnclaimedPlayer(
        id: const UnclaimedPlayerId('fallback'),
        displayName: 'Fallback',
        addedBy: 'u1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    local = _MockLocal();
    pending = _MockPending();
    sync = _MockSync();
    supabase = _MockSupabase();
    auth = _MockAuth();
    user = _MockUser();

    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.id).thenReturn('u1');
    when(() => sync.sync()).thenAnswer((_) async {});
    when(() => local.upsertTeam(any())).thenAnswer((_) async {});
    when(() => local.upsertUnclaimed(any())).thenAnswer((_) async {});
    when(() => local.upsertMember(any())).thenAnswer((_) async {});
    when(() => pending.enqueue(
          opType: any(named: 'opType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async => 1);

    repo = TeamsRepositoryImpl(
      local: local,
      pendingOps: pending,
      syncService: sync,
      supabase: supabase,
      uuid: const Uuid(),
    );
  });

  test('createTeam writes local, enqueues a create op, and nudges sync',
      () async {
    final result = await repo.createTeam(
      name: TeamName.create('Lahore Lions').getRight().toNullable()!,
      type: TeamType.club,
    );

    expect(result.isRight(), isTrue);
    verify(() => local.upsertTeam(any())).called(1);
    verify(() => pending.enqueue(
          opType: OpType.create,
          entityType: 'team',
          entityId: any(named: 'entityId'),
          payload: any(named: 'payload'),
        )).called(1);
    verify(() => sync.sync()).called(1);
  });

  test('addUnclaimedPlayer writes both rows and enqueues both ops in order',
      () async {
    final result = await repo.addUnclaimedPlayer(
      teamId: const TeamId('t1'),
      displayName: PlayerDisplayName.create('Ahmed Khan').getRight().toNullable()!,
    );

    expect(result.isRight(), isTrue);
    verify(() => local.upsertUnclaimed(any())).called(1);
    verify(() => local.upsertMember(any())).called(1);
    verify(() => pending.enqueue(
          opType: OpType.create,
          entityType: 'unclaimed_player',
          entityId: any(named: 'entityId'),
          payload: any(named: 'payload'),
        )).called(1);
    verify(() => pending.enqueue(
          opType: OpType.create,
          entityType: 'team_member',
          entityId: any(named: 'entityId'),
          payload: any(named: 'payload'),
        )).called(1);
  });

  test('setJerseyNumber rejects a number already taken by another member',
      () async {
    when(() => local.getMember('m1'))
        .thenAnswer((_) async => _member('m1'));
    when(() => local.getMembersForTeam('t1')).thenAnswer(
      (_) async => [_member('m1'), _member('m2', jersey: 7)],
    );

    final result = await repo.setJerseyNumber(
      const MembershipId('m1'),
      JerseyNumber.create(7).getRight().toNullable(),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => local.upsertMember(any()));
  });

  test('setMemberRole to captain demotes the existing captain', () async {
    when(() => local.getMember('m2'))
        .thenAnswer((_) async => _member('m2'));
    when(() => local.getMembersForTeam('t1')).thenAnswer(
      (_) async => [_member('m1', role: MemberRole.captain), _member('m2')],
    );

    final result = await repo.setMemberRole(
      const MembershipId('m2'),
      MemberRole.captain,
    );

    expect(result.isRight(), isTrue);
    // Old captain demoted + new captain set = two member upserts + two ops.
    verify(() => local.upsertMember(any())).called(2);
    verify(() => pending.enqueue(
          opType: OpType.update,
          entityType: 'team_member',
          entityId: any(named: 'entityId'),
          payload: any(named: 'payload'),
        )).called(2);
  });
}
