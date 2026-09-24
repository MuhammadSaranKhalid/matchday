import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/domain/entities/match_wicket.dart';
import 'package:matchday/features/matches/domain/scoring/scorecard.dart';

/// The completed-match screen derives every figure from the delivery ledger —
/// there are no aggregate stats tables. That makes this arithmetic, and it
/// encodes real cricket rules (a wide is not a ball faced; byes are not charged
/// to the bowler; a maiden must be a COMPLETE over). Those deserve tests rather
/// than a look at the screen.
///
/// NOTE: this is aggregation, not the scoring engine. The engine — which
/// decides what a delivery *is* — remains the single source of cricket rules
/// and is pinned by vectors.json. Nothing here may contradict it.
void main() {
  const bpo = 6;

  Ball ball({
    required int seq,
    required int over,
    required int ballInOver,
    String striker = 'p1',
    String nonStriker = 'p2',
    String bowler = 'b1',
    int runs = 0,
    int extras = 0,
    BallKind kind = BallKind.legal,
    bool wicket = false,
  }) =>
      Ball(
        id: BallId('b$seq'),
        matchId: const MatchId('m1'),
        inningsNumber: 1,
        seq: seq,
        overNumber: over,
        ballInOver: ballInOver,
        isLegalDelivery: kind != BallKind.wide && kind != BallKind.noBall,
        ballKind: kind,
        runsScored: runs,
        extras: extras,
        isWicket: wicket,
        isFreeHit: false,
        batsmanId: striker,
        nonStrikerId: nonStriker,
        bowlerId: bowler,
      );

  final squad = [
    for (final e in {'p1': 'Ali Raza', 'p2': 'Bilal Khan', 'p3': 'Usman Tariq'}
        .entries)
      MatchPlayer(
        id: MatchPlayerId(e.key),
        matchId: const MatchId('m1'),
        teamSide: MatchTeamSide.a,
        displayName: e.value,
        profileId: 'u-${e.key}',
      ),
    const MatchPlayer(
      id: MatchPlayerId('b1'),
      matchId: MatchId('m1'),
      teamSide: MatchTeamSide.b,
      displayName: 'Kamran Shah',
      profileId: 'u-b1',
    ),
  ];

  InningsCard build(List<Ball> balls, {List<MatchWicket> wickets = const []}) =>
      buildInningsCard(
        inningsNumber: 1,
        battingTeamSide: 'a',
        balls: balls,
        wickets: wickets,
        squad: squad,
        ballsPerOver: bpo,
      );

  test('a wide is not a ball faced, but it does count against the bowler', () {
    final card = build([
      ball(seq: 1, over: 0, ballInOver: 1, runs: 1),
      ball(seq: 2, over: 0, ballInOver: 0, extras: 1, kind: BallKind.wide),
      ball(seq: 3, over: 0, ballInOver: 2, runs: 4),
    ]);

    final ali = card.batting.firstWhere((b) => b.playerId == 'p1');
    expect(ali.runs, 5);
    expect(ali.balls, 2, reason: 'the wide is not a ball faced');
    expect(ali.fours, 1);

    final bowler = card.bowling.single;
    expect(bowler.runs, 6, reason: 'the wide IS charged to the bowler');
    expect(bowler.legalBalls, 2);
    expect(bowler.wides, 1);
    expect(card.totalRuns, 6);
    expect(card.legalBalls, 2);
  });

  test('byes and leg-byes score for the side but not against the bowler', () {
    final card = build([
      ball(seq: 1, over: 0, ballInOver: 1, extras: 4, kind: BallKind.bye),
      ball(seq: 2, over: 0, ballInOver: 2, extras: 2, kind: BallKind.legBye),
    ]);

    expect(card.totalRuns, 6);
    expect(card.extras.byes, 4);
    expect(card.extras.legByes, 2);
    expect(card.extras.total, 6);
    expect(card.extras.label, 'b 4 · lb 2');
    expect(card.bowling.single.runs, 0,
        reason: 'a bye is the keeper\'s fault, not the bowler\'s');
    // They are legal deliveries, so they still count towards the over.
    expect(card.bowling.single.legalBalls, 2);
  });

  test('a maiden must be a complete over that cost nothing', () {
    // Over 0: six dots → a maiden. Over 1: five dots, then the over is
    // abandoned (rain) → not a maiden even though it cost nothing.
    final card = build([
      for (var i = 1; i <= 6; i++) ball(seq: i, over: 0, ballInOver: i),
      for (var i = 1; i <= 5; i++) ball(seq: 6 + i, over: 1, ballInOver: i),
    ]);
    expect(card.bowling.single.maidens, 1);
    expect(card.bowling.single.dots, 11);
    expect(card.bowling.single.economy, 0);
  });

  test('a run out credits no bowler', () {
    final wickets = [
      MatchWicket(
        wicketId: 'w1',
        deliveryId: 'b2',
        inningsId: 'i1',
        playerOutId: 'p2',
        dismissalKind: 'run_out',
        isBowlerCredited: false,
        primaryFielderId: 'b1',
        fallOfWicketScore: 1,
        fallOfWicketNumber: 1,
        fallOfWicketOvers: 0.2,
        createdAt: DateTime(2026),
      ),
    ];
    final card = build([
      ball(seq: 1, over: 0, ballInOver: 1, runs: 1),
      ball(seq: 2, over: 0, ballInOver: 2, wicket: true),
    ], wickets: wickets);

    expect(card.bowling.single.wickets, 0);
    expect(card.batting.firstWhere((b) => b.playerId == 'p2').dismissal,
        'run out (Kamran Shah)');
    expect(card.fallOfWickets.single.label, '1-1 (Bilal Khan, 0.2)');
  });

  test('dismissal text reads as a scorecard line', () {
    MatchWicket w(String kind) => MatchWicket(
          wicketId: 'w',
          deliveryId: 'd',
          inningsId: 'i',
          playerOutId: 'p1',
          dismissalKind: kind,
          isBowlerCredited: true,
          creditedBowlerId: 'b1',
          primaryFielderId: 'p3',
          fallOfWicketScore: 10,
          fallOfWicketNumber: 1,
          fallOfWicketOvers: 1.1,
          createdAt: DateTime(2026),
        );
    String textFor(String kind) => build(
          [ball(seq: 1, over: 0, ballInOver: 1, wicket: true)],
          wickets: [w(kind)],
        ).batting.firstWhere((b) => b.playerId == 'p1').dismissal;

    expect(textFor('bowled'), 'b Kamran Shah');
    expect(textFor('caught'), 'c Usman Tariq b Kamran Shah');
    expect(textFor('lbw'), 'lbw b Kamran Shah');
    expect(textFor('stumped'), 'st Usman Tariq b Kamran Shah');
    expect(textFor('caught_and_bowled'), 'c & b Kamran Shah');
    expect(textFor('retired_hurt'), 'retired hurt');
  });

  test('an undismissed batter is not out, and the tail did not bat', () {
    final card = build([ball(seq: 1, over: 0, ballInOver: 1, runs: 3)]);
    expect(card.batting.firstWhere((b) => b.playerId == 'p1').isOut, isFalse);
    expect(card.batting.firstWhere((b) => b.playerId == 'p1').dismissal,
        'not out');
    // p3 is on the batting side and never came in; the bowler is not.
    expect(card.didNotBat, ['Usman Tariq']);
  });

  test('partnerships split at each wicket and the last one is unbroken', () {
    final wickets = [
      MatchWicket(
        wicketId: 'w1',
        deliveryId: 'b3',
        inningsId: 'i1',
        playerOutId: 'p1',
        dismissalKind: 'bowled',
        isBowlerCredited: true,
        creditedBowlerId: 'b1',
        fallOfWicketScore: 8,
        fallOfWicketNumber: 1,
        fallOfWicketOvers: 0.3,
        createdAt: DateTime(2026),
      ),
    ];
    final card = build([
      ball(seq: 1, over: 0, ballInOver: 1, runs: 4),
      ball(seq: 2, over: 0, ballInOver: 2, runs: 4),
      ball(seq: 3, over: 0, ballInOver: 3, wicket: true),
      ball(seq: 4, over: 0, ballInOver: 4, striker: 'p3', runs: 6),
    ], wickets: wickets);

    expect(card.partnerships, hasLength(2));
    expect(card.partnerships.first.runs, 8);
    expect(card.partnerships.first.startedAtScore, 0);
    expect(card.partnerships.first.unbroken, isFalse);
    expect(card.partnerships.last.runs, 6);
    expect(card.partnerships.last.startedAtScore, 8);
    expect(card.partnerships.last.unbroken, isTrue,
        reason: 'nobody got them out');
  });

  test('runs per over drives the Manhattan, including empty overs', () {
    final card = build([
      ball(seq: 1, over: 0, ballInOver: 1, runs: 6),
      // over 1 is a maiden — it must still occupy a bar
      for (var i = 1; i <= 6; i++) ball(seq: 1 + i, over: 1, ballInOver: i),
      ball(seq: 8, over: 2, ballInOver: 1, runs: 2),
    ]);
    expect(card.runsPerOver, [6, 0, 2]);
  });

  test('an empty ledger yields an empty card rather than throwing', () {
    final card = build(const []);
    expect(card.totalRuns, 0);
    expect(card.batting, isEmpty);
    expect(card.bowling, isEmpty);
    expect(card.partnerships, isEmpty);
    expect(card.runsPerOver, isEmpty);
    expect(card.oversLabel, '0.0');
  });
}
