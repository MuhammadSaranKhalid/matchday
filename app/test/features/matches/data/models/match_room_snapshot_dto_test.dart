import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/data/models/match_room_snapshot_dto.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';

void main() {
  test('decodes canonical room snapshot and match-added provenance', () {
    final dto = MatchRoomSnapshotDto.fromJson(_snapshot());
    final room = dto.toEntity();

    expect(room.revision, 7);
    expect(room.innings, isNull);
    expect(room.participants.single.source, MatchPlayerSource.matchAdded);
    expect(room.capabilities.canAddParticipant, isTrue);
    expect(room.serverTime, DateTime.utc(2026, 9, 21));
  });

  test('missing capabilities fail closed', () {
    final json = _snapshot()..remove('capabilities');
    final room = MatchRoomSnapshotDto.fromJson(json).toEntity();

    expect(room.capabilities.canRecordToss, isFalse);
    expect(room.capabilities.canSetupInnings, isFalse);
    expect(room.capabilities.canAddParticipant, isFalse);
    expect(room.capabilities.canScore, isFalse);
  });
}

Map<String, dynamic> _snapshot() => {
  'revision': 7,
  'server_time': '2026-09-21T00:00:00.000Z',
  'match': {
    'match_id': '13000000-0000-4000-8000-000000000001',
    'team_a_id': '11000000-0000-4000-8000-000000000001',
    'team_b_id': '11000000-0000-4000-8000-000000000002',
    'format': {'overs_per_innings': 20, 'players_per_team': 11},
    'status': 'scheduled',
    'match_type': 'friendly',
    'start_phase': 'lineup',
    'created_by': '10000000-0000-4000-8000-000000000001',
    'created_at': '2026-09-20T00:00:00.000Z',
  },
  'participants': [
    {
      'match_player_id': '15000000-0000-4000-8000-000000000001',
      'match_id': '13000000-0000-4000-8000-000000000001',
      'team_side': 'team_b',
      'unclaimed_id': '16000000-0000-4000-8000-000000000001',
      'display_name': 'Replacement Bowler',
      'source': 'match_added',
      'cricket': {'is_playing_xi': true},
    },
  ],
  'innings': null,
  'capabilities': {
    'can_record_toss': false,
    'can_setup_innings': true,
    'can_add_participant': true,
    'can_score': true,
  },
};
