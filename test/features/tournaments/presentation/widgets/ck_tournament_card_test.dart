import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';
import 'package:matchday/features/tournaments/presentation/widgets/ck_tournament_card.dart';

void main() {
  group('CkTournamentCard widget tests', () {
    final testTournament = Tournament(
      id: 'tourn-1',
      name: 'Lahore Premier League',
      type: TournamentType.league,
      status: TournamentStatus.live,
      privacy: TournamentPrivacy.public,
      city: 'Lahore',
      maxTeams: 8,
      approvedTeamsCount: 8,
      organizers: const ['user-1'],
      venues: const [TournamentVenue(name: 'Gaddafi Stadium')],
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    testWidgets('renders standard variant with title, status and city',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CkTournamentCard(
              tournament: testTournament,
              liveScoreText: 'Lions 165/4 (18.2 ov)',
            ),
          ),
        ),
      );

      expect(find.text('Lahore Premier League'), findsOneWidget);
      expect(find.text('LIVE'), findsWidgets);
      expect(find.text('Lahore'), findsOneWidget);
      expect(find.text('8 Teams'), findsOneWidget);
      expect(find.text('Lions 165/4 (18.2 ov)'), findsOneWidget);
    });

    testWidgets('renders compact variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CkTournamentCard(
              tournament: testTournament,
              variant: TournamentCardVariant.compact,
            ),
          ),
        ),
      );

      expect(find.text('Lahore Premier League'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });
  });
}
