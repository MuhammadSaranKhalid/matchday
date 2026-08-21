import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_provider.dart';
import 'core/log/ck_log.dart';
import 'core/theme/circk_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/notifications/presentation/controllers/push_registrar.dart';
import 'router/app_router.dart';

class MatchdayApp extends ConsumerWidget {
  const MatchdayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wipe transient local stores (wizard drafts, messages cache) on sign-out
    // so user A's data doesn't leak to user B on the same device.
    ref.listen(currentUserStreamProvider, (prev, next) {
      final prevUser = prev?.value;
      final nextUser = next.value;
      if (prevUser != null && nextUser == null) {
        // The scoring write-ahead log is wiped too, and unlike a wizard draft
        // an unsent delivery is not disposable — it is an over of real cricket
        // the server has never seen. Log the count before it goes so a support
        // conversation can at least establish that it happened.
        //
        // This is a last resort, not the guard: the scoring screen should warn
        // the scorer BEFORE they reach sign-out with a non-empty outbox. By
        // here the decision is already made.
        final db = ref.read(appDatabaseProvider);
        unawaited(() async {
          try {
            final owed = await db.pendingScoringOps();
            if (owed > 0) {
              CkLog.warn(CkLogChannel.matchStart, 'signout·discards·deliveries',
                  data: {'owed': owed});
            }
          } catch (_) {
            // Counting is diagnostic only; never let it block the wipe, which
            // is a privacy guarantee.
          }
          await db.clear();
        }());
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
