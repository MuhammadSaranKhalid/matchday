import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_pool_application.dart';
import 'package:matchday/features/matches/domain/entities/match_request.dart';
import 'package:matchday/features/matches/presentation/providers/match_pool_providers.dart';
import 'package:matchday/features/matches/presentation/providers/matches_feed_providers.dart';
import 'package:matchday/features/matches/presentation/widgets/host/applicant_xi_list.dart';
import 'package:matchday/features/matches/presentation/widgets/host/host_detail_view.dart';
import 'package:matchday/features/matches/presentation/widgets/host/my_challenge_card.dart';
import 'package:matchday/features/teams/domain/entities/roster_member.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';

/// Covers the host's challenge surfaces — `Pool.dc.html` section C
/// (artboards 12, 14, 15, 16).
void main() {
  Team team(String id, String name, {bool verified = false}) => Team(
        id: TeamId(id),
        createdBy: 'user-1',
        name: name,
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        primaryColor: '#7A2E2E',
        isVerified: verified,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  MatchRequest request({
    MatchRequestStatus status = MatchRequestStatus.pending,
    DateTime? startTime,
    String? venue = 'Gaddafi B Ground',
    String? code = '7K2M9Q',
    DateTime? expiresAt,
  }) =>
      MatchRequest(
        id: const MatchRequestId('req-1'),
        fromTeamId: const TeamId('team-host'),
        requestedBy: 'user-1',
        status: status,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        proposedStartTime: startTime,
        proposedVenue: venue,
        proposedFormat: const MatchFormat(
          oversPerInnings: 12,
          playersPerTeam: 11,
          maxOversPerBowler: 3,
          ballType: MatchBallType.tape,
        ),
        shareCode: code,
        proposalExpiresAt: expiresAt,
      );

  MyChallengeRow row({
    int pending = 0,
    Team? opponent,
    MatchRequestStatus status = MatchRequestStatus.pending,
    DateTime? startTime,
  }) =>
      MyChallengeRow(
        item: OpenMatchPoolItem(
          request: request(status: status, startTime: startTime),
          fromTeam: team('team-host', 'Lahore Lions'),
          formatLabel: '',
          venue: '',
          shareCode: '7K2M9Q',
          timeLabel: '',
        ),
        pendingApplicants: pending,
        opponent: opponent,
      );

  MatchPoolApplication application({
    String id = 'app-1',
    PoolApplicationStatus status = PoolApplicationStatus.pending,
    List<String> xi = const [],
    String? message,
    Duration age = const Duration(hours: 2),
  }) =>
      MatchPoolApplication(
        id: id,
        requestId: 'req-1',
        applicantTeamId: const TeamId('team-app'),
        applicantUserId: 'user-2',
        applicantXi: xi,
        message: message,
        status: status,
        createdAt: DateTime.now().subtract(age),
        updatedAt: DateTime.now(),
      );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamProvider('team-host')
                .overrideWith((ref) => Stream.value(team('team-host', 'Lahore Lions'))),
            teamProvider('team-app').overrideWith(
              (ref) => Stream.value(team('team-app', 'Gulberg Giants', verified: true)),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: child),
          ),
        ),
      );

  group('MyChallengeCard (artboard 12)', () {
    testWidgets('marks the challenge as yours and counts pending applicants',
        (tester) async {
      await pump(tester, MyChallengeCard(row: row(pending: 4)));
      await tester.pump();

      expect(find.text('HOSTING'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('APPLICANTS'), findsOneWidget);
      expect(find.text('12 OVERS · TAPE-BALL · 11-A-SIDE'), findsOneWidget);
    });

    testWidgets('shows the share code — a host-only surface', (tester) async {
      await pump(tester, MyChallengeCard(row: row(pending: 1)));
      await tester.pump();

      expect(find.text('7K2M9Q'), findsOneWidget);
      // Singular, not "1 Applicants".
      expect(find.text('APPLICANT'), findsOneWidget);
    });

    testWidgets('says so plainly when nobody has applied', (tester) async {
      await pump(tester, MyChallengeCard(row: row()));
      await tester.pump();

      expect(find.text('NO APPLICANTS YET'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('PastChallengeRow (artboard 12, past · closed)', () {
    testWidgets('an accepted challenge names the opponent and reads Matched',
        (tester) async {
      await pump(
        tester,
        PastChallengeRow(
          row: row(
            status: MatchRequestStatus.accepted,
            opponent: team('team-app', 'Ravi Riders'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('v Ravi Riders'), findsOneWidget);
      expect(find.text('MATCHED'), findsOneWidget);
      expect(find.textContaining('ACCEPTED'), findsOneWidget);
    });

    testWidgets('an expired challenge reads Closed, not Matched',
        (tester) async {
      await pump(
        tester,
        PastChallengeRow(row: row(status: MatchRequestStatus.expired)),
      );
      await tester.pump();

      expect(find.text('CLOSED'), findsOneWidget);
      expect(find.text('MATCHED'), findsNothing);
      expect(find.textContaining('EXPIRED'), findsOneWidget);
    });
  });

  group('HostDetailView (artboards 14 / 15)', () {
    Widget view(List<MatchPoolApplication> apps) => HostDetailView(
          request: request(
            expiresAt: DateTime.now().add(const Duration(hours: 41, minutes: 5)),
          ),
          applications: apps,
          onBack: () {},
          onShare: () {},
          onWithdraw: () {},
          onOpenApplicant: (_) {},
        );

    testWidgets('waiting: spec table, zero count and the code to share',
        (tester) async {
      await pump(tester, view(const []));
      await tester.pump();

      expect(find.text('Your open challenge'), findsOneWidget);
      expect(find.text('HOSTING'), findsOneWidget);
      expect(find.text('FORMAT'), findsOneWidget);
      expect(find.text('WHERE'), findsOneWidget);
      expect(find.text('EXPIRES'), findsOneWidget);
      expect(find.text('IN 41H'), findsOneWidget);
      expect(find.text('APPLICANTS · 0'), findsOneWidget);
      expect(find.text('Waiting for applicants'), findsOneWidget);
      expect(find.text('7K2M9Q'), findsOneWidget);
    });

    testWidgets('one host marker only — no kicker, no banner sentence',
        (tester) async {
      await pump(tester, view(const []));
      await tester.pump();

      expect(find.text('HOSTING'), findsOneWidget);
      expect(find.text('OPEN CHALLENGE POSTED'), findsNothing);
      expect(find.text('Open Pool Broadcast'), findsNothing);
    });

    testWidgets('applicants: a card is a row, not a decision', (tester) async {
      await pump(
        tester,
        view([
          application(
            xi: List.generate(11, (i) => 'p$i'),
            message: 'Keen for a 12-over game.',
          ),
        ]),
      );
      await tester.pump();

      expect(find.text('APPLICANTS · 1'), findsOneWidget);
      expect(find.text('Gulberg Giants'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('REVIEW & DECIDE'), findsOneWidget);
      expect(find.textContaining('FULL SQUAD'), findsOneWidget);

      // The single Accept lives on the applicant screen, never on the row.
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Accept & create match'), findsNothing);
    });

    testWidgets('tapping an applicant opens it', (tester) async {
      MatchPoolApplication? opened;
      await pump(
        tester,
        HostDetailView(
          request: request(),
          applications: [application()],
          onBack: () {},
          onShare: () {},
          onWithdraw: () {},
          onOpenApplicant: (a) => opened = a,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Gulberg Giants'));
      await tester.pump();
      expect(opened?.id, 'app-1');
    });

    testWidgets('Withdraw is a red text link, never a button', (tester) async {
      var withdrew = 0;
      await pump(
        tester,
        HostDetailView(
          request: request(),
          applications: const [],
          onBack: () {},
          onShare: () {},
          onWithdraw: () => withdrew++,
          onOpenApplicant: (_) {},
        ),
      );
      await tester.pump();

      await tester.tap(find.text('WITHDRAW CHALLENGE'));
      await tester.pump();
      expect(withdrew, 1);
    });
  });

  group('resolveXi (artboard 16)', () {
    RosterMember member(String id, String name, MemberRole role) => RosterMember(
          member: TeamMember(
            id: MembershipId('m-$id'),
            teamId: const TeamId('team-app'),
            playerId: id,
            playerType: PlayerType.claimed,
            roles: {role.wire},
            addedBy: 'user-1',
            joinedAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          displayName: name,
        );

    test('marks the captain from the roster and the keeper from the XI', () {
      final entries = resolveXi(
        xi: const ['p1', 'p2', 'p3'],
        roster: [
          member('p1', 'Farhan Malik', MemberRole.captain),
          member('p2', 'Zeeshan Khalid', MemberRole.player),
          member('p3', 'Tariq Aziz', MemberRole.player),
        ],
        keeperId: 'p2',
      );

      expect(entries.map((e) => e.name),
          ['Farhan Malik', 'Zeeshan Khalid', 'Tariq Aziz']);
      expect(entries[0].captain, isTrue);
      expect(entries[1].keeper, isTrue);
      expect(entries[2].captain, isFalse);
      expect(entries[2].keeper, isFalse);
      expect(entries[0].initials, 'FM');
    });

    test('marks nobody as keeper when the XI names none', () {
      // Until 2026-09-10 this fell back to a team-level `wicket_keeper` role.
      // That role is gone: keeping is a per-match job, so the only answer is
      // the keeper the applicant actually nominated for THIS match.
      final entries = resolveXi(
        xi: const ['p1'],
        roster: [member('p1', 'Zeeshan Khalid', MemberRole.player)],
      );
      expect(entries.single.keeper, isFalse);
    });

    test('marks the captain from their roster rung', () {
      final entries = resolveXi(
        xi: const ['p1'],
        roster: [member('p1', 'Zeeshan Khalid', MemberRole.captain)],
      );
      expect(entries.single.captain, isTrue);
    });

    test('keeps a row for an id the roster cannot resolve', () {
      final entries = resolveXi(xi: const ['ghost'], roster: const []);
      expect(entries, hasLength(1));
      expect(entries.single.name, 'Unnamed player');
    });
  });

  group('ApplicantXiList (artboard 16)', () {
    testWidgets('collapses a long XI and expands on tap', (tester) async {
      final entries = [
        for (var i = 1; i <= 11; i++)
          XiEntry(name: 'Player $i', initials: 'P$i', captain: i == 1),
      ];

      await pump(tester, SingleChildScrollView(
        child: ApplicantXiList(entries: entries),
      ));

      expect(find.text('Player 4'), findsOneWidget);
      expect(find.text('Player 5'), findsNothing);
      expect(find.text('+ 7 MORE'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      await tester.tap(find.text('+ 7 MORE'));
      await tester.pump();

      expect(find.text('Player 11'), findsOneWidget);
      expect(find.text('+ 7 MORE'), findsNothing);
    });
  });

  group('applicantSummary', () {
    test('names the count, or says the squad is full', () {
      expect(
        applicantSummary(
          application(xi: List.generate(11, (i) => 'p$i')),
          playersPerSide: 11,
        ),
        'Full squad · applied 2h ago',
      );
      expect(
        applicantSummary(
          application(xi: const ['a', 'b']),
          playersPerSide: 11,
        ),
        '2 named · applied 2h ago',
      );
      expect(
        applicantSummary(application(), playersPerSide: 11),
        'No XI named · applied 2h ago',
      );
    });
  });
}
