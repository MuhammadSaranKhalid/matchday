import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/sports/cricket/domain/entities/cricket_player_profile.dart';
import 'package:matchday/features/teams/data/datasources/team_membership_remote_datasource.dart';
import 'package:matchday/features/teams/data/repositories/team_membership_repository_impl.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/value_objects/jersey_number.dart';
import 'package:matchday/features/teams/domain/value_objects/player_display_name.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TeamMembershipRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late TeamMembershipRepositoryImpl repository;
  final name = PlayerDisplayName.create('Ali').getRight().toNullable()!;

  setUp(() {
    remote = _MockRemote();
    repository = TeamMembershipRepositoryImpl(remote: remote);
  });

  test(
    'creates cricket unclaimed player and membership through the atomic API with all details',
    () async {
      when(
        () => remote.addUnclaimedCricketPlayer(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: '+923001234567',
          jerseyNumber: 7,
          playerRole: 'batter',
          battingStyle: 'right_hand',
          bowlingStyle: 'right_arm_fast',
          preferredBallTypes: ['leather', 'tape'],
          yearsPlaying: 5,
        ),
      ).thenAnswer((_) async {});

      final result = await repository.addUnclaimedCricketPlayer(
        teamId: const TeamId('t1'),
        displayName: name,
        phoneNumber: ' +923001234567 ',
        jerseyNumber: JerseyNumber.create(7).getRight().toNullable(),
        playerRole: PlayerRole.batter,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmFast,
        preferredBallTypes: const [BallType.leather, BallType.tape],
        yearsPlaying: 5,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => remote.addUnclaimedCricketPlayer(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: '+923001234567',
          jerseyNumber: 7,
          playerRole: 'batter',
          battingStyle: 'right_hand',
          bowlingStyle: 'right_arm_fast',
          preferredBallTypes: ['leather', 'tape'],
          yearsPlaying: 5,
        ),
      ).called(1);
      verifyNoMoreInteractions(remote);
    },
  );

  test('a name alone works without optional details', () async {
    when(
      () => remote.addUnclaimedCricketPlayer(
        teamId: 't1',
        displayName: 'Ali',
        phoneNumber: null,
        jerseyNumber: null,
        playerRole: null,
        battingStyle: null,
        bowlingStyle: null,
        preferredBallTypes: [],
        yearsPlaying: null,
      ),
    ).thenAnswer((_) async {});

    final result = await repository.addUnclaimedCricketPlayer(
      teamId: const TeamId('t1'),
      displayName: name,
    );
    expect(result.isRight(), isTrue);
    verify(
      () => remote.addUnclaimedCricketPlayer(
        teamId: 't1',
        displayName: 'Ali',
        phoneNumber: null,
        jerseyNumber: null,
        playerRole: null,
        battingStyle: null,
        bowlingStyle: null,
        preferredBallTypes: [],
        yearsPlaying: null,
      ),
    ).called(1);
    verifyNoMoreInteractions(remote);
  });

  test(
    'a refused creation returns a failure without attempting direct inserts',
    () async {
      when(
        () => remote.addUnclaimedCricketPlayer(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: null,
          jerseyNumber: null,
          playerRole: null,
          battingStyle: null,
          bowlingStyle: null,
          preferredBallTypes: [],
          yearsPlaying: null,
        ),
      ).thenThrow(UnauthorizedException('Only team staff can add players'));

      final result = await repository.addUnclaimedCricketPlayer(
        teamId: const TeamId('t1'),
        displayName: name,
      );
      expect(result.getLeft().toNullable(), isA<AuthFailure>());
      verify(
        () => remote.addUnclaimedCricketPlayer(
          teamId: 't1',
          displayName: 'Ali',
          phoneNumber: null,
          jerseyNumber: null,
          playerRole: null,
          battingStyle: null,
          bowlingStyle: null,
          preferredBallTypes: [],
          yearsPlaying: null,
        ),
      ).called(1);
      verifyNoMoreInteractions(remote);
    },
  );
}
