import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/database_provider.dart';
import 'package:matchday/core/database/wizard_draft_store.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:matchday/features/tournaments/presentation/screens/tournament_create_wizard_screen.dart';

class InMemoryWizardDraftStore implements WizardDraftStore {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    _storage[key] = data;
  }

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    return _storage[key];
  }

  @override
  Future<void> clear(String key) async {
    _storage.remove(key);
  }

  @override
  Stream<Map<String, dynamic>?> watch(String key) {
    return Stream.value(_storage[key]);
  }
}

void main() {
  group('TournamentCreateWizardScreen widget tests', () {
    final mockUser = User(
      id: const UserId('org-user-1'),
      email: Email.create('organizer@example.com').getOrElse((_) => throw Exception()),
      displayName: 'Tournament Organizer',
    );

    late InMemoryWizardDraftStore mockDraftStore;

    setUp(() {
      mockDraftStore = InMemoryWizardDraftStore();
    });

    Widget wizard() => ProviderScope(
          overrides: [
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            wizardDraftStoreProvider.overrideWithValue(mockDraftStore),
          ],
          child: const MaterialApp(home: TournamentCreateWizardScreen()),
        );

    /// Fills step 1's required name and advances to step 2.
    Future<void> passStep1(WidgetTester tester) async {
      await tester.enterText(
        find.byType(TextField).first,
        'Model Town Super Cup 2026',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets('step 1 asks the canvas question and counts the name',
        (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.text('Name your tournament'), findsOneWidget);
      expect(find.text('Save & exit'), findsOneWidget);

      // Privacy is two cards with a sentence of consequence, not a switch.
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private · invite only'), findsOneWidget);
      expect(
        find.textContaining('Listed in Explore and search'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsNothing);

      // The counter tracks the field.
      expect(find.text('0 / 100'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Model Town');
      await tester.pumpAndSettle();
      expect(find.text('10 / 100'), findsOneWidget);
    });

    testWidgets('Continue is inert until the name is long enough',
        (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();

      Widget continueBtn() => tester.widget(
            find.ancestor(
              of: find.text('Continue'),
              matching: find.byType(InkWell),
            ).first,
          );

      // Too short — no callback wired, and deliberately not red.
      await tester.enterText(find.byType(TextField).first, 'MT');
      await tester.pumpAndSettle();
      expect((continueBtn() as InkWell).onTap, isNull);

      await tester.enterText(find.byType(TextField).first, 'MTSC 2026');
      await tester.pumpAndSettle();
      expect((continueBtn() as InkWell).onTap, isNotNull);
    });

    testWidgets('step 2 offers the three built structures and marks the rest '
        'coming soon', (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();
      await passStep1(tester);

      expect(find.text('STEP 2 OF 6'), findsOneWidget);
      expect(find.text('How will it be played?'), findsOneWidget);
      expect(find.text('Knockout'), findsOneWidget);
      expect(find.text('Round Robin'), findsOneWidget);
      expect(find.text('League + Playoffs'), findsOneWidget);
      expect(find.text('Group + Knockout'), findsOneWidget);
      expect(find.text('Double Elimination'), findsOneWidget);
      expect(find.text('COMING SOON'), findsNWidgets(2));

      // Team bounds are steppers, defaulting to the canvas's 4–8.
      expect(find.text('Min teams'), findsOneWidget);
      expect(find.text('Max teams'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('step 3 pre-fills from the preset and names where it came from',
        (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();
      await passStep1(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Match format'), findsOneWidget);
      expect(find.text('Overs / innings'), findsOneWidget);
      expect(find.text('Max / bowler'), findsOneWidget);
      expect(
        find.textContaining('T20 sets 20 overs a side'),
        findsOneWidget,
      );
      expect(
        find.text('20 overs a side · max 4 per bowler · Leather (Red)'),
        findsOneWidget,
      );

      // Switching to ODI re-fills both numbers.
      await tester.tap(find.text('ODI'));
      await tester.pumpAndSettle();
      expect(
        find.text('50 overs a side · max 10 per bowler · Leather (Red)'),
        findsOneWidget,
      );
    });

    testWidgets('The Hundred switches the unit from overs to balls',
        (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();
      await passStep1(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('The Hundred'));
      await tester.pumpAndSettle();

      // 100 balls a side, 20 per bowler — not an overs figure.
      expect(find.text('Balls / innings'), findsOneWidget);
      expect(
        find.text('100 balls a side · max 20 per bowler · Leather (Red)'),
        findsOneWidget,
      );
    });

    testWidgets('step 4 shows the deadline error under the field, not a toast',
        (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();
      await passStep1(tester);
      await tester.tap(find.text('Continue')); // -> 3
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue')); // -> 4
      await tester.pumpAndSettle();

      expect(find.text('When and where'), findsOneWidget);
      expect(find.text('Registration deadline'), findsOneWidget);

      // Defaults are valid, so Continue is live and no error is shown.
      expect(
        find.textContaining('Registration deadline must be on or before'),
        findsNothing,
      );
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('step 6 review is editable in place', (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();
      await passStep1(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      expect(find.text('STEP 6 OF 6'), findsOneWidget);
      expect(find.text('Check it over'), findsOneWidget);
      expect(find.text('Model Town Super Cup 2026'), findsOneWidget);
      expect(find.text('STRUCTURE'), findsOneWidget);
      expect(find.text('SCHEDULE'), findsOneWidget);
      expect(find.text('MONEY & SQUADS'), findsOneWidget);
      // The final action publishes rather than continuing.
      expect(find.text('Publish tournament'), findsOneWidget);

      // Each group's Edit jumps back to its own step.
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();
      expect(find.text('STEP 1 OF 6'), findsOneWidget);
    });

    testWidgets('Save & exit persists the draft under the user key',
        (tester) async {
      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Lahore Ramadan Night T20',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & exit'));
      await tester.pumpAndSettle();

      final draft = await mockDraftStore.load('tournament_create:org-user-1');
      expect(draft, isNotNull);
      expect(draft!['name'], 'Lahore Ramadan Night T20');
      expect(draft['step'], 0);
    });

    testWidgets('a saved draft is restored on re-entry', (tester) async {
      await mockDraftStore.save('tournament_create:org-user-1', {
        'step': 2,
        'name': 'Restored Cup',
        'formatPreset': 'ODI',
        'perInnings': 50,
        'perBowler': 10,
        'ballType': 'Tape Ball',
      });

      await tester.pumpWidget(wizard());
      await tester.pumpAndSettle();

      expect(find.text('STEP 3 OF 6'), findsOneWidget);
      expect(
        find.text('50 overs a side · max 10 per bowler · Tape Ball'),
        findsOneWidget,
      );
    });
  });
}
