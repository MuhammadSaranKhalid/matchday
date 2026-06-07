import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../teams/domain/entities/team.dart' show TeamId;
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';

/// Drift-backed read-through cache + drafts store for the messages feature.
///
/// Per CLAUDE.md §5.2, the local data source exposes Domain ENTITIES to the
/// repository (not drift row types). Mapping is handled by the private
/// `_chatFromRow` / `_messageFromRow` helpers at the boundary.
///
/// The store is an OPTIMISATION, not a source of truth — Supabase remains
/// authoritative. The repository pattern is "emit cache → emit network →
/// write-through on every network value." Write failures here are
/// fire-and-forget at the caller (logged, not surfaced).
class MessagesLocalDataSource {
  MessagesLocalDataSource(this._db);
  final AppDatabase _db;

  // ─── Chats ──────────────────────────────────────────────────────────────

  /// All cached chats, sorted by `last_message_at` desc nulls last to match
  /// the inbox query in the `list-my-chats` edge function.
  Future<List<Chat>> listChats() async {
    final rows = await (_db.select(_db.messagesChats)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.lastMessageAt,
                  mode: OrderingMode.desc,
                  nulls: NullsOrder.last,
                ),
          ]))
        .get();
    return rows.map(_chatFromRow).toList(growable: false);
  }

  /// Upsert a single chat. Used by the realtime `chat_updated` patcher.
  Future<void> upsertChat(Chat chat) async {
    await _db.into(_db.messagesChats).insertOnConflictUpdate(_chatRow(chat));
  }

  /// Bulk upsert. Used after a full network fetch returns the inbox.
  Future<void> upsertChats(List<Chat> chats) async {
    if (chats.isEmpty) return;
    await _db.batch((b) {
      for (final c in chats) {
        b.insert(
          _db.messagesChats,
          _chatRow(c),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Wipe and bulk-insert. Used on channel re-subscribe (reconnect sync
  /// point) so chats that no longer apply to the user are dropped cleanly.
  Future<void> replaceChats(List<Chat> chats) async {
    await _db.transaction(() async {
      await _db.delete(_db.messagesChats).go();
      if (chats.isEmpty) return;
      await _db.batch((b) {
        for (final c in chats) {
          b.insert(_db.messagesChats, _chatRow(c));
        }
      });
    });
  }

  // ─── Messages ───────────────────────────────────────────────────────────

  /// Cached non-deleted messages in a chat, oldest first. Soft-deleted rows
  /// stay in the table (the column tracks them) but are filtered here so the
  /// repository never sees them.
  Future<List<Message>> listMessages(String chatId) async {
    final rows = await (_db.select(_db.messagesMessages)
          ..where((t) =>
              t.chatId.equals(chatId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_messageFromRow).toList(growable: false);
  }

  Future<void> upsertMessage(Message msg) async {
    await _db
        .into(_db.messagesMessages)
        .insertOnConflictUpdate(_messageRow(msg));
  }

  Future<void> upsertMessages(List<Message> msgs) async {
    if (msgs.isEmpty) return;
    await _db.batch((b) {
      for (final m in msgs) {
        b.insert(
          _db.messagesMessages,
          _messageRow(m),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Wipe and bulk-insert for one chat. Used on per-thread reconnect.
  Future<void> replaceMessages(String chatId, List<Message> msgs) async {
    await _db.transaction(() async {
      await (_db.delete(_db.messagesMessages)
            ..where((t) => t.chatId.equals(chatId)))
          .go();
      if (msgs.isEmpty) return;
      await _db.batch((b) {
        for (final m in msgs) {
          b.insert(_db.messagesMessages, _messageRow(m));
        }
      });
    });
  }

  // ─── Drafts ─────────────────────────────────────────────────────────────

  /// Read the persisted composer text for a chat, or null when no draft.
  Future<String?> readDraft(String chatId) async {
    final row = await (_db.select(_db.messagesDrafts)
          ..where((t) => t.chatId.equals(chatId)))
        .getSingleOrNull();
    return row?.body;
  }

  Future<void> saveDraft(String chatId, String body) async {
    await _db.into(_db.messagesDrafts).insertOnConflictUpdate(
          MessagesDraftsCompanion.insert(
            chatId: chatId,
            body: body,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> deleteDraft(String chatId) async {
    await (_db.delete(_db.messagesDrafts)
          ..where((t) => t.chatId.equals(chatId)))
        .go();
  }

  // ─── Mappers (drift row ↔ entity) ───────────────────────────────────────

  Chat _chatFromRow(MessagesChatRow r) => Chat(
        id: ChatId(r.chatId),
        kind: ChatKind.fromWire(r.type),
        name: r.teamName ?? '',
        teamId: r.teamId == null ? null : TeamId(r.teamId!),
        unreadCount: r.unreadCount,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        lastMessageAt: r.lastMessageAt,
        lastMessagePreview: r.lastMessageBody,
        lastMessageSenderId: r.lastMessageSenderId,
        lastMessageFromMe: r.lastMessageFromMe,
        teamLogoUrl: r.teamLogoUrl,
        teamLogoMonogram: r.teamLogoMonogram,
        teamPrimaryColorHex: r.teamPrimaryColorHex,
      );

  MessagesChatsCompanion _chatRow(Chat c) => MessagesChatsCompanion.insert(
        chatId: c.id.value,
        type: c.kind.wire,
        teamId: Value(c.teamId?.value),
        teamName: Value(c.name.isEmpty ? null : c.name),
        teamLogoUrl: Value(c.teamLogoUrl),
        teamLogoMonogram: Value(c.teamLogoMonogram),
        teamPrimaryColorHex: Value(c.teamPrimaryColorHex),
        lastMessageAt: Value(c.lastMessageAt),
        lastMessageBody: Value(c.lastMessagePreview),
        lastMessageSenderId: Value(c.lastMessageSenderId),
        lastMessageFromMe: Value(c.lastMessageFromMe),
        unreadCount: Value(c.unreadCount),
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        cachedAt: DateTime.now().toUtc(),
      );

  Message _messageFromRow(MessagesMessageRow r) => Message(
        id: MessageId(r.messageId),
        chatId: ChatId(r.chatId),
        senderId: r.senderId,
        senderDisplayName: r.senderDisplayName,
        body: r.body,
        createdAt: r.createdAt,
        editedAt: r.editedAt,
        deletedAt: r.deletedAt,
        fromMe: r.fromMe,
      );

  MessagesMessagesCompanion _messageRow(Message m) =>
      MessagesMessagesCompanion.insert(
        messageId: m.id.value,
        chatId: m.chatId.value,
        senderId: Value(m.senderId),
        senderDisplayName: Value(m.senderDisplayName),
        body: m.body,
        createdAt: m.createdAt,
        editedAt: Value(m.editedAt),
        deletedAt: Value(m.deletedAt),
        fromMe: Value(m.fromMe),
      );
}
