import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/value_objects/message_body.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../sync/chat_sync_coordinator.dart';
import '../sync/outbox_processor.dart';
import '../sync/realtime_ingestor.dart';

/// Production implementation of ChatRepository.
/// Follows Clean Architecture, local-first outbox pattern, and reactive Drift streams.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    required ChatRemoteDataSource remoteDataSource,
    required OutboxProcessor outboxProcessor,
    required RealtimeIngestor realtimeIngestor,
    required ChatSyncCoordinator syncCoordinator,
    required SupabaseClient supabase,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _outbox = outboxProcessor,
        _ingestor = realtimeIngestor,
        _syncCoordinator = syncCoordinator,
        _supabase = supabase {
    // Background outbox drain on startup
    _outbox.notify();

    // Subscribe to user inbox real-time events
    final userId = _currentUserId;
    if (userId != null) {
      _ingestor.subscribeToUserInbox(
        userId,
        onUpdated: () => _syncCoordinator.syncInbox(userId),
      );
    }
  }

  final ChatLocalDataSource _local;
  final ChatRemoteDataSource _remote;
  final OutboxProcessor _outbox;
  final RealtimeIngestor _ingestor;
  final ChatSyncCoordinator _syncCoordinator;
  final SupabaseClient _supabase;

  static const _uuid = Uuid();

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  Stream<List<ChatChannel>> watchInbox() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    // Trigger asynchronous background sync
    unawaited(_syncCoordinator.syncInbox(userId));

    // Return reactive Drift stream (single read path)
    return _local.watchInbox(userId);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(
    String channelId, {
    int? beforeMessageSeq,
  }) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    // Trigger open-channel sequence asynchronously
    unawaited(_syncCoordinator.openChannel(channelId, userId));

    return _local.watchMessages(
      channelId,
      userId,
      beforeMessageSeq: beforeMessageSeq,
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    String channelId,
    MessageBody body, {
    String? replyToId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final messageId = _uuid.v4();
      final now = DateTime.now().toUtc();

      // Optimistic message row
      final messageComp = LocalMessagesCompanion.insert(
        messageId: messageId,
        channelId: channelId,
        senderId: Value(userId),
        body: Value(body.value),
        messageType: const Value('text'),
        replyToMessageId: Value(replyToId),
        countsAsUnread: const Value(true),
        localCreatedAt: now,
        createdAt: Value(now),
        syncStatus: const Value('pending'),
      );

      // Outbox operation row
      final opComp = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        channelId: channelId,
        entityId: Value(messageId),
        operationType: 'send_message',
        payloadJson: jsonEncode({
          'message_id': messageId,
          'channel_id': channelId,
          'body': body.value,
          'message_type': 'text',
          'reply_to_message_id': replyToId,
        }),
        createdAt: now,
        updatedAt: now,
      );

      // Atomic Drift commit
      await _local.enqueueOutgoingMessage(
        message: messageComp,
        operation: opComp,
      );

      // Notify background worker
      _outbox.notify();

      final optimisticEntity = ChatMessage(
        id: messageId,
        channelId: channelId,
        senderId: userId,
        messageType: 'text',
        body: body.value,
        replyToId: replyToId,
        createdAt: now,
        fromMe: true,
        syncStatus: 'pending',
        deliveryStatus: MessageDeliveryStatus.pending,
      );

      return right(optimisticEntity);
    } catch (e) {
      return left(CacheFailure('Failed to enqueue message: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendImageMessage(
    String channelId, {
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final messageId = _uuid.v4();
      final attachmentId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final mimeType = extension.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';

      // 1. Cache image locally so it can be previewed immediately offline
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/chat_$attachmentId.$extension';
      final localFile = io.File(localPath);
      await localFile.writeAsBytes(imageBytes);

      // 2. Commit to Drift + Outbox
      final messageComp = LocalMessagesCompanion.insert(
        messageId: messageId,
        channelId: channelId,
        senderId: Value(userId),
        body: Value(caption ?? ''),
        messageType: const Value('image'),
        payloadJson: Value(jsonEncode({'local_path': localPath})),
        replyToMessageId: Value(replyToId),
        countsAsUnread: const Value(true),
        localCreatedAt: now,
        createdAt: Value(now),
        syncStatus: const Value('pending'),
      );

      final attComp = LocalMessageAttachmentsCompanion.insert(
        attachmentId: attachmentId,
        messageId: messageId,
        localPath: Value(localPath),
        mimeType: mimeType,
        sizeBytes: Value(imageBytes.length),
        uploadStatus: const Value('pending'),
      );

      final opComp = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        channelId: channelId,
        entityId: Value(messageId),
        operationType: 'send_message',
        payloadJson: jsonEncode({
          'message_id': messageId,
          'channel_id': channelId,
          'body': caption ?? '',
          'message_type': 'image',
          'attachment_id': attachmentId,
          'local_path': localPath,
          'extension': extension,
          'mime_type': mimeType,
          'reply_to_message_id': replyToId,
        }),
        createdAt: now,
        updatedAt: now,
      );

      await _local.enqueueOutgoingMessage(
        message: messageComp,
        operation: opComp,
        attachments: [attComp],
      );

      _outbox.notify();

      final optimisticEntity = ChatMessage(
        id: messageId,
        channelId: channelId,
        senderId: userId,
        messageType: 'image',
        body: caption ?? '',
        payload: {'local_path': localPath},
        replyToId: replyToId,
        createdAt: now,
        fromMe: true,
        syncStatus: 'pending',
        deliveryStatus: MessageDeliveryStatus.pending,
        attachments: [
          MessageAttachment(
            id: attachmentId,
            messageId: messageId,
            localPath: localPath,
            mimeType: mimeType,
            sizeBytes: imageBytes.length,
            uploadStatus: 'pending',
          ),
        ],
      );

      return right(optimisticEntity);
    } catch (e) {
      return left(CacheFailure('Failed to enqueue image message: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> editMessage(
    String messageId,
    int expectedVersion,
    String newBody,
  ) async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final now = DateTime.now().toUtc();
      final opComp = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        channelId: '', // entity level
        entityId: Value(messageId),
        operationType: 'edit_message',
        payloadJson: jsonEncode({
          'message_id': messageId,
          'expected_version': expectedVersion,
          'body': newBody,
        }),
        createdAt: now,
        updatedAt: now,
      );

      await _local.enqueueOperation(opComp);
      _outbox.notify();

      final updated = await _remote.editChannelMessage(
        messageId: messageId,
        expectedVersion: expectedVersion,
        newBody: newBody,
      );

      return right(updated.toEntity());
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Failed to edit message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(String channelId, String messageId) async {
    try {
      final now = DateTime.now().toUtc();
      await _local.softDeleteMessageLocally(messageId);

      final opComp = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        channelId: channelId,
        entityId: Value(messageId),
        operationType: 'delete_message',
        payloadJson: jsonEncode({'message_id': messageId}),
        createdAt: now,
        updatedAt: now,
      );

      await _local.enqueueOperation(opComp);
      _outbox.notify();

      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to delete message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> retryMessage(String messageId) async {
    try {
      await _local.updateMessageSyncStatus(messageId, syncStatus: 'pending');
      _outbox.notify();
      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to retry message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markRead(String channelId, [int? throughMessageSeq]) async {
    final userId = _currentUserId;
    if (userId == null) return right(unit);

    try {
      final seq = (throughMessageSeq != null &&
              throughMessageSeq > 0 &&
              throughMessageSeq != 999999999)
          ? throughMessageSeq
          : await _local.getLatestMessageSeq(channelId);

      // Guard: If channel has no messages, never store or enqueue 0.
      if (seq == null || seq <= 0) {
        return right(unit);
      }

      await _local.updateMemberHorizons(
        channelId,
        userId,
        readSeq: seq,
        deliveredSeq: seq,
      );

      final opRead = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        channelId: channelId,
        operationType: 'mark_read',
        coalesceKey: Value('read:$channelId'),
        payloadJson: jsonEncode({'through_seq': seq}),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await _local.enqueueOperation(opRead);

      _outbox.notify();

      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to mark read: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markDelivered(String channelId, int throughMessageSeq) async {
    final userId = _currentUserId;
    if (userId == null) return right(unit);
    if (throughMessageSeq <= 0) return right(unit);

    try {
      await _local.updateMemberHorizons(channelId, userId, deliveredSeq: throughMessageSeq);

      final opComp = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        channelId: channelId,
        operationType: 'mark_delivered',
        coalesceKey: Value('delivered:$channelId'),
        payloadJson: jsonEncode({'through_seq': throughMessageSeq}),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await _local.enqueueOperation(opComp);
      _outbox.notify();

      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to mark delivered: $e'));
    }
  }

  @override
  void closeChannel(String channelId) {
    _syncCoordinator.closeChannel(channelId);
  }

  @override
  Future<Either<Failure, Unit>> setReaction(
    String messageId,
    String reaction,
    bool selected,
  ) async {
    try {
      final opComp = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        channelId: '',
        entityId: Value(messageId),
        operationType: 'set_reaction',
        coalesceKey: Value('reaction:$messageId:$reaction'),
        payloadJson: jsonEncode({
          'reaction': reaction,
          'selected': selected,
        }),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await _local.enqueueOperation(opComp);
      _outbox.notify();

      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to set reaction: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getOrCreateDmChat(String targetUserId) async {
    try {
      final channelId = await _remote.getOrCreateDirectChannel(targetUserId);
      final userId = _currentUserId;
      if (userId != null) {
        await _syncCoordinator.syncInbox(userId);
      }
      return right(channelId);
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Failed to open direct message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptDirectRequest(String channelId) async {
    try {
      await _remote.acceptChannelInvite(channelId);
      final userId = _currentUserId;
      if (userId != null) {
        await _syncCoordinator.syncInbox(userId);
      }
      return right(unit);
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Failed to accept chat: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> declineDirectRequest(String channelId) async {
    try {
      await _remote.declineChannelInvite(channelId);
      final userId = _currentUserId;
      if (userId != null) {
        await _syncCoordinator.syncInbox(userId);
      }
      return right(unit);
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Failed to decline chat: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> loadOlderMessages(String channelId) async {
    final userId = _currentUserId;
    if (userId == null) return right(0);

    try {
      final count = await _syncCoordinator.loadOlderMessages(channelId, userId);
      return right(count);
    } catch (e) {
      return left(ServerFailure('Failed to load older messages: $e'));
    }
  }

  @override
  Future<String?> readDraft(String channelId) => _local.readDraft(channelId);

  @override
  Future<void> saveDraft(String channelId, String body) =>
      _local.saveDraft(channelId, body);

  @override
  Future<void> deleteDraft(String channelId) => _local.deleteDraft(channelId);

  @override
  Stream<bool> watchTyping(String channelId) => _ingestor.watchTyping(channelId);

  @override
  Future<void> setTyping(String channelId, bool isTyping) async {
    final userId = _currentUserId;
    if (userId != null) {
      await _ingestor.publishTyping(channelId, userId, isTyping);
    }
  }
}
