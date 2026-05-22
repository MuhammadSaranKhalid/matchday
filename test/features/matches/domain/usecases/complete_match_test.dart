import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/matches/domain/repositories/matches_repository.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/complete_match.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';

class _MockRepo extends Mock implements MatchesRepository {}

void main() {
  late _MockRepo repo;
  late CompleteMatch useCase;

  final match = Match(
    id: const MatchId('m1'),
    teamAId: const TeamId('a'),
    teamBId: const TeamId('b'),
    format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4),
    status: MatchStatus.completed,
    createdBy: 'u1',
    createdAt: DateTime(2026),
  );

  setUpAll(() => registerFallbackValue(const MatchId('x')));

  setUp(() {
    repo = _MockRepo();
    useCase = CompleteMatch(repo);
    when(() => repo.completeMatch(
          id: any(named: 'id'),
          description: any(named: 'description'),
        )).thenAnswer((_) async => Right(match));
  });

  test('rejects an empty description', () async {
    final r = await useCase(
        const CompleteMatchParams(id: MatchId('m1'), description: '  '));
    expect(r.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() =>
        repo.completeMatch(id: any(named: 'id'), description: any(named: 'description')));
  });

  test('completes with a trimmed description', () async {
    final r = await useCase(const CompleteMatchParams(
        id: MatchId('m1'), description: '  Model Town XI 132/4 (14.3 ov)  '));
    expect(r.isRight(), isTrue);
    verify(() => repo.completeMatch(
        id: any(named: 'id'),
        description: 'Model Town XI 132/4 (14.3 ov)')).called(1);
  });
}
