import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_awards.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_registration.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_standing.dart';
import 'package:matchday/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:matchday/features/tournaments/presentation/screens/tournament_detail_screen.dart';

void main() {
  group('TournamentDetailScreen widget tests', () {
    final mockUser = User(
      id: const UserId('user-1'),
      email: Email.create('organizer@example.com').getOrElse((_) => throw Exception()),
      displayName: 'Tournament Director',
    );

    final mockTournament = Tournament(
      id: 'tourn-detail-1',
      name: 'Lahore Champions Trophy 2026',
      type: TournamentType.knockout,
      status: TournamentStatus.registration,
      privacy: TournamentPrivacy.public,
      createdBy: 'user-1',
      organizers: const ['user-1'],
      venues: const [TournamentVenue(name: 'Gaddafi Stadium', city: 'Lahore')],
      city: 'Lahore',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 10),
      registrationDeadline: DateTime(2026, 8, 30),
      maxTeams: 8,
      approvedTeamsCount: 6,
      format: const {'overs': 20, 'ballType': 'Leather'},
      rules: const {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockFixtures = <Match>[
      Match(
        id: const MatchId('match-1'),
        tournamentId: 'tourn-detail-1',
        bracketRoundNumber: 1,
        teamAId: const TeamId('team-a'),
        teamBId: const TeamId('team-b'),
        status: MatchStatus.scheduled,
        createdBy: 'user-1',
        scheduledStartTime: DateTime(2026, 9, 1, 15, 0),
        format: const MatchFormat(
          oversPerInnings: 20,
          playersPerTeam: 11,
          maxOversPerBowler: 4,
          ballType: MatchBallType.leather,
        ),
        venue: const Venue(ground: 'Gaddafi Stadium', city: 'Lahore'),
        createdAt: DateTime.now(),
      ),
    ];

    final mockRegistrations = <TournamentRegistration>[
      TournamentRegistration(
        registrationId: 'reg-1',
        tournamentId: 'tourn-detail-1',
        teamId: 'team-a',
        teamName: 'Model Town CC',
        status: TournamentRegistrationStatus.approved,
        registeredBy: 'user-1',
        registeredAt: DateTime.now(),
        squad: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      TournamentRegistration(
        registrationId: 'reg-2',
        tournamentId: 'tourn-detail-1',
        teamId: 'team-b',
        teamName: 'Cantt CC',
        status: TournamentRegistrationStatus.approved,
        registeredBy: 'user-2',
        registeredAt: DateTime.now(),
        squad: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    testWidgets('renders tournament detail header and overview tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserStreamProvider.overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            tournamentFixturesProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(mockFixtures)),
            tournamentRegistrationsProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
            tournamentAwardsProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(const TournamentAwards())),
            tournamentStandingsStreamProvider('tourn-detail-1')
                .overrideWith((ref) => Stream.value(<TournamentStanding>[])),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: 'tourn-detail-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lahore Champions Trophy 2026'), findsOneWidget);
      expect(find.text('REGISTRATION OPEN'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Fixtures'), findsOneWidget);
      expect(find.text('Bracket'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      // The expanded header is a 168pt banner plus the identity zone
      // (artboards 09-15), so the Overview CTA sits below the fold on a
      // phone-sized viewport — scroll to it rather than shrinking the header.
      await tester.scrollUntilVisible(
        find.textContaining('Register Your Team'),
        250,
        scrollable: find.byType(Scrollable).last,
      );

      // The CTA carries the fee, because "is it worth PKR 15,000" is one of
      // the three questions artboard 09 is built around.
      expect(find.textContaining('Register Your Team'), findsOneWidget);
    });

    testWidgets('switches to Teams tab and displays approved teams', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserStreamProvider.overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            tournamentFixturesProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(mockFixtures)),
            tournamentRegistrationsProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
            tournamentAwardsProvider('tourn-detail-1')
                .overrideWith((ref) => Future.value(const TournamentAwards())),
            tournamentStandingsStreamProvider('tourn-detail-1')
                .overrideWith((ref) => Stream.value(<TournamentStanding>[])),
          ],
          child: const MaterialApp(
            home: TournamentDetailScreen(tournamentId: 'tourn-detail-1', initialTab: 3),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Model Town CC'), findsOneWidget);
      expect(find.text('Cantt CC'), findsOneWidget);
    });
  });
}
