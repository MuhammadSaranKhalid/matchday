import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
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

MatchInningsState _inningsAt({required int legalBalls, int version = 2}) =>
    MatchInningsState(
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      version: version,
      updatedAt: DateTime(2026),
      strikerId: const MatchPlayerId('mp1'),
      nonStrikerId: const MatchPlayerId('mp2'),
      bowlerId: const MatchPlayerId('mp9'),
      totalRuns: legalBalls,
      legalBallCount: legalBalls,
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
    when(() => repo.pendingOpsCount(
          matchId: any(named: 'matchId'),
          inningsNumber: any(named: 'inningsNumber'),
        )).thenAnswer((_) async => 0);
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

    test('a settle landing mid-over does not rewind the over position', () async {
      // Regression: over 9 was recorded as 8.1, 8.2, 8.3, 8.4, 8.2, 8.3, 8.4 —
      // positions repeating inside one over — and the following over then
      // appeared to end after two deliveries, because four of its six had been
      // filed into the previous one.
      //
      // `over_number` and `ball_in_over` are derived from legalBallCount at tap
      // time. Settling a delivery used to adopt the server's innings row
      // wholesale, but that row is only current as of THAT delivery. With
      // further balls already tapped it dragged the count backwards, and the
      // next tap reused a position that had already been issued.
      //
      // The count has to be dragged back BETWEEN taps to reproduce it: three
      // taps in a row all build their drafts before any reply lands, so they
      // advance correctly whether or not the bug is present.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      var stored = 0;
      final gates = <Completer<void>>[];
      when(() => repo.recordBall(any())).thenAnswer((_) async {
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
        stored += 1;
        return Right(BallOutcome(
          ball: _ball(runs: 1, id: 'server-$stored'),
          // A server that is accurate about what it holds, and therefore
          // BEHIND the device, which has already taken more deliveries.
          innings: _inningsAt(legalBalls: stored),
        ));
      });

      Future<void> pump() async {
        for (var i = 0; i < 8; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      await notifier(container).recordRun(1);
      await notifier(container).recordRun(1);
      await notifier(container).recordRun(1);
      await pump();

      // Let ONLY the first write land. The device is now three deliveries in;
      // the server's reply knows about one.
      gates.first.complete();
      await pump();

      // The scorer taps again while the queue is still draining.
      await notifier(container).recordRun(1);
      await pump();

      // Release the rest so every draft reaches the repository to be inspected.
      // Index-based: the stub appends a new gate as each queued write starts,
      // so the list grows while we are draining it.
      for (var i = 0; i < gates.length; i++) {
        if (!gates[i].isCompleted) gates[i].complete();
        await pump();
      }

      final drafts = verify(() => repo.recordBall(captureAny()))
          .captured
          .cast<BallDraft>();

      expect(drafts.length, 4);
      expect(
        drafts.map((d) => d.computed!.ballInOver).toList(),
        [1, 2, 3, 4],
        reason: 'a reply landing mid-over must not re-issue a used position',
      );
    });

    test('a delivery is refused while an end is empty', () async {
      // Regression: four consecutive wickets left the non-striker's end vacant,
      // and the pad stayed live — a single was then recorded against nobody.
      // There was a guard for a missing bowler and none for a missing batter.
      final container = makeContainer(
        innings: _innings(version: 1).copyWith(clearNonStriker: true),
      );
      await load(container);

      final result = await notifier(container).recordRun(1);

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>(),
        reason: 'nobody is at the non-striker end to run the single',
      );
      verifyNever(() => repo.recordBall(any()));
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
          )).thenAnswer((_) async => const Right(UndoOutcome.removedStored()));

      final result = await notifier(container).undoLastBall();

      expect(result.isRight(), isTrue);
      verify(() => repo.undoLastBall(
            matchId: const MatchId(_matchId),
            inningsNumber: 1,
          )).called(1);
    });

    test('undo stays available while writes are queued', () async {
      // Regression: `canUndo` required pendingCount == 0, so once writes stopped
      // landing — out of coverage, exactly when a mis-tap most needs taking
      // back — undo was disabled permanently. The repository had always
      // handled an unsent delivery by discarding the queued write; nothing
      // could reach that path.
      final container = makeContainer(innings: _innings(version: 1));
      await load(container);

      final gate = Completer<void>();
      when(() => repo.recordBall(any())).thenAnswer((_) async {
        await gate.future;
        return Right(BallOutcome(
          ball: _ball(runs: 1, id: 'server-1'),
          innings: _inningsAt(legalBalls: 1),
        ));
      });

      await notifier(container).recordRun(1);
      final painted = await load(container);
      expect(painted.hasPending, isTrue, reason: 'the write has not landed');
      expect(
        painted.canScore && painted.balls.isNotEmpty,
        isTrue,
        reason: 'the screen gates undo on exactly this, and it must hold '
            'while a delivery is still queued',
      );

      gate.complete();
    });

    test('a stored delivery is undone on the server, not locally', () async {
      // Regression: the repository chose between the two undo paths by looking
      // at the write-ahead log alone. After a spell of failed writes the log
      // held ops matching nothing on screen, so Undo discarded one of those and
      // appeared to do nothing at all — while the delivery the scorer wanted
      // gone stayed exactly where it was.
      final container = makeContainer(
        innings: _innings(version: 2, runs: 4),
        balls: [_ball(runs: 4, id: 'server-1')],
      );
      await load(container);
      when(() => repo.undoLastBall(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
            pendingOpId: any(named: 'pendingOpId'),
          )).thenAnswer((_) async => const Right(UndoOutcome.removedStored()));

      await notifier(container).undoLastBall();

      final captured = verify(() => repo.undoLastBall(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
            pendingOpId: captureAny(named: 'pendingOpId'),
          )).captured.single;

      expect(
        captured,
        isNull,
        reason: 'the last delivery is a stored row, so there is no queued '
            'write to discard — this must go to the server',
      );
    });

    test('undoing a queued delivery does not re-read the server', () async {
      // The server has never seen an unsent delivery, so its ball list omits
      // every one of them. Re-reading after a purely local undo wiped the rest
      // of the queue off the screen.
      final container = makeContainer(
        innings: _innings(version: 2, runs: 4),
        balls: [_ball(runs: 4)],
      );
      await load(container);
      when(() => repo.undoLastBall(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
          )).thenAnswer(
        (_) async => const Right(UndoOutcome.discardedPending('op-1')),
      );

      clearInteractions(repo);
      final result = await notifier(container).undoLastBall();

      expect(result.isRight(), isTrue);
      verifyNever(() => repo.listBalls(any(), any()));
      verifyNever(() => repo.getMatchInningsState(
            matchId: any(named: 'matchId'),
            inningsNumber: any(named: 'inningsNumber'),
          ));
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
