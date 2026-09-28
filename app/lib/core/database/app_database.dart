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

  AppDatabase.forTesting(super.executor);

  /// v3 adds participant presentation metadata directly to
  /// LocalChannelMembers. There is deliberately NO LocalChatParticipants
  /// table.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createChatIndexes(m);
          await _createScoringIndexes(m);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(localChannels, localChannels.dmOtherUserId);
            await m.addColumn(localChannels, localChannels.dmOtherUserName);
            await m.addColumn(localChannels, localChannels.dmOtherUserUsername);
            await m.addColumn(localChannels, localChannels.dmOtherUserAvatarUrl);
            await m.addColumn(localChannels, localChannels.dmOtherMemberStatus);
            await m.addColumn(localChannels, localChannels.youFollow);
            await m.addColumn(localChannels, localChannels.theyFollowYou);
          }

          if (from < 3) {
            await m.addColumn(localChannelMembers, localChannelMembers.displayName);
            await m.addColumn(localChannelMembers, localChannelMembers.username);
            await m.addColumn(localChannelMembers, localChannelMembers.avatarUrl);
          }

          if (from < 4) {
            await m.addColumn(outboxOperations, outboxOperations.ownerUserId);
          }

          // Development-stage safety: create any newly declared tables and
          // indexes after column migrations.
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
      "CREATE INDEX IF NOT EXISTS idx_outbox_owner_ready "
      "ON outbox_operations (owner_user_id, created_at ASC) "
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
