import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_format.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_when_where.dart';
import 'package:matchday/features/matches/presentation/widgets/wizard/step_open_or_direct.dart';
import 'package:matchday/features/matches/presentation/widgets/wizard/wizard_kit.dart';

/// Covers the posting wizard — `Pool.dc.html` section B (artboards 06–10).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: child)),
      );

  group('StepOpenOrDirect (artboard 06)', () {
    testWidgets('open is the recommended path and shows no team list',
        (tester) async {
      await pump(
        tester,
        StepOpenOrDirect(
          isOpen: true,
          onSelect: (_) {},
          directContent: const Text('THE PICKER'),
        ),
      );

      expect(find.text('How should teams find this match?'), findsOneWidget);
      expect(find.text('Open challenge'), findsOneWidget);
      expect(find.text('Direct challenge'), findsOneWidget);
      expect(find.text('RECOMMENDED · YOU CHOOSE WHO PLAYS'), findsOneWidget);

      // The picker belongs to the Direct branch only.
      expect(find.text('THE PICKER'), findsNothing);
    });

    testWidgets('choosing direct unfolds the picker under the card',
        (tester) async {
      await pump(
        tester,
        StepOpenOrDirect(
          isOpen: false,
          onSelect: (_) {},
          directContent: const Text('THE PICKER'),
        ),
      );

      expect(find.text('THE PICKER'), findsOneWidget);
    });

    testWidgets('reports the fork', (tester) async {
      bool? chose;
      await pump(
        tester,
        StepOpenOrDirect(isOpen: true, onSelect: (v) => chose = v),
      );

      await tester.tap(find.text('Direct challenge'));
      await tester.pump();
      expect(chose, isFalse);
    });
  });

  group('StepFormat (artboard 07)', () {
    testWidgets('asks the questions and previews the card line',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pump(
        tester,
        StepFormat(
          presets: const [],
          selectedPreset: null,
          format: const MatchFormat(
            formatCode: 'custom',
            oversPerInnings: 12,
            playersPerTeam: 11,
            ballType: MatchBallType.tape,
            maxOversPerBowler: 3,
          ),
          isCustom: true,
          onSelectPreset: (_) {},
          onSelectCustom: () {},
          onBall: (_) {},
          onPlayers: (_) {},
          onCustomizeFormat: ({ballsPerOver, maxBowler, overs, wickets}) {},
        ),
      );

      expect(find.text('Match format'), findsOneWidget);
      expect(find.text('OVERS PER INNINGS'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Tape-ball'), findsWidgets);
      expect(find.text('ON THE CARD'), findsOneWidget);
      expect(find.text('12 OVERS · TAPE-BALL · 11-A-SIDE'), findsOneWidget);
    });

    testWidgets('the stepper walks the overs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final seen = <int>[];
      await pump(
        tester,
        StepFormat(
          presets: const [],
          selectedPreset: null,
          format: const MatchFormat(
            formatCode: 'custom',
            oversPerInnings: 12,
            playersPerTeam: 11,
            ballType: MatchBallType.tape,
            maxOversPerBowler: 3,
          ),
          isCustom: true,
          onSelectPreset: (_) {},
          onSelectCustom: () {},
          onBall: (_) {},
          onPlayers: (_) {},
          onCustomizeFormat: ({ballsPerOver, maxBowler, overs, wickets}) {
            if (overs != null) seen.add(overs);
          },
        ),
      );

      await tester.tap(find.text('+').first);
      await tester.pump();
      await tester.tap(find.text('−').first);
      await tester.pump();
      expect(seen, [13, 11]);
    });

    test('the spec line is built in one place', () {
      expect(
        formatSpecLine(
          overs: 16,
          ball: MatchBallType.leather,
          playersPerSide: 8,
        ),
        '16 overs · Leather · 8-a-side',
      );
    });
  });

  group('StepWhenWhere (artboard 08)', () {
    testWidgets('venue is optional and flexible replaces the time',
        (tester) async {
      final venue = TextEditingController();
      addTearDown(venue.dispose);

      await pump(
        tester,
        StepWhenWhere(
          day: DateTime.now(),
          time: 16 * 60 + 30,
          flexible: false,
          venueController: venue,
          onDay: (_) {},
          onTime: (_) {},
          onFlexible: (_) {},
        ),
      );

      expect(find.text('When & where'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('4:30 PM'), findsOneWidget);
      expect(find.text('optional'), findsOneWidget);
      expect(
        find.textContaining("agree the ground with your opponent later"),
        findsOneWidget,
      );
    });

    testWidgets('flexible hides the committed time', (tester) async {
      final venue = TextEditingController();
      addTearDown(venue.dispose);

      await pump(
        tester,
        StepWhenWhere(
          day: DateTime.now(),
          time: 16 * 60 + 30,
          flexible: true,
          venueController: venue,
          onDay: (_) {},
          onTime: (_) {},
          onFlexible: (_) {},
        ),
      );

      expect(find.text('4:30 PM'), findsNothing);
      expect(find.text('Flexible'), findsOneWidget);
    });

    test('clock labels read as 12-hour', () {
      expect(clockLabel(0), '12:00 AM');
      expect(clockLabel(12 * 60), '12:00 PM');
      expect(clockLabel(16 * 60 + 30), '4:30 PM');
    });
  });

  group('WizardProgress', () {
    testWidgets('fills up to and including the current step', (tester) async {
      await pump(tester, const WizardProgress(index: 2, total: 6));
      expect(find.byType(Container), findsNWidgets(7)); // 6 rules + the bar
    });
  });
}
