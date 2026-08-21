import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/controllers/scoring_controller.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchesRepo extends Mock implements MatchesRepository {}

const _matchId = 'm1';
const _teamA = TeamId('a');
const _teamB = TeamId('b');

Match _match() => Match(
      id: const MatchId(_matchId),
      teamAId: _teamA,
      teamBId: _teamB,
      format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
      ),
      status: MatchStatus.live,
      createdBy: 'capA',
      createdAt: DateTime(2026),
      teamACaptain: 'capA',
      teamBCaptain: 'capB',
      tossWonBy: _teamA,
      tossDecision: TossDecision.bat,
      startPhase: MatchStartPhase.live,
    );

List<MatchPlayer> _lineup() => const [
      MatchPlayer(
        id: MatchPlayerId('mp1'),
        matchId: MatchId(_matchId),
        teamSide: MatchTeamSide.a,
        profileId: 'p1',
        displayName: 'Striker',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp2'),
        matchId: MatchId(_matchId),
        teamSide: MatchTeamSide.a,
        profileId: 'p2',
        displayName: 'Non-striker',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp9'),
        matchId: MatchId(_matchId),
        teamSide: MatchTeamSide.b,
        profileId: 'p9',
        displayName: 'Bowler',
      ),
    ];

MatchInningsState _innings({required int version, int runs = 0}) =>
    MatchInningsState(
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      version: version,
      updatedAt: DateTime(2026),
      strikerId: const MatchPlayerId('mp1'),
      nonStrikerId: const MatchPlayerId('mp2'),
      bowlerId: const MatchPlayerId('mp9'),
      totalRuns: runs,
      legalBallCount: runs == 0 ? 0 : 1,
    );

var _seq = 0;

Ball _noBall() => Ball(
      id: BallId('nb${++_seq}'),
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      seq: _seq,
      overNumber: 0,
      ballInOver: 0,
      isLegalDelivery: false,
      ballKind: BallKind.noBall,
      runsScored: 0,
      extras: 1,
      isWicket: false,
      isFreeHit: false,
      bowlerId: 'mp9',
    );

Ball _ball({int runs = 4, String? id}) => Ball(
      id: BallId(id ?? 'b${++_seq}'),
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      seq: _seq,
      overNumber: 0,
      ballInOver: 1,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runs,
      extras: 0,
      isWicket: false,
      isFreeHit: false,
      batsmanId: 'mp1',
      bowlerId: 'mp9',
    );

void main() {
  late _MockMatchesRepo repo;

  setUpAll(() {
    registerFallbackValue(const MatchId(_matchId));
    registerFallbackValue(
      const BallDraft(
        matchId: MatchId(_matchId),
        inningsNumber: 1,
        isLegalDelivery: true,
        ballKind: BallKind.legal,
      ),
    );
  });

  setUp(() {
    repo = _MockMatchesRepo();
    _seq = 0;
    when(() => repo.pendingOpsCount()).thenAnswer((_) async => 0);
    when(() => repo.syncPendingOps(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
        )).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer({
    MatchInningsState? innings,
    List<Ball> balls = const [],
  }) {
    when(() => repo.getMatch(const MatchId(_matchId)))
        .thenAnswer((_) async => Right(_match()));
    when(() => repo.getMatchInningsState(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
        )).thenAnswer((_) async => Right(innings ?? _innings(version: 1)));
    when(() => repo.listBalls(any(), any()))
        .thenAnswer((_) async => Right(balls));
    when(() => repo.listMatchPlayers(any()))
        .thenAnswer((_) async => Right(_lineup()));
    when(() => repo.canScoreInnings(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
        )).thenAnswer((_) async => const Right(true));

    final container = ProviderContainer.test(
      overrides: [
        matchesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(scoringControllerProvider(_matchId, 1), (_, __) {});
    return container;
  }

  Future<ScoringState> load(ProviderContainer c) =>
      c.read(scoringControllerProvider(_matchId, 1).future);

  ScoringController notifier(ProviderContainer c) =>
      c.read(scoringControllerProvider(_matchId, 1).notifier);

  group('ScoringController synchronous prediction and dispatch', () {
    test('paints delivery immediately and dispatches to repository', () async {
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);
      when(() => repo.recordBall(any())).thenAnswer(
        (_) async => Right(BallOutcome(
          ball: _ball(runs: 4, id: 'server-1'),
          innings: _innings(version: 2, runs: 4),
        )),
      );

      final result = await notifier(container).recordRun(4);
      final state = await load(container);

      expect(result.isRight(), isTrue);
      expect(state.totalRuns, 4);
      verify(() => repo.recordBall(any())).called(1);
    });

    test('an illegal delivery is refused before touching repository', () async {
      final container = makeContainer(
        innings: _innings(version: 1),
        balls: [_noBall()],
      );
      await load(container);

      final result =
          await notifier(container).recordWicket(type: WicketType.bowled);

      expect(result.isLeft(), isTrue);
      verifyNever(() => repo.recordBall(any()));
    });
  });

  group('undo', () {
    test('undoLastBall delegates to repository', () async {
      final container = makeContainer(
        innings: _innings(version: 2, runs: 4),
        balls: [_ball(runs: 4)],
      );
      await load(container);
      when(() => repo.undoLastBall(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
          )).thenAnswer((_) async => const Right(true));

      final result = await notifier(container).undoLastBall();

      expect(result.isRight(), isTrue);
      verify(() => repo.undoLastBall(
            matchId: const MatchId(_matchId),
            inningsNumber: 1,
          )).called(1);
    });
  });

  group('bowler and batter adjustments', () {
    test('setBowler delegates to startInnings in repository', () async {
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);
      when(() => repo.startInnings(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
            strikerId: any(named: 'strikerId'),
            nonStrikerId: any(named: 'nonStrikerId'),
            bowlerId: any(named: 'bowlerId'),
          )).thenAnswer((_) async => const Right(unit));

      final result = await notifier(container).setBowler('mp9');

      expect(result.isRight(), isTrue);
      verify(() => repo.startInnings(
            matchId: const MatchId(_matchId),
            inningsNumber: 1,
            strikerId: 'mp1',
            nonStrikerId: 'mp2',
            bowlerId: 'mp9',
          )).called(1);
    });
  });
}
