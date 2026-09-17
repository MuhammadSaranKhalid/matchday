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

// ─── Local-First Chat Architecture Tables (Spec §7) ────────────────────────

/// Mirrors target chat_channels. Stores channel metadata for instant inbox
/// rendering and offline discovery.
@DataClassName('LocalChannelRow')
class LocalChannels extends Table {
  TextColumn get channelId => text()();
  TextColumn get channelKey => text()();
  TextColumn get kind => text()();
  TextColumn get contextType => text()();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get purpose => text().withDefault(const Constant('main'))();

  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();

  TextColumn get teamId => text().nullable()();
  TextColumn get matchId => text().nullable()();
  TextColumn get tournamentId => text().nullable()();
  TextColumn get clubId => text().nullable()();

  IntColumn get lastMessageSeq => integer().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  TextColumn get lastMessagePreview => text().nullable()();
  TextColumn get lastMessageSenderId => text().nullable()();
  BoolColumn get lastMessageFromMe => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get serverUpdatedAt => dateTime()();
  DateTimeColumn get localUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {channelId};
}

/// Mirrors target channel_members. Crucial for unread calculation, read/delivery
/// horizons, and channel permissions.
@DataClassName('LocalChannelMemberRow')
class LocalChannelMembers extends Table {
  TextColumn get channelId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get joinedAt => dateTime().nullable()();
  DateTimeColumn get leftAt => dateTime().nullable()();

  IntColumn get lastDeliveredMessageSeq => integer().nullable()();
  DateTimeColumn get lastDeliveredAt => dateTime().nullable()();

  IntColumn get lastReadMessageSeq => integer().nullable()();
  DateTimeColumn get lastReadAt => dateTime().nullable()();

  DateTimeColumn get notificationsMutedUntil => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get pinnedAt => dateTime().nullable()();

  DateTimeColumn get serverUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {channelId, userId};
}

/// Local message store for both confirmed server messages and pending outbox sends.
@DataClassName('LocalMessageRow')
class LocalMessages extends Table {
  TextColumn get messageId => text()();
  IntColumn get messageSeq => integer().nullable()();
  TextColumn get channelId => text()();
  TextColumn get senderId => text().nullable()();
  TextColumn get senderDisplayName => text().nullable()();
  TextColumn get messageType => text().withDefault(const Constant('text'))();
  TextColumn get body => text().nullable()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  TextColumn get replyToMessageId => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get countsAsUnread => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get localCreatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending | sending | sent | failed
  TextColumn get sendErrorCode => text().nullable()();
  TextColumn get sendErrorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {messageId};
}

/// Local attachments metadata (upload status, local file path, and storage path).
@DataClassName('LocalMessageAttachmentRow')
class LocalMessageAttachments extends Table {
  TextColumn get attachmentId => text()();
  TextColumn get messageId => text()();
  TextColumn get storagePath => text().nullable()();
  TextColumn get mimeType => text()();
  TextColumn get fileName => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get thumbnailLocalPath => text().nullable()();
  TextColumn get uploadStatus => text().withDefault(const Constant('pending'))(); // pending | uploading | uploaded | failed
  RealColumn get uploadProgress => real().nullable()();
  TextColumn get uploadError => text().nullable()();

  @override
  Set<Column> get primaryKey => {attachmentId};
}

/// Cached message emoji reactions.
@DataClassName('LocalMessageReactionRow')
class LocalMessageReactions extends Table {
  TextColumn get messageId => text()();
  TextColumn get userId => text()();
  TextColumn get reaction => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get removedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {messageId, userId, reaction};
}

/// Cached member posting restrictions and timeouts.
@DataClassName('LocalMemberRestrictionRow')
class LocalMemberRestrictions extends Table {
  TextColumn get restrictionId => text()();
  TextColumn get channelId => text()();
  TextColumn get userId => text()();
  TextColumn get permission => text()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {restrictionId};
}

/// Mandatory transactional outbox for reliable offline-first writes.
@DataClassName('OutboxOperationRow')
class OutboxOperations extends Table {
  TextColumn get operationId => text()();
  TextColumn get channelId => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get operationType => text()(); // send_message, edit_message, mark_read, mark_delivered, set_reaction, etc.
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending | processing | retry_wait | failed
  TextColumn get coalesceKey => text().nullable()();
  TextColumn get dependsOnOperationId => text().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// Channel synchronization cursor and gap tracking.
@DataClassName('ChannelSyncStateRow')
class ChannelSyncStates extends Table {
  TextColumn get channelId => text()();
  IntColumn get newestSyncedMessageSeq => integer().nullable()();
  IntColumn get newestAppliedChangeSeq => integer().nullable()();
  IntColumn get oldestCachedMessageSeq => integer().nullable()();
  BoolColumn get hasMoreHistory => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastMemberSyncAt => dateTime().nullable()();
  DateTimeColumn get lastFullSyncAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('idle'))();
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {channelId};
}

/// One composer draft per channel.
@DataClassName('ChannelDraftRow')
class ChannelDrafts extends Table {
  TextColumn get channelId => text()();
  TextColumn get body => text()();
  TextColumn get replyToMessageId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {channelId};
}

// ─── Scoring write-ahead log (offline scoring; design doc §10) ──────────────

/// Append-only scoring write-ahead log.
@DataClassName('ScoringOpRow')
class ScoringOps extends Table {
  TextColumn get opId => text()();
  TextColumn get matchId => text()();
  IntColumn get inningsNumber => integer()();
  IntColumn get localSeq => integer()();
  TextColumn get kind => text().withDefault(const Constant('ball'))();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get refusedAt => dateTime().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};
}

/// Innings state at the last synced op.
@DataClassName('ScoringSnapshotRow')
class ScoringSnapshots extends Table {
  TextColumn get matchId => text()();
  IntColumn get inningsNumber => integer()();
  TextColumn get state => text()();
  IntColumn get throughSeq => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId, inningsNumber};
}

// ─── Offline Match Hydration Cache ──────────────────────────────────────────

/// Caches match metadata (format, teams, toss, status) locally for offline cold-start.
@DataClassName('CachedMatchRow')
class CachedMatches extends Table {
  TextColumn get matchId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId};
}

/// Caches the playing XI (match_players) locally for offline cold-start.
@DataClassName('CachedMatchPlayersRow')
class CachedMatchPlayers extends Table {
  TextColumn get matchId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId};
}

/// Caches running match innings state locally for offline cold-start.
@DataClassName('CachedInningsStateRow')
class CachedInningsStates extends Table {
  TextColumn get matchId => text()();
  IntColumn get inningsNumber => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId, inningsNumber};
}
