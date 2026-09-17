import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';

/// FIFO queue processor draining offline outbox operations reliably per Spec §7.2.
class OutboxProcessor {
  OutboxProcessor(this._local, this._remote);

  final ChatLocalDataSource _local;
  final ChatRemoteDataSource _remote;

  bool _isProcessing = false;
  Timer? _retryTimer;
  static const int _maxRetries = 5;

  /// Signals the processor that new outbox operations are available.
  void notify() {
    _scheduleDrain();
  }

  void _scheduleDrain() {
    if (_isProcessing) return;
    scheduleMicrotask(drain);
  }

  /// Drains pending operations across all channel lanes.
  Future<void> drain() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pendingOps = await _local.getPendingOperations();
      if (pendingOps.isEmpty) return;

      // Group operations by channelId for strict FIFO per-channel execution
      final channelLanes = <String, List<OutboxOperationRow>>{};
      for (final op in pendingOps) {
        channelLanes.putIfAbsent(op.channelId, () => []).add(op);
      }

      // Execute channels in parallel, but operations within each channel sequentially
      await Future.wait(
        channelLanes.entries.map((entry) => _processChannelLane(entry.key, entry.value)),
      );
    } catch (e, st) {
      debugPrint('[OutboxProcessor] Error draining outbox: $e\n$st');
    } finally {
      _isProcessing = false;
      _scheduleNextRetry();
    }
  }

  Future<void> _processChannelLane(
    String channelId,
    List<OutboxOperationRow> operations,
  ) async {
    for (final op in operations) {
      await _local.updateOutboxOperation(op.operationId, status: 'processing');

      try {
        await _executeOperation(op);
        // Successful execution: delete operation
        await _local.deleteOutboxOperation(op.operationId);
      } catch (e) {
        final isTerminal = _isTerminalError(e);
        final nextAttempt = op.attemptCount + 1;

        if (isTerminal || nextAttempt >= _maxRetries) {
          debugPrint('[OutboxProcessor] Terminal error for op ${op.operationId}: $e');
          await _local.updateOutboxOperation(
            op.operationId,
            status: 'failed',
            attemptCount: nextAttempt,
            lastErrorCode: _extractErrorCode(e),
            lastErrorMessage: e.toString(),
          );

          if (op.operationType == 'send_message' && op.entityId != null) {
            await _local.updateMessageSyncStatus(
              op.entityId!,
              syncStatus: 'failed',
              sendErrorCode: _extractErrorCode(e),
              sendErrorMessage: e.toString(),
            );
          }
        } else {
          // Retryable error: apply exponential backoff
          final backoffSeconds = pow(2, nextAttempt).toInt();
          final nextAttemptAt = DateTime.now().toUtc().add(Duration(seconds: backoffSeconds));

          debugPrint(
            '[OutboxProcessor] Op ${op.operationId} failed, retrying in $backoffSeconds s. Error: $e',
          );

          await _local.updateOutboxOperation(
            op.operationId,
            status: 'retry_wait',
            attemptCount: nextAttempt,
            nextAttemptAt: nextAttemptAt,
            lastErrorCode: _extractErrorCode(e),
            lastErrorMessage: e.toString(),
          );
        }

        // Break channel lane on error to preserve FIFO ordering
        break;
      }
    }
  }

  Future<void> _executeOperation(OutboxOperationRow op) async {
    final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;

    switch (op.operationType) {
      case 'send_message':
        final messageId = op.entityId ?? payload['message_id'] as String;
        final channelId = op.channelId;
        final messageType = payload['message_type'] as String? ?? 'text';
        final body = payload['body'] as String?;
        final replyToId = payload['reply_to_message_id'] as String?;
        var msgPayload = payload['payload'] as Map<String, dynamic>?;

        // Offline Attachment handling (Spec §8.4)
        if (messageType == 'image') {
          final localPath = payload['local_path'] as String?;
          final attachmentId = payload['attachment_id'] as String?;
          final extension = payload['extension'] as String? ?? 'jpg';
          final mimeType = payload['mime_type'] as String? ?? 'image/jpeg';

          if (localPath != null &&
              attachmentId != null &&
              (msgPayload == null || msgPayload['media_url'] == null)) {
            final file = io.File(localPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final storageUrl = await _remote.uploadMediaAttachment(
                bytes: bytes,
                channelId: channelId,
                messageId: messageId,
                attachmentId: attachmentId,
                extension: extension,
                mimeType: mimeType,
              );
              await _local.updateAttachmentStoragePath(
                attachmentId,
                storagePath: storageUrl,
                uploadStatus: 'uploaded',
              );
              msgPayload = {
                ...?msgPayload,
                'media_url': storageUrl,
              };
            }
          }
        }

        final confirmedDto = await _remote.sendChannelMessage(
          messageId: messageId,
          channelId: channelId,
          messageType: messageType,
          body: body,
          replyToMessageId: replyToId,
          payload: msgPayload,
        );

        // Clean up outbox file after confirmed upload and send (Spec §25)
        if (messageType == 'image') {
          final localPath = payload['local_path'] as String?;
          if (localPath != null && localPath.contains('chat_outbox')) {
            try {
              final file = io.File(localPath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              debugPrint('[OutboxProcessor] Non-critical error cleaning outbox file: $e');
            }
          }
        }

        // Update local message with confirmed server sequence
        await _local.updateMessageSyncStatus(
          messageId,
          syncStatus: 'sent',
          messageSeq: confirmedDto.messageSeq,
          version: confirmedDto.version,
        );

        // Advance sender's own read and delivered horizons locally
        if (confirmedDto.messageSeq != null && confirmedDto.senderId != null) {
          await _local.updateMemberHorizons(
            channelId,
            confirmedDto.senderId!,
            readSeq: confirmedDto.messageSeq,
            deliveredSeq: confirmedDto.messageSeq,
          );
        }
        break;

      case 'edit_message':
        final messageId = op.entityId ?? payload['message_id'] as String;
        final expectedVersion = payload['expected_version'] as int? ?? 1;
        final newBody = payload['body'] as String;
        final msgPayload = payload['payload'] as Map<String, dynamic>?;

        final updatedDto = await _remote.editChannelMessage(
          messageId: messageId,
          expectedVersion: expectedVersion,
          newBody: newBody,
          payload: msgPayload,
        );

        await _local.updateMessageSyncStatus(
          messageId,
          syncStatus: 'sent',
          version: updatedDto.version,
        );
        break;

      case 'delete_message':
        final messageId = op.entityId ?? payload['message_id'] as String;
        await _remote.deleteChannelMessage(messageId);
        await _local.softDeleteMessageLocally(messageId);
        break;

      case 'mark_read':
        final throughSeq = payload['through_seq'] as int;
        await _remote.markChannelRead(
          channelId: op.channelId,
          throughSeq: throughSeq,
        );
        break;

      case 'mark_delivered':
        final throughSeq = payload['through_seq'] as int;
        await _remote.markChannelDelivered(
          channelId: op.channelId,
          throughSeq: throughSeq,
        );
        break;

      case 'set_reaction':
        final messageId = op.entityId ?? payload['message_id'] as String;
        final reaction = payload['reaction'] as String;
        final selected = payload['selected'] as bool;
        await _remote.setMessageReaction(
          messageId: messageId,
          reaction: reaction,
          selected: selected,
        );
        break;

      case 'accept_invite':
        await _remote.acceptChannelInvite(op.channelId);
        break;

      case 'decline_invite':
        await _remote.declineChannelInvite(op.channelId);
        break;

      default:
        debugPrint('[OutboxProcessor] Unknown operation type: ${op.operationType}');
    }
  }

  bool _isTerminalError(dynamic e) {
    if (e is PostgrestException) {
      final msg = e.message;
      // Slow mode cooldown is transient; retry after delay
      if (msg.contains('CHAT_SLOW_MODE')) {
        return false;
      }
      // 42501: permission denied, 23514: check violation (e.g. participant limit), 22023: invalid param
      if (e.code == '42501' || e.code == '23514' || e.code == '22023') {
        return true;
      }
      // Explicit application domain errors that cannot succeed on retry
      if (e.code == 'P0001') {
        if (msg.contains('CHAT_NOT_MEMBER') ||
            msg.contains('CHAT_PERMISSION_DENIED') ||
            msg.contains('CHAT_FROZEN') ||
            msg.contains('CHAT_INVITE_NOT_PENDING') ||
            msg.contains('CHAT_MESSAGE_NOT_FOUND') ||
            msg.contains('CHAT_CONCURRENT_MODIFICATION')) {
          return true;
        }
      }
    }
    return false;
  }

  String? _extractErrorCode(dynamic e) {
    if (e is PostgrestException) {
      if (e.message.isNotEmpty && e.message.startsWith('CHAT_')) {
        return e.message.split(' ').first;
      }
      return e.code;
    }
    return null;
  }

  void _scheduleNextRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 15), () {
      _scheduleDrain();
    });
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
