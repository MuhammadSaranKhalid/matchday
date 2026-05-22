import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/ball.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/innings.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';
import 'package:novex_clean_arch/features/matches/domain/repositories/matches_repository.dart';
import 'package:novex_clean_arch/features/matches/domain/usecases/record_ball.dart';

class _MockRepo extends Mock implements MatchesRepository {}

class _FakeDraft extends Fake implements BallDraft {}

void main() {
  late _MockRepo repo;
  late RecordBall useCase;

  Innings innings({
    int balls = 0,
    String striker = 's',
    String nonStriker = 'ns',
    String bowler = 'b',
  }) =>
      Innings(
        id: const InningsId('i1'),
        matchId: const MatchId('m1'),
        inningsNumber: 1,
        battingTeamId: const TeamId('a'),
        bowlingTeamId: const TeamId('b'),
        status: InningsStatus.inProgress,
        totalBallsFaced: balls,
        currentStrikerId: striker,
        currentNonStrikerId: nonStriker,
        currentBowlerId: bowler,
      );

  setUpAll(() => registerFallbackValue(_FakeDraft()));

  setUp(() {
    repo = _MockRepo();
    useCase = RecordBall(repo);
    when(() => repo.recordBall(any()))
        .thenAnswer((_) async => Right(innings()));
  });

  BallDraft lastDraft() =>
      verify(() => repo.recordBall(captureAny())).captured.single as BallDraft;

  RecordBallParams params(BallInput input, {Innings? inn, int over = 0}) =>
      RecordBallParams(
        innings: inn ?? innings(),
        input: input,
        deliveriesThisOver: over,
      );

  test('single run rotates strike', () async {
    await useCase(params(const BallInput(runsOffBat: 1)));
    final d = lastDraft();
    expect(d.totalRuns, 1);
    expect(d.legalBallNumber, 1);
    expect(d.overNumber, 0);
    expect(d.nextStrikerId, 'ns'); // swapped
    expect(d.nextNonStrikerId, 's');
  });

  test('boundary four sets isFour and keeps strike', () async {
    await useCase(params(const BallInput(runsOffBat: 4)));
    final d = lastDraft();
    expect(d.isFour, isTrue);
    expect(d.totalRuns, 4);
    expect(d.nextStrikerId, 's'); // even runs, no swap
  });

  test('wide adds a penalty run and is not a legal ball', () async {
    await useCase(params(const BallInput(extraType: ExtraType.wide, extraRuns: 1)));
    final d = lastDraft();
    expect(d.extraType, ExtraType.wide);
    expect(d.runsScored, 0);
    expect(d.extraRuns, 2); // 1 penalty + 1
    expect(d.totalRuns, 2);
    expect(d.legalBallNumber, 0); // no legal ball consumed
  });

  test('no-ball: penalty + bat runs, not a legal ball', () async {
    await useCase(params(const BallInput(extraType: ExtraType.noBall, runsOffBat: 2)));
    final d = lastDraft();
    expect(d.extraType, ExtraType.noBall);
    expect(d.runsScored, 2);
    expect(d.extraRuns, 1);
    expect(d.totalRuns, 3);
    expect(d.legalBallNumber, 0);
  });

  test('wicket without a next batter is rejected', () async {
    final r = await useCase(params(
        const BallInput(isWicket: true, wicketType: WicketType.bowled)));
    expect(r.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.recordBall(any()));
  });

  test('wicket with a next batter replaces the striker', () async {
    await useCase(params(const BallInput(
      isWicket: true,
      wicketType: WicketType.bowled,
      newStrikerId: 'n3',
    )));
    final d = lastDraft();
    expect(d.isWicket, isTrue);
    expect(d.dismissedPlayerId, 's');
    expect(d.nextStrikerId, 'n3');
  });

  test('end of over swaps strike and requires a new bowler', () async {
    // 5 legal balls already → this legal ball is the 6th (over ends).
    final missing = await useCase(
      params(const BallInput(runsOffBat: 2), inn: innings(balls: 5), over: 5),
    );
    expect(missing.getLeft().toNullable(), isA<ValidationFailure>());

    await useCase(params(
      const BallInput(runsOffBat: 2, newBowlerId: 'b2'),
      inn: innings(balls: 5),
      over: 5,
    ));
    final d = lastDraft();
    expect(d.legalBallNumber, 6);
    expect(d.overEnded, isTrue);
    expect(d.nextBowlerId, 'b2');
    // Even runs → no mid-over swap; over-end swap puts the non-striker on strike.
    expect(d.nextStrikerId, 'ns');
  });
}
