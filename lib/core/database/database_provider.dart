import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_database.dart';

part 'database_provider.g.dart';

/// Single AppDatabase instance for the app lifetime.
///
/// Drift's executor owns a background isolate; creating multiple
/// instances would open multiple connections to the same sqlite file.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
