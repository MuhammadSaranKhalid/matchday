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
      final channels = <ChatChannel>[];

      for (final row in rows) {
        final ch = row.readTable(_db.localChannels);
        final member = row.readTableOrNull(_db.localChannelMembers);

        // Fetch latest message for this channel preview
        final latestMsg = await (_db.select(_db.localMessages)
              ..where((m) => m.channelId.equals(ch.channelId))
              ..orderBy([
                (m) => OrderingTerm(
                      expression: m.messageSeq,
                      mode: OrderingMode.desc,
                      nulls: NullsOrder.last,
                    ),
                (m) => OrderingTerm(expression: m.localCreatedAt, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();

        // Calculate unread count
        // If the latest message was sent by current user, current user has read at least up to that message
        final fromMeLatestSeq = (latestMsg?.senderId == currentUserId) ? (latestMsg?.messageSeq ?? 0) : 0;
        final memberReadSeq = member?.lastReadMessageSeq ?? 0;
        final lastReadSeq = fromMeLatestSeq > memberReadSeq ? fromMeLatestSeq : memberReadSeq;

        final unreadCountQuery = _db.localMessages.messageId.count(
          filter: _db.localMessages.channelId.equals(ch.channelId) &
              _db.localMessages.messageSeq.isBiggerThanValue(lastReadSeq) &
              _db.localMessages.countsAsUnread.equals(true) &
              (_db.localMessages.senderId.isNotValue(currentUserId) |
                  _db.localMessages.senderId.isNull()),
        );

        final unreadResult = await (_db.selectOnly(_db.localMessages)
              ..where(_db.localMessages.channelId.equals(ch.channelId))
              ..addColumns([unreadCountQuery]))
            .getSingleOrNull();

        final unreadCount = unreadResult?.read(unreadCountQuery) ?? 0;

        // For DM channels, fetch the other participant's metadata if available
        LocalChannelMemberRow? otherMember;
        if (ch.kind == 'direct') {
          otherMember = await (_db.select(_db.localChannelMembers)
                ..where((m) =>
                    m.channelId.equals(ch.channelId) &
                    m.userId.isNotValue(currentUserId))
                ..limit(1))
              .getSingleOrNull();
        }

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
          lastMessageSeq: latestMsg?.messageSeq ?? ch.lastMessageSeq,
          lastMessageAt: latestMsg?.createdAt ?? latestMsg?.localCreatedAt ?? ch.lastMessageAt,
          lastMessagePreview: latestMsg?.body,
          lastMessageSenderId: latestMsg?.senderId,
          lastMessageFromMe: latestMsg?.senderId == currentUserId,
          unreadCount: unreadCount,
          isAccepted: member?.status != 'pending',
          isPinned: member?.pinnedAt != null,
          isArchived: member?.archivedAt != null,
          isMuted: member?.notificationsMutedUntil != null &&
              member!.notificationsMutedUntil!.isAfter(DateTime.now()),
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
            serverUpdatedAt: DateTime.parse(dto.updatedAt),
            localUpdatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );

        // Upsert current user membership
        final initialReadSeq = dto.unreadCount == 0 && dto.lastMessageSeq != null
            ? dto.lastMessageSeq
            : (dto.lastMessageSeq != null && dto.unreadCount > 0
                ? (dto.lastMessageSeq! - dto.unreadCount)
                : null);

        b.insert(
          _db.localChannelMembers,
          LocalChannelMembersCompanion.insert(
            channelId: dto.channelId,
            userId: currentUserId,
            status: Value(dto.isAccepted ? 'active' : 'pending'),
            lastReadMessageSeq: Value(initialReadSeq),
            pinnedAt: Value(dto.isPinned ? now : null),
            archivedAt: Value(dto.isArchived ? now : null),
            notificationsMutedUntil:
                Value(dto.isMuted ? now.add(const Duration(days: 365)) : null),
            serverUpdatedAt: DateTime.parse(dto.updatedAt),
          ),
          onConflict: DoUpdate(
            (old) => LocalChannelMembersCompanion(
              status: Value(dto.isAccepted ? 'active' : 'pending'),
              lastReadMessageSeq: dto.unreadCount == 0 && dto.lastMessageSeq != null
                  ? Value(dto.lastMessageSeq)
                  : const Value.absent(),
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
  Future<void> updateChannelSummaryFromRealtime({
    required String channelId,
    required int lastMessageSeq,
    required DateTime lastMessageAt,
    String? bodyPreview,
    String? messageId,
    String? senderId,
    String? senderDisplayName,
    String? messageType,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      // 1. Update local_channels with latest activity
      await (_db.update(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .write(
        LocalChannelsCompanion(
          lastMessageSeq: Value(lastMessageSeq),
          lastMessageAt: Value(lastMessageAt),
          localUpdatedAt: Value(now),
        ),
      );

      // 2. If messageId is present, also upsert stub/preview into local_messages
      if (messageId != null) {
        await _db.into(_db.localMessages).insert(
          LocalMessagesCompanion.insert(
            messageId: messageId,
            messageSeq: Value(lastMessageSeq),
            channelId: channelId,
            senderId: Value(senderId),
            senderDisplayName: Value(senderDisplayName),
            messageType: Value(messageType ?? 'text'),
            body: Value(bodyPreview),
            syncStatus: const Value('sent'),
            createdAt: Value(lastMessageAt),
            localCreatedAt: now,
          ),
          onConflict: DoUpdate((old) => LocalMessagesCompanion(
            messageSeq: Value(lastMessageSeq),
            syncStatus: const Value('sent'),
            body: Value(bodyPreview),
          )),
        );
      }
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
              lastDeliveredMessageSeq: Value(deliveredSeq),
              lastDeliveredAt: Value(deliveredSeq != null ? now : null),
              serverUpdatedAt: now,
            ),
          );
    } else {
      await (_db.update(_db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
          .write(LocalChannelMembersCompanion(
        lastReadMessageSeq: readSeq != null &&
                readSeq > (existing.lastReadMessageSeq ?? 0)
            ? Value(readSeq)
            : const Value.absent(),
        lastReadAt: readSeq != null &&
                readSeq > (existing.lastReadMessageSeq ?? 0)
            ? Value(now)
            : const Value.absent(),
        lastDeliveredMessageSeq: deliveredSeq != null &&
                deliveredSeq > (existing.lastDeliveredMessageSeq ?? 0)
            ? Value(deliveredSeq)
            : const Value.absent(),
        lastDeliveredAt: deliveredSeq != null &&
                deliveredSeq > (existing.lastDeliveredMessageSeq ?? 0)
            ? Value(now)
            : const Value.absent(),
      ));
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
      // Coalescing check
      if (op.coalesceKey.present && op.coalesceKey.value != null) {
        final key = op.coalesceKey.value!;
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
