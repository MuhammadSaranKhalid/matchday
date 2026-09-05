import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/tournaments/data/datasources/tournaments_remote_datasource.dart';
import 'package:matchday/features/tournaments/data/repositories/tournaments_repository_impl.dart';
import 'package:matchday/features/tournaments/domain/draw/draw_builder.dart';
import 'package:matchday/features/tournaments/domain/draw/draw_plan.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TournamentsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late TournamentsRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(const DrawPlan()));

  setUp(() {
    remote = _MockRemote();
    repo = TournamentsRepositoryImpl(remote: remote);
  });

  DrawPlan planFor(TournamentType type, int teams) => buildDraw(
        type: type,
        orderedTeamIds: [for (var i = 1; i <= teams; i++) 't$i'],
        grounds: const ['G1', 'G2'],
        startDate: DateTime(2026, 4, 11),
      );

  void stubRemote() {
    when(
      () => remote.generateAndPublishFixtures(
        tournamentId: any(named: 'tournamentId'),
        plan: any(named: 'plan'),
        seedOrder: any(named: 'seedOrder'),
      ),
    ).thenAnswer((_) async => 7);
  }

  group('generateAndPublishFixtures', () {
    test('refuses a type with no generator, naming it', () async {
      final result = await repo.generateAndPublishFixtures(
        tournamentId: 't1',
        plan: planFor(TournamentType.doubleElimination, 8),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(
        result.getLeft().toNullable()!.message,
        contains('not supported yet'),
      );
      verifyNever(
        () => remote.generateAndPublishFixtures(
          tournamentId: any(named: 'tournamentId'),
          plan: any(named: 'plan'),
          seedOrder: any(named: 'seedOrder'),
        ),
      );
    });

    test('refuses an empty plan without calling the remote', () async {
      final result = await repo.generateAndPublishFixtures(
        tournamentId: 't1',
        plan: const DrawPlan(),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(
        () => remote.generateAndPublishFixtures(
          tournamentId: any(named: 'tournamentId'),
          plan: any(named: 'plan'),
          seedOrder: any(named: 'seedOrder'),
        ),
      );
    });

    test('forwards the whole plan — every round, not just the first', () async {
      stubRemote();
      final plan = planFor(TournamentType.knockout, 8);

      final result = await repo.generateAndPublishFixtures(
        tournamentId: 't1',
        plan: plan,
        seedOrder: const ['t1', 't2'],
      );

      expect(result.getRight().toNullable(), 7);

      final sent = verify(
        () => remote.generateAndPublishFixtures(
          tournamentId: 't1',
          plan: captureAny(named: 'plan'),
          seedOrder: const ['t1', 't2'],
        ),
      ).captured.single as DrawPlan;

      expect(sent.roundCount, 3);
      expect(sent.fixtures, hasLength(7));
      expect(
        sent.fixtures.where((f) => f.roundNumber > 1),
        hasLength(3),
        reason: 'the semis and final must travel with the payload',
      );
      expect(
        sent.fixtures.where((f) => f.prevSlotAId != null),
        isNotEmpty,
        reason: 'feeder links are what the advancement trigger follows',
      );
    });

    test('translates a server failure rather than throwing', () async {
      when(
        () => remote.generateAndPublishFixtures(
          tournamentId: any(named: 'tournamentId'),
          plan: any(named: 'plan'),
          seedOrder: any(named: 'seedOrder'),
        ),
      ).thenThrow(ServerException('The draw is already locked'));

      final result = await repo.generateAndPublishFixtures(
        tournamentId: 't1',
        plan: planFor(TournamentType.knockout, 4),
      );

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(
        result.getLeft().toNullable()!.message,
        contains('already locked'),
      );
    });
  });
}
