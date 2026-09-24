import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/matches/data/models/match_room_snapshot_dto.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_room_snapshot.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/controllers/match_room_controller.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/state/match_room_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements MatchesRepository {}

void main() {
  late _MockRepository repository;
  late StreamController<MatchRoomSnapshot> rooms;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const MatchId('m1'));
  });

  setUp(() {
    repository = _MockRepository();
    rooms = StreamController<MatchRoomSnapshot>.broadcast();
    when(
      () => repository.watchMatchRoom(any()),
    ).thenAnswer((_) => rooms.stream);
    container = ProviderContainer(
      overrides: [matchesRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await rooms.close();
  });

  test('adopts command response and emits scoring navigation once', () async {
    final initial = _room(4);
    final live = _room(5, status: 'live');
    when(
      () => repository.startMatch(
        id: any(named: 'id'),
        strikerId: any(named: 'strikerId'),
        nonStrikerId: any(named: 'nonStrikerId'),
        bowlerId: any(named: 'bowlerId'),
      ),
    ).thenAnswer((_) async => Right(live));

    final keepAlive = container.listen(
      matchRoomControllerProvider('m1'),
      (_, __) {},
    );
    addTearDown(keepAlive.close);
    final future = container.read(matchRoomControllerProvider('m1').future);
    rooms.add(initial);
    await future;
    final controller = container.read(
      matchRoomControllerProvider('m1').notifier,
    );
    controller
      ..selectStriker('p1')
      ..selectNonStriker('p2')
      ..selectBowler('p3');

    await controller.startMatch();
    var state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.snapshot.revision, 5);
    expect(state.navigation, MatchRoomNavigation.scoring);

    controller.consumeNavigation();
    rooms.add(live);
    await _pump();
    state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.navigation, isNull);
  });

  test(
    'failed refresh retains content and reports a non-blocking error',
    () async {
      final initial = _room(2);
      when(
        () => repository.getMatchRoom(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      final keepAlive = container.listen(
        matchRoomControllerProvider('m1'),
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final future = container.read(matchRoomControllerProvider('m1').future);
      rooms.add(initial);
      await future;

      await container
          .read(matchRoomControllerProvider('m1').notifier)
          .refresh();
      final state = container.read(matchRoomControllerProvider('m1')).value!;
      expect(state.snapshot.revision, 2);
      expect(state.isRefreshing, isFalse);
      expect(state.nonBlockingError, isA<NetworkFailure>());
    },
  );

  test('new snapshots preserve still-eligible local trio selections', () async {
    final keepAlive = container.listen(
      matchRoomControllerProvider('m1'),
      (_, __) {},
    );
    addTearDown(keepAlive.close);
    final future = container.read(matchRoomControllerProvider('m1').future);
    rooms.add(_room(1));
    await future;
    final controller = container.read(
      matchRoomControllerProvider('m1').notifier,
    );
    controller
      ..selectStriker('p1')
      ..selectNonStriker('p2')
      ..selectBowler('p3');

    rooms.add(_room(2));
    await _pump();
    final state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.selectedStrikerId, 'p1');
    expect(state.selectedNonStrikerId, 'p2');
    expect(state.selectedBowlerId, 'p3');
  });

  test('explicit refresh adopts updated capabilities even at same revision', () async {
    final initial = _room(2, canRecordToss: false);
    final updated = _room(2, canRecordToss: true);
    when(() => repository.getMatchRoom(any()))
        .thenAnswer((_) async => Right(updated));

    final keepAlive = container.listen(
      matchRoomControllerProvider('m1'),
      (_, __) {},
    );
    addTearDown(keepAlive.close);
    final future = container.read(matchRoomControllerProvider('m1').future);
    rooms.add(initial);
    await future;

    var state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.snapshot.capabilities.canRecordToss, isFalse);

    await container
        .read(matchRoomControllerProvider('m1').notifier)
        .refresh();

    state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.snapshot.capabilities.canRecordToss, isTrue);
  });

  test('realtime event with same or lower revision is not adopted', () async {
    final initial = _room(3, canRecordToss: false);
    final staleRealtime = _room(3, canRecordToss: true);

    final keepAlive = container.listen(
      matchRoomControllerProvider('m1'),
      (_, __) {},
    );
    addTearDown(keepAlive.close);
    final future = container.read(matchRoomControllerProvider('m1').future);
    rooms.add(initial);
    await future;

    rooms.add(staleRealtime);
    await _pump();

    final state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.snapshot.capabilities.canRecordToss, isFalse);
  });

  test('swapBatters swaps striker and non-striker', () async {
    final initial = _room(1);
    final keepAlive = container.listen(
      matchRoomControllerProvider('m1'),
      (_, __) {},
    );
    addTearDown(keepAlive.close);
    final future = container.read(matchRoomControllerProvider('m1').future);
    rooms.add(initial);
    await future;

    final controller =
        container.read(matchRoomControllerProvider('m1').notifier);
    controller
      ..selectStriker('p1')
      ..selectNonStriker('p2');

    controller.swapBatters();
    final state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.selectedStrikerId, 'p2');
    expect(state.selectedNonStrikerId, 'p1');
  });

  test('selecting player as striker clears non-striker if already occupying that slot', () async {
    final initial = _room(1);
    final keepAlive = container.listen(
      matchRoomControllerProvider('m1'),
      (_, __) {},
    );
    addTearDown(keepAlive.close);
    final future = container.read(matchRoomControllerProvider('m1').future);
    rooms.add(initial);
    await future;

    final controller =
        container.read(matchRoomControllerProvider('m1').notifier);
    controller.selectNonStriker('p1');
    var state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.selectedNonStrikerId, 'p1');
    expect(state.selectedStrikerId, isNull);

    controller.selectStriker('p1');
    state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.selectedStrikerId, 'p1');
    expect(state.selectedNonStrikerId, isNull);
  });

  test('selecting player as non-striker clears striker if already occupying that slot', () async {
    final initial = _room(1);
    final keepAlive = container.listen(
      matchRoomControllerProvider('m1'),
      (_, __) {},
    );
    addTearDown(keepAlive.close);
    final future = container.read(matchRoomControllerProvider('m1').future);
    rooms.add(initial);
    await future;

    final controller =
        container.read(matchRoomControllerProvider('m1').notifier);
    controller.selectStriker('p1');
    var state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.selectedStrikerId, 'p1');
    expect(state.selectedNonStrikerId, isNull);

    controller.selectNonStriker('p1');
    state = container.read(matchRoomControllerProvider('m1')).value!;
    expect(state.selectedNonStrikerId, 'p1');
    expect(state.selectedStrikerId, isNull);
  });
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 10));

MatchRoomSnapshot _room(
  int revision, {
  String status = 'scheduled',
  bool canRecordToss = false,
}) =>
    MatchRoomSnapshotDto.fromJson({
      'revision': revision,
      'server_time': '2026-09-21T00:00:00.000Z',
      'match': {
        'match_id': 'm1',
        'team_a_id': 'a',
        'team_b_id': 'b',
        'format': <String, dynamic>{},
        'status': status,
        'created_at': '2026-09-20T00:00:00.000Z',
      },
      'participants': [
        for (final id in ['p1', 'p2', 'p3'])
          {
            'match_player_id': id,
            'match_id': 'm1',
            'team_side': id == 'p3' ? 'team_b' : 'team_a',
            'unclaimed_id': 'u-$id',
            'display_name': id,
          },
      ],
      'capabilities': {
        'can_record_toss': canRecordToss,
      },
    }).toEntity();
