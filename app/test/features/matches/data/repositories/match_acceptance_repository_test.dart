import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/matches/data/datasources/format_presets_remote_datasource.dart';
import 'package:matchday/features/matches/data/datasources/match_requests_remote_datasource.dart';
import 'package:matchday/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:matchday/features/matches/data/repositories/match_pool_repository_impl.dart';
import 'package:matchday/features/matches/data/repositories/matches_repository_impl.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_request.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchesRemoteDataSource extends Mock implements MatchesRemoteDataSource {}

class _MockMatchRequestsRemoteDataSource extends Mock
    implements MatchRequestsRemoteDataSource {}

class _MockFormatPresetsRemoteDataSource extends Mock
    implements FormatPresetsRemoteDataSource {}

void main() {
  late _MockMatchesRemoteDataSource mockRemote;
  late _MockMatchRequestsRemoteDataSource mockRequests;
  late _MockFormatPresetsRemoteDataSource mockPresets;
  late MatchesRepositoryImpl matchesRepo;
  late MatchPoolRepositoryImpl poolRepo;

  setUp(() {
    mockRemote = _MockMatchesRemoteDataSource();
    mockRequests = _MockMatchRequestsRemoteDataSource();
    mockPresets = _MockFormatPresetsRemoteDataSource();
    matchesRepo = MatchesRepositoryImpl(mockRemote, mockRequests, mockPresets);
    poolRepo = MatchPoolRepositoryImpl(requestsDataSource: mockRequests);
  });

  group('MatchesRepositoryImpl.acceptMatchChallenge error mapping', () {
    const reqId = MatchRequestId('00000000-0000-0000-0000-000000000001');

    test('returns Right(MatchId) on success', () async {
      when(
        () => mockRequests.acceptMatchChallenge(
          requestId: reqId.value,
          scheduledStartTime: any(named: 'scheduledStartTime'),
          venue: any(named: 'venue'),
          format: any(named: 'format'),
          decisionNote: any(named: 'decisionNote'),
          toTeamId: any(named: 'toTeamId'),
          toTeamXi: any(named: 'toTeamXi'),
          toTeamKeeperId: any(named: 'toTeamKeeperId'),
        ),
      ).thenAnswer((_) async => 'match-123');

      final result = await matchesRepo.acceptMatchChallenge(requestId: reqId);
      expect(result, const Right(MatchId('match-123')));
    });

    test('maps UnauthorizedException to AuthFailure', () async {
      when(
        () => mockRequests.acceptMatchChallenge(
          requestId: reqId.value,
          scheduledStartTime: any(named: 'scheduledStartTime'),
          venue: any(named: 'venue'),
          format: any(named: 'format'),
          decisionNote: any(named: 'decisionNote'),
          toTeamId: any(named: 'toTeamId'),
          toTeamXi: any(named: 'toTeamXi'),
          toTeamKeeperId: any(named: 'toTeamKeeperId'),
        ),
      ).thenThrow(UnauthorizedException('Forbidden'));

      final result = await matchesRepo.acceptMatchChallenge(requestId: reqId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.message, 'message', 'Forbidden'),
      );
    });

    test('maps ConflictException to ConflictFailure', () async {
      when(
        () => mockRequests.acceptMatchChallenge(
          requestId: reqId.value,
          scheduledStartTime: any(named: 'scheduledStartTime'),
          venue: any(named: 'venue'),
          format: any(named: 'format'),
          decisionNote: any(named: 'decisionNote'),
          toTeamId: any(named: 'toTeamId'),
          toTeamXi: any(named: 'toTeamXi'),
          toTeamKeeperId: any(named: 'toTeamKeeperId'),
        ),
      ).thenThrow(ConflictException('Already accepted'));

      final result = await matchesRepo.acceptMatchChallenge(requestId: reqId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ConflictFailure>().having(
          (f) => f.message,
          'message',
          'Already accepted',
        ),
      );
    });

    test('maps ValidationException to ValidationFailure', () async {
      when(
        () => mockRequests.acceptMatchChallenge(
          requestId: reqId.value,
          scheduledStartTime: any(named: 'scheduledStartTime'),
          venue: any(named: 'venue'),
          format: any(named: 'format'),
          decisionNote: any(named: 'decisionNote'),
          toTeamId: any(named: 'toTeamId'),
          toTeamXi: any(named: 'toTeamXi'),
          toTeamKeeperId: any(named: 'toTeamKeeperId'),
        ),
      ).thenThrow(ValidationException('Invalid XI'));

      final result = await matchesRepo.acceptMatchChallenge(requestId: reqId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Invalid XI',
        ),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      when(
        () => mockRequests.acceptMatchChallenge(
          requestId: reqId.value,
          scheduledStartTime: any(named: 'scheduledStartTime'),
          venue: any(named: 'venue'),
          format: any(named: 'format'),
          decisionNote: any(named: 'decisionNote'),
          toTeamId: any(named: 'toTeamId'),
          toTeamXi: any(named: 'toTeamXi'),
          toTeamKeeperId: any(named: 'toTeamKeeperId'),
        ),
      ).thenThrow(ServerException('DB error'));

      final result = await matchesRepo.acceptMatchChallenge(requestId: reqId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ServerFailure>().having((f) => f.message, 'message', 'DB error'),
      );
    });
  });

  group('MatchPoolRepositoryImpl.acceptPoolApplication error mapping', () {
    const appId = 'app-001';

    test('returns Right(MatchId) on success', () async {
      when(
        () => mockRequests.acceptPoolApplication(
          applicationId: appId,
          decisionNote: any(named: 'decisionNote'),
        ),
      ).thenAnswer((_) async => 'match-456');

      final result = await poolRepo.acceptPoolApplication(applicationId: appId);
      expect(result, const Right(MatchId('match-456')));
    });

    test('maps UnauthorizedException to AuthFailure', () async {
      when(
        () => mockRequests.acceptPoolApplication(
          applicationId: appId,
          decisionNote: any(named: 'decisionNote'),
        ),
      ).thenThrow(UnauthorizedException('Not manager'));

      final result = await poolRepo.acceptPoolApplication(applicationId: appId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.message, 'message', 'Not manager'),
      );
    });

    test('maps ConflictException to ConflictFailure', () async {
      when(
        () => mockRequests.acceptPoolApplication(
          applicationId: appId,
          decisionNote: any(named: 'decisionNote'),
        ),
      ).thenThrow(ConflictException('Already resolved'));

      final result = await poolRepo.acceptPoolApplication(applicationId: appId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ConflictFailure>().having(
          (f) => f.message,
          'message',
          'Already resolved',
        ),
      );
    });

    test('maps ValidationException to ValidationFailure', () async {
      when(
        () => mockRequests.acceptPoolApplication(
          applicationId: appId,
          decisionNote: any(named: 'decisionNote'),
        ),
      ).thenThrow(ValidationException('Invalid application id'));

      final result = await poolRepo.acceptPoolApplication(applicationId: appId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Invalid application id',
        ),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      when(
        () => mockRequests.acceptPoolApplication(
          applicationId: appId,
          decisionNote: any(named: 'decisionNote'),
        ),
      ).thenThrow(ServerException('Failed'));

      final result = await poolRepo.acceptPoolApplication(applicationId: appId);
      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ServerFailure>().having((f) => f.message, 'message', 'Failed'),
      );
    });
  });
}
