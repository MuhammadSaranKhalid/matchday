import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/matches/domain/entities/innings_summary.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/providers/matches_board_providers.dart';
import 'package:matchday/features/matches/presentation/widgets/board/board_kit.dart';
import 'package:matchday/features/matches/presentation/widgets/board/match_score_row.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

/// Covers the Matches board — `Matches.dc.html` sections A and B.
void main() {
  Team team(String id, String name) => Team(
        id: TeamId(id),
        ownerId: 'user-1',
        name: name,
        type: TeamType.club,
        privacy: TeamPrivacy.public,
        managers: const ['user-1'],
        primaryColor: '#7A2E2E',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  const format = MatchFormat(
    oversPerInnings: 16,
    playersPerTeam: 11,
    maxOversPerBowler: 4,
    ballType: MatchBallType.tape,
  );

  InningsSummary innings(String teamId, int runs, int wkts, int balls,
          {int n = 1}) =>
      InningsSummary(
        matchId: const MatchId('m1'),
        inningsNumber: n,
        battingTeamId: TeamId(teamId),
        totalRuns: runs,
        totalWickets: wkts,
        legalBallsFaced: balls,
      );

  BoardMatch item({
    MatchStatus status = MatchStatus.live,
    int ballsPerOver = 6,
    List<InningsSummary> summaries = const [],
    String? viewerTeam,
    String? result,
    TeamId? tossWonBy,
    TossDecision? tossDecision,
    DateTime? start,
  }) =>
      BoardMatch(
        match: Match(
          id: const MatchId('m1'),
          teamAId: const TeamId('a'),
          teamBId: const TeamId('b'),
          status: status,
          format: MatchFormat(
            oversPerInnings: format.oversPerInnings,
            playersPerTeam: format.playersPerTeam,
            maxOversPerBowler: format.maxOversPerBowler,
            ballType: format.ballType,
            ballsPerOver: ballsPerOver,
          ),
          matchType: MatchType.friendly,
          createdBy: 'user-1',
          createdAt: DateTime(2026, 1, 1),
          scheduledStartTime: start,
          venue: const Venue(ground: 'Gaddafi B'),
          round: 'Group A',
          resultDescription: result,
          tossWonBy: tossWonBy,
          tossDecision: tossDecision,
        ),
        teamA: team('a', 'Lahore Lions'),
        teamB: team('b', 'Shalimar Riders'),
        innings: summaries,
        viewerTeamId: viewerTeam == null ? null : TeamId(viewerTeam),
      );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: buildCirckTheme(),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  group('MatchScoreRow — the seven states', () {
    testWidgets('live shows scores, overs and the only red on the row',
        (tester) async {
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            summaries: [innings('b', 141, 8, 96, n: 1), innings('a', 104, 4, 75, n: 2)],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('104-4'), findsOneWidget);
      expect(find.text('12.3'), findsOneWidget);
      expect(find.text('141-8'), findsOneWidget);
      expect(find.text('16.0'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('GROUP A · GADDAFI B · 16 OV'), findsOneWidget);
    });

    testWidgets('scheduled carries no pill — the tab already said so',
        (tester) async {
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            status: MatchStatus.scheduled,
            start: DateTime.now().add(const Duration(hours: 3)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SCHEDULED'), findsNothing);
      expect(find.text('LIVE'), findsNothing);
      expect(find.textContaining('Starts'), findsOneWidget);
      // "today at 4:30 PM" — the day lowercases, the meridiem must not.
      expect(find.textContaining(RegExp(r'(AM|PM)')), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('toss says it in words, not a badge', (tester) async {
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            status: MatchStatus.toss,
            tossWonBy: const TeamId('a'),
            tossDecision: TossDecision.bat,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lahore Lions won the toss and will bat'), findsOneWidget);
      expect(find.text('TOSS'), findsNothing);
      // Toss is live: the match is on.
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('innings break names the chase, not just the break',
        (tester) async {
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            status: MatchStatus.inningsBreak,
            summaries: [innings('a', 141, 8, 96)],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('Innings break · Shalimar Riders chase 142 to win'),
        findsOneWidget,
      );
      expect(find.text('INNINGS BREAK'), findsNothing);
    });

    testWidgets('a live chase states what is needed', (tester) async {
      // 16 overs × 6 = 96 balls. Riders made 141; Lions are 104-4 off 75.
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            summaries: [
              innings('b', 141, 8, 96),
              innings('a', 104, 4, 75, n: 2),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Lahore Lions need'), findsOneWidget);
      expect(find.textContaining('38 off 21'), findsOneWidget);
      expect(find.textContaining('6 wickets left'), findsOneWidget);
    });

    testWidgets('a first innings says who batted and who waits',
        (tester) async {
      await pump(
        tester,
        MatchScoreRow(item: item(summaries: [innings('b', 31, 1, 26)])),
      );
      await tester.pump();

      expect(
        find.textContaining(
          'Shalimar Riders opted to bat · Lahore Lions yet to bat',
        ),
        findsOneWidget,
      );
    });

    testWidgets('balls left come from the format, not an assumed six',
        (tester) async {
      // A 5-ball over (The Hundred preset ships in this app): 16 × 5 = 80.
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            ballsPerOver: 5,
            summaries: [
              innings('b', 141, 8, 80),
              innings('a', 104, 4, 60, n: 2),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('38 off 20'), findsOneWidget);
    });

    testWidgets('live with no ball bowled does not invent a score situation',
        (tester) async {
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            tossWonBy: const TeamId('a'),
            tossDecision: TossDecision.bat,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('Lahore Lions won the toss and will bat'),
        findsOneWidget,
      );
      expect(find.textContaining('need'), findsNothing);
    });

    testWidgets('completed makes the result the hero and dims the loser',
        (tester) async {
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            status: MatchStatus.completed,
            result: 'Lions won by 24 runs',
            summaries: [innings('a', 165, 7, 96), innings('b', 141, 9, 96, n: 2)],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lions won by 24 runs'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);

      // The winner's score is ink; the loser's drops to ink-2.
      expect(tester.widget<Text>(find.text('165-7')).style!.color, CkColors.ink);
      expect(tester.widget<Text>(find.text('141-9')).style!.color, CkColors.ink2);
    });

    testWidgets('abandoned is a cream card pill, not a result',
        (tester) async {
      await pump(
        tester,
        MatchScoreRow(
          item: item(
            status: MatchStatus.abandoned,
            result: 'No result — rain',
            summaries: [innings('a', 48, 2, 37)],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No result — rain'), findsOneWidget);
      expect(find.text('ABANDONED'), findsOneWidget);
    });

    testWidgets("the viewer's own team wears a soft YOU and nothing else",
        (tester) async {
      await pump(tester, MatchScoreRow(item: item(viewerTeam: 'a')));
      await tester.pump();

      expect(find.textContaining('YOU'), findsOneWidget);
      // No card chrome, no filter, no section — it marks the team only.
      expect(find.text('YOUR MATCH'), findsNothing);
    });
  });

  group('BoardTabs (artboard 02)', () {
    testWidgets('the live count rides after the word, and vanishes at zero',
        (tester) async {
      await pump(
        tester,
        BoardTabs(
          selected: MatchesBoardTab.live,
          liveCount: 2,
          onSelect: (_) {},
        ),
      );
      expect(find.text('LIVE 2'), findsOneWidget);

      await pump(
        tester,
        BoardTabs(
          selected: MatchesBoardTab.live,
          liveCount: 0,
          onSelect: (_) {},
        ),
      );
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('LIVE 0'), findsNothing);
    });

    testWidgets('caps at 9+ — the tab is not a metric', (tester) async {
      await pump(
        tester,
        BoardTabs(
          selected: MatchesBoardTab.live,
          liveCount: 14,
          onSelect: (_) {},
        ),
      );
      expect(find.text('LIVE 9+'), findsOneWidget);
    });

    testWidgets('the selected tab is ink, never red', (tester) async {
      await pump(
        tester,
        BoardTabs(
          selected: MatchesBoardTab.forYou,
          liveCount: 2,
          onSelect: (_) {},
        ),
      );

      expect(
        tester.widget<Text>(find.text('FOR YOU')).style!.color,
        CkColors.ink,
      );
      expect(
        tester.widget<Text>(find.text('UPCOMING')).style!.color,
        CkColors.muted,
      );
    });

    testWidgets('reports selection', (tester) async {
      MatchesBoardTab? picked;
      await pump(
        tester,
        BoardTabs(
          selected: MatchesBoardTab.live,
          liveCount: 0,
          onSelect: (t) => picked = t,
        ),
      );

      await tester.tap(find.text('FINISHED'));
      await tester.pump();
      expect(picked, MatchesBoardTab.finished);
    });
  });

  group('BoardGroupHeader (artboard 09)', () {
    testWidgets('collapsed keeps the sub-line and gains a live tally',
        (tester) async {
      final group = BoardGroup(
        matches: [item(), item(status: MatchStatus.scheduled)],
      );

      await pump(
        tester,
        BoardGroupHeader(group: group, collapsed: true, onToggle: () {}),
      );
      await tester.pump();

      expect(find.text('1 LIVE'), findsOneWidget);
      expect(find.textContaining('2 FIXTURES'), findsOneWidget);
    });

    testWidgets('a friendly group is named, with no crest', (tester) async {
      final group = BoardGroup(matches: [item()]);

      await pump(
        tester,
        BoardGroupHeader(group: group, collapsed: false, onToggle: () {}),
      );
      await tester.pump();

      expect(find.text('Friendlies'), findsOneWidget);
      expect(find.textContaining('CHALLENGES AND POOL'), findsOneWidget);
      // Singular, not "1 fixtures".
      expect(find.textContaining('1 FIXTURE'), findsOneWidget);
    });
  });
}
