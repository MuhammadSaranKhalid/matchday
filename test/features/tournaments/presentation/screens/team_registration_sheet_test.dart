import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/teams/domain/entities/roster_member.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_registration.dart';
import 'package:matchday/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:matchday/features/tournaments/presentation/screens/team_registration_sheet.dart';

void main() {
  group('TeamRegistrationSheet widget tests', () {
    final mockUser = User(
      id: const UserId('user-mgr-1'),
      email: Email.create('manager@example.com').getOrElse((_) => throw Exception()),
      displayName: 'Team Manager',
    );

    final mockTournament = Tournament(
      id: 'tourn-reg-1',
      name: 'All Pakistan Tape Ball Trophy',
      type: TournamentType.knockout,
      status: TournamentStatus.registration,
      privacy: TournamentPrivacy.public,
      createdBy: 'org-user-1',
      organizers: const ['org-user-1'],
      venues: const [TournamentVenue(name: 'National Stadium', city: 'Karachi')],
      city: 'Karachi',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 10),
      entryFee: 5000.0,
      format: const {'overs': 10},
      rules: const {'paymentDetails': 'EasyPaisa 0300-1122334'},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockTeams = <Team>[
      Team(
        id: const TeamId('team-reg-1'),
        ownerId: 'user-mgr-1',
        name: 'Lahore Warriors',
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        managers: const ['user-mgr-1'],
        city: 'Lahore',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final mockRoster = List.generate(12, (i) {
      return RosterMember(
        member: TeamMember(
          id: MembershipId('member-$i'),
          teamId: const TeamId('team-reg-1'),
          playerId: 'player-$i',
          role: i == 0 ? MemberRole.captain : MemberRole.player,
          playerType: PlayerType.claimed,
          addedBy: 'user-mgr-1',
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        displayName: 'Player Number $i',
      );
    });

    testWidgets('renders Step 1: Select Team and Requirements checklist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserStreamProvider.overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            myTeamsProvider.overrideWith((ref) => Stream.value(mockTeams)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(<TournamentRegistration>[])),
          ],
          child: const MaterialApp(
            home: TeamRegistrationSheet(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Team Registration'), findsOneWidget);
      expect(find.text('TOURNAMENT REQUIREMENTS'), findsOneWidget);
      expect(find.text('Lahore Warriors'), findsOneWidget);
      expect(find.text('PKR 5000'), findsWidgets);
      expect(find.text('Continue →'), findsOneWidget);
    });

    testWidgets('transitions through Step 1 to Step 2 Squad Picker', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserStreamProvider.overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            myTeamsProvider.overrideWith((ref) => Stream.value(mockTeams)),
            rosterProvider('team-reg-1').overrideWith((ref) => Stream.value(mockRoster)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(<TournamentRegistration>[])),
          ],
          child: const MaterialApp(
            home: TeamRegistrationSheet(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap team card
      await tester.tap(find.text('Lahore Warriors'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue →'));
      await tester.pumpAndSettle();

      expect(find.text('SQUAD SELECTION'), findsOneWidget);
      expect(find.text('TEAM ROSTER PLAYERS'), findsOneWidget);
      expect(find.text('+ Add Guest Player'), findsOneWidget);
    });

    testWidgets('renders existing registration tracker view (Artboard 33) when registered', (tester) async {
      final existingRegistration = TournamentRegistration(
        registrationId: 'reg-approved-1',
        tournamentId: 'tourn-reg-1',
        teamId: 'team-reg-1',
        teamName: 'Lahore Warriors',
        status: TournamentRegistrationStatus.approved,
        seedNumber: 1,
        squad: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9', 'p10', 'p11'],
        registeredBy: 'user-mgr-1',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserStreamProvider.overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            myTeamsProvider.overrideWith((ref) => Stream.value(mockTeams)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value([existingRegistration])),
          ],
          child: const MaterialApp(
            home: TeamRegistrationSheet(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('🎉 Entry Approved & Confirmed'), findsOneWidget);
      expect(find.text('11 Players Registered'), findsOneWidget);
      expect(find.text('Seed Number: #1'), findsOneWidget);
    });
  });
}
