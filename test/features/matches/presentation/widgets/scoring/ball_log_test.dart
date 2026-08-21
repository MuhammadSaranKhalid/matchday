import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/scoring_board.dart';

void main() {
  const matchId = MatchId('m1');
  const players = [
    MatchPlayer(
      id: MatchPlayerId('mp1'),
      matchId: matchId,
      teamSide: MatchTeamSide.a,
      profileId: 'p1',
      displayName: 'Saran',
    ),
    MatchPlayer(
      id: MatchPlayerId('mp2'),
      matchId: matchId,
      teamSide: MatchTeamSide.a,
      profileId: 'p2',
      displayName: 'Rizwan',
    ),
    MatchPlayer(
      id: MatchPlayerId('mp3'),
      matchId: matchId,
      teamSide: MatchTeamSide.b,
      profileId: 'p3',
      displayName: 'Muazam',
    ),
    MatchPlayer(
      id: MatchPlayerId('mp4'),
      matchId: matchId,
      teamSide: MatchTeamSide.b,
      profileId: 'p4',
      displayName: 'Ali',
    ),
  ];

  String nameOf(String? refId) {
    if (refId == 'p1') return 'Saran';
    if (refId == 'p2') return 'Rizwan';
    if (refId == 'p3') return 'Muazam';
    if (refId == 'p4') return 'Ali';
    return '—';
  }

  testWidgets('BallLog displays empty state when balls list is empty',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BallLog(balls: []),
        ),
      ),
    );

    expect(find.text('No deliveries recorded yet'), findsOneWidget);
  });

  testWidgets('BallLog groups deliveries by over with bowler attribution',
      (tester) async {
    final balls = [
      // Over 0 by Bowler Ali (mp4)
      const Ball(
        id: BallId('b1'),
        matchId: matchId,
        inningsNumber: 1,
        seq: 1,
        overNumber: 0,
        ballInOver: 1,
        isLegalDelivery: true,
        ballKind: BallKind.legal,
        runsScored: 1,
        extras: 0,
        isWicket: false,
        isFreeHit: false,
        batsmanId: 'mp1',
        bowlerId: 'mp4',
      ),
      const Ball(
        id: BallId('b2'),
        matchId: matchId,
        inningsNumber: 1,
        seq: 2,
        overNumber: 0,
        ballInOver: 2,
        isLegalDelivery: true,
        ballKind: BallKind.legal,
        runsScored: 4,
        extras: 0,
        isWicket: false,
        isFreeHit: false,
        batsmanId: 'mp2',
        bowlerId: 'mp4',
      ),
      // Over 1 by Bowler Muazam (mp3)
      const Ball(
        id: BallId('b3'),
        matchId: matchId,
        inningsNumber: 1,
        seq: 3,
        overNumber: 1,
        ballInOver: 1,
        isLegalDelivery: true,
        ballKind: BallKind.legal,
        runsScored: 2,
        extras: 0,
        isWicket: false,
        isFreeHit: false,
        batsmanId: 'mp1',
        bowlerId: 'mp3',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BallLog(
            balls: balls,
            nameOf: nameOf,
            matchPlayers: players,
          ),
        ),
      ),
    );

    // Over 2 (overNumber 1) is newest, rendered first with Muazam
    expect(find.text('OVER 2'), findsOneWidget);
    expect(find.text('Muazam'), findsOneWidget);

    // Over 1 (overNumber 0) is rendered with Ali and 5 runs (1 + 4)
    expect(find.text('OVER 1'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('5 runs'), findsOneWidget);
  });
}
