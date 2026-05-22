import 'dart:convert';

import 'app_database.dart';

/// Best-effort local persistence for multi-step wizard drafts, backed by the
/// `wizard_drafts` drift table. Lets a controller autosave in-progress form
/// state (keyed by something like `onboarding:<userId>`) and restore it after
/// an app kill.
///
/// Deliberately NOT a domain repository: a draft is transient *presentation*
/// state, not domain data, so it carries no `Either<Failure, T>` plumbing.
/// Reads/writes are best-effort — failures are swallowed (a lost draft is a
/// minor annoyance, never an error the user must handle). Controllers use this
/// directly via [wizardDraftStoreProvider], the same way the todos controller
/// reaches for the sync service.
class WizardDraftStore {
  WizardDraftStore(this._db);
  final AppDatabase _db;

  /// Returns the decoded draft for [key], or null if absent / unreadable.
  Future<Map<String, dynamic>?> load(String key) async {
    try {
      final row = await (_db.select(_db.wizardDrafts)
            ..where((t) => t.key.equals(key)))
          .getSingleOrNull();
      if (row == null) return null;
      final decoded = jsonDecode(row.payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String key, Map<String, dynamic> json) async {
    try {
      await _db.into(_db.wizardDrafts).insertOnConflictUpdate(
            WizardDraftsCompanion.insert(
              key: key,
              payload: jsonEncode(json),
              updatedAt: DateTime.now(),
            ),
          );
    } catch (_) {
      // best-effort
    }
  }

  Future<void> clear(String key) async {
    try {
      await (_db.delete(_db.wizardDrafts)..where((t) => t.key.equals(key))).go();
    } catch (_) {
      // best-effort
    }
  }
}
