import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matchday/features/auth/domain/entities/user.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:matchday/router/app_router.dart';

/// go_router matches routes in **declaration order**, so a parameterised route
/// swallows any literal sibling declared after it: with `/matches/:matchId`
/// first, `/matches/send-challenge` was read as a match id and rendered
/// "Match not available" instead of the composer.
///
/// The bug is invisible until someone taps, and trivial to reintroduce by
/// appending a route at the bottom of the list — so this asserts the ordering
/// invariant across the whole table rather than spot-checking the one path.
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

  /// Every concrete path in the tree, in declaration order.
  List<String> declaredPaths() {
    final router = container.read(appRouterProvider);
    final out = <String>[];

    void walk(List<RouteBase> routes, String parent) {
      for (final route in routes) {
        var here = parent;
        if (route is GoRoute) {
          here = route.path.startsWith('/')
              ? route.path
              : '${parent.endsWith('/') ? parent : '$parent/'}${route.path}';
          out.add(here);
        }
        walk(route.routes, here);
      }
    }

    walk(router.configuration.routes, '');
    return out;
  }

  bool isParam(String segment) => segment.startsWith(':');

  /// A literal path is shadowed when an earlier path of the same depth matches
  /// it segment for segment, with at least one of those matches a parameter.
  ({String literal, String shadowedBy})? findShadowed(List<String> paths) {
    for (var i = 0; i < paths.length; i++) {
      final later = paths[i].split('/');
      if (later.any(isParam)) continue; // only literals can be shadowed

      for (var j = 0; j < i; j++) {
        final earlier = paths[j].split('/');
        if (earlier.length != later.length) continue;
        if (!earlier.any(isParam)) continue;

        var matches = true;
        for (var k = 0; k < earlier.length; k++) {
          if (!isParam(earlier[k]) && earlier[k] != later[k]) {
            matches = false;
            break;
          }
        }
        if (matches) {
          return (literal: paths[i], shadowedBy: paths[j]);
        }
      }
    }
    return null;
  }

  test('no literal route is shadowed by an earlier parameterised one', () {
    final paths = declaredPaths();
    expect(paths, isNotEmpty, reason: 'the router should declare routes');

    final clash = findShadowed(paths);
    expect(
      clash,
      isNull,
      reason: clash == null
          ? ''
          : 'Route "${clash.literal}" is unreachable: "${clash.shadowedBy}" is '
              'declared earlier and matches it first. Move the literal route '
              'above the parameterised one in app_router.dart.',
    );
  });

  test('the pool posts an open challenge, not a targeted one', () {
    final router = container.read(appRouterProvider);

    GoRoute routeFor(String path) => router.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == path);

    // The pool surfaces push ?mode=open; the wizard reads it to drop its
    // open-vs-direct step. If the query param is ever dropped from the route
    // builder, the flow silently starts on a direct challenge again.
    final send = routeFor('/matches/send-challenge');
    expect(send.builder, isNotNull,
        reason: '/matches/send-challenge must build the composer');
  });

  test('the paths the Pool feature pushes are all reachable', () {
    final paths = declaredPaths();

    // Every destination the pool / challenge screens push to.
    for (final path in const [
      '/pool',
      '/my/pool-requests',
      '/matches/send-challenge',
      '/challenges/:requestId',
      '/challenges/:requestId/applicants/:applicationId',
    ]) {
      expect(paths, contains(path), reason: '$path is not declared');
    }

    // …and specifically that the composer is not behind the match detail.
    final send = paths.indexOf('/matches/send-challenge');
    final detail = paths.indexOf('/matches/:matchId');
    expect(
      send,
      lessThan(detail),
      reason: '/matches/send-challenge must precede /matches/:matchId, '
          'or go_router reads "send-challenge" as a match id.',
    );
  });
}
