import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:matchday/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:matchday/features/messages/data/models/chat_channel_dto.dart';
import 'package:matchday/features/messages/data/models/chat_message_dto.dart';
import 'package:matchday/features/messages/data/sync/catch_up_scheduler.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock implements ChatRemoteDataSource {}

void main() {
  late AppDatabase db;
  late ChatLocalDataSource local;
  late _MockRemoteDataSource remote;
  late CatchUpScheduler scheduler;

  const currentUserId = 'user-test-111';
  const channelId = 'ch-catchup-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = ChatLocalDataSource(db);
    remote = _MockRemoteDataSource();
    when(() => remote.fetchChannelChanges(
          any(),
          afterChangeSeq: any(named: 'afterChangeSeq'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => []);
    scheduler = CatchUpScheduler(
      local: local,
      remote: remote,
      db: db,
      maxConcurrent: 3,
      initialWindowSize: 50,
      deltaPageSize: 100,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CatchUpScheduler', () {
    test('D. Fresh unsynced channel fetches recent bounded bootstrap page, NOT full history', () async {
      final now = DateTime.now().toUtc();
      await local.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: channelId,
          channelKey: 'direct:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Direct Chat',
          lastMessageSeq: 500,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // Verify no prior sync state
      final initialState = await local.getChannelSyncState(channelId);
      expect(initialState, isNull);

      // Mock recent window (e.g. 50 messages from 451 to 500)
      final recentDtos = List.generate(
        50,
        (i) => ChatMessageDto(
          messageId: 'msg-${451 + i}',
          messageSeq: 451 + i,
          channelId: channelId,
          senderId: 'other-user',
          body: 'Message ${451 + i}',
          createdAt: now.toIso8601String(),
        ),
      );

      when(() => remote.fetchRecentMessages(channelId, limit: 50))
          .thenAnswer((_) async => recentDtos);

      // Run sync
      await scheduler.syncChannel(channelId, currentUserId);

      // Verify fetchRecentMessages was called with bounded limit
      verify(() => remote.fetchRecentMessages(channelId, limit: 50)).called(1);
      verifyNever(() => remote.fetchDeltaMessages(any(), any(), limit: any(named: 'limit')));

      // Verify ChannelSyncStates initialized
      final syncState = await local.getChannelSyncState(channelId);
      expect(syncState, isNotNull);
      expect(syncState!.newestSyncedMessageSeq, 500);
      expect(syncState.oldestCachedMessageSeq, 451);
      expect(syncState.hasMoreHistory, isTrue);

      // Verify messages persisted in Drift
      final messages = await (db.select(db.localMessages)
            ..where((m) => m.channelId.equals(channelId)))
          .get();
      expect(messages.length, 50);
    });

    test('C. Existing sync cursor: newestSyncedMessageSeq = 100 calls delta > 100', () async {
      final now = DateTime.now().toUtc();
      await local.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: channelId,
          channelKey: 'direct:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Direct Chat',
          lastMessageSeq: 105,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // Initialize cursor at 100
      await local.markChannelSyncSucceeded(
        channelId,
        newestSeq: 100,
        oldestSeq: 50,
      );

      final deltaDtos = [
        ChatMessageDto(
          messageId: 'msg-101',
          messageSeq: 101,
          channelId: channelId,
          senderId: 'other-user',
          body: 'Message 101',
          createdAt: now.toIso8601String(),
        ),
        ChatMessageDto(
          messageId: 'msg-105',
          messageSeq: 105,
          channelId: channelId,
          senderId: 'other-user',
          body: 'Message 105',
          createdAt: now.toIso8601String(),
        ),
      ];

      when(() => remote.fetchDeltaMessages(channelId, 100, limit: 100))
          .thenAnswer((_) async => deltaDtos);

      await scheduler.syncChannel(channelId, currentUserId);

      verify(() => remote.fetchDeltaMessages(channelId, 100, limit: 100)).called(1);
      verifyNever(() => remote.fetchRecentMessages(any(), limit: any(named: 'limit')));

      final updatedState = await local.getChannelSyncState(channelId);
      expect(updatedState!.newestSyncedMessageSeq, 105);
      expect(updatedState.oldestCachedMessageSeq, 50); // Untouched
    });

    test('E. Multi-page forward catch-up advances cursor page by page', () async {
      final now = DateTime.now().toUtc();
      final smallPageScheduler = CatchUpScheduler(
        local: local,
        remote: remote,
        db: db,
        deltaPageSize: 2, // 2 items per page for testing pagination
      );

      await local.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: channelId,
          channelKey: 'direct:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Direct Chat',
          lastMessageSeq: 104,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      await local.markChannelSyncSucceeded(channelId, newestSeq: 100);

      // Page 1: 101, 102
      final page1 = [
        ChatMessageDto(
          messageId: 'msg-101',
          messageSeq: 101,
          channelId: channelId,
          senderId: 'other',
          body: 'Msg 101',
          createdAt: now.toIso8601String(),
        ),
        ChatMessageDto(
          messageId: 'msg-102',
          messageSeq: 102,
          channelId: channelId,
          senderId: 'other',
          body: 'Msg 102',
          createdAt: now.toIso8601String(),
        ),
      ];

      // Page 2: 103, 104
      final page2 = [
        ChatMessageDto(
          messageId: 'msg-103',
          messageSeq: 103,
          channelId: channelId,
          senderId: 'other',
          body: 'Msg 103',
          createdAt: now.toIso8601String(),
        ),
        ChatMessageDto(
          messageId: 'msg-104',
          messageSeq: 104,
          channelId: channelId,
          senderId: 'other',
          body: 'Msg 104',
          createdAt: now.toIso8601String(),
        ),
      ];

      when(() => remote.fetchDeltaMessages(channelId, 100, limit: 2))
          .thenAnswer((_) async => page1);
      when(() => remote.fetchDeltaMessages(channelId, 102, limit: 2))
          .thenAnswer((_) async => page2);

      await smallPageScheduler.syncChannel(channelId, currentUserId);

      verify(() => remote.fetchDeltaMessages(channelId, 100, limit: 2)).called(1);
      verify(() => remote.fetchDeltaMessages(channelId, 102, limit: 2)).called(1);

      final finalState = await local.getChannelSyncState(channelId);
      expect(finalState!.newestSyncedMessageSeq, 104);

      final localRows = await (db.select(db.localMessages)
            ..where((m) => m.channelId.equals(channelId)))
          .get();
      expect(localRows.length, 4);
    });

    test('F. Duplicate message: realtime + delta same message_id => one local row', () async {
      final now = DateTime.now().toUtc();
      const duplicateMsgId = 'msg-dup-1';

      // 1. Ingest via simulated realtime
      await local.upsertMessagesFromDto([
        ChatMessageDto(
          messageId: duplicateMsgId,
          messageSeq: 200,
          channelId: channelId,
          senderId: 'other',
          body: 'Realtime body',
          createdAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // 2. Reconciliation delta returns the same message
      await local.markChannelSyncSucceeded(channelId, newestSeq: 199);

      when(() => remote.fetchDeltaMessages(channelId, 199, limit: 100)).thenAnswer(
        (_) async => [
          ChatMessageDto(
            messageId: duplicateMsgId,
            messageSeq: 200,
            channelId: channelId,
            senderId: 'other',
            body: 'Realtime body',
            createdAt: now.toIso8601String(),
          ),
        ],
      );

      await scheduler.syncChannel(channelId, currentUserId);

      final rows = await (db.select(db.localMessages)
            ..where((m) => m.messageId.equals(duplicateMsgId)))
          .get();
      expect(rows.length, 1);
    });

    test('R. Older pagination updates oldestCachedMessageSeq without moving newest cursor', () async {
      final now = DateTime.now().toUtc();
      await local.markChannelSyncSucceeded(
        channelId,
        newestSeq: 300,
        oldestSeq: 250,
      );

      final olderDtos = List.generate(
        50,
        (i) => ChatMessageDto(
          messageId: 'msg-older-${200 + i}',
          messageSeq: 200 + i,
          channelId: channelId,
          senderId: 'other',
          body: 'Older msg ${200 + i}',
          createdAt: now.toIso8601String(),
        ),
      );

      when(() => remote.fetchOlderMessages(channelId, 250, limit: 50))
          .thenAnswer((_) async => olderDtos);

      final count = await scheduler.loadOlderMessages(channelId, currentUserId);
      expect(count, 50);

      final state = await local.getChannelSyncState(channelId);
      expect(state!.oldestCachedMessageSeq, 200);
      expect(state.newestSyncedMessageSeq, 300); // Unaltered!
    });

    test('replays receipt changes from chat_changes ledger updating member horizons', () async {
      final now = DateTime.now().toUtc();
      const otherUserId = 'user-counterparty-999';

      await local.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: channelId,
          channelKey: 'direct:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Direct Chat',
          lastMessageSeq: 100,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // Seed sync state so it queries after seq 100
      await local.markChannelSyncSucceeded(
        channelId,
        newestSeq: 100,
        oldestSeq: 1,
      );

      when(() => remote.fetchDeltaMessages(channelId, 100, limit: any(named: 'limit')))
          .thenAnswer((_) async => []);

      // Mock chat_changes ledger containing a read receipt from counterparty
      when(() => remote.fetchChannelChanges(
            channelId,
            afterChangeSeq: 0,
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [
            {
              'change_seq': 1,
              'channel_id': channelId,
              'entity_type': 'receipt',
              'entity_id': otherUserId,
              'operation': 'insert',
              'payload': {
                'type': 'read',
                'user_id': otherUserId,
                'through_message_seq': 100,
              },
              'created_at': now.toIso8601String(),
            },
          ]);

      await scheduler.syncChannel(channelId, currentUserId);

      final members = await (db.select(db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(otherUserId)))
          .getSingle();

      expect(members.lastReadMessageSeq, 100);
    });
  });
}
