import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/data/models/tournament_dto.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';

void main() {
  group('TournamentDto serialization tests', () {
    test('TournamentDto fromJson maps to Domain Tournament correctly', () {
      final json = {
        'tournament_id': 'tourn-123',
        'tournament_name': 'Ramadan Night Cup',
        'tournament_type': 'knockout',
        'status': 'registration',
        'privacy': 'public',
        'created_by': 'user-1',
        'organizers': ['user-1'],
        'venues': [
          {'name': 'Model Town Ground', 'city': 'Lahore'}
        ],
        'format': {'max_overs': 10, 'ball_type': 'Tape Ball'},
        'rules': {'min_squad': 11},
        'start_date': '2026-09-01',
        'end_date': '2026-09-07',
        'location': {'city': 'Lahore', 'lat': 31.5204, 'lng': 74.3587},
        'prize_details': 'PKR 100,000',
        'entry_fee': 5000,
        'min_teams': 4,
        'max_teams': 8,
        'approved_teams_count': 6,
        'created_at': '2026-08-25T12:00:00Z',
        'updated_at': '2026-08-25T12:00:00Z',
      };

      final dto = TournamentDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.id, equals('tourn-123'));
      expect(entity.name, equals('Ramadan Night Cup'));
      expect(entity.type, equals(TournamentType.knockout));
      expect(entity.status, equals(TournamentStatus.registration));
      expect(entity.city, equals('Lahore'));
      expect(entity.entryFee, equals(5000.0));
      expect(entity.approvedTeamsCount, equals(6));
      expect(entity.venues.first.name, equals('Model Town Ground'));
    });
  });
}
