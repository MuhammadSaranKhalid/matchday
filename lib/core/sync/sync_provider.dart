import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/connectivity/connectivity_provider.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../features/todos/data/datasources/todos_datasource_providers.dart';
import 'sync_service.dart';

part 'sync_provider.g.dart';

/// Owns the SyncService and wires it to connectivity.
///
/// Triggers a sync when:
///  - The service is first created (app startup, if online)
///  - Connectivity flips from offline → online
///
/// The repository also calls service.sync() after every local mutation
/// so writes propagate immediately when online.
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final service = SyncService(
    local: ref.watch(todosLocalDataSourceProvider),
    remote: ref.watch(todosRemoteDataSourceProvider),
    pendingOps: ref.watch(pendingOperationsDataSourceProvider),
    supabase: ref.watch(supabaseClientProvider),
  );

  // Only sync on the offline → online edge, not on every emission.
  var wasOnline = false;
  ref.listen(isOnlineProvider, (prev, next) {
    final online = next.value ?? false;
    if (online && !wasOnline) {
      service.sync();
      service.startRealtimeMirror();
    } else if (!online && wasOnline) {
      service.stopRealtimeMirror();
    }
    wasOnline = online;
  });

  // Initial sync on app start if online. Scheduled with Future() so the
  // provider tree finishes building before sync() runs.
  Future(() async {
    final online = await ref.read(isOnlineProvider.future);
    if (online) {
      service.sync();
      service.startRealtimeMirror();
    }
  });

  ref.onDispose(service.dispose);
  return service;
}
