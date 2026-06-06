import '../entities/chat.dart';

/// Online-only read contract for the chat inbox.
///
/// Write paths and per-thread message streams live in part 2 of the rollout
/// (ticket #7); this contract intentionally exposes only the list view.
abstract class MessagesRepository {
  /// Streams the current user's chats, sorted by `last_message_at` desc,
  /// nulls last. Backed by an initial fetch + a Supabase broadcast
  /// subscription on `user:<my_user_id>:notifications` (the `chat_updated`
  /// event fires from the `broadcast_new_message` trigger on every message
  /// insert, see migration 0802).
  ///
  /// Errors propagate as stream errors per CLAUDE.md Rule 2; consumers let
  /// AsyncValue / AsyncError handle them.
  Stream<List<Chat>> watchMyChats();
}
