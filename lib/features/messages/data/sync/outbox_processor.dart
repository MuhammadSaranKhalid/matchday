import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';

/// FIFO processor for durable offline chat mutations.
class OutboxProcessor {
  OutboxProcessor(
    this._local,
    this._remote, {
    required String? Function() currentUserId,
  }) : _currentUserId = currentUserId;

  final ChatLocalDataSource _local;
  final ChatRemoteDataSource _remote;
  final String? Function() _currentUserId;

  bool _isProcessing = false;
  bool _drainAgainRequested = false;
  Timer? _retryTimer;
  static const int _maxRetries = 5;

  void notify() {
    if (_isProcessing) {
      // The active drain already owns a snapshot. Remember that another pass
      // is required instead of silently dropping this wake-up.
      _drainAgainRequested = true;
      return;
    }
    _scheduleDrain();
  }

  void _scheduleDrain() {
    if (_isProcessing) {
      _drainAgainRequested = true;
      return;
    }
    scheduleMicrotask(drain);
  }

  Future<void> drain() async {
    if (_isProcessing) {
      _drainAgainRequested = true;
      return;
    }

    _isProcessing = true;
    try {
      final ownerUserId = _currentUserId();
      if (ownerUserId == null) return;

      final ready = await _local.getPendingOperations(
        ownerUserId: ownerUserId,
      );
      if (ready.isEmpty) return;

      final lanes = <String, List<OutboxOperationRow>>{};
      for (final operation in ready) {
        lanes.putIfAbsent(operation.channelId, () => []).add(operation);
      }

      const maxConcurrentLanes = 4;
      final entries = lanes.entries.toList();
      var cursor = 0;

      Future<void> worker() async {
        while (cursor < entries.length) {
          final entry = entries[cursor++];
          await _processLane(entry.value);
        }
      }

      await Future.wait(
        List.generate(
          min(maxConcurrentLanes, entries.length),
          (_) => worker(),
        ),
      );
    } catch (e, st) {
      debugPrint('[OutboxProcessor] drain failed: $e\n$st');
    } finally {
      _isProcessing = false;

      if (_drainAgainRequested) {
        _drainAgainRequested = false;
        scheduleMicrotask(drain);
      } else {
        await _scheduleNextRetry();
      }
    }
  }

