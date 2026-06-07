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

  /// Streams the messages in a chat, sorted by `created_at` asc. Backed by
  /// an initial fetch + a Supabase broadcast subscription on
  /// `chat:<chat_id>:messages` (event `new_message`, fired by the
  /// `broadcast_new_message` trigger in migration 0802 on every insert).
  Stream<List<Message>> watchMessages(ChatId chatId);

  /// Inserts a new message authored by the current user. Server-side
  /// triggers handle the realtime broadcast and the push fan-out — this
  /// returns once the row is committed.
  Future<Either<Failure, Message>> sendMessage(ChatId chatId, MessageBody body);

  /// Stamps `chat_members.last_read_at = now()` for the current user in this
  /// chat, so unread counts re-emit as 0.
  Future<Either<Failure, Unit>> markRead(ChatId chatId);

  // ─── Drafts (local-only; ticket #23) ──────────────────────────────────
  //
  // Compose-state persistence so a killed app can restore a half-typed
  // message. Backed by drift (`message_drafts`); never touches the
  // network. No `Either` wrapping — drafts are best-effort and a lost
  // draft is a minor annoyance, not an error to surface.

  /// Read the persisted composer text for a chat, or null when none exists.
  Future<String?> readDraft(ChatId chatId);

  /// Persist the composer text for a chat. Caller debounces writes so a
  /// burst of keystrokes doesn't hammer the disk.
  Future<void> saveDraft(ChatId chatId, String body);

  /// Drop the draft for a chat — typically after a successful send.
  Future<void> deleteDraft(ChatId chatId);
}
