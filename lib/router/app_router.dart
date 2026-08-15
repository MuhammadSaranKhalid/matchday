import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_feed_screen.dart';
import '../features/matches/presentation/screens/matches_v2_screen.dart';
import '../features/messages/presentation/screens/message_thread_screen.dart';
import '../features/profile/presentation/screens/my_profile_screen.dart';
import '../features/profile/presentation/screens/public_profile_screen.dart';
import '../features/messages/presentation/screens/inbox_screen.dart';
import '../features/pavilion/presentation/screens/my_matches_screen.dart';
import '../features/pavilion/presentation/screens/pavilion_match_detail_screen.dart';
import '../features/pavilion/presentation/screens/pavilion_v2_screen.dart';
import '../features/shell/presentation/widgets/app_shell.dart';
import '../features/shell/presentation/widgets/swipeable_branch_view.dart';
import '../features/teams/presentation/screens/add_unclaimed_player_screen.dart';
import '../features/teams/presentation/screens/team_create_screen.dart';
import '../features/teams/presentation/screens/team_page_screen.dart';
import '../features/teams/presentation/screens/team_manage_screen.dart';
import '../features/teams/presentation/screens/team_search_screen.dart';
import '../features/teams/presentation/screens/teams_list_screen.dart';
// Counter flow temporarily disabled — keep import commented for easy restore.
// import '../features/matches/presentation/screens/challenge_counter_screen.dart';
import '../features/matches/presentation/screens/challenge_detail_screen.dart';
import '../features/matches/presentation/screens/challenge_send_screen.dart';
import '../features/matches/presentation/screens/challenge_sent_screen.dart';
import '../features/matches/presentation/screens/match_start_screen.dart';
import '../features/matches/presentation/screens/scoring_screen.dart';
import '../features/matches/presentation/screens/innings_break_screen.dart';
import '../features/matches/presentation/screens/scorecard_screen.dart';
import '../features/matches/presentation/screens/result_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';

part 'app_router.g.dart';

