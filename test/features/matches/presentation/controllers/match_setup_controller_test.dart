import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/database/database_provider.dart';
import 'package:novex_clean_arch/core/database/wizard_draft_store.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/create_match_request.dart';
import 'package:novex_clean_arch/features/matches/presentation/controllers/match_setup_controller.dart';
import 'package:novex_clean_arch/features/matches/presentation/providers/matches_providers.dart';
import 'package:novex_clean_arch/features/matches/presentation/state/match_setup_state.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';

class _MockCreate extends Mock implements CreateMatchRequest {}

class _MockDraftStore extends Mock implements WizardDraftStore {}

void main() {
  late _MockCreate create;
  late _MockDraftStore store;

  final match = Match(
    id: const MatchId('m1'),
    teamAId: const TeamId('a'),
    teamBId: const TeamId('b'),
    format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 2,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4),
    status: MatchStatus.pending,
    createdBy: 'u1',
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(
      const CreateMatchRequestParams(
        teamAId: TeamId('a'),
        teamBId: TeamId('b'),
        format: MatchFormat(
            oversPerInnings: 20,
            playersPerTeam: 2,
            ballType: MatchBallType.tape,
            maxOversPerBowler: 4),
        squad: ['p1', 'p2'],
        captain: 'p1',
      ),
    );
  });

  setUp(() {
    create = _MockCreate();
    store = _MockDraftStore();
    when(() => store.load(any())).thenAnswer((_) async => null);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer.test(
      overrides: [
        createMatchRequestUseCaseProvider.overrideWithValue(create),
        wizardDraftStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchSetupControllerProvider('a'), (_, __) {});
    return container;
  }

  test('starts on the type step', () async {
    final container = makeContainer();
    final state =
        await container.read(matchSetupControllerProvider('a').future);
    expect(state.step, MatchSetupStep.type);
  });

  test('togglePlayer respects the playersPerTeam cap and xiComplete', () async {
    final container = makeContainer();
    await container.read(matchSetupControllerProvider('a').future);
    final c = container.read(matchSetupControllerProvider('a').notifier);

    c.setPlayersPerTeam(2);
    c.togglePlayer('p1');
    c.togglePlayer('p2');
    c.togglePlayer('p3'); // over cap — ignored
    c.setCaptain('p1');

    final s = container.read(matchSetupControllerProvider('a')).value!;
    expect(s.selectedPlayers, {'p1', 'p2'});
    expect(s.xiComplete, isTrue);
  });

  test('submit success records the created match id', () async {
    when(() => create.call(any())).thenAnswer((_) async => Right(match));

    final container = makeContainer();
    await container.read(matchSetupControllerProvider('a').future);
    final c = container.read(matchSetupControllerProvider('a').notifier);

    c.pickOpponent('b', 'Model Town XI');
    c.setPlayersPerTeam(2);
    c.togglePlayer('p1');
    c.togglePlayer('p2');
    c.setCaptain('p1');
    c.setVenueGround('Gaddafi B');
    c.setWhen(DateTime(2026, 6, 1, 16));
    await c.submit();

    final s = container.read(matchSetupControllerProvider('a')).value!;
    expect(s.createdMatchId, 'm1');
    verify(() => create.call(any())).called(1);
    verify(() => store.clear(any())).called(1);
  });
}
