import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:matchday/router/app_router.dart';

/// Which routes render *over* the four-tab shell and which render *inside* it
/// is invisible until you look at a running screen — and getting it wrong is
/// silent: the page still appears, just wearing the shell's header and bottom
/// nav, so it reads as a fifth tab instead of somewhere you navigated to.
///
/// A route escapes the shell by being declared as a sibling of the
/// [StatefulShellRoute] rather than inside one of its branches. Nesting it a
/// level too deep is a one-line mistake, so this pins the invariant.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(
      overrides: [
        currentUserStreamProvider
            .overrideWith((ref) => Stream<User?>.value(null)),
        onboardingStatusProvider.overrideWith((ref) async => true),
      ],
    );
  });

  /// True when [location] resolves through a shell route — i.e. it renders
  /// inside the [AppShell] chrome rather than on top of it.
  bool isInsideShell(String location) {
    final router = container.read(appRouterProvider);
    final matches = router.configuration.findMatch(Uri.parse(location)).matches;
    return matches.any((m) => m is ShellRouteMatch);
  }

  test('the four tabs render inside the shell', () {
    for (final tab in ['/home', '/matches', '/pool', '/messages']) {
      expect(isInsideShell(tab), isTrue, reason: '$tab should be a shell tab');
    }
  });

  test('full-screen destinations render over the shell, not inside it', () {
    // `/menu` is the "you" surface, pushed by the header's avatar. It carries
    // its own CkPushNav back bar, so if it ever slipped inside the shell the
    // user would see two headers stacked and a bottom nav that does not apply.
    for (final route in [
      '/menu',
      '/profile',
      '/explore',
      '/my/matches',
      '/my/teams',
      '/my/pool-requests',
      '/my/tournaments',
      '/settings',
      '/saved',
      '/notifications',
      // The console's own destinations (artboards 24c, 27j). Both are pushed
      // off the console, which is itself pushed off the hub — a shell header
      // over either would read as a tab the organiser never chose.
      '/tournaments/abc-123/fees',
      '/tournaments/abc-123/live/m-1/officials',
    ]) {
      expect(
        isInsideShell(route),
        isFalse,
        reason: '$route must render over the shell, not inside it',
      );
    }
  });

  /// The Published screen shares `joinmatchday.com/t/<id>` to WhatsApp, and
  /// the Android/iOS app-link config forwards that path to the engine. There
  /// was no `/t/:id` route at all, so the one way into a tournament for
  /// someone who was sent an invite matched nothing and raised a GoException.
  ///
  /// `findMatch` resolves the route tree but does not run redirects, so this
  /// asserts the link is claimed by a redirect-only route — the redirect
  /// target itself is a one-liner in the route definition.
  test('a tournament invite link is claimed by a route', () {
    final router = container.read(appRouterProvider);
    final match = router.configuration.findMatch(Uri.parse('/t/abc-123'));

    expect(match.error, isNull,
        reason: '/t/:id must match a route, not fall through');
    expect(match.matches, hasLength(1));
    expect(match.pathParameters['tournamentId'], 'abc-123');

    // Control: an unclaimed path really does produce the error this guards
    // against, so the assertion above is not vacuous.
    expect(
      router.configuration.findMatch(Uri.parse('/zzz-not-a-route')).error,
      isNotNull,
    );
  });
}
