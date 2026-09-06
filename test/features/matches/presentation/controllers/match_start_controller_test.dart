import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/controllers/match_start_controller.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/state/match_start_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchesRepo extends Mock implements MatchesRepository {}

const _matchId = 'm1';
const _teamA = TeamId('a');
const _teamB = TeamId('b');

User _user(String id) => User(
      id: UserId(id),
      email: Email.create('$id@example.com').toNullable()!,
      displayName: id,
    );

Match _match({TeamId? tossWonBy, TossDecision? decision, MatchStartPhase phase = MatchStartPhase.toss}) =>
    Match(
      id: const MatchId(_matchId),
      teamAId: _teamA,
      teamBId: _teamB,
      format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
      ),
      status: MatchStatus.pending,
      createdBy: 'capA',
      createdAt: DateTime(2026),
      teamACaptain: 'capA',
      teamBCaptain: 'capB',
      tossWonBy: tossWonBy,
      tossDecision: decision,
      startPhase: phase,
    );

/// Team A players `p1..p3`, materialised as match_players `mp1..mp3`.
List<MatchPlayer> _lineup() => [
      for (var i = 1; i <= 3; i++)
        MatchPlayer(
          id: MatchPlayerId('mp$i'),
          matchId: const MatchId(_matchId),
          teamSide: MatchTeamSide.a,
          profileId: 'p$i',
          displayName: 'Player $i',
          battingOrder: i,
        ),
    ];

MatchInningsState _innings({String? striker, String? nonStriker}) =>
    MatchInningsState(
      matchId: const MatchId(_matchId),
      inningsNumber: 1,
      version: 1,
      updatedAt: DateTime(2026),
      strikerId: striker == null ? null : MatchPlayerId(striker),
      nonStrikerId: nonStriker == null ? null : MatchPlayerId(nonStriker),
    );

