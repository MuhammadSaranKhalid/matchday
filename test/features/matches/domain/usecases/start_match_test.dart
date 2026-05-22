import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/innings.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/matches/domain/repositories/matches_repository.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/start_match.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';

class _MockRepo extends Mock implements MatchesRepository {}

void main() {
  late _MockRepo repo;
  late StartMatch useCase;

  Match match({MatchStatus status = MatchStatus.accepted}) => Match(
        id: const MatchId('m1'),
        teamAId: const TeamId('a'),
        teamBId: const TeamId('b'),
        teamASquad: const ['a1', 'a2', 'a3'],
        teamBSquad: const ['b1', 'b2', 'b3'],
        format: const MatchFormat(
            oversPerInnings: 20,
            playersPerTeam: 3,
            ballType: MatchBallType.tape,
            maxOversPerBowler: 4),
        status: status,
        createdBy: 'u1',
        createdAt: DateTime(2026),
      );

  const innings = Innings(
    id: InningsId('i1'),
    matchId: MatchId('m1'),
    inningsNumber: 1,
    battingTeamId: TeamId('a'),
    bowlingTeamId: TeamId('b'),
    status: InningsStatus.inProgress,
  );

  setUpAll(() {
    registerFallbackValue(const TeamId('x'));
    registerFallbackValue(const MatchId('x'));
    registerFallbackValue(TossDecision.bat);
  });

  setUp(() {
    repo = _MockRepo();
    useCase = StartMatch(repo);
    when(() => repo.startMatch(
          id: any(named: 'id'),
          tossWonBy: any(named: 'tossWonBy'),
          tossDecision: any(named: 'tossDecision'),
          battingTeamId: any(named: 'battingTeamId'),
          bowlingTeamId: any(named: 'bowlingTeamId'),
          strikerId: any(named: 'strikerId'),
          nonStrikerId: any(named: 'nonStrikerId'),
          bowlerId: any(named: 'bowlerId'),
        )).thenAnswer((_) async => const Right(innings));
  });

  StartMatchParams p({
    Match? m,
    TeamId tossWonBy = const TeamId('a'),
    TossDecision decision = TossDecision.bat,
    String striker = 'a1',
    String nonStriker = 'a2',
    String bowler = 'b1',
  }) =>
      StartMatchParams(
        match: m ?? match(),
        tossWonBy: tossWonBy,
        tossDecision: decision,
        strikerId: striker,
        nonStrikerId: nonStriker,
        bowlerId: bowler,
      );

  test('rejects a non-accepted match', () async {
    final r = await useCase(p(m: match(status: MatchStatus.pending)));
    expect(r.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects identical openers', () async {
    final r = await useCase(p(nonStriker: 'a1'));
    expect(r.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects openers not in the batting XI', () async {
    final r = await useCase(p(striker: 'b1')); // b1 is not in team A's squad
    expect(r.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects a bowler not in the bowling XI', () async {
    final r = await useCase(p(bowler: 'a3')); // a3 bats, can't bowl for B
    expect(r.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('A wins + bats → team A bats; persists', () async {
    final r = await useCase(p());
    expect(r.isRight(), isTrue);
    verify(() => repo.startMatch(
          id: any(named: 'id'),
          tossWonBy: any(named: 'tossWonBy'),
          tossDecision: any(named: 'tossDecision'),
          battingTeamId: const TeamId('a'),
          bowlingTeamId: const TeamId('b'),
          strikerId: 'a1',
          nonStrikerId: 'a2',
          bowlerId: 'b1',
        )).called(1);
  });

  test('A wins + bowls → team B bats', () async {
    final r = await useCase(p(
      decision: TossDecision.bowl,
      striker: 'b1',
      nonStriker: 'b2',
      bowler: 'a1',
    ));
    expect(r.isRight(), isTrue);
    verify(() => repo.startMatch(
          id: any(named: 'id'),
          tossWonBy: any(named: 'tossWonBy'),
          tossDecision: any(named: 'tossDecision'),
          battingTeamId: const TeamId('b'),
          bowlingTeamId: const TeamId('a'),
          strikerId: 'b1',
          nonStrikerId: 'b2',
          bowlerId: 'a1',
        )).called(1);
  });
}