  Future<void> _processLane(List<OutboxOperationRow> snapshots) async {
    for (final snapshot in snapshots) {
      // A user can cancel an unsent message after getPendingOperations() took
      // its snapshot. Re-read before executing so cancelled work stays gone.
      final operation = await _local.getOutboxOperation(snapshot.operationId);
      if (operation == null) continue;

      // Never execute another account's durable command. Re-check the active
      // auth identity for every operation because the user can switch accounts
      // after the drain snapshot was taken.
      final activeUserId = _currentUserId();
      if (activeUserId == null || operation.ownerUserId != activeUserId) {
        break;
      }

      await _local.updateOutboxOperation(
        operation.operationId,
        status: 'processing',
      );

      if (operation.operationType == 'send_message' &&
          operation.entityId != null) {
        await _local.updateMessageSyncStatus(
          operation.entityId!,
          syncStatus: 'sending',
        );
      }

      try {
        await _executeOperation(operation);
        await _local.deleteOutboxOperation(operation.operationId);
      } catch (e) {
        final offline = _isNetworkOrOfflineError(e);
        final terminal = _isTerminalError(e);
        final nextAttempt = operation.attemptCount + 1;

        if (!offline && (terminal || nextAttempt >= _maxRetries)) {
          await _local.updateOutboxOperation(
            operation.operationId,
            status: 'failed',
            attemptCount: nextAttempt,
            lastErrorCode: _extractErrorCode(e),
            lastErrorMessage: e.toString(),
          );

          if (operation.operationType == 'edit_message' ||
              operation.operationType == 'delete_message' ||
              operation.operationType == 'set_reaction') {
            await _rollbackOptimisticMutation(operation);
            // These mutations can be issued again as fresh commands. Once the
            // optimistic UI has been rolled back, retaining a permanently
            // failed row only pollutes the queue. Failed SEND rows are kept
            // because the user can explicitly Retry them.
            await _local.deleteOutboxOperation(operation.operationId);
          }

          if (operation.operationType == 'send_message' &&
              operation.entityId != null) {
            await _local.updateMessageSyncStatus(
              operation.entityId!,
              syncStatus: 'failed',
              sendErrorCode: _extractErrorCode(e),
              sendErrorMessage: e.toString(),
            );

            // The message stays visible for Retry/Remove, but a remotely
            // uploaded object from a permanently failed send is an orphan.
            try {
              final attachments = await _local.getAttachmentsForMessage(
                operation.entityId!,
              );
              for (final attachment in attachments) {
                final path = attachment.storagePath;
                if (path != null && path.isNotEmpty) {
                  await _remote.deleteStorageAttachment(path);
                }
              }
            } catch (cleanupError) {
              debugPrint(
                '[OutboxProcessor] storage cleanup failed: $cleanupError',
              );
            }
          }
        } else if (offline) {
          await _resetSendToPending(operation, e, code: 'NETWORK_OFFLINE');
          await _local.updateOutboxOperation(
            operation.operationId,
            status: 'retry_wait',
            attemptCount: operation.attemptCount,
            nextAttemptAt:
                DateTime.now().toUtc().add(const Duration(seconds: 15)),
            lastErrorCode: 'NETWORK_OFFLINE',
            lastErrorMessage: e.toString(),
          );
        } else {
          final slowModeSeconds = _extractSlowModeWaitSeconds(e);
          final backoffSeconds = slowModeSeconds != null && slowModeSeconds > 0
              ? slowModeSeconds + 1
              : max(
                  1,
                  (pow(2, nextAttempt) *
                          (0.8 + Random().nextDouble() * 0.4))
                      .round(),
                );

          await _resetSendToPending(
            operation,
            e,
            code: _extractErrorCode(e),
          );
          await _local.updateOutboxOperation(
            operation.operationId,
            status: 'retry_wait',
            attemptCount: nextAttempt,
            nextAttemptAt: DateTime.now()
                .toUtc()
                .add(Duration(seconds: backoffSeconds)),
            lastErrorCode: _extractErrorCode(e),
            lastErrorMessage: e.toString(),
          );
        }

        // Preserve strict FIFO within this channel. Later operations may
        // depend on the failed operation having completed first.
        break;
      }
    }
  }

  Future<void> _resetSendToPending(
    OutboxOperationRow operation,
    Object error, {
    String? code,
  }) async {
    if (operation.operationType != 'send_message' ||
        operation.entityId == null) {
      return;
    }

    await _local.updateMessageSyncStatus(
      operation.entityId!,
      syncStatus: 'pending',
      sendErrorCode: code,
      sendErrorMessage: error.toString(),
    );
  }

