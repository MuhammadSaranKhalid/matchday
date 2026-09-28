import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:matchday/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:matchday/features/messages/data/models/chat_channel_dto.dart';
import 'package:matchday/features/messages/data/models/chat_message_dto.dart';
import 'package:matchday/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:matchday/features/messages/data/sync/chat_sync_coordinator.dart';
import 'package:matchday/features/messages/data/sync/outbox_processor.dart';
import 'package:matchday/features/messages/data/sync/receipt_coordinator.dart';
import 'package:matchday/features/messages/data/sync/realtime_ingestor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRemoteDataSource extends Mock implements ChatRemoteDataSource {}
class _MockOutboxProcessor extends Mock implements OutboxProcessor {}
class _MockRealtimeIngestor extends Mock implements RealtimeIngestor {}
class _MockChatSyncCoordinator extends Mock implements ChatSyncCoordinator {}
class _MockReceiptCoordinator extends Mock implements ReceiptCoordinator {}
class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late AppDatabase db;
  late ChatLocalDataSource local;
  late _MockRemoteDataSource remote;
  late _MockOutboxProcessor outbox;
  late _MockRealtimeIngestor ingestor;
  late _MockChatSyncCoordinator syncCoord;
  late _MockReceiptCoordinator receipts;
  late _MockSupabaseClient supabase;
  late _MockGoTrueClient auth;
  late ChatRepositoryImpl repo;

  const currentUserId = 'user-test-repo';
  const channelId = 'ch-repo-1';
  const messageId = 'msg-test-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = ChatLocalDataSource(db);
    remote = _MockRemoteDataSource();
    outbox = _MockOutboxProcessor();
    ingestor = _MockRealtimeIngestor();
    syncCoord = _MockChatSyncCoordinator();
    receipts = _MockReceiptCoordinator();
    supabase = _MockSupabaseClient();
    auth = _MockGoTrueClient();

    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(
      User(
        id: currentUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    when(() => outbox.notify()).thenReturn(null);

    repo = ChatRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      outboxProcessor: outbox,
      realtimeIngestor: ingestor,
      syncCoordinator: syncCoord,
      receiptCoordinator: receipts,
      supabase: supabase,
    );

    // Insert dummy channel and initial message
    final now = DateTime.now().toUtc();
    await local.upsertChannelsFromDto([
      ChatChannelDto(
        channelId: channelId,
        channelKey: 'direct:1:2',
        kind: 'direct',
        contextType: 'none',
        title: 'Direct Chat',
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
    ], currentUserId);

    await db.into(db.localMessages).insert(
      LocalMessagesCompanion.insert(
        messageId: messageId,
        channelId: channelId,
        senderId: const Value(currentUserId),
        body: const Value('Original message'),
        localCreatedAt: now,
        syncStatus: const Value('failed'),
        sendErrorCode: const Value('network_error'),
        sendErrorMessage: const Value('Connection reset'),
      ),
    );

    await db.into(db.outboxOperations).insert(
      OutboxOperationsCompanion.insert(
        operationId: 'op-failed-1',
        channelId: channelId,
        entityId: const Value(messageId),
        operationType: 'send_message',
        payloadJson: jsonEncode({'message_id': messageId, 'body': 'Original message'}),
        status: const Value('failed'),
        attemptCount: const Value(5),
        lastErrorCode: const Value('network_error'),
        lastErrorMessage: const Value('Connection reset'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ChatRepositoryImpl & Local-First Invariants', () {
    test('O. Failed send retry resets message & Outbox operation atomically (Spec §19)', () async {
      final result = await repo.retryMessage(messageId);
      expect(result.isRight(), isTrue);

      // Verify outbox worker was notified
      verify(() => outbox.notify()).called(1);

      // Verify local message status was reset
      final msg = await local.getMessage(messageId);
      expect(msg, isNotNull);
      expect(msg!.syncStatus, 'pending');
      expect(msg.sendErrorCode, isNull);
      expect(msg.sendErrorMessage, isNull);

      // Verify Outbox operation status was reset
      final op = await (db.select(db.outboxOperations)
            ..where((o) => o.entityId.equals(messageId)))
          .getSingle();
      expect(op.status, 'pending');
      expect(op.attemptCount, 0);
      expect(op.nextAttemptAt, isNull);
      expect(op.lastErrorCode, isNull);
      expect(op.lastErrorMessage, isNull);
    });

    test('P. editMessage performs single write path (optimistic Drift + Outbox op, ZERO remote call) (Spec §18)', () async {
      final result = await repo.editMessage(messageId, 1, 'Edited text body');
      expect(result.isRight(), isTrue);

      final editedMessage = result.getOrElse((_) => throw Exception());
      expect(editedMessage.body, 'Edited text body');

      // Verify ZERO remote calls were made from repository
      verifyZeroInteractions(remote);

      // Verify outbox worker was notified
      verify(() => outbox.notify()).called(1);

      // Verify local message was updated in Drift
      final msg = await local.getMessage(messageId);
      expect(msg!.body, 'Edited text body');
      expect(msg.editedAt, isNotNull);

      // Verify Outbox operation was created with proper channelId lane
      final editOp = await (db.select(db.outboxOperations)
            ..where((o) => o.operationType.equals('edit_message')))
          .getSingle();
      expect(editOp.channelId, channelId);
      expect(editOp.entityId, messageId);
      expect(editOp.status, 'pending');
    });

    test('F. Duplicate message idempotency: multiple deliveries result in exactly 1 local row (Spec §30)', () async {
      final now = DateTime.now().toUtc();
      final dto = ChatMessageDto(
        messageId: 'msg-idempotent-1',
        messageSeq: 105,
        channelId: channelId,
        senderId: 'other-user',
        senderDisplayName: 'Other User',
        messageType: 'text',
        body: 'Idempotency test',
        createdAt: now.toIso8601String(),
        countsAsUnread: true,
      );

      // First ingestion (e.g. from Ably)
      await local.upsertMessagesFromDto([dto], currentUserId);

      // Duplicate ingestion (e.g. from Supabase catch-up delta)
      await local.upsertMessagesFromDto([dto], currentUserId);

      final rows = await (db.select(db.localMessages)
            ..where((m) => m.messageId.equals('msg-idempotent-1')))
          .get();
      expect(rows, hasLength(1));
      expect(rows.first.body, 'Idempotency test');
      expect(rows.first.messageSeq, 105);
    });

    test('watchPresence delegates to realtimeIngestor', () {
      when(() => ingestor.watchPresence(channelId))
          .thenAnswer((_) => Stream.value({'user-1', 'user-2'}));

      final stream = repo.watchPresence(channelId);

      expect(stream, emits({'user-1', 'user-2'}));
      verify(() => ingestor.watchPresence(channelId)).called(1);
    });

    test('acceptDirectRequest updates local membership active and enqueues outbox op without network call', () async {
      final now = DateTime.now().toUtc();
      await local.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: channelId,
          channelKey: 'dm:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Direct Chat',
          isAccepted: false,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      final result = await repo.acceptDirectRequest(channelId);
      expect(result.isRight(), isTrue);

      final member = await (db.select(db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(currentUserId)))
          .getSingle();
      expect(member.status, 'active');

      final op = await (db.select(db.outboxOperations)
            ..where((o) => o.channelId.equals(channelId) & o.operationType.equals('accept_invite')))
          .getSingle();
      expect(op.status, 'pending');
      verify(() => outbox.notify()).called(1);
      verifyZeroInteractions(remote);
    });

    test('declineDirectRequest updates local membership declined and enqueues outbox op without network call', () async {
      final now = DateTime.now().toUtc();
      await local.upsertChannelsFromDto([
        ChatChannelDto(
          channelId: channelId,
          channelKey: 'dm:1:2',
          kind: 'direct',
          contextType: 'none',
          title: 'Direct Chat',
          isAccepted: false,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        ),
      ], currentUserId);

      final result = await repo.declineDirectRequest(channelId);
      expect(result.isRight(), isTrue);

      final member = await (db.select(db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(currentUserId)))
          .getSingle();
      expect(member.status, 'declined');

      final op = await (db.select(db.outboxOperations)
            ..where((o) => o.channelId.equals(channelId) & o.operationType.equals('decline_invite')))
          .getSingle();
      expect(op.status, 'pending');
      verify(() => outbox.notify()).called(1);
      verifyZeroInteractions(remote);
    });
  });
}

