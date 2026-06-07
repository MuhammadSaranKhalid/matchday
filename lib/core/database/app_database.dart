import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [WizardDrafts, MessagesChats, MessagesMessages, MessagesDrafts],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Schema history:
  /// - v1–v4 carried offline-first tables (`todos`, `pending_operations`,
  ///   `teams`, `team_members`, `unclaimed_players`) that have since been
  ///   removed.
  /// - v5: online-only reset; keeps only `wizard_drafts`.
  /// - v6: messages read-through cache + drafts (ticket #23). Adds
  ///   `messages_chats`, `messages_messages`, `messages_drafts`. Scoped to
  ///   the messages feature only — other features remain online-only.
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 5) {
            // Drop every offline-first table that may still exist on devices
            // coming from v1–v4. `IF EXISTS` so this is idempotent and safe
            // regardless of which subset the device actually has.
            await m.database
                .customStatement('DROP TABLE IF EXISTS todos');
            await m.database
                .customStatement('DROP TABLE IF EXISTS pending_operations');
            await m.database
                .customStatement('DROP TABLE IF EXISTS teams');
            await m.database
                .customStatement('DROP TABLE IF EXISTS team_members');
            await m.database
                .customStatement('DROP TABLE IF EXISTS unclaimed_players');
            // wizard_drafts was added at v3; only create it for devices
            // jumping from v1/v2 — devices already at v3+ have it.
            if (from < 3) {
              await m.createTable(wizardDrafts);
            }
          }
          if (from < 6) {
            // Messages cache + drafts (ticket #23).
            await m.createTable(messagesChats);
            await m.createTable(messagesMessages);
            await m.createTable(messagesDrafts);
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_messages_chats_last_message_at '
              'ON messages_chats (last_message_at DESC)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_messages_messages_chat_created '
              'ON messages_messages (chat_id, created_at DESC)',
            );
          }
        },
      );

  /// Wipe local drift state on sign-out so a different user on the same
  /// device never sees the previous user's data. Covers all messages cache
  /// tables in addition to wizard drafts.
  Future<void> clear() async {
    await batch((b) {
      b.deleteAll(wizardDrafts);
      b.deleteAll(messagesChats);
      b.deleteAll(messagesMessages);
      b.deleteAll(messagesDrafts);
    });
  }
}

/// drift_flutter handles native sqlite3 setup, path resolution, and
/// background isolate creation. The DB file lives in the app's
/// documents directory.
///
/// The [DriftWebOptions] are ignored on native platforms but are REQUIRED on
/// web (drift_flutter throws `ArgumentError` otherwise). They point at the
/// `sqlite3.wasm` + `drift_worker.js` assets in `web/`, which drift loads to
/// run SQLite via WebAssembly (OPFS / IndexedDB) in the browser. This keeps
/// the wizard-draft store working when the app is run on web; native builds
/// are unaffected. (App remains mobile-first — web is a convenience target.)
QueryExecutor _openConnection() => driftDatabase(
      name: 'novex_clean_arch',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