  Future<void> _executeOperation(OutboxOperationRow operation) async {
    final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;

    switch (operation.operationType) {
      case 'send_message':
        final messageId =
            operation.entityId ?? payload['message_id'] as String;
        final channelId = operation.channelId;
        final type = payload['message_type'] as String? ?? 'text';
        final body = payload['body'] as String?;
        final replyTo = payload['reply_to_message_id'] as String?;
        var messagePayload = payload['payload'] is Map
            ? Map<String, dynamic>.from(payload['payload'] as Map)
            : <String, dynamic>{};

        if (type == 'image') {
          final localPath = payload['local_path'] as String?;
          final attachmentId = payload['attachment_id'] as String?;
          final extension = payload['extension'] as String? ?? 'jpg';
          final mimeType = payload['mime_type'] as String? ?? 'image/jpeg';
          final fileName = payload['file_name'] as String?;
          final width = (payload['width'] as num?)?.toInt();
          final height = (payload['height'] as num?)?.toInt();

          String? storagePath = messagePayload['media_url'] as String?;
          int? sizeBytes;

          if (storagePath == null && localPath != null && attachmentId != null) {
            final file = io.File(localPath);
            if (!await file.exists()) {
              throw StateError('Pending chat attachment file is missing');
            }

            final bytes = await file.readAsBytes();
            sizeBytes = bytes.length;
            storagePath = await _remote.uploadMediaAttachment(
              bytes: bytes,
              channelId: channelId,
              messageId: messageId,
              attachmentId: attachmentId,
              extension: extension,
              mimeType: mimeType,
            );
            await _local.updateAttachmentStoragePath(
              attachmentId,
              storagePath: storagePath,
              uploadStatus: 'uploaded',
            );
          }

          if (storagePath != null) {
            messagePayload = {
              ...messagePayload,
              'media_url': storagePath,
              'attachment': {
                if (attachmentId != null) 'attachment_id': attachmentId,
                'storage_path': storagePath,
                'mime_type': mimeType,
                if (fileName != null) 'file_name': fileName,
                if (sizeBytes != null) 'size_bytes': sizeBytes,
                if (width != null) 'width': width,
                if (height != null) 'height': height,
              },
            };
          }
        }

        final confirmed = await _remote.sendChannelMessage(
          messageId: messageId,
          channelId: channelId,
          messageType: type,
          body: body,
          replyToMessageId: replyTo,
          payload: messagePayload,
        );

        if (type == 'image') {
          final localPath = payload['local_path'] as String?;
          final attachmentId = payload['attachment_id'] as String?;
          if (localPath != null && localPath.contains('chat_outbox')) {
            try {
              final file = io.File(localPath);
              if (await file.exists()) await file.delete();
              if (attachmentId != null) {
                await _local.clearAttachmentLocalPath(attachmentId);
              }
            } catch (e) {
              debugPrint('[OutboxProcessor] local file cleanup failed: $e');
            }
          }
        }

        await _local.updateMessageSyncStatus(
          messageId,
          syncStatus: 'sent',
          messageSeq: confirmed.messageSeq,
          version: confirmed.version,
        );

        if (confirmed.messageSeq != null && confirmed.senderId != null) {
          await _local.updateMemberHorizons(
            channelId,
            confirmed.senderId!,
            readSeq: confirmed.messageSeq,
            deliveredSeq: confirmed.messageSeq,
          );
        }
        break;

      case 'edit_message':
        final messageId =
            operation.entityId ?? payload['message_id'] as String;
        final updated = await _remote.editChannelMessage(
          messageId: messageId,
          expectedVersion: payload['expected_version'] as int? ?? 1,
          newBody: payload['body'] as String,
          payload: payload['payload'] is Map
              ? Map<String, dynamic>.from(payload['payload'] as Map)
              : null,
        );
        await _local.updateMessageSyncStatus(
          messageId,
          syncStatus: 'sent',
          version: updated.version,
        );
        break;

      case 'delete_message':
        final messageId =
            operation.entityId ?? payload['message_id'] as String;
        await _remote.deleteChannelMessage(messageId);
        await _local.softDeleteMessageLocally(messageId);
        break;

      case 'mark_read':
        await _remote.markChannelRead(
          channelId: operation.channelId,
          throughSeq: (payload['through_seq'] as num).toInt(),
        );
        break;

      case 'mark_delivered':
        await _remote.markChannelDelivered(
          channelId: operation.channelId,
          throughSeq: (payload['through_seq'] as num).toInt(),
        );
        break;

      case 'set_reaction':
        await _remote.setMessageReaction(
          messageId: operation.entityId ?? payload['message_id'] as String,
          reaction: payload['reaction'] as String,
          selected: payload['selected'] as bool,
        );
        break;

      case 'accept_invite':
        await _remote.acceptChannelInvite(operation.channelId);
        break;

      case 'decline_invite':
        await _remote.declineChannelInvite(operation.channelId);
        break;

      default:
        // Returning normally would make the caller delete unknown work as if
        // it had succeeded. Unknown durable commands must fail loudly.
        throw StateError(
          'Unknown chat outbox operation: ${operation.operationType}',
        );
    }
  }

