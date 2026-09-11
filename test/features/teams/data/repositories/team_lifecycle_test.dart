import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/teams/data/datasources/teams_remote_datasource.dart';
import 'package:matchday/features/teams/data/models/team_dto.dart';
import 'package:matchday/features/teams/data/repositories/teams_repository_impl.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TeamsRemoteDataSource {}

TeamDto _dto({String status = 'active'}) => TeamDto(
      teamId: 't1',
      createdBy: 'u1',
      teamName: 'Lahore Lions',
      teamType: 'club',
      status: status,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-09-06T00:00:00Z',
    );

void main() {
  late _MockRemote remote;
  late TeamsRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    remote = _MockRemote();
    repo = TeamsRepositoryImpl(remote: remote);
  });

  group('archive / restore', () {
    test('archiving sends only the status column', () async {
      when(() => remote.updateTeam(any(), any()))
          .thenAnswer((_) async => _dto(status: 'archived'));

      final result = await repo.setTeamStatus(
        teamId: const TeamId('t1'),
        status: TeamStatus.archived,
      );

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()?.isArchived, isTrue);
      // Archiving must not touch a team's identity — a stray field here
      // would silently rewrite the name or colour it was last edited with.
      verify(() => remote.updateTeam('t1', {'status': 'archived'})).called(1);
    });

    test('restoring moves the same column back to active', () async {
      when(() => remote.updateTeam(any(), any()))
          .thenAnswer((_) async => _dto());

      final result = await repo.setTeamStatus(
        teamId: const TeamId('t1'),
        status: TeamStatus.active,
      );

      expect(result.getRight().toNullable()?.status, TeamStatus.active);
      verify(() => remote.updateTeam('t1', {'status': 'active'})).called(1);
    });

    test('a non-manager gets an AuthFailure, not an exception', () async {
      when(() => remote.updateTeam(any(), any()))
          .thenThrow(UnauthorizedException('Must be signed in'));

      final result = await repo.setTeamStatus(
        teamId: const TeamId('t1'),
        status: TeamStatus.archived,
      );

      expect(result.getLeft().toNullable(), isA<AuthFailure>());
    });

    test('a server error becomes a ServerFailure', () async {
      when(() => remote.updateTeam(any(), any()))
          .thenThrow(ServerException('row level security'));

      final result = await repo.setTeamStatus(
        teamId: const TeamId('t1'),
        status: TeamStatus.archived,
      );

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('leaveTeam', () {
    test('goes through the RPC with the membership id', () async {
      when(() => remote.leaveTeam(any())).thenAnswer((_) async {});

      final result = await repo.leaveTeam(const MembershipId('m1'));

      expect(result.isRight(), isTrue);
      verify(() => remote.leaveTeam('m1')).called(1);
    });

    test('translates a refused leave rather than throwing', () async {
      // The RPC raises 42501 when the membership is not the caller's.
      when(() => remote.leaveTeam(any()))
          .thenThrow(ServerException('Cannot leave a membership that is not yours'));

      final result = await repo.leaveTeam(const MembershipId('m1'));

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('status round-trips through the DTO', () {
    test('an unknown wire value degrades to active', () {
      expect(_dto(status: 'something_new').toEntity().status, TeamStatus.active);
    });

    test('archived rows surface as archived entities', () {
      expect(_dto(status: 'archived').toEntity().isArchived, isTrue);
    });
  });
}
