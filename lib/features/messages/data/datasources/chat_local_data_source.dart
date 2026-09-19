import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/entities/chat_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/entities/chat_sync_state.dart';
import '../../domain/entities/message_attachment.dart';
import '../../domain/entities/message_reaction.dart';
import '../models/chat_channel_dto.dart';
import '../models/chat_message_dto.dart';
import '../models/chat_participant_dto.dart';

/// Local-first Drift data source. All presentation streams read from here.
class ChatLocalDataSource {
  ChatLocalDataSource(this._db);

  final AppDatabase _db;

  // ──────────────────────────────────────────────────────────────────────────
  // Reactive inbox / thread projections
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<ChatChannel>> watchInbox(String currentUserId) {
    final query = _db.select(_db.localChannels).join([
      innerJoin(
        _db.localChannelMembers,
        _db.localChannelMembers.channelId.equalsExp(_db.localChannels.channelId) &
            _db.localChannelMembers.userId.equals(currentUserId) &
            _db.localChannelMembers.status.isIn(const ['active', 'pending']) &
            _db.localChannelMembers.archivedAt.isNull(),
      ),
    ]);

    return query.watch().asyncMap((rows) async {
      if (rows.isEmpty) return const <ChatChannel>[];

      final directChannelIds = rows
          .map((r) => r.readTable(_db.localChannels))
          .where((c) => c.kind == 'direct')
          .map((c) => c.channelId)
          .toList();

      final otherMembers = directChannelIds.isEmpty
          ? <LocalChannelMemberRow>[]
          : await (_db.select(_db.localChannelMembers)
                ..where(
                  (m) =>
                      m.channelId.isIn(directChannelIds) &
                      m.userId.isNotValue(currentUserId),
                ))
              .get();

      final otherByChannel = <String, LocalChannelMemberRow>{};
      for (final member in otherMembers) {
        otherByChannel.putIfAbsent(member.channelId, () => member);
      }

      final now = DateTime.now().toUtc();
      final channels = <ChatChannel>[];

      for (final row in rows) {
        final ch = row.readTable(_db.localChannels);
        final member = row.readTable(_db.localChannelMembers);
        final other = otherByChannel[ch.channelId];

        channels.add(
          ChatChannel(
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
            lastReadMessageSeq: member.lastReadMessageSeq,
            lastDeliveredMessageSeq: member.lastDeliveredMessageSeq,
            isAccepted: member.status != 'pending',
            isPinned: member.pinnedAt != null,
            isArchived: member.archivedAt != null,
            isMuted: member.notificationsMutedUntil != null &&
                member.notificationsMutedUntil!.isAfter(now),
            dmOtherUserId: ch.dmOtherUserId ?? other?.userId,
            dmOtherUserName: ch.dmOtherUserName ?? other?.displayName,
            dmOtherUserUsername: ch.dmOtherUserUsername ?? other?.username,
            dmOtherUserAvatarUrl: ch.dmOtherUserAvatarUrl ?? other?.avatarUrl,
            dmOtherMemberStatus: ch.dmOtherMemberStatus ?? other?.status,
            youFollow: ch.youFollow,
            theyFollowYou: ch.theyFollowYou,
            // The list_my_chats projection currently stores team values in
            // LocalChannels title/avatar; these explicit fields remain null
            // locally unless the DTO supplies them through the title/avatar.
            teamName: ch.contextType == 'team' ? ch.title : null,
            teamLogoUrl: ch.contextType == 'team' ? ch.avatarUrl : null,
            createdAt: ch.serverUpdatedAt,
            updatedAt: ch.localUpdatedAt,
          ),
        );
      }

      channels.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return channels;
    });
  }

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
        (m) => OrderingTerm.asc(m.localCreatedAt),
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
    ])
      ..where(
        _db.localMessages.channelId.equals(channelId) &
            _db.localMessageReactions.removedAt.isNull(),
      );

    return Rx.combineLatest4(
      messagesQuery.watch(),
      membersQuery.watch(),
      attachmentsQuery.watch().map(
            (rows) => rows
                .map((r) => r.readTable(_db.localMessageAttachments))
                .toList(),
          ),
      reactionsQuery.watch().map(
            (rows) => rows
                .map((r) => r.readTable(_db.localMessageReactions))
                .toList(),
          ),
      (
        List<LocalMessageRow> messageRows,
        List<LocalChannelMemberRow> memberRows,
        List<LocalMessageAttachmentRow> attachmentRows,
        List<LocalMessageReactionRow> reactionRows,
      ) {
        if (messageRows.isEmpty) return const <ChatMessage>[];

        final distinct = <String, LocalMessageRow>{};
        for (final row in messageRows) {
          final existing = distinct[row.messageId];
          if (existing == null) {
            distinct[row.messageId] = row;
            continue;
          }
          final existingTime = existing.updatedAt ?? existing.localCreatedAt;
          final rowTime = row.updatedAt ?? row.localCreatedAt;
          if (rowTime.isAfter(existingTime)) distinct[row.messageId] = row;
        }

        final attachmentsByMessage = <String, List<MessageAttachment>>{};
        for (final row in attachmentRows) {
          attachmentsByMessage.putIfAbsent(row.messageId, () => []).add(
                MessageAttachment(
                  id: row.attachmentId,
                  messageId: row.messageId,
                  storagePath: row.storagePath,
                  mimeType: row.mimeType,
                  fileName: row.fileName,
                  sizeBytes: row.sizeBytes,
                  width: row.width,
                  height: row.height,
                  durationMs: row.durationMs,
                  localPath: row.localPath,
                  thumbnailLocalPath: row.thumbnailLocalPath,
                  uploadStatus: row.uploadStatus,
                ),
              );
        }

        final reactionsByMessage = <String, List<MessageReaction>>{};
        for (final row in reactionRows) {
          reactionsByMessage.putIfAbsent(row.messageId, () => []).add(
                MessageReaction(
                  messageId: row.messageId,
                  userId: row.userId,
                  reaction: row.reaction,
                  createdAt: row.createdAt,
                  isRemoved: row.removedAt != null,
                ),
              );
        }

        final membersByUser = {
          for (final member in memberRows) member.userId: member,
        };
        final otherActiveMembers = memberRows
            .where((m) => m.userId != currentUserId && m.status == 'active')
            .toList();

        final baseMessages = distinct.values.map((row) {
          final fromMe = row.senderId == currentUserId;
          var deliveryStatus = MessageDeliveryStatus.sent;

          if (row.syncStatus == 'pending') {
            deliveryStatus = MessageDeliveryStatus.pending;
          } else if (row.syncStatus == 'sending') {
            deliveryStatus = MessageDeliveryStatus.sending;
          } else if (row.syncStatus == 'failed') {
            deliveryStatus = MessageDeliveryStatus.failed;
          } else if (fromMe && row.messageSeq != null && otherActiveMembers.isNotEmpty) {
            final seq = row.messageSeq!;
            final allRead = otherActiveMembers.every(
              (member) => (member.lastReadMessageSeq ?? 0) >= seq,
            );
            if (allRead) {
              deliveryStatus = MessageDeliveryStatus.read;
            } else {
              final allDelivered = otherActiveMembers.every((member) {
                final delivered = member.lastDeliveredMessageSeq ?? 0;
                final read = member.lastReadMessageSeq ?? 0;
                return (delivered > read ? delivered : read) >= seq;
              });
              deliveryStatus = allDelivered
                  ? MessageDeliveryStatus.delivered
                  : MessageDeliveryStatus.sent;
            }
          }

          Map<String, dynamic> payload = const {};
          try {
            payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
          } catch (_) {}

          final sender = row.senderId == null ? null : membersByUser[row.senderId];

          return ChatMessage(
            id: row.messageId,
            messageSeq: row.messageSeq,
            channelId: row.channelId,
            senderId: row.senderId,
            senderDisplayName: sender?.displayName ?? row.senderDisplayName,
            senderUsername: sender?.username,
            senderAvatarUrl: sender?.avatarUrl,
            messageType: row.messageType,
            body: row.body,
            payload: payload,
            replyToId: row.replyToMessageId,
            version: row.version,
            createdAt: row.createdAt ?? row.localCreatedAt,
            editedAt: row.editedAt,
            deletedAt: row.deletedAt,
            fromMe: fromMe,
            syncStatus: row.syncStatus,
            deliveryStatus: deliveryStatus,
            attachments: attachmentsByMessage[row.messageId] ?? const [],
            reactions: reactionsByMessage[row.messageId] ?? const [],
          );
        }).toList();

        final byId = {for (final message in baseMessages) message.id: message};

        return baseMessages.map((message) {
          final replyId = message.replyToId;
          if (replyId == null) return message;

          final quoted = byId[replyId];
          if (quoted == null) return message;

          final quoteBody = quoted.isDeleted
              ? 'This message was deleted'
              : quoted.isImage
                  ? '📷 Photo'
                  : quoted.body;

          return message.withReplyPreview(
            body: quoteBody,
            author: quoted.fromMe
                ? 'You'
                : quoted.senderDisplayName ?? 'Deleted user',
          );
        }).toList();
      },
    );
  }

  Stream<List<ChatParticipant>> watchParticipants(String channelId) {
    return (_db.select(_db.localChannelMembers)
          ..where((m) => m.channelId.equals(channelId))
          ..orderBy([(m) => OrderingTerm.asc(m.displayName)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => ChatParticipant(
                  channelId: row.channelId,
                  userId: row.userId,
                  displayName: row.displayName?.trim().isNotEmpty == true
                      ? row.displayName!.trim()
                      : (row.username?.trim().isNotEmpty == true
                          ? '@${row.username!.trim()}'
                          : 'Deleted user'),
                  username: row.username,
                  avatarUrl: row.avatarUrl,
                  channelRole: row.role,
                  membershipStatus: row.status,
                  lastReadMessageSeq: row.lastReadMessageSeq,
                  lastDeliveredMessageSeq: row.lastDeliveredMessageSeq,
                ),
              )
              .toList(),
        );
  }

  Stream<ChatSyncState> watchChannelSyncState(String channelId) {
    return (_db.select(_db.channelSyncStates)
          ..where((s) => s.channelId.equals(channelId)))
        .watchSingleOrNull()
        .map((row) {
      if (row == null) {
        return ChatSyncState(
          channelId: channelId,
          phase: ChatSyncPhase.unhydrated,
        );
      }

      final phase = switch (row.syncStatus) {
        'syncing' => ChatSyncPhase.syncing,
        'failed' => ChatSyncPhase.failed,
        _ => ChatSyncPhase.ready,
      };

      return ChatSyncState(
        channelId: channelId,
        phase: phase,
        lastError: row.lastSyncError,
        hasMoreHistory: row.hasMoreHistory,
        newestSyncedMessageSeq: row.newestSyncedMessageSeq,
        oldestCachedMessageSeq: row.oldestCachedMessageSeq,
      );
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Inbox + participant synchronization
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> upsertChannelsFromDto(
    List<ChatChannelDto> dtos,
    String currentUserId,
  ) async {
    final now = DateTime.now().toUtc();
    final serverChannelIds = dtos.map((d) => d.channelId).toSet();

    final localMemberships = await (_db.select(_db.localChannelMembers)
          ..where((m) => m.userId.equals(currentUserId)))
        .get();

    final localIds = localMemberships.map((m) => m.channelId).toSet();
    final absent = localIds.difference(serverChannelIds);

    if (absent.isNotEmpty) {
      final pendingOps = await (_db.select(_db.outboxOperations)
            ..where(
              (o) =>
                  o.channelId.isIn(absent) &
                  o.status.isIn(const ['pending', 'processing', 'retry_wait']),
            ))
          .get();
      final protected = pendingOps.map((o) => o.channelId).toSet();

      for (final channelId in absent.difference(protected)) {
        // The authoritative inbox no longer contains this current-user
        // membership. LocalChannelMembers also caches OTHER participants now,
        // so checking whether "any member row remains" would keep stale
        // conversations forever. Prune the whole per-channel cache instead.
        await deleteChannelCache(channelId);
      }
    }

    // A just-issued Accept/Decline can race with an inbox response that was
    // produced before the server command committed. Preserve the durable local
    // intent until its outbox command is completed instead of rolling the UI
    // backward to stale server membership state.
    final requestOps = await (_db.select(_db.outboxOperations)
          ..where(
            (o) =>
                o.ownerUserId.equals(currentUserId) &
                o.operationType.isIn(const ['accept_invite', 'decline_invite']) &
                o.status.isIn(const ['pending', 'processing', 'retry_wait']),
          )
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
        .get();
    final optimisticRequestStatus = <String, String>{};
    for (final operation in requestOps) {
      optimisticRequestStatus[operation.channelId] =
          operation.operationType == 'accept_invite' ? 'active' : 'declined';
    }

    await _db.batch((batch) {
      for (final dto in dtos) {
        batch.insert(
          _db.localChannels,
          LocalChannelsCompanion.insert(
            channelId: dto.channelId,
            channelKey: dto.channelKey,
            kind: dto.kind,
            contextType: dto.contextType,
            title: Value(dto.title ?? dto.teamName ?? dto.dmOtherUserName),
            avatarUrl: Value(
              dto.avatarUrl ?? dto.teamLogoUrl ?? dto.dmOtherUserAvatarUrl,
            ),
            teamId: Value(dto.teamId),
            matchId: Value(dto.matchId),
            tournamentId: Value(dto.tournamentId),
            lastMessageSeq: Value(dto.lastMessageSeq),
            lastMessageAt: Value(
              dto.lastMessageAt == null ? null : DateTime.parse(dto.lastMessageAt!),
            ),
            lastMessagePreview: Value(dto.lastMessageBody),
            lastMessageSenderId: Value(dto.lastMessageSenderId),
            lastMessageFromMe: Value(dto.lastMessageFromMe),
            unreadCount: Value(dto.unreadCount),
            serverUpdatedAt: DateTime.parse(dto.updatedAt),
            localUpdatedAt: now,
            dmOtherUserId: Value(dto.dmOtherUserId),
            dmOtherUserName: Value(dto.dmOtherUserName),
            dmOtherUserUsername: Value(dto.dmOtherUserUsername),
            dmOtherUserAvatarUrl: Value(dto.dmOtherUserAvatarUrl),
            dmOtherMemberStatus: Value(dto.dmOtherMemberStatus),
            youFollow: Value(dto.youFollow),
            theyFollowYou: Value(dto.theyFollowYou),
          ),
          mode: InsertMode.insertOrReplace,
        );

        final readAt = dto.lastReadAt == null ? null : DateTime.tryParse(dto.lastReadAt!);
        final deliveredAt = dto.lastDeliveredAt == null
            ? null
            : DateTime.tryParse(dto.lastDeliveredAt!);
        final pinnedAt = dto.pinnedAt != null
            ? DateTime.tryParse(dto.pinnedAt!)
            : (dto.isPinned ? now : null);
        final archivedAt = dto.archivedAt != null
            ? DateTime.tryParse(dto.archivedAt!)
            : (dto.isArchived ? now : null);
        final mutedUntil = dto.notificationsMutedUntil != null
            ? DateTime.tryParse(dto.notificationsMutedUntil!)
            : (dto.isMuted ? now.add(const Duration(days: 365)) : null);

        final currentMembershipStatus = optimisticRequestStatus[dto.channelId] ??
            (dto.isAccepted ? 'active' : 'pending');

        batch.insert(
          _db.localChannelMembers,
          LocalChannelMembersCompanion.insert(
            channelId: dto.channelId,
            userId: currentUserId,
            status: Value(currentMembershipStatus),
            lastReadMessageSeq: Value(dto.lastReadMessageSeq),
            lastReadAt: Value(readAt),
            lastDeliveredMessageSeq: Value(dto.lastDeliveredMessageSeq),
            lastDeliveredAt: Value(deliveredAt),
            pinnedAt: Value(pinnedAt),
            archivedAt: Value(archivedAt),
            notificationsMutedUntil: Value(mutedUntil),
            serverUpdatedAt: DateTime.parse(dto.updatedAt),
          ),
          onConflict: DoUpdate(
            (_) => LocalChannelMembersCompanion(
              status: Value(currentMembershipStatus),
              lastReadMessageSeq: Value(dto.lastReadMessageSeq),
              lastReadAt: Value(readAt),
              lastDeliveredMessageSeq: Value(dto.lastDeliveredMessageSeq),
              lastDeliveredAt: Value(deliveredAt),
              pinnedAt: Value(pinnedAt),
              archivedAt: Value(archivedAt),
              notificationsMutedUntil: Value(mutedUntil),
              serverUpdatedAt: Value(DateTime.parse(dto.updatedAt)),
            ),
          ),
        );

        if (dto.dmOtherUserId != null) {
          batch.insert(
            _db.localChannelMembers,
            LocalChannelMembersCompanion.insert(
              channelId: dto.channelId,
              userId: dto.dmOtherUserId!,
              displayName: Value(dto.dmOtherUserName),
              username: Value(dto.dmOtherUserUsername),
              avatarUrl: Value(dto.dmOtherUserAvatarUrl),
              status: Value(dto.dmOtherMemberStatus ?? 'active'),
              serverUpdatedAt: DateTime.parse(dto.updatedAt),
            ),
            onConflict: DoUpdate(
              (_) => LocalChannelMembersCompanion(
                displayName: Value(dto.dmOtherUserName),
                username: Value(dto.dmOtherUserUsername),
                avatarUrl: Value(dto.dmOtherUserAvatarUrl),
                status: Value(dto.dmOtherMemberStatus ?? 'active'),
                serverUpdatedAt: Value(DateTime.parse(dto.updatedAt)),
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> upsertParticipants(
    List<ChatParticipantDto> participants, {
    required String currentUserId,
  }) async {
    if (participants.isEmpty) return;

    // Identity/role/status can be replaced from the latest authoritative
    // participant snapshot. Receipt horizons are different: realtime may have
    // advanced them after this request started, so they must merge
    // monotonically instead of being overwritten by an older response.
    await _db.batch((batch) {
      for (final participant in participants) {
        batch.insert(
          _db.localChannelMembers,
          LocalChannelMembersCompanion.insert(
            channelId: participant.channelId,
            userId: participant.userId,
            role: Value(participant.channelRole),
            status: Value(participant.membershipStatus),
            displayName: Value(participant.displayName),
            username: Value(participant.username),
            avatarUrl: Value(participant.avatarUrl),
            lastReadMessageSeq: Value(participant.lastReadMessageSeq),
            lastReadAt: Value(participant.lastReadAt),
            lastDeliveredMessageSeq: Value(participant.lastDeliveredMessageSeq),
            lastDeliveredAt: Value(participant.lastDeliveredAt),
            serverUpdatedAt: participant.updatedAt,
          ),
          onConflict: DoUpdate(
            (_) => LocalChannelMembersCompanion(
              role: Value(participant.channelRole),
              // Current-user membership state is owned by list_my_chats and
              // optimistic accept/decline commands. A participant hydration
              // request may have started before one of those transitions and
              // must not roll the local state back with a stale response.
              status: participant.userId == currentUserId
                  ? const Value.absent()
                  : Value(participant.membershipStatus),
              displayName: Value(participant.displayName),
              username: Value(participant.username),
              avatarUrl: Value(participant.avatarUrl),
              serverUpdatedAt: Value(participant.updatedAt),
            ),
          ),
        );
      }
    });

    for (final participant in participants) {
      if (participant.lastReadMessageSeq != null ||
          participant.lastDeliveredMessageSeq != null) {
        await updateMemberHorizons(
          participant.channelId,
          participant.userId,
          readSeq: participant.lastReadMessageSeq,
          deliveredSeq: participant.lastDeliveredMessageSeq,
        );
      }
    }
  }

  Future<void> deleteChannelCache(String channelId) async {
    await _db.transaction(() async {
      final messageIds = await (_db.select(_db.localMessages)
            ..where((m) => m.channelId.equals(channelId)))
          .get()
          .then((rows) => rows.map((r) => r.messageId).toList());

      if (messageIds.isNotEmpty) {
        await (_db.delete(_db.localMessageReactions)
              ..where((r) => r.messageId.isIn(messageIds)))
            .go();
        await (_db.delete(_db.localMessageAttachments)
              ..where((a) => a.messageId.isIn(messageIds)))
            .go();
      }

      await (_db.delete(_db.localMessages)
            ..where((m) => m.channelId.equals(channelId)))
          .go();
      await (_db.delete(_db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId)))
          .go();
      await (_db.delete(_db.channelSyncStates)
            ..where((s) => s.channelId.equals(channelId)))
          .go();
      await (_db.delete(_db.channelDrafts)
            ..where((d) => d.channelId.equals(channelId)))
          .go();
      await (_db.delete(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .go();
    });
  }

  Future<bool> updateChannelSummaryFromRealtime({
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

    return _db.transaction(() async {
      final current = await (_db.select(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .getSingleOrNull();
      if (current == null) return false;

      final newSeq = current.lastMessageSeq == null
          ? lastMessageSeq
          : (current.lastMessageSeq! > lastMessageSeq
              ? current.lastMessageSeq!
              : lastMessageSeq);

      var newUnread = current.unreadCount;
      if (unreadCount != null) {
        newUnread = unreadCount;
      } else if (senderId != null &&
          currentUserId != null &&
          senderId != currentUserId &&
          (countsAsUnread ?? true) &&
          lastMessageSeq > (current.lastMessageSeq ?? 0)) {
        newUnread++;
      }

      await (_db.update(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .write(
        LocalChannelsCompanion(
          lastMessageSeq: Value(newSeq),
          lastMessageAt: Value(lastMessageAt),
          lastMessagePreview:
              bodyPreview == null ? const Value.absent() : Value(bodyPreview),
          lastMessageSenderId:
              senderId == null ? const Value.absent() : Value(senderId),
          lastMessageFromMe: senderId != null && currentUserId != null
              ? Value(senderId == currentUserId)
              : const Value.absent(),
          unreadCount: Value(newUnread),
          localUpdatedAt: Value(now),
        ),
      );

      return true;
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Message synchronization / optimistic mutation
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> upsertMessagesFromDto(
    List<ChatMessageDto> dtos,
    String currentUserId,
  ) async {
    if (dtos.isEmpty) return;

    // Do not open another transaction here. Catch-up methods call this from an
    // outer transaction so that message rows and sync cursors commit together.
    // Realtime callers still get one atomic Drift batch.
    final ids = dtos.map((dto) => dto.messageId).toList();
    final existingRows = await (_db.select(_db.localMessages)
          ..where((m) => m.messageId.isIn(ids)))
        .get();
    final existingById = {
      for (final row in existingRows) row.messageId: row,
    };

    await _db.batch((batch) {
      for (final dto in dtos) {
        final existing = existingById[dto.messageId];
        final localCreatedAt =
            existing?.localCreatedAt ?? DateTime.now().toUtc();

        batch.insert(
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
            updatedAt: Value(
              dto.updatedAt == null ? null : DateTime.parse(dto.updatedAt!),
            ),
            editedAt: Value(
              dto.editedAt == null ? null : DateTime.parse(dto.editedAt!),
            ),
            deletedAt: Value(
              dto.deletedAt == null ? null : DateTime.parse(dto.deletedAt!),
            ),
            localCreatedAt: localCreatedAt,
            syncStatus: const Value('sent'),
          ),
          mode: InsertMode.insertOrReplace,
        );

        // Do NOT delete attachment rows first. localPath / thumbnailLocalPath
        // are device-only cache fields and survive these on-conflict updates.
        for (final attachment in dto.attachments) {
          batch.insert(
            _db.localMessageAttachments,
            LocalMessageAttachmentsCompanion.insert(
              attachmentId: attachment.attachmentId,
              messageId: attachment.messageId,
              storagePath: Value(attachment.storagePath),
              mimeType: attachment.mimeType,
              fileName: Value(attachment.fileName),
              sizeBytes: Value(attachment.sizeBytes),
              width: Value(attachment.width),
              height: Value(attachment.height),
              durationMs: Value(attachment.durationMs),
              uploadStatus: const Value('uploaded'),
            ),
            onConflict: DoUpdate(
              (_) => LocalMessageAttachmentsCompanion(
                storagePath: Value(attachment.storagePath),
                mimeType: Value(attachment.mimeType),
                fileName: Value(attachment.fileName),
                sizeBytes: Value(attachment.sizeBytes),
                width: Value(attachment.width),
                height: Value(attachment.height),
                durationMs: Value(attachment.durationMs),
                uploadStatus: const Value('uploaded'),
                uploadError: const Value(null),
              ),
            ),
          );
        }

        // Reactions have no device-local fields, so the server snapshot can
        // replace them wholesale for this message.
        batch.deleteWhere(
          _db.localMessageReactions,
          (r) => r.messageId.equals(dto.messageId),
        );
        for (final reaction in dto.reactions) {
          batch.insert(
            _db.localMessageReactions,
            LocalMessageReactionsCompanion.insert(
              messageId: reaction.messageId,
              userId: reaction.userId,
              reaction: reaction.reaction,
              createdAt: DateTime.parse(reaction.createdAt),
              updatedAt: DateTime.parse(reaction.createdAt),
              removedAt: Value(
                reaction.removedAt == null
                    ? null
                    : DateTime.parse(reaction.removedAt!),
              ),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

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
        .write(
      LocalMessagesCompanion(
        syncStatus: Value(syncStatus),
        messageSeq: messageSeq == null ? const Value.absent() : Value(messageSeq),
        version: version == null ? const Value.absent() : Value(version),
        sendErrorCode: Value(sendErrorCode),
        sendErrorMessage: Value(sendErrorMessage),
      ),
    );
  }

  Future<LocalMessageRow?> getMessage(String messageId) =>
      (_db.select(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .getSingleOrNull();

  Future<void> softDeleteMessageLocally(
    String messageId, {
    int? version,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.localMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(
      LocalMessagesCompanion(
        deletedAt: Value(now),
        body: const Value('This message was deleted'),
        updatedAt: Value(now),
        version: version == null ? const Value.absent() : Value(version),
      ),
    );
  }

  /// Hard-cancels a local optimistic send that has never received a server
  /// sequence. It removes the pending send operation and the local bubble
  /// rather than creating a meaningless delete tombstone.
  Future<List<String>> cancelPendingOutgoingMessage({
    required String messageId,
    required String currentUserId,
  }) async {
    final now = DateTime.now().toUtc();

    return _db.transaction(() async {
      final existing = await getMessage(messageId);
      if (existing == null) return const <String>[];

      if (existing.messageSeq != null) {
        throw StateError('Server-confirmed messages cannot be hard-cancelled.');
      }
      if (existing.syncStatus == 'sending') {
        throw StateError('Message send is already in flight.');
      }

      final attachments = await getAttachmentsForMessage(messageId);
      final localPaths = attachments
          .map((a) => a.localPath)
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toList();

      await (_db.delete(_db.outboxOperations)
            ..where(
              (o) =>
                  o.entityId.equals(messageId) &
                  o.operationType.equals('send_message') &
                  o.status.isIn(const ['pending', 'retry_wait', 'failed']),
            ))
          .go();
      await (_db.delete(_db.localMessageReactions)
            ..where((r) => r.messageId.equals(messageId)))
          .go();
      await (_db.delete(_db.localMessageAttachments)
            ..where((a) => a.messageId.equals(messageId)))
          .go();
      await (_db.delete(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .go();

      final remaining = await (_db.select(_db.localMessages)
            ..where((m) => m.channelId.equals(existing.channelId)))
          .get();

      LocalMessageRow? latest;
      DateTime? latestTime;
      for (final row in remaining) {
        final time = row.createdAt ?? row.localCreatedAt;
        if (latest == null || latestTime == null || time.isAfter(latestTime)) {
          latest = row;
          latestTime = time;
        }
      }

      await (_db.update(_db.localChannels)
            ..where((c) => c.channelId.equals(existing.channelId)))
          .write(
        LocalChannelsCompanion(
          lastMessagePreview: Value(
            latest == null
                ? null
                : latest.deletedAt != null
                    ? 'This message was deleted'
                    : latest.body,
          ),
          lastMessageAt: Value(
            latest == null ? null : latest.createdAt ?? latest.localCreatedAt,
          ),
          lastMessageSenderId: Value(latest?.senderId),
          lastMessageFromMe:
              Value(latest != null && latest.senderId == currentUserId),
          localUpdatedAt: Value(now),
        ),
      );

      return localPaths;
    });
  }

  Future<LocalMessageRow?> optimisticEditMessage({
    required String messageId,
    required String newBody,
    required OutboxOperationsCompanion operation,
  }) {
    return _db.transaction(() async {
      final existing = await getMessage(messageId);
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
      await _db.into(_db.outboxOperations).insert(operation);
      return getMessage(messageId);
    });
  }

  Future<LocalMessageRow?> optimisticDeleteMessage({
    required String messageId,
    required OutboxOperationsCompanion operation,
  }) {
    return _db.transaction(() async {
      final existing = await getMessage(messageId);
      if (existing == null) return null;

      final now = DateTime.now().toUtc();
      await (_db.update(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .write(
        LocalMessagesCompanion(
          deletedAt: Value(now),
          body: const Value('This message was deleted'),
          updatedAt: Value(now),
        ),
      );
      await _db.into(_db.outboxOperations).insert(operation);
      return getMessage(messageId);
    });
  }

  Future<void> rollbackOptimisticEdit({
    required String messageId,
    required String? previousBody,
    required DateTime? previousEditedAt,
    required DateTime? previousUpdatedAt,
  }) async {
    await (_db.update(_db.localMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(
      LocalMessagesCompanion(
        body: Value(previousBody),
        editedAt: Value(previousEditedAt),
        updatedAt: Value(previousUpdatedAt),
      ),
    );
  }

  Future<void> rollbackOptimisticDelete({
    required String messageId,
    required String? previousBody,
    required DateTime? previousDeletedAt,
    required DateTime? previousUpdatedAt,
  }) async {
    await (_db.update(_db.localMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(
      LocalMessagesCompanion(
        body: Value(previousBody),
        deletedAt: Value(previousDeletedAt),
        updatedAt: Value(previousUpdatedAt),
      ),
    );
  }

  Future<void> retryMessage(String messageId) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      await (_db.update(_db.localMessages)
            ..where((m) => m.messageId.equals(messageId)))
          .write(
        const LocalMessagesCompanion(
          syncStatus: Value('pending'),
          sendErrorCode: Value(null),
          sendErrorMessage: Value(null),
        ),
      );
      await (_db.update(_db.outboxOperations)
            ..where(
              (o) => o.entityId.equals(messageId) &
                  o.operationType.equals('send_message'),
            ))
          .write(
        OutboxOperationsCompanion(
          status: const Value('pending'),
          attemptCount: const Value(0),
          nextAttemptAt: const Value(null),
          lastErrorCode: const Value(null),
          lastErrorMessage: const Value(null),
          updatedAt: Value(now),
        ),
      );
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sync cursors
  // ──────────────────────────────────────────────────────────────────────────

  Future<ChannelSyncStateRow?> getChannelSyncState(String channelId) =>
      (_db.select(_db.channelSyncStates)
            ..where((s) => s.channelId.equals(channelId)))
          .getSingleOrNull();

  Future<void> markChannelSyncStarted(String channelId) async {
    final now = DateTime.now().toUtc();
    await _db.into(_db.channelSyncStates).insert(
          ChannelSyncStatesCompanion.insert(
            channelId: channelId,
            syncStatus: const Value('syncing'),
            lastFullSyncAt: Value(now),
          ),
          onConflict: DoUpdate(
            (_) => const ChannelSyncStatesCompanion(
              syncStatus: Value('syncing'),
              lastSyncError: Value(null),
            ),
          ),
        );
  }

  Future<void> markChannelSyncSucceeded(
    String channelId, {
    required int newestSeq,
    int? newestChangeSeq,
    int? oldestSeq,
    bool? hasMore,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await getChannelSyncState(channelId);

    final currentNewest = existing?.newestSyncedMessageSeq ?? 0;
    final updatedNewest = newestSeq > currentNewest ? newestSeq : currentNewest;

    final currentChange = existing?.newestAppliedChangeSeq ?? 0;
    final updatedChange = newestChangeSeq != null && newestChangeSeq > currentChange
        ? newestChangeSeq
        : existing?.newestAppliedChangeSeq;

    final currentOldest = existing?.oldestCachedMessageSeq;
    final updatedOldest = oldestSeq == null
        ? currentOldest
        : currentOldest == null
            ? oldestSeq
            : (oldestSeq < currentOldest ? oldestSeq : currentOldest);

    await _db.into(_db.channelSyncStates).insert(
          ChannelSyncStatesCompanion.insert(
            channelId: channelId,
            newestSyncedMessageSeq: Value(updatedNewest),
            newestAppliedChangeSeq: Value(updatedChange),
            oldestCachedMessageSeq: Value(updatedOldest),
            hasMoreHistory: Value(hasMore ?? existing?.hasMoreHistory ?? true),
            lastFullSyncAt: Value(now),
            syncStatus: const Value('idle'),
            lastSyncError: const Value(null),
          ),
          onConflict: DoUpdate(
            (_) => ChannelSyncStatesCompanion(
              newestSyncedMessageSeq: Value(updatedNewest),
              newestAppliedChangeSeq: Value(updatedChange),
              oldestCachedMessageSeq: Value(updatedOldest),
              hasMoreHistory: Value(hasMore ?? existing?.hasMoreHistory ?? true),
              lastFullSyncAt: Value(now),
              syncStatus: const Value('idle'),
              lastSyncError: const Value(null),
            ),
          ),
        );
  }

  Future<void> updateNewestAppliedChangeSeq(
    String channelId,
    int changeSeq,
  ) async {
    final existing = await getChannelSyncState(channelId);
    if (changeSeq <= (existing?.newestAppliedChangeSeq ?? 0)) return;

    await _db.into(_db.channelSyncStates).insert(
          ChannelSyncStatesCompanion.insert(
            channelId: channelId,
            newestAppliedChangeSeq: Value(changeSeq),
          ),
          onConflict: DoUpdate(
            (_) => ChannelSyncStatesCompanion(
              newestAppliedChangeSeq: Value(changeSeq),
            ),
          ),
        );
  }

  Future<void> markChannelSyncFailed(String channelId, Object error) async {
    final existing = await getChannelSyncState(channelId);
    if (existing == null) {
      await _db.into(_db.channelSyncStates).insert(
            ChannelSyncStatesCompanion.insert(
              channelId: channelId,
              syncStatus: const Value('failed'),
              lastSyncError: Value(error.toString()),
            ),
          );
      return;
    }

    await (_db.update(_db.channelSyncStates)
          ..where((s) => s.channelId.equals(channelId)))
        .write(
      ChannelSyncStatesCompanion(
        syncStatus: const Value('failed'),
        lastSyncError: Value(error.toString()),
      ),
    );
  }

  Future<void> commitMessagesAndAdvanceCursor({
    required String channelId,
    required List<ChatMessageDto> messages,
    required String currentUserId,
    required int newestSeq,
    int? oldestSeq,
    bool? hasMore,
  }) {
    return _db.transaction(() async {
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

  Future<void> commitOlderMessagesAndUpdateCursor({
    required String channelId,
    required List<ChatMessageDto> messages,
    required String currentUserId,
    required int oldestSeq,
    required bool hasMore,
  }) {
    return _db.transaction(() async {
      if (messages.isNotEmpty) {
        await upsertMessagesFromDto(messages, currentUserId);
      }
      final existing = await getChannelSyncState(channelId);
      final currentOldest = existing?.oldestCachedMessageSeq;
      final updatedOldest = currentOldest != null && currentOldest < oldestSeq
          ? currentOldest
          : oldestSeq;

      await _db.into(_db.channelSyncStates).insert(
            ChannelSyncStatesCompanion.insert(
              channelId: channelId,
              oldestCachedMessageSeq: Value(updatedOldest),
              hasMoreHistory: Value(hasMore),
              syncStatus: const Value('idle'),
            ),
            onConflict: DoUpdate(
              (_) => ChannelSyncStatesCompanion(
                oldestCachedMessageSeq: Value(updatedOldest),
                hasMoreHistory: Value(hasMore),
                syncStatus: const Value('idle'),
              ),
            ),
          );
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Reactions / attachments / members
  // ──────────────────────────────────────────────────────────────────────────

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

  Future<LocalMessageReactionRow?> getReaction({
    required String messageId,
    required String userId,
    required String reaction,
  }) =>
      (_db.select(_db.localMessageReactions)
            ..where(
              (r) =>
                  r.messageId.equals(messageId) &
                  r.userId.equals(userId) &
                  r.reaction.equals(reaction),
            ))
          .getSingleOrNull();

  Future<void> updateAttachmentStoragePath(
    String attachmentId, {
    required String storagePath,
    required String uploadStatus,
  }) async {
    await (_db.update(_db.localMessageAttachments)
          ..where((a) => a.attachmentId.equals(attachmentId)))
        .write(
      LocalMessageAttachmentsCompanion(
        storagePath: Value(storagePath),
        uploadStatus: Value(uploadStatus),
      ),
    );
  }

  Future<void> updateAttachmentUploadStatus(
    String attachmentId, {
    required String uploadStatus,
    String? uploadError,
  }) async {
    await (_db.update(_db.localMessageAttachments)
          ..where((a) => a.attachmentId.equals(attachmentId)))
        .write(
      LocalMessageAttachmentsCompanion(
        uploadStatus: Value(uploadStatus),
        uploadError: Value(uploadError),
      ),
    );
  }

  Future<void> clearAttachmentLocalPath(String attachmentId) async {
    await (_db.update(_db.localMessageAttachments)
          ..where((a) => a.attachmentId.equals(attachmentId)))
        .write(
      const LocalMessageAttachmentsCompanion(localPath: Value(null)),
    );
  }

  Future<List<LocalMessageAttachmentRow>> getAttachmentsForMessage(
    String messageId,
  ) =>
      (_db.select(_db.localMessageAttachments)
            ..where((a) => a.messageId.equals(messageId)))
          .get();

  Future<void> updateMemberHorizons(
    String channelId,
    String userId, {
    int? readSeq,
    int? deliveredSeq,
  }) async {
    final now = DateTime.now().toUtc();
    final effectiveDelivered = readSeq != null && deliveredSeq != null
        ? (readSeq > deliveredSeq ? readSeq : deliveredSeq)
        : (deliveredSeq ?? readSeq);

    final existing = await (_db.select(_db.localChannelMembers)
          ..where(
            (m) => m.channelId.equals(channelId) & m.userId.equals(userId),
          ))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.localChannelMembers).insert(
            LocalChannelMembersCompanion.insert(
              channelId: channelId,
              userId: userId,
              lastReadMessageSeq: Value(readSeq),
              lastReadAt: Value(readSeq == null ? null : now),
              lastDeliveredMessageSeq: Value(effectiveDelivered),
              lastDeliveredAt: Value(effectiveDelivered == null ? null : now),
              serverUpdatedAt: now,
            ),
          );
    } else {
      final currentRead = existing.lastReadMessageSeq ?? 0;
      final currentDelivered = existing.lastDeliveredMessageSeq ?? 0;
      final newRead = readSeq != null && readSeq > currentRead ? readSeq : null;
      final newDelivered = effectiveDelivered != null &&
              effectiveDelivered > currentDelivered
          ? effectiveDelivered
          : (newRead != null && newRead > currentDelivered ? newRead : null);

      await (_db.update(_db.localChannelMembers)
            ..where(
              (m) => m.channelId.equals(channelId) & m.userId.equals(userId),
            ))
          .write(
        LocalChannelMembersCompanion(
          lastReadMessageSeq:
              newRead == null ? const Value.absent() : Value(newRead),
          lastReadAt: newRead == null ? const Value.absent() : Value(now),
          lastDeliveredMessageSeq:
              newDelivered == null ? const Value.absent() : Value(newDelivered),
          lastDeliveredAt:
              newDelivered == null ? const Value.absent() : Value(now),
        ),
      );
    }

    if (readSeq != null) {
      final channel = await (_db.select(_db.localChannels)
            ..where((c) => c.channelId.equals(channelId)))
          .getSingleOrNull();
      if (channel != null &&
          (channel.lastMessageSeq == null || readSeq >= channel.lastMessageSeq!)) {
        await (_db.update(_db.localChannels)
              ..where((c) => c.channelId.equals(channelId)))
            .write(const LocalChannelsCompanion(unreadCount: Value(0)));
      }
    }
  }

  Future<void> updateMemberStatus(
    String channelId,
    String userId,
    String status,
  ) async {
    await (_db.update(_db.localChannelMembers)
          ..where(
            (m) => m.channelId.equals(channelId) & m.userId.equals(userId),
          ))
        .write(LocalChannelMembersCompanion(status: Value(status)));
  }


  /// Atomically changes the current user's local membership state and queues
  /// the matching server command. Accept/decline must never be split into two
  /// independent writes, otherwise a process kill can make local UI disagree
  /// permanently with the durable Outbox intent.
  Future<void> optimisticMemberStatusChange({
    required String channelId,
    required String userId,
    required String status,
    required OutboxOperationsCompanion operation,
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.localChannelMembers)
            ..where(
              (m) => m.channelId.equals(channelId) & m.userId.equals(userId),
            ))
          .write(LocalChannelMembersCompanion(status: Value(status)));
      await _db.into(_db.outboxOperations).insert(operation);
    });
  }


  /// Returns true only when [userId] is an accepted/active member of the
  /// channel. Pending DM request recipients deliberately return false so
  /// background hydration cannot emit ordinary chat delivery receipts before
  /// acceptance.
  Future<bool> isActiveMembership(String channelId, String userId) async {
    final row = await (_db.select(_db.localChannelMembers)
          ..where(
            (m) =>
                m.channelId.equals(channelId) &
                m.userId.equals(userId),
          ))
        .getSingleOrNull();
    return row?.status == 'active';
  }

  Future<int?> getLatestMessageSeq(String channelId) async {
    final channel = await (_db.select(_db.localChannels)
          ..where((c) => c.channelId.equals(channelId)))
        .getSingleOrNull();
    final message = await (_db.select(_db.localMessages)
          ..where(
            (m) => m.channelId.equals(channelId) & m.messageSeq.isNotNull(),
          )
          ..orderBy([(m) => OrderingTerm.desc(m.messageSeq)])
          ..limit(1))
        .getSingleOrNull();

    final a = channel?.lastMessageSeq;
    final b = message?.messageSeq;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Outbox
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> enqueueOutgoingMessage({
    required LocalMessagesCompanion message,
    required OutboxOperationsCompanion operation,
    List<LocalMessageAttachmentsCompanion>? attachments,
  }) async {
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      await _db.into(_db.localMessages).insert(message);
      for (final attachment in attachments ?? const <LocalMessageAttachmentsCompanion>[]) {
        await _db.into(_db.localMessageAttachments).insert(attachment);
      }
      await _db.into(_db.outboxOperations).insert(operation);

      await (_db.update(_db.localChannels)
            ..where((c) => c.channelId.equals(message.channelId.value)))
          .write(
        LocalChannelsCompanion(
          localUpdatedAt: Value(now),
          lastMessagePreview:
              message.body.present ? message.body : const Value.absent(),
          lastMessageSenderId:
              message.senderId.present ? message.senderId : const Value.absent(),
          lastMessageFromMe: const Value(true),
          lastMessageAt: Value(message.createdAt.value ?? now),
        ),
      );
    });
  }

  Future<void> enqueueOperation(OutboxOperationsCompanion op) async {
    await _db.transaction(() async {
      if (op.coalesceKey.present && op.coalesceKey.value != null) {
        final key = op.coalesceKey.value!;
        final isReceipt = key.startsWith('read:') || key.startsWith('delivered:');

        if (isReceipt) {
          final existing = await (_db.select(_db.outboxOperations)
                ..where(
                  (o) =>
                      o.coalesceKey.equals(key) &
                      o.status.isIn(const ['pending', 'retry_wait']),
                ))
              .getSingleOrNull();

          if (existing != null) {
            try {
              final oldPayload =
                  jsonDecode(existing.payloadJson) as Map<String, dynamic>;
              final newPayload =
                  jsonDecode(op.payloadJson.value) as Map<String, dynamic>;
              final oldSeq = (oldPayload['through_seq'] as num?)?.toInt() ?? 0;
              final newSeq = (newPayload['through_seq'] as num?)?.toInt() ?? 0;
              if (oldSeq >= newSeq) return;
            } catch (_) {}
          }
        }

        await (_db.delete(_db.outboxOperations)
              ..where(
                (o) =>
                    o.coalesceKey.equals(key) &
                    o.status.isIn(const ['pending', 'retry_wait']),
              ))
            .go();
      }

      await _db.into(_db.outboxOperations).insert(op);
    });
  }

  Future<List<OutboxOperationRow>> getPendingOperations({
    required String ownerUserId,
    String? channelId,
  }) {
    final now = DateTime.now().toUtc();
    final query = _db.select(_db.outboxOperations)
      ..where((o) {
        Expression<bool> predicate = o.ownerUserId.equals(ownerUserId) &
            (o.status.equals('pending') |
                (o.status.equals('retry_wait') &
                    (o.nextAttemptAt.isNull() |
                        o.nextAttemptAt.isSmallerOrEqualValue(now))));
        if (channelId != null) {
          predicate = predicate & o.channelId.equals(channelId);
        }
        return predicate;
      })
      ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]);
    return query.get();
  }

  Future<OutboxOperationRow?> getOutboxOperation(String operationId) =>
      (_db.select(_db.outboxOperations)
            ..where((o) => o.operationId.equals(operationId)))
          .getSingleOrNull();

  Future<DateTime?> getNextOutboxRetryAt(String ownerUserId) async {
    final row = await (_db.select(_db.outboxOperations)
          ..where(
            (o) =>
                o.ownerUserId.equals(ownerUserId) &
                o.status.equals('retry_wait') &
                o.nextAttemptAt.isNotNull(),
          )
          ..orderBy([(o) => OrderingTerm.asc(o.nextAttemptAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.nextAttemptAt;
  }

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
        .write(
      OutboxOperationsCompanion(
        status: Value(status),
        attemptCount:
            attemptCount == null ? const Value.absent() : Value(attemptCount),
        nextAttemptAt: Value(nextAttemptAt),
        lastErrorCode: Value(lastErrorCode),
        lastErrorMessage: Value(lastErrorMessage),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> deleteOutboxOperation(String operationId) async {
    await (_db.delete(_db.outboxOperations)
          ..where((o) => o.operationId.equals(operationId)))
        .go();
  }

  Future<int> recoverStaleProcessingOperations({
    Duration lease = const Duration(minutes: 2),
  }) {
    final cutoff = DateTime.now().toUtc().subtract(lease);
    return (_db.update(_db.outboxOperations)
          ..where(
            (o) =>
                o.status.equals('processing') &
                o.updatedAt.isSmallerThanValue(cutoff),
          ))
        .write(
      const OutboxOperationsCompanion(
        status: Value('pending'),
        nextAttemptAt: Value(null),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Drafts
  // ──────────────────────────────────────────────────────────────────────────

  Future<ChatDraft?> readDraftState(String channelId) async {
    final row = await (_db.select(_db.channelDrafts)
          ..where((d) => d.channelId.equals(channelId)))
        .getSingleOrNull();
    if (row == null) return null;
    return ChatDraft(body: row.body, replyToMessageId: row.replyToMessageId);
  }

  Future<void> saveDraftState(String channelId, ChatDraft draft) async {
    await _db.into(_db.channelDrafts).insertOnConflictUpdate(
          ChannelDraftsCompanion.insert(
            channelId: channelId,
            body: draft.body,
            replyToMessageId: Value(draft.replyToMessageId),
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
