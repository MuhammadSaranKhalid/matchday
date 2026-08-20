import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

/// These are the rules that used to live inside `ScoringScreen`'s widget
/// methods, where nothing could test them. The wide-attribution bug that
/// corrupted scorecards lived in exactly that blind spot.

const _matchId = MatchId('m1');

Match _match({
  int overs = 20,
  int players = 11,
  int? wicketsToAllOut,
  TeamId? tossWonBy,
  TossDecision? tossDecision,
}) =>
    Match(
      id: _matchId,
      teamAId: const TeamId('a'),
      teamBId: const TeamId('b'),
      format: MatchFormat(
        oversPerInnings: overs,
        playersPerTeam: players,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
        wicketsToAllOut: wicketsToAllOut,
      ),
      status: MatchStatus.live,
      createdBy: 'u1',
      createdAt: DateTime(2026),
      tossWonBy: tossWonBy,
      tossDecision: tossDecision,
    );

MatchInningsState _innings({
  String? striker = 'mp1',
  String? nonStriker = 'mp2',
  String? bowler = 'mp9',
  int legalBalls = 0,
  int runs = 0,
  int wickets = 0,
}) =>
    MatchInningsState(
      matchId: _matchId,
      inningsNumber: 1,
      version: 1,
      updatedAt: DateTime(2026),
      strikerId: striker == null ? null : MatchPlayerId(striker),
      nonStrikerId: nonStriker == null ? null : MatchPlayerId(nonStriker),
      bowlerId: bowler == null ? null : MatchPlayerId(bowler),
      legalBallCount: legalBalls,
      totalRuns: runs,
      totalWickets: wickets,
    );

int _seq = 0;
Ball _ball({
  BallKind kind = BallKind.legal,
  int runs = 0,
  int extras = 0,
  bool wicket = false,
  WicketType? wicketType,
  String batsman = 'mp1',
  String bowler = 'mp9',
  int over = 0,
}) =>
    Ball(
      id: BallId('b${_seq++}'),
      matchId: _matchId,
      inningsNumber: 1,
      seq: _seq,
      overNumber: over,
      ballInOver: 1,
      isLegalDelivery: kind != BallKind.wide && kind != BallKind.noBall,
      ballKind: kind,
      runsScored: runs,
      extras: extras,
      isWicket: wicket,
      isFreeHit: false,
      wicketType: wicketType,
      batsmanId: batsman,
      bowlerId: bowler,
    );

ScoringState _state({
  Match? match,
  MatchInningsState? innings,
  List<Ball> balls = const [],
  bool canScore = true,
  int inningsNumber = 1,
  List<MatchPlayer> matchPlayers = const [],
}) =>
    ScoringState(
      match: match ?? _match(),
      inningsNumber: inningsNumber,
      innings: innings ?? _innings(),
      balls: balls,
      matchPlayers: matchPlayers,
      canScore: canScore,
    );

