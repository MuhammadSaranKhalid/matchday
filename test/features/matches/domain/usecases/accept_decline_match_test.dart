import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/matches/domain/repositories/matches_repository.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/accept_match.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/decline_match.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';

class _MockRepo extends Mock implements MatchesRepository {}

void main() {
  late _MockRepo repo;
  late AcceptMatch accept;
  late DeclineMatch decline;

  final match = Match(
    id: const MatchId('m1'),
    teamAId: const TeamId('a'),
    teamBId: const TeamId('b'),
    format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 2,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4),
    status: MatchStatus.accepted,
    createdBy: 'u1',
    createdAt: DateTime(2026),
  );

  setUpAll(() => registerFallbackValue(const MatchId('x')));

  setUp(() {
    repo = _MockRepo();
    accept = AcceptMatch(repo);
    decline = DeclineMatch(repo);
    when(() => repo.acceptMatch(
          id: any(named: 'id'),
          squad: any(named: 'squad'),
          captain: any(named: 'captain'),
          keeper: any(named: 'keeper'),
        )).thenAnswer((_) async => Right(match));
    when(() => repo.declineMatch(id: any(named: 'id'), reason: any(named: 'reason')))
        .thenAnswer((_) async => Right(match));
  });

  group('AcceptMatch', () {
    AcceptMatchParams p({
      List<String> squad = const ['p1', 'p2'],
      String captain = 'p1',
      String? keeper,
    }) =>
        AcceptMatchParams(
          id: const MatchId('m1'),
          playersPerTeam: 2,
          squad: squad,
          captain: captain,
          keeper: keeper,
        );

    test('rejects wrong-size XI', () async {
      final r = await accept(p(squad: const ['p1']));
      expect(r.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repo.acceptMatch(
          id: any(named: 'id'),
          squad: any(named: 'squad'),
          captain: any(named: 'captain'),
          keeper: any(named: 'keeper')));
    });

    test('rejects captain not in XI', () async {
      final r = await accept(p(captain: 'pX'));
      expect(r.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('rejects keeper not in XI', () async {
      final r = await accept(p(keeper: 'pX'));
      expect(r.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('accepts a valid XI', () async {
      final r = await accept(p(keeper: 'p2'));
      expect(r.isRight(), isTrue);
      verify(() => repo.acceptMatch(
          id: any(named: 'id'),
          squad: any(named: 'squad'),
          captain: 'p1',
          keeper: 'p2')).called(1);
    });
  });

  group('DeclineMatch', () {
    test('normalises a blank reason to null', () async {
      await decline(const DeclineMatchParams(id: MatchId('m1'), reason: '   '));
      verify(() => repo.declineMatch(id: any(named: 'id'), reason: null))
          .called(1);
    });

    test('forwards a real reason', () async {
      await decline(
          const DeclineMatchParams(id: MatchId('m1'), reason: 'Venue too far'));
      verify(() =>
              repo.declineMatch(id: any(named: 'id'), reason: 'Venue too far'))
          .called(1);
    });
  });
}
