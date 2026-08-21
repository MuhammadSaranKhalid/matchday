import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/explore/domain/entities/explore_results.dart';
import 'package:matchday/features/explore/domain/entities/player_result.dart';
import 'package:matchday/features/explore/domain/repositories/explore_repository.dart';
import 'package:matchday/features/explore/presentation/controllers/explore_controller.dart';
import 'package:matchday/features/explore/presentation/providers/explore_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockExploreRepo extends Mock implements ExploreRepository {}

PlayerResult _player(String id, {String name = 'Ahmed Khan'}) => PlayerResult(
      id: id,
      kind: PlayerKind.profile,
      name: name,
      score: 0.8,
      username: 'ahmedk',
    );

ExploreResults _results(List<PlayerResult> players) =>
    ExploreResults(players: players);

void main() {
  late _MockExploreRepo repo;

  setUp(() {
    repo = _MockExploreRepo();
    when(() => repo.browse())
        .thenAnswer((_) async => const Right(ExploreBrowse.empty));
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer.test(
      overrides: [exploreRepositoryProvider.overrideWithValue(repo)],
    );
    // The controller is autodispose: without a listener it is torn down
    // between `read`s and an in-flight action would fire against a disposed
    // Ref. A real screen always holds a subscription; mirror that.
    c.listen(exploreControllerProvider, (_, __) {});
    addTearDown(c.dispose);
    return c;
  }

  group('query threshold', () {
    test('a 1-char query never reaches the repository', () async {
      final c = makeContainer();
      final notifier = c.read(exploreControllerProvider.notifier);

      notifier.setQuery('a');
      // Longer than the 300ms debounce — nothing should have been dispatched.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      verifyNever(() => repo.search(any(),
          category: any(named: 'category'), limit: any(named: 'limit')));
      expect(c.read(exploreControllerProvider).hasQuery, isFalse);
    });

    test('a 2-char query does reach the repository', () async {
      when(() => repo.search(any(),
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(_results([_player('p1')])));

      final c = makeContainer();
      c.read(exploreControllerProvider.notifier).setQuery('la');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      verify(() => repo.search('la',
          category: any(named: 'category'), limit: any(named: 'limit'))).called(1);
      expect(c.read(exploreControllerProvider).results.players, hasLength(1));
    });
  });

  group('debounce', () {
    test('rapid keystrokes coalesce into a single request', () async {
      when(() => repo.search(any(),
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(_results([_player('p1')])));

      final c = makeContainer();
      final notifier = c.read(exploreControllerProvider.notifier);

      notifier.setQuery('la');
      notifier.setQuery('lah');
      notifier.setQuery('laho');
      notifier.setQuery('lahor');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Only the final query is dispatched.
      verify(() => repo.search('lahor',
          category: any(named: 'category'), limit: any(named: 'limit'))).called(1);
      verifyNever(() => repo.search('la',
          category: any(named: 'category'), limit: any(named: 'limit')));
    });
  });

  group('race defeat', () {
    test('a slow earlier reply cannot overwrite a faster later one', () async {
      // "lah" resolves slowly with a stale result; "lahore" resolves fast.
      when(() => repo.search('lah',
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return Right(_results([_player('stale', name: 'Stale')]));
      });
      when(() => repo.search('lahore',
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(_results([_player('fresh', name: 'Fresh')])));

      final c = makeContainer();
      final notifier = c.read(exploreControllerProvider.notifier);

      notifier.setQuery('lah');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      notifier.setQuery('lahore');
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final players = c.read(exploreControllerProvider).results.players;
      expect(players.single.name, 'Fresh',
          reason: 'the stale "lah" reply must not land after "lahore"');
    });
  });

  group('loading', () {
    test('previous results are retained while a new request is in flight',
        () async {
      when(() => repo.search('lah',
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(_results([_player('p1')])));
      when(() => repo.search('laho',
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return Right(_results([_player('p2')]));
      });

      final c = makeContainer();
      final notifier = c.read(exploreControllerProvider.notifier);

      notifier.setQuery('lah');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(c.read(exploreControllerProvider).results.players, hasLength(1));

      notifier.setQuery('laho');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final mid = c.read(exploreControllerProvider);
      expect(mid.loading, isTrue, reason: 'request still in flight');
      expect(mid.results.players, hasLength(1),
          reason: 'the list must not blank between keystrokes');
    });
  });

  group('errors', () {
    test('a failure lands in state without clearing retained results',
        () async {
      when(() => repo.search('lah',
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(_results([_player('p1')])));
      when(() => repo.search('laho',
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final c = makeContainer();
      final notifier = c.read(exploreControllerProvider.notifier);

      notifier.setQuery('lah');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      notifier.setQuery('laho');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final s = c.read(exploreControllerProvider);
      expect(s.error, isA<NetworkFailure>());
      expect(s.results.players, hasLength(1));
      expect(s.loading, isFalse);
    });
  });

  group('clearing', () {
    test('dropping below the threshold cancels the pending request', () async {
      when(() => repo.search(any(),
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(_results([_player('p1')])));

      final c = makeContainer();
      final notifier = c.read(exploreControllerProvider.notifier);

      notifier.setQuery('lah');
      // Backspace to one character before the debounce elapses.
      notifier.setQuery('l');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      verifyNever(() => repo.search(any(),
          category: any(named: 'category'), limit: any(named: 'limit')));
      expect(c.read(exploreControllerProvider).loading, isFalse);
    });

    test('clearQuery empties results and returns to browse', () async {
      when(() => repo.search(any(),
              category: any(named: 'category'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(_results([_player('p1')])));

      final c = makeContainer();
      final notifier = c.read(exploreControllerProvider.notifier);

      notifier.setQuery('lah');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      notifier.clearQuery();

      final s = c.read(exploreControllerProvider);
      expect(s.query, isEmpty);
      expect(s.results.isEmpty, isTrue);
      expect(s.showBrowse, isTrue);
    });
  });

  group('grouping', () {
    test('nonEmptyCategories lists only groups with hits, teams first', () {
      const r = ExploreResults(
        players: [],
        teams: [],
        matches: [],
      );
      expect(r.nonEmptyCategories, isEmpty);

      final withPlayers = _results([_player('p1')]);
      expect(withPlayers.nonEmptyCategories, [ExploreCategory.players]);
      expect(withPlayers.totalCount, 1);
    });
  });
}