void main() {
  setUp(() => _seq = 0);

  group('splitExtraRuns — the wide bug', () {
    test('a wide sends everything to extras, nothing to the batter', () {
      // 1 penalty + 2 run. Crediting the batter here inflated their score and
      // understated the extras column while the team total looked right.
      final split = splitExtraRuns(BallKind.wide, 2);
      expect(split.runsScored, 0);
      expect(split.extras, 3);
    });

    test('a plain wide is one extra', () {
      final split = splitExtraRuns(BallKind.wide, 0);
      expect(split.runsScored, 0);
      expect(split.extras, 1);
    });

    test('a no-ball credits the bat and charges one extra', () {
      final split = splitExtraRuns(BallKind.noBall, 4);
      expect(split.runsScored, 4);
      expect(split.extras, 1);
    });

    test('byes and leg-byes are all extras', () {
      expect(splitExtraRuns(BallKind.bye, 2).runsScored, 0);
      expect(splitExtraRuns(BallKind.bye, 2).extras, 2);
      expect(splitExtraRuns(BallKind.legBye, 1).extras, 1);
    });

    test('the team total is unchanged by the fix', () {
      // What the old code produced vs the new, summed — the reason this went
      // unnoticed: the scoreboard was right, only the scorecard was wrong.
      final split = splitExtraRuns(BallKind.wide, 2);
      expect(split.runsScored + split.extras, 3);
    });
  });

  group('freeHitActive', () {
    test('false with no deliveries', () {
      expect(_state().freeHitActive, isFalse);
    });

    test('true immediately after a no-ball', () {
      expect(
        _state(balls: [_ball(kind: BallKind.noBall, extras: 1)]).freeHitActive,
        isTrue,
      );
    });

    test('a wide does not consume the free hit', () {
      final s = _state(balls: [
        _ball(kind: BallKind.noBall, extras: 1),
        _ball(kind: BallKind.wide, extras: 1),
      ]);
      expect(s.freeHitActive, isTrue);
    });

    test('the next legal delivery consumes it', () {
      final s = _state(balls: [
        _ball(kind: BallKind.noBall, extras: 1),
        _ball(runs: 1),
      ]);
      expect(s.freeHitActive, isFalse);
    });
  });

  group('inningsOver', () {
    test('false while the innings is in progress', () {
      expect(_state(innings: _innings(legalBalls: 30)).inningsOver, isFalse);
    });

    test('true when the overs are bowled out', () {
      final s = _state(
        match: _match(overs: 6),
        innings: _innings(legalBalls: 36),
      );
      expect(s.inningsOver, isTrue);
    });

    test('true when the side is all out', () {
      // 11 a side → 10 wickets ends it.
      expect(_state(innings: _innings(wickets: 10)).inningsOver, isTrue);
      expect(_state(innings: _innings(wickets: 9)).inningsOver, isFalse);
    });

    test('honours a format-specific wicketsToAllOut', () {
      final s = _match(players: 6, wicketsToAllOut: 5);
      expect(_state(match: s, innings: _innings(wickets: 5)).inningsOver, isTrue);
      expect(_state(match: s, innings: _innings(wickets: 4)).inningsOver, isFalse);
    });

    test('false before any innings row exists', () {
      final s = ScoringState(
        match: _match(),
        inningsNumber: 1,
        innings: null,
        balls: const [],
        matchPlayers: const [],
        canScore: true,
      );
      expect(s.inningsOver, isFalse);
    });
  });

  group('bowler gating', () {
    test('needsOpeningBowler only before the first delivery', () {
      expect(
        _state(innings: _innings(bowler: null)).needsOpeningBowler,
        isTrue,
      );
      expect(
        _state(innings: _innings(bowler: null), balls: [_ball()])
            .needsOpeningBowler,
        isFalse,
      );
    });

    test('bowlerSet is false for an empty id', () {
      expect(_state(innings: _innings(bowler: null)).bowlerSet, isFalse);
      expect(_state().bowlerSet, isTrue);
    });
  });

  group('overJustCompleted', () {
    test('false mid-over', () {
      final balls = List.generate(3, (_) => _ball());
      expect(_state(balls: balls).overJustCompleted, isFalse);
    });

    test('true after six legal deliveries in the over', () {
      final balls = List.generate(6, (_) => _ball());
      expect(_state(balls: balls).overJustCompleted, isTrue);
    });

    test('wides do not advance the over', () {
      final balls = [
        ...List.generate(5, (_) => _ball()),
        _ball(kind: BallKind.wide, extras: 1),
      ];
      expect(_state(balls: balls).overJustCompleted, isFalse);
    });
  });

  group('stats', () {
    test('batter runs exclude extras but include no-ball bat runs', () {
      final s = _state(balls: [
        _ball(runs: 4),
        _ball(kind: BallKind.wide, extras: 1),
        _ball(kind: BallKind.noBall, runs: 6, extras: 1),
      ]);
      final stats = s.batterStats('mp1');
      expect(stats.runs, 10);
      expect(stats.fours, 1);
      // The six came off a no-ball, so it is not counted as a legal six.
      expect(stats.sixes, 0);
    });

    test('bowler is not charged for byes', () {
      final s = _state(balls: [
        _ball(kind: BallKind.bye, extras: 4),
        _ball(runs: 1),
      ]);
      expect(s.bowlerSpell.runs, 1);
    });

    test('bowler is charged for wides', () {
      final s = _state(balls: [_ball(kind: BallKind.wide, extras: 2)]);
      expect(s.bowlerSpell.runs, 2);
    });

    test('a run-out is not the bowler’s wicket', () {
      final s = _state(balls: [
        _ball(wicket: true, wicketType: WicketType.runOut),
        _ball(wicket: true, wicketType: WicketType.bowled),
      ]);
      expect(s.bowlerSpell.wickets, 1);
    });

    test('overs and balls-this-over come off legal deliveries only', () {
      final s = _state(balls: [
        ...List.generate(8, (_) => _ball()),
        _ball(kind: BallKind.wide, extras: 1),
      ]);
      expect(s.bowlerSpell.overs, 1);
      expect(s.bowlerSpell.ballsThisOver, 2);
    });
  });

  group('score presentation', () {
    test('over text is legal balls in overs.balls', () {
      expect(_state(innings: _innings(legalBalls: 0)).overText, '0.0');
      expect(_state(innings: _innings(legalBalls: 7)).overText, '1.1');
    });

    test('run rate is runs per over, zero before a ball is bowled', () {
      expect(_state().currentRunRate, 0);
      final s = _state(innings: _innings(legalBalls: 12, runs: 18));
      expect(s.currentRunRate, closeTo(9, 0.001));
    });

    test('balls remaining counts down from the format', () {
      final s = _state(
        match: _match(overs: 6),
        innings: _innings(legalBalls: 10),
      );
      expect(s.ballsRemaining, 26);
    });
  });

  group('batting side by innings', () {
    // Team A won the toss and chose to bat, so A bats innings 1 and 3.
    final tossed = _match(
      tossWonBy: const TeamId('a'),
      tossDecision: TossDecision.bat,
    );

    test('alternates across innings', () {
      TeamId battingIn(int n) =>
          _state(match: tossed, inningsNumber: n).battingTeamId;

      expect(battingIn(1), const TeamId('a'));
      expect(battingIn(2), const TeamId('b'));
      // The screen used to special-case `inningsNumber == 1`, which handed
      // innings 3 to the wrong side — wrong for super overs and Tests.
      expect(battingIn(3), const TeamId('a'));
      expect(battingIn(4), const TeamId('b'));
    });

    test('bowling side is always the other one', () {
      final s = _state(match: tossed, inningsNumber: 2);
      expect(s.battingSide, MatchTeamSide.b);
      expect(s.bowlingSide, MatchTeamSide.a);
    });

    test('falls back to team A before the toss is recorded', () {
      expect(_state().battingTeamId, const TeamId('a'));
    });
  });

  group('squads', () {
    List<MatchPlayer> xi() => [
          for (var i = 1; i <= 3; i++)
            MatchPlayer(
              id: MatchPlayerId('a$i'),
              matchId: _matchId,
              teamSide: MatchTeamSide.a,
              profileId: 'pa$i',
              displayName: 'Batter $i',
            ),
          for (var i = 1; i <= 3; i++)
            MatchPlayer(
              id: MatchPlayerId('b$i'),
              matchId: _matchId,
              teamSide: MatchTeamSide.b,
              profileId: 'pb$i',
              displayName: 'Bowler $i',
            ),
        ];

    ScoringState squadState({
      List<Ball> balls = const [],
      MatchInningsState? innings,
    }) =>
        _state(
          match: _match(
            tossWonBy: const TeamId('a'),
            tossDecision: TossDecision.bat,
          ),
          innings: innings ?? _innings(striker: 'a1', nonStriker: 'a2', bowler: 'b1'),
          balls: balls,
          matchPlayers: xi(),
        );

    test('the fielding XI is the bowling side, named', () {
      final s = squadState();
      expect(s.fieldingXi.map((p) => p.matchPlayerId), ['b1', 'b2', 'b3']);
      expect(s.fieldingXi.first.name, 'Bowler 1');
    });

    test('names and avatars come off the lineup, not a roster', () {
      // The regression this guards: names were looked up against the team
      // roster, so a guest or substitute — in the XI but with no roster row —
      // came out as "Player 3f2a", and the avatar monogram derived from that
      // string was "P3". The lineup now names itself.
      final s = _state(
        match: _match(
          tossWonBy: const TeamId('a'),
          tossDecision: TossDecision.bat,
        ),
        innings: _innings(striker: 'g1', nonStriker: 'a2', bowler: 'b1'),
        matchPlayers: [
          const MatchPlayer(
            id: MatchPlayerId('g1'),
            matchId: _matchId,
            teamSide: MatchTeamSide.a,
            profileId: 'guest-9',
            displayName: 'Guest Batter',
            photoUrl: 'https://cdn/avatars/guest-9/a.jpg',
          ),
          const MatchPlayer(
            id: MatchPlayerId('a2'),
            matchId: _matchId,
            teamSide: MatchTeamSide.a,
            unclaimedId: 'x1',
            displayName: 'Village Keeper',
          ),
          const MatchPlayer(
            id: MatchPlayerId('b1'),
            matchId: _matchId,
            teamSide: MatchTeamSide.b,
            profileId: 'pb1',
            displayName: 'Bowler 1',
          ),
        ],
      );

      expect(s.strikerName, 'Guest Batter');
      expect(s.strikerPhoto, 'https://cdn/avatars/guest-9/a.jpg');

      // Unclaimed placeholders have no photo column at all — the monogram is
      // the final rendering for them, not a loading state.
      expect(s.nonStrikerName, 'Village Keeper');
      expect(s.nonStrikerPhoto, isNull);

      expect(s.bowlerName, 'Bowler 1');
    });

    test('the picker carries each candidate avatar through', () {
      final s = squadState();
      expect(s.availableBatters.map((p) => p.name), ['Batter 3']);
      expect(
        s.fieldingXi.map((p) => p.photoUrl),
        everyElement(isNull),
      );
    });

    test('available bowlers exclude whoever just bowled', () {
      // Nobody bowls consecutive overs.
      final s = squadState();
      expect(s.availableBowlers.map((p) => p.matchPlayerId), ['b2', 'b3']);
    });

    test('still excludes the last bowler once the over clears bowler_id', () {
      // The regression this guards, caught on-device: the server clears
      // `bowler_id` the moment an over completes — which is exactly when the
      // next-bowler picker opens. Reading the excluded bowler from the innings
      // row therefore excluded nobody, and the player who had just finished an
      // over was offered for the next one. Cricket does not allow that.
      final s = squadState(
        innings: _innings(striker: 'a1', nonStriker: 'a2', bowler: null),
        balls: [_ball(bowler: 'b1', batsman: 'a1')],
      );

      expect(s.bowlerSet, isFalse);
      expect(s.lastOverBowlerId, 'b1');
      expect(s.lastOverBowlerName, 'Bowler 1');
      expect(s.availableBowlers.map((p) => p.matchPlayerId), ['b2', 'b3']);
    });

    test('offers the whole fielding side when no ball has been bowled yet', () {
      final s = squadState(
        innings: _innings(striker: 'a1', nonStriker: 'a2', bowler: null),
      );

      expect(s.lastOverBowlerId, isNull);
      expect(s.availableBowlers.map((p) => p.matchPlayerId), ['b1', 'b2', 'b3']);
    });

    test('available batters exclude those already in or out', () {
      // a1 and a2 are at the crease; a3 is the only one left.
      final s = squadState();
      expect(s.availableBatters.map((p) => p.matchPlayerId), ['a3']);
    });

    test('a batter who has faced a ball is not available again', () {
      final s = squadState(
        innings: _innings(striker: 'a3', nonStriker: 'a2', bowler: 'b1'),
        balls: [_ball(batsman: 'a1')],
      );
      expect(s.availableBatters, isEmpty);
    });
  });
}
