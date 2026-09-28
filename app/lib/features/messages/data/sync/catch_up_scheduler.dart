import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_message_dto.dart';

/// Bounded, prioritized background scheduler that hydrates recent/missing messages
/// for conversations without requiring the user to open them (Spec §4, §5, §6, §12).
class CatchUpScheduler {
  CatchUpScheduler({
    required this.local,
    required this.remote,
    required this.db,
    this.maxConcurrent = 3,
    this.initialWindowSize = 50,
    this.deltaPageSize = 100,
  });

  final ChatLocalDataSource local;
  final ChatRemoteDataSource remote;
  final AppDatabase db;
  final int maxConcurrent;
  final int initialWindowSize;
  final int deltaPageSize;

  /// Optional callback notified when messages are persisted during catch-up,
  /// allowing receipt coordination (Spec §13).
  void Function(String channelId, int throughSeq)? onMessagesDelivered;

  final Set<String> _inFlightChannels = {};
  final Set<String> _queuedHighPriority = {};
  final Set<String> _queuedNormalPriority = {};
  bool _isProcessingQueue = false;
  String? _activeUserId;
  int _sessionGeneration = 0;
  Completer<void>? _activeRunCompleter;

  /// Updates the active user session or cancels work on logout.
  void setSessionUser(String? userId) {
    if (_activeUserId != userId) {
      _sessionGeneration++;
      _activeUserId = userId;
      _queuedHighPriority.clear();
      _queuedNormalPriority.clear();
      if (_activeRunCompleter != null && !_activeRunCompleter!.isCompleted) {
        _activeRunCompleter!.complete();
      }
    }
  }

  /// Enqueues a specific channel for targeted catch-up.
  void enqueue(String channelId, {bool highPriority = false}) {
    if (highPriority) {
      _queuedHighPriority.add(channelId);
    } else {
      _queuedNormalPriority.add(channelId);
    }
    _processQueue();
  }

  /// Runs catch-up across all active conversations for [userId] (Spec §4).
  Future<void> run(String userId) async {
    setSessionUser(userId);

    try {
      // Query all non-archived channels where user is a member
      final query = db.select(db.localChannels).join([
        innerJoin(
          db.localChannelMembers,
          db.localChannelMembers.channelId.equalsExp(db.localChannels.channelId) &
              db.localChannelMembers.userId.equals(userId),
        ),
      ]);

      final rows = await query.get();
      if (rows.isEmpty) return;

      // Extract and sort by priority:
      // 1. Unread count > 0
      // 2. Pinned
      // 3. Recently active (lastMessageAt DESC)
      // 4. Remaining active channels
      final channelItems = rows.map((r) {
        final ch = r.readTable(db.localChannels);
        final member = r.readTable(db.localChannelMembers);
        return (channel: ch, member: member);
      }).where((item) => item.member.archivedAt == null).toList();

      if (channelItems.isEmpty) return;

      channelItems.sort((a, b) {
        final aUnread = a.channel.unreadCount > 0 ? 1 : 0;
        final bUnread = b.channel.unreadCount > 0 ? 1 : 0;
        if (aUnread != bUnread) return bUnread.compareTo(aUnread);

        final aPinned = a.member.pinnedAt != null ? 1 : 0;
        final bPinned = b.member.pinnedAt != null ? 1 : 0;
        if (aPinned != bPinned) return bPinned.compareTo(aPinned);

        final aTime = a.channel.lastMessageAt ?? a.channel.serverUpdatedAt;
        final bTime = b.channel.lastMessageAt ?? b.channel.serverUpdatedAt;
        return bTime.compareTo(aTime);
      });

      _activeRunCompleter = Completer<void>();

      for (final item in channelItems) {
        if (!_queuedHighPriority.contains(item.channel.channelId)) {
          _queuedNormalPriority.add(item.channel.channelId);
        }
      }

      _processQueue();

      await _activeRunCompleter?.future;
    } catch (e, st) {
      debugPrint('[CatchUpScheduler] Error collecting channels: $e\n$st');
    }
  }

  void _processQueue() {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    scheduleMicrotask(() async {
      try {
        final currentGen = _sessionGeneration;
        final userId = _activeUserId;
        if (userId == null) return;

        while ((_queuedHighPriority.isNotEmpty || _queuedNormalPriority.isNotEmpty) &&
            _inFlightChannels.length < maxConcurrent) {
          if (_sessionGeneration != currentGen) break;

          String? nextChannelId;
          if (_queuedHighPriority.isNotEmpty) {
            nextChannelId = _queuedHighPriority.first;
            _queuedHighPriority.remove(nextChannelId);
          } else if (_queuedNormalPriority.isNotEmpty) {
            nextChannelId = _queuedNormalPriority.first;
            _queuedNormalPriority.remove(nextChannelId);
          }

          if (nextChannelId == null) break;
          if (_inFlightChannels.contains(nextChannelId)) continue;

          _inFlightChannels.add(nextChannelId);
          unawaited(_syncChannelSafe(nextChannelId, userId, currentGen));
        }
      } finally {
        _isProcessingQueue = false;
      }
    });
  }

