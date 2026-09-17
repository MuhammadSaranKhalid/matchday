import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:matchday/features/messages/data/models/chat_channel_dto.dart';
import 'package:matchday/features/messages/data/models/chat_message_dto.dart';

void main() {
  late AppDatabase db;
  late ChatLocalDataSource dataSource;
  const currentUserId = 'user-111';
  const otherUserId = 'user-222';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = ChatLocalDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ChatLocalDataSource - Inbox Stream', () {
    test('watchInbox emits channels with computed unread count and sorting', () async {
      final now = DateTime.now().toUtc();

      // Upsert two channels via DTO
      await dataSource.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: 'ch-1',
          channelKey: 'direct:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Direct Chat 1',
          dmOtherUserId: otherUserId,
          dmOtherUserName: 'Adeel',
          isAccepted: true,
          isPinned: false,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
        ChatChannelDto(
          channelId: 'ch-2',
          channelKey: 'team:t1:main',
          kind: 'group',
          contextType: 'team',
          title: 'Team Chat 2',
          isAccepted: true,
          isPinned: true, // Pinned channel
          createdAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // Add messages to ch-1: 3 unread messages from otherUser
      await dataSource.upsertMessagesFromDto([
        ChatMessageDto(
          messageId: 'm-1',
          messageSeq: 1,
          channelId: 'ch-1',
          senderId: otherUserId,
          body: 'Hello 1',
          countsAsUnread: true,
          createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
        ),
        ChatMessageDto(
          messageId: 'm-2',
          messageSeq: 2,
          channelId: 'ch-1',
          senderId: otherUserId,
          body: 'Hello 2',
          countsAsUnread: true,
          createdAt: now.subtract(const Duration(minutes: 4)).toIso8601String(),
        ),
        ChatMessageDto(
          messageId: 'm-3',
          messageSeq: 3,
          channelId: 'ch-1',
          senderId: otherUserId,
          body: 'Hello 3',
          countsAsUnread: true,
          createdAt: now.subtract(const Duration(minutes: 3)).toIso8601String(),
        ),
      ], currentUserId);

      final inbox = await dataSource.watchInbox(currentUserId).first;

      expect(inbox.length, 2);
      // Pinned channel ch-2 should be first
      expect(inbox.first.id, 'ch-2');
      expect(inbox.first.isPinned, isTrue);

      // ch-1 should have 3 unread messages
      final ch1 = inbox.firstWhere((c) => c.id == 'ch-1');
      expect(ch1.unreadCount, 3);
      expect(ch1.lastMessagePreview, 'Hello 3');

      // Now update read horizon to seq 2
      await dataSource.updateMemberHorizons('ch-1', currentUserId, readSeq: 2);

      final updatedInbox = await dataSource.watchInbox(currentUserId).first;
      final ch1Updated = updatedInbox.firstWhere((c) => c.id == 'ch-1');
      // Only message seq 3 should be unread now
      expect(ch1Updated.unreadCount, 1);
    });
  });

  group('ChatLocalDataSource - Messages Stream & Outbox', () {
    test('watchMessages places pending outbox messages chronologically at bottom', () async {
      const channelId = 'ch-thread-1';
      final now = DateTime.now().toUtc();

      // Confirmed server messages
      await dataSource.upsertMessagesFromDto([
        ChatMessageDto(
          messageId: 'srv-1',
          messageSeq: 10,
          channelId: channelId,
          senderId: otherUserId,
          body: 'Server message 1',
          createdAt: now.subtract(const Duration(minutes: 10)).toIso8601String(),
        ),
        ChatMessageDto(
          messageId: 'srv-2',
          messageSeq: 11,
          channelId: channelId,
          senderId: otherUserId,
          body: 'Server message 2',
          createdAt: now.subtract(const Duration(minutes: 9)).toIso8601String(),
        ),
      ], currentUserId);

      // Local outbox optimistic send (no server seq yet)
      await dataSource.enqueueOutgoingMessage(
        message: LocalMessagesCompanion.insert(
          messageId: 'local-msg-1',
          channelId: channelId,
          senderId: const drift.Value(currentUserId),
          body: const drift.Value('Optimistic outgoing message'),
          localCreatedAt: now,
          syncStatus: const drift.Value('pending'),
        ),
        operation: OutboxOperationsCompanion.insert(
          operationId: 'op-1',
          channelId: channelId,
          entityId: const drift.Value('local-msg-1'),
          operationType: 'send_message',
          payloadJson: '{"message_id": "local-msg-1"}',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final messages = await dataSource.watchMessages(channelId, currentUserId).first;

      expect(messages.length, 3);
      expect(messages[0].id, 'srv-1');
      expect(messages[0].messageSeq, 10);
      expect(messages[1].id, 'srv-2');
      expect(messages[1].messageSeq, 11);
      // Pending local message is at the bottom
      expect(messages[2].id, 'local-msg-1');
      expect(messages[2].messageSeq, isNull);
      expect(messages[2].isPending, isTrue);

      // Verify outbox operation is queued
      final pendingOps = await dataSource.getPendingOperations(channelId: channelId);
      expect(pendingOps.length, 1);
      expect(pendingOps.first.operationId, 'op-1');
      expect(pendingOps.first.status, 'pending');

      // Now server confirms message with seq 12
      await dataSource.updateMessageSyncStatus(
        'local-msg-1',
        syncStatus: 'sent',
        messageSeq: 12,
      );
      await dataSource.deleteOutboxOperation('op-1');

      final confirmedMessages = await dataSource.watchMessages(channelId, currentUserId).first;
      expect(confirmedMessages.last.messageSeq, 12);
      expect(confirmedMessages.last.syncStatus, 'sent');

      final emptyOps = await dataSource.getPendingOperations(channelId: channelId);
      expect(emptyOps, isEmpty);
    });
  });
}
