import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/todos/presentation/screens/todos_screen.dart';

part 'app_router.g.dart';

/// Auth-aware router.
///
/// The redirect callback reads the current-user stream's latest value.
/// When it flips (sign in / sign out), the router re-evaluates and moves
/// the user accordingly.
@riverpod
GoRouter appRouter(Ref ref) {
  final userStream = ref.watch(currentUserStreamProvider);

  return GoRouter(
    initialLocation: '/sign-in',
    redirect: (context, state) {
      final user = userStream.valueOrNull;
      final isSignedIn = user != null;
      final goingToSignIn = state.matchedLocation == '/sign-in';

      if (!isSignedIn && !goingToSignIn) return '/sign-in';
      if (isSignedIn && goingToSignIn) return '/todos';
      return null;
    },
    refreshListenable: _StreamListenable(ref),
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: '/todos',
        builder: (_, __) => const TodosScreen(),
      ),
    ],
  );
}

/// Tiny adapter: poke the router whenever the currentUserStream emits.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(this._ref) {
    _ref.listen(currentUserStreamProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
