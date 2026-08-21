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
// Naming mirrors the Supabase schema 1:1 (`chats`, `messages`,
// `message_drafts`) so the mental model "local row N is the cached counterpart
// of remote row N" is immediate. Other features (teams / posts / matches /
// pavilion / profile) remain online-only.

/// Inbox row mirror. Denormalised — the columns track the shape returned by
/// the `list-my-chats` edge function so a single SELECT can paint the inbox
/// without joins.
@DataClassName('ChatRow')
class Chats extends Table {
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
@DataClassName('MessageRow')
class Messages extends Table {
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
@DataClassName('MessageDraftRow')
class MessageDrafts extends Table {
  TextColumn get chatId => text()();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chatId};
}

// ─── Scoring write-ahead log (offline scoring; design doc §10) ──────────────
//
// EXEMPTION from the online-only rule, scoped to LIVE SCORING ONLY. Unlike the
// messages cache above — which is a read-through optimisation — this is an
// offline WRITE path. A scorer on a ground with no signal must be able to keep
// scoring, and nothing they enter may be lost.
//
// The design that makes this safe is in docs/offline-scoring-design.md §3:
// scoring is single-writer, append-only, deterministic and bounded (~250
// deliveries a match). Those four properties are why this needs no CRDT, no
// vector clock, and no merge logic — it is a queue with an idempotency key,
// not a sync engine. If anyone finds themselves writing merge logic here, the
// design has been misread.
//
// Do NOT generalise this to other features.

/// The log of deliveries the scorer has entered, whether or not the server has
/// them yet.
///
/// Append-only. This records INTENT — the delivery as entered — not the
/// engine's computed result. That distinction is what makes the log safe
/// independently of whether the client engine is correct: the server recomputes
/// every op authoritatively on sync, so a client-side rules bug can produce a
/// wrong provisional *display* but can never lose or corrupt a delivery.
@DataClassName('ScoringOpRow')
class ScoringOps extends Table {
  /// Client-generated uuid, created ONCE when the scorer taps and reused on
  /// every retry. This is the idempotency key the server dedupes on, and it is
  /// why "the server committed it but the reply was lost" is safe to retry.
  TextColumn get opId => text()();

  TextColumn get matchId => text()();
  IntColumn get inningsNumber => integer()();

  /// Monotonic per (match, innings) — the order the scorer entered them, which
  /// is the order the server must receive them. Deliveries are sequential; out
  /// of order they are meaningless.
  IntColumn get localSeq => integer()();

  /// 'ball' | 'undo'.
  TextColumn get kind => text().withDefault(const Constant('ball'))();

  /// The delivery as entered, JSON-encoded.
  TextColumn get payload => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// Null while the server still owes us this one. The outbox drains exactly
  /// the null rows, in localSeq order.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};
}

/// Innings state at the last synced op, so resuming does not mean replaying an
/// innings from ball one.
///
/// Local state is a fold of this snapshot plus the ops after it — recomputable
/// at any moment, which is what turns crash recovery into an ordinary read
/// rather than a special case.
@DataClassName('ScoringSnapshotRow')
class ScoringSnapshots extends Table {
  TextColumn get matchId => text()();
  IntColumn get inningsNumber => integer()();

  /// JSON-encoded innings state as of [throughSeq].
  TextColumn get state => text()();

  /// The localSeq this snapshot already accounts for.
  IntColumn get throughSeq => integer()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId, inningsNumber};
}
