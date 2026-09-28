import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_database.dart';
import 'wizard_draft_store.dart';

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

/// Shared wizard-draft persistence (onboarding, team-create, ...). Lives here
/// to keep DB-provider definitions in a `*_provider*.dart` file per Rule 5;
/// the [WizardDraftStore] class itself stays in `wizard_draft_store.dart`.
@Riverpod(keepAlive: true)
WizardDraftStore wizardDraftStore(Ref ref) =>
    WizardDraftStore(ref.watch(appDatabaseProvider));