  Future<void> _syncChannelSafe(
    String channelId,
    String userId,
    int generation,
  ) async {
    try {
      await syncChannel(channelId, userId, generation: generation);
    } catch (e, st) {
      debugPrint('[CatchUpScheduler] Error syncing channel $channelId: $e\n$st');
    } finally {
      _inFlightChannels.remove(channelId);
      if (_queuedHighPriority.isNotEmpty || _queuedNormalPriority.isNotEmpty) {
        _processQueue();
      } else if (_inFlightChannels.isEmpty) {
        if (_activeRunCompleter != null && !_activeRunCompleter!.isCompleted) {
          _activeRunCompleter!.complete();
        }
      }
    }
  }

  /// Universal forward synchronization primitive shared by CatchUpScheduler and
  /// Thread openChannel (Spec §12).
  Future<void> syncChannel(
    String channelId,
    String currentUserId, {
    int? generation,
  }) async {
    final activeGen = generation ?? _sessionGeneration;
    await local.markChannelSyncStarted(channelId);

    try {
      final syncState = await local.getChannelSyncState(channelId);

      if (syncState == null || syncState.newestSyncedMessageSeq == null) {
        // Spec §5: Never-synced channel: fetch bounded recent window only
        final recentMessages = await remote.fetchRecentMessages(
          channelId,
          limit: initialWindowSize,
        );

        if (_sessionGeneration != activeGen) return; // Session expired

        if (recentMessages.isEmpty) {
          await local.markChannelSyncSucceeded(
            channelId,
            newestSeq: 0,
            hasMore: false,
          );
          return;
        }

        final seqs = recentMessages
            .map((m) => m.messageSeq)
            .whereType<int>()
            .toList();
        final newestSeq = seqs.isEmpty ? 0 : seqs.reduce(max);
        final oldestSeq = seqs.isEmpty ? 0 : seqs.reduce(min);
        final hasMore = recentMessages.length == initialWindowSize;

        await local.commitMessagesAndAdvanceCursor(
          channelId: channelId,
          messages: recentMessages,
          currentUserId: currentUserId,
          newestSeq: newestSeq,
          oldestSeq: oldestSeq,
          hasMore: hasMore,
        );

        if (newestSeq > 0) {
          onMessagesDelivered?.call(channelId, newestSeq);
        }
      } else {
        // Spec §6: Paginated forward delta catch-up
        var cursor = syncState.newestSyncedMessageSeq!;
        final ch = await (db.select(db.localChannels)
              ..where((c) => c.channelId.equals(channelId)))
            .getSingleOrNull();
        final targetSeq = ch?.lastMessageSeq ?? cursor;

        while (true) {
          if (_sessionGeneration != activeGen) return;

          final page = await remote.fetchDeltaMessages(
            channelId,
            cursor,
            limit: deltaPageSize,
          );

          if (_sessionGeneration != activeGen) return;
          if (page.isEmpty) break;

          final seqs = page.map((m) => m.messageSeq).whereType<int>().toList();
          final pageNewest = seqs.isEmpty ? cursor : seqs.reduce(max);
          cursor = max(cursor, pageNewest);

          await local.commitMessagesAndAdvanceCursor(
            channelId: channelId,
            messages: page,
            currentUserId: currentUserId,
            newestSeq: cursor,
          );

          onMessagesDelivered?.call(channelId, cursor);

          if (page.length < deltaPageSize || cursor >= targetSeq) {
            break;
          }
        }
      }

      // Catch up durable mutations from chat_changes ledger (Spec §12, Items 17 & 19)
      final afterChangeSeq = syncState?.newestAppliedChangeSeq ?? 0;
      var currentChangeCursor = afterChangeSeq;

      while (true) {
        if (_sessionGeneration != activeGen) return;

        final changes = await remote.fetchChannelChanges(
          channelId,
          afterChangeSeq: currentChangeCursor,
          limit: deltaPageSize,
        );

        if (_sessionGeneration != activeGen) return;
        if (changes.isEmpty) break;

        for (final change in changes) {
          final entityType = change['entity_type'] as String?;
          final operation = change['operation'] as String?;
          final payload = change['payload'] is Map
              ? (change['payload'] as Map<String, dynamic>)
              : <String, dynamic>{};
          final changeSeq =
              (change['change_seq'] as num?)?.toInt() ?? currentChangeCursor;
          if (changeSeq > currentChangeCursor) {
            currentChangeCursor = changeSeq;
          }

          if (entityType == 'message') {
            if (operation == 'delete') {
              final messageId = payload['message_id'] as String? ??
                  change['entity_id'] as String?;
              final version = (payload['version'] as num?)?.toInt();
              if (messageId != null) {
                final existing = await local.getMessage(messageId);
                if (existing != null &&
                    version != null &&
                    existing.version > version) {
                  // Stale delete
                  continue;
                }
                await local.softDeleteMessageLocally(messageId, version: version);
              }
            } else if (operation == 'update' || operation == 'insert') {
              try {
                final dto = ChatMessageDto.fromJson(payload);
                final existing = await local.getMessage(dto.messageId);
                if (existing != null && existing.version >= dto.version) {
                  // Stale update
                  continue;
                }
                await local.upsertMessagesFromDto([dto], currentUserId);
              } catch (_) {}
            }
          } else if (entityType == 'reaction') {
            final messageId = payload['message_id'] as String? ??
                change['entity_id'] as String?;
            final userId = payload['user_id'] as String?;
            final reaction = payload['reaction'] as String?;
            final selected =
                payload['selected'] as bool? ?? (operation == 'insert');
            final occurredAtStr = change['occurred_at'] as String?;
            final occurredAt = occurredAtStr != null
                ? DateTime.tryParse(occurredAtStr) ?? DateTime.now().toUtc()
                : DateTime.now().toUtc();

            if (messageId != null && userId != null && reaction != null) {
              await local.upsertReaction(
                messageId: messageId,
                userId: userId,
                reaction: reaction,
                createdAt: occurredAt,
                removedAt: selected ? null : occurredAt,
              );
            }
          } else if (entityType == 'receipt') {
            final type = payload['type'] as String?;
            final userId = payload['user_id'] as String? ??
                change['entity_id'] as String?;
            final throughSeq =
                (payload['through_message_seq'] ?? payload['through_seq'])
                    as int?;
            if (userId != null && throughSeq != null) {
              if (type == 'read') {
                await local.updateMemberHorizons(channelId, userId,
                    readSeq: throughSeq);
              } else if (type == 'delivered') {
                await local.updateMemberHorizons(channelId, userId,
                    deliveredSeq: throughSeq);
              }
            }
          }
        }

        if (currentChangeCursor > afterChangeSeq) {
          await local.updateNewestAppliedChangeSeq(channelId, currentChangeCursor);
        }

        if (changes.length < deltaPageSize) break;
      }
    } catch (e) {
      await local.markChannelSyncFailed(channelId, e);
      rethrow;
    }
  }

