import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/teams/data/datasources/teams_remote_datasource.dart';
import 'package:matchday/features/teams/data/repositories/teams_repository_impl.dart';
import 'package:matchday/features/teams/domain/entities/player_skills.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/value_objects/jersey_number.dart';
import 'package:matchday/features/teams/domain/value_objects/player_display_name.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TeamsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late TeamsRepositoryImpl repository;
  final name = PlayerDisplayName.create('Ali').getRight().toNullable()!;

  setUp(() {
    remote = _MockRemote();
    repository = TeamsRepositoryImpl(remote: remote);
  });

  test(
    'creates player and membership through the atomic API with all details',
    () async {
      final profile = {'playing_role': PlayingRole.values.first.wire};
      when(
        () => remote.addUnclaimedTeamMember(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: '+923001234567',
          jerseyNumber: 7,
          playerProfile: profile,
        ),
      ).thenAnswer((_) async {});

      final result = await repository.addUnclaimedPlayer(
        teamId: const TeamId('t1'),
        displayName: name,
        phoneNumber: ' +923001234567 ',
        jerseyNumber: JerseyNumber.create(7).getRight().toNullable(),
        playingRole: PlayingRole.values.first,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => remote.addUnclaimedTeamMember(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: '+923001234567',
          jerseyNumber: 7,
          playerProfile: profile,
        ),
      ).called(1);
      verifyNoMoreInteractions(remote);
    },
  );

  test('a name alone works without optional details', () async {
    when(
      () => remote.addUnclaimedTeamMember(
        teamId: 't1',
        displayName: 'Ali',
        phoneNumber: null,
        jerseyNumber: null,
        playerProfile: {},
      ),
    ).thenAnswer((_) async {});

    final result = await repository.addUnclaimedPlayer(
      teamId: const TeamId('t1'),
      displayName: name,
    );
    expect(result.isRight(), isTrue);
  });

  test(
    'a refused creation returns a failure without attempting direct inserts',
    () async {
      when(
        () => remote.addUnclaimedTeamMember(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: null,
          jerseyNumber: null,
          playerProfile: {},
        ),
      ).thenThrow(UnauthorizedException('Only team staff can add players'));

      final result = await repository.addUnclaimedPlayer(
        teamId: const TeamId('t1'),
        displayName: name,
      );
      expect(result.getLeft().toNullable(), isA<AuthFailure>());
      verify(
        () => remote.addUnclaimedTeamMember(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: null,
          jerseyNumber: null,
          playerProfile: {},
        ),
      ).called(1);
      verifyNoMoreInteractions(remote);
    },
  );
}
