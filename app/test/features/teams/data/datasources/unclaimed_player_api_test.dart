import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/features/teams/data/datasources/team_membership_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabase extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

void main() {
  test(
    'roster reads public unclaimed-player fields without requesting contact PII',
    () async {
      final requestedSelects = <String>[];
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient((request) async {
          final select = request.url.queryParameters['select'];
          if (select != null) requestedSelects.add(select);

          return switch (request.url.path) {
            '/rest/v1/team_members' => http.Response(
                jsonEncode([
                  {
                    'membership_id': 'membership-1',
                    'team_id': 'team-1',
                    'user_id': null,
                    'unclaimed_id': 'unclaimed-1',
                    'jersey_number': 7,
                    'added_by': 'manager-1',
                    'joined_at': '2026-09-21T00:00:00.000Z',
                    'updated_at': '2026-09-21T00:00:00.000Z',
                  },
                ]),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              ),
            '/rest/v1/team_member_roles' => http.Response(
                jsonEncode([
                  {
                    'membership_id': 'membership-1',
                    'role_key': 'player',
                  },
                ]),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              ),
            '/rest/v1/unclaimed_players' => select?.contains('phone_number') ==
                    true
                ? http.Response(
                    jsonEncode({
                      'code': '42501',
                      'message':
                          'permission denied for table unclaimed_players',
                    }),
                    403,
                    request: request,
                    headers: {'content-type': 'application/json'},
                  )
                : http.Response(
                    jsonEncode([
                      {
                        'unclaimed_id': 'unclaimed-1',
                        'display_name': 'Ali',
                      },
                    ]),
                    200,
                    request: request,
                    headers: {'content-type': 'application/json'},
                  ),
            _ => http.Response('Not found', 404, request: request),
          };
        }),
      );
      addTearDown(client.dispose);

      final roster =
          await TeamMembershipRemoteDataSource(client).getRoster('team-1');

      expect(roster, hasLength(1));
      expect(roster.single.unclaimed?['display_name'], 'Ali');
      expect(
        requestedSelects.where((select) => select.contains('unclaimed_id')),
        everyElement(isNot(contains('phone_number'))),
      );
    },
  );

  /// Creates a [TeamMembershipRemoteDataSource] backed by an [http.MockClient]
  /// that intercepts the [add_unclaimed_cricket_team_member] RPC call and
  /// returns a synthetic Postgres error response with the given [code] and
  /// [message]. Used to verify how the datasource classifies Postgres error
  /// codes into typed exceptions.
  Future<void> createPlayer({
    required String code,
    required String message,
  }) async {
    final transport = SupabaseClient(
      'https://example.test',
      'test-key',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/rest/v1/rpc/add_unclaimed_cricket_team_member',
        );
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
      () => client.rpc<dynamic>(
        'add_unclaimed_cricket_team_member',
        params: any(named: 'params'),
      ),
    ).thenAnswer(
      (call) => transport.rpc<dynamic>(
        'add_unclaimed_cricket_team_member',
        params: call.namedArguments[#params] as Map<String, dynamic>,
      ),
    );

    await TeamMembershipRemoteDataSource(client).addUnclaimedCricketPlayer(
      teamId: 'team-1',
      displayName: 'Ali',
    );
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