void main() {
  late _MockMatchesRepo repo;

  setUpAll(() {
    registerFallbackValue(const MatchId(_matchId));
    registerFallbackValue(_teamA);
    registerFallbackValue(TossDecision.bat);
  });

  setUp(() => repo = _MockMatchesRepo());

  ProviderContainer makeContainer({
    Match? match,
    String userId = 'capA',
    List<MatchPlayer>? lineup,
    MatchInningsState? innings,
  }) {
    final container = ProviderContainer.test(
      overrides: [
        matchesRepositoryProvider.overrideWithValue(repo),
        currentUserStreamProvider
            .overrideWith((ref) => Stream.value(_user(userId))),
        liveMatchProvider(_matchId)
            .overrideWith((ref) => Stream.value(match ?? _match())),
        matchPlayersProvider(_matchId)
            .overrideWith((ref) async => lineup ?? _lineup()),
        liveInningsStateProvider(_matchId, 1)
            .overrideWith((ref) => Stream.value(innings)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchStartControllerProvider(_matchId), (_, __) {});
    return container;
  }

  Future<MatchStartState> load(ProviderContainer c) =>
      c.read(matchStartControllerProvider(_matchId).future);

  MatchStartController notifier(ProviderContainer c) =>
      c.read(matchStartControllerProvider(_matchId).notifier);

  group('viewer role', () {
    test('before the toss, only the match creator may act', () async {
      // _match() is created by capA.
      final creator = await load(makeContainer(userId: 'capA'));
      expect(creator.viewerRole, MatchStartViewerRole.captain);
      expect(creator.isCreator, isTrue);
      expect(creator.viewerCanAct, isTrue);

      final other = await load(makeContainer(userId: 'capB'));
      expect(other.viewerRole, MatchStartViewerRole.captain);
      expect(other.captainOf, _teamB);
      expect(other.viewerCanAct, isFalse);
    });

    test('once the winner is known, the call is their captain\'s alone',
        () async {
      final match = _match(tossWonBy: _teamB);

      final winner = await load(makeContainer(match: match, userId: 'capB'));
      expect(winner.tossStep, TossStep.decision);
      expect(winner.isViewerTossWinnerCaptain, isTrue);
      expect(winner.viewerCanAct, isTrue);

      // The creator has had their turn; bat-or-bowl is not theirs.
      final creator = await load(makeContainer(match: match, userId: 'capA'));
      expect(creator.isCreator, isTrue);
      expect(creator.viewerCanAct, isFalse);
    });

    test('after the toss, roles follow who is batting first', () async {
      // A won and chose to bowl → B bats first, so capB is the batting captain.
      final container = makeContainer(
        match: _match(tossWonBy: _teamA, decision: TossDecision.bowl),
        userId: 'capA',
      );
      final state = await load(container);

      expect(state.viewerRole, MatchStartViewerRole.bowlingCaptain);
      expect(state.battingTeamId, _teamB);
      expect(state.bowlingTeamId, _teamA);
      expect(state.isViewerBattingCaptain, isFalse);
    });

    test('a non-captain is always a spectator', () async {
      final state = await load(makeContainer(userId: 'someone-else'));

      expect(state.viewerRole, MatchStartViewerRole.spectator);
      expect(state.viewerCanAct, isFalse);
    });
  });

  group('tapOpener', () {
    test('fills the striker slot, then the non-striker', () async {
      final container = makeContainer();
      await load(container);

      notifier(container).tapOpener('p1');
      expect(container.read(matchStartControllerProvider(_matchId)).value,
          isA<MatchStartState>().having((s) => s.striker, 'striker', 'p1'));

      notifier(container).tapOpener('p2');
      final state =
          container.read(matchStartControllerProvider(_matchId)).value!;
      expect(state.striker, 'p1');
      expect(state.nonStriker, 'p2');
      expect(state.isLineupReady, isTrue);
    });

    test('tapping the non-striker swaps the pair', () async {
      final container = makeContainer();
      await load(container);

      notifier(container)
        ..tapOpener('p1')
        ..tapOpener('p2')
        ..tapOpener('p2'); // p2 currently holds non-striker

      final state =
          container.read(matchStartControllerProvider(_matchId)).value!;
      expect(state.striker, 'p2');
      expect(state.nonStriker, 'p1');
    });

    test('with both slots filled, a new name replaces the striker', () async {
      final container = makeContainer();
      await load(container);

      notifier(container)
        ..tapOpener('p1')
        ..tapOpener('p2')
        ..tapOpener('p3');

      final state =
          container.read(matchStartControllerProvider(_matchId)).value!;
      expect(state.striker, 'p3');
      expect(state.nonStriker, 'p2');
    });

    test('the same player cannot hold both slots', () async {
      final container = makeContainer();
      await load(container);

      notifier(container)
        ..tapOpener('p1')
        ..tapOpener('p1'); // striker filled → this targets the non-striker

      final state =
          container.read(matchStartControllerProvider(_matchId)).value!;
      expect(state.striker, isNull);
      expect(state.nonStriker, 'p1');
      expect(state.isLineupReady, isFalse);
    });
  });

  group('locked openers', () {
    test('openers persisted on the innings row surface as ref ids', () async {
      final container = makeContainer(
        match: _match(
          tossWonBy: _teamA,
          decision: TossDecision.bat,
          phase: MatchStartPhase.ready,
        ),
        innings: _innings(striker: 'mp1', nonStriker: 'mp2'),
      );

      final state = await load(container);

      expect(state.lockedStriker, 'p1');
      expect(state.lockedNonStriker, 'p2');
      expect(state.striker, 'p1');
      expect(state.isLineupReady, isTrue);
    });

    test('a local pick overrides the locked opener', () async {
      final container = makeContainer(
        innings: _innings(striker: 'mp1', nonStriker: 'mp2'),
      );
      await load(container);

      notifier(container).tapOpener('p3'); // both filled → replaces striker

      final state =
          container.read(matchStartControllerProvider(_matchId)).value!;
      expect(state.striker, 'p3');
      expect(state.lockedStriker, 'p1');
    });
  });

  group('writes', () {
    test('submitTossWinner rejects an empty selection without calling the repo',
        () async {
      final container = makeContainer();
      await load(container);

      final result = await notifier(container).submitTossWinner();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repo.recordTossWinner(
            id: any(named: 'id'),
            wonBy: any(named: 'wonBy'),
          ));
    });

    test('submitTossWinner sends the winner alone and stops there', () async {
      when(() => repo.recordTossWinner(
            id: any(named: 'id'),
            wonBy: any(named: 'wonBy'),
          )).thenAnswer((_) async => const Right(unit));

      final container = makeContainer();
      await load(container);

      notifier(container).pickTossWinner(_teamB);
      final result = await notifier(container).submitTossWinner();

      expect(result.isRight(), isTrue);
      verify(() => repo.recordTossWinner(
            id: const MatchId(_matchId),
            wonBy: _teamB,
          )).called(1);

      // No decision is implied by recording a winner: the flow parks on the
      // second act until the winning captain calls it.
      final state =
          container.read(matchStartControllerProvider(_matchId)).value!;
      expect(state.tossStep, TossStep.decision);
      expect(state.match.tossDecision, isNull);
      expect(state.phase, MatchStartPhase.toss);
      expect(state.pendingTossWinner, isNull);
      expect(state.isBusy, isFalse);
    });

    test('submitTossDecision rejects an empty call without calling the repo',
        () async {
      final container = makeContainer(
        match: _match(tossWonBy: _teamB),
        userId: 'capB',
      );
      await load(container);

      final result = await notifier(container).submitTossDecision();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repo.recordTossDecision(
            id: any(named: 'id'),
            decision: any(named: 'decision'),
          ));
    });

    test('submitTossDecision settles which side bats', () async {
      when(() => repo.recordTossDecision(
            id: any(named: 'id'),
            decision: any(named: 'decision'),
          )).thenAnswer((_) async => const Right(unit));

      final container = makeContainer(
        match: _match(tossWonBy: _teamB),
        userId: 'capB',
      );
      await load(container);

      notifier(container).pickTossDecision(TossDecision.bowl);
      final result = await notifier(container).submitTossDecision();

      expect(result.isRight(), isTrue);
      verify(() => repo.recordTossDecision(
            id: const MatchId(_matchId),
            decision: TossDecision.bowl,
          )).called(1);

      // B won and elected to bowl, so A bats first and capB — who made the
      // call — is the bowling captain from here on.
      final state =
          container.read(matchStartControllerProvider(_matchId)).value!;
      expect(state.phase, MatchStartPhase.lineup);
      expect(state.battingTeamId, _teamA);
      expect(state.viewerRole, MatchStartViewerRole.bowlingCaptain);
      expect(state.pendingDecision, isNull);
      expect(state.isBusy, isFalse);
    });

    test('submitOpeners translates ref ids to match_player ids', () async {
      when(() => repo.submitMatchOpeners(
            id: any(named: 'id'),
            strikerId: any(named: 'strikerId'),
            nonStrikerId: any(named: 'nonStrikerId'),
          )).thenAnswer((_) async => const Right(unit));

      final container = makeContainer();
      await load(container);

      notifier(container)
        ..tapOpener('p2')
        ..tapOpener('p3');
      final result = await notifier(container).submitOpeners();

      expect(result.isRight(), isTrue);
      verify(() => repo.submitMatchOpeners(
            id: const MatchId(_matchId),
            strikerId: 'mp2',
            nonStrikerId: 'mp3',
          )).called(1);
    });

    test('submitOpeners refuses a player missing from the match XI', () async {
      final container = makeContainer();
      await load(container);

      notifier(container)
        ..tapOpener('ghost')
        ..tapOpener('p1');
      final result = await notifier(container).submitOpeners();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repo.submitMatchOpeners(
            id: any(named: 'id'),
            strikerId: any(named: 'strikerId'),
            nonStrikerId: any(named: 'nonStrikerId'),
          ));
    });

    test('a failed write still lowers the busy flag', () async {
      when(() => repo.startMatchNow(any()))
          .thenAnswer((_) async => const Left(ServerFailure('nope')));

      final container = makeContainer();
      await load(container);

      final result = await notifier(container).startMatchNow();

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(
        container.read(matchStartControllerProvider(_matchId)).value!.isBusy,
        isFalse,
      );
    });
  });
}
