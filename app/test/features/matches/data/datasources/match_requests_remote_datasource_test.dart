import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/features/matches/data/datasources/match_requests_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late _MockSupabaseClient mockSupabase;
  late _MockFunctionsClient mockFunctions;
  late MatchRequestsRemoteDataSource dataSource;

  setUp(() {
    mockSupabase = _MockSupabaseClient();
    mockFunctions = _MockFunctionsClient();
    when(() => mockSupabase.functions).thenReturn(mockFunctions);
    dataSource = MatchRequestsRemoteDataSource(mockSupabase);
  });

  group('acceptMatchChallenge', () {
    const requestId = '00000000-0000-0000-0000-000000000001';
    const matchId = '00000000-0000-0000-0000-000000000099';

    test('invokes match-request-action edge function with accept_challenge action', () async {
      when(
        () => mockFunctions.invoke(
          'match-request-action',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          status: 200,
          data: {'ok': true, 'match_id': matchId},
        ),
      );

      final result = await dataSource.acceptMatchChallenge(
        requestId: requestId,
        toTeamXi: ['00000000-0000-0000-0000-000000000002'],
      );

      expect(result, matchId);
      final captured = verify(
        () => mockFunctions.invoke(
          'match-request-action',
          body: captureAny(named: 'body'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(captured['action'], 'accept_challenge');
      final body = captured['body'] as Map<String, dynamic>;
      expect(body['request_id'], requestId);
      expect(body['to_team_xi'], ['00000000-0000-0000-0000-000000000002']);
    });

    test('throws ServerException when response data is missing match_id', () async {
      when(
        () => mockFunctions.invoke(
          'match-request-action',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          status: 200,
          data: {'ok': true},
        ),
      );

      expect(
        () => dataSource.acceptMatchChallenge(
          requestId: requestId,
          toTeamXi: [],
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('maps 401/403 FunctionException to UnauthorizedException', () async {
      when(
        () => mockFunctions.invoke(
          'match-request-action',
          body: any(named: 'body'),
        ),
      ).thenThrow(
        const FunctionException(
          status: 403,
          details: {'error': {'message': 'Not team manager'}},
        ),
      );

      expect(
        () => dataSource.acceptMatchChallenge(
          requestId: requestId,
          toTeamXi: [],
        ),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            'Not team manager',
          ),
        ),
      );
    });

    test('maps 409 FunctionException to ConflictException', () async {
      when(
        () => mockFunctions.invoke(
          'match-request-action',
          body: any(named: 'body'),
        ),
      ).thenThrow(
        const FunctionException(
          status: 409,
          details: {'error': {'message': 'Challenge already accepted'}},
        ),
      );

      expect(
        () => dataSource.acceptMatchChallenge(
          requestId: requestId,
          toTeamXi: [],
        ),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'Challenge already accepted',
          ),
        ),
      );
    });

    test('maps 422 FunctionException to ValidationException', () async {
      when(
        () => mockFunctions.invoke(
          'match-request-action',
          body: any(named: 'body'),
        ),
      ).thenThrow(
        const FunctionException(
          status: 422,
          details: {'error': {'message': 'Wicket-keeper must be part of the picked XI'}},
        ),
      );

      expect(
        () => dataSource.acceptMatchChallenge(
          requestId: requestId,
          toTeamXi: [],
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Wicket-keeper must be part of the picked XI',
          ),
        ),
      );
    });
  });

  group('acceptPoolApplication', () {
    const applicationId = '00000000-0000-0000-0000-000000000010';
    const matchId = '00000000-0000-0000-0000-000000000088';

    test('invokes match-request-action edge function with accept_pool_application action', () async {
      when(
        () => mockFunctions.invoke(
          'match-request-action',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          status: 200,
          data: {'ok': true, 'match_id': matchId},
        ),
      );

      final result = await dataSource.acceptPoolApplication(
        applicationId: applicationId,
        decisionNote: 'Welcome!',
      );

      expect(result, matchId);
      final captured = verify(
        () => mockFunctions.invoke(
          'match-request-action',
          body: captureAny(named: 'body'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(captured['action'], 'accept_pool_application');
      final body = captured['body'] as Map<String, dynamic>;
      expect(body['application_id'], applicationId);
      expect(body['decision_note'], 'Welcome!');
    });

    test('maps 409 FunctionException to ConflictException on acceptPoolApplication', () async {
      when(
        () => mockFunctions.invoke(
          'match-request-action',
          body: any(named: 'body'),
        ),
      ).thenThrow(
        const FunctionException(
          status: 409,
          details: {'error': {'message': 'Application not pending'}},
        ),
      );

      expect(
        () => dataSource.acceptPoolApplication(applicationId: applicationId),
        throwsA(isA<ConflictException>()),
      );
    });
  });
}
