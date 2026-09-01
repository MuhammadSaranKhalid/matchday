import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_standing.dart';

void main() {
  group('TournamentStanding entity tests', () {
    test('formattedNrr correctly formats positive, negative, and zero NRR', () {
      final positiveStanding = TournamentStanding(
        tournamentId: 't-1',
        teamId: 'team-1',
        matchesPlayed: 3,
        wins: 3,
        losses: 0,
        ties: 0,
        noResults: 0,
        points: 6,
        runsScored: 520,
        oversFaced: 60.0,
        runsConceded: 410,
        oversBowled: 60.0,
        netRunRate: 1.833,
        updatedAt: DateTime.now(),
      );

      final negativeStanding = positiveStanding.copyWith(netRunRate: -0.654);
      final zeroStanding = positiveStanding.copyWith(netRunRate: 0.0);

      expect(positiveStanding.formattedNrr, equals('+1.833'));
      expect(negativeStanding.formattedNrr, equals('-0.654'));
      expect(zeroStanding.formattedNrr, equals('0.000'));
    });
  });
}
