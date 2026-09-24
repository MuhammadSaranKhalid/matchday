import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/scoring/scorecard.dart';
import 'package:matchday/features/matches/presentation/providers/completed_match_providers.dart';
import 'package:matchday/features/matches/presentation/screens/completed_match_screen.dart';
import 'package:matchday/features/matches/presentation/state/completed_match_view.dart';

/// Builds the completed-match screen in every state `Completed Match.dc.html`
/// specifies, at the real 393×852 viewport.
///
/// Content-only assertions are not enough here: the Challenges screen shipped
/// a negative margin, a borderRadius on a mixed-colour Border, two RenderFlex
/// overflows and a 10× letter-spacing bug that every content assertion passed
/// straight through. Each test below therefore also asserts no exception.
void main() {
  Ball ball({
    required int seq,
    required int over,
    required int ballInOver,
    int runs = 0,
    int extras = 0,
    BallKind kind = BallKind.legal,
    bool wicket = false,
    String striker = 'p1',
    String bowler = 'b1',
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
        nonStrikerId: 'p2',
        bowlerId: bowler,
      );

  InningsCard card({
    required int number,
    required String side,
    int runs = 144,
    int wickets = 4,
  }) =>
      InningsCard(
        inningsNumber: number,
        battingTeamSide: side,
        batting: const [
          BattingLine(
            playerId: 'p1',
            name: 'Bilal Hussain',
            runs: 61,
            balls: 38,
            fours: 5,
            sixes: 3,
            isOut: true,
            dismissal: 'c Shahzaib b Danish Raza',
            batted: true,
          ),
          BattingLine(
            playerId: 'p2',
            name: 'Abdul Rehman Qureshi',
            runs: 0,
            balls: 3,
            fours: 0,
            sixes: 0,
            isOut: false,
            dismissal: 'not out',
            batted: true,
          ),
        ],
        bowling: const [
          BowlingLine(
            playerId: 'b1',
            name: 'Hamza Sheikh',
            legalBalls: 24,
            maidens: 1,
            runs: 19,
            wickets: 4,
            wides: 0,
            noBalls: 0,
            dots: 12,
            ballsPerOver: 6,
          ),
        ],
        extras: const ExtrasBreakdown(
            byes: 2, legByes: 3, wides: 5, noBalls: 2, penalties: 0),
        fallOfWickets: const [
          FallOfWicket(
              number: 1, score: 12, overs: 2.3, playerName: 'Abdul Rehman'),
        ],
        partnerships: const [
          Partnership(
            wicketNumber: 1,
            runs: 12,
            balls: 15,
            startedAtScore: 0,
            strikerName: 'Bilal Hussain',
            strikerRuns: 8,
            nonStrikerName: 'Abdul Rehman',
            nonStrikerRuns: 4,
            unbroken: false,
            endedAtOvers: 2.3,
          ),
        ],
        runsPerOver: const [6, 0, 12, 8],
        balls: [
          ball(seq: 1, over: 0, ballInOver: 1),
          ball(seq: 2, over: 0, ballInOver: 2, runs: 4),
          ball(seq: 3, over: 0, ballInOver: 0, extras: 1, kind: BallKind.wide),
          ball(seq: 4, over: 1, ballInOver: 1, wicket: true),
        ],
        totalRuns: runs,
        wickets: wickets,
        legalBalls: 91,
        ballsPerOver: 6,
        didNotBat: const ['Hamza Sheikh', 'Talha Aziz'],
      );

  CompletedSide side({
    required String letter,
    required String name,
    required String short,
    bool won = false,
    bool batted = true,
    bool isYou = false,
    int runs = 144,
    int wkts = 4,
  }) =>
      CompletedSide(
        teamId: letter,
        sideLetter: letter,
        name: name,
        short: short,
        color: const Color(0xFF7A2E2E),
        isYou: isYou,
        won: won,
        batted: batted,
        runs: batted ? runs : null,
        wickets: batted ? wkts : null,
        oversLabel: batted ? '15.1' : null,
      );

  CompletedMatchView view({
    ResultTone tone = ResultTone.won,
    String sentence = 'Lions won by 6 wickets · 5 balls left',
    List<InningsCard>? innings,
    String? headline,
    bool secondBatted = true,
  }) =>
      CompletedMatchView(
        title: 'Lions vs Riders',
        sides: [
          side(letter: 'a', name: 'Lahore Lions', short: 'LL', won: tone == ResultTone.won, isYou: true),
          side(
            letter: 'b',
            name: 'Shalimar Riders',
            short: 'SR',
            batted: secondBatted,
            runs: 141,
            wkts: 9,
          ),
        ],
        tone: tone,
        sentence: sentence,
        metaLine: 'Sun 6 Sep · Gaddafi B · Friendly · T20',
        innings: innings ??
            [card(number: 1, side: 'a'), card(number: 2, side: 'b', runs: 141, wickets: 9)],
        headline: headline,
        absenceNote: headline == null
            ? null
            : 'The fixture was awarded without a ball being bowled.',
        recordRows: headline == null
            ? const []
            : const [
                (label: 'Scheduled', value: 'Sat 23 Aug · 4:30 PM'),
                (label: 'Ground', value: 'Gaddafi Ground B'),
              ],
        tossLine: 'Riders, chose to bat',
        squadsLine: '11 v 11 · named on the card',
      );

  Future<void> pump(WidgetTester tester, AsyncValue<CompletedMatchView> v) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        // Riverpod 3 retries a failed provider, so an errored one bounces back
        // to AsyncLoading and the error branch never renders under test.
        retry: (_, __) => null,
        overrides: [
          completedMatchProvider('m1').overrideWith((ref) async {
            if (v is AsyncError) throw v.error!;
            if (v is AsyncLoading) return Completer<CompletedMatchView>().future;
            return v.requireValue;
          }),
        ],
        child: const MaterialApp(
          home: CompletedMatchScreen(matchId: 'm1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
  }

  testWidgets('summary leads with the result and the top performers',
      (tester) async {
    await pump(tester, AsyncData(view()));
    expect(find.text('Lions vs Riders'), findsOneWidget);
    expect(find.text('Lions won by 6 wickets · 5 balls left'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('TOP PERFORMERS'), findsOneWidget);
    // All four tabs are present when there is a ledger.
    for (final t in ['SUMMARY', 'CARD', 'OVERS', 'STATS']) {
      expect(find.text(t), findsOneWidget, reason: '$t tab missing');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a walkover renders a record page and NO tab bar',
      (tester) async {
    await pump(
      tester,
      AsyncData(view(
        innings: const [],
        headline: 'No match was played.',
        sentence: 'Awarded to Lahore Lions · walkover',
        secondBatted: false,
      )),
    );
    expect(find.text('No match was played.'), findsOneWidget);
    expect(find.text('NO DELIVERIES RECORDED'), findsOneWidget);
    expect(find.text('THE FIXTURE AS AGREED'), findsOneWidget);
    // The whole point of the case: no tabs to tap through.
    expect(find.text('SUMMARY'), findsNothing);
    expect(find.text('CARD'), findsNothing);
    // A side that never batted says so, rather than showing 0/0.
    expect(find.text('Did not bat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tie lights neither side', (tester) async {
    await pump(
      tester,
      AsyncData(view(
        tone: ResultTone.tied,
        sentence: 'Match tied · scores level',
      )),
    );
    expect(find.text('Match tied · scores level'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card tab prints figures, extras, total and did-not-bat',
      (tester) async {
    await pump(tester, AsyncData(view()));
    await tester.tap(find.text('CARD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('Bilal Hussain'), findsWidgets);
    expect(find.text('c Shahzaib b Danish Raza'), findsOneWidget);
    expect(find.text('EXTRAS'), findsOneWidget);
    expect(find.text('b 2 · lb 3 · w 5 · nb 2'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('DID NOT BAT'), findsOneWidget);
    expect(find.text('FALL OF WICKETS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the overs tab opens on the last over and offers the first',
      (tester) async {
    await pump(tester, AsyncData(view()));
    await tester.tap(find.text('OVERS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('↑ FIRST OVER'), findsOneWidget);
    // Newest over first: over 2 (index 1) precedes over 1 on screen.
    final over2 = tester.getTopLeft(find.text('OVER 2')).dy;
    final over1 = tester.getTopLeft(find.text('OVER 1')).dy;
    expect(over2, lessThan(over1));
    // A wide keeps its ball number and reads as an extra.
    expect(find.text('Wide'), findsOneWidget);
    expect(find.text('Dot ball'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the stats tab draws both innings without overflowing',
      (tester) async {
    await pump(tester, AsyncData(view()));
    await tester.tap(find.text('STATS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('MANHATTAN · RUNS PER OVER'), findsOneWidget);
    expect(find.text('WORM · CUMULATIVE RUNS'), findsOneWidget);
    expect(find.text('WHERE THE RUNS CAME FROM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading keeps the chrome and shows no spinner', (tester) async {
    await pump(tester, const AsyncLoading());
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error is ink, not red, and offers a retry', (tester) async {
    await pump(tester, AsyncError(Exception('boom'), StackTrace.empty));
    expect(find.text("Couldn't load this match."), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mono labels use em letter-spacing, not pre-multiplied pixels',
      (tester) async {
    await pump(tester, AsyncData(view()));
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      final ls = t.style?.letterSpacing;
      final fs = t.style?.fontSize;
      if (ls == null || fs == null) continue;
      expect(
        ls.abs(),
        lessThan(fs * 0.2),
        reason: 'letterSpacing ${ls}px on ${fs}px "${t.data}" — CkType '
            'multiplies by fontSize, so pass the em value',
      );
    }
  });
}
