import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/format_preset.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_format.dart';

void main() {
  final testPresets = [
    const FormatPreset(
      id: 'quick_6',
      label: '6 Over',
      format: MatchFormat(
        formatCode: 'quick_6',
        oversPerInnings: 6,
        playersPerTeam: 8,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 2,
      ),
    ),
    const FormatPreset(
      id: 'quick_8',
      label: '8 Over',
      format: MatchFormat(
        formatCode: 'quick_8',
        oversPerInnings: 8,
        playersPerTeam: 8,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 2,
      ),
    ),
    const FormatPreset(
      id: 't10',
      label: 'T10',
      format: MatchFormat(
        formatCode: 't10',
        oversPerInnings: 10,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 2,
      ),
    ),
    const FormatPreset(
      id: 't20',
      label: 'T20',
      format: MatchFormat(
        formatCode: 't20',
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
      ),
    ),
    const FormatPreset(
      id: 'over_50',
      label: '50 Over',
      format: MatchFormat(
        formatCode: 'over_50',
        oversPerInnings: 50,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 10,
      ),
    ),
  ];

  group('FormatPreset helper logic', () {
    test('defaultBowlerLimit derives correct limits', () {
      expect(FormatPreset.defaultBowlerLimit(6), 2);
      expect(FormatPreset.defaultBowlerLimit(8), 2);
      expect(FormatPreset.defaultBowlerLimit(10), 2);
      expect(FormatPreset.defaultBowlerLimit(20), 4);
      expect(FormatPreset.defaultBowlerLimit(30), 6);
      expect(FormatPreset.defaultBowlerLimit(40), 8);
      expect(FormatPreset.defaultBowlerLimit(45), 9);
      expect(FormatPreset.defaultBowlerLimit(50), 10);
    });

    test('formatSpecLine renders ball types and overs correctly', () {
      expect(
        formatSpecLine(
          overs: 20,
          ball: MatchBallType.tape,
          playersPerSide: 11,
        ),
        '20 overs · Tape-ball · 11-a-side',
      );

      expect(
        formatSpecLine(
          overs: 10,
          ball: MatchBallType.tennis,
          playersPerSide: 8,
        ),
        '10 overs · Tennis · 8-a-side',
      );

      expect(
        formatSpecLine(
          overs: 50,
          ball: MatchBallType.leather,
          playersPerSide: 11,
        ),
        '50 overs · Leather · 11-a-side',
      );
    });

    test('formatTitle displays preset name or custom with overs', () {
      expect(
        formatTitle(
          preset: testPresets.firstWhere((p) => p.id == 't20'),
          isCustom: false,
          overs: 20,
        ),
        'T20',
      );

      expect(
        formatTitle(
          preset: null,
          isCustom: true,
          overs: 18,
        ),
        'CUSTOM (18 OVERS)',
      );
    });
  });

  group('StepFormat widget', () {
    testWidgets('renders popular grid, ball types including tennis, and card preview',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FormatPreset? selectedPreset = testPresets.firstWhere((p) => p.id == 't20');
      MatchFormat format = selectedPreset.format;
      bool isCustom = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StepFormat(
                  presets: testPresets,
                  selectedPreset: selectedPreset,
                  format: format,
                  isCustom: isCustom,
                  onSelectPreset: (p) => setState(() {
                    selectedPreset = p;
                    isCustom = false;
                    format = p.format.copyWith(
                      ballType: format.ballType,
                      playersPerTeam: format.playersPerTeam,
                    );
                  }),
                  onSelectCustom: () => setState(() {
                    selectedPreset = null;
                    isCustom = true;
                    format = format.copyWith(formatCode: 'custom');
                  }),
                  onBall: (b) => setState(() {
                    format = format.copyWith(ballType: b);
                  }),
                  onPlayers: (n) => setState(() {
                    format = format.copyWith(playersPerTeam: n);
                  }),
                  onCustomizeFormat: ({ballsPerOver, maxBowler, overs, wickets}) =>
                      setState(() {
                    format = format.copyWith(
                      oversPerInnings: overs ?? format.oversPerInnings,
                      maxOversPerBowler: maxBowler ?? format.maxOversPerBowler,
                    );
                  }),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Heading & section titles
      expect(find.text('Match format'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);
      expect(find.text('T10'), findsOneWidget);
      expect(find.text('T20'), findsWidgets);
      expect(find.text('50 OVER'), findsOneWidget);
      expect(find.text('CUSTOM'), findsOneWidget);

      // Ball types: Tape-ball, Tennis, Leather
      expect(find.text('Tape-ball'), findsWidgets);
      expect(find.text('Tennis'), findsOneWidget);
      expect(find.text('Leather'), findsOneWidget);

      // On the card preview
      expect(find.text('ON THE CARD'), findsOneWidget);
      expect(find.text('20 OVERS · TAPE-BALL · 11-A-SIDE'), findsOneWidget);

      // Tap Tennis ball
      await tester.tap(find.text('Tennis'));
      await tester.pumpAndSettle();
      expect(find.text('20 OVERS · TENNIS · 11-A-SIDE'), findsOneWidget);

      // Tap T10 preset (use .first if title appears in preview as well)
      await tester.tap(find.text('T10').first);
      await tester.pumpAndSettle();
      expect(format.oversPerInnings, 10);
      expect(format.maxOversPerBowler, 2);
      expect(find.text('10 OVERS · TENNIS · 11-A-SIDE'), findsOneWidget);

      // Tap Custom
      await tester.tap(find.text('CUSTOM'));
      await tester.pumpAndSettle();
      expect(isCustom, isTrue);
      expect(find.text('CUSTOM (10 OVERS)'), findsOneWidget);
    });
  });
}
