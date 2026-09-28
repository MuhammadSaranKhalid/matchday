import 'dart:async';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/realtime/ably_service.dart';
import 'package:matchday/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:matchday/features/matches/data/models/match_room_snapshot_dto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabase extends Mock implements SupabaseClient {}

class _MockAblyService extends Mock implements AblyService {}

class _MockChannel extends Mock implements ably.RealtimeChannel {}

class _TestDataSource extends MatchesRemoteDataSource {
  _TestDataSource(super.supabase, super.ablyService, this.fetch);

  final Future<MatchRoomSnapshotDto> Function() fetch;
  int fetchCount = 0;

  @override
  Future<MatchRoomSnapshotDto> getMatchRoom(String matchId) {
    fetchCount += 1;
    return fetch();
  }
}

void main() {
  late _MockAblyService ablyService;
  late _MockChannel channel;
  late StreamController<ably.Message> events;
  late StreamController<RealtimeConnectionStatus> connections;
  late ChannelLease<ably.RealtimeChannel> lease;

  setUp(() {
    ablyService = _MockAblyService();
    channel = _MockChannel();
    events = StreamController<ably.Message>.broadcast();
    connections = StreamController<RealtimeConnectionStatus>.broadcast();
    lease = ChannelLease<ably.RealtimeChannel>(channel, () async {});
    when(() => ablyService.acquireChannel(any())).thenReturn(lease);
    when(
      () => ablyService.connectionChanges,
    ).thenAnswer((_) => connections.stream);
    when(
      () => channel.subscribe(name: any(named: 'name')),
    ).thenAnswer((_) => events.stream);
  });

  tearDown(() async {
    await events.close();
    await connections.close();
  });

  test('ignores old revisions and reconciles a revision gap once', () async {
    var revision = 4;
    final source = _TestDataSource(
      _MockSupabase(),
      ablyService,
      () async => MatchRoomSnapshotDto.fromJson(_snapshot(revision)),
    );
    final received = <int>[];
    final subscription = source
        .watchMatchRoom('m1')
        .listen((room) => received.add(room.revision));
    await _pump();

    events.add(ably.Message(data: _event(3)));
    await _pump();
    expect(source.fetchCount, 1);

    revision = 7;
    events.add(ably.Message(data: _event(7)));
    await _pump();
    expect(source.fetchCount, 2);
    expect(received, [4, 7]);
    await subscription.cancel();
  });

  test(
    'reconnect refetches and transient failure retains last snapshot',
    () async {
      var revision = 2;
      var fail = false;
      final source = _TestDataSource(_MockSupabase(), ablyService, () async {
        if (fail) throw Exception('offline');
        return MatchRoomSnapshotDto.fromJson(_snapshot(revision));
      });
      final received = <int>[];
      final errors = <Object>[];
      final subscription = source
          .watchMatchRoom('m1')
          .listen((room) => received.add(room.revision), onError: errors.add);
      await _pump();

      fail = true;
      connections.add(RealtimeConnectionStatus.connected);
      await _pump();
      expect(received, [2]);
      expect(errors, hasLength(1));

      fail = false;
      revision = 3;
      connections.add(RealtimeConnectionStatus.connected);
      await _pump();
      expect(received, [2, 3]);
      await subscription.cancel();
    },
  );
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

Map<String, dynamic> _event(int revision) => {
  'eventId': 'event-$revision',
  'matchId': 'm1',
  'revision': revision,
  'eventType': 'match_changed',
  'occurredAt': '2026-09-21T00:00:00.000Z',
};

Map<String, dynamic> _snapshot(int revision) => {
  'revision': revision,
  'server_time': '2026-09-21T00:00:00.000Z',
  'match': {
    'match_id': 'm1',
    'team_a_id': 'a',
    'team_b_id': 'b',
    'format': <String, dynamic>{},
    'status': 'scheduled',
    'created_at': '2026-09-20T00:00:00.000Z',
  },
  'participants': <dynamic>[],
  'capabilities': <String, dynamic>{},
};
