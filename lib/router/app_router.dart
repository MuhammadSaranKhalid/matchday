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
import '../features/explore/domain/entities/explore_results.dart';
import '../features/explore/presentation/screens/explore_screen.dart';
import '../features/explore/presentation/screens/explore_see_all_screen.dart';
import '../features/teams/presentation/screens/team_search_screen.dart';
import '../features/teams/presentation/screens/teams_list_screen.dart';
// Counter flow temporarily disabled — keep import commented for easy restore.
// import '../features/matches/presentation/screens/challenge_counter_screen.dart';
import '../features/matches/presentation/screens/challenge_detail_screen.dart';
import '../features/matches/presentation/screens/challenge_send_screen.dart';
import '../features/matches/presentation/screens/challenge_sent_screen.dart';
import '../features/matches/presentation/screens/match_start_screen.dart';
import '../features/matches/presentation/screens/my_pool_broadcasts_screen.dart';
import '../features/matches/presentation/screens/open_match_pool_screen.dart';
import '../features/matches/presentation/screens/scoring_screen.dart';
import '../features/matches/presentation/screens/innings_break_screen.dart';
import '../features/matches/presentation/screens/scorecard_screen.dart';
import '../features/matches/presentation/screens/result_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/posts/domain/entities/post.dart';
import '../features/posts/presentation/screens/composer_screen.dart';

part 'app_router.g.dart';

/// Root navigator key — the router's top-level navigator, above the shell.
/// Full-screen routes (Teams, Pavilion, the match lifecycle) live here so they
/// cover the tab bar, and they are declared as real routes rather than
/// imperative pushes so the URL updates and a web refresh restores the page.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth-aware router.
///
/// The redirect callback reads the current-user stream's latest value.
/// When it flips (sign in / sign out), the router re-evaluates and moves
/// the user accordingly.
///
/// Authenticated users land in the five-tab shell (Home · Search · Matches ·
/// Pool · Profile — D9 in docs/search-feature-design.md, amended 2026-08-21
/// when Pool replaced Pavilion in the bar) via a
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
                  // Tap an author in the feed → push their public profile
                  // by @username. Defined as `/u/:username` (root-level
                  // route, full-screen over the shell — see below).
                  onOpenProfile: (username) =>
                      context.push('/u/$username'),
                ),
              ),
            ],
          ),
          // 1 · Explore — unified search + discovery over players, teams and
          // matches (docs/explore-feature-design.md). v1 ships without the
          // proximity surfaces: no coordinates are captured yet, so near-me
          // and city facets would rank an empty dimension.
          //
          // `/search` is retained as a redirect: the path predates Explore and
          // is referenced by the header search shortcut. TeamSearchScreen
          // stays reachable at /search/teams until the geo capture lands and
          // it can be retired into Explore's teams category.
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, _) => ExploreScreen(
                  onOpenTeam: (teamId) => context.push('/teams/$teamId'),
                  onOpenProfile: (username) => context.push('/u/$username'),
                  onOpenMatch: (matchId) => context.push('/matches/$matchId/scorecard'),
                  onCreateTeam: () => context.push('/teams/create'),
                  onSeeAll: (query, category) => context.push(
                    '/explore/all/${category.wireName}?q=${Uri.encodeQueryComponent(query)}',
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'all/:category',
                    builder: (context, state) {
                      final raw = state.pathParameters['category'];
                      // Unknown category in a deep link degrades to teams
                      // rather than throwing — the path is user-reachable.
                      final category = ExploreCategory.values.firstWhere(
                        (c) => c.wireName == raw,
                        orElse: () => ExploreCategory.teams,
                      );
                      return ExploreSeeAllScreen(
                        query: state.uri.queryParameters['q'] ?? '',
                        category: category,
                        onOpenTeam: (teamId) => context.push('/teams/$teamId'),
                        onOpenProfile: (u) => context.push('/u/$u'),
                        onOpenMatch: (matchId) =>
                            context.push('/matches/$matchId/scorecard'),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'teams',
                    builder: (_, __) => const TeamSearchScreen(),
                  ),
                ],
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
                builder: (_, __) => const MatchesV2Screen(),
              ),
            ],
          ),
          // 3 · Pool — the open match pool (matchmaking). Took this slot from
          // Pavilion on 2026-08-21: browsing open fixtures is a daily,
          // discovery-shaped activity that belongs in the bar, whereas
          // Pavilion is a management workspace and now lives behind the
          // Management sheet (a full-screen route — see below).
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/pool',
                builder: (_, __) => const OpenMatchPoolScreen(),
              ),
            ],
          ),
          // 4 · Profile — own profile tab
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const MyProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Pavilion — the management workspace. Full-screen over the shell
      // (reached from the Management sheet) since it gave up its nav tab to
      // the Pool. It renders its own back chevron, so arriving here via `go`
      // (from a post-action redirect) is not a dead end.
      GoRoute(
        path: '/pavilion',
        builder: (_, __) => const PavilionV2Screen(),
        routes: [
          // My matches — URL-nested under /pavilion so a web refresh restores
          // [Pavilion → My matches] with a working back.
          GoRoute(
            path: 'my-matches',
            builder: (_, __) => const MyMatchesScreen(),
          ),
          // Match Detail — resolves the match by id, so a refresh / deep link
          // restores it with a working back.
          GoRoute(
            path: 'match/:id',
            builder: (_, state) => PavilionMatchDetailScreen(
              matchId: state.pathParameters['id']!,
            ),
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
        path: '/matches/:matchId/scoring',
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
      // Legacy location of the pool, kept so older links / pushes still land.
      GoRoute(
        path: '/matches/pool',
        redirect: (_, __) => '/pool',
      ),
      GoRoute(
        path: '/matches/my-broadcasts',
        builder: (_, __) => const MyPoolBroadcastsScreen(),
      ),
      GoRoute(
        path: '/challenge',
        builder: (_, __) => const ChallengeSendScreen(),
      ),
      GoRoute(
        path: '/matches/send-challenge',
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
      // Messages inbox — full-screen over the shell, opened from the header
      // messages button in [V2Header].
      GoRoute(
        path: '/messages',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _) =>
            InboxScreen(onBell: () => _openBell(context), showBack: true),
        routes: [
          // Message thread — rendered full-screen over the shell
          GoRoute(
            path: ':chatId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => MessageThreadScreen(
              chatId: state.pathParameters['chatId']!,
            ),
          ),
        ],
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
      GoRoute(
        path: '/composer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final teamId = state.uri.queryParameters['teamId'];
          final teamName = state.uri.queryParameters['teamName'];
          final teamMono = state.uri.queryParameters['teamMono'];
          return ComposerScreen(
            initialAuthorContext: teamId != null
                ? PostAuthorContext.teamManager
                : PostAuthorContext.personal,
            initialEntityId: teamId,
            initialEntityName: teamName,
            initialEntityMono: teamMono,
          );
        },
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
