import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [WizardDrafts, Chats, Messages, MessageDrafts, ScoringOps,
           ScoringSnapshots],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// An instance over a caller-supplied executor, for tests.
  ///
  /// The scoring write-ahead log is a durability guarantee, and a guarantee
  /// asserted against a mock is not asserted at all — these tests run against
  /// real SQLite so the transaction that allocates `local_seq` is genuinely
  /// exercised.
  AppDatabase.forTesting(super.executor);

  /// Schema history:
  /// - v1–v4 carried offline-first tables (`todos`, `pending_operations`,
  ///   `teams`, `team_members`, `unclaimed_players`) that have since been
  ///   removed.
  /// - v5: online-only reset; keeps only `wizard_drafts`.
  /// - v6: messages read-through cache + drafts (ticket #23). Adds `chats`,
  ///   `messages`, `message_drafts`. Names mirror the Supabase schema 1:1.
  ///   Scoped to the messages feature only — other features remain
  ///   online-only.
  /// - v7: scoring write-ahead log (`scoring_ops`, `scoring_snapshots`). The
  ///   second exemption to online-only, and the first offline WRITE path —
  ///   a scorer with no signal keeps scoring and loses nothing. See
  ///   docs/offline-scoring-design.md.
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Fresh install — drift creates all tables declared on
          // @DriftDatabase. createAll() does NOT process raw
          // `CREATE INDEX` statements, so the hot-path indexes must be
          // created explicitly here too (ticket #28). Without this call,
          // every new install runs the inbox sort + thread paging without
          // an index — every fresh user pays the full-scan cost forever.
          await m.createAll();
          await _createMessagesIndexes(m);
          await _createScoringIndexes(m);
        },
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
            // The first iteration of v6 (PR #26 pre-rename) used
            // `messages_chats` / `messages_messages` / `messages_drafts`.
            // Drop them if they exist so a tester device that pulled the
            // earlier commit gets the new names cleanly. Production users
            // coming from v5 don't have these — DROP IF EXISTS is a no-op
            // for them.
            await m.database
                .customStatement('DROP TABLE IF EXISTS messages_chats');
            await m.database
                .customStatement('DROP TABLE IF EXISTS messages_messages');
            await m.database
                .customStatement('DROP TABLE IF EXISTS messages_drafts');

            // Partial-rerun safety (ticket #28). The createTable calls
            // below are not wrapped in an explicit transaction; if the
            // process is killed mid-migration `schemaVersion` stays at 5
            // and this block re-runs on next launch. Dropping the new
            // names here too means any orphan half-created table from a
            // prior partial run gets cleared. No-op on a clean upgrade.
            await m.database.customStatement('DROP TABLE IF EXISTS chats');
            await m.database.customStatement('DROP TABLE IF EXISTS messages');
            await m.database
                .customStatement('DROP TABLE IF EXISTS message_drafts');

            // Messages cache + drafts (ticket #23).
            await m.createTable(chats);
            await m.createTable(messages);
            await m.createTable(messageDrafts);
            await _createMessagesIndexes(m);
          }
          if (from < 7) {
            // Same partial-rerun safety as v6: not wrapped in an explicit
            // transaction, so a kill mid-migration leaves schemaVersion at 6
            // and re-runs this block.
            await m.database
                .customStatement('DROP TABLE IF EXISTS scoring_ops');
            await m.database
                .customStatement('DROP TABLE IF EXISTS scoring_snapshots');
            await m.createTable(scoringOps);
            await m.createTable(scoringSnapshots);
            await _createScoringIndexes(m);
          }
        },
      );

  /// The outbox's only query is "unsynced ops for this innings, in order".
  /// createAll() does not process raw CREATE INDEX, so fresh installs need this
  /// explicitly too — the same trap ticket #28 documents for messages.
  Future<void> _createScoringIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS scoring_ops_pending '
      'ON scoring_ops (match_id, innings_number, local_seq) '
      'WHERE synced_at IS NULL',
    );
  }

  /// Hot-path indexes for the messages cache. Called from BOTH `onCreate`
  /// (fresh install) and `onUpgrade(from < 6)` because `m.createAll()` does
  /// not process raw index statements — fresh installs would otherwise miss
  /// them and pay full-scan cost on every inbox / thread query (ticket #28).
  Future<void> _createMessagesIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_chats_last_message_at '
      'ON chats (last_message_at DESC)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_messages_chat_created '
      'ON messages (chat_id, created_at DESC)',
    );
  }

  /// Wipe local drift state on sign-out so a different user on the same
  /// device never sees the previous user's data. Covers all messages cache
  /// tables in addition to wizard drafts.
  /// Deliveries entered but never accepted by the server.
  ///
  /// Sign-out wipes the whole database, so this exists to let the caller ask
  /// "is anything about to be thrown away?" BEFORE that happens. Discarding a
  /// scorer's unsent overs without telling them would be the worst possible
  /// way for this feature to fail.
  Future<int> pendingScoringOps() async {
    final rows = await (select(scoringOps)
          ..where((t) => t.syncedAt.isNull()))
        .get();
    return rows.length;
  }

  Future<void> clear() async {
    await batch((b) {
      b.deleteAll(wizardDrafts);
      b.deleteAll(chats);
      b.deleteAll(messages);
      b.deleteAll(messageDrafts);
      // Unsynced deliveries belong to the scorer who entered them. Callers
      // MUST warn before reaching here with a non-empty outbox — see
      // pendingScoringOps — because this discards them irrecoverably.
      b.deleteAll(scoringOps);
      b.deleteAll(scoringSnapshots);
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
