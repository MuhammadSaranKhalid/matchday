import 'package:drift/drift.dart';

/// Local-only persistence for in-progress multi-step wizards (onboarding,
/// team-create, match-setup). Lets a user resume a half-filled flow after
/// killing the app. Keyed by a caller-defined string (e.g.
/// `onboarding:<userId>`); [payload] is the wizard's JSON-encoded draft.
///
/// Wizard drafts are transient presentation state, not domain data — they
/// carry no `user_id`/`updated_at` LWW columns and are cleared on sign-out.
@DataClassName('WizardDraftRow')
class WizardDrafts extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─── Messages cache (read-through; ticket #23) ──────────────────────────────
//
// EXEMPTION from the online-only rule, scoped to MESSAGES ONLY. The cache
// makes inbox + thread cold-starts paint instantly and lets in-progress
// composer drafts survive app restarts. Writes still go to Supabase first;
// these tables are a read-through cache + a tiny drafts store. There is NO
// pending-ops queue, NO sync service, NO LWW. Sign-out wipes everything via
// AppDatabase.clear().
//
// Other features (teams / posts / matches / pavilion / profile) remain
// online-only. Promote this pattern only if a feature genuinely benefits.

/// Inbox row mirror. Denormalised — the columns track the shape returned by
/// the `list-my-chats` edge function so a single SELECT can paint the inbox
/// without joins.
@DataClassName('MessagesChatRow')
class MessagesChats extends Table {
  TextColumn get chatId => text()();
  TextColumn get type => text()();
  TextColumn get teamId => text().nullable()();
  TextColumn get teamName => text().nullable()();
  TextColumn get teamLogoUrl => text().nullable()();
  TextColumn get teamLogoMonogram => text().nullable()();
  TextColumn get teamPrimaryColorHex => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  TextColumn get lastMessageBody => text().nullable()();
  TextColumn get lastMessageSenderId => text().nullable()();
  BoolColumn get lastMessageFromMe =>
      boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chatId};
}

/// Thread message mirror. `senderDisplayName` is the joined value from the
/// `profiles` table at the time the message was cached; rare display-name
/// updates may go stale until the next thread re-fetch.
@DataClassName('MessagesMessageRow')
class MessagesMessages extends Table {
  TextColumn get messageId => text()();
  TextColumn get chatId => text()();
  TextColumn get senderId => text().nullable()();
  TextColumn get senderDisplayName => text().nullable()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get fromMe => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {messageId};
}

/// One draft per chat. Persists the composer's current text so a killed app
/// can resume mid-message.
@DataClassName('MessagesDraftRow')
class MessagesDrafts extends Table {
  TextColumn get chatId => text()();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chatId};
}
