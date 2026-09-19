import 'package:drift/drift.dart';

/// Local-only persistence for in-progress multi-step wizards (onboarding,
/// team-create, match-setup). Lets a user resume a half-filled flow after
/// killing the app. Keyed by a caller-defined string (e.g.
/// `onboarding:<userId>`); [payload] is the wizard's JSON-encoded draft.
@DataClassName('WizardDraftRow')
class WizardDrafts extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─── Local-First Chat Architecture Tables ──────────────────────────────────

/// Mirrors target chat_channels and stores inbox metadata for instant offline
/// rendering.
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

  // Denormalized DM counterpart projection used only for inbox rendering.
  TextColumn get dmOtherUserId => text().nullable()();
  TextColumn get dmOtherUserName => text().nullable()();
  TextColumn get dmOtherUserUsername => text().nullable()();
  TextColumn get dmOtherUserAvatarUrl => text().nullable()();
  TextColumn get dmOtherMemberStatus => text().nullable()();
  BoolColumn get youFollow => boolean().withDefault(const Constant(false))();
  BoolColumn get theyFollowYou => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {channelId};
}

/// One local projection row per `(channelId, userId)`.
///
/// IMPORTANT: this table intentionally owns BOTH membership state and the
/// small public identity snapshot needed by chat presentation. There is no
/// separate LocalChatParticipants table.
///
/// Why: membership, receipt horizons and participant identity all describe
/// the same channel-user relationship. Splitting those fields across two
/// Drift tables creates duplicate keys, extra joins and consistency problems.
@DataClassName('LocalChannelMemberRow')
class LocalChannelMembers extends Table {
  TextColumn get channelId => text()();
  TextColumn get userId => text()();

  // Membership / authority.
  TextColumn get role => text().withDefault(const Constant('member'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get joinedAt => dateTime().nullable()();
  DateTimeColumn get leftAt => dateTime().nullable()();

  // Public presentation identity snapshot.
  // These fields are not authority. They are only cached UI metadata from
  // `profiles` and can be refreshed independently.
  TextColumn get displayName => text().nullable()();
  TextColumn get username => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();

  // Delivery/read horizons.
  IntColumn get lastDeliveredMessageSeq => integer().nullable()();
  DateTimeColumn get lastDeliveredAt => dateTime().nullable()();
  IntColumn get lastReadMessageSeq => integer().nullable()();
  DateTimeColumn get lastReadAt => dateTime().nullable()();

  // Per-member inbox settings.
  DateTimeColumn get notificationsMutedUntil => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get pinnedAt => dateTime().nullable()();

  DateTimeColumn get serverUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {channelId, userId};
}

/// Local message store for both confirmed server messages and pending outbox
/// sends.
@DataClassName('LocalMessageRow')
class LocalMessages extends Table {
  TextColumn get messageId => text()();
  IntColumn get messageSeq => integer().nullable()();
  TextColumn get channelId => text()();
  TextColumn get senderId => text().nullable()();

  /// Historical/fallback sender-name snapshot. Active presentation should
  /// resolve identity from LocalChannelMembers when possible.
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
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get sendErrorCode => text().nullable()();
  TextColumn get sendErrorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {messageId};
}

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
  TextColumn get uploadStatus => text().withDefault(const Constant('pending'))();
  RealColumn get uploadProgress => real().nullable()();
  TextColumn get uploadError => text().nullable()();

  @override
  Set<Column> get primaryKey => {attachmentId};
}

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

@DataClassName('OutboxOperationRow')
class OutboxOperations extends Table {
  TextColumn get operationId => text()();
  // Account boundary for durable commands. Null only for pre-v4 dev rows,
  // which the processor deliberately ignores.
  TextColumn get ownerUserId => text().nullable()();
  TextColumn get channelId => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
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

@DataClassName('ChannelDraftRow')
class ChannelDrafts extends Table {
  TextColumn get channelId => text()();
  TextColumn get body => text()();
  TextColumn get replyToMessageId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {channelId};
}

// ─── Scoring write-ahead log ────────────────────────────────────────────────

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

@DataClassName('CachedMatchRow')
class CachedMatches extends Table {
  TextColumn get matchId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId};
}

@DataClassName('CachedMatchPlayersRow')
class CachedMatchPlayers extends Table {
  TextColumn get matchId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId};
}

@DataClassName('CachedInningsStateRow')
class CachedInningsStates extends Table {
  TextColumn get matchId => text()();
  IntColumn get inningsNumber => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {matchId, inningsNumber};
}
