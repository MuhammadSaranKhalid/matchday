import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/theme/circk_theme.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../core/widgets/ck_push_nav.dart';
import '../core/supabase/supabase_auth_state_provider.dart';
import '../core/supabase/supabase_client_provider.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_feed_screen.dart';
import '../features/matches/presentation/screens/matches_v2_screen.dart';
import '../features/messages/presentation/screens/message_thread_screen.dart';
import '../features/messages/presentation/screens/message_requests_screen.dart';
import '../features/messages/presentation/screens/chat_details_screen.dart';
import '../features/profile/presentation/screens/my_profile_screen.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/profile/presentation/screens/public_profile_screen.dart';
import '../features/messages/presentation/screens/inbox_screen.dart';
import '../features/matches/presentation/screens/match_detail_screen.dart';
import '../features/matches/presentation/screens/my_matches_screen.dart';
import '../features/shell/presentation/screens/menu_screen.dart';
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
import '../features/matches/presentation/screens/applicant_detail_screen.dart';
import '../features/matches/presentation/screens/challenge_detail_screen.dart';
import '../features/matches/presentation/screens/challenge_send_screen.dart';
import '../features/matches/presentation/screens/challenge_sent_screen.dart';
import '../features/matches/presentation/screens/challenges_screen.dart';
import '../features/matches/presentation/screens/my_pool_requests_screen.dart';
import '../features/matches/presentation/screens/open_match_pool_screen.dart';
import '../features/matches/presentation/screens/scoring_screen.dart';
import '../features/matches/presentation/screens/completed_match_screen.dart';
import '../features/matches/presentation/screens/scorecard_screen.dart';
import '../features/matches/presentation/screens/result_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/posts/domain/entities/post.dart';
import '../features/posts/domain/entities/post_draft.dart';
import '../features/posts/presentation/screens/composer_screen.dart';
import '../features/posts/presentation/screens/post_detail_screen.dart';
import '../features/posts/presentation/screens/saved_posts_screen.dart';
import '../features/tournaments/presentation/screens/my_tournaments_screen.dart';
import '../features/tournaments/presentation/screens/tournament_announce_screen.dart';
import '../features/tournaments/presentation/screens/tournament_fee_ledger_screen.dart';
import '../features/tournaments/presentation/screens/tournament_officials_screen.dart';
import '../features/tournaments/presentation/screens/tournament_people_screen.dart';
import '../features/tournaments/presentation/screens/tournament_published_screen.dart';
import '../features/tournaments/presentation/screens/tournament_settings_screen.dart';
import '../features/tournaments/presentation/screens/organizer_console_screen.dart';
import '../features/tournaments/presentation/screens/team_registration_sheet.dart';
import '../features/tournaments/presentation/screens/tournament_create_wizard_screen.dart';
import '../features/tournaments/presentation/screens/tournament_detail_screen.dart';
import '../features/tournaments/presentation/screens/tournament_registration_status_screen.dart';
import '../features/tournaments/presentation/screens/tournament_requests_screen.dart';

part 'app_router.g.dart';

