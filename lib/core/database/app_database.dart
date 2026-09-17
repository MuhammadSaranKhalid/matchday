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

  /// Schema history:
  /// - v1–v4: legacy offline-first tables.
  /// - v5: online-only reset; keeps only `wizard_drafts`.
  /// - v6: legacy messages read-through cache (`chats`, `messages`, `message_drafts`).
  /// - v7: scoring write-ahead log (`scoring_ops`, `scoring_snapshots`).
  /// - v8: match hydration cache.
  /// - v9: `scoring_ops.refused_at`.
  /// - v10: Target local-first chat architecture (Spec §7).
  /// - v11: messageId primary key on LocalMessages.
  /// - v12: LocalChannels authoritative inbox projection.
  /// - v13: ChannelSyncStates.newestAppliedChangeSeq durable mutation cursor.
  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createChatIndexes(m);
          await _createScoringIndexes(m);
        },
        onUpgrade: (m, from, to) async {
          if (from < 5) {
            await m.database.customStatement('DROP TABLE IF EXISTS todos');
            await m.database.customStatement('DROP TABLE IF EXISTS pending_operations');
            await m.database.customStatement('DROP TABLE IF EXISTS teams');
            await m.database.customStatement('DROP TABLE IF EXISTS team_members');
            await m.database.customStatement('DROP TABLE IF EXISTS unclaimed_players');
            if (from < 3) {
              await m.createTable(wizardDrafts);
            }
          }
          if (from < 6) {
            await m.database.customStatement('DROP TABLE IF EXISTS messages_chats');
            await m.database.customStatement('DROP TABLE IF EXISTS messages_messages');
            await m.database.customStatement('DROP TABLE IF EXISTS messages_drafts');
            await m.database.customStatement('DROP TABLE IF EXISTS chats');
            await m.database.customStatement('DROP TABLE IF EXISTS messages');
            await m.database.customStatement('DROP TABLE IF EXISTS message_drafts');
          }
          if (from < 7) {
            await m.database.customStatement('DROP TABLE IF EXISTS scoring_ops');
            await m.database.customStatement('DROP TABLE IF EXISTS scoring_snapshots');
            await m.createTable(scoringOps);
            await m.createTable(scoringSnapshots);
            await _createScoringIndexes(m);
          }
          if (from < 8) {
            await m.database.customStatement('DROP TABLE IF EXISTS cached_matches');
            await m.database.customStatement('DROP TABLE IF EXISTS cached_match_players');
            await m.database.customStatement('DROP TABLE IF EXISTS cached_innings_states');
            await m.createTable(cachedMatches);
            await m.createTable(cachedMatchPlayers);
            await m.createTable(cachedInningsStates);
          }
          if (from < 9) {
            await m.addColumn(scoringOps, scoringOps.refusedAt);
            await m.database.customStatement('DROP INDEX IF EXISTS scoring_ops_pending');
            await _createScoringIndexes(m);
          }
          if (from < 10) {
            await m.database.customStatement('DROP TABLE IF EXISTS chats');
            await m.database.customStatement('DROP TABLE IF EXISTS messages');
            await m.database.customStatement('DROP TABLE IF EXISTS message_drafts');

            await m.createTable(localChannels);
            await m.createTable(localChannelMembers);
            await m.createTable(localMessages);
            await m.createTable(localMessageAttachments);
            await m.createTable(localMessageReactions);
            await m.createTable(localMemberRestrictions);
            await m.createTable(outboxOperations);
            await m.createTable(channelSyncStates);
            await m.createTable(channelDrafts);
            await _createChatIndexes(m);
          }
          if (from < 11) {
            await m.database.transaction(() async {
              final tables = await m.database
                  .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
                  .get();
              final tableNames = tables.map((r) => r.read<String>('name')).toSet();

              if (tableNames.contains('local_messages')) {
                await m.database.customStatement('ALTER TABLE local_messages RENAME TO _legacy_local_messages;');
              }
              if (tableNames.contains('outbox_operations')) {
                await m.database.customStatement('ALTER TABLE outbox_operations RENAME TO _legacy_outbox_operations;');
              }

              // Drop auxiliary non-outbox tables
              await m.database.customStatement('DROP TABLE IF EXISTS local_channels;');
              await m.database.customStatement('DROP TABLE IF EXISTS local_channel_members;');
              await m.database.customStatement('DROP TABLE IF EXISTS local_message_attachments;');
              await m.database.customStatement('DROP TABLE IF EXISTS local_message_reactions;');
              await m.database.customStatement('DROP TABLE IF EXISTS local_member_restrictions;');
              await m.database.customStatement('DROP TABLE IF EXISTS channel_sync_states;');
              await m.database.customStatement('DROP TABLE IF EXISTS channel_drafts;');

              // Recreate all tables with definitive schema
              await m.createTable(localChannels);
              await m.createTable(localChannelMembers);
              await m.createTable(localMessages);
              await m.createTable(localMessageAttachments);
              await m.createTable(localMessageReactions);
              await m.createTable(localMemberRestrictions);
              await m.createTable(outboxOperations);
              await m.createTable(channelSyncStates);
              await m.createTable(channelDrafts);

              // Restore preserved rows
              if (tableNames.contains('local_messages')) {
                await m.database.customStatement('''
                  INSERT OR REPLACE INTO local_messages 
                  SELECT * FROM _legacy_local_messages;
                ''');
                await m.database.customStatement('DROP TABLE IF EXISTS _legacy_local_messages;');
              }
              if (tableNames.contains('outbox_operations')) {
                await m.database.customStatement('''
                  INSERT OR REPLACE INTO outbox_operations 
                  SELECT * FROM _legacy_outbox_operations;
                ''');
                await m.database.customStatement('DROP TABLE IF EXISTS _legacy_outbox_operations;');
              }

              await _createChatIndexes(m);
            });
          }
          if (from < 12) {
            await m.addColumn(localChannels, localChannels.lastMessagePreview);
            await m.addColumn(localChannels, localChannels.lastMessageSenderId);
            await m.addColumn(localChannels, localChannels.lastMessageFromMe);
            await m.addColumn(localChannels, localChannels.unreadCount);
          }
          if (from < 13) {
            await m.addColumn(channelSyncStates, channelSyncStates.newestAppliedChangeSeq);
          }
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
      name: 'novex_clean_arch',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
