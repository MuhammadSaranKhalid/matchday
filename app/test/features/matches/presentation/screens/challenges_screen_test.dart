import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/widgets/v2/ck_shimmer.dart';
import 'package:matchday/features/matches/domain/entities/match_request.dart';
import 'package:matchday/features/matches/presentation/providers/challenges_providers.dart';
import 'package:matchday/features/matches/presentation/screens/challenges_screen.dart';
import 'package:matchday/features/matches/presentation/state/challenges_view.dart';
import 'package:matchday/features/matches/presentation/widgets/challenges/challenge_card.dart';

/// Builds ChallengesScreen in every state it can reach.
///
/// This suite exists because the screen shipped with a crash that neither
/// `flutter analyze` nor any unit test could see: the design's
/// `margin-left:-4px` was transliterated into `EdgeInsets.only(left: -4)`, and
/// Flutter's Container asserts `margin.isNonNegative`. It only failed when the
/// widget was actually built. Analysis cannot catch a build-time assertion —
/// only pumping the widget can.
void main() {
  ChallengeRow row({
    required String id,
    required bool inbound,
    required Duration expiresIn,
    MatchRequestStatus status = MatchRequestStatus.pending,
    bool canWithdraw = false,
    String? message,
    bool countered = false,
  }) =>
      ChallengeRow(
        requestId: id,
        isInbound: inbound,
        canWithdraw: canWithdraw,
        opponentName: 'Shalimar Riders',
        opponentShort: 'SR',
        opponentColor: const Color(0xFF3A4A6B),
        status: status,
        createdAt: DateTime.now().subtract(const Duration(hours: 46)),
        // +1min so the label does not truncate down a unit between
        // constructing the fixture and building the frame.
        expiresAt: DateTime.now().add(expiresIn + const Duration(minutes: 1)),
        whenLabel: 'Sat 12 Sep · 4:30 PM',
        metaLabel: 'Gaddafi Ground B · 20 ov · 11-a-side',
        message: message,
        supersededLabel: countered ? 'Sun 13 Sep · 3:00 PM · Nishat Park' : null,
        counterLabel: countered ? 'Sun 13 Sep · 8:00 AM · Ravi Ground 2' : null,
      );

  Future<void> pump(WidgetTester tester, AsyncValue<ChallengesView> value) async {
    // The design is drawn at 393×852. The default 800×600 test surface is both
    // too narrow and too short, which lazily drops trailing list rows.
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        // Riverpod 3 retries a failed provider with backoff, so an errored
        // provider bounces straight back to AsyncLoading (with the error
        // attached) and `when(error:)` never fires under test. Disable retry
        // here so the error branch is reachable. In the real app the retry is
        // desirable — a failed challenges fetch heals itself.
        retry: (_, __) => null,
        overrides: [
          challengesViewProvider.overrideWith((ref) async {
            if (value is AsyncError) throw value.error!;
            if (value is AsyncLoading) {
              // Never completes — holds the screen in its loading state.
              return Completer<ChallengesView>().future;
            }
            return value.requireValue;
          }),
        ],
        child: const MaterialApp(home: ChallengesScreen()),
      ),
    );
    // One frame for loading; settle for the rest. The urgent row runs a
    // repeating pulse, so pumpAndSettle would spin forever — pump twice.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('loading keeps the chrome real and skeletons only counts + rows',
      (tester) async {
    await pump(tester, const AsyncLoading());

    // "Chrome is real from the first frame" — the title and both tab labels
    // are the actual text, not placeholders, so returning from a detail screen
    // never blanks the page.
    expect(find.text('Challenges'), findsOneWidget);
    expect(find.text('NEEDS YOU'), findsOneWidget);
    expect(find.text('WAITING ON THEM'), findsOneWidget);

    // No spinner anywhere — the skeleton IS the loading affordance.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Three cards fading back, and only the first one animates.
    expect(find.byType(CkShimmer), findsNWidgets(3)); // header bar + crest + name
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-run empty suppresses the tabs', (tester) async {
    await pump(tester, const AsyncData(ChallengesView.empty()));
    expect(find.text('No challenges yet.'), findsOneWidget);
    // Two empty tabs is a filing cabinet with no files.
    expect(find.text('NEEDS YOU'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('needs-you renders every expiry tier and the countered ledger',
      (tester) async {
    await pump(
      tester,
      AsyncData(ChallengesView(
        needsYou: [
          row(
            id: 'urgent',
            inbound: true,
            expiresIn: const Duration(hours: 2, minutes: 10),
            message: 'Openers back from Karachi — up for a proper game?',
          ),
          row(
            id: 'countered',
            inbound: true,
            expiresIn: const Duration(hours: 9),
            status: MatchRequestStatus.countered,
            countered: true,
          ),
          row(id: 'calm', inbound: true, expiresIn: const Duration(hours: 41)),
        ],
        waitingOnThem: const [],
      )),
    );

    expect(find.byType(ChallengeCard), findsNWidgets(3));
    // Urgent tier counts down in minutes; calm tier says "Expires Nh".
    expect(find.text('2h 10m'), findsOneWidget);
    expect(find.text('9h'), findsOneWidget);
    expect(find.text('Expires 41h'), findsOneWidget);
    // The ledger names the actor so one component works in either tab.
    expect(find.text('Countered'), findsOneWidget);
    expect(find.text('THEY PROPOSED'), findsOneWidget);
    expect(find.text('YOU PROPOSED'), findsOneWidget);
    // The header's red clause appears only because one row is urgent.
    expect(find.text('1 EXPIRING SOON'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waiting tab offers Withdraw only on challenges I sent',
      (tester) async {
    await pump(
      tester,
      AsyncData(ChallengesView(
        needsYou: const [],
        waitingOnThem: [
          row(
            id: 'mine',
            inbound: false,
            expiresIn: const Duration(hours: 20),
            canWithdraw: true,
          ),
          // I countered THEIR challenge: cancel_match_request enforces
          // is_team_manager(from_team_id), so Withdraw would be refused.
          row(
            id: 'my-counter',
            inbound: false,
            expiresIn: const Duration(hours: 12),
            status: MatchRequestStatus.countered,
            countered: true,
          ),
        ],
      )),
    );

    await tester.tap(find.text('WAITING ON THEM'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('WITHDRAW'), findsOneWidget);
    expect(find.text('THEIR MOVE — YOUR COUNTER IS WITH THEM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error state renders a retry, not an alarm', (tester) async {
    await pump(tester, AsyncError(Exception('boom'), StackTrace.empty));
    expect(find.text("Couldn't load your challenges."), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mono labels use em letter-spacing, not pre-multiplied pixels',
      (tester) async {
    // CkType.mono/display take letterSpacing as an EM MULTIPLE and multiply by
    // fontSize internally. This screen originally passed the already-multiplied
    // pixel value (`0.08 * 11`), which came out ~10x too wide on device and
    // collapsed the 26px title into an unreadable blob at -0.52em.
    //
    // Text-content assertions cannot see that — every other test in this file
    // passed while the screen was visibly broken. This one checks the resolved
    // style instead.
    await pump(
      tester,
      AsyncData(ChallengesView(
        needsYou: [
          row(id: 'calm', inbound: true, expiresIn: const Duration(hours: 41)),
        ],
        waitingOnThem: const [],
      )),
    );

    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      final ls = t.style?.letterSpacing;
      final fs = t.style?.fontSize;
      if (ls == null || fs == null) continue;
      // Sane tracking is well under a fifth of the font size in either
      // direction. 0.08em on an 11px label is 0.88px; the bug produced 9.7px.
      expect(
        ls.abs(),
        lessThan(fs * 0.2),
        reason: 'letterSpacing ${ls}px on a ${fs}px "${t.data}" is out of range '
            '— CkType multiplies by fontSize, so pass the em value',
      );
    }
  });
}
