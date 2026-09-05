import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/explore/data/models/tournament_result_dto.dart';

void main() {
  /// The exact projection `search-all`'s tournament group returns.
  Map<String, dynamic> row({
    Object? entryFee = 15000,
    Map<String, dynamic>? location = const {'city': 'Lahore'},
    int? maxTeams = 8,
    int? approved = 6,
    String? startDate = '2026-04-11',
  }) =>
      <String, dynamic>{
        'tournament_id': 't1',
        'tournament_name': 'Model Town Super Cup',
        'tournament_type': 'knockout',
        'status': 'registration',
        'banner_image_url': null,
        'logo_url': null,
        'start_date': startDate,
        'end_date': '2026-04-16',
        'location': location,
        'entry_fee': entryFee,
        'max_teams': maxTeams,
        'approved_teams_count': approved,
        'score': 0.42,
      };

  group('TournamentResultDto', () {
    test('maps the wire row onto the entity', () {
      final t = TournamentResultDto.fromJson(row()).toEntity();

      expect(t.tournamentId, 't1');
      expect(t.name, 'Model Town Super Cup');
      expect(t.type, 'knockout');
      expect(t.typeLabel, 'Knockout');
      expect(t.status, 'registration');
      expect(t.isRegistrationOpen, isTrue);
      expect(t.isLive, isFalse);
      expect(t.city, 'Lahore');
      expect(t.entryFee, 15000);
      expect(t.startDate, DateTime(2026, 4, 11));
      expect(t.teamsLine, '6 / 8 teams');
    });

    test('accepts entry_fee as a string, which numeric(10,2) may arrive as',
        () {
      final t = TournamentResultDto.fromJson(row(entryFee: '2500.00'))
          .toEntity();
      expect(t.entryFee, 2500.0);
    });

    test('a malformed date does not take the row down', () {
      final t = TournamentResultDto.fromJson(row(startDate: 'not-a-date'))
          .toEntity();
      expect(t.startDate, isNull);
      expect(t.name, 'Model Town Super Cup');
    });

    test('an empty location leaves city null rather than throwing', () {
      final t = TournamentResultDto.fromJson(row(location: const {})).toEntity();
      expect(t.city, isNull);
    });

    test('teamsLine drops the cap when max_teams is null', () {
      final t = TournamentResultDto.fromJson(row(maxTeams: null)).toEntity();
      expect(t.teamsLine, '6 teams');
    });

    test('teamsLine is singular at one and absent at zero-with-no-cap', () {
      expect(
        TournamentResultDto.fromJson(row(maxTeams: null, approved: 1))
            .toEntity()
            .teamsLine,
        '1 team',
      );
      expect(
        TournamentResultDto.fromJson(row(maxTeams: null, approved: 0))
            .toEntity()
            .teamsLine,
        isNull,
      );
    });

    test('an unknown tournament_type degrades to words, not an exception', () {
      final raw = row()..['tournament_type'] = 'swiss_system';
      expect(TournamentResultDto.fromJson(raw).toEntity().typeLabel,
          'swiss system');
    });
  });
}
