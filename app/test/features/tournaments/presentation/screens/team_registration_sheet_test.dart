import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/teams/domain/entities/roster_member.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:matchday/features/teams/domain/entities/team_membership.dart';
import 'package:matchday/features/teams/presentation/providers/team_membership_providers.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_registration.dart';
import 'package:matchday/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:matchday/features/tournaments/presentation/screens/team_registration_sheet.dart';
import 'package:matchday/features/tournaments/presentation/screens/tournament_registration_status_screen.dart';

void main() {
  group('TeamRegistrationSheet widget tests', () {
    final mockTournament = Tournament(
      id: 'tourn-reg-1',
      name: 'All Pakistan Tape Ball Trophy',
      type: TournamentType.knockout,
      status: TournamentStatus.registration,
      privacy: TournamentPrivacy.public,
      ownerUserId: 'org-user-1',
      createdBy: 'org-user-1',
      venues: const [TournamentVenue(name: 'National Stadium', city: 'Karachi')],
      city: 'Karachi',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 10),
      entryFee: 5000.0,
      format: const {'max_overs': 10},
      rules: const {
        'paymentDetails': 'EasyPaisa 0300-1122334',
        'min_squad': 12,
        'max_squad': 18,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockTeams = <Team>[
      Team(
        id: const TeamId('team-reg-1'),
        createdBy: 'user-mgr-1',
        name: 'Lahore Warriors',
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final mockMemberships = <TeamMembership>[
      TeamMembership(
        team: mockTeams.first,
        member: TeamMember(
          id: const MembershipId('member-owner-1'),
          teamId: const TeamId('team-reg-1'),
          playerId: 'user-mgr-1',
          roles: {MemberRole.owner.wire},
          playerType: PlayerType.claimed,
          addedBy: 'user-mgr-1',
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];

    final mockRoster = List.generate(12, (i) {
      return RosterMember(
        member: TeamMember(
          id: MembershipId('member-$i'),
          teamId: const TeamId('team-reg-1'),
          playerId: 'player-$i',
          roles: {(i == 0 ? MemberRole.captain : MemberRole.player).wire},
          playerType: PlayerType.claimed,
          addedBy: 'user-mgr-1',
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        displayName: 'Player Number $i',
      );
    });

    testWidgets('renders Step 1: Select Team and displays eligible teams', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            currentUserTeamMembershipsProvider
                .overrideWith((ref) => Future.value(mockMemberships)),
            rosterProvider('team-reg-1')
                .overrideWith((ref) => Future.value(mockRoster)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(<TournamentRegistration>[])),
          ],
          child: const MaterialApp(
            home: TeamRegistrationSheet(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Which team is playing?'), findsOneWidget);
      expect(find.text('Lahore Warriors'), findsOneWidget);
      expect(find.text('12 players · eligible'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('transitions through Step 1 to Step 2 Squad Picker', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            currentUserTeamMembershipsProvider
                .overrideWith((ref) => Future.value(mockMemberships)),
            rosterProvider('team-reg-1')
                .overrideWith((ref) => Future.value(mockRoster)),
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
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT SQUAD ROSTER'), findsOneWidget);
      expect(find.text('Player Number 0'), findsOneWidget);
    });

    testWidgets('shows already registered badge when team is registered', (tester) async {
      final existingRegistration = TournamentRegistration(
        registrationId: 'reg-approved-1',
        tournamentId: 'tourn-reg-1',
        teamId: 'team-reg-1',
        teamName: 'Lahore Warriors',
        status: TournamentRegistrationStatus.approved,
        squadProposal: const ['p1', 'p2', 'p3'],
        registeredBy: 'user-mgr-1',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            currentUserTeamMembershipsProvider
                .overrideWith((ref) => Future.value(mockMemberships)),
            rosterProvider('team-reg-1')
                .overrideWith((ref) => Future.value(mockRoster)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value([existingRegistration])),
          ],
          child: const MaterialApp(
            home: TeamRegistrationSheet(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ALREADY REGISTERED · PENDING'), findsOneWidget);
    });

    testWidgets('transitions to Step 3 Rules & Fee agreement', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            currentUserTeamMembershipsProvider
                .overrideWith((ref) => Future.value(mockMemberships)),
            rosterProvider('team-reg-1')
                .overrideWith((ref) => Future.value(mockRoster)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(<TournamentRegistration>[])),
          ],
          child: const MaterialApp(
            home: TeamRegistrationSheet(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: select team and continue
      await tester.tap(find.text('Lahore Warriors'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: 12 players auto-selected, continue to Step 3
      await tester.tap(find.textContaining('Continue'));
      await tester.pumpAndSettle();

      // Step 3
      expect(find.text('MATCH RULES'), findsOneWidget);
      expect(find.text('ENTRY FEE'), findsOneWidget);
      expect(find.text('PKR 5,000'), findsOneWidget);
      expect(find.text('Overs per innings'), findsOneWidget);
      expect(find.text('10'), findsWidgets);
    });

    testWidgets('a manager with a second team can still enter it', (tester) async {
      final team2 = Team(
        id: const TeamId('team-reg-2'),
        createdBy: 'user-mgr-1',
        name: 'Gulberg Lions',
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final twoMemberships = <TeamMembership>[
        ...mockMemberships,
        TeamMembership(
          team: team2,
          member: TeamMember(
            id: const MembershipId('member-owner-2'),
            teamId: const TeamId('team-reg-2'),
            playerId: 'user-mgr-1',
            roles: {MemberRole.owner.wire},
            playerType: PlayerType.claimed,
            addedBy: 'user-mgr-1',
            joinedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];

      final firstTeamIn = TournamentRegistration(
        registrationId: 'reg-1',
        tournamentId: 'tourn-reg-1',
        teamId: 'team-reg-1',
        teamName: 'Lahore Warriors',
        status: TournamentRegistrationStatus.approved,
        squadProposal: const [],
        registeredBy: 'user-mgr-1',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            currentUserTeamMembershipsProvider
                .overrideWith((ref) => Future.value(twoMemberships)),
            rosterProvider('team-reg-1')
                .overrideWith((ref) => Future.value(mockRoster)),
            rosterProvider('team-reg-2')
                .overrideWith((ref) => Future.value(mockRoster)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value([firstTeamIn])),
          ],
          child: const MaterialApp(
            home: TeamRegistrationSheet(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lahore Warriors'), findsOneWidget);
      expect(find.text('ALREADY REGISTERED · PENDING'), findsOneWidget);
      expect(find.text('Gulberg Lions'), findsOneWidget);
      expect(find.text('12 players · eligible'), findsOneWidget);
    });
  });

  group('TournamentRegistrationStatusScreen widget tests', () {
    final mockTournament = Tournament(
      id: 'tourn-reg-1',
      name: 'All Pakistan Tape Ball Trophy',
      type: TournamentType.knockout,
      status: TournamentStatus.registration,
      privacy: TournamentPrivacy.public,
      ownerUserId: 'org-user-1',
      createdBy: 'org-user-1',
      venues: const [TournamentVenue(name: 'National Stadium', city: 'Karachi')],
      city: 'Karachi',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 10),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockTeam = Team(
      id: const TeamId('team-reg-1'),
      createdBy: 'user-mgr-1',
      name: 'Lahore Warriors',
      type: TeamType.club,
      privacy: TeamPrivacy.public,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockMemberships = <TeamMembership>[
      TeamMembership(
        team: mockTeam,
        member: TeamMember(
          id: const MembershipId('member-owner-1'),
          teamId: const TeamId('team-reg-1'),
          playerId: 'user-mgr-1',
          roles: {MemberRole.owner.wire},
          playerType: PlayerType.claimed,
          addedBy: 'user-mgr-1',
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];

    testWidgets('renders approved registration tracker view (Artboard 33)', (tester) async {
      final approvedRegistration = TournamentRegistration(
        registrationId: 'reg-approved-1',
        tournamentId: 'tourn-reg-1',
        teamId: 'team-reg-1',
        teamName: 'Lahore Warriors',
        status: TournamentRegistrationStatus.approved,
        squadProposal: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9', 'p10', 'p11'],
        registeredBy: 'user-mgr-1',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            currentUserTeamMembershipsProvider
                .overrideWith((ref) => Future.value(mockMemberships)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value([approvedRegistration])),
          ],
          child: const MaterialApp(
            home: TournamentRegistrationStatusScreen(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('You’re in the draw'), findsOneWidget);
      expect(find.text('Approved by the organiser'), findsOneWidget);
      expect(find.text('11 players · submitted 0 minutes ago'), findsOneWidget);
    });

    testWidgets('a declined team is shown the organiser\'s reason, not its own application note',
        (tester) async {
      final declined = TournamentRegistration(
        registrationId: 'reg-declined-1',
        tournamentId: 'tourn-reg-1',
        teamId: 'team-reg-1',
        teamName: 'Lahore Warriors',
        status: TournamentRegistrationStatus.rejected,
        squadProposal: const [],
        message: 'Payment Ref: TX-9931 | Captain: player-0',
        decisionReason: 'The cup filled before your entry arrived.',
        registeredBy: 'user-mgr-1',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentDetailProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            currentUserTeamMembershipsProvider
                .overrideWith((ref) => Future.value(mockMemberships)),
            tournamentRegistrationsProvider('tourn-reg-1')
                .overrideWith((ref) => Future.value([declined])),
          ],
          child: const MaterialApp(
            home: TournamentRegistrationStatusScreen(tournamentId: 'tourn-reg-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('The cup filled before your entry arrived.'),
        findsOneWidget,
      );
      expect(find.textContaining('Payment Ref'), findsNothing);
    });
  });
}