/// Root navigator key — lets Pavilion drill-downs (e.g. My matches) render
/// full-screen over the shell while staying URL-nested under their tab, so the
/// browser URL updates and a web refresh restores the page (with a working
/// back) instead of an imperative push the URL never reflects.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth-aware router.
///
/// The redirect callback reads the current-user stream's latest value.
/// When it flips (sign in / sign out), the router re-evaluates and moves
/// the user accordingly.
///
/// Authenticated users land in the five-tab shell (Home · Search · Matches ·
/// Messages · Pavilion — D9 in docs/search-feature-design.md) via a
/// [StatefulShellRoute] so each tab keeps its own navigation stack. Own
/// profile is a root-level route reached from the header avatar.
/// The onboarding gate (signed-in but profile incomplete → /onboarding) is
/// added in Feature 2 alongside the `profiles` table.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // keepAlive + ref.read inside redirect (NOT ref.watch in the body): the
  // router is built once and the refreshListenable below re-runs `redirect`
  // on each auth change. Watching here would rebuild a whole new GoRouter on
  // every auth event and leak the previous _StreamListenable.
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final user = ref.read(currentUserStreamProvider).value;
      final isSignedIn = user != null;
      final loc = state.matchedLocation;
      final goingToSignIn = loc == '/sign-in';
      final goingToOnboarding = loc == '/onboarding';

      if (!isSignedIn) return goingToSignIn ? null : '/sign-in';

      // Signed in. Gate on onboarding completion (has the user claimed a
      // username?). `.value` is null while the profile status is still
      // loading — don't bounce during that window; the refreshListenable
      // re-runs this redirect once it resolves.
      final onboarded = ref.read(onboardingStatusProvider).value;
      if (onboarded == null) return null;
      if (!onboarded) return goingToOnboarding ? null : '/onboarding';
      if (goingToSignIn || goingToOnboarding) return '/home';
      return null;
    },
    refreshListenable: _StreamListenable(ref),
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        // Lay the five branch navigators out in a PageView so the tabs can be
        // swiped through with a smooth, finger-tracking transition (the
        // default .indexedStack snaps instantly). See SwipeableBranchView.
        navigatorContainerBuilder: (context, navigationShell, children) =>
            SwipeableBranchView(
              navigationShell: navigationShell,
              children: children,
            ),
        branches: [
          // 0 · Home — feed
          // `preload: true` on every branch so a swipe lands on real content
          // immediately instead of a blank page that builds mid-gesture. Each
          // branch's Navigator state is still kept alive across swipes.
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) => HomeFeedScreen(
                  onBell: () => _openBell(context),
                  // Tap an author in the feed → push their public profile
                  // by @username. Defined as `/u/:username` (root-level
                  // route, full-screen over the shell — see below).
                  onOpenProfile: (username) =>
                      context.push('/u/$username'),
                ),
              ),
            ],
          ),
          // 1 · Search — team search & discovery (placeholder until search
          // Slice 3 ships the real screen; see docs/search-feature-design.md).
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, _) =>
                    TeamSearchScreen(onBell: () => _openBell(context)),
              ),
            ],
          ),
          // 2 · Matches — Live · Upcoming · Recent · Browse (the open match
          // pool lands here as the primary sub-tab; see
          // docs/match-pool-feature-design.md D10).
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/matches',
                builder: (context, _) =>
                    MatchesV2Screen(onBell: () => _openBell(context)),
              ),
            ],
          ),
          // 3 · Messages — threads aggregator
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, _) =>
                    InboxScreen(onBell: () => _openBell(context)),
                routes: [
                  // Message thread — rendered full-screen over the shell
                  // (root navigator), URL-nested under /messages so a refresh
                  // or push deep-link restores [Messages → thread] with a
                  // working back. Mirrors the /pavilion/match/:id pattern.
                  GoRoute(
                    path: ':chatId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => MessageThreadScreen(
                      chatId: state.pathParameters['chatId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 4 · Pavilion — workspace (calendar + yours + create)
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/pavilion',
                builder: (context, _) =>
                    PavilionV2Screen(onBell: () => _openBell(context)),
                routes: [
                  // My matches — rendered full-screen over the shell (root
                  // navigator), but URL-nested under /pavilion. Navigated with
                  // `go`, so the address bar updates and a web refresh restores
                  // [Pavilion → My matches] with a working back.
                  GoRoute(
                    path: 'my-matches',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, __) => const MyMatchesScreen(),
                  ),
                  // Match Detail — full-screen over the shell (root navigator),
                  // URL-nested under /pavilion. Resolves the match by id, so a
                  // refresh / deep link restores it with a working back.
                  GoRoute(
                    path: 'match/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => PavilionMatchDetailScreen(
                      matchId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Teams (full-screen, pushed over the shell). Gated by the redirect.
      GoRoute(
        path: '/teams',
        builder: (_, __) => const TeamsListScreen(),
      ),
      GoRoute(
        path: '/teams/create',
        builder: (_, __) => const TeamCreateScreen(),
      ),
      GoRoute(
        path: '/teams/:teamId',
        builder: (_, state) =>
            TeamPageScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/teams/:teamId/manage',
        builder: (_, state) => TeamManageScreen(
          teamId: state.pathParameters['teamId']!,
          justCreated: state.uri.queryParameters['justCreated'] == 'true',
        ),
      ),
      GoRoute(
        path: '/teams/:teamId/add-unclaimed',
        builder: (_, state) => AddUnclaimedPlayerScreen(
          teamId: state.pathParameters['teamId']!,
        ),
      ),
      GoRoute(
        path: '/matches/:matchId/start',
        builder: (_, state) =>
            MatchStartScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/score',
        builder: (_, state) => ScoringScreen(
          matchId: state.pathParameters['matchId']!,
          inningsNumber:
              int.tryParse(state.uri.queryParameters['innings'] ?? '') ?? 1,
        ),
      ),
      GoRoute(
        path: '/matches/:matchId/innings-break',
        builder: (_, state) =>
            InningsBreakScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/scorecard',
        builder: (_, state) =>
            ScorecardScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/result',
        builder: (_, state) =>
            ResultScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenge',
        builder: (_, __) => const ChallengeSendScreen(),
      ),
      GoRoute(
        path: '/teams/:teamId/challenge',
        builder: (_, state) => ChallengeSendScreen(
          fromTeamId: state.pathParameters['teamId']!,
        ),
      ),
      GoRoute(
        path: '/challenges/:requestId',
        builder: (_, state) => ChallengeDetailScreen(
          requestId: state.pathParameters['requestId']!,
        ),
      ),
      GoRoute(
        path: '/challenges/:requestId/sent',
        builder: (_, state) => ChallengeSentScreen(
          requestId: state.pathParameters['requestId']!,
        ),
      ),
      // Counter flow temporarily disabled — restore route + import above to re-enable.
      // GoRoute(
      //   path: '/challenges/:requestId/counter',
      //   builder: (_, state) => ChallengeCounterScreen(
      //     requestId: state.pathParameters['requestId']!,
      //   ),
      // ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      // Own profile — full-screen over the shell, opened from the header
      // avatar in [V2Header]. (The dedicated Profile tab was replaced by the
      // Search tab — D9 in docs/search-feature-design.md.)
      GoRoute(
        path: '/profile',
        builder: (_, __) => const MyProfileScreen(),
      ),
      // Public profile by @username — the landing for a shared
      // `joinmatchday.com/u/<username>` link (universal/app link) and for
      // tapping a user elsewhere. Full-screen over the shell; gated by the
      // auth redirect like every other route.
      GoRoute(
        path: '/u/:username',
        builder: (_, state) =>
            PublicProfileScreen(username: state.pathParameters['username']!),
      ),
    ],
  );
}

/// The header bell (every primary tab) opens the Notifications inbox over the
/// whole shell, including the bottom nav (root navigator).
void _openBell(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
  );
}

/// Poke the router whenever auth OR onboarding status changes, so the redirect
/// re-evaluates (e.g. after the profile-status future resolves, or after the
/// onboarding controller invalidates it on finish).
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(this._ref) {
    _ref.listen(currentUserStreamProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingStatusProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
