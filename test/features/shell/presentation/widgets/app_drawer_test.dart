import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/domain/value_objects/email.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/matches/domain/entities/innings_summary.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_role.dart';
import 'package:matchday/features/matches/domain/repositories/matches_repository.dart';
import 'package:matchday/features/matches/presentation/providers/match_pool_providers.dart';
import 'package:matchday/features/matches/presentation/providers/matches_feed_providers.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/matches/presentation/providers/my_matches_providers.dart';
import 'package:matchday/features/matches/presentation/state/my_matches_view.dart';
import 'package:matchday/features/profile/domain/entities/player_profile.dart';
import 'package:matchday/features/profile/domain/entities/profile.dart';
import 'package:matchday/features/profile/presentation/providers/profile_providers.dart';
import 'package:matchday/features/shell/presentation/widgets/app_drawer.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchesRepo extends Mock implements MatchesRepository {}

const _profile = Profile(
  userId: ProfileUserId('u1'),
  username: 'saran',
  displayName: 'Saran Khalid',
);

MyMatchConfirmed _row({required String id, required bool live}) =>
    MyMatchConfirmed(
      id: id,
      tag: 'Friendly',
      homeTeamId: 'tA',
      awayTeamId: 'tB',
      oversPerInnings: 20,
      ballsPerOver: 6,
      homeShort: 'LL',
      homeColor: const Color(0xFF7A2E2E),
      homeName: 'Lahore Lions',
      awayShort: 'GG',
      awayColor: const Color(0xFF2E5D57),
      awayName: 'Gulberg Giants',
      when: 'Today',
      venue: 'Model Town',
      role: 'Captain · Live',
      roleKind: MatchRoleKind.captain,
      countdown: 'Now',
      urgent: true,
      live: live,
    );

/// The drawer reads the current location off go_router, so it has to be
/// pumped inside a router rather than a bare MaterialApp.
Future<void> _pumpDrawer(
  WidgetTester tester, {
  MyMatchesView view = const MyMatchesView.empty(),
  List<Team> teams = const [],
  List<OpenMatchPoolItem> pool = const [],
  MatchesRepository? matchesRepo,
  Profile profile = _profile,
  double textScale = 1.0,
}) async {
  final email = Email.create('saran@example.com').toOption().toNullable()!;
  final user = User(
    id: const UserId('u1'),
    email: email,
    displayName: 'Saran Khalid',
  );

  // The design's artboard viewport. The panel's row list scrolls, so the
  // default 800×600 test surface would push the account zone below the fold.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // MaterialApp rebuilds MediaQuery from the view, so an ancestor MediaQuery
  // would be discarded — the scale has to be set on the platform dispatcher.
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: AppDrawer()),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserStreamProvider.overrideWith((ref) => Stream.value(user)),
        myProfileProvider.overrideWith((ref) => Future.value(profile)),
        myTeamsProvider.overrideWith((ref) => Stream.value(teams)),
        myMatchesViewProvider.overrideWith((ref) => Future.value(view)),
        myPoolRequestsProvider.overrideWith((ref) => Future.value(pool)),
        if (matchesRepo != null)
          matchesRepositoryProvider.overrideWithValue(matchesRepo),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('identity, the three YOURS rows, the account zone and sign out',
      (tester) async {
    await _pumpDrawer(tester);

    // Identity block.
    expect(find.text('Saran Khalid'), findsOneWidget);
    expect(find.text('@saran'), findsOneWidget);

    // YOURS — personal destinations.
    expect(find.text('My Matches'), findsOneWidget);
    expect(find.text('My Teams'), findsOneWidget);
    expect(find.text('My Pool Requests'), findsOneWidget);

    // ACCOUNT — built out per §5.1 of the brief.
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);

    // NOT BUILT YET — roadmap rows live in their own group now, so an empty
    // account never reads as a broken one.
    expect(find.text('NOT BUILT YET'), findsOneWidget);
    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('Clubs'), findsOneWidget);

    // Help + the two roadmap rows are all honestly inert.
    expect(find.text('SOON'), findsNWidgets(3));

    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('MATCHDAY · v2.0'), findsOneWidget);
  });

  testWidgets('first run furnishes empty rows instead of leaving them bare',
      (tester) async {
    await _pumpDrawer(tester);

    // One orientation note that states the rule of the panel — a sentence,
    // not a button. Nouns only: no create action appears.
    expect(find.text('YOUR SIDE OF MATCHDAY'), findsOneWidget);
    expect(find.text('Fixtures you are playing in'), findsOneWidget);
    expect(find.text('Squads you own or belong to'), findsOneWidget);
    expect(find.text('Open fixtures you posted'), findsOneWidget);

    // Em-dash in each of the three badge slots.
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('a live match is promoted into the hero card, not duplicated',
      (tester) async {
    final repo = _MockMatchesRepo();
    when(() => repo.listInningsForMatches(any())).thenAnswer(
      (_) async => Right<Failure, Map<MatchId, List<InningsSummary>>>({
        const MatchId('m1'): const [
          InningsSummary(
            matchId: MatchId('m1'),
            inningsNumber: 1,
            battingTeamId: TeamId('tB'),
            totalRuns: 154,
            totalWickets: 8,
            legalBallsFaced: 120,
          ),
          InningsSummary(
            matchId: MatchId('m1'),
            inningsNumber: 2,
            battingTeamId: TeamId('tA'),
            totalRuns: 142,
            totalWickets: 6,
            legalBallsFaced: 86,
          ),
        ],
      }),
    );

    await _pumpDrawer(
      tester,
      matchesRepo: repo,
      view: MyMatchesView(
        confirmed: [
          _row(id: 'm1', live: true),
          _row(id: 'm2', live: false),
        ],
        past: const [],
        totalPastCount: 0,
        pendingRequestsCount: 0,
        sent: const [],
      ),
    );

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('14.2 OV'), findsOneWidget);
    expect(find.text('142/6'), findsOneWidget);
    expect(find.text('154'), findsOneWidget);
    // 155 to win, 142 scored, 120 - 86 balls left.
    expect(find.text('NEED 13 OFF 34'), findsOneWidget);

    // The live state is promoted, not duplicated: My Matches drops back to
    // its upcoming count rather than also shouting LIVE NOW. The promoted
    // match is not counted there — it is in progress, not upcoming.
    expect(find.text('LIVE NOW'), findsNothing);
    expect(find.text('1 UPCOMING'), findsOneWidget);
  });

  testWidgets('overflow: 28-char name, long subline and 120% text scale',
      (tester) async {
    await _pumpDrawer(
      tester,
      textScale: 1.2,
      profile: const Profile(
        userId: ProfileUserId('u1'),
        username: 'a_very_long_username',
        displayName: 'Muhammad Abdul-Rehman Q.',
        city: 'Muzaffargarh',
        playerProfile: PlayerProfile(role: PlayerRole.wicketKeeper),
      ),
      view: MyMatchesView(
        confirmed: [for (var i = 0; i < 12; i++) _row(id: 'm$i', live: false)],
        past: const [],
        totalPastCount: 0,
        pendingRequestsCount: 0,
        sent: const [],
      ),
    );

    // Nothing overflows: no RenderFlex assertion anywhere in the panel.
    expect(tester.takeException(), isNull);

    // The label yields; the badge never shrinks or wraps.
    expect(find.text('12 UPCOMING'), findsOneWidget);

    // Rows are min-height, not height — 56 at 1x grows past 60 at 1.2x
    // instead of clipping.
    final rowBox = tester.getSize(
      find
          .ancestor(
            of: find.text('My Matches'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(rowBox.height, greaterThan(60));
  });
}
