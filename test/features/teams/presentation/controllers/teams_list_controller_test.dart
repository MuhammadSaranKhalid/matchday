import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/presentation/controllers/teams_list_controller.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';
import 'package:matchday/features/teams/presentation/state/my_teams_view.dart';

class _MockMatchesRepo extends Mock implements MatchesRepository {}

User _user(String id) => User(
      id: UserId(id),
      email: Email.create('$id@example.com').toNullable()!,
      displayName: id,
    );

Team _team(String id, {String name = 'Team', String? color, String owner = 'u1'}) =>
    Team(
      id: TeamId(id),
      ownerId: owner,
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
  late _MockMatchesRepo matchesRepo;

  setUp(() => matchesRepo = _MockMatchesRepo());

  ProviderContainer makeContainer({
    required List<Team> teams,
    List<Team> cached = const [],
    List<Match> matches = const [],
    Failure? matchesFailure,
    String userId = 'u1',
  }) {
    when(() => matchesRepo.listMyMatches()).thenAnswer(
      (_) async => matchesFailure != null ? Left(matchesFailure) : Right(matches),
    );
    final container = ProviderContainer.test(
      overrides: [
        myTeamsProvider.overrideWith((ref) => Stream.value(teams)),
        allTeamsProvider.overrideWith((ref) => Stream.value(cached)),
        matchesRepositoryProvider.overrideWithValue(matchesRepo),
        currentUserStreamProvider
            .overrideWith((ref) => Stream.value(_user(userId))),
      ],
    );
    addTearDown(container.dispose);
    container.listen(teamsListControllerProvider, (_, __) {});
    return container;
  }

  test('owned teams land in the captain bucket with a count subtitle', () async {
    final container = makeContainer(
      teams: [_team('a'), _team('b')], // both owned by u1
    );

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.isEmpty, isFalse);
    expect(view.teams.captain, hasLength(2));
    expect(view.teams.playing, isEmpty);
    expect(view.subtitle, '2 teams');
    expect(view.today, isNull);
  });

  test('hero match resolves opponent crest + which side is mine (live)',
      () async {
    final container = makeContainer(
      teams: [_team('a', name: 'My Side')],
      cached: [_team('b', name: 'Karachi Eagles', color: '#123456')],
      matches: [
        _match('m1', a: 'a', b: 'b', status: MatchStatus.pending),
        _match('m2', a: 'b', b: 'a', status: MatchStatus.live), // live wins
        _match('m3', a: 'a', b: 'c', status: MatchStatus.declined), // inactive
      ],
    );

    final view = await container.read(teamsListControllerProvider.future);

    final today = view.today;
    expect(today, isNotNull);
    expect(today!.live, isTrue);
    // m2 has teamA = 'b' (opponent), so my side is B.
    expect(today.a.name, 'Karachi Eagles');
    expect(today.b.name, 'My Side');
  });

  test('incoming pending match surfaces an "Incoming request" phrase', () async {
    final container = makeContainer(
      teams: [_team('a', name: 'My Side')],
      cached: [_team('b', name: 'Karachi Eagles')],
      // I am team B → incoming request.
      matches: [_match('m1', a: 'b', b: 'a', status: MatchStatus.pending)],
    );

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.today, isNotNull);
    expect(view.today!.live, isFalse);
    expect(view.today!.when, 'Incoming request');
    expect(view.subtitle, '1 team');
  });

  test('a matches failure still buckets teams with no hero match', () async {
    final container = makeContainer(
      teams: [_team('a'), _team('b')],
      matchesFailure: const ServerFailure('offline'),
    );

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.teams.captain, hasLength(2));
    expect(view.today, isNull);
    expect(view.isEmpty, isFalse);
  });

  test('first-team onboarding: subtitle + NeedsYou CTA targets the team',
      () async {
    final container = makeContainer(teams: [_team('a', name: 'Lions')]);

    final view = await container.read(teamsListControllerProvider.future);

    expect(view.subtitle, '1 team · onboarding');
    expect(view.needsYou, hasLength(1));
    expect(view.needsYou.single.actions.first.label, 'Add players');
    expect(view.needsYou.single.actions.first.manageTeamId, 'a');
  });

  test('setFilter re-derives synchronously without re-fetching matches',
      () async {
    final container = makeContainer(
      teams: [_team('a'), _team('b')],
    );
    await container.read(teamsListControllerProvider.future);

    container
        .read(teamsListControllerProvider.notifier)
        .setFilter(MyTeamsFilter.archived);

    final view = container.read(teamsListControllerProvider).value!;
    expect(view.activeFilter, MyTeamsFilter.archived);
    // Archived filter hides the captain bucket.
    expect(view.teams.captain, isEmpty);
    // Repo was called once (build), not again on filter change.
    verify(() => matchesRepo.listMyMatches()).called(1);
  });

  test('refresh re-runs build and picks up new matches', () async {
    final container = makeContainer(
      teams: [_team('a', name: 'My Side')],
      cached: [_team('b', name: 'Karachi Eagles')],
      matches: [_match('m1', a: 'a', b: 'b', status: MatchStatus.pending)],
    );

    final first = await container.read(teamsListControllerProvider.future);
    expect(first.today, isNotNull);
    expect(first.today!.live, isFalse);

    when(() => matchesRepo.listMyMatches()).thenAnswer((_) async => Right([
          _match('m1', a: 'a', b: 'b', status: MatchStatus.pending),
          _match('m2', a: 'a', b: 'b', status: MatchStatus.live),
        ]));

    await container.read(teamsListControllerProvider.notifier).refresh();

    final second = await container.read(teamsListControllerProvider.future);
    expect(second.today!.live, isTrue); // live match now wins the hero slot
  });
}
