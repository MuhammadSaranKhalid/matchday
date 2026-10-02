import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:matchday/core/supabase/supabase_client_provider.dart';
import 'package:matchday/features/tournaments/domain/entities/my_tournament_entry.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_registration.dart';
import 'package:matchday/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:matchday/features/tournaments/presentation/screens/my_tournaments_screen.dart';
import '../../../../helpers/mock_auth.dart';

void main() {
  group('MyTournamentsScreen widget tests', () {
    final mockSupabase = createMockSupabaseClient(
      id: 'user-1',
      email: 'imran@example.com',
    );

    final mockTournaments = <Tournament>[
      Tournament(
        id: 'tourn-org-1',
        name: 'Lahore Champions League 2026',
        type: TournamentType.knockout,
        status: TournamentStatus.registration,
        privacy: TournamentPrivacy.public,
        ownerUserId: 'user-1',
        createdBy: 'user-1',
        venues: const [TournamentVenue(name: 'Gaddafi Stadium', city: 'Lahore')],
        city: 'Lahore',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 10),
        format: const {'overs': 20},
        rules: const {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Tournament(
        id: 'tourn-play-1',
        name: 'Islamabad Tape Ball Cup',
        type: TournamentType.roundRobin,
        status: TournamentStatus.live,
        privacy: TournamentPrivacy.public,
        ownerUserId: 'user-2',
        createdBy: 'user-2',
        venues: const [TournamentVenue(name: 'Diamond Ground', city: 'Islamabad')],
        city: 'Islamabad',
        startDate: DateTime(2026, 8, 25),
        endDate: DateTime(2026, 9, 5),
        format: const {'overs': 10},
        rules: const {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    Widget hub({
      List<Tournament>? tournaments,
      List<MyTournamentEntry>? playing,
      Map<String, dynamic>? draft,
    }) =>
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabase),
            myTournamentsProvider.overrideWith(
              (ref) => Future.value(tournaments ?? mockTournaments),
            ),
            myPlayingTournamentsProvider
                .overrideWith((ref) => Future.value(playing ?? const [])),
            tournamentDraftStreamProvider
                .overrideWith((ref) => Stream.value(draft)),
            // The organizing card reads registrations for its progress and
            // pending-count chips.
            tournamentRegistrationsProvider('tourn-org-1')
                .overrideWith((ref) => Future.value(const [])),
            tournamentRegistrationsProvider('tourn-play-1')
                .overrideWith((ref) => Future.value(const [])),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MyTournamentsScreen(),
          ),
        );

    testWidgets('is a pushed screen with a Create pill and a segmented control',
        (tester) async {
      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();

      expect(find.text('My Tournaments'), findsOneWidget);
      expect(find.text('CREATE'), findsOneWidget);

      // A segmented filter, not a TabBar — counts ride in the semantics and badges.
      expect(find.byType(TabBar), findsNothing);
      expect(find.text('ORGANIZING'), findsOneWidget);
      expect(find.text('PLAYING'), findsOneWidget);
      expect(find.text('FOLLOWING'), findsOneWidget);
    });

    testWidgets('organizing cards carry the console verb and a fee note',
        (tester) async {
      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();

      expect(find.text('ORGANIZING (ACTIVE)'), findsOneWidget);
      expect(find.text('Lahore Champions League 2026'), findsOneWidget);
      expect(find.text('REG OPEN'), findsOneWidget);
      expect(find.text('Manage Console'), findsOneWidget);
    });

    testWidgets('a spectator card carries no verbs at all', (tester) async {
      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();

      await tester.tap(find.text('FOLLOWING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('LIVE & UPCOMING'), findsOneWidget);
      expect(find.text('Islamabad Tape Ball Cup'), findsOneWidget);
      // Manage Console belongs to organisers; it is hidden here, not disabled.
      expect(find.text('Manage Console'), findsNothing);
      expect(find.text('Register'), findsNothing);
      // The discovery nudge sits after the list.
      expect(find.text('Looking for local cups to join?'), findsOneWidget);
    });

    testWidgets('an unpublished draft appears in the Drafts group',
        (tester) async {
      await tester.pumpWidget(
        hub(draft: const {'step': 2, 'name': 'Lahore Ramadan Night T20'}),
      );
      await tester.pumpAndSettle();

      expect(find.text('DRAFTS (1)'), findsOneWidget);
      expect(find.text('Lahore Ramadan Night T20'), findsOneWidget);
      expect(find.text('3 of 6 steps complete'), findsOneWidget);
      expect(find.text('Resume Setup'), findsOneWidget);
    });

    testWidgets('with nothing anywhere, the segmented control is not rendered',
        (tester) async {
      await tester.pumpWidget(hub(tournaments: const []));
      await tester.pumpAndSettle();

      // Single-relationship rule: three empty tabs would be three dead ends.
      expect(find.text('ORGANIZING'), findsNothing);
      expect(find.text('FOLLOWING'), findsNothing);
      // And the nav drops Create, because the body already owns that CTA.
      expect(find.text('CREATE'), findsNothing);

      expect(find.text('No tournaments yet'), findsOneWidget);
      expect(find.text('Create a Tournament'), findsOneWidget);
      expect(find.text('Browse Public Tournaments'), findsOneWidget);
    });

    testWidgets('the Playing bucket shows squad state, not organiser verbs',
        (tester) async {
      final entry = MyTournamentEntry(
        tournament: mockTournaments[1],
        registration: TournamentRegistration(
          registrationId: 'reg-1',
          tournamentId: 'tourn-play-1',
          teamId: 'team-1',
          teamName: 'Lahore Lions',
          status: TournamentRegistrationStatus.approved,
          squadProposal: const ['p1', 'p2', 'p3'],
          registeredBy: 'user-1',
          registeredAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(hub(playing: [entry]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PLAYING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('CURRENTLY PLAYING'), findsOneWidget);
      expect(find.text('Playing as Lahore Lions'), findsOneWidget);
      expect(find.text('Squad confirmed · 3'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Manage Console'), findsNothing);
    });
  });
}
