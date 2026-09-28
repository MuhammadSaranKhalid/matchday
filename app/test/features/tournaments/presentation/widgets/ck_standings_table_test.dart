import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_standing.dart';
import 'package:matchday/features/tournaments/presentation/widgets/ck_standings_table.dart';

void main() {
  group('CkStandingsTable widget tests', () {
    final standings = [
      TournamentStanding(
        tournamentId: 't-1',
        teamId: 'team-1',
        teamName: 'Model Town CC',
        matchesPlayed: 3,
        wins: 3,
        losses: 0,
        ties: 0,
        noResults: 0,
        points: 6,
        runsScored: 540,
        oversFaced: 60.0,
        runsConceded: 420,
        oversBowled: 60.0,
        netRunRate: 2.000,
        updatedAt: DateTime.now(),
      ),
      TournamentStanding(
        tournamentId: 't-1',
        teamId: 'team-2',
        teamName: 'Cantt CC',
        matchesPlayed: 3,
        wins: 2,
        losses: 1,
        ties: 0,
        noResults: 0,
        points: 4,
        runsScored: 490,
        oversFaced: 60.0,
        runsConceded: 450,
        oversBowled: 60.0,
        netRunRate: 0.667,
        updatedAt: DateTime.now(),
      ),
    ];

    testWidgets('renders team rows and qualification cut line',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CkStandingsTable(
              standings: standings,
              qualificationCutRank: 1,
              cutLabel: 'Top 4 advance to semi-finals',
            ),
          ),
        ),
      );

      expect(find.text('Model Town CC'), findsOneWidget);
      expect(find.text('Cantt CC'), findsOneWidget);
      expect(find.text('+2.000'), findsOneWidget);
      expect(find.text('+0.667'), findsOneWidget);
      expect(find.text('TOP 4 ADVANCE TO SEMI-FINALS'),
          findsOneWidget);
    });
  });
}
