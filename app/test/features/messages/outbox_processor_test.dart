import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:matchday/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:matchday/features/messages/data/models/chat_message_dto.dart';
import 'package:matchday/features/messages/data/sync/outbox_processor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRemoteDataSource extends Mock implements ChatRemoteDataSource {}

void main() {
  late AppDatabase db;
  late ChatLocalDataSource local;
  late _MockRemoteDataSource remote;
  late OutboxProcessor outbox;

  const currentUserId = 'user-123';
  const channelId = 'ch-test-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = ChatLocalDataSource(db);
    remote = _MockRemoteDataSource();
    outbox = OutboxProcessor(local, remote);
  });

  tearDown(() async {
    outbox.dispose();
    await db.close();
  });

  group('OutboxProcessor', () {
    test('drains pending send_message op, updates local message, and deletes op', () async {
      final now = DateTime.now().toUtc();
      const messageId = 'msg-out-1';
      const opId = 'op-out-1';

      // 1. Enqueue outgoing message into Drift
      await local.enqueueOutgoingMessage(
        message: LocalMessagesCompanion.insert(
          messageId: messageId,
          channelId: channelId,
          senderId: const drift.Value(currentUserId),
          body: const drift.Value('Hello Outbox'),
          localCreatedAt: now,
          syncStatus: const drift.Value('pending'),
        ),
        operation: OutboxOperationsCompanion.insert(
          operationId: opId,
          channelId: channelId,
          entityId: const drift.Value(messageId),
          operationType: 'send_message',
          payloadJson: jsonEncode({
            'message_id': messageId,
            'channel_id': channelId,
            'body': 'Hello Outbox',
            'message_type': 'text',
          }),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 2. Mock remote response
      when(() => remote.sendChannelMessage(
            messageId: messageId,
            channelId: channelId,
            messageType: 'text',
            body: 'Hello Outbox',
            replyToMessageId: null,
            payload: null,
          )).thenAnswer(
        (_) async => ChatMessageDto(
          messageId: messageId,
          messageSeq: 42,
          channelId: channelId,
          senderId: currentUserId,
          body: 'Hello Outbox',
          version: 1,
          createdAt: now.toIso8601String(),
        ),
      );

      // 3. Drain
      await outbox.drain();

      // 4. Verify remote called
      verify(() => remote.sendChannelMessage(
            messageId: messageId,
            channelId: channelId,
            messageType: 'text',
            body: 'Hello Outbox',
            replyToMessageId: null,
            payload: null,
          )).called(1);

      // 5. Verify local message is confirmed with server seq
      final messages = await local.watchMessages(channelId, currentUserId).first;
      expect(messages.first.messageSeq, 42);
      expect(messages.first.syncStatus, 'sent');

      // 6. Verify outbox is drained
      final remainingOps = await local.getPendingOperations(channelId: channelId);
      expect(remainingOps, isEmpty);
    });

    test('marks operation as failed on terminal permission error (42501)', () async {
      final now = DateTime.now().toUtc();
      const messageId = 'msg-out-2';
      const opId = 'op-out-2';

      await local.enqueueOutgoingMessage(
        message: LocalMessagesCompanion.insert(
          messageId: messageId,
          channelId: channelId,
          senderId: const drift.Value(currentUserId),
          body: const drift.Value('Blocked text'),
          localCreatedAt: now,
          syncStatus: const drift.Value('pending'),
        ),
        operation: OutboxOperationsCompanion.insert(
          operationId: opId,
          channelId: channelId,
          entityId: const drift.Value(messageId),
          operationType: 'send_message',
          payloadJson: jsonEncode({
            'message_id': messageId,
            'channel_id': channelId,
            'body': 'Blocked text',
            'message_type': 'text',
          }),
          createdAt: now,
          updatedAt: now,
        ),
      );

      when(() => remote.sendChannelMessage(
            messageId: messageId,
            channelId: channelId,
            messageType: 'text',
            body: 'Blocked text',
            replyToMessageId: null,
            payload: null,
          )).thenThrow(
        const PostgrestException(
          message: 'Permission denied: send_messages not permitted',
          code: '42501',
        ),
      );

      await outbox.drain();

      // Message and operation should be marked 'failed'
      final messages = await local.watchMessages(channelId, currentUserId).first;
      expect(messages.first.syncStatus, 'failed');
      expect(messages.first.isFailed, isTrue);

      final opRow = await (db.select(db.outboxOperations)
            ..where((o) => o.operationId.equals(opId)))
          .getSingle();
      expect(opRow.status, 'failed');
      expect(opRow.lastErrorCode, '42501');
    });

    test('preserves attemptCount and keeps retry_wait on offline SocketException', () async {
      final now = DateTime.now().toUtc();
      const messageId = 'msg-offline-1';
      const opId = 'op-offline-1';

      await local.enqueueOutgoingMessage(
        message: LocalMessagesCompanion.insert(
          messageId: messageId,
          channelId: channelId,
          senderId: const drift.Value(currentUserId),
          body: const drift.Value('Offline message'),
          localCreatedAt: now,
          syncStatus: const drift.Value('pending'),
        ),
        operation: OutboxOperationsCompanion.insert(
          operationId: opId,
          channelId: channelId,
          entityId: const drift.Value(messageId),
          operationType: 'send_message',
          payloadJson: jsonEncode({
            'message_id': messageId,
            'channel_id': channelId,
            'body': 'Offline message',
            'message_type': 'text',
          }),
          createdAt: now,
          updatedAt: now,
        ),
      );

      when(() => remote.sendChannelMessage(
            messageId: messageId,
            channelId: channelId,
            messageType: 'text',
            body: 'Offline message',
            replyToMessageId: null,
            payload: null,
          )).thenThrow(
        const SocketException('Failed host lookup: api.supabase.co'),
      );

      // Attempt 1 offline
      await outbox.drain();

      var opRow = await (db.select(db.outboxOperations)
            ..where((o) => o.operationId.equals(opId)))
          .getSingle();
      expect(opRow.status, 'retry_wait');
      // Retry budget must NOT be consumed!
      expect(opRow.attemptCount, 0);
      expect(opRow.lastErrorCode, 'NETWORK_OFFLINE');

      // Attempt 2, 3, 4, 5, 6 offline
      for (var i = 0; i < 5; i++) {
        await outbox.drain();
      }

      opRow = await (db.select(db.outboxOperations)
            ..where((o) => o.operationId.equals(opId)))
          .getSingle();
      // Still NOT failed!
      expect(opRow.status, 'retry_wait');
      expect(opRow.attemptCount, 0);

      // Message in local table must NOT be marked failed
      final messages = await local.watchMessages(channelId, currentUserId).first;
      expect(messages.first.syncStatus, 'pending');
      expect(messages.first.isFailed, isFalse);
    });
  });
}
