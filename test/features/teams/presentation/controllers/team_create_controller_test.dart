import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/database/database_provider.dart';
import 'package:novex_clean_arch/core/database/wizard_draft_store.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';
import 'package:novex_clean_arch/features/teams/domain/repositories/teams_repository.dart';
import 'package:novex_clean_arch/features/teams/domain/value_objects/team_name.dart';
import 'package:novex_clean_arch/features/teams/presentation/controllers/team_create_controller.dart';
import 'package:novex_clean_arch/features/teams/presentation/providers/teams_providers.dart';
import 'package:novex_clean_arch/features/teams/presentation/state/team_create_state.dart';

class _MockTeamsRepo extends Mock implements TeamsRepository {}

class _MockDraftStore extends Mock implements WizardDraftStore {}

void main() {
  late _MockTeamsRepo repo;
  late _MockDraftStore store;

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
    registerFallbackValue(
      TeamName.create('Lahore Lions').getOrElse((_) => throw ''),
    );
    registerFallbackValue(TeamType.club);
    registerFallbackValue(TeamPrivacy.public);
  });

  setUp(() {
    repo = _MockTeamsRepo();
    store = _MockDraftStore();
    when(() => store.load(any())).thenAnswer((_) async => null);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer.test(
      overrides: [
        teamsRepositoryProvider.overrideWithValue(repo),
        wizardDraftStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    container.listen(teamCreateControllerProvider, (_, __) {});
    return container;
  }

  test('starts on the basics step with no draft', () async {
    final container = makeContainer();
    final state = await container.read(teamCreateControllerProvider.future);
    expect(state.step, TeamCreateStep.basics);
    expect(state.canContinueBasics, isFalse);
  });

  test('a 3+ char name unlocks the basics step', () async {
    final container = makeContainer();
    await container.read(teamCreateControllerProvider.future);
    final c = container.read(teamCreateControllerProvider.notifier);

    c.setName('Lahore Lions');
    expect(
      container.read(teamCreateControllerProvider).value!.canContinueBasics,
      isTrue,
    );
  });

  test('submit success records the created team id and clears the draft',
      () async {
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
          tagline: any(named: 'tagline'),
          logoMonogram: any(named: 'logoMonogram'),
        )).thenAnswer((_) async => Right(team));

    final container = makeContainer();
    await container.read(teamCreateControllerProvider.future);
    final c = container.read(teamCreateControllerProvider.notifier);

    c.setName('Lahore Lions');
    c.setCity('Lahore');
    await c.submit();

    final state = container.read(teamCreateControllerProvider).value!;
    expect(state.createdTeamId, 't1');
    expect(state.submitting, isFalse);
    verify(() => repo.createTeam(
          name: any(named: 'name'),
          type: any(named: 'type'),
          privacy: any(named: 'privacy'),
          description: any(named: 'description'),
          homeGround: any(named: 'homeGround'),
          city: any(named: 'city'),
          foundedYear: any(named: 'foundedYear'),
          primaryColor: any(named: 'primaryColor'),
          secondaryColor: any(named: 'secondaryColor'),
          tagline: any(named: 'tagline'),
          logoMonogram: any(named: 'logoMonogram'),
        )).called(1);
    verify(() => store.clear(any())).called(1);
  });
}
