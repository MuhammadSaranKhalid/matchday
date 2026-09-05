import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_live_match.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_registration.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/features/tournaments/domain/repositories/tournaments_repository.dart';
import 'package:matchday/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:matchday/features/tournaments/presentation/screens/organizer_console_screen.dart';
import 'package:matchday/features/tournaments/presentation/widgets/tournament_seeding_tab.dart';

class _MockRepo extends Mock implements TournamentsRepository {}

void main() {
  group('OrganizerConsoleScreen widget tests', () {
    late _MockRepo repo;

    setUp(() {
      repo = _MockRepo();
      when(() => repo.approveRegistration(any()))
          .thenAnswer((_) async => const Right(null));
    });

    final mockUser = User(
      id: const UserId('org-user-1'),
      email: Email.create('organizer@example.com').getOrElse((_) => throw Exception()),
      displayName: 'Tournament Organizer',
    );

    final mockTournament = Tournament(
      id: 'tourn-console-1',
      name: 'Lahore Champions Trophy',
      type: TournamentType.knockout,
      status: TournamentStatus.registration,
      privacy: TournamentPrivacy.public,
      createdBy: 'org-user-1',
      organizers: const ['org-user-1'],
      venues: const [TournamentVenue(name: 'Gaddafi Stadium', city: 'Lahore')],
      city: 'Lahore',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 10),
      entryFee: 5000.0,
      minTeams: 4,
      maxTeams: 8,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockRegistrations = <TournamentRegistration>[
      TournamentRegistration(
        registrationId: 'reg-p1',
        tournamentId: 'tourn-console-1',
        teamId: 'team-1',
        teamName: 'Lahore Lions',
        status: TournamentRegistrationStatus.pending,
        squad: const ['p1', 'p2', 'p3'],
        registeredBy: 'mgr-1',
        registeredByName: 'Captain Ali',
        message: 'Looking forward to participating!',
        paymentStatus: 'UNPAID',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      TournamentRegistration(
        registrationId: 'reg-a1',
        tournamentId: 'tourn-console-1',
        teamId: 'team-2',
        teamName: 'Karachi Kings Club',
        status: TournamentRegistrationStatus.approved,
        seedNumber: 1,
        groupId: 'Group A',
        squad: const ['p4', 'p5', 'p6'],
        registeredBy: 'mgr-2',
        registeredByName: 'Coach Khan',
        paymentStatus: 'PAID',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    testWidgets('chrome is Manage + three tabs, with a badge for what is owed',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage'), findsOneWidget);
      expect(find.text('Lahore Champions Trophy'), findsOneWidget);

      // Three tabs, and the second names seeds because this cup is knockout.
      expect(find.text('Registrations'), findsOneWidget);
      expect(find.text('Fixtures & Seeds'), findsOneWidget);
      expect(find.text('Live Ops'), findsOneWidget);
      expect(find.text('Groups & Pools'), findsNothing);

      // One application is waiting, so the badge reads 1 — not 2, which is
      // how many registrations exist.
      expect(find.text('1'), findsWidgets);

      expect(find.text('PENDING APPLICATIONS (1)'), findsOneWidget);
      expect(find.text('Lahore Lions'), findsOneWidget);
      expect(find.text('Approve Team'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('APPROVED TEAMS (1 / 8)'), findsOneWidget);
    });

    testWidgets('the second tab is Fixtures & Order for a flat format',
        (tester) async {
      final league = Tournament(
        id: 'tourn-console-1',
        name: 'Punjab Champions Trophy',
        type: TournamentType.roundRobin,
        status: TournamentStatus.registration,
        privacy: TournamentPrivacy.public,
        createdBy: 'org-user-1',
        organizers: const ['org-user-1'],
        venues: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(league)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fixtures & Order'), findsOneWidget);
      expect(find.text('Fixtures & Seeds'), findsNothing);
    });

    testWidgets('an empty queue states what happens next', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(const [])),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No applications yet'), findsOneWidget);
      expect(find.text('Share the link'), findsOneWidget);
      expect(find.text('Invite specific teams'), findsOneWidget);
      // Nothing is owed, so the Registrations tab carries no badge.
      expect(find.textContaining('PENDING APPLICATIONS'), findsNothing);
    });

    testWidgets('approving is undoable for five seconds rather than confirmed',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approve Team'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // No dialog — a snackbar carrying the undo.
      expect(find.text('Lahore Lions approved'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      // The row leaves the queue immediately.
      expect(find.text('PENDING APPLICATIONS (1)'), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Undo puts it back.
      expect(find.text('PENDING APPLICATIONS (1)'), findsOneWidget);
    });

    testWidgets('the seeding tab explains the draw and gates the lock',
        (tester) async {
      // Four approved teams so the draw is available.
      final approved = [
        for (var i = 0; i < 4; i++)
          TournamentRegistration(
            registrationId: 'reg-$i',
            tournamentId: 'tourn-console-1',
            teamId: 'team-$i',
            teamName: 'Team $i',
            status: TournamentRegistrationStatus.approved,
            squad: const ['p1', 'p2'],
            registeredBy: 'mgr-$i',
            paymentStatus: 'PAID',
            registeredAt: DateTime(2026, 8, i + 1),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(approved)),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fixtures & Seeds'));
      await tester.pumpAndSettle();

      expect(find.text('Seeding method'), findsOneWidget);
      // Method is three icon cards, not pill chips.
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Past form'), findsOneWidget);
      // One helper line: what to do, and what the order means.
      expect(
        find.text('Drag to set seeds. Seed 1 meets seed 4 in the first round.'),
        findsOneWidget,
      );
      // Past form is withheld with its reason stated, not silently disabled.
      expect(find.textContaining('Past form is unavailable'), findsOneWidget);
      // The lock button is the last row of a long list, and ListView only
      // mounts what is on screen — so scroll the seeding tab's own scrollable
      // rather than looking for a widget that does not exist yet.
      final lockButton = find.text('Lock & Publish Fixtures');
      await tester.scrollUntilVisible(
        lockButton,
        300,
        scrollable: find
            .descendant(
              of: find.byType(TournamentSeedingTab),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(lockButton, findsOneWidget);

      await tester.tap(lockButton);
      await tester.pumpAndSettle();

      // Artboard 26: a checkbox gates the confirm, and the confirm is ink.
      expect(find.text('CANNOT BE UNDONE'), findsOneWidget);
      expect(find.text('Lock the draw and publish fixtures?'), findsOneWidget);

      final confirm = find.widgetWithText(ElevatedButton, 'Lock & Publish');
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

      await tester.tap(
        find.textContaining('I have checked the seeds'),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
    });

    // ─── Live Ops (artboard 27) ──────────────────────────────────────────────

    List<TournamentLiveMatch> buildLiveBoard() => <TournamentLiveMatch>[
      // Ground 1 — live, scored, second innings in progress.
      TournamentLiveMatch(
        matchId: 'm-live',
        venue: 'Ground 1 · Gaddafi Stadium',
        status: 'live',
        scheduledStartTime: DateTime(2026, 9, 1, 14, 5),
        teamAId: 'team-1',
        teamAName: 'Lahore Lions',
        teamBId: 'team-2',
        teamBName: 'Karachi Kings Club',
        scorerId: 'scorer-1',
        scorerName: 'Haris Rauf',
        lastBallAt: DateTime.now().subtract(const Duration(seconds: 40)),
        inningsLines: const [
          LiveInningsLine(
            inningsNumber: 1,
            battingTeamId: 'team-1',
            runs: 161,
            wickets: 7,
            legalBalls: 120,
          ),
          LiveInningsLine(
            inningsNumber: 2,
            battingTeamId: 'team-2',
            runs: 142,
            wickets: 3,
            legalBalls: 98,
          ),
        ],
      ),
      // Ground 3 — upcoming with nobody appointed to score it.
      TournamentLiveMatch(
        matchId: 'm-unscored',
        venue: 'Ground 3 · Model Town',
        status: 'scheduled',
        scheduledStartTime:
            DateTime.now().add(const Duration(hours: 4, minutes: 30)),
        teamAId: 'team-3',
        teamAName: 'DHA Strikers',
        teamBId: 'team-4',
        teamBName: 'Cantt Lions',
      ),
    ];

    Widget console({List<TournamentLiveMatch>? board}) => ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockTournament)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
            tournamentLiveBoardProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(board ?? buildLiveBoard())),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        );

    // The live pulse dot animates forever, so pumpAndSettle never returns once
    // the board is on screen. Every interaction past this point pumps a fixed
    // number of frames instead.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    Future<void> openLiveOps(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('Live Ops'));
      await settle(tester);
    }

    testWidgets('Live Ops renders the multi-ground board with live scores',
        (tester) async {
      await tester.pumpWidget(console());
      await openLiveOps(tester);

      // Ground header + LIVE pill.
      expect(find.text('GROUND 1 · GADDAFI STADIUM'), findsOneWidget);
      expect(find.text('LIVE · 2ND INNINGS'), findsOneWidget);

      // Both innings lines, in O.B over notation.
      expect(find.text('161/7 (20.0)'), findsOneWidget);
      expect(find.text('142/3 (16.2)'), findsOneWidget);

      // The scorer footer with last-ball staleness.
      expect(find.text('Haris Rauf · scoring'), findsOneWidget);
      expect(find.text('Last ball 40s ago'), findsOneWidget);
      expect(find.text('OPEN SCORER'), findsOneWidget);
      expect(find.text('MATCH OPS'), findsOneWidget);
    });

    testWidgets('an unassigned fixture raises the cream scorer alert',
        (tester) async {
      await tester.pumpWidget(console());
      await openLiveOps(tester);

      expect(find.text('1 MATCH HAS NO SCORER ASSIGNED'), findsOneWidget);
      expect(find.text('FIX'), findsOneWidget);
      expect(find.text('NO SCORER ASSIGNED'), findsOneWidget);
      expect(find.text('ASSIGN'), findsOneWidget);
      expect(find.text('Starts in 4 hours'), findsOneWidget);
    });

    testWidgets('an innings break goes amber and offers the one action that '
        'unblocks it', (tester) async {
      // Artboard 27L: nothing is being scored at the break, so the day's one
      // red belongs to the ground that IS live — this card keeps its ink.
      final broken = TournamentLiveMatch(
        matchId: 'm-break',
        venue: 'Ground 2 · Racecourse',
        status: 'innings_break',
        scheduledStartTime: DateTime(2026, 4, 11, 9),
        teamAId: 'team-a',
        teamAName: 'Lahore Lions',
        teamBId: 'team-b',
        teamBName: 'Faisalabad Falcons',
        scorerId: 'scorer-1',
        scorerName: 'Ali',
        inningsLines: const [
          LiveInningsLine(
            inningsNumber: 1,
            battingTeamId: 'team-a',
            runs: 185,
            wickets: 6,
            legalBalls: 120,
          ),
        ],
      );

      await tester.pumpWidget(console(board: [buildLiveBoard()[0], broken]));
      await openLiveOps(tester);

      expect(find.text('INNINGS BREAK'), findsOneWidget);
      expect(find.text('Start 2nd Innings'), findsOneWidget);
      // The side yet to bat has a target, which beats "Yet to bat".
      expect(find.text('Target 186 in 20'), findsOneWidget);
    });

    testWidgets('the Actions menu offers the rain sheet once play is under way',
        (tester) async {
      await tester.pumpWidget(console());
      await openLiveOps(tester);

      await tester.tap(find.text('MATCH OPS'));
      await settle(tester);

      // Artboards 27m / 28b reached from the per-match menu.
      expect(find.text('Revise match conditions'), findsOneWidget);
      // And the officials destination artboard 27 had nowhere to send you.
      expect(find.text('Assign umpires & scorers'), findsOneWidget);
    });

    testWidgets('tournament state counts played and pending fixtures',
        (tester) async {
      await tester.pumpWidget(console());
      await openLiveOps(tester);

      expect(find.text('TOURNAMENT STATE'), findsOneWidget);

      // The tiles sit below the fold once the ground cards carry their own
      // Start Match / Toss action (artboard 27k), and a ListView will not
      // build what it has not laid out — so scroll before asserting.
      await tester.scrollUntilVisible(
        find.text('0 / 2'),
        200,
        scrollable: find.descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.text('0 / 2'), findsOneWidget); // played
      // One ground is live, so the organiser's other queue is what has not
      // started yet rather than what has no result (artboard 27L).
      expect(find.text('AWAITING TOSS'), findsOneWidget);
      // Scoped to the tile: a bare find.text('1') would also match the
      // Registrations tab's pending badge.
      expect(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('AWAITING TOSS'),
                matching: find.byType(Column),
              )
              .first,
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the per-match Actions menu offers the ground-ops verbs',
        (tester) async {
      await tester.pumpWidget(console());
      await openLiveOps(tester);

      await tester.tap(find.text('MATCH OPS'));
      await settle(tester);

      expect(find.text('Change scorer'), findsOneWidget);
      expect(find.text('Currently Haris Rauf'), findsOneWidget);
      expect(find.text('Change ground or time'), findsOneWidget);
      expect(find.text('Declare walkover'), findsOneWidget);
      // A live match can be abandoned; the result is not overridable yet.
      expect(find.text('Abandon match'), findsOneWidget);
      expect(find.text('Override the result'), findsNothing);
    });

    testWidgets('the abandon sheet defaults to reschedule and states the '
        'consequence of each mode', (tester) async {
      await tester.pumpWidget(console());
      await openLiveOps(tester);

      await tester.tap(find.text('MATCH OPS'));
      await settle(tester);
      await tester.tap(find.text('Abandon match'));
      await settle(tester);

      expect(find.text('Reschedule to a new date'), findsOneWidget);
      expect(
        find.textContaining('The scorecard is discarded'),
        findsOneWidget,
      );
      expect(find.text('Declare no result'), findsOneWidget);
      expect(find.textContaining('Points split 1–1'), findsOneWidget);
      // Abandon is the only sheet that spends red on its confirm.
      expect(find.text('Abandon Match'), findsOneWidget);
      expect(find.text('Keep playing'), findsOneWidget);
    });

    testWidgets('the walkover sheet requires a winner before it will confirm',
        (tester) async {
      await tester.pumpWidget(console());
      await openLiveOps(tester);

      await tester.tap(find.text('MATCH OPS'));
      await settle(tester);
      await tester.tap(find.text('Declare walkover'));
      await settle(tester);

      final confirm = find.widgetWithText(ElevatedButton, 'Declare Walkover');
      expect(confirm, findsOneWidget);
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

      // The board behind the sheet renders the same name, so target the
      // sheet's choice card, which is painted last.
      await tester.tap(find.text('Lahore Lions').last);
      await settle(tester);

      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
      // The table effect is spelled out, naming the side that gains.
      expect(
        find.textContaining('neither team’s NRR changes'),
        findsOneWidget,
      );
    });

    testWidgets('before the first ball Live Ops is a readiness checklist',
        (tester) async {
      await tester.pumpWidget(
        console(board: [buildLiveBoard()[1]]), // only the unstarted fixture
      );
      await openLiveOps(tester);

      expect(find.text('MATCHDAY READINESS'), findsOneWidget);
      expect(find.text('1 fixtures scheduled'), findsOneWidget);
      expect(find.text('0 of 1 scorers assigned'), findsOneWidget);
      expect(
        find.text('Live scores appear here on matchday'),
        findsOneWidget,
      );
    });

    testWidgets('a cancelled tournament shows a record, not a workspace',
        (tester) async {
      final cancelled = Tournament(
        id: 'tourn-console-1',
        name: 'Lahore Champions Trophy',
        type: TournamentType.knockout,
        status: TournamentStatus.cancelled,
        privacy: TournamentPrivacy.public,
        createdBy: 'org-user-1',
        organizers: const ['org-user-1'],
        venues: const [],
        rules: const {
          'cancelled_reason': 'Ground flooded, no replacement venue.',
        },
        entryFee: 5000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(mockUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(cancelled)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This tournament was cancelled'), findsOneWidget);
      expect(
        find.text('“Ground flooded, no replacement venue.”'),
        findsOneWidget,
      );
      expect(find.text('WHAT WAS KEPT'), findsOneWidget);
      // The tabs are gone — there is nothing left to manage.
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('co-organizer cannot cancel tournament from console menu',
        (tester) async {
      final coOrgUser = User(
        id: const UserId('co-org-user-99'),
        email: Email.create('coorg@example.com').getOrElse((_) => throw Exception()),
        displayName: 'Co Organizer',
      );

      final tournamentWithCoOrg = Tournament(
        id: 'tourn-console-1',
        name: 'Lahore Champions Trophy',
        type: TournamentType.knockout,
        status: TournamentStatus.registration,
        privacy: TournamentPrivacy.public,
        createdBy: 'org-user-1', // creator is org-user-1, not co-org-user-99
        organizers: const ['org-user-1', 'co-org-user-99'],
        venues: const [TournamentVenue(name: 'Gaddafi Stadium', city: 'Lahore')],
        city: 'Lahore',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentsRepositoryProvider.overrideWithValue(repo),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(coOrgUser)),
            tournamentDetailProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(tournamentWithCoOrg)),
            tournamentRegistrationsProvider('tourn-console-1')
                .overrideWith((ref) => Future.value(mockRegistrations)),
          ],
          child: const MaterialApp(
            home: OrganizerConsoleScreen(tournamentId: 'tourn-console-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap overflow menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Cancel tournament'), findsOneWidget);
      expect(
        find.text('Only the tournament creator can cancel it'),
        findsOneWidget,
      );
    });
  });
}