// Run explicitly with flutter test tool/store_assets/render_screenshots_test.dart.
// Store assets render production widgets with fictional, local-only fixtures.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/presentation/controllers/scoring_controller.dart';
import 'package:matchday/features/matches/presentation/screens/scoring_screen.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';
import 'package:matchday/features/settings/presentation/screens/settings_screen.dart';
import 'package:matchday/features/safety/presentation/providers/safety_providers.dart';

class DemoScoring extends ScoringController {
  @override
  Future<ScoringState> build(String matchId, int inningsNumber) async {
    final runs = [0, 4, 2, 0, 6, 0, 4, 0, 2, 4];
    final players = [
      for (final (id, name, side) in [
        ('a1', 'Ayan Khan', MatchTeamSide.a),
        ('a2', 'Hamza Ali', MatchTeamSide.a),
        ('b1', 'Bilal Ahmed', MatchTeamSide.b),
      ])
        MatchPlayer(
          id: MatchPlayerId(id),
          matchId: const MatchId('demo'),
          teamSide: side,
          profileId: id,
          displayName: name,
        ),
    ];
    return ScoringState(
      match: Match(
        id: const MatchId('demo'),
        teamAId: const TeamId('a'),
        teamBId: const TeamId('b'),
        format: const MatchFormat(
          oversPerInnings: 10,
          playersPerTeam: 11,
          ballType: MatchBallType.tape,
          maxOversPerBowler: 2,
        ),
        status: MatchStatus.live,
        createdBy: 'demo',
        createdAt: DateTime(2026),
        tossWonBy: const TeamId('a'),
        tossDecision: TossDecision.bat,
        startPhase: MatchStartPhase.live,
      ),
      inningsNumber: 1,
      innings: MatchInningsState(
        matchId: const MatchId('demo'),
        inningsNumber: 1,
        version: 10,
        updatedAt: DateTime(2026),
        strikerId: const MatchPlayerId('a1'),
        nonStrikerId: const MatchPlayerId('a2'),
        bowlerId: const MatchPlayerId('b1'),
        totalRuns: 22,
        legalBallCount: 10,
      ),
      balls: [
        for (var i = 0; i < runs.length; i++)
          Ball(
            id: BallId('ball$i'),
            matchId: const MatchId('demo'),
            inningsNumber: 1,
            seq: i + 1,
            overNumber: i ~/ 6,
            ballInOver: i % 6 + 1,
            isLegalDelivery: true,
            ballKind: BallKind.legal,
            runsScored: runs[i],
            extras: 0,
            isWicket: false,
            isFreeHit: false,
            batsmanId: i < 6 ? 'a1' : 'a2',
            nonStrikerId: i < 6 ? 'a2' : 'a1',
            bowlerId: 'b1',
          ),
      ],
      matchPlayers: players,
      canScore: true,
    );
  }
}

void main() {
  testWidgets('render store phone screenshots from actual screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final (family, file) in [
      ('Inter', 'Inter'),
      ('Inter Tight', 'InterTight'),
      ('JetBrains Mono', 'JetBrainsMono'),
    ]) {
      await (FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$file.ttf'))).load();
    }
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    Future<void> capture(String name, Widget screen) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scoringControllerProvider('demo', 1).overrideWith(DemoScoring.new),
            teamProvider('a').overrideWith(
              (ref) => Stream.value(
                Team(
                  id: const TeamId('a'),
                  createdBy: 'demo',
                  name: 'Lahore Falcons',
                  type: TeamType.club,
                  privacy: TeamPrivacy.public,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ),
            ),
            blockedAccountsProvider.overrideWith((ref) async => []),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildCirckTheme(),
              home: screen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2.75);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/launch/play-store-assets/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('phone-01-scoring', const ScoringScreen(matchId: 'demo'));
    await capture('phone-02-settings', const SettingsScreen());
  });
}
