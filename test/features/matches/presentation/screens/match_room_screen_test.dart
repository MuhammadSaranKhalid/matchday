import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:matchday/features/matches/data/models/match_room_snapshot_dto.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_room_snapshot.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/controllers/match_room_controller.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/widgets/match_room/match_room_body.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements MatchesRepository {}

void main() {
  late _MockRepository repository;
  late StreamController<MatchRoomSnapshot> rooms;

  setUpAll(() {
    registerFallbackValue(const MatchId('m1'));
  });

  setUp(() {
    repository = _MockRepository();
    rooms = StreamController<MatchRoomSnapshot>.broadcast();
    when(
      () => repository.watchMatchRoom(any()),
    ).thenAnswer((_) => rooms.stream);
  });

  tearDown(() => rooms.close());

  testWidgets('requires complete trio before starting', (tester) async {
    final initial = _room(1);
    when(
      () => repository.startMatch(
        id: any(named: 'id'),
        strikerId: any(named: 'strikerId'),
        nonStrikerId: any(named: 'nonStrikerId'),
        bowlerId: any(named: 'bowlerId'),
      ),
    ).thenAnswer((_) async => Right(_room(2, status: 'live')));
    await _pumpHarness(tester, repository);
    rooms.add(initial);
    await tester.pumpAndSettle();

    FilledButton startButton() => tester.widget(
      find.widgetWithText(FilledButton, 'Start match — first ball'),
    );
    expect(startButton().onPressed, isNull);

    await _select(tester, 'On strike', 'Batter One');
    await _select(tester, 'Non-striker', 'Batter Two');
    expect(startButton().onPressed, isNull);
    await _select(tester, 'Opening bowler', 'Bowler One');
    expect(startButton().onPressed, isNotNull);

    await tester.tap(find.text('Start match — first ball'));
    await tester.pumpAndSettle();
    verify(
      () => repository.startMatch(
        id: any(named: 'id'),
        strikerId: 'p1',
        nonStrikerId: 'p2',
        bowlerId: 'p3',
      ),
    ).called(1);
  });

  testWidgets('scorer can open match-only player form for either side', (
    tester,
  ) async {
    await _pumpHarness(tester, repository);
    rooms.add(_room(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add player for this match'));
    await tester.pumpAndSettle();
    expect(find.text('Add player to this match'), findsOneWidget);
    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('Team B'), findsOneWidget);
    expect(
      find.textContaining('does not change the team roster'),
      findsOneWidget,
    );
  });

  testWidgets(
    'waiting copy identifies the batting side without claiming a lease',
    (tester) async {
      await _pumpHarness(tester, repository);
      rooms.add(_room(1, canSetupInnings: false));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for Team A lineup'), findsOneWidget);
      expect(
        find.text(
          'A scorer authorized for the batting team must select both openers and the opening bowler.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('active scorer'), findsNothing);
    },
  );
}

Future<void> _pumpHarness(WidgetTester tester, MatchesRepository repository) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [matchesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final async = ref.watch(matchRoomControllerProvider('m1'));
              return Scaffold(
                body: async.when(
                  data: (state) => MatchRoomBody(matchId: 'm1', state: state),
                  error: (error, _) => Text('$error'),
                  loading: () => const CircularProgressIndicator(),
                ),
              );
            },
          ),
        ),
      ),
    );

Future<void> _select(WidgetTester tester, String label, String option) async {
  await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

MatchRoomSnapshot _room(
  int revision, {
  String status = 'scheduled',
  bool canSetupInnings = true,
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
        'start_phase': status == 'live' ? 'live' : 'lineup',
        'toss_won_by': 'a',
        'toss_decision': 'bat',
        'created_at': '2026-09-20T00:00:00.000Z',
      },
      'participants': [
        {
          'match_player_id': 'p1',
          'match_id': 'm1',
          'team_side': 'team_a',
          'unclaimed_id': 'u1',
          'display_name': 'Batter One',
        },
        {
          'match_player_id': 'p2',
          'match_id': 'm1',
          'team_side': 'team_a',
          'unclaimed_id': 'u2',
          'display_name': 'Batter Two',
        },
        {
          'match_player_id': 'p3',
          'match_id': 'm1',
          'team_side': 'team_b',
          'unclaimed_id': 'u3',
          'display_name': 'Bowler One',
        },
      ],
      'capabilities': {
        'can_setup_innings': canSetupInnings,
        'can_add_participant': canSetupInnings,
      },
    }).toEntity();
