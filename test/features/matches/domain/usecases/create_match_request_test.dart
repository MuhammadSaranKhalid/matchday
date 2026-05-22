import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/matches/domain/repositories/matches_repository.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/create_match_request.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';

class _MockRepo extends Mock implements MatchesRepository {}

void main() {
  late _MockRepo repo;
  late CreateMatchRequest useCase;

  const format = MatchFormat(
    oversPerInnings: 20,
    playersPerTeam: 3,
    ballType: MatchBallType.tape,
    maxOversPerBowler: 4,
  );

  final match = Match(
    id: const MatchId('m1'),
    teamAId: const TeamId('a'),
    teamBId: const TeamId('b'),
    format: format,
    status: MatchStatus.pending,
    createdBy: 'u1',
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(const TeamId('fallback'));
    registerFallbackValue(format);
  });

  setUp(() {
    repo = _MockRepo();
    useCase = CreateMatchRequest(repo);
    when(() => repo.createMatchRequest(
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          format: any(named: 'format'),
          squad: any(named: 'squad'),
          captain: any(named: 'captain'),
          keeper: any(named: 'keeper'),
          venue: any(named: 'venue'),
          scheduledStartTime: any(named: 'scheduledStartTime'),
        )).thenAnswer((_) async => Right(match));
  });

  CreateMatchRequestParams params({
    List<String> squad = const ['p1', 'p2', 'p3'],
    String captain = 'p1',
    String? keeper,
    Venue? venue = const Venue(ground: 'Gaddafi B'),
    DateTime? when,
  }) =>
      CreateMatchRequestParams(
        teamAId: const TeamId('a'),
        teamBId: const TeamId('b'),
        format: format,
        squad: squad,
        captain: captain,
        keeper: keeper,
        venue: venue,
        scheduledStartTime: when ?? DateTime(2026, 6, 1, 16),
      );

  test('rejects an XI that is not exactly playersPerTeam', () async {
    final result = await useCase(params(squad: const ['p1', 'p2']));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects a captain not in the XI', () async {
    final result = await useCase(params(captain: 'pX'));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects a keeper not in the XI', () async {
    final result = await useCase(params(keeper: 'pX'));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects a missing venue', () async {
    final result = await useCase(params(venue: null));
    expect(
      result.getLeft().toNullable(),
      isA<ValidationFailure>()
          .having((f) => f.message, 'message', 'A venue is required'),
    );
  });

  test('sends a valid request', () async {
    final result = await useCase(params());
    expect(result.isRight(), isTrue);
    verify(() => repo.createMatchRequest(
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          format: any(named: 'format'),
          squad: any(named: 'squad'),
          captain: 'p1',
          keeper: any(named: 'keeper'),
          venue: any(named: 'venue'),
          scheduledStartTime: any(named: 'scheduledStartTime'),
        )).called(1);
  });
}
