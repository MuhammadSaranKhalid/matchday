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
import '../../domain/entities/chat_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/entities/chat_sync_state.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/value_objects/message_body.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../sync/chat_sync_coordinator.dart';
import '../sync/outbox_processor.dart';
import '../sync/receipt_coordinator.dart';
import '../sync/realtime_ingestor.dart';

/// Production local-first implementation of [ChatRepository].
///
/// Presentation reads ONLY Drift streams. Supabase is the authoritative remote
/// write/reconciliation source and the Outbox is the only path for durable
/// offline mutations.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    required ChatRemoteDataSource remoteDataSource,
    required OutboxProcessor outboxProcessor,
    required RealtimeIngestor realtimeIngestor,
    required ChatSyncCoordinator syncCoordinator,
    required ReceiptCoordinator receiptCoordinator,
    required SupabaseClient supabase,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _outbox = outboxProcessor,
        _ingestor = realtimeIngestor,
        _syncCoordinator = syncCoordinator,
        _receiptCoordinator = receiptCoordinator,
        _supabase = supabase;

  final ChatLocalDataSource _local;
  final ChatRemoteDataSource _remote;
  final OutboxProcessor _outbox;
  final RealtimeIngestor _ingestor;
  final ChatSyncCoordinator _syncCoordinator;
  final ReceiptCoordinator _receiptCoordinator;
  final SupabaseClient _supabase;

  static const _uuid = Uuid();

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  Stream<List<ChatChannel>> watchInbox() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(const []);
    return _local.watchInbox(userId);
  }

  @override
  Future<Either<Failure, Unit>> refreshInbox() async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      await _syncCoordinator.syncInbox(userId);
      return right(unit);
    } catch (e) {
      return left(ServerFailure('Failed to refresh chats: $e'));
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(
    String channelId, {
    int? beforeMessageSeq,
  }) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(const <ChatMessage>[]);

    // Drift remains the immediate UI source. The coordinator owns the
    // realtime/Presence policy and opens the transport exactly once for the
    // lifetime of the thread provider.
    unawaited(
      _syncCoordinator.openChannel(
        channelId,
        userId,
      ),
    );

    return _local.watchMessages(
      channelId,
      userId,
      beforeMessageSeq: beforeMessageSeq,
    );
  }

  @override
  Stream<List<ChatParticipant>> watchParticipants(String channelId) =>
      _local.watchParticipants(channelId);

  @override
  Stream<ChatSyncState> watchSyncState(String channelId) =>
      _local.watchChannelSyncState(channelId);

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

      final message = LocalMessagesCompanion.insert(
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

      final operation = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
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

      await _local.enqueueOutgoingMessage(
        message: message,
        operation: operation,
      );
      _outbox.notify();

      return right(
        ChatMessage(
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
        ),
      );
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
      final normalizedExt = extension.replaceFirst('.', '').toLowerCase();
      final mimeType = normalizedExt == 'png' ? 'image/png' : 'image/jpeg';

      // A durable application-support file keeps an offline image available
      // even when the OS clears the image picker's temporary file.
      final supportDir = await getApplicationSupportDirectory();
      final outboxDir = io.Directory(
        '${supportDir.path}/chat_outbox/$userId/$channelId',
      );
      if (!await outboxDir.exists()) {
        await outboxDir.create(recursive: true);
      }

      final localPath = '${outboxDir.path}/$attachmentId.$normalizedExt';
      await io.File(localPath).writeAsBytes(imageBytes);

      final message = LocalMessagesCompanion.insert(
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

      final attachment = LocalMessageAttachmentsCompanion.insert(
        attachmentId: attachmentId,
        messageId: messageId,
        localPath: Value(localPath),
        mimeType: mimeType,
        sizeBytes: Value(imageBytes.length),
        uploadStatus: const Value('pending'),
      );

      final operation = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
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
          'extension': normalizedExt,
          'mime_type': mimeType,
          'reply_to_message_id': replyToId,
        }),
        createdAt: now,
        updatedAt: now,
      );

      await _local.enqueueOutgoingMessage(
        message: message,
        operation: operation,
        attachments: [attachment],
      );
      _outbox.notify();

      return right(
        ChatMessage(
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
        ),
      );
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
      final existing = await _local.getMessage(messageId);
      if (existing == null) {
        return left(const NotFoundFailure('Message not found locally'));
      }

      if (existing.senderId != userId) {
        return left(const AuthFailure('You can only edit your own message'));
      }
      if (existing.deletedAt != null) {
        return left(const ValidationFailure('Deleted messages cannot be edited'));
      }
      if (existing.messageSeq == null) {
        return left(
          const ValidationFailure(
            'Wait for this message to send before editing it',
          ),
        );
      }

      final now = DateTime.now().toUtc();
      final operation = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
        channelId: existing.channelId,
        entityId: Value(messageId),
        operationType: 'edit_message',
        payloadJson: jsonEncode({
          'message_id': messageId,
          'channel_id': existing.channelId,
          'expected_version': expectedVersion,
          'body': newBody,
          // Inverse state lets the Outbox restore the optimistic UI when the
          // mutation is permanently rejected by the server.
          'previous_body': existing.body,
          'previous_edited_at': existing.editedAt?.toIso8601String(),
          'previous_updated_at': existing.updatedAt?.toIso8601String(),
        }),
        createdAt: now,
        updatedAt: now,
      );

      final updated = await _local.optimisticEditMessage(
        messageId: messageId,
        newBody: newBody,
        operation: operation,
      );
      if (updated == null) {
        return left(const NotFoundFailure('Message not found locally'));
      }

      _outbox.notify();

      return right(
        ChatMessage(
          id: updated.messageId,
          messageSeq: updated.messageSeq,
          channelId: updated.channelId,
          senderId: updated.senderId,
          senderDisplayName: updated.senderDisplayName,
          messageType: updated.messageType,
          body: updated.body,
          replyToId: updated.replyToMessageId,
          version: updated.version,
          createdAt: updated.createdAt ?? updated.localCreatedAt,
          editedAt: updated.editedAt,
          fromMe: updated.senderId == userId,
          syncStatus: updated.syncStatus,
          deliveryStatus: MessageDeliveryStatus.sent,
        ),
      );
    } catch (e) {
      return left(CacheFailure('Failed to edit message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    String channelId,
    String messageId,
  ) async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final existing = await _local.getMessage(messageId);
      if (existing == null) {
        return left(const NotFoundFailure('Message not found locally'));
      }

      if (existing.senderId != userId) {
        return left(const AuthFailure('You can only delete your own message'));
      }

      // No server sequence means the optimistic send has never been accepted.
      // This is a cancellation, not a chat tombstone.
      if (existing.messageSeq == null && existing.syncStatus != 'sending') {
        final localFiles = await _local.cancelPendingOutgoingMessage(
          messageId: messageId,
          currentUserId: userId,
        );

        for (final path in localFiles) {
          try {
            final file = io.File(path);
            if (await file.exists()) await file.delete();
          } catch (_) {
            // A leftover cache file is non-critical; DB/UI cancellation already
            // succeeded and must not be reported as a failed user action.
          }
        }
        return right(unit);
      }

      final now = DateTime.now().toUtc();
      final operation = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
        channelId: channelId,
        entityId: Value(messageId),
        operationType: 'delete_message',
        payloadJson: jsonEncode({
          'message_id': messageId,
          'previous_body': existing.body,
          'previous_deleted_at': existing.deletedAt?.toIso8601String(),
          'previous_updated_at': existing.updatedAt?.toIso8601String(),
        }),
        createdAt: now,
        updatedAt: now,
      );

      final updated = await _local.optimisticDeleteMessage(
        messageId: messageId,
        operation: operation,
      );
      if (updated == null) {
        return left(const NotFoundFailure('Message not found locally'));
      }

      _outbox.notify();
      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to delete message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> retryMessage(String messageId) async {
    try {
      final existing = await _local.getMessage(messageId);
      if (existing == null) {
        return left(const NotFoundFailure('Message not found locally'));
      }
      if (existing.messageSeq != null) return right(unit);

      await _local.retryMessage(messageId);
      _outbox.notify();
      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to retry message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markRead(
    String channelId, [
    int? throughMessageSeq,
  ]) async {
    final userId = _currentUserId;
    if (userId == null) return right(unit);

    try {
      final seq = throughMessageSeq ?? await _local.getLatestMessageSeq(channelId);
      if (seq == null || seq <= 0) return right(unit);
      await _receiptCoordinator.markRead(channelId, userId, seq);
      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to mark read: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markDelivered(
    String channelId,
    int throughMessageSeq,
  ) async {
    final userId = _currentUserId;
    if (userId == null || throughMessageSeq <= 0) return right(unit);

    try {
      await _receiptCoordinator.markDelivered(
        channelId,
        userId,
        throughMessageSeq,
      );
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
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final message = await _local.getMessage(messageId);
      if (message == null) {
        return left(const NotFoundFailure('Message not found locally'));
      }
      if (message.messageSeq == null) {
        return left(
          const ValidationFailure(
            'Wait for this message to send before reacting',
          ),
        );
      }

      final previous = await _local.getReaction(
        messageId: messageId,
        userId: userId,
        reaction: reaction,
      );
      final previouslySelected = previous != null && previous.removedAt == null;
      final now = DateTime.now().toUtc();

      await _local.upsertReaction(
        messageId: messageId,
        userId: userId,
        reaction: reaction,
        createdAt: previous?.createdAt ?? now,
        removedAt: selected ? null : now,
      );

      final operation = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
        channelId: message.channelId,
        entityId: Value(messageId),
        operationType: 'set_reaction',
        coalesceKey: Value('reaction:$messageId:$userId:$reaction'),
        payloadJson: jsonEncode({
          'message_id': messageId,
          'reaction': reaction,
          'selected': selected,
          'user_id': userId,
          'previous_selected': previouslySelected,
        }),
        createdAt: now,
        updatedAt: now,
      );

      await _local.enqueueOperation(operation);
      _outbox.notify();
      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to set reaction: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getOrCreateDmChat(String targetUserId) async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final channelId = await _remote.getOrCreateDirectChannel(targetUserId);
      await _syncCoordinator.syncInbox(userId);
      return right(channelId);
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Failed to open direct message: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createGroupChat({
    required String title,
    required List<String> memberUserIds,
    String? description,
    String? avatarUrl,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final channelId = await _remote.createGroupChannel(
        title: title,
        memberUserIds: memberUserIds,
        description: description,
        avatarUrl: avatarUrl,
      );
      await _syncCoordinator.syncInbox(userId);
      return right(channelId);
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Failed to create group: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptDirectRequest(String channelId) async {
    final result = await _changeRequestStatus(
      channelId: channelId,
      localStatus: 'active',
      operationType: 'accept_invite',
    );

    final userId = _currentUserId;
    if (result.isRight() && userId != null) {
      // The user has explicitly accepted the request. If this thread is
      // already open, enter Presence on its existing presence-capable Ably
      // attachment. Do not rebuild/re-subscribe the message thread.
      unawaited(
        _syncCoordinator.enablePresenceForOpenChannel(channelId),
      );
    }

    return result;
  }

  @override
  Future<Either<Failure, Unit>> declineDirectRequest(String channelId) async {
    return _changeRequestStatus(
      channelId: channelId,
      localStatus: 'declined',
      operationType: 'decline_invite',
    );
  }

  Future<Either<Failure, Unit>> _changeRequestStatus({
    required String channelId,
    required String localStatus,
    required String operationType,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return left(const AuthFailure('User not authenticated'));
    }

    try {
      final now = DateTime.now().toUtc();
      final operation = OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
        channelId: channelId,
        entityId: Value(channelId),
        operationType: operationType,
        payloadJson: jsonEncode({'channel_id': channelId}),
        createdAt: now,
        updatedAt: now,
      );

      await _local.optimisticMemberStatusChange(
        channelId: channelId,
        userId: userId,
        status: localStatus,
        operation: operation,
      );
      _outbox.notify();
      return right(unit);
    } catch (e) {
      return left(CacheFailure('Failed to update chat request: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> loadOlderMessages(String channelId) async {
    final userId = _currentUserId;
    if (userId == null) return right(0);

    try {
      return right(
        await _syncCoordinator.loadOlderMessages(channelId, userId),
      );
    } catch (e) {
      return left(ServerFailure('Failed to load older messages: $e'));
    }
  }

  @override
  Future<ChatDraft?> readDraftState(String channelId) =>
      _local.readDraftState(channelId);

  @override
  Future<void> saveDraftState(String channelId, ChatDraft draft) =>
      _local.saveDraftState(channelId, draft);

  @override
  Future<void> deleteDraft(String channelId) => _local.deleteDraft(channelId);

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) =>
      _ingestor.watchTypingUsers(channelId);

  @override
  Future<void> setTyping(String channelId, bool isTyping) async {
    final userId = _currentUserId;
    if (userId != null) {
      await _ingestor.publishTyping(channelId, userId, isTyping);
    }
  }

  @override
  Stream<Set<String>> watchPresence(String channelId) =>
      _ingestor.watchPresence(channelId);

  @override
  Future<Either<Failure, String>> resolveMediaUrl(String storagePath) async {
    if (storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return right(storagePath);
    }

    try {
      return right(
        await _remote.getMediaSignedUrl(
          storagePath,
          expiresInSeconds: 3600,
        ),
      );
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Could not load chat media: $e'));
    }
  }
}
