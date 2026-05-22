import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/database/database_provider.dart';
import 'package:novex_clean_arch/core/database/wizard_draft_store.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';
import 'package:novex_clean_arch/features/teams/domain/usecases/create_team.dart';
import 'package:novex_clean_arch/features/teams/presentation/controllers/team_create_controller.dart';
import 'package:novex_clean_arch/features/teams/presentation/providers/teams_providers.dart';
import 'package:novex_clean_arch/features/teams/presentation/state/team_create_state.dart';

class _MockCreateTeam extends Mock implements CreateTeam {}

class _MockDraftStore extends Mock implements WizardDraftStore {}

void main() {
  late _MockCreateTeam createTeam;
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
    registerFallbackValue(const CreateTeamParams(name: 'x', type: TeamType.club));
  });

  setUp(() {
    createTeam = _MockCreateTeam();
    store = _MockDraftStore();
    when(() => store.load(any())).thenAnswer((_) async => null);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer.test(
      overrides: [
        createTeamUseCaseProvider.overrideWithValue(createTeam),
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
    when(() => createTeam.call(any())).thenAnswer((_) async => Right(team));

    final container = makeContainer();
    await container.read(teamCreateControllerProvider.future);
    final c = container.read(teamCreateControllerProvider.notifier);

    c.setName('Lahore Lions');
    c.setCity('Lahore');
    await c.submit();

    final state = container.read(teamCreateControllerProvider).value!;
    expect(state.createdTeamId, 't1');
    expect(state.submitting, isFalse);
    verify(() => createTeam.call(any())).called(1);
    verify(() => store.clear(any())).called(1);
  });
}
