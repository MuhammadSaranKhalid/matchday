import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/features/teams/data/datasources/teams_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabase extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

void main() {
  Future<void> createPlayer({
    required String code,
    required String message,
  }) async {
    final transport = SupabaseClient(
      'https://example.test',
      'test-key',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/add_unclaimed_team_member');
        expect(jsonDecode(request.body)['p_team_id'], 'team-1');
          return http.Response(
            jsonEncode({'code': code, 'message': message}),
            403,
            request: request,
            headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(transport.dispose);
    final client = _MockSupabase();
    final auth = _MockAuth();
    final user = _MockUser();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.id).thenReturn('user-1');
    when(
      () => client.rpc<String>(
        'add_unclaimed_team_member',
        params: any(named: 'params'),
      ),
    ).thenAnswer(
      (call) => transport.rpc<String>(
        'add_unclaimed_team_member',
        params: call.namedArguments[#params] as Map<String, dynamic>,
      ),
    );

    await TeamsRemoteDataSource(
      client,
    ).addUnclaimedTeamMember(teamId: 'team-1', displayName: 'Ali');
  }

  test('preserves an explicit staff authorization rejection', () async {
    await expectLater(
      createPlayer(code: '42501', message: 'Only team staff can add players'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test(
    'does not label a database privilege failure as a team-role failure',
    () async {
      const message = 'permission denied for table unclaimed_players';
      await expectLater(
        createPlayer(code: '42501', message: message),
        throwsA(
          isA<ServerException>().having((e) => e.message, 'message', message),
        ),
      );
    },
  );
}
