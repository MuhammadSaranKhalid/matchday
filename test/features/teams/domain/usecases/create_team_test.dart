import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';
import 'package:novex_clean_arch/features/teams/domain/repositories/teams_repository.dart';
import 'package:novex_clean_arch/features/teams/domain/usecases/create_team.dart';
import 'package:novex_clean_arch/features/teams/domain/value_objects/team_name.dart';

class _MockTeamsRepo extends Mock implements TeamsRepository {}

void main() {
  late _MockTeamsRepo repo;
  late CreateTeam useCase;

  final team = Team(
    id: const TeamId('t1'),
    ownerId: 'u1',
    name: 'Lahore Lions',
    type: TeamType.club,
    privacy: TeamPrivacy.public,
    managers: const ['u1'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(TeamName.create('Lahore Lions').getRight().toNullable()!);
    registerFallbackValue(TeamType.club);
    registerFallbackValue(TeamPrivacy.public);
  });

  setUp(() {
    repo = _MockTeamsRepo();
    useCase = CreateTeam(repo);
    when(() => repo.createTeam(
          name: any(named: 'name'),
          type: any(named: 'type'),
          privacy: any(named: 'privacy'),
          description: any(named: 'description'),
          homeGround: any(named: 'homeGround'),
          city: any(named: 'city'),
          foundedYear: any(named: 'foundedYear'),
          primaryColor: any(named: 'primaryColor'),
          secondaryColor: any(named: 'secondaryColor'),
        )).thenAnswer((_) async => Right(team));
  });

  test('rejects a name shorter than 3 chars without calling the repo', () async {
    final result = await useCase(
      const CreateTeamParams(name: 'LL', type: TeamType.club),
    );
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.createTeam(
          name: any(named: 'name'),
          type: any(named: 'type'),
        ));
  });

  test('forwards a valid team and blanks empty optionals to null', () async {
    final result = await useCase(
      const CreateTeamParams(
        name: '  Lahore Lions  ',
        type: TeamType.club,
        description: '   ',
      ),
    );
    expect(result.isRight(), isTrue);
    verify(() => repo.createTeam(
          name: any(named: 'name'),
          type: TeamType.club,
          privacy: any(named: 'privacy'),
          description: null,
          homeGround: any(named: 'homeGround'),
          city: any(named: 'city'),
          foundedYear: any(named: 'foundedYear'),
          primaryColor: any(named: 'primaryColor'),
          secondaryColor: any(named: 'secondaryColor'),
        )).called(1);
  });
}
