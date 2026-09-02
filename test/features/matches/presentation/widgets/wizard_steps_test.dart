import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_format.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_pick_xi.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_when_where.dart';
import 'package:matchday/features/matches/presentation/widgets/wizard/step_open_or_direct.dart';
import 'package:matchday/features/matches/presentation/widgets/wizard/wizard_kit.dart';
import 'package:matchday/features/teams/domain/entities/roster_member.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';

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
    testWidgets('asks the three questions and previews the card line',
        (tester) async {
      await pump(
        tester,
        StepFormat(
          overs: 12,
          ball: MatchBallType.tape,
          playersPerSide: 11,
          onOvers: (_) {},
          onBall: (_) {},
          onPlayers: (_) {},
        ),
      );

      expect(find.text('Match format'), findsOneWidget);
      expect(find.text('OVERS PER INNINGS'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Tape-ball'), findsOneWidget);
      expect(find.text('ON THE CARD'), findsOneWidget);
      expect(find.text('12 OVERS · TAPE-BALL · 11-A-SIDE'), findsOneWidget);
    });

    testWidgets('the stepper walks the overs', (tester) async {
      final seen = <int>[];
      await pump(
        tester,
        StepFormat(
          overs: 12,
          ball: MatchBallType.tape,
          playersPerSide: 11,
          onOvers: seen.add,
          onBall: (_) {},
          onPlayers: (_) {},
        ),
      );

      await tester.tap(find.text('+'));
      await tester.tap(find.text('−'));
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

  group('StepPickXi (artboard 09)', () {
    RosterMember member(String id, String name, MemberRole role) => RosterMember(
          member: TeamMember(
            id: MembershipId('m-$id'),
            teamId: const TeamId('team-a'),
            playerId: id,
            playerType: PlayerType.claimed,
            role: role,
            addedBy: 'user-1',
            joinedAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          displayName: name,
        );

    final roster = [
      member('p1', 'Ahmed Khan', MemberRole.captain),
      member('p2', 'Bilal Aslam', MemberRole.wicketKeeper),
      member('p3', 'Hamza Raza', MemberRole.player),
    ];

    testWidgets('splits the squad into selected and bench', (tester) async {
      await pump(
        tester,
        StepPickXi(
          roster: roster,
          selected: const ['p1', 'p2'],
          captainId: 'p1',
          keeperId: 'p2',
          onToggle: (_) {},
          onCaptain: (_) {},
          onKeeper: (_) {},
        ),
      );

      expect(find.text('SELECTED · 2'), findsOneWidget);
      expect(find.text('BENCH · NOT PLAYING'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('WK'), findsOneWidget);
      // Only selected rows offer the armbands.
      expect(find.text('C · WK'), findsNothing);
    });

    testWidgets('a selected player with no armband offers both',
        (tester) async {
      await pump(
        tester,
        StepPickXi(
          roster: roster,
          selected: const ['p3'],
          captainId: null,
          keeperId: null,
          onToggle: (_) {},
          onCaptain: (_) {},
          onKeeper: (_) {},
        ),
      );

      expect(find.text('C · WK'), findsOneWidget);
    });

    testWidgets('tapping a bench row selects it', (tester) async {
      String? toggled;
      await pump(
        tester,
        StepPickXi(
          roster: roster,
          selected: const [],
          captainId: null,
          keeperId: null,
          onToggle: (id) => toggled = id,
          onCaptain: (_) {},
          onKeeper: (_) {},
        ),
      );

      await tester.tap(find.text('Ahmed Khan'));
      await tester.pump();
      expect(toggled, 'p1');
    });
  });

  group('WizardProgress', () {
    testWidgets('fills up to and including the current step', (tester) async {
      await pump(tester, const WizardProgress(index: 2, total: 6));
      expect(find.byType(Container), findsNWidgets(7)); // 6 rules + the bar
    });
  });
}
