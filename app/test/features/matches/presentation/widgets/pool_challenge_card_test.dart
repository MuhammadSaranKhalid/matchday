import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_request.dart';
import 'package:matchday/features/matches/presentation/providers/matches_feed_providers.dart';
import 'package:matchday/features/matches/presentation/widgets/pool/pool_challenge_card.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

/// Covers the Pool board's challenge card — `Pool.dc.html` artboard 01.
void main() {
  const format = MatchFormat(
    oversPerInnings: 12,
    playersPerTeam: 11,
    maxOversPerBowler: 3,
    ballType: MatchBallType.tape,
  );

  Team team({bool verified = false}) => Team(
        id: const TeamId('team-a'),
        createdBy: 'user-1',
        name: 'Lahore Lions',
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        primaryColor: '#7A2E2E',
        isVerified: verified,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  OpenMatchPoolItem item({
    DateTime? startTime,
    String? venue,
    DateTime? expiresAt,
    bool verified = false,
    MatchBallType ball = MatchBallType.tape,
  }) {
    final request = MatchRequest(
      id: const MatchRequestId('req-1'),
      fromTeamId: const TeamId('team-a'),
      requestedBy: 'user-1',
      status: MatchRequestStatus.pending,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      proposedStartTime: startTime,
      proposedVenue: venue,
      proposedFormat: MatchFormat(
        oversPerInnings: format.oversPerInnings,
        playersPerTeam: format.playersPerTeam,
        maxOversPerBowler: format.maxOversPerBowler,
        ballType: ball,
      ),
      proposalExpiresAt: expiresAt,
    );
    return OpenMatchPoolItem(
      request: request,
      fromTeam: team(verified: verified),
      formatLabel: '12 Overs · TAPE',
      venue: venue ?? '',
      shareCode: '123456',
      timeLabel: '',
    );
  }

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  group('PoolChallengeCard', () {
    testWidgets('states the fixture: team, format line, time, ground, expiry',
        (tester) async {
      final now = DateTime.now();
      await pump(
        tester,
        PoolChallengeCard(
          item: item(
            startTime: DateTime(now.year, now.month, now.day, 16, 30),
            venue: 'Gaddafi B Ground',
            expiresAt: now.add(const Duration(hours: 41, minutes: 5)),
          ),
        ),
      );

      expect(find.text('Lahore Lions'), findsOneWidget);
      expect(find.text('12 OVERS · TAPE-BALL · 11-A-SIDE'), findsOneWidget);
      expect(find.text('Today · 4:30 PM'), findsOneWidget);
      expect(find.text('Gaddafi B Ground'), findsOneWidget);
      expect(find.text('EXPIRES IN 41H'), findsOneWidget);
    });

    testWidgets('carries no kicker and no Open pill — the header says it',
        (tester) async {
      await pump(tester, PoolChallengeCard(item: item()));

      expect(find.text('OPEN CHALLENGE'), findsNothing);
      expect(find.text('Open'), findsNothing);
      expect(find.text('OPEN'), findsNothing);
    });

    testWidgets('drops the meta block and footer when the host left them unset',
        (tester) async {
      await pump(tester, PoolChallengeCard(item: item()));

      expect(find.text('12 OVERS · TAPE-BALL · 11-A-SIDE'), findsOneWidget);
      expect(find.textContaining('EXPIRES IN'), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('an expiry beyond 48h reads in days, not hours',
        (tester) async {
      await pump(
        tester,
        PoolChallengeCard(
          item: item(expiresAt: DateTime.now().add(const Duration(days: 2, minutes: 5))),
        ),
      );

      expect(find.text('EXPIRES IN 2D'), findsOneWidget);
    });

    testWidgets('a lapsed challenge shows no countdown rather than a negative one',
        (tester) async {
      await pump(
        tester,
        PoolChallengeCard(
          item: item(expiresAt: DateTime.now().subtract(const Duration(hours: 1))),
        ),
      );

      expect(find.textContaining('EXPIRES IN'), findsNothing);
    });

    testWidgets('tapping opens the challenge; the dimmed card does not',
        (tester) async {
      var taps = 0;
      await pump(
        tester,
        Column(
          children: [
            PoolChallengeCard(item: item(), onTap: () => taps++),
            PoolChallengeCard(item: item(), dimmed: true, onTap: () => taps++),
          ],
        ),
      );

      await tester.tap(find.text('Lahore Lions').first);
      await tester.pump();
      expect(taps, 1);

      await tester.tap(find.text('Lahore Lions').last);
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('OpenMatchPoolItem board projections', () {
    test('format line names overs, ball and side count', () {
      expect(
        item(ball: MatchBallType.leather).formatLine,
        '12 overs · Leather · 11-a-side',
      );
    });

    test('a blank venue is null, not an empty ground row', () {
      expect(item(venue: '   ').ground, isNull);
      expect(item(venue: 'Model Town Greens').ground, 'Model Town Greens');
    });

    test('ball type drives the Tape-ball / Leather facets', () {
      expect(item().ballType, MatchBallType.tape);
      expect(item(ball: MatchBallType.leather).ballType, MatchBallType.leather);
    });
  });
}
