import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/teams/presentation/widgets/team_page/tp_options_sheet.dart';
import 'package:matchday/features/teams/presentation/widgets/team_page/tp_view.dart';

TpTeam _team({String? archived}) => TpTeam(
      name: 'Lahore Lions',
      mono: 'LL',
      type: 'club',
      city: 'Lahore',
      area: 'Model Town',
      primary: const Color(0xFF1E5A2C),
      privacy: 'public',
      archived: archived,
    );

/// Opens the sheet the way the hero's ⋯ button does and settles it.
Future<void> _openSheet(
  WidgetTester tester, {
  required TeamPageViewer viewer,
  String? archived,
  String? membershipId,
}) async {
  // Tear the previous tree down first: a sheet left open from an earlier
  // iteration keeps its modal barrier over the trigger.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildCirckTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTeamOptionsSheet(
                context,
                teamId: 't1',
                team: _team(archived: archived),
                viewer: viewer,
                viewerMembershipId: membershipId,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('⋯ sheet role variants', () {
    testWidgets('every role can share and copy the link', (tester) async {
      for (final viewer in TeamPageViewer.values) {
        await _openSheet(tester, viewer: viewer);
        expect(find.text('Share team'), findsOneWidget, reason: '$viewer');
        expect(find.text('Copy link'), findsOneWidget, reason: '$viewer');
        // The header names what the sheet acts on.
        expect(find.text('Lahore Lions'), findsOneWidget, reason: '$viewer');
      }
    });

    testWidgets('owner gets settings and archive', (tester) async {
      await _openSheet(tester, viewer: TeamPageViewer.owner);

      expect(find.text('Edit team'), findsOneWidget);
      expect(find.text('Invite players'), findsOneWidget);
      expect(find.text('Team settings'), findsOneWidget);
      expect(find.text('Archive team'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
    });

    testWidgets('captain edits the team but cannot end it', (tester) async {
      await _openSheet(tester, viewer: TeamPageViewer.captain);

      expect(find.text('Edit team'), findsOneWidget);
      expect(find.text('Invite players'), findsOneWidget);
      // Only the owner can archive or reach settings.
      expect(find.text('Team settings'), findsNothing);
      expect(find.text('Archive team'), findsNothing);
    });

    testWidgets('a player can leave, and the row is destructive', (tester) async {
      await _openSheet(
        tester,
        viewer: TeamPageViewer.player,
        membershipId: 'm1',
      );

      final leave = find.text('Leave team');
      expect(leave, findsOneWidget);
      expect(tester.widget<Text>(leave).style?.color, CkColors.red);
      expect(find.text('Archive team'), findsNothing);
    });

    testWidgets('a player with no membership id gets no leave row',
        (tester) async {
      // Nothing to pass to leave_team(), so the row would fail on tap.
      await _openSheet(tester, viewer: TeamPageViewer.player);
      expect(find.text('Leave team'), findsNothing);
    });

    testWidgets('strangers are offered the join request', (tester) async {
      await _openSheet(tester, viewer: TeamPageViewer.stranger);
      expect(find.text('Request to join'), findsOneWidget);
      expect(find.text('The owner approves requests'), findsOneWidget);
    });

    testWidgets('a private team says what stays hidden', (tester) async {
      await _openSheet(tester, viewer: TeamPageViewer.strangerPrivate);
      expect(find.text('Request to join'), findsOneWidget);
      expect(
        find.text('Squad and stats stay hidden until you’re in'),
        findsOneWidget,
      );
      expect(find.text('PRIVATE'), findsOneWidget);
    });
  });

  group('archived teams', () {
    testWidgets('suppress every action but the owner\'s way back',
        (tester) async {
      await _openSheet(
        tester,
        viewer: TeamPageViewer.owner,
        archived: '14 Aug 2026',
      );

      expect(find.text('Restore team'), findsOneWidget);
      // Hidden, not disabled.
      expect(find.text('Archive team'), findsNothing);
      expect(find.text('Edit team'), findsNothing);
      expect(find.text('Team settings'), findsNothing);
      expect(find.text('ARCHIVED'), findsOneWidget);
    });

    testWidgets('a non-owner cannot restore', (tester) async {
      await _openSheet(
        tester,
        viewer: TeamPageViewer.player,
        archived: '14 Aug 2026',
        membershipId: 'm1',
      );

      expect(find.text('Restore team'), findsNothing);
      expect(find.text('Leave team'), findsNothing);
      expect(find.text('Share team'), findsOneWidget);
    });
  });
}