/// Root navigator key — the router's top-level navigator, above the shell.
/// Full-screen routes (Teams, the match lifecycle, profile) live here so they
/// cover the tab bar, and they are declared as real routes rather than
/// imperative pushes so the URL updates and a web refresh restores the page.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth-aware router.
///
/// The redirect callback reads the current-user stream's latest value.
/// When it flips (sign in / sign out), the router re-evaluates and moves
/// the user accordingly.
///
/// Authenticated users land in the four-tab shell (Home · Explore · Matches ·
/// Pool — N5 in docs/navigation-ia-design.md) via a
/// [StatefulShellRoute] so each tab keeps its own navigation stack. Own
/// profile is a root-level route reached from the drawer masthead.
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
      final authAsync = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final goingToSignIn = loc == '/sign-in';
      final goingToOnboarding = loc == '/onboarding';

      return switch (authAsync) {
        // 1. Bootstrapping: Supabase is restoring credentials from device
        // storage. Do not redirect yet; avoid flashing /sign-in prematurely.
        AsyncLoading() => null,

        // 2. Stream/network error (e.g. transient token-refresh failure):
        // - If a user is already authenticated, preserve their current page —
        //   a network hiccup is not a sign-out.
        // - If no user exists (e.g. very first launch), redirect to sign-in.
        AsyncError() =>
          ref.read(supabaseClientProvider).auth.currentUser != null
              ? null
              : goingToSignIn
              ? null
              : '/sign-in',

        // 3. Resolved AuthState:
        AsyncData(:final value) => switch (value.event) {
          AuthChangeEvent.signedOut => goingToSignIn ? null : '/sign-in',
          AuthChangeEvent.initialSession when value.session == null =>
            goingToSignIn ? null : '/sign-in',
          _ when value.session != null => () {
            // Signed in. Gate on onboarding completion (has the user claimed a
            // username?). `.value` is null while the profile status is still
            // loading — don't bounce during that window; the refreshListenable
            // re-runs this redirect once it resolves.
            final onboarded = ref.read(onboardingStatusProvider).value;
            if (onboarded == null) return null;
            if (!onboarded) return goingToOnboarding ? null : '/onboarding';
            if (goingToSignIn || goingToOnboarding) return '/home';
            return null;
          }(),
          _ => null,
        },
      };
    },
    refreshListenable: _StreamListenable(ref),
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      StatefulShellRoute(
        builder:
            (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
        // Lay the four branch navigators out in a PageView so the tabs can be
        // swiped through with a smooth, finger-tracking transition (the
        // default .indexedStack snaps instantly). See SwipeableBranchView.
        navigatorContainerBuilder:
            (context, navigationShell, children) => SwipeableBranchView(
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
                builder:
                    (context, _) => HomeFeedScreen(
                      // Tap an author in the feed → push their public profile
                      // by @username. Defined as `/u/:username` (root-level
                      // route, full-screen over the shell — see below).
                      onOpenProfile: (username) => context.push('/u/$username'),
                    ),
              ),
            ],
          ),
          // 1 · Matches — Live · Upcoming · Recent · Browse
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/matches',
                builder: (_, __) => const MatchesV2Screen(),
              ),
            ],
          ),
          // 2 · Pool — the open match pool (matchmaking).
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/pool',
                builder: (_, __) => const OpenMatchPoolScreen(),
              ),
            ],
          ),
          // 3 · Messages inbox — team chats and direct messages.
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/messages',
                builder:
                    (context, _) => InboxScreen(
                      onBell: () => _openBell(context),
                      showBack: false,
                      showHeader: false,
                    ),
              ),
            ],
          ),
        ],
      ),
      // Explore — unified search + discovery over players, teams and matches
      // Opened full-screen over the shell via the header search bar.
      GoRoute(
        path: '/explore',
        parentNavigatorKey: _rootNavigatorKey,
        builder:
            (context, _) => Scaffold(
              backgroundColor: CkColors.paper,
              body: SafeArea(
                bottom: false,
                child: ExploreScreen(
                  onOpenTeam: (teamId) => context.push('/teams/$teamId'),
                  onOpenProfile: (username) => context.push('/u/$username'),
                  onOpenMatch:
                      (matchId) => context.push('/matches/$matchId/scorecard'),
                  onOpenTournament:
                      (tournamentId) =>
                          context.push('/tournaments/$tournamentId'),
                  onCreateTeam: () => context.push('/teams/create'),
                  onSeeAll:
                      (query, category) => context.push(
                        '/explore/all/${category.wireName}?q=${Uri.encodeQueryComponent(query)}',
                      ),
                ),
              ),
            ),
        routes: [
          GoRoute(
            path: 'all/:category',
            parentNavigatorKey: _rootNavigatorKey,
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
                onOpenMatch:
                    (matchId) => context.push('/matches/$matchId/scorecard'),
                onOpenTournament:
                    (tournamentId) =>
                        context.push('/tournaments/$tournamentId'),
              );
            },
          ),
          // Team search / discovery. TeamSearchScreen was written as a tab
          // body — it returns a bare ColoredBox with no Scaffold — so the
          // route supplies the Scaffold + nav, the same arrangement /explore
          // uses above. Without it the screen's TextField throws "No Material
          // widget found". Reached from the My Teams empty state's
          // "Find a team".
          GoRoute(
            path: 'teams',
            parentNavigatorKey: _rootNavigatorKey,
            builder:
                (context, _) => Scaffold(
                  backgroundColor: CkColors.paper,
                  body: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        CkPushNav(
                          title: 'Find a Team',
                          onBack:
                              () =>
                                  context.canPop()
                                      ? context.pop()
                                      : context.go('/explore'),
                        ),
                        const Expanded(child: TeamSearchScreen()),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
      // The "you" surface — a full-screen page over the shell, pushed by the
      // avatar at the header's left edge. Was a Scaffold.drawer until the
      // drawer's edge-drag proved unwinnable against the tab pager's swipe;
      // see docs/navigation-ia-design.md N12.
      GoRoute(
        path: '/menu',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MenuScreen(),
      ),
      // Own profile (root-level push route over the shell, reached from Menu)
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MyProfileScreen(),
      ),
      // Artboard 1a. A real route rather than a raw Navigator.push, so the
      // screen's own back handling (the discard guard) pops the router stack
      // it was actually pushed onto.
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ProfileEditScreen(),
      ),
      // Menu destinations under `/my/...`
      GoRoute(path: '/my/matches', builder: (_, __) => const MyMatchesScreen()),
      GoRoute(path: '/my/teams', builder: (_, __) => const TeamsListScreen()),
      // Match Challenges queue (Challenges.dc.html). A pushed page: it is a
      // list you work down, not a sheet you return from.
      GoRoute(
        path: '/my/challenges',
        builder: (_, __) => const ChallengesScreen(),
      ),
      GoRoute(
        path: '/my/pool-requests',
        builder: (_, __) => const MyPoolRequestsScreen(),
      ),
      GoRoute(
        path: '/my/tournaments',
        builder: (_, __) => const MyTournamentsScreen(),
      ),
      GoRoute(path: '/tournaments', redirect: (_, __) => '/my/tournaments'),
      GoRoute(
        path: '/tournaments/create',
        builder: (_, __) => const TournamentCreateWizardScreen(),
      ),
      GoRoute(
        path: '/tournaments/:tournamentId',
        builder:
            (_, state) => TournamentDetailScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      GoRoute(
        path: '/tournaments/:tournamentId/manage',
        builder:
            (_, state) => OrganizerConsoleScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      GoRoute(
        path: '/tournaments/:tournamentId/console',
        builder:
            (_, state) => OrganizerConsoleScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      // Artboard 22 — the post-publish screen. pushReplacement'd from the
      // wizard, so Back does not re-enter step 6.
      GoRoute(
        path: '/tournaments/:tournamentId/published',
        builder:
            (_, state) => TournamentPublishedScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      // The three destinations behind the console ⋮ menu (artboards 27d–f).
      GoRoute(
        path: '/tournaments/:tournamentId/settings',
        builder:
            (_, state) => TournamentSettingsScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      GoRoute(
        path: '/tournaments/:tournamentId/announce',
        builder:
            (_, state) => TournamentAnnounceScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      GoRoute(
        path: '/tournaments/:tournamentId/people',
        builder:
            (_, state) => TournamentPeopleScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      // Artboard 24c — the payment reconciliation ledger.
      GoRoute(
        path: '/tournaments/:tournamentId/fees',
        builder:
            (_, state) => TournamentFeeLedgerScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      // Artboard 27j — assign umpires & scorers for one fixture.
      GoRoute(
        path: '/tournaments/:tournamentId/live/:matchId/officials',
        builder:
            (_, state) => TournamentOfficialsScreen(
              tournamentId: state.pathParameters['tournamentId']!,
              matchId: state.pathParameters['matchId']!,
            ),
      ),
      // Artboard 24f — requests as a pushed page.
      GoRoute(
        path: '/tournaments/:tournamentId/requests',
        builder:
            (_, state) => TournamentRequestsScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      GoRoute(
        path: '/tournaments/:tournamentId/register',
        builder:
            (_, state) => TeamRegistrationSheet(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      // Artboard 33 — status tracker + outcomes.
      GoRoute(
        path: '/tournaments/:tournamentId/register/status',
        builder:
            (_, state) => TournamentRegistrationStatusScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
      ),
      // Account settings and saved content.
      GoRoute(
        path: '/saved',
        builder: (_, __) => const SavedPostsScreen(),
      ),
      GoRoute(
        path: '/posts/:postId',
        builder: (_, state) => PostDetailScreen(
          postId: state.pathParameters['postId']!,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      // Legacy redirects for Pavilion and old paths
      GoRoute(
        path: '/pavilion',
        redirect: (_, __) => '/my/matches',
        routes: [
          GoRoute(path: 'my-matches', redirect: (_, __) => '/my/matches'),
          GoRoute(
            path: 'match/:id',
            redirect: (_, state) => '/matches/${state.pathParameters['id']}',
          ),
        ],
      ),
      // Teams redirects & full-screen routes
      GoRoute(path: '/teams', redirect: (_, __) => '/my/teams'),
      GoRoute(
        path: '/teams/create',
        builder: (_, __) => const TeamCreateScreen(),
      ),
      GoRoute(
        path: '/teams/:teamId',
        builder:
            (_, state) =>
                TeamPageScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/teams/:teamId/manage',
        builder:
            (_, state) => TeamManageScreen(
              teamId: state.pathParameters['teamId']!,
              justCreated: state.uri.queryParameters['justCreated'] == 'true',
              // The team page's ⋯ menu sends "Edit team" / "Team settings" and
              // "Invite players" to different tabs of the same console.
              initialTab: state.uri.queryParameters['tab'],
            ),
      ),
      GoRoute(
        path: '/teams/:teamId/add-unclaimed',
        builder:
            (_, state) => AddUnclaimedPlayerScreen(
              teamId: state.pathParameters['teamId']!,
            ),
      ),
      // Literal /matches/<word> routes MUST be declared before
      // '/matches/:matchId'. go_router matches in declaration order, so with
      // the parameterised route first these were being read as a match id and
      // rendering "Match not available" instead of the screen they name.
      GoRoute(
        path: '/matches/send-challenge',
        // ?mode=open comes from the pool surfaces, where the open-vs-direct
        // fork is already answered and should not be asked again.
        builder:
            (_, state) => ChallengeSendScreen(
              openOnly: state.uri.queryParameters['mode'] == 'open',
            ),
      ),
      // Legacy locations, kept so older links / pushes still land.
      GoRoute(path: '/matches/pool', redirect: (_, __) => '/pool'),
      GoRoute(
        path: '/matches/my-broadcasts',
        redirect: (_, __) => '/my/pool-requests',
      ),
      GoRoute(
        path: '/matches/:matchId',
        builder:
            (_, state) =>
                MatchDetailScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/start',
        redirect: (_, state) => '/matches/${state.pathParameters['matchId']!}',
      ),
      GoRoute(
        path: '/matches/:matchId/score',
        builder:
            (_, state) => ScoringScreen(
              matchId: state.pathParameters['matchId']!,
              inningsNumber:
                  int.tryParse(state.uri.queryParameters['innings'] ?? '') ?? 1,
            ),
      ),
      GoRoute(
        path: '/matches/:matchId/scoring',
        builder:
            (_, state) => ScoringScreen(
              matchId: state.pathParameters['matchId']!,
              inningsNumber:
                  int.tryParse(state.uri.queryParameters['innings'] ?? '') ?? 1,
            ),
      ),
      GoRoute(
        path: '/matches/:matchId/innings-break',
        redirect:
            (_, state) =>
                '/matches/${state.pathParameters['matchId']!}/score?innings=1',
      ),
      // The completed-match record. Distinct from /scorecard, which serves
      // matches still in progress: this one derives everything from the final
      // ledger and renders a printed record when no ball was ever bowled.
      GoRoute(
        path: '/matches/:matchId/summary',
        builder:
            (_, state) =>
                CompletedMatchScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/scorecard',
        builder:
            (_, state) =>
                ScorecardScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/matches/:matchId/result',
        builder:
            (_, state) =>
                ResultScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/challenge',
        builder: (_, __) => const ChallengeSendScreen(),
      ),
      GoRoute(
        path: '/teams/:teamId/challenge',
        builder:
            (_, state) => ChallengeSendScreen(
              fromTeamId: state.pathParameters['teamId']!,
            ),
      ),
      GoRoute(
        path: '/challenges/:requestId',
        builder:
            (_, state) => ChallengeDetailScreen(
              requestId: state.pathParameters['requestId']!,
            ),
      ),
      GoRoute(
        path: '/challenges/:requestId/applicants/:applicationId',
        builder:
            (_, state) => ApplicantDetailScreen(
              requestId: state.pathParameters['requestId']!,
              applicationId: state.pathParameters['applicationId']!,
            ),
      ),
      GoRoute(
        path: '/challenges/:requestId/sent',
        builder:
            (_, state) => ChallengeSentScreen(
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
      // Message requests screen
      GoRoute(
        path: '/messages/requests',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MessageRequestsScreen(),
      ),
      // Message thread — rendered full-screen over the shell
      GoRoute(
        path: '/messages/:chatId',
        parentNavigatorKey: _rootNavigatorKey,
        builder:
            (_, state) =>
                MessageThreadScreen(chatId: state.pathParameters['chatId']!),
      ),
      // Chat details screen (team info / DM profile / roster / settings)
      GoRoute(
        path: '/messages/:chatId/details',
        parentNavigatorKey: _rootNavigatorKey,
        builder:
            (_, state) =>
                ChatDetailsScreen(chatId: state.pathParameters['chatId']!),
      ),
      // Public profile by @username — the landing for a shared
      // `joinmatchday.com/u/<username>` link (universal/app link) and for
      // tapping a user elsewhere. Full-screen over the shell; gated by the
      // auth redirect like every other route.
      GoRoute(
        path: '/u/:username',
        builder:
            (_, state) => PublicProfileScreen(
              username: state.pathParameters['username']!,
            ),
      ),
      // Shared-link prefixes. team_share.dart documents the scheme as
      // "/u/ user, /t/ team, /c/ competition"; tournaments had taken /t/ as
      // well, so every shared TEAM link redirected to /tournaments/<teamId>
      // and resolved to nothing. Corrected 2026-09-06: /t/ is teams, as
      // documented, and tournaments move to /c/.
      //
      // Redirects rather than second builders, so /teams/:id and
      // /tournaments/:id each stay the single owner of their surface.
      GoRoute(
        path: '/t/:teamId',
        redirect: (_, state) => '/teams/${state.pathParameters['teamId']}',
      ),
      GoRoute(
        path: '/c/:tournamentId',
        redirect:
            (_, state) =>
                '/tournaments/${state.pathParameters['tournamentId']}',
      ),
      GoRoute(
        path: '/composer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final teamId = state.uri.queryParameters['teamId'];
          final teamName = state.uri.queryParameters['teamName'];
          final teamMono = state.uri.queryParameters['teamMono'];
          final tournamentId = state.uri.queryParameters['tournamentId'];
          final tournamentName = state.uri.queryParameters['tournamentName'];
          final publisher = teamId != null
              ? PostPublisherSelection(
                  type: PostPublisherType.team,
                  id: teamId,
                  name: teamName,
                  monogram: teamMono,
                )
              : (tournamentId != null
                  ? PostPublisherSelection(
                      type: PostPublisherType.tournament,
                      id: tournamentId,
                      name: tournamentName,
                    )
                  : PostPublisherSelection.user);
          return ComposerScreen(initialPublisher: publisher);
        },
      ),
    ],
  );
}

/// The header bell (every primary tab) opens the Notifications inbox over the
/// whole shell, including the bottom nav (root navigator).
void _openBell(BuildContext context) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()));
}

/// Poke the router whenever auth OR onboarding status changes, so the redirect
/// re-evaluates (e.g. after the profile-status future resolves, or after the
/// onboarding controller invalidates it on finish).
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingStatusProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
