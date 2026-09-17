import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat.dart';
import '../entities/message.dart';
import '../value_objects/message_body.dart';

/// Online-only contract for the messages feature.
///
/// Reads (`watchMyChats`, `watchMessages`) return live streams backed by
/// Supabase broadcast channels; errors propagate as stream errors wrapped in
/// [FailureWrapper] per CLAUDE.md Rule 2.
///
/// Writes (`sendMessage`, `markRead`) return `Either<Failure, T>` directly.
abstract class MessagesRepository {
  /// Streams the current user's chats, sorted by `last_message_at` desc.
  Stream<List<Chat>> watchMyChats();

  /// Forces authoritative synchronization of the user's inbox list from Supabase into Drift.
  Future<Either<Failure, Unit>> refreshInbox();

  /// Streams the messages in a chat, sorted by `created_at` asc. Backed by
  /// an initial fetch of the LATEST 50 messages + a Supabase broadcast
  /// subscription on `chat:<chat_id>:messages` (event `new_message`, fired
  /// by the `broadcast_new_message` trigger in migration 0802 on every
  /// insert). Older messages are loaded on demand via [loadOlderMessages]
  /// (ticket #35).
  Stream<List<Message>> watchMessages(ChatId chatId);

  /// Fetch the next page of older messages for [chatId] (keyset pagination
  /// on `(created_at, message_id)` against the oldest currently loaded
  /// message). The new messages are prepended to the in-memory list and
  /// emitted through the [watchMessages] stream — no separate return value
  /// for the list itself.
  ///
  /// Returns the number of older messages loaded:
  ///   - `0` means no more history to load (end-of-thread).
  ///   - A value `< 50` (the page size) also means end-of-thread reached.
  ///   - A value `== 50` means another page may exist.
  ///
  /// Safe to call without checking state — the implementation no-ops when
  /// a load is already in flight or `hasMore` is exhausted.
  Future<Either<Failure, int>> loadOlderMessages(ChatId chatId);

  /// Inserts a new message authored by the current user. Server-side
  /// triggers handle the realtime broadcast and the push fan-out — this
  /// returns once the row is committed.
  Future<Either<Failure, Message>> sendMessage(
    ChatId chatId,
    MessageBody body, {
    String? replyToId,
  });

  /// Uploads an image and sends an image message.
  Future<Either<Failure, Message>> sendImageMessage(
    ChatId chatId, {
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  });

  /// Soft deletes a message for the user.
  Future<Either<Failure, Unit>> deleteMessage(ChatId chatId, MessageId messageId);

  /// Stamps `chat_members.last_read_at = now()` and advances read horizon
  /// for the current user in this chat, so unread counts re-emit as 0.
  Future<Either<Failure, Unit>> markRead(ChatId chatId, {int? throughMessageSeq});

  /// Resolves or creates a 1-on-1 direct message conversation with [targetUserId].
  Future<Either<Failure, ChatId>> getOrCreateDmChat(String targetUserId);

  /// Accepts an incoming DM message request.
  Future<Either<Failure, Unit>> acceptDmRequest(ChatId chatId);

  /// Declines / archives an incoming DM message request.
  Future<Either<Failure, Unit>> declineDmRequest(ChatId chatId);


  // ─── Drafts (local-only; ticket #23) ──────────────────────────────────
  //
  // Compose-state persistence so a killed app can restore a half-typed
  // message. Backed by drift (`message_drafts`); never touches the
  // network. No `Either` wrapping — drafts are best-effort and a lost
  // draft is a minor annoyance, not an error to surface.

  /// Read the persisted composer text for a chat, or null when none exists.
  /// Raw `String` — drafts ARE partial-by-definition; `MessageBody` would
  /// reject valid draft states (empty / mid-word).
  Future<String?> readDraft(ChatId chatId);

  /// Persist the composer text for a chat. Caller debounces writes so a
  /// burst of keystrokes doesn't hammer the disk. Raw `String` is
  /// INTENTIONAL — drafts may be partial/invalid; this is not an oversight.
  /// Do NOT apply `MessageBody.create` here or draft restore breaks.
  Future<void> saveDraft(ChatId chatId, String body);

  /// Drop the draft for a chat — typically after a successful send.
  Future<void> deleteDraft(ChatId chatId);

  /// Streams typing indicator state for [chatId] via real-time presence.
  Stream<bool> watchTyping(ChatId chatId);

  /// Broadcasts typing activity for the current user in [chatId].
  Future<void> setTyping(ChatId chatId, bool isTyping);

  /// Streams the set of user IDs currently present (online) in [chatId] via Ably.
  Stream<Set<String>> watchPresence(ChatId chatId);
}

