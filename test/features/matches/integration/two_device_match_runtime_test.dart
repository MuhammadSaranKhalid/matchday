import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/features/matches/data/models/match_room_snapshot_dto.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/domain/entities/match_room_snapshot.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/controllers/match_room_controller.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/state/match_room_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements MatchesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MatchId('match-1'));
    registerFallbackValue(const TeamId('team-a'));
    registerFallbackValue(TossDecision.bat);
    registerFallbackValue(MatchTeamSide.a);
  });

  test(
    'two devices converge through setup, missed events, and start',
    () async {
      final repository = _MockRepository();
      final phoneAEvents = StreamController<MatchRoomSnapshot>.broadcast();
      final phoneBEvents = StreamController<MatchRoomSnapshot>.broadcast();
      addTearDown(phoneAEvents.close);
      addTearDown(phoneBEvents.close);

      var snapshot = _snapshot(
        revision: 1,
        status: 'scheduled',
        startPhase: 'toss',
        participants: const [
          ('a-1', 'team_a', 'Saran opener 1'),
          ('a-2', 'team_a', 'Saran opener 2'),
          ('b-1', 'team_b', 'Hawks bowler'),
          ('b-2', 'team_b', 'Hawks batter'),
        ],
      );
      var watcher = 0;
      var deliverToPhoneB = true;
      var liveTransitions = 0;

      void publish() {
        phoneAEvents.add(snapshot);
        if (deliverToPhoneB) phoneBEvents.add(snapshot);
      }

      when(() => repository.watchMatchRoom(any())).thenAnswer((_) {
        watcher += 1;
        return watcher == 1 ? phoneAEvents.stream : phoneBEvents.stream;
      });
      when(
        () => repository.getMatchRoom(any()),
      ).thenAnswer((_) async => Right(snapshot));
      when(
        () => repository.watchRealtimeStatus(),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => repository.recordToss(
          id: any(named: 'id'),
          wonBy: any(named: 'wonBy'),
          decision: any(named: 'decision'),
          face: any(named: 'face'),
        ),
      ).thenAnswer((_) async {
        snapshot = _copySnapshot(
          snapshot,
          revision: snapshot.revision + 1,
          status: 'toss',
          startPhase: 'lineup',
        );
        publish();
        return Right(snapshot);
      });
      when(
        () => repository.addMatchParticipant(
          id: any(named: 'id'),
          side: any(named: 'side'),
          displayName: any(named: 'displayName'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        final name = invocation.namedArguments[#displayName]! as String;
        snapshot = _copySnapshot(
          snapshot,
          revision: snapshot.revision + 1,
          participants: [
            ..._participantTuples(snapshot),
            ('b-new', 'team_b', name),
          ],
        );
        publish();
        return Right(snapshot);
      });
      when(
        () => repository.startMatch(
          id: any(named: 'id'),
          strikerId: any(named: 'strikerId'),
          nonStrikerId: any(named: 'nonStrikerId'),
          bowlerId: any(named: 'bowlerId'),
        ),
      ).thenAnswer((_) async {
        if (snapshot.match.status != MatchStatus.live) {
          liveTransitions += 1;
          snapshot = _copySnapshot(
            snapshot,
            revision: snapshot.revision + 1,
            status: 'live',
            startPhase: 'live',
            innings: const {
              'match_id': 'match-1',
              'innings_number': 1,
              'version': 1,
              'striker_id': 'a-1',
              'non_striker_id': 'a-2',
              'bowler_id': 'b-new',
              'total_runs': 0,
              'total_wickets': 0,
              'legal_ball_count': 0,
              'updated_at': '2026-09-21T00:00:00.000Z',
            },
          );
          publish();
        }
        return Right(snapshot);
      });

      final phoneA = ProviderContainer(
        overrides: [matchesRepositoryProvider.overrideWithValue(repository)],
      );
      final phoneB = ProviderContainer(
        overrides: [matchesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(phoneA.dispose);
      addTearDown(phoneB.dispose);
      final aLease = phoneA.listen(
        matchRoomControllerProvider('match-1'),
        (_, __) {},
      );
      final bLease = phoneB.listen(
        matchRoomControllerProvider('match-1'),
        (_, __) {},
      );
      addTearDown(aLease.close);
      addTearDown(bLease.close);
      final aReady = phoneA.read(matchRoomControllerProvider('match-1').future);
      final bReady = phoneB.read(matchRoomControllerProvider('match-1').future);
      publish();
      await Future.wait([aReady, bReady]);

      expect(aReady, completes);
      expect(
        phoneA
            .read(matchRoomControllerProvider('match-1'))
            .value!
            .snapshot
            .participants,
        hasLength(4),
      );

      await phoneA
          .read(matchRoomControllerProvider('match-1').notifier)
          .submitToss(wonByTeamId: 'team-a', decision: TossDecision.bat);
      await _pump();
      expect(
        phoneB
            .read(matchRoomControllerProvider('match-1'))
            .value!
            .snapshot
            .match
            .startPhase,
        MatchStartPhase.lineup,
      );

      await phoneA
          .read(matchRoomControllerProvider('match-1').notifier)
          .addParticipant(
            side: MatchTeamSide.b,
            displayName: 'Late Hawks bowler',
          );
      await _pump();
      expect(
        _state(phoneB).snapshot.participants.any(
          (player) => player.displayName == 'Late Hawks bowler',
        ),
        isTrue,
      );

      deliverToPhoneB = false;
      await phoneA
          .read(matchRoomControllerProvider('match-1').notifier)
          .addParticipant(
            side: MatchTeamSide.b,
            displayName: 'Missed substitute',
          );
      expect(_state(phoneB).snapshot.revision, lessThan(snapshot.revision));
      await phoneB
          .read(matchRoomControllerProvider('match-1').notifier)
          .refresh();
      expect(_state(phoneB).snapshot.revision, snapshot.revision);
      deliverToPhoneB = true;

      for (final container in [phoneA, phoneB]) {
        container.read(matchRoomControllerProvider('match-1').notifier)
          ..selectStriker('a-1')
          ..selectNonStriker('a-2')
          ..selectBowler('b-new');
      }
      await Future.wait([
        phoneA
            .read(matchRoomControllerProvider('match-1').notifier)
            .startMatch(),
        phoneB
            .read(matchRoomControllerProvider('match-1').notifier)
            .startMatch(),
      ]);
      await _pump();

      expect(liveTransitions, 1);
      expect(_state(phoneA).snapshot.match.status, MatchStatus.live);
      expect(_state(phoneB).snapshot.match.status, MatchStatus.live);
      expect(_state(phoneA).navigation, MatchRoomNavigation.scoring);
      expect(_state(phoneB).navigation, MatchRoomNavigation.scoring);
    },
  );
}

MatchRoomState _state(ProviderContainer container) =>
    container.read(matchRoomControllerProvider('match-1')).value!;

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 10));

List<(String, String, String)> _participantTuples(MatchRoomSnapshot snapshot) =>
    snapshot.participants
        .map(
          (player) => (
            player.id.value,
            player.teamSide == MatchTeamSide.a ? 'team_a' : 'team_b',
            player.displayName,
          ),
        )
        .toList();

MatchRoomSnapshot _copySnapshot(
  MatchRoomSnapshot previous, {
  required int revision,
  String? status,
  String? startPhase,
  List<(String, String, String)>? participants,
  Map<String, dynamic>? innings,
}) => _snapshot(
  revision: revision,
  status: status ?? previous.match.status.wire,
  startPhase: startPhase ?? previous.match.startPhase.wire,
  participants: participants ?? _participantTuples(previous),
  innings: innings,
);

MatchRoomSnapshot _snapshot({
  required int revision,
  required String status,
  required String startPhase,
  required List<(String, String, String)> participants,
  Map<String, dynamic>? innings,
}) =>
    MatchRoomSnapshotDto.fromJson({
      'revision': revision,
      'server_time': '2026-09-21T00:00:00.000Z',
      'match': {
        'match_id': 'match-1',
        'team_a_id': 'team-a',
        'team_b_id': 'team-b',
        'format': <String, dynamic>{},
        'status': status,
        'start_phase': startPhase,
        'created_at': '2026-09-20T00:00:00.000Z',
      },
      'participants': [
        for (final (id, side, name) in participants)
          {
            'match_player_id': id,
            'match_id': 'match-1',
            'team_side': side,
            'unclaimed_id': 'unclaimed-$id',
            'display_name': name,
          },
      ],
      if (innings != null) 'innings': innings,
      'capabilities': {
        'can_record_toss': true,
        'can_setup_innings': true,
        'can_add_participant': true,
        'can_score': true,
      },
    }).toEntity();
