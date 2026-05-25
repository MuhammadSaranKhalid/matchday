import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_feed_screen.dart';
import '../features/matches/presentation/screens/matches_v2_screen.dart';
import '../features/messages/presentation/screens/messages_screen.dart';
import '../features/notifications/presentation/screens/notifications_bell_screen.dart';
import '../features/pavilion/presentation/screens/pavilion_v2_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/shell/presentation/widgets/app_shell.dart';
import '../features/teams/presentation/screens/team_create_screen.dart';
import '../features/teams/presentation/screens/team_hub_screen.dart';
import '../features/teams/presentation/screens/team_manage_screen.dart';
import '../features/matches/presentation/screens/live_match_screen.dart';
import '../features/matches/presentation/screens/match_request_screen.dart';
import '../features/matches/presentation/screens/match_setup_screen.dart';
import '../features/matches/presentation/screens/match_start_screen.dart';
import '../features/matches/presentation/screens/scoring_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/todos/presentation/screens/todos_screen.dart';

part 'app_router.g.dart';

/// Auth-aware router.
///
/// The redirect callback reads the current-user stream's latest value.
/// When it flips (sign in / sign out), the router re-evaluates and moves
/// the user accordingly.
///
/// Authenticated users land in the three-tab shell (HOME · MATCH · PAVILION)
/// via a [StatefulShellRoute] so each tab keeps its own navigation stack.
/// The onboarding gate (signed-in but profile incomplete → /onboarding) is
/// added in Feature 2 alongside the `profiles` table.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // keepAlive + ref.read inside redirect (NOT ref.watch in the body): the
  // router is built once and the refreshListenable below re-runs `redirect`
  // on each auth change. Watching here would rebuild a whole new GoRouter on
  // every auth event and leak the previous _StreamListenable.
  return GoRouter(
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // 0 · Home — feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) => HomeFeedScreen(
                  onBell: () => _openBell(context),
                  onOpenProfile: () => _openSpectatorProfile(context),
                ),
              ),
            ],
          ),
          // 1 · Matches — Live · Upcoming · Recent · Browse
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/matches',
                builder: (context, _) =>
                    MatchesV2Screen(onBell: () => _openBell(context)),
              ),
            ],
          ),
          // 2 · Pavilion — workspace (calendar + yours + create)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pavilion',
                builder: (context, _) =>
                    PavilionV2Screen(onBell: () => _openBell(context)),
              ),
            ],
          ),
          // 3 · Messages — threads aggregator
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, _) =>
                    MessagesScreen(onBell: () => _openBell(context)),
              ),
            ],
          ),
          // 4 · You — profile (self)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(isTab: true),
              ),
            ],
          ),
        ],
      ),
      // Teams (full-screen, pushed over the shell). Gated by the redirect.
      GoRoute(
        path: '/teams/create',
        builder: (_, __) => const TeamCreateScreen(),
      ),
      GoRoute(
        path: '/teams/:teamId',
        builder: (_, state) =>
            TeamHubScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/teams/:teamId/manage',
        builder: (_, state) => TeamManageScreen(
          teamId: state.pathParameters['teamId']!,
          justCreated: state.uri.queryParameters['justCreated'] == 'true',
        ),
      ),
      GoRoute(
        path: '/matches/setup/:teamAId',
        builder: (_, state) =>
            MatchSetupScreen(teamAId: state.pathParameters['teamAId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/request',
        builder: (_, state) =>
            MatchRequestScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/start',
        builder: (_, state) =>
            MatchStartScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/score/:inningsId',
        builder: (_, state) => ScoringScreen(
          matchId: state.pathParameters['matchId']!,
          inningsId: state.pathParameters['inningsId']!,
        ),
      ),
      GoRoute(
        path: '/matches/:matchId/live',
        builder: (_, state) =>
            LiveMatchScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      // Kept reachable as the Clean Architecture / offline-first reference
      // (CLAUDE.md §1). Not surfaced in the bottom nav.
      GoRoute(
        path: '/todos',
        builder: (_, __) => const TodosScreen(),
      ),
    ],
  );
}

/// The header bell (every primary tab) opens the Notifications inbox over the
/// whole shell, including the bottom nav (root navigator).
void _openBell(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => const NotificationsBellScreen()),
  );
}

/// Tapping another user in the feed opens their profile (spectator view).
void _openSpectatorProfile(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => const ProfileScreen(spectator: true)),
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
