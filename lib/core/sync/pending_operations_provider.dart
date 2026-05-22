import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database_provider.dart';
import 'pending_operations_datasource.dart';

part 'pending_operations_provider.g.dart';

/// Shared across all offline features (the queue is feature-agnostic).
@Riverpod(keepAlive: true)
PendingOperationsDataSource pendingOperationsDataSource(Ref ref) =>
    PendingOperationsDataSource(ref.watch(appDatabaseProvider));
