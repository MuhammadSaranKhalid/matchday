import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/posts/presentation/providers/posts_providers.dart';
import 'package:matchday/features/teams/data/models/team_dto.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';
import 'package:matchday/features/teams/presentation/screens/team_manage_screen.dart';
import 'package:matchday/features/teams/presentation/widgets/team_manage/announcements_manage_tab.dart';
import 'package:matchday/features/teams/presentation/widgets/team_manage/roster_tab.dart';

final _team =
    const TeamDto(
      teamId: 't1',
      createdBy: 'u1',
      teamName: 'Lahore Lions',
      teamType: 'club',
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    ).toEntity();

Widget _app({String? initialTab, bool justCreated = false}) => ProviderScope(
  overrides: [
    // The screen refuses to render for a non-manager (2026-09-10). These
    // tests are about the tab layout, so put the viewer in the owner's chair.
    myTeamRolesProvider.overrideWith(
      (ref) => Stream.value(const {'t1': MemberRole.owner}),
    ),
    teamProvider('t1').overrideWith((ref) => Stream.value(_team)),
    rosterProvider('t1').overrideWith((ref) => Stream.value([])),
    teamPostsProvider('t1').overrideWith((ref) async => []),
  ],
  child: MaterialApp(
    home: TeamManageScreen(
      teamId: 't1',
      initialTab: initialTab,
      justCreated: justCreated,
    ),
  ),
);

void main() {
  testWidgets('Posts comes first and opens by default; Roster still opens', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Posts')).dx,
      lessThan(tester.getTopLeft(find.text('Roster')).dx),
    );
    expect(find.byType(TeamAnnouncementsManageTab), findsOneWidget);

    await tester.tap(find.text('Roster'));
    await tester.pumpAndSettle();
    expect(find.byType(RosterTab), findsOneWidget);
  });

  testWidgets('existing roster deep links still open the player list', (
    tester,
  ) async {
    await tester.pumpWidget(_app(initialTab: 'roster'));
    await tester.pumpAndSettle();
    expect(find.byType(RosterTab), findsOneWidget);
  });

  testWidgets(
    'new team keeps the add-first-player prompt with the player list',
    (tester) async {
      await tester.pumpWidget(_app(justCreated: true));
      await tester.pumpAndSettle();
      expect(find.byType(RosterTab), findsOneWidget);
      expect(
        find.text('Team created. Add your first player below.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Posts'));
      await tester.pumpAndSettle();
      expect(find.byType(TeamAnnouncementsManageTab), findsOneWidget);
      expect(
        find.text('Team created. Add your first player below.'),
        findsNothing,
      );
    },
  );
}
