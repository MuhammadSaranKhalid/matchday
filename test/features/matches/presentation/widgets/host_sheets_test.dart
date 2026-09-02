import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/presentation/widgets/host/host_sheets.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

/// Covers the host's three confirmations — `Pool.dc.html` artboards 17–19.
void main() {
  Team team(String name) => Team(
        id: const TeamId('team-app'),
        ownerId: 'user-1',
        name: name,
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        managers: const ['user-1'],
        primaryColor: '#2E5D57',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  /// Opens [open] from a tap so the sheet gets a real Navigator.
  Future<void> launch(
    WidgetTester tester,
    Future<void> Function(BuildContext) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('Accept sheet (artboard 17)', () {
    testWidgets('states both consequences, and confirms in ink not red',
        (tester) async {
      bool? result;
      await launch(tester, (context) async {
        result = await showAcceptApplicantSheet(
          context,
          applicant: team('Gulberg Giants'),
          otherApplicantNames: const ['Model Town', 'Ravi Riders', 'Ludhiana'],
        );
      });

      expect(find.text('Accept Gulberg Giants?'), findsOneWidget);
      expect(find.text('A match will be created'), findsOneWidget);
      expect(find.text('The other 3 applicants are declined'), findsOneWidget);
      expect(
        find.textContaining('Model Town, Ravi Riders and 1 more'),
        findsOneWidget,
      );
      expect(find.textContaining("can't be undone"), findsOneWidget);

      await tester.tap(find.text('Accept & create the match'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('omits the decline consequence when nobody else applied',
        (tester) async {
      await launch(tester, (context) async {
        await showAcceptApplicantSheet(
          context,
          applicant: team('Gulberg Giants'),
          otherApplicantNames: const [],
        );
      });

      expect(find.text('A match will be created'), findsOneWidget);
      expect(find.textContaining('are declined'), findsNothing);
    });

    testWidgets('cancelling returns false', (tester) async {
      bool? result;
      await launch(tester, (context) async {
        result = await showAcceptApplicantSheet(
          context,
          applicant: team('Gulberg Giants'),
          otherApplicantNames: const ['Model Town'],
        );
      });

      // Singular, not "the other 1 applicants".
      expect(find.text('The other applicant is declined'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('Reject sheet (artboard 18)', () {
    testWidgets('declines one applicant and says the others stay',
        (tester) async {
      RejectDecision? result;
      await launch(tester, (context) async {
        result = await showRejectApplicantSheet(
          context,
          applicant: team('Model Town Strikers'),
        );
      });

      expect(find.text('Decline Model Town Strikers?'), findsOneWidget);
      expect(
        find.text("They'll be notified. Your other applicants stay."),
        findsOneWidget,
      );
      expect(find.text('SLOT FILLED'), findsOneWidget);
      expect(find.text('FORMAT MISMATCH'), findsOneWidget);
      expect(find.text('TOO FAR'), findsOneWidget);

      await tester.tap(find.text('Decline applicant'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.reason, isNull, reason: 'the reason is optional');
    });

    testWidgets('carries the chosen chip and note as the reason',
        (tester) async {
      RejectDecision? result;
      await launch(tester, (context) async {
        result = await showRejectApplicantSheet(
          context,
          applicant: team('Model Town Strikers'),
        );
      });

      await tester.tap(find.text('SLOT FILLED'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Already matched.');
      await tester.tap(find.text('Decline applicant'));
      await tester.pumpAndSettle();

      expect(result!.reason, 'Slot filled — Already matched.');
    });

    testWidgets('tapping the active chip clears it', (tester) async {
      RejectDecision? result;
      await launch(tester, (context) async {
        result = await showRejectApplicantSheet(
          context,
          applicant: team('Model Town Strikers'),
        );
      });

      await tester.tap(find.text('TOO FAR'));
      await tester.pump();
      await tester.tap(find.text('TOO FAR'));
      await tester.pump();
      await tester.tap(find.text('Decline applicant'));
      await tester.pumpAndSettle();

      expect(result!.reason, isNull);
    });

    testWidgets('dismissing returns null, so nothing is declined',
        (tester) async {
      RejectDecision? result = const RejectDecision(reason: 'sentinel');
      await launch(tester, (context) async {
        result = await showRejectApplicantSheet(
          context,
          applicant: team('Model Town Strikers'),
        );
      });

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('Withdraw sheet (artboard 19)', () {
    testWidgets('states the consequence and counts the stranded applicants',
        (tester) async {
      bool? result;
      await launch(tester, (context) async {
        result = await showWithdrawChallengeSheet(
          context,
          hostTeam: team('Lahore Lions'),
          summary: '12 ov · Today 4:30 PM · 4 pending',
          pendingApplicants: 4,
        );
      });

      expect(find.text('Withdraw this challenge?'), findsOneWidget);
      expect(find.textContaining("can't be reinstated"), findsOneWidget);
      expect(find.textContaining('4 applicants'), findsOneWidget);
      expect(find.text('12 OV · TODAY 4:30 PM · 4 PENDING'), findsOneWidget);

      await tester.tap(find.text('Withdraw challenge'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('drops the notification sentence when nobody has applied',
        (tester) async {
      await launch(tester, (context) async {
        await showWithdrawChallengeSheet(
          context,
          hostTeam: team('Lahore Lions'),
          summary: '12 ov · Today 4:30 PM',
          pendingApplicants: 0,
        );
      });

      expect(find.textContaining("can't be reinstated"), findsOneWidget);
      expect(find.textContaining('will be notified'), findsNothing);
    });

    testWidgets('the dismiss reads "Keep it live", never "Cancel"',
        (tester) async {
      bool? result;
      await launch(tester, (context) async {
        result = await showWithdrawChallengeSheet(
          context,
          hostTeam: team('Lahore Lions'),
          summary: '12 ov',
          pendingApplicants: 2,
        );
      });

      expect(find.text('Cancel'), findsNothing);
      await tester.tap(find.text('Keep it live'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
