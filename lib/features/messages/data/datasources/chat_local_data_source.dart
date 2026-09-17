import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/entities/message_reaction.dart';
import '../models/chat_channel_dto.dart';
import '../models/chat_message_dto.dart';

/// Local-first Drift data source implementing Spec §7 & §8.
/// All UI streams read directly from here (single read path).
class ChatLocalDataSource {
  ChatLocalDataSource(this._db);

  final AppDatabase _db;

  // ═══════════════════════════════════════════════════════════════════════════
  // Reactive Streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watches all active channels for [currentUserId] to display the inbox.
  Stream<List<ChatChannel>> watchInbox(String currentUserId) {
    // Watch localChannels joined with current user's localChannelMembers
    final channelQuery = _db.select(_db.localChannels).join([
      leftOuterJoin(
        _db.localChannelMembers,
        _db.localChannelMembers.channelId.equalsExp(_db.localChannels.channelId) &
            _db.localChannelMembers.userId.equals(currentUserId),
      ),
    ]);

    return channelQuery.watch().asyncMap((rows) async {
      if (rows.isEmpty) return const <ChatChannel>[];

      // Batch query other members for direct message channels to avoid N+1 queries
      final directChannelIds = rows
          .map((r) => r.readTable(_db.localChannels))
          .where((c) => c.kind == 'direct')
          .map((c) => c.channelId)
          .toList();

      final otherMembers = directChannelIds.isEmpty
          ? <LocalChannelMemberRow>[]
          : await (_db.select(_db.localChannelMembers)
                ..where((m) =>
                    m.channelId.isIn(directChannelIds) &
                    m.userId.isNotValue(currentUserId)))
              .get();
      final otherMemberMap = {for (final m in otherMembers) m.channelId: m};

      final channels = <ChatChannel>[];
      final now = DateTime.now().toUtc();

      for (final row in rows) {
        final ch = row.readTable(_db.localChannels);
        final member = row.readTableOrNull(_db.localChannelMembers);
        final otherMember = otherMemberMap[ch.channelId];

        channels.add(ChatChannel(
          id: ch.channelId,
          channelKey: ch.channelKey,
          kind: ChatChannelKind.fromWire(ch.kind),
          contextType: ChatChannelContext.fromWire(ch.contextType),
          name: ch.title ?? '',
          description: ch.description,
          avatarUrl: ch.avatarUrl,
          teamId: ch.teamId,
          matchId: ch.matchId,
          tournamentId: ch.tournamentId,
          clubId: ch.clubId,
          lastMessageSeq: ch.lastMessageSeq,
          lastMessageAt: ch.lastMessageAt,
          lastMessagePreview: ch.lastMessagePreview,
          lastMessageSenderId: ch.lastMessageSenderId,
          lastMessageFromMe: ch.lastMessageFromMe,
          unreadCount: ch.unreadCount,
          isAccepted: member?.status != 'pending',
          isPinned: member?.pinnedAt != null,
          isArchived: member?.archivedAt != null,
          isMuted: member?.notificationsMutedUntil != null &&
              member!.notificationsMutedUntil!.isAfter(now),
          dmOtherUserId: otherMember?.userId,
          createdAt: ch.serverUpdatedAt,
          updatedAt: ch.localUpdatedAt,
        ));
      }

      // Sort: pinned first, then lastMessageAt DESC nulls last, then createdAt DESC
      channels.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return channels;
    });
  }

