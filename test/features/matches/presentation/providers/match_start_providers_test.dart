import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/data/models/match_room_snapshot_dto.dart';
import 'package:matchday/features/matches/domain/entities/match_room_snapshot.dart';
import 'package:matchday/features/matches/presentation/controllers/match_room_controller.dart';
import 'package:matchday/features/matches/presentation/providers/match_start_providers.dart';
import 'package:matchday/features/matches/presentation/state/match_room_state.dart';

const _matchId = 'm1';

MatchRoomSnapshot _room({
  required List<Map<String, dynamic>> participants,
}) =>
    MatchRoomSnapshotDto.fromJson({
      'revision': 1,
      'server_time': '2026-09-24T00:00:00.000Z',
      'match': {
        'match_id': _matchId,
        'team_a_id': 'a',
        'team_b_id': 'b',
        'format': <String, dynamic>{},
        'status': 'toss',
        'start_phase': 'lineup',
        'toss_won_by': 'a',
        'toss_decision': 'bat',
        'created_at': '2026-09-24T00:00:00.000Z',
      },
      'participants': participants,
      'capabilities': {
        'can_record_toss': true,
        'can_setup_innings': true,
      },
    }).toEntity();

void main() {
  group('matchStartLineup (pure snapshot projection)', () {
    test('lists the batting side in participants order', () async {
      final room = _room(participants: [
        {
          'match_player_id': 'mp1',
          'match_id': _matchId,
          'team_side': 'team_a',
          'profile_id': 'p1',
          'display_name': 'Imran',
          'jersey_number': 7,
          'is_captain': true,
        },
        {
          'match_player_id': 'mp2',
          'match_id': _matchId,
          'team_side': 'team_a',
          'profile_id': 'p2',
          'display_name': 'Wasim',
          'jersey_number': 10,
        },
      ]);

      final container = ProviderContainer.test(
        overrides: [
          matchRoomControllerProvider(_matchId).overrideWith(
            () => _TestMatchRoomController(MatchRoomState(snapshot: room)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(matchRoomControllerProvider(_matchId).future);
      final candidates = container.read(matchStartLineupProvider(_matchId));

      expect(candidates.map((c) => c.name), ['Imran', 'Wasim']);
      expect(candidates.map((c) => c.refId), ['p1', 'p2']);
      expect(candidates.first.isCaptain, isTrue);
      expect(candidates.first.jersey, 7);
    });

    test('excludes the bowling side', () async {
      final room = _room(participants: [
        {
          'match_player_id': 'mp1',
          'match_id': _matchId,
          'team_side': 'team_a',
          'profile_id': 'p1',
          'display_name': 'Imran',
        },
        {
          'match_player_id': 'mp9',
          'match_id': _matchId,
          'team_side': 'team_b',
          'profile_id': 'opp-1',
          'display_name': 'Opponent',
        },
      ]);

      final container = ProviderContainer.test(
        overrides: [
          matchRoomControllerProvider(_matchId).overrideWith(
            () => _TestMatchRoomController(MatchRoomState(snapshot: room)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(matchRoomControllerProvider(_matchId).future);
      final candidates = container.read(matchStartLineupProvider(_matchId));

      expect(candidates.map((c) => c.refId), ['p1']);
    });

    test('matchStartBowlingLineup lists the fielding side', () async {
      final room = _room(participants: [
        {
          'match_player_id': 'mp1',
          'match_id': _matchId,
          'team_side': 'team_a',
          'profile_id': 'p1',
          'display_name': 'Imran',
        },
        {
          'match_player_id': 'mp9',
          'match_id': _matchId,
          'team_side': 'team_b',
          'profile_id': 'opp-1',
          'display_name': 'Shoaib',
          'jersey_number': 14,
        },
      ]);

      final container = ProviderContainer.test(
        overrides: [
          matchRoomControllerProvider(_matchId).overrideWith(
            () => _TestMatchRoomController(MatchRoomState(snapshot: room)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(matchRoomControllerProvider(_matchId).future);
      final candidates =
          container.read(matchStartBowlingLineupProvider(_matchId));

      expect(candidates.map((c) => c.refId), ['opp-1']);
      expect(candidates.single.name, 'Shoaib');
      expect(candidates.single.jersey, 14);
    });
  });
}

class _TestMatchRoomController extends MatchRoomController {
  _TestMatchRoomController(this._initial);
  final MatchRoomState _initial;

  @override
  Future<MatchRoomState> build(String matchId) async => _initial;
}
