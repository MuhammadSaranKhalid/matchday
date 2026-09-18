import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_provider.dart';
import 'core/supabase/supabase_auth_state_provider.dart';
import 'core/theme/circk_theme.dart';
import 'features/messages/presentation/providers/messages_providers.dart';
import 'features/notifications/presentation/controllers/push_registrar.dart';
import 'router/app_router.dart';

class MatchdayApp extends ConsumerWidget {
  const MatchdayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wipe transient local stores (wizard drafts, messages cache) on explicit
    // sign-out or account deletion, or when switching to a different user,
    // so user A's data doesn't leak to user B on the same device.
    // Transient stream errors, token refreshes, and startup bootstrapping
    // must NEVER purge the local database.
    ref.listen(authStateProvider, (prev, next) {
      final nextState = next.value;
      final prevState = prev?.value;
      if (nextState == null) return;

      final isSignedOut = nextState.event == AuthChangeEvent.signedOut ||
          // ignore: deprecated_member_use
          nextState.event == AuthChangeEvent.userDeleted;
      final isUserSwitched = prevState?.session?.user.id != null &&
          nextState.session?.user.id != null &&
          prevState!.session!.user.id != nextState.session!.user.id;

      if (isSignedOut || isUserSwitched) {
        final db = ref.read(appDatabaseProvider);
        unawaited(db.clear());
      }
    });



    // Activate the FCM token registrar for the session (registers on sign-in,
    // re-registers on token refresh, deep-links notification taps).
    ref.watch(pushRegistrarProvider);

    // Activate the universal application-scoped chat local-first engine (Spec §8)
    ref.watch(chatLocalFirstEngineProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Matchday',
      theme: buildCirckTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
