import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/supabase/supabase_current_user_id_provider.dart';
import 'package:matchday/features/matches/data/models/match_room_snapshot_dto.dart';
import 'package:matchday/features/matches/domain/entities/match_room_snapshot.dart';
import 'package:matchday/features/matches/presentation/screens/match_start_screen.dart';
import 'package:matchday/features/matches/presentation/state/match_room_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';

void main() {
  testWidgets('renders toss stage when match is in toss phase', (tester) async {
    final room = _room(startPhase: 'toss', canRecordToss: true);
    final roomState = MatchRoomState(snapshot: room);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          teamProvider('a').overrideWith((ref) async => _team('a', 'Thunder')),
          teamProvider('b').overrideWith((ref) async => _team('b', 'Falcons')),
        ],
        child: MaterialApp(
          home: MatchStartScreen(
            matchId: 'm1',
            room: roomState,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Match hub'), findsOneWidget);
    expect(find.text('Who won the toss?'), findsOneWidget);
    expect(find.text('Thunder'), findsOneWidget);
    expect(find.text('Falcons'), findsOneWidget);
  });

  testWidgets('coin flip is independent and does not auto-select team', (tester) async {
    final room = _room(startPhase: 'toss', canRecordToss: true);
    final roomState = MatchRoomState(snapshot: room);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          teamProvider('a').overrideWith((ref) async => _team('a', 'Thunder')),
          teamProvider('b').overrideWith((ref) async => _team('b', 'Falcons')),
        ],
        child: MaterialApp(
          home: MatchStartScreen(
            matchId: 'm1',
            room: roomState,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap coin to flip
    await tester.tap(find.text('Tap coin to toss'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));

    // Toss outcome is visible (HEADS or TAILS)
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data?.startsWith('TOSS OUTCOME:') ?? false),
      ),
      findsOneWidget,
    );

    // Coin flip does NOT select any team automatically
    expect(find.text('Toss Winner'), findsNothing);

    // User independently taps Thunder to record ground decision
    await tester.tap(find.text('Thunder'));
    await tester.pumpAndSettle();

    expect(find.text('Toss Winner'), findsOneWidget);
  });

  testWidgets('renders waiting card when user cannot record toss', (tester) async {
    final room = _room(startPhase: 'toss', canRecordToss: false);
    final roomState = MatchRoomState(snapshot: room);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          teamProvider('a').overrideWith((ref) async => _team('a', 'Thunder')),
          teamProvider('b').overrideWith((ref) async => _team('b', 'Falcons')),
        ],
        child: MaterialApp(
          home: MatchStartScreen(
            matchId: 'm1',
            room: roomState,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('The assigned official will record the toss'), findsOneWidget);
  });

  testWidgets('renders lineup stage when match is in lineup phase', (tester) async {
    final room = _room(startPhase: 'lineup', canSetupInnings: true);
    final roomState = MatchRoomState(snapshot: room);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          teamProvider('a').overrideWith((ref) async => _team('a', 'Thunder')),
          teamProvider('b').overrideWith((ref) async => _team('b', 'Falcons')),
        ],
        child: MaterialApp(
          home: MatchStartScreen(
            matchId: 'm1',
            room: roomState,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opening players'), findsOneWidget);
    expect(find.text('SWAP ENDS'), findsOneWidget);
  });
}

Team _team(String id, String name) => Team(
      id: TeamId(id),
      createdBy: 'u1',
      name: name,
      type: TeamType.club,
      privacy: TeamPrivacy.public,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

MatchRoomSnapshot _room({
  required String startPhase,
  bool canRecordToss = false,
  bool canSetupInnings = false,
}) =>
    MatchRoomSnapshotDto.fromJson({
      'revision': 1,
      'server_time': '2026-09-24T00:00:00.000Z',
      'match': {
        'match_id': 'm1',
        'team_a_id': 'a',
        'team_b_id': 'b',
        'format': <String, dynamic>{},
        'status': 'scheduled',
        'start_phase': startPhase,
        'toss_won_by': startPhase == 'lineup' ? 'a' : null,
        'toss_decision': startPhase == 'lineup' ? 'bat' : null,
        'created_at': '2026-09-24T00:00:00.000Z',
      },
      'participants': [
        {
          'match_player_id': 'p1',
          'match_id': 'm1',
          'team_side': 'team_a',
          'unclaimed_id': 'u-1',
          'display_name': 'Thunder Player 1',
        },
        {
          'match_player_id': 'p2',
          'match_id': 'm1',
          'team_side': 'team_a',
          'unclaimed_id': 'u-2',
          'display_name': 'Thunder Player 2',
        },
        {
          'match_player_id': 'p3',
          'match_id': 'm1',
          'team_side': 'team_b',
          'unclaimed_id': 'u-3',
          'display_name': 'Falcon Bowler 1',
        },
      ],
      'capabilities': {
        'can_record_toss': canRecordToss,
        'can_setup_innings': canSetupInnings,
      },
    }).toEntity();
