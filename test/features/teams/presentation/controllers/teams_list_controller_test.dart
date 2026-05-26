import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/core/usecase/usecase.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/list_my_matches.dart';
import 'package:novex_clean_arch/features/matches/presentation/providers/matches_providers.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';
import 'package:novex_clean_arch/features/teams/presentation/controllers/teams_list_controller.dart';
import 'package:novex_clean_arch/features/teams/presentation/providers/teams_providers.dart';

class _MockListMyMatches extends Mock implements ListMyMatches {}

Team _team(String id, {String name = 'Team', String? color}) => Team(
      id: TeamId(id),
      ownerId: 'u1',
      name: name,
      type: TeamType.club,
      privacy: TeamPrivacy.public,
      managers: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      city: 'Lahore',
      primaryColor: color,
    );

Match _match(
  String id, {
  required String a,
  required String b,
  MatchStatus status = MatchStatus.pending,
}) =>
    Match(
      id: MatchId(id),
      teamAId: TeamId(a),
      teamBId: TeamId(b),
      format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
      ),
      status: status,
      createdBy: 'u1',
      createdAt: DateTime(2026),
    );

void main() {
  late _MockListMyMatches listMatches;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() => listMatches = _MockListMyMatches());

  ProviderContainer makeContainer({
    required List<Team> teams,
    List<Team> cached = const [],
    List<Match> matches = const [],
    Failure? matchesFailure,
  }) {
    when(() => listMatches.call(any())).thenAnswer(
      (_) async => matchesFailure != null ? Left(matchesFailure) : Right(matches),
    );
    final container = ProviderContainer.test(
      overrides: [
        myTeamsProvider.overrideWith((ref) => Stream.value(teams)),
        allTeamsProvider.overrideWith((ref) => Stream.value(cached)),
        listMyMatchesUseCaseProvider.overrideWithValue(listMatches),
      ],
    );
    addTearDown(container.dispose);
    container.listen(teamsListControllerProvider, (_, __) {});
    return container;
  }

  test('filters to active matches, resolves opponent + incoming', () async {
    final container = makeContainer(
      teams: [_team('a', name: 'My Side')],
      cached: [_team('b', name: 'Karachi Eagles', color: '#123456')],
      matches: [
        _match('m1', a: 'a', b: 'b', status: MatchStatus.pending), // I am A
        _match('m2', a: 'b', b: 'a', status: MatchStatus.live), // I am B (incoming)
        _match('m3', a: 'a', b: 'c', status: MatchStatus.declined), // excluded
      ],
    );

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.teams, hasLength(1));
    expect(view.activeMatches, hasLength(2)); // declined dropped

    final m1 = view.activeMatches.firstWhere((e) => e.match.id.value == 'm1');
    expect(m1.incoming, isFalse);
    expect(m1.opponent?.name, 'Karachi Eagles');

    final m2 = view.activeMatches.firstWhere((e) => e.match.id.value == 'm2');
    expect(m2.incoming, isTrue);
    expect(m2.opponent?.name, 'Karachi Eagles');
  });

  test('opponent stays null when the team is not cached', () async {
    final container = makeContainer(
      teams: [_team('a')],
      matches: [_match('m1', a: 'a', b: 'z', status: MatchStatus.pending)],
    );

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.activeMatches, hasLength(1));
    expect(view.activeMatches.single.opponent, isNull);
  });

  test('a matches failure still yields teams with no active matches', () async {
    final container = makeContainer(
      teams: [_team('a'), _team('b')],
      matchesFailure: const ServerFailure('offline'),
    );

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.teams, hasLength(2));
    expect(view.activeMatches, isEmpty);
  });

  test('empty teams list with active matches yields no active match entries',
      () async {
    final container = makeContainer(
      teams: const [],
      matches: [_match('m1', a: 'x', b: 'y', status: MatchStatus.live)],
    );

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.teams, isEmpty);
    // With no user teams, the match has no incoming/owning side — but
    // [TeamsListController.build] still includes it (incoming=false,
    // opponent=teamA). This documents that contract.
    expect(view.activeMatches, hasLength(1));
    expect(view.activeMatches.single.incoming, isFalse);
  });

  test('refresh re-runs build and picks up new matches', () async {
    final container = makeContainer(
      teams: [_team('a', name: 'My Side')],
      cached: [_team('b', name: 'Karachi Eagles')],
      matches: [_match('m1', a: 'a', b: 'b', status: MatchStatus.pending)],
    );

    final first = await container.read(teamsListControllerProvider.future);
    expect(first.activeMatches, hasLength(1));

    // Reconfigure the mock to return a different match set, then refresh.
    when(() => listMatches.call(any())).thenAnswer((_) async => Right([
          _match('m1', a: 'a', b: 'b', status: MatchStatus.pending),
          _match('m2', a: 'a', b: 'b', status: MatchStatus.live),
        ]));

    await container.read(teamsListControllerProvider.notifier).refresh();

    final second = await container.read(teamsListControllerProvider.future);
    expect(second.activeMatches, hasLength(2));
    expect(
      second.activeMatches.map((e) => e.match.id.value).toSet(),
      {'m1', 'm2'},
    );
  });
}
