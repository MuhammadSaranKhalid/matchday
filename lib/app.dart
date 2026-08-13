import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_provider.dart';
import 'core/theme/circk_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/notifications/presentation/controllers/push_registrar.dart';
import 'router/app_router.dart';

class MatchdayApp extends ConsumerWidget {
  const MatchdayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wipe transient local stores (wizard drafts) on sign-out so user A's
    // in-progress forms don't leak to user B on the same device.
    ref.listen(currentUserStreamProvider, (prev, next) {
      final prevUser = prev?.value;
      final nextUser = next.value;
      if (prevUser != null && nextUser == null) {
        ref.read(appDatabaseProvider).clear();
      }
    });

    // Activate the FCM token registrar for the session (registers on sign-in,
    // re-registers on token refresh, deep-links notification taps).
    ref.watch(pushRegistrarProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Matchday',
      theme: buildCirckTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