  Future<void> _rollbackOptimisticMutation(
    OutboxOperationRow operation,
  ) async {
    final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;

    DateTime? parseDate(Object? raw) {
      if (raw is! String || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    switch (operation.operationType) {
      case 'edit_message':
        final messageId = operation.entityId ?? payload['message_id'] as String?;
        if (messageId == null) return;
        await _local.rollbackOptimisticEdit(
          messageId: messageId,
          previousBody: payload['previous_body'] as String?,
          previousEditedAt: parseDate(payload['previous_edited_at']),
          previousUpdatedAt: parseDate(payload['previous_updated_at']),
        );
        break;

      case 'delete_message':
        final messageId = operation.entityId ?? payload['message_id'] as String?;
        if (messageId == null) return;
        await _local.rollbackOptimisticDelete(
          messageId: messageId,
          previousBody: payload['previous_body'] as String?,
          previousDeletedAt: parseDate(payload['previous_deleted_at']),
          previousUpdatedAt: parseDate(payload['previous_updated_at']),
        );
        break;

      case 'set_reaction':
        final messageId = operation.entityId ?? payload['message_id'] as String?;
        final userId = payload['user_id'] as String?;
        final reaction = payload['reaction'] as String?;
        if (messageId == null || userId == null || reaction == null) return;

        await _local.upsertReaction(
          messageId: messageId,
          userId: userId,
          reaction: reaction,
          createdAt: DateTime.now().toUtc(),
          removedAt: payload['previous_selected'] == true
              ? null
              : DateTime.now().toUtc(),
        );
        break;
    }
  }

  bool _isNetworkOrOfflineError(Object e) {
    if (e is io.SocketException || e is io.HttpException || e is TimeoutException) {
      return true;
    }

    final text = e.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('network error') ||
        text.contains('connection refused') ||
        text.contains('connection timed out') ||
        text.contains('connection reset') ||
        text.contains('connection closed') ||
        text.contains('clientexception') ||
        text.contains('handshakeexception') ||
        text.contains('tls exception') ||
        text.contains('software caused connection abort');
  }

  bool _isTerminalError(Object e) {
    if (e is StateError) return true;
    if (e is PostgrestException) {
      if (e.message.contains('CHAT_SLOW_MODE')) return false;
      if (e.code == '42501' || e.code == '23514' || e.code == '22023') {
        return true;
      }
      if (e.code == 'P0001') {
        return e.message.contains('CHAT_NOT_MEMBER') ||
            e.message.contains('CHAT_PERMISSION_DENIED') ||
            e.message.contains('CHAT_FROZEN') ||
            e.message.contains('CHAT_INVITE_NOT_PENDING') ||
            e.message.contains('CHAT_MESSAGE_NOT_FOUND') ||
            e.message.contains('CHAT_CONCURRENT_MODIFICATION');
      }
    }
    return false;
  }

  int? _extractSlowModeWaitSeconds(Object e) {
    if (e is! PostgrestException) return null;

    if (e.details is Map) {
      final value = (e.details as Map)['retry_after_seconds'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
    }

    if (e.details is String) {
      try {
        final decoded = jsonDecode(e.details as String);
        if (decoded is Map) {
          final value = decoded['retry_after_seconds'];
          if (value is int) return value;
          if (value is String) return int.tryParse(value);
        }
      } catch (_) {}
    }

    final match = RegExp(r'(\d+)\s*seconds').firstMatch(e.message);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String? _extractErrorCode(Object e) {
    if (e is PostgrestException) {
      if (e.message.startsWith('CHAT_')) return e.message.split(' ').first;
      return e.code;
    }
    if (e is StateError) return 'LOCAL_OUTBOX_ERROR';
    return null;
  }

  Future<void> _scheduleNextRetry() async {
    _retryTimer?.cancel();
    _retryTimer = null;

    final ownerUserId = _currentUserId();
    if (ownerUserId == null) return;

    final retryAt = await _local.getNextOutboxRetryAt(ownerUserId);
    if (retryAt == null) return;

    final rawDelay = retryAt.difference(DateTime.now().toUtc());
    _retryTimer = Timer(
      rawDelay.isNegative ? Duration.zero : rawDelay,
      _scheduleDrain,
    );
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
