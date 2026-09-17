import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WizardDrafts,
    LocalChannels,
    LocalChannelMembers,
    LocalMessages,
    LocalMessageAttachments,
    LocalMessageReactions,
    LocalMemberRestrictions,
    OutboxOperations,
    ChannelSyncStates,
    ChannelDrafts,
    ScoringOps,
    ScoringSnapshots,
    CachedMatches,
    CachedMatchPlayers,
    CachedInningsStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// An instance over a caller-supplied executor, for tests.
  AppDatabase.forTesting(super.executor);

  /// Canonical production baseline schema (v1).
  ///
  /// In pre-release development, all legacy incremental upgrade ladders
  /// have been consolidated into the canonical v1 baseline schema.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createChatIndexes(m);
          await _createScoringIndexes(m);
        },
        onUpgrade: (m, from, to) async {
          // Pre-release development: ensure all tables and indexes exist cleanly
          await m.createAll();
          await _createChatIndexes(m);
          await _createScoringIndexes(m);
        },
      );

  Future<void> _createScoringIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS scoring_ops_pending '
      'ON scoring_ops (match_id, innings_number, local_seq) '
      'WHERE synced_at IS NULL AND refused_at IS NULL',
    );
  }

  Future<void> _createChatIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_messages_channel_seq '
      'ON local_messages (channel_id, message_seq DESC)',
    );
    await m.database.customStatement(
      "CREATE INDEX IF NOT EXISTS idx_local_messages_pending "
      "ON local_messages (channel_id, local_created_at ASC) "
      "WHERE sync_status != 'sent'",
    );
    await m.database.customStatement(
      "CREATE INDEX IF NOT EXISTS idx_outbox_pending_lane "
      "ON outbox_operations (channel_id, created_at ASC) "
      "WHERE status = 'pending' OR status = 'retry_wait'",
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_channels_last_message '
      'ON local_channels (last_message_at DESC)',
    );
  }

  Future<int> pendingScoringOps({
    String? matchId,
    int? inningsNumber,
  }) async {
    final rows = await (select(scoringOps)
          ..where((t) {
            var w = t.syncedAt.isNull() & t.refusedAt.isNull();
            if (matchId != null) w = w & t.matchId.equals(matchId);
            if (inningsNumber != null) {
              w = w & t.inningsNumber.equals(inningsNumber);
            }
            return w;
          }))
        .get();
    return rows.length;
  }

  Future<void> clear() async {
    await batch((b) {
      b.deleteAll(wizardDrafts);
      b.deleteAll(localChannels);
      b.deleteAll(localChannelMembers);
      b.deleteAll(localMessages);
      b.deleteAll(localMessageAttachments);
      b.deleteAll(localMessageReactions);
      b.deleteAll(localMemberRestrictions);
      b.deleteAll(outboxOperations);
      b.deleteAll(channelSyncStates);
      b.deleteAll(channelDrafts);
      b.deleteAll(scoringOps);
      b.deleteAll(scoringSnapshots);
      b.deleteAll(cachedMatches);
      b.deleteAll(cachedMatchPlayers);
      b.deleteAll(cachedInningsStates);
    });
  }
}

QueryExecutor _openConnection() => driftDatabase(
      name: 'matchday_local',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