  /// Watches all messages for a specific channel chronologically.
  Stream<List<ChatMessage>> watchMessages(
    String channelId,
    String currentUserId, {
    int? beforeMessageSeq,
  }) {
    final messagesQuery = _db.select(_db.localMessages)
      ..where((m) {
        Expression<bool> predicate = m.channelId.equals(channelId);
        if (beforeMessageSeq != null) {
          predicate = predicate &
              (m.messageSeq.isNull() |
                  m.messageSeq.isSmallerThanValue(beforeMessageSeq));
        }
        return predicate;
      })
      ..orderBy([
        (m) => OrderingTerm(
              expression: m.messageSeq,
              mode: OrderingMode.asc,
              nulls: NullsOrder.last,
            ),
        (m) => OrderingTerm(expression: m.localCreatedAt, mode: OrderingMode.asc),
      ]);

    final membersQuery = _db.select(_db.localChannelMembers)
      ..where((m) => m.channelId.equals(channelId));

    final attachmentsQuery = _db.select(_db.localMessageAttachments).join([
      innerJoin(
        _db.localMessages,
        _db.localMessages.messageId.equalsExp(_db.localMessageAttachments.messageId),
      ),
    ])..where(_db.localMessages.channelId.equals(channelId));

    final reactionsQuery = _db.select(_db.localMessageReactions).join([
      innerJoin(
        _db.localMessages,
        _db.localMessages.messageId.equalsExp(_db.localMessageReactions.messageId),
      ),
    ])..where(
        _db.localMessages.channelId.equals(channelId) &
        _db.localMessageReactions.removedAt.isNull(),
      );

    return Rx.combineLatest4(
      messagesQuery.watch(),
      membersQuery.watch(),
      attachmentsQuery.watch().map((rows) =>
          rows.map((r) => r.readTable(_db.localMessageAttachments)).toList()),
      reactionsQuery.watch().map((rows) =>
          rows.map((r) => r.readTable(_db.localMessageReactions)).toList()),
      (
        List<LocalMessageRow> messageRows,
        List<LocalChannelMemberRow> memberRows,
        List<LocalMessageAttachmentRow> attachmentRows,
        List<LocalMessageReactionRow> reactionRows,
      ) {
        if (messageRows.isEmpty) return const <ChatMessage>[];

        // Deduplicate rows by messageId preserving the newest version/timestamp
        final distinctMap = <String, LocalMessageRow>{};
        for (final r in messageRows) {
          final existing = distinctMap[r.messageId];
          if (existing == null) {
            distinctMap[r.messageId] = r;
          } else {
            final existingTime = existing.updatedAt ?? existing.localCreatedAt;
            final newTime = r.updatedAt ?? r.localCreatedAt;
            if (newTime.isAfter(existingTime)) {
              distinctMap[r.messageId] = r;
            }
          }
        }
        final distinctRows = distinctMap.values.toList();

        final attachmentMap = <String, List<MessageAttachment>>{};
        for (final a in attachmentRows) {
          attachmentMap.putIfAbsent(a.messageId, () => []).add(MessageAttachment(
                id: a.attachmentId,
                messageId: a.messageId,
                storagePath: a.storagePath,
                mimeType: a.mimeType,
                fileName: a.fileName,
                sizeBytes: a.sizeBytes,
                width: a.width,
                height: a.height,
                durationMs: a.durationMs,
                localPath: a.localPath,
                thumbnailLocalPath: a.thumbnailLocalPath,
                uploadStatus: a.uploadStatus,
              ));
        }

        final reactionMap = <String, List<MessageReaction>>{};
        for (final r in reactionRows) {
          reactionMap.putIfAbsent(r.messageId, () => []).add(MessageReaction(
                messageId: r.messageId,
                userId: r.userId,
                reaction: r.reaction,
                createdAt: r.createdAt,
                isRemoved: r.removedAt != null,
              ));
        }

        final otherMembers = memberRows
            .where((m) => m.userId != currentUserId && m.status == 'active')
            .toList();

        return distinctRows.map((r) {
          final fromMe = r.senderId == currentUserId;
          MessageDeliveryStatus deliveryStatus = MessageDeliveryStatus.sent;

          if (r.syncStatus == 'pending') {
            deliveryStatus = MessageDeliveryStatus.pending;
          } else if (r.syncStatus == 'sending') {
            deliveryStatus = MessageDeliveryStatus.sending;
          } else if (r.syncStatus == 'failed') {
            deliveryStatus = MessageDeliveryStatus.failed;
          } else if (fromMe && r.messageSeq != null) {
            final seq = r.messageSeq!;
            if (otherMembers.isNotEmpty) {
              final allRead = otherMembers.every(
                  (m) => (m.lastReadMessageSeq ?? 0) >= seq);
              if (allRead) {
                deliveryStatus = MessageDeliveryStatus.read;
              } else {
                final allDelivered = otherMembers.every((m) {
                  final del = m.lastDeliveredMessageSeq ?? 0;
                  final rd = m.lastReadMessageSeq ?? 0;
                  return (del > rd ? del : rd) >= seq;
                });
                if (allDelivered) {
                  deliveryStatus = MessageDeliveryStatus.delivered;
                } else {
                  deliveryStatus = MessageDeliveryStatus.sent;
                }
              }
            } else {
              deliveryStatus = MessageDeliveryStatus.sent;
            }
          }

          Map<String, dynamic> payload = {};
          try {
            payload = jsonDecode(r.payloadJson) as Map<String, dynamic>;
          } catch (_) {}

          return ChatMessage(
            id: r.messageId,
            messageSeq: r.messageSeq,
            channelId: r.channelId,
            senderId: r.senderId,
            senderDisplayName: r.senderDisplayName,
            messageType: r.messageType,
            body: r.body,
            payload: payload,
            replyToId: r.replyToMessageId,
            version: r.version,
            createdAt: r.createdAt ?? r.localCreatedAt,
            editedAt: r.editedAt,
            deletedAt: r.deletedAt,
            fromMe: fromMe,
            syncStatus: r.syncStatus,
            deliveryStatus: deliveryStatus,
            attachments: attachmentMap[r.messageId] ?? const [],
            reactions: reactionMap[r.messageId] ?? const [],
          );
        }).toList();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Upserts & Updates (Server Sync / Realtime Ingest)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upserts channels returned from `list_my_chats` RPC.
  Future<void> upsertChannelsFromDto(
    List<ChatChannelDto> dtos,
    String currentUserId,
  ) async {
    final now = DateTime.now().toUtc();
    await _db.batch((b) {
      for (final dto in dtos) {
        b.insert(
          _db.localChannels,
          LocalChannelsCompanion.insert(
            channelId: dto.channelId,
            channelKey: dto.channelKey,
            kind: dto.kind,
            contextType: dto.contextType,
            title: Value(dto.title ?? dto.teamName ?? dto.dmOtherUserName),
            avatarUrl: Value(dto.teamLogoUrl ?? dto.dmOtherUserAvatarUrl),
            teamId: Value(dto.teamId),
            matchId: Value(dto.matchId),
            lastMessageSeq: Value(dto.lastMessageSeq),
            lastMessageAt: Value(dto.lastMessageAt == null
                ? null
                : DateTime.parse(dto.lastMessageAt!)),
            lastMessagePreview: Value(dto.lastMessageBody),
            lastMessageSenderId: Value(dto.lastMessageSenderId),
            lastMessageFromMe: Value(dto.lastMessageFromMe),
            unreadCount: Value(dto.unreadCount),
            serverUpdatedAt: DateTime.parse(dto.updatedAt),
            localUpdatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );

        // Upsert current user membership with exact authoritative horizons
        final readAt = dto.lastReadAt != null ? DateTime.tryParse(dto.lastReadAt!) : null;
        final deliveredAt =
            dto.lastDeliveredAt != null ? DateTime.tryParse(dto.lastDeliveredAt!) : null;

        b.insert(
          _db.localChannelMembers,
          LocalChannelMembersCompanion.insert(
            channelId: dto.channelId,
            userId: currentUserId,
            status: Value(dto.isAccepted ? 'active' : 'pending'),
            lastReadMessageSeq: Value(dto.lastReadMessageSeq),
            lastReadAt: Value(readAt),
            lastDeliveredMessageSeq: Value(dto.lastDeliveredMessageSeq),
            lastDeliveredAt: Value(deliveredAt),
            pinnedAt: Value(dto.isPinned ? now : null),
            archivedAt: Value(dto.isArchived ? now : null),
            notificationsMutedUntil:
                Value(dto.isMuted ? now.add(const Duration(days: 365)) : null),
            serverUpdatedAt: DateTime.parse(dto.updatedAt),
          ),
          onConflict: DoUpdate(
            (old) => LocalChannelMembersCompanion(
              status: Value(dto.isAccepted ? 'active' : 'pending'),
              lastReadMessageSeq: dto.lastReadMessageSeq != null
                  ? Value(dto.lastReadMessageSeq)
                  : const Value.absent(),
              lastReadAt: readAt != null ? Value(readAt) : const Value.absent(),
              lastDeliveredMessageSeq: dto.lastDeliveredMessageSeq != null
                  ? Value(dto.lastDeliveredMessageSeq)
                  : const Value.absent(),
              lastDeliveredAt:
                  deliveredAt != null ? Value(deliveredAt) : const Value.absent(),
              pinnedAt: Value(dto.isPinned ? now : null),
              archivedAt: Value(dto.isArchived ? now : null),
              notificationsMutedUntil:
                  Value(dto.isMuted ? now.add(const Duration(days: 365)) : null),
              serverUpdatedAt: Value(DateTime.parse(dto.updatedAt)),
            ),
          ),
        );

        // Upsert DM counterparty if present
        if (dto.dmOtherUserId != null) {
          b.insert(
            _db.localChannelMembers,
            LocalChannelMembersCompanion.insert(
              channelId: dto.channelId,
              userId: dto.dmOtherUserId!,
              serverUpdatedAt: DateTime.parse(dto.updatedAt),
            ),
            onConflict: DoUpdate(
              (old) => LocalChannelMembersCompanion(
                serverUpdatedAt: Value(DateTime.parse(dto.updatedAt)),
              ),
            ),
          );
        }
      }
    });
  }

  /// Atomically updates a channel's last message summary from real-time events.
  /// Updates local_channels projection directly from real-time events without inserting
  /// incomplete stubs into local_messages (Spec §10, §11).
  Future<void> updateChannelSummaryFromRealtime({
    required String channelId,
    required int lastMessageSeq,
    required DateTime lastMessageAt,
    String? bodyPreview,
    String? messageId,
    String? senderId,
    String? senderDisplayName,
    String? messageType,
    String? currentUserId,
    int? unreadCount,
    bool? countsAsUnread,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      final currentChannel = await (_db.select(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .getSingleOrNull();

      if (currentChannel == null) return;

      final newSeq = currentChannel.lastMessageSeq != null
          ? (currentChannel.lastMessageSeq! > lastMessageSeq
              ? currentChannel.lastMessageSeq!
              : lastMessageSeq)
          : lastMessageSeq;

      int newUnreadCount = currentChannel.unreadCount;
      if (unreadCount != null) {
        newUnreadCount = unreadCount;
      } else if (senderId != null &&
          currentUserId != null &&
          senderId != currentUserId &&
          (countsAsUnread ?? true)) {
        if (lastMessageSeq > (currentChannel.lastMessageSeq ?? 0)) {
          newUnreadCount = currentChannel.unreadCount + 1;
        }
      }

      await (_db.update(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .write(
        LocalChannelsCompanion(
          lastMessageSeq: Value(newSeq),
          lastMessageAt: Value(lastMessageAt),
          lastMessagePreview:
              bodyPreview != null ? Value(bodyPreview) : const Value.absent(),
          lastMessageSenderId:
              senderId != null ? Value(senderId) : const Value.absent(),
          lastMessageFromMe: (senderId != null && currentUserId != null)
              ? Value(senderId == currentUserId)
              : const Value.absent(),
          unreadCount: Value(newUnreadCount),
          localUpdatedAt: Value(now),
        ),
      );
    });
  }

  /// Upserts message rows confirmed by server or ingested via Ably.
  Future<void> upsertMessagesFromDto(
    List<ChatMessageDto> dtos,
    String currentUserId,
  ) async {
    if (dtos.isEmpty) return;
    final now = DateTime.now().toUtc();
    final dtoIds = dtos.map((d) => d.messageId).toList();

    await _db.batch((b) {
      b.deleteWhere(_db.localMessages, (m) => m.messageId.isIn(dtoIds));
      b.deleteWhere(_db.localMessageAttachments, (a) => a.messageId.isIn(dtoIds));

      for (final dto in dtos) {
        b.insert(
          _db.localMessages,
          LocalMessagesCompanion.insert(
            messageId: dto.messageId,
            messageSeq: Value(dto.messageSeq),
            channelId: dto.channelId,
            senderId: Value(dto.senderId),
            senderDisplayName: Value(dto.senderDisplayName),
            messageType: Value(dto.messageType),
            body: Value(dto.body),
            payloadJson: Value(jsonEncode(dto.payload)),
            replyToMessageId: Value(dto.replyToMessageId),
            version: Value(dto.version),
            countsAsUnread: Value(dto.countsAsUnread),
            createdAt: Value(DateTime.parse(dto.createdAt)),
            updatedAt: Value(dto.updatedAt == null ? null : DateTime.parse(dto.updatedAt!)),
            editedAt: Value(dto.editedAt == null ? null : DateTime.parse(dto.editedAt!)),
            deletedAt: Value(dto.deletedAt == null ? null : DateTime.parse(dto.deletedAt!)),
            localCreatedAt: now,
            syncStatus: const Value('sent'),
          ),
          mode: InsertMode.insertOrReplace,
        );

        // Upsert attachments
        for (final att in dto.attachments) {
          b.insert(
            _db.localMessageAttachments,
            LocalMessageAttachmentsCompanion.insert(
              attachmentId: att.attachmentId,
              messageId: att.messageId,
              mimeType: att.mimeType,
              storagePath: Value(att.storagePath),
              fileName: Value(att.fileName),
              sizeBytes: Value(att.sizeBytes),
              width: Value(att.width),
              height: Value(att.height),
              durationMs: Value(att.durationMs),
              uploadStatus: const Value('uploaded'),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }

        // Upsert reactions
        for (final r in dto.reactions) {
          b.insert(
            _db.localMessageReactions,
            LocalMessageReactionsCompanion.insert(
              messageId: r.messageId,
              userId: r.userId,
              reaction: r.reaction,
              createdAt: DateTime.parse(r.createdAt),
              updatedAt: DateTime.parse(r.createdAt),
              removedAt: Value(r.removedAt == null ? null : DateTime.parse(r.removedAt!)),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  /// Updates message status upon network response or failure.
  Future<void> updateMessageSyncStatus(
    String messageId, {
    required String syncStatus,
    int? messageSeq,
    int? version,
    String? sendErrorCode,
    String? sendErrorMessage,
  }) async {
    await (_db.update(_db.localMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(LocalMessagesCompanion(
      syncStatus: Value(syncStatus),
      messageSeq: messageSeq != null ? Value(messageSeq) : const Value.absent(),
      version: version != null ? Value(version) : const Value.absent(),
      sendErrorCode: Value(sendErrorCode),
      sendErrorMessage: Value(sendErrorMessage),
    ));
  }

  /// Gets a single message row by messageId.
  Future<LocalMessageRow?> getMessage(String messageId) =>
      (_db.select(_db.localMessages)..where((m) => m.messageId.equals(messageId)))
          .getSingleOrNull();

  /// Soft-deletes a message locally.
  Future<void> softDeleteMessageLocally(String messageId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.localMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(LocalMessagesCompanion(
      deletedAt: Value(now),
      body: const Value('This message was deleted'),
    ));
  }

  /// Optimistically updates a local message's body and enqueues an outbox operation in a single transaction (Spec §18).
  Future<LocalMessageRow?> optimisticEditMessage({
    required String messageId,
    required String newBody,
    required OutboxOperationsCompanion operation,
  }) async {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .getSingleOrNull();

      if (existing == null) return null;

      final now = DateTime.now().toUtc();
      await (_db.update(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .write(
        LocalMessagesCompanion(
          body: Value(newBody),
          editedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await enqueueOperation(operation);

      return (_db.select(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .getSingle();
    });
  }

  /// Atomically resets a failed message and its associated outbox operation to 'pending' (Spec §19).
  Future<void> retryMessage(String messageId) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      // 1. Reset message status
      await (_db.update(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .write(const LocalMessagesCompanion(
        syncStatus: Value('pending'),
        sendErrorCode: Value(null),
        sendErrorMessage: Value(null),
      ));

      // 2. Reset matching Outbox operation
      await (_db.update(_db.outboxOperations)
            ..where((o) => o.entityId.equals(messageId)))
          .write(OutboxOperationsCompanion(
        status: const Value('pending'),
        attemptCount: const Value(0),
        nextAttemptAt: const Value(null),
        lastErrorCode: const Value(null),
        lastErrorMessage: const Value(null),
        updatedAt: Value(now),
      ));
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Channel Synchronization State (§3, §5, §22)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets the synchronization state and cursors for [channelId].
  Future<ChannelSyncStateRow?> getChannelSyncState(String channelId) {
    return (_db.select(_db.channelSyncStates)
          ..where((s) => s.channelId.equals(channelId)))
        .getSingleOrNull();
  }

  /// Marks synchronization as started/in-progress for [channelId].
  Future<void> markChannelSyncStarted(String channelId) async {
    final now = DateTime.now().toUtc();
    await _db.into(_db.channelSyncStates).insert(
          ChannelSyncStatesCompanion.insert(
            channelId: channelId,
            syncStatus: const Value('syncing'),
            lastFullSyncAt: Value(now),
          ),
          onConflict: DoUpdate(
            (old) => const ChannelSyncStatesCompanion(
              syncStatus: Value('syncing'),
              lastSyncError: Value(null),
            ),
          ),
        );
  }

  /// Marks synchronization as succeeded, advancing cursors monotonically.
  Future<void> markChannelSyncSucceeded(
    String channelId, {
    required int newestSeq,
    int? oldestSeq,
    bool? hasMore,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await getChannelSyncState(channelId);

    final currentNewest = existing?.newestSyncedMessageSeq ?? 0;
    final updatedNewest = newestSeq > currentNewest ? newestSeq : currentNewest;

    final currentOldest = existing?.oldestCachedMessageSeq;
    final updatedOldest = (oldestSeq != null && currentOldest != null)
        ? (oldestSeq < currentOldest ? oldestSeq : currentOldest)
        : (oldestSeq ?? currentOldest);

    await _db.into(_db.channelSyncStates).insert(
          ChannelSyncStatesCompanion.insert(
            channelId: channelId,
            newestSyncedMessageSeq: Value(updatedNewest),
            oldestCachedMessageSeq: Value(updatedOldest),
            hasMoreHistory: Value(hasMore ?? existing?.hasMoreHistory ?? true),
            lastFullSyncAt: Value(now),
            syncStatus: const Value('idle'),
            lastSyncError: const Value(null),
          ),
          onConflict: DoUpdate(
            (old) => ChannelSyncStatesCompanion(
              newestSyncedMessageSeq: Value(updatedNewest),
              oldestCachedMessageSeq: Value(updatedOldest),
              hasMoreHistory: Value(hasMore ?? existing?.hasMoreHistory ?? true),
              lastFullSyncAt: Value(now),
              syncStatus: const Value('idle'),
              lastSyncError: const Value(null),
            ),
          ),
        );
  }

  /// Marks synchronization as failed.
  Future<void> markChannelSyncFailed(String channelId, Object error) async {
    await (_db.update(_db.channelSyncStates)
          ..where((s) => s.channelId.equals(channelId)))
        .write(ChannelSyncStatesCompanion(
      syncStatus: const Value('failed'),
      lastSyncError: Value(error.toString()),
    ));
  }

  /// Atomically commits server messages and advances the forward sync cursor
  /// in the SAME Drift transaction (Spec §3 invariant).
  Future<void> commitMessagesAndAdvanceCursor({
    required String channelId,
    required List<ChatMessageDto> messages,
    required String currentUserId,
    required int newestSeq,
    int? oldestSeq,
    bool? hasMore,
  }) async {
    await _db.transaction(() async {
      if (messages.isNotEmpty) {
        await upsertMessagesFromDto(messages, currentUserId);
      }
      await markChannelSyncSucceeded(
        channelId,
        newestSeq: newestSeq,
        oldestSeq: oldestSeq,
        hasMore: hasMore,
      );
    });
  }

  /// Atomically commits older message history and updates oldestCachedMessageSeq
  /// without modifying newestSyncedMessageSeq (Spec §22).
  Future<void> commitOlderMessagesAndUpdateCursor({
    required String channelId,
    required List<ChatMessageDto> messages,
    required String currentUserId,
    required int oldestSeq,
    required bool hasMore,
  }) async {
    await _db.transaction(() async {
      if (messages.isNotEmpty) {
        await upsertMessagesFromDto(messages, currentUserId);
      }
      final existing = await getChannelSyncState(channelId);
      final currentOldest = existing?.oldestCachedMessageSeq;
      final updatedOldest = currentOldest != null && currentOldest < oldestSeq
          ? currentOldest
          : oldestSeq;

      await (_db.into(_db.channelSyncStates)).insert(
            ChannelSyncStatesCompanion.insert(
              channelId: channelId,
              oldestCachedMessageSeq: Value(updatedOldest),
              hasMoreHistory: Value(hasMore),
              syncStatus: const Value('idle'),
            ),
            onConflict: DoUpdate(
              (old) => ChannelSyncStatesCompanion(
                oldestCachedMessageSeq: Value(updatedOldest),
                hasMoreHistory: Value(hasMore),
                syncStatus: const Value('idle'),
              ),
            ),
          );
    });
  }

  /// Upserts or removes a message reaction locally.
  Future<void> upsertReaction({
    required String messageId,
    required String userId,
    required String reaction,
    required DateTime createdAt,
    DateTime? removedAt,
  }) async {
    await _db.into(_db.localMessageReactions).insert(
          LocalMessageReactionsCompanion.insert(
            messageId: messageId,
            userId: userId,
            reaction: reaction,
            createdAt: createdAt,
            updatedAt: DateTime.now().toUtc(),
            removedAt: Value(removedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Updates an attachment's storage path and upload status upon successful upload.
  Future<void> updateAttachmentStoragePath(
    String attachmentId, {
    required String storagePath,
    required String uploadStatus,
  }) async {
    await (_db.update(_db.localMessageAttachments)
          ..where((a) => a.attachmentId.equals(attachmentId)))
        .write(LocalMessageAttachmentsCompanion(
      storagePath: Value(storagePath),
      uploadStatus: Value(uploadStatus),
    ));
  }

  /// Updates an attachment's upload status or error.
  Future<void> updateAttachmentUploadStatus(
    String attachmentId, {
    required String uploadStatus,
    String? uploadError,
  }) async {
    await (_db.update(_db.localMessageAttachments)
          ..where((a) => a.attachmentId.equals(attachmentId)))
        .write(LocalMessageAttachmentsCompanion(
      uploadStatus: Value(uploadStatus),
      uploadError: Value(uploadError),
    ));
  }

  /// Gets all attachments associated with a message.
  Future<List<LocalMessageAttachmentRow>> getAttachmentsForMessage(String messageId) =>
      (_db.select(_db.localMessageAttachments)..where((a) => a.messageId.equals(messageId)))
          .get();

  /// Updates a member's read and delivered horizons.
  Future<void> updateMemberHorizons(
    String channelId,
    String userId, {
    int? readSeq,
    int? deliveredSeq,
  }) async {
    final now = DateTime.now().toUtc();
    // Guarantee delivered horizon >= read horizon
    final effectiveDeliveredSeq = (deliveredSeq != null && readSeq != null)
        ? (deliveredSeq > readSeq ? deliveredSeq : readSeq)
        : (deliveredSeq ?? readSeq);

    final existing = await (_db.select(_db.localChannelMembers)
          ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.localChannelMembers).insert(
            LocalChannelMembersCompanion.insert(
              channelId: channelId,
              userId: userId,
              lastReadMessageSeq: Value(readSeq),
              lastReadAt: Value(readSeq != null ? now : null),
              lastDeliveredMessageSeq: Value(effectiveDeliveredSeq),
              lastDeliveredAt: Value(effectiveDeliveredSeq != null ? now : null),
              serverUpdatedAt: now,
            ),
          );
    } else {
      final currentRead = existing.lastReadMessageSeq ?? 0;
      final currentDelivered = existing.lastDeliveredMessageSeq ?? 0;
      final newRead = readSeq != null && readSeq > currentRead ? readSeq : null;
      final newDelivered = effectiveDeliveredSeq != null &&
              effectiveDeliveredSeq > currentDelivered
          ? effectiveDeliveredSeq
          : (newRead != null && newRead > currentDelivered ? newRead : null);

      await (_db.update(_db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
          .write(LocalChannelMembersCompanion(
        lastReadMessageSeq:
            newRead != null ? Value(newRead) : const Value.absent(),
        lastReadAt: newRead != null ? Value(now) : const Value.absent(),
        lastDeliveredMessageSeq:
            newDelivered != null ? Value(newDelivered) : const Value.absent(),
        lastDeliveredAt:
            newDelivered != null ? Value(now) : const Value.absent(),
      ));
    }

    // If read reached or exceeded lastMessageSeq, local unread count safely becomes 0
    if (readSeq != null) {
      final ch = await (_db.select(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .getSingleOrNull();
      if (ch != null && (ch.lastMessageSeq == null || readSeq >= ch.lastMessageSeq!)) {
        await (_db.update(_db.localChannels)
              ..where((c) => c.channelId.equals(channelId)))
            .write(const LocalChannelsCompanion(unreadCount: Value(0)));
      }
    }
  }

  /// Gets the highest message sequence known locally for a channel.
  Future<int?> getLatestMessageSeq(String channelId) async {
    final ch = await (_db.select(_db.localChannels)
          ..where((c) => c.channelId.equals(channelId)))
        .getSingleOrNull();
    final latestMsg = await (_db.select(_db.localMessages)
          ..where((m) =>
              m.channelId.equals(channelId) &
              m.messageSeq.isNotNull())
          ..orderBy([(m) => OrderingTerm.desc(m.messageSeq)])
          ..limit(1))
        .getSingleOrNull();

    final chSeq = ch?.lastMessageSeq;
    final msgSeq = latestMsg?.messageSeq;
    if (chSeq == null && msgSeq == null) return null;
    if (chSeq == null) return msgSeq;
    if (msgSeq == null) return chSeq;
    return chSeq > msgSeq ? chSeq : msgSeq;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Outbox Operations (Spec §7.2)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Atomic Outbox insertion for local-first message echo before network send.
  Future<void> enqueueOutgoingMessage({
    required LocalMessagesCompanion message,
    required OutboxOperationsCompanion operation,
    List<LocalMessageAttachmentsCompanion>? attachments,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.localMessages).insert(message);
      if (attachments != null && attachments.isNotEmpty) {
        for (final att in attachments) {
          await _db.into(_db.localMessageAttachments).insert(att);
        }
      }
      await _db.into(_db.outboxOperations).insert(operation);

      // Update channel's localUpdatedAt so inbox moves this channel to top immediately
      await (_db.update(_db.localChannels)
            ..where((c) => c.channelId.equals(message.channelId.value)))
          .write(LocalChannelsCompanion(
        localUpdatedAt: Value(DateTime.now().toUtc()),
      ));
    });
  }

  /// Enqueues generic outbox operations (edit, delete, mark_read, mark_delivered, reaction).
  Future<void> enqueueOperation(OutboxOperationsCompanion op) async {
    await _db.transaction(() async {
      // Coalescing check (Spec §20)
      if (op.coalesceKey.present && op.coalesceKey.value != null) {
        final key = op.coalesceKey.value!;
        final isReceipt = key.startsWith('read:') || key.startsWith('delivered:');
        if (isReceipt) {
          final existing = await (_db.select(_db.outboxOperations)
                ..where((o) =>
                    o.coalesceKey.equals(key) &
                    o.status.isIn(['pending', 'retry_wait'])))
              .getSingleOrNull();
          if (existing != null) {
            try {
              final oldPayload =
                  jsonDecode(existing.payloadJson) as Map<String, dynamic>;
              final newPayload =
                  jsonDecode(op.payloadJson.value) as Map<String, dynamic>;
              final oldSeq = (oldPayload['through_seq'] as num?)?.toInt() ?? 0;
              final newSeq = (newPayload['through_seq'] as num?)?.toInt() ?? 0;
              if (oldSeq >= newSeq) {
                // Keep the larger existing horizon; do not regress intent!
                return;
              }
            } catch (_) {}
          }
        }
        await (_db.delete(_db.outboxOperations)
              ..where((o) =>
                  o.coalesceKey.equals(key) &
                  o.status.isIn(['pending', 'retry_wait'])))
            .go();
      }
      await _db.into(_db.outboxOperations).insert(op);
    });
  }

  /// Retrieves pending operations sorted chronologically (FIFO lane per channel).
  Future<List<OutboxOperationRow>> getPendingOperations({String? channelId}) async {
    final now = DateTime.now().toUtc();
    final query = _db.select(_db.outboxOperations)
      ..where((o) {
        Expression<bool> pred = o.status.equals('pending') |
            (o.status.equals('retry_wait') &
                (o.nextAttemptAt.isNull() | o.nextAttemptAt.isSmallerOrEqualValue(now)));
        if (channelId != null) {
          pred = pred & o.channelId.equals(channelId);
        }
        return pred;
      })
      ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]);

    return query.get();
  }

  /// Updates status of an outbox operation.
  Future<void> updateOutboxOperation(
    String operationId, {
    required String status,
    int? attemptCount,
    DateTime? nextAttemptAt,
    String? lastErrorCode,
    String? lastErrorMessage,
  }) async {
    await (_db.update(_db.outboxOperations)
          ..where((o) => o.operationId.equals(operationId)))
        .write(OutboxOperationsCompanion(
      status: Value(status),
      attemptCount: attemptCount != null ? Value(attemptCount) : const Value.absent(),
      nextAttemptAt: Value(nextAttemptAt),
      lastErrorCode: Value(lastErrorCode),
      lastErrorMessage: Value(lastErrorMessage),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
  }

  /// Deletes a successfully completed outbox operation.
  Future<void> deleteOutboxOperation(String operationId) async {
    await (_db.delete(_db.outboxOperations)
          ..where((o) => o.operationId.equals(operationId)))
        .go();
  }

  /// Recovers outbox operations that were left in 'processing' state due to
  /// an unexpected process death or crash (Spec §15).
  Future<int> recoverStaleProcessingOperations({
    Duration lease = const Duration(minutes: 2),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(lease);
    return (_db.update(_db.outboxOperations)
          ..where((o) =>
              o.status.equals('processing') &
              o.updatedAt.isSmallerThanValue(cutoff)))
        .write(const OutboxOperationsCompanion(
      status: Value('pending'),
      nextAttemptAt: Value(null),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Drafts
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> readDraft(String channelId) async {
    final row = await (_db.select(_db.channelDrafts)
          ..where((d) => d.channelId.equals(channelId)))
        .getSingleOrNull();
    return row?.body;
  }

  Future<void> saveDraft(String channelId, String body, {String? replyToId}) async {
    await _db.into(_db.channelDrafts).insertOnConflictUpdate(
          ChannelDraftsCompanion.insert(
            channelId: channelId,
            body: body,
            replyToMessageId: Value(replyToId),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> deleteDraft(String channelId) async {
    await (_db.delete(_db.channelDrafts)
          ..where((d) => d.channelId.equals(channelId)))
        .go();
  }
}
