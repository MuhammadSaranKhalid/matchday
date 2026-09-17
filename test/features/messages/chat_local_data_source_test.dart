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
    test('inbox projection works with ZERO LocalMessages (31A)', () async {
      final now = DateTime.now().toUtc();

      await dataSource.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: 'ch-zero-msg',
          channelKey: 'team:t1:main',
          kind: 'group',
          contextType: 'team',
          title: 'Team Chat',
          lastMessageBody: 'hello',
          unreadCount: 4,
          lastMessageSeq: 100,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // Verify ZERO local messages exist in the database
      final allMessages = await db.select(db.localMessages).get();
      expect(allMessages, isEmpty);

      // watchInbox must still project preview 'hello' and unread = 4
      final inbox = await dataSource.watchInbox(currentUserId).first;
      expect(inbox.length, 1);
      expect(inbox.first.id, 'ch-zero-msg');
      expect(inbox.first.lastMessagePreview, 'hello');
      expect(inbox.first.unreadCount, 4);
    });

    test('global sparse sequence does NOT estimate lastReadSeq = lastMessageSeq - unreadCount (31B)', () async {
      final now = DateTime.now().toUtc();

      await dataSource.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: 'ch-sparse',
          channelKey: 'direct:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Sparse Channel',
          lastMessageSeq: 970,
          unreadCount: 2,
          lastReadMessageSeq: 900, // Explicit member horizon from server
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // Check member horizon in DB
      final member = await (db.select(db.localChannelMembers)
            ..where((m) => m.channelId.equals('ch-sparse') & m.userId.equals(currentUserId)))
          .getSingle();

      // Must be exact server value (900), NOT calculated (970 - 2 = 968)
      expect(member.lastReadMessageSeq, 900);
      expect(member.lastReadMessageSeq, isNot(968));
    });

    test('watchInbox emits channels with authoritative unread count and sorting', () async {
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
          lastMessageBody: 'Hello 3',
          lastMessageSeq: 3,
          unreadCount: 3,
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

      final inbox = await dataSource.watchInbox(currentUserId).first;

      expect(inbox.length, 2);
      // Pinned channel ch-2 should be first
      expect(inbox.first.id, 'ch-2');
      expect(inbox.first.isPinned, isTrue);

      // ch-1 should have 3 unread messages
      final ch1 = inbox.firstWhere((c) => c.id == 'ch-1');
      expect(ch1.unreadCount, 3);
      expect(ch1.lastMessagePreview, 'Hello 3');

      // Now update read horizon to seq 3 (fully read)
      await dataSource.updateMemberHorizons('ch-1', currentUserId, readSeq: 3);

      final updatedInbox = await dataSource.watchInbox(currentUserId).first;
      final ch1Updated = updatedInbox.firstWhere((c) => c.id == 'ch-1');
      expect(ch1Updated.unreadCount, 0);
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

    test('prunes channels absent from server unless pending outbox operations exist', () async {
      final now = DateTime.now().toUtc();

      // 1. Initially user has 3 channels: ch-A, ch-B, ch-C
      await dataSource.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: 'ch-A',
          channelKey: 'team:t1:main',
          kind: 'group',
          contextType: 'team',
          title: 'Chat A',
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
        ChatChannelDto(
          channelId: 'ch-B',
          channelKey: 'team:t2:main',
          kind: 'group',
          contextType: 'team',
          title: 'Chat B',
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
        ChatChannelDto(
          channelId: 'ch-C',
          channelKey: 'team:t3:main',
          kind: 'group',
          contextType: 'team',
          title: 'Chat C',
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      var inbox = await dataSource.watchInbox(currentUserId).first;
      expect(inbox.map((c) => c.id).toSet(), {'ch-A', 'ch-B', 'ch-C'});

      // 2. Queue a pending outbox operation in ch-C
      await dataSource.enqueueOperation(OutboxOperationsCompanion.insert(
        operationId: 'op-ch-c',
        channelId: 'ch-C',
        operationType: 'send_message',
        payloadJson: '{"message_id": "m-c"}',
        createdAt: now,
        updatedAt: now,
      ));

      // 3. Authoritative server sync returns ONLY ch-A (ch-B and ch-C are absent from server)
      await dataSource.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: 'ch-A',
          channelKey: 'team:t1:main',
          kind: 'group',
          contextType: 'team',
          title: 'Chat A',
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      inbox = await dataSource.watchInbox(currentUserId).first;
      final inboxIds = inbox.map((c) => c.id).toSet();

      // ch-A must be present
      expect(inboxIds.contains('ch-A'), isTrue);
      // ch-B had no pending outbox ops and was absent from server -> must be PRUNED!
      expect(inboxIds.contains('ch-B'), isFalse);
      // ch-C was absent from server BUT has a pending outbox op -> must be PROTECTED!
      expect(inboxIds.contains('ch-C'), isTrue);
    });

    test('watchInbox excludes channels where membership is declined or left', () async {
      final now = DateTime.now().toUtc();

      await dataSource.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: 'ch-declined',
          channelKey: 'dm:u1:u2',
          kind: 'direct',
          contextType: 'direct',
          title: 'Declined DM',
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      // Verify initially visible as pending/active
      var inbox = await dataSource.watchInbox(currentUserId).first;
      expect(inbox.length, 1);

      // Mark declined
      await dataSource.updateMemberStatus('ch-declined', currentUserId, 'declined');

      inbox = await dataSource.watchInbox(currentUserId).first;
      expect(inbox, isEmpty);
    });
  });
}
