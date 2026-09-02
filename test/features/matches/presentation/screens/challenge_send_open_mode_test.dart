import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matchday/features/matches/domain/entities/format_preset.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/screens/challenge_send_screen.dart';

/// Entering the wizard from a pool surface (My challenges → New challenge)
/// already answers the open-vs-direct question, so the opponent step must not
/// appear at all — not appear pre-answered.
void main() {
  final presets = [
    const FormatPreset(
      id: 'p-t20',
      label: 'T20',
      format: MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        maxOversPerBowler: 4,
        ballType: MatchBallType.tape,
      ),
    ),
  ];

  Future<void> pump(WidgetTester tester, {required bool openOnly}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          formatPresetsProvider.overrideWith((ref) async => presets),
        ],
        child: MaterialApp(
          home: ChallengeSendScreen(
            // A preselected team drops the team step, so step 1 is the fork
            // (or, when openOnly, whatever follows it).
            fromTeamId: 'team-a',
            openOnly: openOnly,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('open mode drops the fork and shortens the wizard',
      (tester) async {
    await pump(tester, openOnly: true);

    expect(find.text('How should teams find this match?'), findsNothing);
    expect(find.text('Open challenge'), findsNothing);
    expect(find.text('Direct challenge'), findsNothing);

    // The fork drops out, so the counter must shrink with it.
    expect(find.text('STEP 1 / 3'), findsOneWidget);
    expect(find.text('Match format'), findsOneWidget);
  });

  testWidgets('the generic entry still asks the question', (tester) async {
    await pump(tester, openOnly: false);

    expect(find.text('How should teams find this match?'), findsOneWidget);
    expect(find.text('Open challenge'), findsOneWidget);
    expect(find.text('Direct challenge'), findsOneWidget);
    expect(find.text('STEP 1 / 4'), findsOneWidget);
  });

  testWidgets('?mode=open survives a real navigation to the route',
      (tester) async {
    // Mirrors app_router's definition, so a change to how the route reads the
    // query param fails here rather than silently reverting the flow to a
    // direct challenge.
    final router = GoRouter(
      initialLocation: '/matches/send-challenge?mode=open',
      routes: [
        GoRoute(
          path: '/matches/send-challenge',
          builder: (_, state) => ChallengeSendScreen(
            fromTeamId: 'team-a',
            openOnly: state.uri.queryParameters['mode'] == 'open',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          formatPresetsProvider.overrideWith((ref) async => presets),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('How should teams find this match?'), findsNothing);
    expect(find.text('STEP 1 / 3'), findsOneWidget);
  });

  testWidgets('posting a challenge never asks for an XI', (tester) async {
    // Scheduling and team selection are decoupled: a friendly or open
    // challenge settles when/where/format only, and the XI is picked at the
    // ground on the match-start lineup screen. Committing a squad here would
    // freeze it days early and make every late change a re-post.
    for (final open in [true, false]) {
      await pump(tester, openOnly: open);

      expect(find.text('Pick your XI'), findsNothing);
      expect(find.textContaining('SELECTED ·'), findsNothing);
      expect(find.textContaining('BENCH'), findsNothing);
    }
  });
}
