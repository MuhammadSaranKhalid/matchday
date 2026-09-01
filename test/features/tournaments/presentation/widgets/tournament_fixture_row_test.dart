import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/tournaments/presentation/widgets/tournament_fixture_row.dart';
import 'package:matchday/features/tournaments/presentation/widgets/tournament_shimmers.dart';

void main() {
  group('TournamentFixtureRow widget tests', () {
    const format = MatchFormat(
      oversPerInnings: 20,
      playersPerTeam: 11,
      maxOversPerBowler: 4,
      ballType: MatchBallType.tape,
    );

    final scheduledMatch = Match(
      id: const MatchId('match-1'),
      tournamentId: 'tourn-1',
      teamAId: const TeamId('team-a'),
      teamBId: const TeamId('team-b'),
      status: MatchStatus.scheduled,
      format: format,
      matchType: MatchType.tournament,
      createdBy: 'user-1',
      scheduledStartTime: DateTime(2026, 8, 30, 16, 0),
      createdAt: DateTime.now(),
    );

    final liveMatch = Match(
      id: const MatchId('match-2'),
      tournamentId: 'tourn-1',
      teamAId: const TeamId('team-a'),
      teamBId: const TeamId('team-b'),
      status: MatchStatus.live,
      format: format,
      matchType: MatchType.tournament,
      createdBy: 'user-1',
      createdAt: DateTime.now(),
    );

    final completedMatch = Match(
      id: const MatchId('match-3'),
      tournamentId: 'tourn-1',
      teamAId: const TeamId('team-a'),
      teamBId: const TeamId('team-b'),
      status: MatchStatus.completed,
      format: format,
      matchType: MatchType.tournament,
      createdBy: 'user-1',
      createdAt: DateTime.now(),
    );

    final abandonedMatch = Match(
      id: const MatchId('match-4'),
      tournamentId: 'tourn-1',
      teamAId: const TeamId('team-a'),
      teamBId: const TeamId('team-b'),
      status: MatchStatus.abandoned,
      format: format,
      matchType: MatchType.tournament,
      createdBy: 'user-1',
      createdAt: DateTime.now(),
    );

    testWidgets('renders scheduled match with teams and time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentFixtureRow(
              match: scheduledMatch,
              teamAName: 'Lahore Qalandars',
              teamBName: 'Karachi Kings',
              stageLabel: 'SEMI-FINAL 1',
            ),
          ),
        ),
      );

      expect(find.text('Lahore Qalandars'), findsOneWidget);
      expect(find.text('Karachi Kings'), findsOneWidget);
      expect(find.text('SEMI-FINAL 1'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);
    });

    testWidgets('renders live match badge with score text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentFixtureRow(
              match: liveMatch,
              teamAName: 'Islamabad United',
              teamBName: 'Peshawar Zalmi',
              scoreText: '142/3 (16.2 ov)',
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('142/3 (16.2 ov)'), findsOneWidget);
    });

    testWidgets('renders completed match badge (FINAL)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentFixtureRow(
              match: completedMatch,
              teamAName: 'Multan Sultans',
              teamBName: 'Quetta Gladiators',
              scoreText: '184/5 v 160/9',
            ),
          ),
        ),
      );

      expect(find.text('FINAL'), findsOneWidget);
      expect(find.text('184/5 v 160/9'), findsOneWidget);
    });

    testWidgets('renders abandoned match badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentFixtureRow(
              match: abandonedMatch,
              teamAName: 'Team A',
              teamBName: 'Team B',
            ),
          ),
        ),
      );

      expect(find.text('ABANDONED'), findsOneWidget);
    });
  });

  group('TournamentShimmers widget tests', () {
    testWidgets('renders card and standings shimmers without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  TournamentCardShimmer(),
                  SizedBox(height: 16),
                  StandingsTableShimmer(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TournamentCardShimmer), findsOneWidget);
      expect(find.byType(StandingsTableShimmer), findsOneWidget);
    });
  });
}
