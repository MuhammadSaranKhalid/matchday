import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';

void main() {
  group('Tournament entity tests', () {
    test('isOrganizedBy returns true for owner_user_id or created_by', () {
      final tournament = Tournament(
        id: 't-1',
        name: 'Lahore Cup',
        type: TournamentType.knockout,
        status: TournamentStatus.registration,
        privacy: TournamentPrivacy.public,
        createdBy: 'user-1',
        ownerUserId: 'user-2',
        venues: const [TournamentVenue(name: 'Model Town Ground')],
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      expect(tournament.isOrganizedBy('user-2'), isTrue);
      expect(tournament.isOrganizedBy('user-1'), isFalse);
      expect(tournament.isOrganizedBy('user-3'), isFalse);

      final fallbackTournament = Tournament(
        id: 't-2',
        name: 'Karachi Cup',
        type: TournamentType.knockout,
        status: TournamentStatus.registration,
        privacy: TournamentPrivacy.public,
        createdBy: 'user-1',
        venues: const [TournamentVenue(name: 'National Stadium')],
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );
      expect(fallbackTournament.isOrganizedBy('user-1'), isTrue);
    });

    test('TournamentType parsing and labels', () {
      expect(TournamentType.fromWire('knockout'), equals(TournamentType.knockout));
      expect(TournamentType.fromWire('round_robin'), equals(TournamentType.roundRobin));
      expect(TournamentType.fromWire('league'), equals(TournamentType.league));
      expect(TournamentType.fromWire('unknown'), equals(TournamentType.knockout));

      expect(TournamentType.knockout.label, equals('Knockout'));
      expect(TournamentType.roundRobin.label, equals('Round Robin'));
      expect(TournamentType.league.label, equals('League'));
    });

    test('TournamentStatus parsing and labels', () {
      expect(TournamentStatus.fromWire('draft'), equals(TournamentStatus.draft));
      expect(TournamentStatus.fromWire('registration'), equals(TournamentStatus.registration));
      expect(TournamentStatus.fromWire('upcoming'), equals(TournamentStatus.upcoming));
      expect(TournamentStatus.fromWire('live'), equals(TournamentStatus.live));
      expect(TournamentStatus.fromWire('completed'), equals(TournamentStatus.completed));
      expect(TournamentStatus.fromWire('cancelled'), equals(TournamentStatus.cancelled));

      expect(TournamentStatus.live.label, equals('Live'));
      expect(TournamentStatus.completed.label, equals('Completed'));
    });
  });
}
