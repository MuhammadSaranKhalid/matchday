// The innings row reaches the client by two routes that serialise `version`
// (a Postgres bigint) differently, and the DTO has to accept both:
//
//   * the realtime broadcast — built with `to_jsonb(new)` → a JSON NUMBER
//   * the record-ball reply — read over a direct postgres.js connection,
//     which renders bigint as a STRING to avoid JS precision loss
//
// It used to accept only the number. Parsing the reply threw
// `type 'String' is not a subtype of type 'num?'`, the repository turned that
// into a failure, and the delivery was rolled back — so every ball would have
// looked like a failed write while the server had actually recorded it.
//
// Caught by executing the real function against a real database, not by
// reading the code.
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/data/models/match_innings_state_dto.dart';

Map<String, dynamic> _row(Object? version) => {
      'match_id': '33333333-3333-3333-3333-333333333333',
      'innings_number': 1,
      'striker_id': '55555555-0000-0000-0000-00000000000b',
      'non_striker_id': '55555555-0000-0000-0000-00000000000a',
      'bowler_id': '55555555-0000-0000-0000-00000000000c',
      'legal_ball_count': 1,
      'total_runs': 1,
      'total_wickets': 0,
      'total_extras': 0,
      'is_declared': false,
      'is_all_out': false,
      'target': null,
      'version': version,
      'updated_at': '2026-08-20T16:47:40.306Z',
    };

void main() {
  group('version arrives in two shapes', () {
    test('a JSON string, as the record-ball reply sends it', () {
      final dto = MatchInningsStateDto.fromJson(_row('1'));
      expect(dto.version, 1);
      expect(dto.toEntity().version, 1);
    });

    test('a JSON number, as the realtime broadcast sends it', () {
      expect(MatchInningsStateDto.fromJson(_row(1)).version, 1);
    });

    test('the two routes agree, which is what the overlay merge relies on', () {
      // The controller decides which of two innings rows is fresher by
      // comparing versions. If one route parsed to 1 and the other to 0, the
      // server's answer could lose to a stale broadcast.
      expect(
        MatchInningsStateDto.fromJson(_row('7')).version,
        MatchInningsStateDto.fromJson(_row(7)).version,
      );
    });

    test('a large bigint survives the string route', () {
      // The reason postgres.js sends it as a string in the first place.
      expect(MatchInningsStateDto.fromJson(_row('9007199254740993')).version,
          9007199254740993);
    });

    test('a missing or unparseable version degrades to 0, never throws', () {
      // 0 loses every merge comparison, which is the safe direction: the
      // server's real answer wins.
      expect(MatchInningsStateDto.fromJson(_row(null)).version, 0);
      expect(MatchInningsStateDto.fromJson(_row('nonsense')).version, 0);
    });
  });

  test('the rest of the reply parses as sent', () {
    final dto = MatchInningsStateDto.fromJson(_row('1'));
    expect(dto.totalRuns, 1);
    expect(dto.legalBallCount, 1);
    expect(dto.strikerId, '55555555-0000-0000-0000-00000000000b',
        reason: 'strike rotated on the single');
  });
}
