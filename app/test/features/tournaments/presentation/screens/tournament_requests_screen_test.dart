import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_registration.dart';
import 'package:matchday/features/tournaments/domain/repositories/tournaments_repository.dart';
import 'package:matchday/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:matchday/features/tournaments/presentation/screens/tournament_requests_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TournamentsRepository {}

void main() {
  group('TournamentRequestsScreen (artboard 24f)', () {
    late _MockRepo repo;

    setUp(() {
      repo = _MockRepo();
      when(() => repo.approveRegistration(any()))
          .thenAnswer((_) async => const Right(null));
    });

    final user = User(
      id: const UserId('org-user-1'),
      email:
          Email.create('organizer@example.com').getOrElse((_) => throw Exception()),
      displayName: 'Tournament Organizer',
    );

    final tournament = Tournament(
      id: 't1',
      name: 'Model Town Super Cup',
      type: TournamentType.knockout,
      status: TournamentStatus.registration,
      privacy: TournamentPrivacy.public,
      createdBy: 'org-user-1',
      organizers: const ['org-user-1'],
      venues: const [TournamentVenue(name: 'Model Town Ground', city: 'Lahore')],
      city: 'Lahore',
      entryFee: 15000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    /// [count] pending applications, the oldest [oldestDays] days old.
    List<TournamentRegistration> pending(int count, {int oldestDays = 6}) {
      final now = DateTime.now();
      return [
        for (var i = 0; i < count; i++)
          TournamentRegistration(
            registrationId: 'reg-$i',
            tournamentId: 't1',
            teamId: 'team-$i',
            teamName: 'Applicant $i',
            status: TournamentRegistrationStatus.pending,
            // Squad of 14: three named, then eleven more, two of them guests.
            squad: [
              'Imran Yousaf',
              'Zeeshan Tariq',
              'Faraz Alam',
              for (var p = 0; p < 9; p++) 'player-$p',
              'guest_Uncle Asif',
              'guest_Young Bilal',
            ],
            registeredBy: 'mgr-$i',
            registeredByName: 'Manager $i',
            registeredAt: now.subtract(Duration(days: i == 0 ? oldestDays : 1)),
            createdAt: now,
            updatedAt: now,
          ),
      ];
    }

    Widget harness(List<TournamentRegistration> regs) => ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider.overrideWith((ref) => Stream.value(user)),
            tournamentDetailProvider('t1')
                .overrideWith((ref) => Future.value(tournament)),
            tournamentRegistrationsProvider('t1')
                .overrideWith((ref) => Future.value(regs)),
          ],
          child: const MaterialApp(
            home: TournamentRequestsScreen(tournamentId: 't1'),
          ),
        );

    testWidgets('the queue opens at four and offers the rest', (tester) async {
      await tester.pumpWidget(harness(pending(6)));
      await tester.pumpAndSettle();

      expect(find.text('Applicant 0'), findsOneWidget);
      expect(find.text('Applicant 3'), findsOneWidget);
      // Five and six are behind the footer.
      expect(find.text('Applicant 4'), findsNothing);
      expect(find.text('Applicant 5'), findsNothing);

      // The age is the reason to open them, so the footer carries it.
      await tester.scrollUntilVisible(find.text('Show all'), 300);
      await tester.pumpAndSettle();
      expect(find.text('2 more pending · oldest applied 6 days ago'),
          findsOneWidget);

      await tester.tap(find.text('Show all'));
      await tester.pumpAndSettle();

      // The footer is spent, and the rest of the queue is now reachable.
      expect(find.text('Show all'), findsNothing);
      await tester.scrollUntilVisible(find.text('Applicant 5'), 300);
      expect(find.text('Applicant 5'), findsOneWidget);
    });

    testWidgets('a short queue carries no footer at all', (tester) async {
      await tester.pumpWidget(harness(pending(3)));
      await tester.pumpAndSettle();

      expect(find.text('Applicant 2'), findsOneWidget);
      expect(find.text('Show all'), findsNothing);
      expect(find.textContaining('more pending'), findsNothing);
    });

    testWidgets('the squad expander names three, then counts the rest',
        (tester) async {
      await tester.pumpWidget(harness(pending(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('14 players'));
      await tester.pumpAndSettle();

      expect(find.text('Imran Yousaf'), findsOneWidget);
      expect(find.text('Zeeshan Tariq'), findsOneWidget);
      expect(find.text('Faraz Alam'), findsOneWidget);

      // The organiser needs the guest count: those players have no account
      // behind them, so they cannot be messaged or verified.
      expect(find.text('+ 11 more · 2 unregistered on Matchday'),
          findsOneWidget);
    });
  });
}