  /// Loads older history before oldest cached seq without altering newest cursor (Spec §22).
  Future<int> loadOlderMessages(String channelId, String currentUserId) async {
    final syncState = await local.getChannelSyncState(channelId);
    var oldestSeq = syncState?.oldestCachedMessageSeq;

    if (oldestSeq == null) {
      // Discover from local_messages if syncState does not have it yet
      final oldestLocalMsg = await (db.select(db.localMessages)
            ..where((m) =>
                m.channelId.equals(channelId) & m.messageSeq.isNotNull())
            ..orderBy([(m) => OrderingTerm.asc(m.messageSeq)])
            ..limit(1))
          .getSingleOrNull();
      oldestSeq = oldestLocalMsg?.messageSeq;
    }

    if (oldestSeq == null || oldestSeq <= 1) {
      return 0;
    }

    final olderDtos = await remote.fetchOlderMessages(
      channelId,
      oldestSeq,
      limit: 50,
    );

    if (olderDtos.isEmpty) {
      await (db.update(db.channelSyncStates)
            ..where((s) => s.channelId.equals(channelId)))
          .write(const ChannelSyncStatesCompanion(hasMoreHistory: Value(false)));
      return 0;
    }

    final fetchedOldest = olderDtos
        .map((m) => m.messageSeq)
        .whereType<int>()
        .reduce(min);
    final hasMore = olderDtos.length == 50;

    await local.commitOlderMessagesAndUpdateCursor(
      channelId: channelId,
      messages: olderDtos,
      currentUserId: currentUserId,
      oldestSeq: fetchedOldest,
      hasMore: hasMore,
    );

    return olderDtos.length;
  }
}
