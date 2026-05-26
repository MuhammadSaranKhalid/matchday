import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [WizardDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // No upgrades yet — schema started fresh as online-only.
        },
      );

  /// Wipe local drift state on sign-out (currently only wizard drafts) so a
  /// different user on the same device never sees the previous user's
  /// in-progress forms.
  Future<void> clear() async {
    await batch((b) {
      b.deleteAll(wizardDrafts);
    });
  }
}

/// drift_flutter handles native sqlite3 setup, path resolution, and
/// background isolate creation. The DB file lives in the app's
/// documents directory.
QueryExecutor _openConnection() => driftDatabase(name: 'novex_clean_arch');
