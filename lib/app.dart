import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_provider.dart';
import 'core/sync/sync_provider.dart';
import 'core/theme/circk_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'router/app_router.dart';

class NovexApp extends ConsumerWidget {
  const NovexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly create the SyncService at boot so it starts watching
    // connectivity from the first frame, not from the first time the
    // todos screen opens.
    ref.watch(syncServiceProvider);

    // Wipe the local DB on sign-out. The auth listener fires when the
    // current-user stream emits null (signed out) AFTER having a user.
    ref.listen(currentUserStreamProvider, (prev, next) {
      final prevUser = prev?.value;
      final nextUser = next.value;
      if (prevUser != null && nextUser == null) {
        ref.read(appDatabaseProvider).clear();
      }
    });

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Novex Clean Arch',
      theme: buildCirckTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
