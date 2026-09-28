import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/explore/data/datasources/explore_remote_datasource.dart';
import 'package:matchday/features/explore/data/models/match_result_dto.dart';
import 'package:matchday/features/explore/data/models/player_result_dto.dart';
import 'package:matchday/features/explore/data/models/team_result_dto.dart';
import 'package:matchday/features/explore/data/models/tournament_result_dto.dart';
import 'package:matchday/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:matchday/features/explore/domain/entities/player_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ExploreRemoteDataSource {}

typedef _SearchResult = ({
  List<PlayerResultDto> players,
  List<TeamResultDto> teams,
  List<MatchResultDto> matches,
  List<TournamentResultDto> tournaments,
});

_SearchResult _empty() => (
      players: <PlayerResultDto>[],
      teams: <TeamResultDto>[],
      matches: <MatchResultDto>[],
      tournaments: <TournamentResultDto>[],
    );

void main() {
  late _MockRemote remote;
  late ExploreRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = ExploreRepositoryImpl(remote);
  });

  group('query threshold (business rule lives in the repository)', () {
    test('a sub-2-char query returns empty without touching the remote',
        () async {
      final result = await repo.search('a');

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!.isEmpty, isTrue);
      verifyNever(() => remote.search(any(),
          kind: any(named: 'kind'), limit: any(named: 'limit')));
    });

    test('whitespace is trimmed before the length check', () async {
      final result = await repo.search('  a  ');

      expect(result.isRight(), isTrue);
      verifyNever(() => remote.search(any(),
          kind: any(named: 'kind'), limit: any(named: 'limit')));
    });

    test('a valid query is forwarded trimmed', () async {
      when(() => remote.search(any(),
              kind: any(named: 'kind'), limit: any(named: 'limit')))
          .thenAnswer((_) async => _empty());

      await repo.search('  lah  ');

      verify(() => remote.search('lah',
          kind: any(named: 'kind'), limit: any(named: 'limit'))).called(1);
    });
  });

  group('exception → Failure translation', () {
    test('UnauthorizedException becomes AuthFailure', () async {
      when(() => remote.search(any(),
              kind: any(named: 'kind'), limit: any(named: 'limit')))
          .thenThrow(UnauthorizedException('no session'));

      final result = await repo.search('lah');

      expect(result.getLeft().toNullable(), isA<AuthFailure>());
    });

    test('ServerException becomes ServerFailure carrying the message',
        () async {
      when(() => remote.search(any(),
              kind: any(named: 'kind'), limit: any(named: 'limit')))
          .thenThrow(ServerException('query_failed'));

      final result = await repo.search('lah');
      final failure = result.getLeft().toNullable();

      expect(failure, isA<ServerFailure>());
      expect(failure!.message, 'query_failed');
    });

    test('SocketException becomes NetworkFailure', () async {
      when(() => remote.search(any(),
              kind: any(named: 'kind'), limit: any(named: 'limit')))
          .thenThrow(const SocketException('offline'));

      final result = await repo.search('lah');

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('an unexpected error becomes UnknownFailure, never escapes',
        () async {
      when(() => remote.search(any(),
              kind: any(named: 'kind'), limit: any(named: 'limit')))
          .thenThrow(StateError('boom'));

      final result = await repo.search('lah');

      expect(result.getLeft().toNullable(), isA<UnknownFailure>());
    });

    test('browse translates failures the same way', () async {
      when(() => remote.browse()).thenThrow(ServerException('down'));

      final result = await repo.browse();

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('DTO → entity mapping', () {
    test('an unknown player_type degrades to unclaimed rather than throwing',
        () async {
      when(() => remote.search(any(),
              kind: any(named: 'kind'), limit: any(named: 'limit')))
          .thenAnswer((_) async => (
                players: [
                  const PlayerResultDto(
                    playerType: 'something_new',
                    id: 'x1',
                    name: 'Future Kind',
                  ),
                ],
                teams: <TeamResultDto>[],
                matches: <MatchResultDto>[],
                tournaments: <TournamentResultDto>[],
              ));

      final result = await repo.search('lah');
      final player = result.getRight().toNullable()!.players.single;

      expect(player.kind, PlayerKind.unclaimed);
      expect(player.isUnclaimed, isTrue);
    });

    test('a registered player exposes its handle in the meta line', () async {
      when(() => remote.search(any(),
              kind: any(named: 'kind'), limit: any(named: 'limit')))
          .thenAnswer((_) async => (
                players: [
                  const PlayerResultDto(
                    playerType: 'profile',
                    id: 'u1',
                    name: 'Ahmed Khan',
                    username: 'ahmedk',
                    playerRole: 'all_rounder',
                  ),
                ],
                teams: <TeamResultDto>[],
                matches: <MatchResultDto>[],
                tournaments: <TournamentResultDto>[],
              ));

      final result = await repo.search('ahm');
      final player = result.getRight().toNullable()!.players.single;

      expect(player.kind, PlayerKind.profile);
      // snake_case enum values are rendered as words.
      expect(player.metaLine, '@ahmedk · all rounder');
    });
  });
}
