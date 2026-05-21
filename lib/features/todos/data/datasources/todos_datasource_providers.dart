import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import 'pending_operations_datasource.dart';
import 'todos_local_datasource.dart';
import 'todos_remote_datasource.dart';

part 'todos_datasource_providers.g.dart';

/// Lives in its own file so the sync provider and the repository
/// provider can both depend on these without creating an import cycle.

@Riverpod(keepAlive: true)
TodosLocalDataSource todosLocalDataSource(Ref ref) =>
    TodosLocalDataSource(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PendingOperationsDataSource pendingOperationsDataSource(Ref ref) =>
    PendingOperationsDataSource(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
TodosRemoteDataSource todosRemoteDataSource(Ref ref) =>
    TodosRemoteDataSource(ref.watch(supabaseClientProvider));
