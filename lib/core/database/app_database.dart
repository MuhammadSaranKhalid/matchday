import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Todos, PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// Wipe the local DB on sign-out so a different user on the same
  /// device never sees the previous user's cached todos.
  ///
  /// Called from the auth flow when sign-out completes.
  Future<void> clear() async {
    await batch((b) {
      b.deleteAll(todos);
      b.deleteAll(pendingOperations);
    });
  }
}

/// drift_flutter handles native sqlite3 setup, path resolution, and
/// background isolate creation. The DB file lives in the app's
/// documents directory.
QueryExecutor _openConnection() => driftDatabase(name: 'novex_clean_arch');
