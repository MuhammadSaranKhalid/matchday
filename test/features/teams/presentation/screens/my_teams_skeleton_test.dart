import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/widgets/v2/ck_shimmer.dart';
import 'package:matchday/features/teams/presentation/controllers/teams_list_controller.dart';
import 'package:matchday/features/teams/presentation/screens/teams_list_screen.dart';
import 'package:matchday/features/teams/presentation/state/my_teams_view.dart';
import 'package:matchday/features/teams/presentation/widgets/my_teams/crest_palette.dart';
import 'package:matchday/features/teams/presentation/widgets/my_teams/my_teams_shimmer_skeleton.dart';
import 'package:matchday/features/teams/presentation/widgets/team_crest.dart';
import 'package:matchday/features/teams/presentation/widgets/team_create/team_draft_card.dart';

const _vm = TeamRowVm(
  crest: CrestStyle(
    color: Color(0xFF1C4E80),
    mono: 'LL',
    name: 'Lyari Lions',
    city: 'Karachi',
  ),
  role: MyTeamsRole.captain,
  teamId: 't1',
  meta: 'Karachi · 14 players',
);

/// One controller held in loading until the test releases it, so both states
/// are measured in the same tree — which is what "nothing jumps" means.
class _GatedController extends TeamsListController {
  static late Completer<MyTeamsView> gate;

  @override
  Future<MyTeamsView> build() => gate.future;
}

Widget _app() => ProviderScope(
      overrides: [
        teamsListControllerProvider.overrideWith(_GatedController.new),
        teamCreationDraftProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: const MaterialApp(home: TeamsListScreen()),
    );

void main() {
  testWidgets('My Teams loads into a shape-matched skeleton, not a spinner',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    _GatedController.gate = Completer<MyTeamsView>();
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 120));

    // Chrome is real while loading; only the list is skeletal.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MyTeamsShimmerSkeleton), findsOneWidget);
    expect(find.text('My Teams'), findsOneWidget, reason: 'nav title is real');
    expect(find.text('CREATE'), findsOneWidget, reason: 'nav pill stays live');

    final skeletonCrest = tester.getRect(
      find
          .byWidgetPredicate(
            (w) => w is CkShimmerBox && w.shape == BoxShape.circle,
          )
          .first,
    );
    final skeletonChevron =
        tester.getRect(find.byIcon(Icons.chevron_right_rounded).first);

    // Data lands.
    _GatedController.gate
        .complete(const MyTeamsView(teams: TeamGroups(captain: [_vm])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(MyTeamsShimmerSkeleton), findsNothing);
    expect(find.text('Lyari Lions'), findsOneWidget);

    // The skeleton row and the real row occupy the same pixels: the first
    // crest and its chevron must not move when the teams arrive.
    expect(
      tester.getRect(find.byType(TeamCrest).first),
      skeletonCrest,
      reason: 'first crest moved between loading and loaded',
    );
    expect(
      tester.getRect(find.byIcon(Icons.chevron_right_rounded).first),
      skeletonChevron,
      reason: 'chevron moved between loading and loaded',
    );
  });
}
