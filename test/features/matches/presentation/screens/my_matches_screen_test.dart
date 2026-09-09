import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match_request.dart';
import 'package:matchday/features/matches/domain/entities/match_role.dart';
import 'package:matchday/features/matches/presentation/providers/challenges_providers.dart';
import 'package:matchday/features/matches/presentation/providers/my_matches_providers.dart';
import 'package:matchday/features/matches/presentation/screens/my_matches_screen.dart';
import 'package:matchday/features/matches/presentation/state/challenges_view.dart';
import 'package:matchday/features/matches/presentation/state/my_matches_view.dart';
import 'package:matchday/features/matches/presentation/widgets/my_matches/fixture_card.dart';
import 'package:matchday/features/matches/presentation/widgets/my_matches/past_card.dart';

/// Builds My Matches in every state `My Matches.dc.html` specifies.
///
/// This suite exists because the Challenges screen shipped three crashes and a
/// typography bug that neither `flutter analyze` nor content assertions could
/// see — a negative Container margin, a borderRadius on a mixed-colour Border,
/// and two RenderFlex overflows. All four only surface when the widget is
/// actually built at the real viewport.
void main() {
  MyMatchConfirmed fixture({
    required String id,
    DateTime? at,
    bool tossReady = false,
    String? liveState,
    String role = '',
    bool roleIsDuty = false,
    bool tbc = false,
  }) =>
      MyMatchConfirmed(
        id: id,
        tag: 'Friendly',
        homeTeamId: 'a',
        awayTeamId: 'b',
        oversPerInnings: 20,
        ballsPerOver: 6,
        homeShort: 'LL',
        homeColor: const Color(0xFF7A2E2E),
        homeName: 'Lahore Lions',
        awayShort: 'SR',
        awayColor: const Color(0xFF3A4A6B),
        awayName: tbc ? 'Winner of Semi-final 2' : 'Shalimar Riders',
        when: 'Sat 12 Sep',
        venue: 'Gaddafi B',
        role: role,
        roleKind: MatchRoleKind.captain,
        countdown: 'In 5h 40m',
        urgent: false,
        tossReady: tossReady,
        live: liveState != null,
        helper: tossReady ? 'Both captains are here. Flip the coin together.' : null,
        startTime: at ?? DateTime.now().add(const Duration(hours: 5)),
        metaLine: 'Friendly · Gaddafi B · 20 ov',
        roleIsDuty: roleIsDuty,
        liveState: liveState,
        liveSince: liveState == null ? null : 'Started 4:30',
        opponentTbc: tbc,
        tbcNote: tbc ? 'Opponent decided Fri 18 Sep' : null,
      );

  MyMatchPast past({required String id, required String result}) => MyMatchPast(
        id: id,
        tag: 'Friendly',
        when: 'Sun 6 Sep',
        homeShort: 'LL',
        homeColor: const Color(0xFF7A2E2E),
        homeName: 'Lahore Lions',
        homeRuns: 165,
        homeWkts: 7,
        awayShort: 'SR',
        awayColor: const Color(0xFF3A4A6B),
        awayName: 'Shalimar Riders',
        awayRuns: 141,
        awayWkts: 9,
        homeWon: result == 'Won',
        result: result,
        mine: '',
        startTime: DateTime.now().subtract(const Duration(days: 3)),
        sentence: result == 'Won' ? 'Lions won by 24 runs' : 'Match ended',
        metaLine: 'Friendly · Gaddafi B · T20',
        homeOvers: '16.0',
        awayOvers: '16.0',
        showScores: result != 'Walkover',
        note: result == 'Walkover'
            ? 'Opposition did not arrive · no overs bowled'
            : null,
      );

  Future<void> pump(
    WidgetTester tester,
    AsyncValue<MyMatchesView> value, {
    List<ChallengeRow> challenges = const [],
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        // Riverpod 3 retries a failed provider, so an errored one bounces back
        // to AsyncLoading and `when(error:)` never fires under test.
        retry: (_, __) => null,
        overrides: [
          myMatchesViewProvider.overrideWith((ref) async {
            if (value is AsyncError) throw value.error!;
            if (value is AsyncLoading) return Completer<MyMatchesView>().future;
            return value.requireValue;
          }),
          challengesViewProvider.overrideWith(
            (ref) async => ChallengesView(needsYou: challenges, waitingOnThem: const []),
          ),
        ],
        child: const MaterialApp(home: MyMatchesScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
  }

  testWidgets('loading keeps chrome, skeletons rows, shows no spinner',
      (tester) async {
    await pump(tester, const AsyncLoading());
    expect(find.text('My Matches'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first run suppresses the tabs entirely', (tester) async {
    await pump(tester, const AsyncData(MyMatchesView.empty()));
    expect(find.text('No matches yet.'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed renders the full escalation ladder', (tester) async {
    // Noon today. Grouping is by calendar day, so the wall-clock time the
    // suite happens to run at must not change the label.
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day, 12);
    await pump(
      tester,
      AsyncData(MyMatchesView(
        confirmed: [
          fixture(id: 'toss', at: today, tossReady: true),
          fixture(
            id: 'live',
            at: today,
            liveState: 'LIVE',
            role: 'Scorer · score live',
            roleIsDuty: true,
          ),
          fixture(
            id: 'calm',
            at: DateTime.now().add(const Duration(days: 4)),
            role: 'Squad member',
          ),
        ],
        past: const [],
        totalPastCount: 0,
        pendingRequestsCount: 0,
        sent: const [],
      )),
    );

    expect(find.byType(FixtureCard), findsNWidgets(3));
    // Toss rung: red label + ink action, never a red button.
    expect(find.text('TOSS'), findsOneWidget);
    expect(find.text('START MATCH · TOSS →'), findsOneWidget);
    // Live rung: the gutter clock is replaced, the card is otherwise untouched.
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Started 4:30'), findsOneWidget);
    // Relative date prefix only for today/tomorrow.
    // Relative prefix only for the two days a person plans in words.
    expect(
      find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').startsWith('TODAY · ')),
      findsOneWidget,
    );
    // Duties take the arrow, states do not.
    expect(find.text('SCORER · SCORE LIVE'), findsOneWidget);
    expect(find.text('SQUAD MEMBER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('past renders the result sentence and a walkover without scores',
      (tester) async {
    await pump(
      tester,
      AsyncData(MyMatchesView(
        confirmed: const [],
        past: [past(id: 'w', result: 'Won'), past(id: 'wo', result: 'Walkover')],
        totalPastCount: 9,
        pendingRequestsCount: 0,
        sent: const [],
      )),
    );

    await tester.tap(find.text('PAST'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byType(PastCard), findsNWidgets(2));
    // The sentence is the hero, the chip only summarises it.
    expect(find.text('Lions won by 24 runs'), findsOneWidget);
    expect(find.text('WON'), findsOneWidget);
    // A walkover was never bowled, so it prints the reason, not 0/0.
    expect(find.text('OPPOSITION DID NOT ARRIVE · NO OVERS BOWLED'),
        findsOneWidget);
    // Windowed footer.
    expect(find.text('SEE ALL 9 MATCHES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  ChallengeRow ch(Duration d) => ChallengeRow(
        requestId: 'c',
        isInbound: true,
        canWithdraw: false,
        opponentName: 'Shalimar Riders',
        opponentShort: 'SR',
        opponentColor: const Color(0xFF3A4A6B),
        status: MatchRequestStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(d),
        whenLabel: '',
        metaLabel: '',
      );

  MyMatchesView oneFixture() => MyMatchesView(
        confirmed: [fixture(id: 'a')],
        past: const [],
        totalPastCount: 0,
        pendingRequestsCount: 0,
        sent: const [],
      );

  testWidgets('a calm challenge queue puts no cream slab on the schedule',
      (tester) async {
    await pump(tester, AsyncData(oneFixture()),
        challenges: [ch(const Duration(hours: 30))]);
    expect(find.textContaining('NEED YOU'), findsNothing);
    expect(find.textContaining('NEEDS YOU'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a challenge inside 6h raises the banner', (tester) async {
    await pump(tester, AsyncData(oneFixture()),
        challenges: [ch(const Duration(hours: 2))]);
    expect(find.textContaining('CHALLENGE NEEDS YOU'), findsOneWidget);
    expect(find.textContaining('EXPIRES IN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error is ink, not red, and offers a retry', (tester) async {
    await pump(tester, AsyncError(Exception('boom'), StackTrace.empty));
    expect(find.text("Couldn't load your matches."), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mono labels use em letter-spacing, not pre-multiplied pixels',
      (tester) async {
    await pump(
      tester,
      AsyncData(MyMatchesView(
        confirmed: [fixture(id: 'a', role: 'Captain · pick XI', roleIsDuty: true)],
        past: const [],
        totalPastCount: 0,
        pendingRequestsCount: 0,
        sent: const [],
      )),
    );
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
