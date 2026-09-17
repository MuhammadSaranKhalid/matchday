// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WizardDraftsTable extends WizardDrafts
    with TableInfo<$WizardDraftsTable, WizardDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WizardDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wizard_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<WizardDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  WizardDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WizardDraftRow(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $WizardDraftsTable createAlias(String alias) {
    return $WizardDraftsTable(attachedDatabase, alias);
  }
}

class WizardDraftRow extends DataClass implements Insertable<WizardDraftRow> {
  final String key;
  final String payload;
  final DateTime updatedAt;
  const WizardDraftRow({
    required this.key,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WizardDraftsCompanion toCompanion(bool nullToAbsent) {
    return WizardDraftsCompanion(
      key: Value(key),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory WizardDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WizardDraftRow(
      key: serializer.fromJson<String>(json['key']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WizardDraftRow copyWith({
    String? key,
    String? payload,
    DateTime? updatedAt,
  }) => WizardDraftRow(
    key: key ?? this.key,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WizardDraftRow copyWithCompanion(WizardDraftsCompanion data) {
    return WizardDraftRow(
      key: data.key.present ? data.key.value : this.key,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WizardDraftRow(')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WizardDraftRow &&
          other.key == this.key &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class WizardDraftsCompanion extends UpdateCompanion<WizardDraftRow> {
  final Value<String> key;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WizardDraftsCompanion({
    this.key = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WizardDraftsCompanion.insert({
    required String key,
    required String payload,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<WizardDraftRow> custom({
    Expression<String>? key,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WizardDraftsCompanion copyWith({
    Value<String>? key,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WizardDraftsCompanion(
      key: key ?? this.key,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WizardDraftsCompanion(')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalChannelsTable extends LocalChannels
    with TableInfo<$LocalChannelsTable, LocalChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelKeyMeta = const VerificationMeta(
    'channelKey',
  );
  @override
  late final GeneratedColumn<String> channelKey = GeneratedColumn<String>(
    'channel_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextTypeMeta = const VerificationMeta(
    'contextType',
  );
  @override
  late final GeneratedColumn<String> contextType = GeneratedColumn<String>(
    'context_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('private'),
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('main'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageSeqMeta = const VerificationMeta(
    'lastMessageSeq',
  );
  @override
  late final GeneratedColumn<int> lastMessageSeq = GeneratedColumn<int>(
    'last_message_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageSenderIdMeta =
      const VerificationMeta('lastMessageSenderId');
  @override
  late final GeneratedColumn<String> lastMessageSenderId =
      GeneratedColumn<String>(
        'last_message_sender_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageFromMeMeta = const VerificationMeta(
    'lastMessageFromMe',
  );
  @override
  late final GeneratedColumn<bool> lastMessageFromMe = GeneratedColumn<bool>(
    'last_message_from_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_message_from_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    channelKey,
    kind,
    contextType,
    visibility,
    purpose,
    title,
    description,
    avatarUrl,
    teamId,
    matchId,
    tournamentId,
    clubId,
    lastMessageSeq,
    lastMessageAt,
    lastMessagePreview,
    lastMessageSenderId,
    lastMessageFromMe,
    unreadCount,
    serverUpdatedAt,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalChannelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('channel_key')) {
      context.handle(
        _channelKeyMeta,
        channelKey.isAcceptableOrUnknown(data['channel_key']!, _channelKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_channelKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('context_type')) {
      context.handle(
        _contextTypeMeta,
        contextType.isAcceptableOrUnknown(
          data['context_type']!,
          _contextTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextTypeMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    }
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    }
    if (data.containsKey('last_message_seq')) {
      context.handle(
        _lastMessageSeqMeta,
        lastMessageSeq.isAcceptableOrUnknown(
          data['last_message_seq']!,
          _lastMessageSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('last_message_sender_id')) {
      context.handle(
        _lastMessageSenderIdMeta,
        lastMessageSenderId.isAcceptableOrUnknown(
          data['last_message_sender_id']!,
          _lastMessageSenderIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_from_me')) {
      context.handle(
        _lastMessageFromMeMeta,
        lastMessageFromMe.isAcceptableOrUnknown(
          data['last_message_from_me']!,
          _lastMessageFromMeMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverUpdatedAtMeta);
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  LocalChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalChannelRow(
      channelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_id'],
          )!,
      channelKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_key'],
          )!,
      kind:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}kind'],
          )!,
      contextType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}context_type'],
          )!,
      visibility:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}visibility'],
          )!,
      purpose:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}purpose'],
          )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      ),
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      ),
      tournamentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tournament_id'],
      ),
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      ),
      lastMessageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_seq'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      ),
      lastMessageSenderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sender_id'],
      ),
      lastMessageFromMe:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}last_message_from_me'],
          )!,
      unreadCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}unread_count'],
          )!,
      serverUpdatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}server_updated_at'],
          )!,
      localUpdatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}local_updated_at'],
          )!,
    );
  }

  @override
  $LocalChannelsTable createAlias(String alias) {
    return $LocalChannelsTable(attachedDatabase, alias);
  }
}

class LocalChannelRow extends DataClass implements Insertable<LocalChannelRow> {
  final String channelId;
  final String channelKey;
  final String kind;
  final String contextType;
  final String visibility;
  final String purpose;
  final String? title;
  final String? description;
  final String? avatarUrl;
  final String? teamId;
  final String? matchId;
  final String? tournamentId;
  final String? clubId;
  final int? lastMessageSeq;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final bool lastMessageFromMe;
  final int unreadCount;
  final DateTime serverUpdatedAt;
  final DateTime localUpdatedAt;
  const LocalChannelRow({
    required this.channelId,
    required this.channelKey,
    required this.kind,
    required this.contextType,
    required this.visibility,
    required this.purpose,
    this.title,
    this.description,
    this.avatarUrl,
    this.teamId,
    this.matchId,
    this.tournamentId,
    this.clubId,
    this.lastMessageSeq,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageSenderId,
    required this.lastMessageFromMe,
    required this.unreadCount,
    required this.serverUpdatedAt,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['channel_key'] = Variable<String>(channelKey);
    map['kind'] = Variable<String>(kind);
    map['context_type'] = Variable<String>(contextType);
    map['visibility'] = Variable<String>(visibility);
    map['purpose'] = Variable<String>(purpose);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || matchId != null) {
      map['match_id'] = Variable<String>(matchId);
    }
    if (!nullToAbsent || tournamentId != null) {
      map['tournament_id'] = Variable<String>(tournamentId);
    }
    if (!nullToAbsent || clubId != null) {
      map['club_id'] = Variable<String>(clubId);
    }
    if (!nullToAbsent || lastMessageSeq != null) {
      map['last_message_seq'] = Variable<int>(lastMessageSeq);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    if (!nullToAbsent || lastMessageSenderId != null) {
      map['last_message_sender_id'] = Variable<String>(lastMessageSenderId);
    }
    map['last_message_from_me'] = Variable<bool>(lastMessageFromMe);
    map['unread_count'] = Variable<int>(unreadCount);
    map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  LocalChannelsCompanion toCompanion(bool nullToAbsent) {
    return LocalChannelsCompanion(
      channelId: Value(channelId),
      channelKey: Value(channelKey),
      kind: Value(kind),
      contextType: Value(contextType),
      visibility: Value(visibility),
      purpose: Value(purpose),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      avatarUrl:
          avatarUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(avatarUrl),
      teamId:
          teamId == null && nullToAbsent ? const Value.absent() : Value(teamId),
      matchId:
          matchId == null && nullToAbsent
              ? const Value.absent()
              : Value(matchId),
      tournamentId:
          tournamentId == null && nullToAbsent
              ? const Value.absent()
              : Value(tournamentId),
      clubId:
          clubId == null && nullToAbsent ? const Value.absent() : Value(clubId),
      lastMessageSeq:
          lastMessageSeq == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessageSeq),
      lastMessageAt:
          lastMessageAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessageAt),
      lastMessagePreview:
          lastMessagePreview == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessagePreview),
      lastMessageSenderId:
          lastMessageSenderId == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessageSenderId),
      lastMessageFromMe: Value(lastMessageFromMe),
      unreadCount: Value(unreadCount),
      serverUpdatedAt: Value(serverUpdatedAt),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory LocalChannelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalChannelRow(
      channelId: serializer.fromJson<String>(json['channelId']),
      channelKey: serializer.fromJson<String>(json['channelKey']),
      kind: serializer.fromJson<String>(json['kind']),
      contextType: serializer.fromJson<String>(json['contextType']),
      visibility: serializer.fromJson<String>(json['visibility']),
      purpose: serializer.fromJson<String>(json['purpose']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      matchId: serializer.fromJson<String?>(json['matchId']),
      tournamentId: serializer.fromJson<String?>(json['tournamentId']),
      clubId: serializer.fromJson<String?>(json['clubId']),
      lastMessageSeq: serializer.fromJson<int?>(json['lastMessageSeq']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      lastMessagePreview: serializer.fromJson<String?>(
        json['lastMessagePreview'],
      ),
      lastMessageSenderId: serializer.fromJson<String?>(
        json['lastMessageSenderId'],
      ),
      lastMessageFromMe: serializer.fromJson<bool>(json['lastMessageFromMe']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      serverUpdatedAt: serializer.fromJson<DateTime>(json['serverUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'channelKey': serializer.toJson<String>(channelKey),
      'kind': serializer.toJson<String>(kind),
      'contextType': serializer.toJson<String>(contextType),
      'visibility': serializer.toJson<String>(visibility),
      'purpose': serializer.toJson<String>(purpose),
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'teamId': serializer.toJson<String?>(teamId),
      'matchId': serializer.toJson<String?>(matchId),
      'tournamentId': serializer.toJson<String?>(tournamentId),
      'clubId': serializer.toJson<String?>(clubId),
      'lastMessageSeq': serializer.toJson<int?>(lastMessageSeq),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'lastMessagePreview': serializer.toJson<String?>(lastMessagePreview),
      'lastMessageSenderId': serializer.toJson<String?>(lastMessageSenderId),
      'lastMessageFromMe': serializer.toJson<bool>(lastMessageFromMe),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'serverUpdatedAt': serializer.toJson<DateTime>(serverUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  LocalChannelRow copyWith({
    String? channelId,
    String? channelKey,
    String? kind,
    String? contextType,
    String? visibility,
    String? purpose,
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> teamId = const Value.absent(),
    Value<String?> matchId = const Value.absent(),
    Value<String?> tournamentId = const Value.absent(),
    Value<String?> clubId = const Value.absent(),
    Value<int?> lastMessageSeq = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    Value<String?> lastMessagePreview = const Value.absent(),
    Value<String?> lastMessageSenderId = const Value.absent(),
    bool? lastMessageFromMe,
    int? unreadCount,
    DateTime? serverUpdatedAt,
    DateTime? localUpdatedAt,
  }) => LocalChannelRow(
    channelId: channelId ?? this.channelId,
    channelKey: channelKey ?? this.channelKey,
    kind: kind ?? this.kind,
    contextType: contextType ?? this.contextType,
    visibility: visibility ?? this.visibility,
    purpose: purpose ?? this.purpose,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    teamId: teamId.present ? teamId.value : this.teamId,
    matchId: matchId.present ? matchId.value : this.matchId,
    tournamentId: tournamentId.present ? tournamentId.value : this.tournamentId,
    clubId: clubId.present ? clubId.value : this.clubId,
    lastMessageSeq:
        lastMessageSeq.present ? lastMessageSeq.value : this.lastMessageSeq,
    lastMessageAt:
        lastMessageAt.present ? lastMessageAt.value : this.lastMessageAt,
    lastMessagePreview:
        lastMessagePreview.present
            ? lastMessagePreview.value
            : this.lastMessagePreview,
    lastMessageSenderId:
        lastMessageSenderId.present
            ? lastMessageSenderId.value
            : this.lastMessageSenderId,
    lastMessageFromMe: lastMessageFromMe ?? this.lastMessageFromMe,
    unreadCount: unreadCount ?? this.unreadCount,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  LocalChannelRow copyWithCompanion(LocalChannelsCompanion data) {
    return LocalChannelRow(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      channelKey:
          data.channelKey.present ? data.channelKey.value : this.channelKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      contextType:
          data.contextType.present ? data.contextType.value : this.contextType,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      tournamentId:
          data.tournamentId.present
              ? data.tournamentId.value
              : this.tournamentId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      lastMessageSeq:
          data.lastMessageSeq.present
              ? data.lastMessageSeq.value
              : this.lastMessageSeq,
      lastMessageAt:
          data.lastMessageAt.present
              ? data.lastMessageAt.value
              : this.lastMessageAt,
      lastMessagePreview:
          data.lastMessagePreview.present
              ? data.lastMessagePreview.value
              : this.lastMessagePreview,
      lastMessageSenderId:
          data.lastMessageSenderId.present
              ? data.lastMessageSenderId.value
              : this.lastMessageSenderId,
      lastMessageFromMe:
          data.lastMessageFromMe.present
              ? data.lastMessageFromMe.value
              : this.lastMessageFromMe,
      unreadCount:
          data.unreadCount.present ? data.unreadCount.value : this.unreadCount,
      serverUpdatedAt:
          data.serverUpdatedAt.present
              ? data.serverUpdatedAt.value
              : this.serverUpdatedAt,
      localUpdatedAt:
          data.localUpdatedAt.present
              ? data.localUpdatedAt.value
              : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalChannelRow(')
          ..write('channelId: $channelId, ')
          ..write('channelKey: $channelKey, ')
          ..write('kind: $kind, ')
          ..write('contextType: $contextType, ')
          ..write('visibility: $visibility, ')
          ..write('purpose: $purpose, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('teamId: $teamId, ')
          ..write('matchId: $matchId, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('clubId: $clubId, ')
          ..write('lastMessageSeq: $lastMessageSeq, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageFromMe: $lastMessageFromMe, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    channelId,
    channelKey,
    kind,
    contextType,
    visibility,
    purpose,
    title,
    description,
    avatarUrl,
    teamId,
    matchId,
    tournamentId,
    clubId,
    lastMessageSeq,
    lastMessageAt,
    lastMessagePreview,
    lastMessageSenderId,
    lastMessageFromMe,
    unreadCount,
    serverUpdatedAt,
    localUpdatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalChannelRow &&
          other.channelId == this.channelId &&
          other.channelKey == this.channelKey &&
          other.kind == this.kind &&
          other.contextType == this.contextType &&
          other.visibility == this.visibility &&
          other.purpose == this.purpose &&
          other.title == this.title &&
          other.description == this.description &&
          other.avatarUrl == this.avatarUrl &&
          other.teamId == this.teamId &&
          other.matchId == this.matchId &&
          other.tournamentId == this.tournamentId &&
          other.clubId == this.clubId &&
          other.lastMessageSeq == this.lastMessageSeq &&
          other.lastMessageAt == this.lastMessageAt &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.lastMessageSenderId == this.lastMessageSenderId &&
          other.lastMessageFromMe == this.lastMessageFromMe &&
          other.unreadCount == this.unreadCount &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class LocalChannelsCompanion extends UpdateCompanion<LocalChannelRow> {
  final Value<String> channelId;
  final Value<String> channelKey;
  final Value<String> kind;
  final Value<String> contextType;
  final Value<String> visibility;
  final Value<String> purpose;
  final Value<String?> title;
  final Value<String?> description;
  final Value<String?> avatarUrl;
  final Value<String?> teamId;
  final Value<String?> matchId;
  final Value<String?> tournamentId;
  final Value<String?> clubId;
  final Value<int?> lastMessageSeq;
  final Value<DateTime?> lastMessageAt;
  final Value<String?> lastMessagePreview;
  final Value<String?> lastMessageSenderId;
  final Value<bool> lastMessageFromMe;
  final Value<int> unreadCount;
  final Value<DateTime> serverUpdatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const LocalChannelsCompanion({
    this.channelId = const Value.absent(),
    this.channelKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.contextType = const Value.absent(),
    this.visibility = const Value.absent(),
    this.purpose = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.teamId = const Value.absent(),
    this.matchId = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.lastMessageSeq = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageFromMe = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalChannelsCompanion.insert({
    required String channelId,
    required String channelKey,
    required String kind,
    required String contextType,
    this.visibility = const Value.absent(),
    this.purpose = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.teamId = const Value.absent(),
    this.matchId = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.lastMessageSeq = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageFromMe = const Value.absent(),
    this.unreadCount = const Value.absent(),
    required DateTime serverUpdatedAt,
    required DateTime localUpdatedAt,
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       channelKey = Value(channelKey),
       kind = Value(kind),
       contextType = Value(contextType),
       serverUpdatedAt = Value(serverUpdatedAt),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<LocalChannelRow> custom({
    Expression<String>? channelId,
    Expression<String>? channelKey,
    Expression<String>? kind,
    Expression<String>? contextType,
    Expression<String>? visibility,
    Expression<String>? purpose,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? avatarUrl,
    Expression<String>? teamId,
    Expression<String>? matchId,
    Expression<String>? tournamentId,
    Expression<String>? clubId,
    Expression<int>? lastMessageSeq,
    Expression<DateTime>? lastMessageAt,
    Expression<String>? lastMessagePreview,
    Expression<String>? lastMessageSenderId,
    Expression<bool>? lastMessageFromMe,
    Expression<int>? unreadCount,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (channelKey != null) 'channel_key': channelKey,
      if (kind != null) 'kind': kind,
      if (contextType != null) 'context_type': contextType,
      if (visibility != null) 'visibility': visibility,
      if (purpose != null) 'purpose': purpose,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (teamId != null) 'team_id': teamId,
      if (matchId != null) 'match_id': matchId,
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (clubId != null) 'club_id': clubId,
      if (lastMessageSeq != null) 'last_message_seq': lastMessageSeq,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (lastMessageSenderId != null)
        'last_message_sender_id': lastMessageSenderId,
      if (lastMessageFromMe != null) 'last_message_from_me': lastMessageFromMe,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalChannelsCompanion copyWith({
    Value<String>? channelId,
    Value<String>? channelKey,
    Value<String>? kind,
    Value<String>? contextType,
    Value<String>? visibility,
    Value<String>? purpose,
    Value<String?>? title,
    Value<String?>? description,
    Value<String?>? avatarUrl,
    Value<String?>? teamId,
    Value<String?>? matchId,
    Value<String?>? tournamentId,
    Value<String?>? clubId,
    Value<int?>? lastMessageSeq,
    Value<DateTime?>? lastMessageAt,
    Value<String?>? lastMessagePreview,
    Value<String?>? lastMessageSenderId,
    Value<bool>? lastMessageFromMe,
    Value<int>? unreadCount,
    Value<DateTime>? serverUpdatedAt,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return LocalChannelsCompanion(
      channelId: channelId ?? this.channelId,
      channelKey: channelKey ?? this.channelKey,
      kind: kind ?? this.kind,
      contextType: contextType ?? this.contextType,
      visibility: visibility ?? this.visibility,
      purpose: purpose ?? this.purpose,
      title: title ?? this.title,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      teamId: teamId ?? this.teamId,
      matchId: matchId ?? this.matchId,
      tournamentId: tournamentId ?? this.tournamentId,
      clubId: clubId ?? this.clubId,
      lastMessageSeq: lastMessageSeq ?? this.lastMessageSeq,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageFromMe: lastMessageFromMe ?? this.lastMessageFromMe,
      unreadCount: unreadCount ?? this.unreadCount,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (channelKey.present) {
      map['channel_key'] = Variable<String>(channelKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (contextType.present) {
      map['context_type'] = Variable<String>(contextType.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (lastMessageSeq.present) {
      map['last_message_seq'] = Variable<int>(lastMessageSeq.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (lastMessageSenderId.present) {
      map['last_message_sender_id'] = Variable<String>(
        lastMessageSenderId.value,
      );
    }
    if (lastMessageFromMe.present) {
      map['last_message_from_me'] = Variable<bool>(lastMessageFromMe.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalChannelsCompanion(')
          ..write('channelId: $channelId, ')
          ..write('channelKey: $channelKey, ')
          ..write('kind: $kind, ')
          ..write('contextType: $contextType, ')
          ..write('visibility: $visibility, ')
          ..write('purpose: $purpose, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('teamId: $teamId, ')
          ..write('matchId: $matchId, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('clubId: $clubId, ')
          ..write('lastMessageSeq: $lastMessageSeq, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageFromMe: $lastMessageFromMe, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalChannelMembersTable extends LocalChannelMembers
    with TableInfo<$LocalChannelMembersTable, LocalChannelMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalChannelMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('member'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leftAtMeta = const VerificationMeta('leftAt');
  @override
  late final GeneratedColumn<DateTime> leftAt = GeneratedColumn<DateTime>(
    'left_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastDeliveredMessageSeqMeta =
      const VerificationMeta('lastDeliveredMessageSeq');
  @override
  late final GeneratedColumn<int> lastDeliveredMessageSeq =
      GeneratedColumn<int>(
        'last_delivered_message_seq',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastDeliveredAtMeta = const VerificationMeta(
    'lastDeliveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastDeliveredAt =
      GeneratedColumn<DateTime>(
        'last_delivered_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastReadMessageSeqMeta =
      const VerificationMeta('lastReadMessageSeq');
  @override
  late final GeneratedColumn<int> lastReadMessageSeq = GeneratedColumn<int>(
    'last_read_message_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationsMutedUntilMeta =
      const VerificationMeta('notificationsMutedUntil');
  @override
  late final GeneratedColumn<DateTime> notificationsMutedUntil =
      GeneratedColumn<DateTime>(
        'notifications_muted_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta(
    'pinnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    userId,
    role,
    status,
    joinedAt,
    leftAt,
    lastDeliveredMessageSeq,
    lastDeliveredAt,
    lastReadMessageSeq,
    lastReadAt,
    notificationsMutedUntil,
    archivedAt,
    pinnedAt,
    serverUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_channel_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalChannelMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    if (data.containsKey('left_at')) {
      context.handle(
        _leftAtMeta,
        leftAt.isAcceptableOrUnknown(data['left_at']!, _leftAtMeta),
      );
    }
    if (data.containsKey('last_delivered_message_seq')) {
      context.handle(
        _lastDeliveredMessageSeqMeta,
        lastDeliveredMessageSeq.isAcceptableOrUnknown(
          data['last_delivered_message_seq']!,
          _lastDeliveredMessageSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_delivered_at')) {
      context.handle(
        _lastDeliveredAtMeta,
        lastDeliveredAt.isAcceptableOrUnknown(
          data['last_delivered_at']!,
          _lastDeliveredAtMeta,
        ),
      );
    }
    if (data.containsKey('last_read_message_seq')) {
      context.handle(
        _lastReadMessageSeqMeta,
        lastReadMessageSeq.isAcceptableOrUnknown(
          data['last_read_message_seq']!,
          _lastReadMessageSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('notifications_muted_until')) {
      context.handle(
        _notificationsMutedUntilMeta,
        notificationsMutedUntil.isAcceptableOrUnknown(
          data['notifications_muted_until']!,
          _notificationsMutedUntilMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('pinned_at')) {
      context.handle(
        _pinnedAtMeta,
        pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId, userId};
  @override
  LocalChannelMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalChannelMemberRow(
      channelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_id'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      role:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}role'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      ),
      leftAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}left_at'],
      ),
      lastDeliveredMessageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_delivered_message_seq'],
      ),
      lastDeliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_delivered_at'],
      ),
      lastReadMessageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_message_seq'],
      ),
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      ),
      notificationsMutedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}notifications_muted_until'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      pinnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pinned_at'],
      ),
      serverUpdatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}server_updated_at'],
          )!,
    );
  }

  @override
  $LocalChannelMembersTable createAlias(String alias) {
    return $LocalChannelMembersTable(attachedDatabase, alias);
  }
}

class LocalChannelMemberRow extends DataClass
    implements Insertable<LocalChannelMemberRow> {
  final String channelId;
  final String userId;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int? lastDeliveredMessageSeq;
  final DateTime? lastDeliveredAt;
  final int? lastReadMessageSeq;
  final DateTime? lastReadAt;
  final DateTime? notificationsMutedUntil;
  final DateTime? archivedAt;
  final DateTime? pinnedAt;
  final DateTime serverUpdatedAt;
  const LocalChannelMemberRow({
    required this.channelId,
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
    this.leftAt,
    this.lastDeliveredMessageSeq,
    this.lastDeliveredAt,
    this.lastReadMessageSeq,
    this.lastReadAt,
    this.notificationsMutedUntil,
    this.archivedAt,
    this.pinnedAt,
    required this.serverUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || joinedAt != null) {
      map['joined_at'] = Variable<DateTime>(joinedAt);
    }
    if (!nullToAbsent || leftAt != null) {
      map['left_at'] = Variable<DateTime>(leftAt);
    }
    if (!nullToAbsent || lastDeliveredMessageSeq != null) {
      map['last_delivered_message_seq'] = Variable<int>(
        lastDeliveredMessageSeq,
      );
    }
    if (!nullToAbsent || lastDeliveredAt != null) {
      map['last_delivered_at'] = Variable<DateTime>(lastDeliveredAt);
    }
    if (!nullToAbsent || lastReadMessageSeq != null) {
      map['last_read_message_seq'] = Variable<int>(lastReadMessageSeq);
    }
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt);
    }
    if (!nullToAbsent || notificationsMutedUntil != null) {
      map['notifications_muted_until'] = Variable<DateTime>(
        notificationsMutedUntil,
      );
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    return map;
  }

  LocalChannelMembersCompanion toCompanion(bool nullToAbsent) {
    return LocalChannelMembersCompanion(
      channelId: Value(channelId),
      userId: Value(userId),
      role: Value(role),
      status: Value(status),
      joinedAt:
          joinedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(joinedAt),
      leftAt:
          leftAt == null && nullToAbsent ? const Value.absent() : Value(leftAt),
      lastDeliveredMessageSeq:
          lastDeliveredMessageSeq == null && nullToAbsent
              ? const Value.absent()
              : Value(lastDeliveredMessageSeq),
      lastDeliveredAt:
          lastDeliveredAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastDeliveredAt),
      lastReadMessageSeq:
          lastReadMessageSeq == null && nullToAbsent
              ? const Value.absent()
              : Value(lastReadMessageSeq),
      lastReadAt:
          lastReadAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastReadAt),
      notificationsMutedUntil:
          notificationsMutedUntil == null && nullToAbsent
              ? const Value.absent()
              : Value(notificationsMutedUntil),
      archivedAt:
          archivedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(archivedAt),
      pinnedAt:
          pinnedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(pinnedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
    );
  }

  factory LocalChannelMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalChannelMemberRow(
      channelId: serializer.fromJson<String>(json['channelId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      joinedAt: serializer.fromJson<DateTime?>(json['joinedAt']),
      leftAt: serializer.fromJson<DateTime?>(json['leftAt']),
      lastDeliveredMessageSeq: serializer.fromJson<int?>(
        json['lastDeliveredMessageSeq'],
      ),
      lastDeliveredAt: serializer.fromJson<DateTime?>(json['lastDeliveredAt']),
      lastReadMessageSeq: serializer.fromJson<int?>(json['lastReadMessageSeq']),
      lastReadAt: serializer.fromJson<DateTime?>(json['lastReadAt']),
      notificationsMutedUntil: serializer.fromJson<DateTime?>(
        json['notificationsMutedUntil'],
      ),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      serverUpdatedAt: serializer.fromJson<DateTime>(json['serverUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'joinedAt': serializer.toJson<DateTime?>(joinedAt),
      'leftAt': serializer.toJson<DateTime?>(leftAt),
      'lastDeliveredMessageSeq': serializer.toJson<int?>(
        lastDeliveredMessageSeq,
      ),
      'lastDeliveredAt': serializer.toJson<DateTime?>(lastDeliveredAt),
      'lastReadMessageSeq': serializer.toJson<int?>(lastReadMessageSeq),
      'lastReadAt': serializer.toJson<DateTime?>(lastReadAt),
      'notificationsMutedUntil': serializer.toJson<DateTime?>(
        notificationsMutedUntil,
      ),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'serverUpdatedAt': serializer.toJson<DateTime>(serverUpdatedAt),
    };
  }

  LocalChannelMemberRow copyWith({
    String? channelId,
    String? userId,
    String? role,
    String? status,
    Value<DateTime?> joinedAt = const Value.absent(),
    Value<DateTime?> leftAt = const Value.absent(),
    Value<int?> lastDeliveredMessageSeq = const Value.absent(),
    Value<DateTime?> lastDeliveredAt = const Value.absent(),
    Value<int?> lastReadMessageSeq = const Value.absent(),
    Value<DateTime?> lastReadAt = const Value.absent(),
    Value<DateTime?> notificationsMutedUntil = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> pinnedAt = const Value.absent(),
    DateTime? serverUpdatedAt,
  }) => LocalChannelMemberRow(
    channelId: channelId ?? this.channelId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    status: status ?? this.status,
    joinedAt: joinedAt.present ? joinedAt.value : this.joinedAt,
    leftAt: leftAt.present ? leftAt.value : this.leftAt,
    lastDeliveredMessageSeq:
        lastDeliveredMessageSeq.present
            ? lastDeliveredMessageSeq.value
            : this.lastDeliveredMessageSeq,
    lastDeliveredAt:
        lastDeliveredAt.present ? lastDeliveredAt.value : this.lastDeliveredAt,
    lastReadMessageSeq:
        lastReadMessageSeq.present
            ? lastReadMessageSeq.value
            : this.lastReadMessageSeq,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    notificationsMutedUntil:
        notificationsMutedUntil.present
            ? notificationsMutedUntil.value
            : this.notificationsMutedUntil,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
  );
  LocalChannelMemberRow copyWithCompanion(LocalChannelMembersCompanion data) {
    return LocalChannelMemberRow(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      status: data.status.present ? data.status.value : this.status,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      leftAt: data.leftAt.present ? data.leftAt.value : this.leftAt,
      lastDeliveredMessageSeq:
          data.lastDeliveredMessageSeq.present
              ? data.lastDeliveredMessageSeq.value
              : this.lastDeliveredMessageSeq,
      lastDeliveredAt:
          data.lastDeliveredAt.present
              ? data.lastDeliveredAt.value
              : this.lastDeliveredAt,
      lastReadMessageSeq:
          data.lastReadMessageSeq.present
              ? data.lastReadMessageSeq.value
              : this.lastReadMessageSeq,
      lastReadAt:
          data.lastReadAt.present ? data.lastReadAt.value : this.lastReadAt,
      notificationsMutedUntil:
          data.notificationsMutedUntil.present
              ? data.notificationsMutedUntil.value
              : this.notificationsMutedUntil,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      serverUpdatedAt:
          data.serverUpdatedAt.present
              ? data.serverUpdatedAt.value
              : this.serverUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalChannelMemberRow(')
          ..write('channelId: $channelId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('lastDeliveredMessageSeq: $lastDeliveredMessageSeq, ')
          ..write('lastDeliveredAt: $lastDeliveredAt, ')
          ..write('lastReadMessageSeq: $lastReadMessageSeq, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('notificationsMutedUntil: $notificationsMutedUntil, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    channelId,
    userId,
    role,
    status,
    joinedAt,
    leftAt,
    lastDeliveredMessageSeq,
    lastDeliveredAt,
    lastReadMessageSeq,
    lastReadAt,
    notificationsMutedUntil,
    archivedAt,
    pinnedAt,
    serverUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalChannelMemberRow &&
          other.channelId == this.channelId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.status == this.status &&
          other.joinedAt == this.joinedAt &&
          other.leftAt == this.leftAt &&
          other.lastDeliveredMessageSeq == this.lastDeliveredMessageSeq &&
          other.lastDeliveredAt == this.lastDeliveredAt &&
          other.lastReadMessageSeq == this.lastReadMessageSeq &&
          other.lastReadAt == this.lastReadAt &&
          other.notificationsMutedUntil == this.notificationsMutedUntil &&
          other.archivedAt == this.archivedAt &&
          other.pinnedAt == this.pinnedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt);
}

class LocalChannelMembersCompanion
    extends UpdateCompanion<LocalChannelMemberRow> {
  final Value<String> channelId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> status;
  final Value<DateTime?> joinedAt;
  final Value<DateTime?> leftAt;
  final Value<int?> lastDeliveredMessageSeq;
  final Value<DateTime?> lastDeliveredAt;
  final Value<int?> lastReadMessageSeq;
  final Value<DateTime?> lastReadAt;
  final Value<DateTime?> notificationsMutedUntil;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> pinnedAt;
  final Value<DateTime> serverUpdatedAt;
  final Value<int> rowid;
  const LocalChannelMembersCompanion({
    this.channelId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.leftAt = const Value.absent(),
    this.lastDeliveredMessageSeq = const Value.absent(),
    this.lastDeliveredAt = const Value.absent(),
    this.lastReadMessageSeq = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.notificationsMutedUntil = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalChannelMembersCompanion.insert({
    required String channelId,
    required String userId,
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.leftAt = const Value.absent(),
    this.lastDeliveredMessageSeq = const Value.absent(),
    this.lastDeliveredAt = const Value.absent(),
    this.lastReadMessageSeq = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.notificationsMutedUntil = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    required DateTime serverUpdatedAt,
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       userId = Value(userId),
       serverUpdatedAt = Value(serverUpdatedAt);
  static Insertable<LocalChannelMemberRow> custom({
    Expression<String>? channelId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? status,
    Expression<DateTime>? joinedAt,
    Expression<DateTime>? leftAt,
    Expression<int>? lastDeliveredMessageSeq,
    Expression<DateTime>? lastDeliveredAt,
    Expression<int>? lastReadMessageSeq,
    Expression<DateTime>? lastReadAt,
    Expression<DateTime>? notificationsMutedUntil,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? pinnedAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (leftAt != null) 'left_at': leftAt,
      if (lastDeliveredMessageSeq != null)
        'last_delivered_message_seq': lastDeliveredMessageSeq,
      if (lastDeliveredAt != null) 'last_delivered_at': lastDeliveredAt,
      if (lastReadMessageSeq != null)
        'last_read_message_seq': lastReadMessageSeq,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (notificationsMutedUntil != null)
        'notifications_muted_until': notificationsMutedUntil,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalChannelMembersCompanion copyWith({
    Value<String>? channelId,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? status,
    Value<DateTime?>? joinedAt,
    Value<DateTime?>? leftAt,
    Value<int?>? lastDeliveredMessageSeq,
    Value<DateTime?>? lastDeliveredAt,
    Value<int?>? lastReadMessageSeq,
    Value<DateTime?>? lastReadAt,
    Value<DateTime?>? notificationsMutedUntil,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? pinnedAt,
    Value<DateTime>? serverUpdatedAt,
    Value<int>? rowid,
  }) {
    return LocalChannelMembersCompanion(
      channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      lastDeliveredMessageSeq:
          lastDeliveredMessageSeq ?? this.lastDeliveredMessageSeq,
      lastDeliveredAt: lastDeliveredAt ?? this.lastDeliveredAt,
      lastReadMessageSeq: lastReadMessageSeq ?? this.lastReadMessageSeq,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      notificationsMutedUntil:
          notificationsMutedUntil ?? this.notificationsMutedUntil,
      archivedAt: archivedAt ?? this.archivedAt,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (leftAt.present) {
      map['left_at'] = Variable<DateTime>(leftAt.value);
    }
    if (lastDeliveredMessageSeq.present) {
      map['last_delivered_message_seq'] = Variable<int>(
        lastDeliveredMessageSeq.value,
      );
    }
    if (lastDeliveredAt.present) {
      map['last_delivered_at'] = Variable<DateTime>(lastDeliveredAt.value);
    }
    if (lastReadMessageSeq.present) {
      map['last_read_message_seq'] = Variable<int>(lastReadMessageSeq.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    if (notificationsMutedUntil.present) {
      map['notifications_muted_until'] = Variable<DateTime>(
        notificationsMutedUntil.value,
      );
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalChannelMembersCompanion(')
          ..write('channelId: $channelId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('lastDeliveredMessageSeq: $lastDeliveredMessageSeq, ')
          ..write('lastDeliveredAt: $lastDeliveredAt, ')
          ..write('lastReadMessageSeq: $lastReadMessageSeq, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('notificationsMutedUntil: $notificationsMutedUntil, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageSeqMeta = const VerificationMeta(
    'messageSeq',
  );
  @override
  late final GeneratedColumn<int> messageSeq = GeneratedColumn<int>(
    'message_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderDisplayNameMeta = const VerificationMeta(
    'senderDisplayName',
  );
  @override
  late final GeneratedColumn<String> senderDisplayName =
      GeneratedColumn<String>(
        'sender_display_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _messageTypeMeta = const VerificationMeta(
    'messageType',
  );
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _replyToMessageIdMeta = const VerificationMeta(
    'replyToMessageId',
  );
  @override
  late final GeneratedColumn<String> replyToMessageId = GeneratedColumn<String>(
    'reply_to_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _countsAsUnreadMeta = const VerificationMeta(
    'countsAsUnread',
  );
  @override
  late final GeneratedColumn<bool> countsAsUnread = GeneratedColumn<bool>(
    'counts_as_unread',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counts_as_unread" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localCreatedAtMeta = const VerificationMeta(
    'localCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localCreatedAt =
      GeneratedColumn<DateTime>(
        'local_created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _sendErrorCodeMeta = const VerificationMeta(
    'sendErrorCode',
  );
  @override
  late final GeneratedColumn<String> sendErrorCode = GeneratedColumn<String>(
    'send_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendErrorMessageMeta = const VerificationMeta(
    'sendErrorMessage',
  );
  @override
  late final GeneratedColumn<String> sendErrorMessage = GeneratedColumn<String>(
    'send_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    messageSeq,
    channelId,
    senderId,
    senderDisplayName,
    messageType,
    body,
    payloadJson,
    replyToMessageId,
    version,
    countsAsUnread,
    createdAt,
    updatedAt,
    editedAt,
    deletedAt,
    localCreatedAt,
    syncStatus,
    sendErrorCode,
    sendErrorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('message_seq')) {
      context.handle(
        _messageSeqMeta,
        messageSeq.isAcceptableOrUnknown(data['message_seq']!, _messageSeqMeta),
      );
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    }
    if (data.containsKey('sender_display_name')) {
      context.handle(
        _senderDisplayNameMeta,
        senderDisplayName.isAcceptableOrUnknown(
          data['sender_display_name']!,
          _senderDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('message_type')) {
      context.handle(
        _messageTypeMeta,
        messageType.isAcceptableOrUnknown(
          data['message_type']!,
          _messageTypeMeta,
        ),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
        _replyToMessageIdMeta,
        replyToMessageId.isAcceptableOrUnknown(
          data['reply_to_message_id']!,
          _replyToMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('counts_as_unread')) {
      context.handle(
        _countsAsUnreadMeta,
        countsAsUnread.isAcceptableOrUnknown(
          data['counts_as_unread']!,
          _countsAsUnreadMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('local_created_at')) {
      context.handle(
        _localCreatedAtMeta,
        localCreatedAt.isAcceptableOrUnknown(
          data['local_created_at']!,
          _localCreatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localCreatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('send_error_code')) {
      context.handle(
        _sendErrorCodeMeta,
        sendErrorCode.isAcceptableOrUnknown(
          data['send_error_code']!,
          _sendErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('send_error_message')) {
      context.handle(
        _sendErrorMessageMeta,
        sendErrorMessage.isAcceptableOrUnknown(
          data['send_error_message']!,
          _sendErrorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  LocalMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessageRow(
      messageId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message_id'],
          )!,
      messageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_seq'],
      ),
      channelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_id'],
          )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      ),
      senderDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_display_name'],
      ),
      messageType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message_type'],
          )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      payloadJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload_json'],
          )!,
      replyToMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_message_id'],
      ),
      version:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}version'],
          )!,
      countsAsUnread:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}counts_as_unread'],
          )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}edited_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      localCreatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}local_created_at'],
          )!,
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      sendErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}send_error_code'],
      ),
      sendErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}send_error_message'],
      ),
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessageRow extends DataClass implements Insertable<LocalMessageRow> {
  final String messageId;
  final int? messageSeq;
  final String channelId;
  final String? senderId;
  final String? senderDisplayName;
  final String messageType;
  final String? body;
  final String payloadJson;
  final String? replyToMessageId;
  final int version;
  final bool countsAsUnread;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime localCreatedAt;
  final String syncStatus;
  final String? sendErrorCode;
  final String? sendErrorMessage;
  const LocalMessageRow({
    required this.messageId,
    this.messageSeq,
    required this.channelId,
    this.senderId,
    this.senderDisplayName,
    required this.messageType,
    this.body,
    required this.payloadJson,
    this.replyToMessageId,
    required this.version,
    required this.countsAsUnread,
    this.createdAt,
    this.updatedAt,
    this.editedAt,
    this.deletedAt,
    required this.localCreatedAt,
    required this.syncStatus,
    this.sendErrorCode,
    this.sendErrorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || messageSeq != null) {
      map['message_seq'] = Variable<int>(messageSeq);
    }
    map['channel_id'] = Variable<String>(channelId);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<String>(senderId);
    }
    if (!nullToAbsent || senderDisplayName != null) {
      map['sender_display_name'] = Variable<String>(senderDisplayName);
    }
    map['message_type'] = Variable<String>(messageType);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || replyToMessageId != null) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId);
    }
    map['version'] = Variable<int>(version);
    map['counts_as_unread'] = Variable<bool>(countsAsUnread);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['local_created_at'] = Variable<DateTime>(localCreatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || sendErrorCode != null) {
      map['send_error_code'] = Variable<String>(sendErrorCode);
    }
    if (!nullToAbsent || sendErrorMessage != null) {
      map['send_error_message'] = Variable<String>(sendErrorMessage);
    }
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      messageId: Value(messageId),
      messageSeq:
          messageSeq == null && nullToAbsent
              ? const Value.absent()
              : Value(messageSeq),
      channelId: Value(channelId),
      senderId:
          senderId == null && nullToAbsent
              ? const Value.absent()
              : Value(senderId),
      senderDisplayName:
          senderDisplayName == null && nullToAbsent
              ? const Value.absent()
              : Value(senderDisplayName),
      messageType: Value(messageType),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      payloadJson: Value(payloadJson),
      replyToMessageId:
          replyToMessageId == null && nullToAbsent
              ? const Value.absent()
              : Value(replyToMessageId),
      version: Value(version),
      countsAsUnread: Value(countsAsUnread),
      createdAt:
          createdAt == null && nullToAbsent
              ? const Value.absent()
              : Value(createdAt),
      updatedAt:
          updatedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(updatedAt),
      editedAt:
          editedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(editedAt),
      deletedAt:
          deletedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(deletedAt),
      localCreatedAt: Value(localCreatedAt),
      syncStatus: Value(syncStatus),
      sendErrorCode:
          sendErrorCode == null && nullToAbsent
              ? const Value.absent()
              : Value(sendErrorCode),
      sendErrorMessage:
          sendErrorMessage == null && nullToAbsent
              ? const Value.absent()
              : Value(sendErrorMessage),
    );
  }

  factory LocalMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessageRow(
      messageId: serializer.fromJson<String>(json['messageId']),
      messageSeq: serializer.fromJson<int?>(json['messageSeq']),
      channelId: serializer.fromJson<String>(json['channelId']),
      senderId: serializer.fromJson<String?>(json['senderId']),
      senderDisplayName: serializer.fromJson<String?>(
        json['senderDisplayName'],
      ),
      messageType: serializer.fromJson<String>(json['messageType']),
      body: serializer.fromJson<String?>(json['body']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      replyToMessageId: serializer.fromJson<String?>(json['replyToMessageId']),
      version: serializer.fromJson<int>(json['version']),
      countsAsUnread: serializer.fromJson<bool>(json['countsAsUnread']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      localCreatedAt: serializer.fromJson<DateTime>(json['localCreatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      sendErrorCode: serializer.fromJson<String?>(json['sendErrorCode']),
      sendErrorMessage: serializer.fromJson<String?>(json['sendErrorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'messageSeq': serializer.toJson<int?>(messageSeq),
      'channelId': serializer.toJson<String>(channelId),
      'senderId': serializer.toJson<String?>(senderId),
      'senderDisplayName': serializer.toJson<String?>(senderDisplayName),
      'messageType': serializer.toJson<String>(messageType),
      'body': serializer.toJson<String?>(body),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'replyToMessageId': serializer.toJson<String?>(replyToMessageId),
      'version': serializer.toJson<int>(version),
      'countsAsUnread': serializer.toJson<bool>(countsAsUnread),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'localCreatedAt': serializer.toJson<DateTime>(localCreatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'sendErrorCode': serializer.toJson<String?>(sendErrorCode),
      'sendErrorMessage': serializer.toJson<String?>(sendErrorMessage),
    };
  }

  LocalMessageRow copyWith({
    String? messageId,
    Value<int?> messageSeq = const Value.absent(),
    String? channelId,
    Value<String?> senderId = const Value.absent(),
    Value<String?> senderDisplayName = const Value.absent(),
    String? messageType,
    Value<String?> body = const Value.absent(),
    String? payloadJson,
    Value<String?> replyToMessageId = const Value.absent(),
    int? version,
    bool? countsAsUnread,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> editedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? localCreatedAt,
    String? syncStatus,
    Value<String?> sendErrorCode = const Value.absent(),
    Value<String?> sendErrorMessage = const Value.absent(),
  }) => LocalMessageRow(
    messageId: messageId ?? this.messageId,
    messageSeq: messageSeq.present ? messageSeq.value : this.messageSeq,
    channelId: channelId ?? this.channelId,
    senderId: senderId.present ? senderId.value : this.senderId,
    senderDisplayName:
        senderDisplayName.present
            ? senderDisplayName.value
            : this.senderDisplayName,
    messageType: messageType ?? this.messageType,
    body: body.present ? body.value : this.body,
    payloadJson: payloadJson ?? this.payloadJson,
    replyToMessageId:
        replyToMessageId.present
            ? replyToMessageId.value
            : this.replyToMessageId,
    version: version ?? this.version,
    countsAsUnread: countsAsUnread ?? this.countsAsUnread,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    localCreatedAt: localCreatedAt ?? this.localCreatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    sendErrorCode:
        sendErrorCode.present ? sendErrorCode.value : this.sendErrorCode,
    sendErrorMessage:
        sendErrorMessage.present
            ? sendErrorMessage.value
            : this.sendErrorMessage,
  );
  LocalMessageRow copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessageRow(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      messageSeq:
          data.messageSeq.present ? data.messageSeq.value : this.messageSeq,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderDisplayName:
          data.senderDisplayName.present
              ? data.senderDisplayName.value
              : this.senderDisplayName,
      messageType:
          data.messageType.present ? data.messageType.value : this.messageType,
      body: data.body.present ? data.body.value : this.body,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      replyToMessageId:
          data.replyToMessageId.present
              ? data.replyToMessageId.value
              : this.replyToMessageId,
      version: data.version.present ? data.version.value : this.version,
      countsAsUnread:
          data.countsAsUnread.present
              ? data.countsAsUnread.value
              : this.countsAsUnread,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      localCreatedAt:
          data.localCreatedAt.present
              ? data.localCreatedAt.value
              : this.localCreatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      sendErrorCode:
          data.sendErrorCode.present
              ? data.sendErrorCode.value
              : this.sendErrorCode,
      sendErrorMessage:
          data.sendErrorMessage.present
              ? data.sendErrorMessage.value
              : this.sendErrorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageRow(')
          ..write('messageId: $messageId, ')
          ..write('messageSeq: $messageSeq, ')
          ..write('channelId: $channelId, ')
          ..write('senderId: $senderId, ')
          ..write('senderDisplayName: $senderDisplayName, ')
          ..write('messageType: $messageType, ')
          ..write('body: $body, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('version: $version, ')
          ..write('countsAsUnread: $countsAsUnread, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('localCreatedAt: $localCreatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('sendErrorCode: $sendErrorCode, ')
          ..write('sendErrorMessage: $sendErrorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    messageSeq,
    channelId,
    senderId,
    senderDisplayName,
    messageType,
    body,
    payloadJson,
    replyToMessageId,
    version,
    countsAsUnread,
    createdAt,
    updatedAt,
    editedAt,
    deletedAt,
    localCreatedAt,
    syncStatus,
    sendErrorCode,
    sendErrorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessageRow &&
          other.messageId == this.messageId &&
          other.messageSeq == this.messageSeq &&
          other.channelId == this.channelId &&
          other.senderId == this.senderId &&
          other.senderDisplayName == this.senderDisplayName &&
          other.messageType == this.messageType &&
          other.body == this.body &&
          other.payloadJson == this.payloadJson &&
          other.replyToMessageId == this.replyToMessageId &&
          other.version == this.version &&
          other.countsAsUnread == this.countsAsUnread &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt &&
          other.localCreatedAt == this.localCreatedAt &&
          other.syncStatus == this.syncStatus &&
          other.sendErrorCode == this.sendErrorCode &&
          other.sendErrorMessage == this.sendErrorMessage);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessageRow> {
  final Value<String> messageId;
  final Value<int?> messageSeq;
  final Value<String> channelId;
  final Value<String?> senderId;
  final Value<String?> senderDisplayName;
  final Value<String> messageType;
  final Value<String?> body;
  final Value<String> payloadJson;
  final Value<String?> replyToMessageId;
  final Value<int> version;
  final Value<bool> countsAsUnread;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> editedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> localCreatedAt;
  final Value<String> syncStatus;
  final Value<String?> sendErrorCode;
  final Value<String?> sendErrorMessage;
  final Value<int> rowid;
  const LocalMessagesCompanion({
    this.messageId = const Value.absent(),
    this.messageSeq = const Value.absent(),
    this.channelId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderDisplayName = const Value.absent(),
    this.messageType = const Value.absent(),
    this.body = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.version = const Value.absent(),
    this.countsAsUnread = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.localCreatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.sendErrorCode = const Value.absent(),
    this.sendErrorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    required String messageId,
    this.messageSeq = const Value.absent(),
    required String channelId,
    this.senderId = const Value.absent(),
    this.senderDisplayName = const Value.absent(),
    this.messageType = const Value.absent(),
    this.body = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.version = const Value.absent(),
    this.countsAsUnread = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime localCreatedAt,
    this.syncStatus = const Value.absent(),
    this.sendErrorCode = const Value.absent(),
    this.sendErrorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       channelId = Value(channelId),
       localCreatedAt = Value(localCreatedAt);
  static Insertable<LocalMessageRow> custom({
    Expression<String>? messageId,
    Expression<int>? messageSeq,
    Expression<String>? channelId,
    Expression<String>? senderId,
    Expression<String>? senderDisplayName,
    Expression<String>? messageType,
    Expression<String>? body,
    Expression<String>? payloadJson,
    Expression<String>? replyToMessageId,
    Expression<int>? version,
    Expression<bool>? countsAsUnread,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? editedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? localCreatedAt,
    Expression<String>? syncStatus,
    Expression<String>? sendErrorCode,
    Expression<String>? sendErrorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (messageSeq != null) 'message_seq': messageSeq,
      if (channelId != null) 'channel_id': channelId,
      if (senderId != null) 'sender_id': senderId,
      if (senderDisplayName != null) 'sender_display_name': senderDisplayName,
      if (messageType != null) 'message_type': messageType,
      if (body != null) 'body': body,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (version != null) 'version': version,
      if (countsAsUnread != null) 'counts_as_unread': countsAsUnread,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (localCreatedAt != null) 'local_created_at': localCreatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (sendErrorCode != null) 'send_error_code': sendErrorCode,
      if (sendErrorMessage != null) 'send_error_message': sendErrorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessagesCompanion copyWith({
    Value<String>? messageId,
    Value<int?>? messageSeq,
    Value<String>? channelId,
    Value<String?>? senderId,
    Value<String?>? senderDisplayName,
    Value<String>? messageType,
    Value<String?>? body,
    Value<String>? payloadJson,
    Value<String?>? replyToMessageId,
    Value<int>? version,
    Value<bool>? countsAsUnread,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? editedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? localCreatedAt,
    Value<String>? syncStatus,
    Value<String?>? sendErrorCode,
    Value<String?>? sendErrorMessage,
    Value<int>? rowid,
  }) {
    return LocalMessagesCompanion(
      messageId: messageId ?? this.messageId,
      messageSeq: messageSeq ?? this.messageSeq,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      messageType: messageType ?? this.messageType,
      body: body ?? this.body,
      payloadJson: payloadJson ?? this.payloadJson,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      version: version ?? this.version,
      countsAsUnread: countsAsUnread ?? this.countsAsUnread,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      localCreatedAt: localCreatedAt ?? this.localCreatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      sendErrorCode: sendErrorCode ?? this.sendErrorCode,
      sendErrorMessage: sendErrorMessage ?? this.sendErrorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (messageSeq.present) {
      map['message_seq'] = Variable<int>(messageSeq.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderDisplayName.present) {
      map['sender_display_name'] = Variable<String>(senderDisplayName.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (countsAsUnread.present) {
      map['counts_as_unread'] = Variable<bool>(countsAsUnread.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (localCreatedAt.present) {
      map['local_created_at'] = Variable<DateTime>(localCreatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (sendErrorCode.present) {
      map['send_error_code'] = Variable<String>(sendErrorCode.value);
    }
    if (sendErrorMessage.present) {
      map['send_error_message'] = Variable<String>(sendErrorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('messageSeq: $messageSeq, ')
          ..write('channelId: $channelId, ')
          ..write('senderId: $senderId, ')
          ..write('senderDisplayName: $senderDisplayName, ')
          ..write('messageType: $messageType, ')
          ..write('body: $body, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('version: $version, ')
          ..write('countsAsUnread: $countsAsUnread, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('localCreatedAt: $localCreatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('sendErrorCode: $sendErrorCode, ')
          ..write('sendErrorMessage: $sendErrorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessageAttachmentsTable extends LocalMessageAttachments
    with TableInfo<$LocalMessageAttachmentsTable, LocalMessageAttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessageAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailLocalPathMeta =
      const VerificationMeta('thumbnailLocalPath');
  @override
  late final GeneratedColumn<String> thumbnailLocalPath =
      GeneratedColumn<String>(
        'thumbnail_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _uploadStatusMeta = const VerificationMeta(
    'uploadStatus',
  );
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
    'upload_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _uploadProgressMeta = const VerificationMeta(
    'uploadProgress',
  );
  @override
  late final GeneratedColumn<double> uploadProgress = GeneratedColumn<double>(
    'upload_progress',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadErrorMeta = const VerificationMeta(
    'uploadError',
  );
  @override
  late final GeneratedColumn<String> uploadError = GeneratedColumn<String>(
    'upload_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    attachmentId,
    messageId,
    storagePath,
    mimeType,
    fileName,
    sizeBytes,
    width,
    height,
    durationMs,
    localPath,
    thumbnailLocalPath,
    uploadStatus,
    uploadProgress,
    uploadError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_message_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessageAttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('thumbnail_local_path')) {
      context.handle(
        _thumbnailLocalPathMeta,
        thumbnailLocalPath.isAcceptableOrUnknown(
          data['thumbnail_local_path']!,
          _thumbnailLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('upload_status')) {
      context.handle(
        _uploadStatusMeta,
        uploadStatus.isAcceptableOrUnknown(
          data['upload_status']!,
          _uploadStatusMeta,
        ),
      );
    }
    if (data.containsKey('upload_progress')) {
      context.handle(
        _uploadProgressMeta,
        uploadProgress.isAcceptableOrUnknown(
          data['upload_progress']!,
          _uploadProgressMeta,
        ),
      );
    }
    if (data.containsKey('upload_error')) {
      context.handle(
        _uploadErrorMeta,
        uploadError.isAcceptableOrUnknown(
          data['upload_error']!,
          _uploadErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  LocalMessageAttachmentRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessageAttachmentRow(
      attachmentId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}attachment_id'],
          )!,
      messageId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message_id'],
          )!,
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      ),
      mimeType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mime_type'],
          )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      thumbnailLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_local_path'],
      ),
      uploadStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}upload_status'],
          )!,
      uploadProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}upload_progress'],
      ),
      uploadError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_error'],
      ),
    );
  }

  @override
  $LocalMessageAttachmentsTable createAlias(String alias) {
    return $LocalMessageAttachmentsTable(attachedDatabase, alias);
  }
}

class LocalMessageAttachmentRow extends DataClass
    implements Insertable<LocalMessageAttachmentRow> {
  final String attachmentId;
  final String messageId;
  final String? storagePath;
  final String mimeType;
  final String? fileName;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? localPath;
  final String? thumbnailLocalPath;
  final String uploadStatus;
  final double? uploadProgress;
  final String? uploadError;
  const LocalMessageAttachmentRow({
    required this.attachmentId,
    required this.messageId,
    this.storagePath,
    required this.mimeType,
    this.fileName,
    this.sizeBytes,
    this.width,
    this.height,
    this.durationMs,
    this.localPath,
    this.thumbnailLocalPath,
    required this.uploadStatus,
    this.uploadProgress,
    this.uploadError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<String>(attachmentId);
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || thumbnailLocalPath != null) {
      map['thumbnail_local_path'] = Variable<String>(thumbnailLocalPath);
    }
    map['upload_status'] = Variable<String>(uploadStatus);
    if (!nullToAbsent || uploadProgress != null) {
      map['upload_progress'] = Variable<double>(uploadProgress);
    }
    if (!nullToAbsent || uploadError != null) {
      map['upload_error'] = Variable<String>(uploadError);
    }
    return map;
  }

  LocalMessageAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return LocalMessageAttachmentsCompanion(
      attachmentId: Value(attachmentId),
      messageId: Value(messageId),
      storagePath:
          storagePath == null && nullToAbsent
              ? const Value.absent()
              : Value(storagePath),
      mimeType: Value(mimeType),
      fileName:
          fileName == null && nullToAbsent
              ? const Value.absent()
              : Value(fileName),
      sizeBytes:
          sizeBytes == null && nullToAbsent
              ? const Value.absent()
              : Value(sizeBytes),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      durationMs:
          durationMs == null && nullToAbsent
              ? const Value.absent()
              : Value(durationMs),
      localPath:
          localPath == null && nullToAbsent
              ? const Value.absent()
              : Value(localPath),
      thumbnailLocalPath:
          thumbnailLocalPath == null && nullToAbsent
              ? const Value.absent()
              : Value(thumbnailLocalPath),
      uploadStatus: Value(uploadStatus),
      uploadProgress:
          uploadProgress == null && nullToAbsent
              ? const Value.absent()
              : Value(uploadProgress),
      uploadError:
          uploadError == null && nullToAbsent
              ? const Value.absent()
              : Value(uploadError),
    );
  }

  factory LocalMessageAttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessageAttachmentRow(
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      thumbnailLocalPath: serializer.fromJson<String?>(
        json['thumbnailLocalPath'],
      ),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      uploadProgress: serializer.fromJson<double?>(json['uploadProgress']),
      uploadError: serializer.fromJson<String?>(json['uploadError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<String>(attachmentId),
      'messageId': serializer.toJson<String>(messageId),
      'storagePath': serializer.toJson<String?>(storagePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileName': serializer.toJson<String?>(fileName),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationMs': serializer.toJson<int?>(durationMs),
      'localPath': serializer.toJson<String?>(localPath),
      'thumbnailLocalPath': serializer.toJson<String?>(thumbnailLocalPath),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'uploadProgress': serializer.toJson<double?>(uploadProgress),
      'uploadError': serializer.toJson<String?>(uploadError),
    };
  }

  LocalMessageAttachmentRow copyWith({
    String? attachmentId,
    String? messageId,
    Value<String?> storagePath = const Value.absent(),
    String? mimeType,
    Value<String?> fileName = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> thumbnailLocalPath = const Value.absent(),
    String? uploadStatus,
    Value<double?> uploadProgress = const Value.absent(),
    Value<String?> uploadError = const Value.absent(),
  }) => LocalMessageAttachmentRow(
    attachmentId: attachmentId ?? this.attachmentId,
    messageId: messageId ?? this.messageId,
    storagePath: storagePath.present ? storagePath.value : this.storagePath,
    mimeType: mimeType ?? this.mimeType,
    fileName: fileName.present ? fileName.value : this.fileName,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    localPath: localPath.present ? localPath.value : this.localPath,
    thumbnailLocalPath:
        thumbnailLocalPath.present
            ? thumbnailLocalPath.value
            : this.thumbnailLocalPath,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    uploadProgress:
        uploadProgress.present ? uploadProgress.value : this.uploadProgress,
    uploadError: uploadError.present ? uploadError.value : this.uploadError,
  );
  LocalMessageAttachmentRow copyWithCompanion(
    LocalMessageAttachmentsCompanion data,
  ) {
    return LocalMessageAttachmentRow(
      attachmentId:
          data.attachmentId.present
              ? data.attachmentId.value
              : this.attachmentId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      storagePath:
          data.storagePath.present ? data.storagePath.value : this.storagePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      thumbnailLocalPath:
          data.thumbnailLocalPath.present
              ? data.thumbnailLocalPath.value
              : this.thumbnailLocalPath,
      uploadStatus:
          data.uploadStatus.present
              ? data.uploadStatus.value
              : this.uploadStatus,
      uploadProgress:
          data.uploadProgress.present
              ? data.uploadProgress.value
              : this.uploadProgress,
      uploadError:
          data.uploadError.present ? data.uploadError.value : this.uploadError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageAttachmentRow(')
          ..write('attachmentId: $attachmentId, ')
          ..write('messageId: $messageId, ')
          ..write('storagePath: $storagePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('localPath: $localPath, ')
          ..write('thumbnailLocalPath: $thumbnailLocalPath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('uploadProgress: $uploadProgress, ')
          ..write('uploadError: $uploadError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attachmentId,
    messageId,
    storagePath,
    mimeType,
    fileName,
    sizeBytes,
    width,
    height,
    durationMs,
    localPath,
    thumbnailLocalPath,
    uploadStatus,
    uploadProgress,
    uploadError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessageAttachmentRow &&
          other.attachmentId == this.attachmentId &&
          other.messageId == this.messageId &&
          other.storagePath == this.storagePath &&
          other.mimeType == this.mimeType &&
          other.fileName == this.fileName &&
          other.sizeBytes == this.sizeBytes &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationMs == this.durationMs &&
          other.localPath == this.localPath &&
          other.thumbnailLocalPath == this.thumbnailLocalPath &&
          other.uploadStatus == this.uploadStatus &&
          other.uploadProgress == this.uploadProgress &&
          other.uploadError == this.uploadError);
}

class LocalMessageAttachmentsCompanion
    extends UpdateCompanion<LocalMessageAttachmentRow> {
  final Value<String> attachmentId;
  final Value<String> messageId;
  final Value<String?> storagePath;
  final Value<String> mimeType;
  final Value<String?> fileName;
  final Value<int?> sizeBytes;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationMs;
  final Value<String?> localPath;
  final Value<String?> thumbnailLocalPath;
  final Value<String> uploadStatus;
  final Value<double?> uploadProgress;
  final Value<String?> uploadError;
  final Value<int> rowid;
  const LocalMessageAttachmentsCompanion({
    this.attachmentId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.localPath = const Value.absent(),
    this.thumbnailLocalPath = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.uploadProgress = const Value.absent(),
    this.uploadError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessageAttachmentsCompanion.insert({
    required String attachmentId,
    required String messageId,
    this.storagePath = const Value.absent(),
    required String mimeType,
    this.fileName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.localPath = const Value.absent(),
    this.thumbnailLocalPath = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.uploadProgress = const Value.absent(),
    this.uploadError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attachmentId = Value(attachmentId),
       messageId = Value(messageId),
       mimeType = Value(mimeType);
  static Insertable<LocalMessageAttachmentRow> custom({
    Expression<String>? attachmentId,
    Expression<String>? messageId,
    Expression<String>? storagePath,
    Expression<String>? mimeType,
    Expression<String>? fileName,
    Expression<int>? sizeBytes,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationMs,
    Expression<String>? localPath,
    Expression<String>? thumbnailLocalPath,
    Expression<String>? uploadStatus,
    Expression<double>? uploadProgress,
    Expression<String>? uploadError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (messageId != null) 'message_id': messageId,
      if (storagePath != null) 'storage_path': storagePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileName != null) 'file_name': fileName,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationMs != null) 'duration_ms': durationMs,
      if (localPath != null) 'local_path': localPath,
      if (thumbnailLocalPath != null)
        'thumbnail_local_path': thumbnailLocalPath,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (uploadProgress != null) 'upload_progress': uploadProgress,
      if (uploadError != null) 'upload_error': uploadError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessageAttachmentsCompanion copyWith({
    Value<String>? attachmentId,
    Value<String>? messageId,
    Value<String?>? storagePath,
    Value<String>? mimeType,
    Value<String?>? fileName,
    Value<int?>? sizeBytes,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? durationMs,
    Value<String?>? localPath,
    Value<String?>? thumbnailLocalPath,
    Value<String>? uploadStatus,
    Value<double?>? uploadProgress,
    Value<String?>? uploadError,
    Value<int>? rowid,
  }) {
    return LocalMessageAttachmentsCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      messageId: messageId ?? this.messageId,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      durationMs: durationMs ?? this.durationMs,
      localPath: localPath ?? this.localPath,
      thumbnailLocalPath: thumbnailLocalPath ?? this.thumbnailLocalPath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadError: uploadError ?? this.uploadError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (thumbnailLocalPath.present) {
      map['thumbnail_local_path'] = Variable<String>(thumbnailLocalPath.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (uploadProgress.present) {
      map['upload_progress'] = Variable<double>(uploadProgress.value);
    }
    if (uploadError.present) {
      map['upload_error'] = Variable<String>(uploadError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageAttachmentsCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('messageId: $messageId, ')
          ..write('storagePath: $storagePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('localPath: $localPath, ')
          ..write('thumbnailLocalPath: $thumbnailLocalPath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('uploadProgress: $uploadProgress, ')
          ..write('uploadError: $uploadError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessageReactionsTable extends LocalMessageReactions
    with TableInfo<$LocalMessageReactionsTable, LocalMessageReactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessageReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reactionMeta = const VerificationMeta(
    'reaction',
  );
  @override
  late final GeneratedColumn<String> reaction = GeneratedColumn<String>(
    'reaction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedAtMeta = const VerificationMeta(
    'removedAt',
  );
  @override
  late final GeneratedColumn<DateTime> removedAt = GeneratedColumn<DateTime>(
    'removed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    userId,
    reaction,
    createdAt,
    updatedAt,
    removedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_message_reactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessageReactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('reaction')) {
      context.handle(
        _reactionMeta,
        reaction.isAcceptableOrUnknown(data['reaction']!, _reactionMeta),
      );
    } else if (isInserting) {
      context.missing(_reactionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('removed_at')) {
      context.handle(
        _removedAtMeta,
        removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, userId, reaction};
  @override
  LocalMessageReactionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessageReactionRow(
      messageId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message_id'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      reaction:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reaction'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
      removedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}removed_at'],
      ),
    );
  }

  @override
  $LocalMessageReactionsTable createAlias(String alias) {
    return $LocalMessageReactionsTable(attachedDatabase, alias);
  }
}

class LocalMessageReactionRow extends DataClass
    implements Insertable<LocalMessageReactionRow> {
  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? removedAt;
  const LocalMessageReactionRow({
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
    required this.updatedAt,
    this.removedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['user_id'] = Variable<String>(userId);
    map['reaction'] = Variable<String>(reaction);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = Variable<DateTime>(removedAt);
    }
    return map;
  }

  LocalMessageReactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalMessageReactionsCompanion(
      messageId: Value(messageId),
      userId: Value(userId),
      reaction: Value(reaction),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      removedAt:
          removedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(removedAt),
    );
  }

  factory LocalMessageReactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessageReactionRow(
      messageId: serializer.fromJson<String>(json['messageId']),
      userId: serializer.fromJson<String>(json['userId']),
      reaction: serializer.fromJson<String>(json['reaction']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      removedAt: serializer.fromJson<DateTime?>(json['removedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'userId': serializer.toJson<String>(userId),
      'reaction': serializer.toJson<String>(reaction),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'removedAt': serializer.toJson<DateTime?>(removedAt),
    };
  }

  LocalMessageReactionRow copyWith({
    String? messageId,
    String? userId,
    String? reaction,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> removedAt = const Value.absent(),
  }) => LocalMessageReactionRow(
    messageId: messageId ?? this.messageId,
    userId: userId ?? this.userId,
    reaction: reaction ?? this.reaction,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    removedAt: removedAt.present ? removedAt.value : this.removedAt,
  );
  LocalMessageReactionRow copyWithCompanion(
    LocalMessageReactionsCompanion data,
  ) {
    return LocalMessageReactionRow(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      userId: data.userId.present ? data.userId.value : this.userId,
      reaction: data.reaction.present ? data.reaction.value : this.reaction,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageReactionRow(')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('reaction: $reaction, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('removedAt: $removedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(messageId, userId, reaction, createdAt, updatedAt, removedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessageReactionRow &&
          other.messageId == this.messageId &&
          other.userId == this.userId &&
          other.reaction == this.reaction &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.removedAt == this.removedAt);
}

class LocalMessageReactionsCompanion
    extends UpdateCompanion<LocalMessageReactionRow> {
  final Value<String> messageId;
  final Value<String> userId;
  final Value<String> reaction;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> removedAt;
  final Value<int> rowid;
  const LocalMessageReactionsCompanion({
    this.messageId = const Value.absent(),
    this.userId = const Value.absent(),
    this.reaction = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessageReactionsCompanion.insert({
    required String messageId,
    required String userId,
    required String reaction,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.removedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       userId = Value(userId),
       reaction = Value(reaction),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMessageReactionRow> custom({
    Expression<String>? messageId,
    Expression<String>? userId,
    Expression<String>? reaction,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? removedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (userId != null) 'user_id': userId,
      if (reaction != null) 'reaction': reaction,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (removedAt != null) 'removed_at': removedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessageReactionsCompanion copyWith({
    Value<String>? messageId,
    Value<String>? userId,
    Value<String>? reaction,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? removedAt,
    Value<int>? rowid,
  }) {
    return LocalMessageReactionsCompanion(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      reaction: reaction ?? this.reaction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      removedAt: removedAt ?? this.removedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (reaction.present) {
      map['reaction'] = Variable<String>(reaction.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (removedAt.present) {
      map['removed_at'] = Variable<DateTime>(removedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageReactionsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('reaction: $reaction, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMemberRestrictionsTable extends LocalMemberRestrictions
    with TableInfo<$LocalMemberRestrictionsTable, LocalMemberRestrictionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMemberRestrictionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _restrictionIdMeta = const VerificationMeta(
    'restrictionId',
  );
  @override
  late final GeneratedColumn<String> restrictionId = GeneratedColumn<String>(
    'restriction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionMeta = const VerificationMeta(
    'permission',
  );
  @override
  late final GeneratedColumn<String> permission = GeneratedColumn<String>(
    'permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    restrictionId,
    channelId,
    userId,
    permission,
    startsAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_member_restrictions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMemberRestrictionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('restriction_id')) {
      context.handle(
        _restrictionIdMeta,
        restrictionId.isAcceptableOrUnknown(
          data['restriction_id']!,
          _restrictionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_restrictionIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('permission')) {
      context.handle(
        _permissionMeta,
        permission.isAcceptableOrUnknown(data['permission']!, _permissionMeta),
      );
    } else if (isInserting) {
      context.missing(_permissionMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {restrictionId};
  @override
  LocalMemberRestrictionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMemberRestrictionRow(
      restrictionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}restriction_id'],
          )!,
      channelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_id'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      permission:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}permission'],
          )!,
      startsAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}starts_at'],
          )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
    );
  }

  @override
  $LocalMemberRestrictionsTable createAlias(String alias) {
    return $LocalMemberRestrictionsTable(attachedDatabase, alias);
  }
}

class LocalMemberRestrictionRow extends DataClass
    implements Insertable<LocalMemberRestrictionRow> {
  final String restrictionId;
  final String channelId;
  final String userId;
  final String permission;
  final DateTime startsAt;
  final DateTime? expiresAt;
  const LocalMemberRestrictionRow({
    required this.restrictionId,
    required this.channelId,
    required this.userId,
    required this.permission,
    required this.startsAt,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['restriction_id'] = Variable<String>(restrictionId);
    map['channel_id'] = Variable<String>(channelId);
    map['user_id'] = Variable<String>(userId);
    map['permission'] = Variable<String>(permission);
    map['starts_at'] = Variable<DateTime>(startsAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  LocalMemberRestrictionsCompanion toCompanion(bool nullToAbsent) {
    return LocalMemberRestrictionsCompanion(
      restrictionId: Value(restrictionId),
      channelId: Value(channelId),
      userId: Value(userId),
      permission: Value(permission),
      startsAt: Value(startsAt),
      expiresAt:
          expiresAt == null && nullToAbsent
              ? const Value.absent()
              : Value(expiresAt),
    );
  }

  factory LocalMemberRestrictionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMemberRestrictionRow(
      restrictionId: serializer.fromJson<String>(json['restrictionId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      userId: serializer.fromJson<String>(json['userId']),
      permission: serializer.fromJson<String>(json['permission']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'restrictionId': serializer.toJson<String>(restrictionId),
      'channelId': serializer.toJson<String>(channelId),
      'userId': serializer.toJson<String>(userId),
      'permission': serializer.toJson<String>(permission),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  LocalMemberRestrictionRow copyWith({
    String? restrictionId,
    String? channelId,
    String? userId,
    String? permission,
    DateTime? startsAt,
    Value<DateTime?> expiresAt = const Value.absent(),
  }) => LocalMemberRestrictionRow(
    restrictionId: restrictionId ?? this.restrictionId,
    channelId: channelId ?? this.channelId,
    userId: userId ?? this.userId,
    permission: permission ?? this.permission,
    startsAt: startsAt ?? this.startsAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
  );
  LocalMemberRestrictionRow copyWithCompanion(
    LocalMemberRestrictionsCompanion data,
  ) {
    return LocalMemberRestrictionRow(
      restrictionId:
          data.restrictionId.present
              ? data.restrictionId.value
              : this.restrictionId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      userId: data.userId.present ? data.userId.value : this.userId,
      permission:
          data.permission.present ? data.permission.value : this.permission,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemberRestrictionRow(')
          ..write('restrictionId: $restrictionId, ')
          ..write('channelId: $channelId, ')
          ..write('userId: $userId, ')
          ..write('permission: $permission, ')
          ..write('startsAt: $startsAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    restrictionId,
    channelId,
    userId,
    permission,
    startsAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMemberRestrictionRow &&
          other.restrictionId == this.restrictionId &&
          other.channelId == this.channelId &&
          other.userId == this.userId &&
          other.permission == this.permission &&
          other.startsAt == this.startsAt &&
          other.expiresAt == this.expiresAt);
}

class LocalMemberRestrictionsCompanion
    extends UpdateCompanion<LocalMemberRestrictionRow> {
  final Value<String> restrictionId;
  final Value<String> channelId;
  final Value<String> userId;
  final Value<String> permission;
  final Value<DateTime> startsAt;
  final Value<DateTime?> expiresAt;
  final Value<int> rowid;
  const LocalMemberRestrictionsCompanion({
    this.restrictionId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.userId = const Value.absent(),
    this.permission = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMemberRestrictionsCompanion.insert({
    required String restrictionId,
    required String channelId,
    required String userId,
    required String permission,
    required DateTime startsAt,
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : restrictionId = Value(restrictionId),
       channelId = Value(channelId),
       userId = Value(userId),
       permission = Value(permission),
       startsAt = Value(startsAt);
  static Insertable<LocalMemberRestrictionRow> custom({
    Expression<String>? restrictionId,
    Expression<String>? channelId,
    Expression<String>? userId,
    Expression<String>? permission,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (restrictionId != null) 'restriction_id': restrictionId,
      if (channelId != null) 'channel_id': channelId,
      if (userId != null) 'user_id': userId,
      if (permission != null) 'permission': permission,
      if (startsAt != null) 'starts_at': startsAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMemberRestrictionsCompanion copyWith({
    Value<String>? restrictionId,
    Value<String>? channelId,
    Value<String>? userId,
    Value<String>? permission,
    Value<DateTime>? startsAt,
    Value<DateTime?>? expiresAt,
    Value<int>? rowid,
  }) {
    return LocalMemberRestrictionsCompanion(
      restrictionId: restrictionId ?? this.restrictionId,
      channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId,
      permission: permission ?? this.permission,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (restrictionId.present) {
      map['restriction_id'] = Variable<String>(restrictionId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (permission.present) {
      map['permission'] = Variable<String>(permission.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemberRestrictionsCompanion(')
          ..write('restrictionId: $restrictionId, ')
          ..write('channelId: $channelId, ')
          ..write('userId: $userId, ')
          ..write('permission: $permission, ')
          ..write('startsAt: $startsAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxOperationsTable extends OutboxOperations
    with TableInfo<$OutboxOperationsTable, OutboxOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _coalesceKeyMeta = const VerificationMeta(
    'coalesceKey',
  );
  @override
  late final GeneratedColumn<String> coalesceKey = GeneratedColumn<String>(
    'coalesce_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnOperationIdMeta =
      const VerificationMeta('dependsOnOperationId');
  @override
  late final GeneratedColumn<String> dependsOnOperationId =
      GeneratedColumn<String>(
        'depends_on_operation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    channelId,
    entityId,
    operationType,
    payloadJson,
    status,
    coalesceKey,
    dependsOnOperationId,
    attemptCount,
    nextAttemptAt,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('coalesce_key')) {
      context.handle(
        _coalesceKeyMeta,
        coalesceKey.isAcceptableOrUnknown(
          data['coalesce_key']!,
          _coalesceKeyMeta,
        ),
      );
    }
    if (data.containsKey('depends_on_operation_id')) {
      context.handle(
        _dependsOnOperationIdMeta,
        dependsOnOperationId.isAcceptableOrUnknown(
          data['depends_on_operation_id']!,
          _dependsOnOperationIdMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  OutboxOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxOperationRow(
      operationId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}operation_id'],
          )!,
      channelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_id'],
          )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      operationType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}operation_type'],
          )!,
      payloadJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload_json'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      coalesceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coalesce_key'],
      ),
      dependsOnOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on_operation_id'],
      ),
      attemptCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}attempt_count'],
          )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $OutboxOperationsTable createAlias(String alias) {
    return $OutboxOperationsTable(attachedDatabase, alias);
  }
}

class OutboxOperationRow extends DataClass
    implements Insertable<OutboxOperationRow> {
  final String operationId;
  final String channelId;
  final String? entityId;
  final String operationType;
  final String payloadJson;
  final String status;
  final String? coalesceKey;
  final String? dependsOnOperationId;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OutboxOperationRow({
    required this.operationId,
    required this.channelId,
    this.entityId,
    required this.operationType,
    required this.payloadJson,
    required this.status,
    this.coalesceKey,
    this.dependsOnOperationId,
    required this.attemptCount,
    this.nextAttemptAt,
    this.lastErrorCode,
    this.lastErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['channel_id'] = Variable<String>(channelId);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || coalesceKey != null) {
      map['coalesce_key'] = Variable<String>(coalesceKey);
    }
    if (!nullToAbsent || dependsOnOperationId != null) {
      map['depends_on_operation_id'] = Variable<String>(dependsOnOperationId);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxOperationsCompanion toCompanion(bool nullToAbsent) {
    return OutboxOperationsCompanion(
      operationId: Value(operationId),
      channelId: Value(channelId),
      entityId:
          entityId == null && nullToAbsent
              ? const Value.absent()
              : Value(entityId),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      coalesceKey:
          coalesceKey == null && nullToAbsent
              ? const Value.absent()
              : Value(coalesceKey),
      dependsOnOperationId:
          dependsOnOperationId == null && nullToAbsent
              ? const Value.absent()
              : Value(dependsOnOperationId),
      attemptCount: Value(attemptCount),
      nextAttemptAt:
          nextAttemptAt == null && nullToAbsent
              ? const Value.absent()
              : Value(nextAttemptAt),
      lastErrorCode:
          lastErrorCode == null && nullToAbsent
              ? const Value.absent()
              : Value(lastErrorCode),
      lastErrorMessage:
          lastErrorMessage == null && nullToAbsent
              ? const Value.absent()
              : Value(lastErrorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxOperationRow(
      operationId: serializer.fromJson<String>(json['operationId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      coalesceKey: serializer.fromJson<String?>(json['coalesceKey']),
      dependsOnOperationId: serializer.fromJson<String?>(
        json['dependsOnOperationId'],
      ),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'channelId': serializer.toJson<String>(channelId),
      'entityId': serializer.toJson<String?>(entityId),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'coalesceKey': serializer.toJson<String?>(coalesceKey),
      'dependsOnOperationId': serializer.toJson<String?>(dependsOnOperationId),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxOperationRow copyWith({
    String? operationId,
    String? channelId,
    Value<String?> entityId = const Value.absent(),
    String? operationType,
    String? payloadJson,
    String? status,
    Value<String?> coalesceKey = const Value.absent(),
    Value<String?> dependsOnOperationId = const Value.absent(),
    int? attemptCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> lastErrorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OutboxOperationRow(
    operationId: operationId ?? this.operationId,
    channelId: channelId ?? this.channelId,
    entityId: entityId.present ? entityId.value : this.entityId,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    coalesceKey: coalesceKey.present ? coalesceKey.value : this.coalesceKey,
    dependsOnOperationId:
        dependsOnOperationId.present
            ? dependsOnOperationId.value
            : this.dependsOnOperationId,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptAt:
        nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
    lastErrorCode:
        lastErrorCode.present ? lastErrorCode.value : this.lastErrorCode,
    lastErrorMessage:
        lastErrorMessage.present
            ? lastErrorMessage.value
            : this.lastErrorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OutboxOperationRow copyWithCompanion(OutboxOperationsCompanion data) {
    return OutboxOperationRow(
      operationId:
          data.operationId.present ? data.operationId.value : this.operationId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operationType:
          data.operationType.present
              ? data.operationType.value
              : this.operationType,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      coalesceKey:
          data.coalesceKey.present ? data.coalesceKey.value : this.coalesceKey,
      dependsOnOperationId:
          data.dependsOnOperationId.present
              ? data.dependsOnOperationId.value
              : this.dependsOnOperationId,
      attemptCount:
          data.attemptCount.present
              ? data.attemptCount.value
              : this.attemptCount,
      nextAttemptAt:
          data.nextAttemptAt.present
              ? data.nextAttemptAt.value
              : this.nextAttemptAt,
      lastErrorCode:
          data.lastErrorCode.present
              ? data.lastErrorCode.value
              : this.lastErrorCode,
      lastErrorMessage:
          data.lastErrorMessage.present
              ? data.lastErrorMessage.value
              : this.lastErrorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperationRow(')
          ..write('operationId: $operationId, ')
          ..write('channelId: $channelId, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('coalesceKey: $coalesceKey, ')
          ..write('dependsOnOperationId: $dependsOnOperationId, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    channelId,
    entityId,
    operationType,
    payloadJson,
    status,
    coalesceKey,
    dependsOnOperationId,
    attemptCount,
    nextAttemptAt,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxOperationRow &&
          other.operationId == this.operationId &&
          other.channelId == this.channelId &&
          other.entityId == this.entityId &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.coalesceKey == this.coalesceKey &&
          other.dependsOnOperationId == this.dependsOnOperationId &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxOperationsCompanion extends UpdateCompanion<OutboxOperationRow> {
  final Value<String> operationId;
  final Value<String> channelId;
  final Value<String?> entityId;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<String?> coalesceKey;
  final Value<String?> dependsOnOperationId;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastErrorCode;
  final Value<String?> lastErrorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutboxOperationsCompanion({
    this.operationId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.coalesceKey = const Value.absent(),
    this.dependsOnOperationId = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxOperationsCompanion.insert({
    required String operationId,
    required String channelId,
    this.entityId = const Value.absent(),
    required String operationType,
    required String payloadJson,
    this.status = const Value.absent(),
    this.coalesceKey = const Value.absent(),
    this.dependsOnOperationId = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       channelId = Value(channelId),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OutboxOperationRow> custom({
    Expression<String>? operationId,
    Expression<String>? channelId,
    Expression<String>? entityId,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<String>? coalesceKey,
    Expression<String>? dependsOnOperationId,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastErrorCode,
    Expression<String>? lastErrorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (channelId != null) 'channel_id': channelId,
      if (entityId != null) 'entity_id': entityId,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (coalesceKey != null) 'coalesce_key': coalesceKey,
      if (dependsOnOperationId != null)
        'depends_on_operation_id': dependsOnOperationId,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxOperationsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? channelId,
    Value<String?>? entityId,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<String?>? coalesceKey,
    Value<String?>? dependsOnOperationId,
    Value<int>? attemptCount,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastErrorCode,
    Value<String?>? lastErrorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OutboxOperationsCompanion(
      operationId: operationId ?? this.operationId,
      channelId: channelId ?? this.channelId,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      coalesceKey: coalesceKey ?? this.coalesceKey,
      dependsOnOperationId: dependsOnOperationId ?? this.dependsOnOperationId,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (coalesceKey.present) {
      map['coalesce_key'] = Variable<String>(coalesceKey.value);
    }
    if (dependsOnOperationId.present) {
      map['depends_on_operation_id'] = Variable<String>(
        dependsOnOperationId.value,
      );
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperationsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('channelId: $channelId, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('coalesceKey: $coalesceKey, ')
          ..write('dependsOnOperationId: $dependsOnOperationId, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelSyncStatesTable extends ChannelSyncStates
    with TableInfo<$ChannelSyncStatesTable, ChannelSyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newestSyncedMessageSeqMeta =
      const VerificationMeta('newestSyncedMessageSeq');
  @override
  late final GeneratedColumn<int> newestSyncedMessageSeq = GeneratedColumn<int>(
    'newest_synced_message_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newestAppliedChangeSeqMeta =
      const VerificationMeta('newestAppliedChangeSeq');
  @override
  late final GeneratedColumn<int> newestAppliedChangeSeq = GeneratedColumn<int>(
    'newest_applied_change_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oldestCachedMessageSeqMeta =
      const VerificationMeta('oldestCachedMessageSeq');
  @override
  late final GeneratedColumn<int> oldestCachedMessageSeq = GeneratedColumn<int>(
    'oldest_cached_message_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasMoreHistoryMeta = const VerificationMeta(
    'hasMoreHistory',
  );
  @override
  late final GeneratedColumn<bool> hasMoreHistory = GeneratedColumn<bool>(
    'has_more_history',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_more_history" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastMemberSyncAtMeta = const VerificationMeta(
    'lastMemberSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMemberSyncAt =
      GeneratedColumn<DateTime>(
        'last_member_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastFullSyncAtMeta = const VerificationMeta(
    'lastFullSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFullSyncAt =
      GeneratedColumn<DateTime>(
        'last_full_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idle'),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    newestSyncedMessageSeq,
    newestAppliedChangeSeq,
    oldestCachedMessageSeq,
    hasMoreHistory,
    lastMemberSyncAt,
    lastFullSyncAt,
    syncStatus,
    lastSyncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelSyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('newest_synced_message_seq')) {
      context.handle(
        _newestSyncedMessageSeqMeta,
        newestSyncedMessageSeq.isAcceptableOrUnknown(
          data['newest_synced_message_seq']!,
          _newestSyncedMessageSeqMeta,
        ),
      );
    }
    if (data.containsKey('newest_applied_change_seq')) {
      context.handle(
        _newestAppliedChangeSeqMeta,
        newestAppliedChangeSeq.isAcceptableOrUnknown(
          data['newest_applied_change_seq']!,
          _newestAppliedChangeSeqMeta,
        ),
      );
    }
    if (data.containsKey('oldest_cached_message_seq')) {
      context.handle(
        _oldestCachedMessageSeqMeta,
        oldestCachedMessageSeq.isAcceptableOrUnknown(
          data['oldest_cached_message_seq']!,
          _oldestCachedMessageSeqMeta,
        ),
      );
    }
    if (data.containsKey('has_more_history')) {
      context.handle(
        _hasMoreHistoryMeta,
        hasMoreHistory.isAcceptableOrUnknown(
          data['has_more_history']!,
          _hasMoreHistoryMeta,
        ),
      );
    }
    if (data.containsKey('last_member_sync_at')) {
      context.handle(
        _lastMemberSyncAtMeta,
        lastMemberSyncAt.isAcceptableOrUnknown(
          data['last_member_sync_at']!,
          _lastMemberSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_full_sync_at')) {
      context.handle(
        _lastFullSyncAtMeta,
        lastFullSyncAt.isAcceptableOrUnknown(
          data['last_full_sync_at']!,
          _lastFullSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  ChannelSyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelSyncStateRow(
      channelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_id'],
          )!,
      newestSyncedMessageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}newest_synced_message_seq'],
      ),
      newestAppliedChangeSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}newest_applied_change_seq'],
      ),
      oldestCachedMessageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}oldest_cached_message_seq'],
      ),
      hasMoreHistory:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}has_more_history'],
          )!,
      lastMemberSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_member_sync_at'],
      ),
      lastFullSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_full_sync_at'],
      ),
      syncStatus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_status'],
          )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
    );
  }

  @override
  $ChannelSyncStatesTable createAlias(String alias) {
    return $ChannelSyncStatesTable(attachedDatabase, alias);
  }
}

class ChannelSyncStateRow extends DataClass
    implements Insertable<ChannelSyncStateRow> {
  final String channelId;
  final int? newestSyncedMessageSeq;
  final int? newestAppliedChangeSeq;
  final int? oldestCachedMessageSeq;
  final bool hasMoreHistory;
  final DateTime? lastMemberSyncAt;
  final DateTime? lastFullSyncAt;
  final String syncStatus;
  final String? lastSyncError;
  const ChannelSyncStateRow({
    required this.channelId,
    this.newestSyncedMessageSeq,
    this.newestAppliedChangeSeq,
    this.oldestCachedMessageSeq,
    required this.hasMoreHistory,
    this.lastMemberSyncAt,
    this.lastFullSyncAt,
    required this.syncStatus,
    this.lastSyncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    if (!nullToAbsent || newestSyncedMessageSeq != null) {
      map['newest_synced_message_seq'] = Variable<int>(newestSyncedMessageSeq);
    }
    if (!nullToAbsent || newestAppliedChangeSeq != null) {
      map['newest_applied_change_seq'] = Variable<int>(newestAppliedChangeSeq);
    }
    if (!nullToAbsent || oldestCachedMessageSeq != null) {
      map['oldest_cached_message_seq'] = Variable<int>(oldestCachedMessageSeq);
    }
    map['has_more_history'] = Variable<bool>(hasMoreHistory);
    if (!nullToAbsent || lastMemberSyncAt != null) {
      map['last_member_sync_at'] = Variable<DateTime>(lastMemberSyncAt);
    }
    if (!nullToAbsent || lastFullSyncAt != null) {
      map['last_full_sync_at'] = Variable<DateTime>(lastFullSyncAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  ChannelSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return ChannelSyncStatesCompanion(
      channelId: Value(channelId),
      newestSyncedMessageSeq:
          newestSyncedMessageSeq == null && nullToAbsent
              ? const Value.absent()
              : Value(newestSyncedMessageSeq),
      newestAppliedChangeSeq:
          newestAppliedChangeSeq == null && nullToAbsent
              ? const Value.absent()
              : Value(newestAppliedChangeSeq),
      oldestCachedMessageSeq:
          oldestCachedMessageSeq == null && nullToAbsent
              ? const Value.absent()
              : Value(oldestCachedMessageSeq),
      hasMoreHistory: Value(hasMoreHistory),
      lastMemberSyncAt:
          lastMemberSyncAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMemberSyncAt),
      lastFullSyncAt:
          lastFullSyncAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastFullSyncAt),
      syncStatus: Value(syncStatus),
      lastSyncError:
          lastSyncError == null && nullToAbsent
              ? const Value.absent()
              : Value(lastSyncError),
    );
  }

  factory ChannelSyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelSyncStateRow(
      channelId: serializer.fromJson<String>(json['channelId']),
      newestSyncedMessageSeq: serializer.fromJson<int?>(
        json['newestSyncedMessageSeq'],
      ),
      newestAppliedChangeSeq: serializer.fromJson<int?>(
        json['newestAppliedChangeSeq'],
      ),
      oldestCachedMessageSeq: serializer.fromJson<int?>(
        json['oldestCachedMessageSeq'],
      ),
      hasMoreHistory: serializer.fromJson<bool>(json['hasMoreHistory']),
      lastMemberSyncAt: serializer.fromJson<DateTime?>(
        json['lastMemberSyncAt'],
      ),
      lastFullSyncAt: serializer.fromJson<DateTime?>(json['lastFullSyncAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'newestSyncedMessageSeq': serializer.toJson<int?>(newestSyncedMessageSeq),
      'newestAppliedChangeSeq': serializer.toJson<int?>(newestAppliedChangeSeq),
      'oldestCachedMessageSeq': serializer.toJson<int?>(oldestCachedMessageSeq),
      'hasMoreHistory': serializer.toJson<bool>(hasMoreHistory),
      'lastMemberSyncAt': serializer.toJson<DateTime?>(lastMemberSyncAt),
      'lastFullSyncAt': serializer.toJson<DateTime?>(lastFullSyncAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  ChannelSyncStateRow copyWith({
    String? channelId,
    Value<int?> newestSyncedMessageSeq = const Value.absent(),
    Value<int?> newestAppliedChangeSeq = const Value.absent(),
    Value<int?> oldestCachedMessageSeq = const Value.absent(),
    bool? hasMoreHistory,
    Value<DateTime?> lastMemberSyncAt = const Value.absent(),
    Value<DateTime?> lastFullSyncAt = const Value.absent(),
    String? syncStatus,
    Value<String?> lastSyncError = const Value.absent(),
  }) => ChannelSyncStateRow(
    channelId: channelId ?? this.channelId,
    newestSyncedMessageSeq:
        newestSyncedMessageSeq.present
            ? newestSyncedMessageSeq.value
            : this.newestSyncedMessageSeq,
    newestAppliedChangeSeq:
        newestAppliedChangeSeq.present
            ? newestAppliedChangeSeq.value
            : this.newestAppliedChangeSeq,
    oldestCachedMessageSeq:
        oldestCachedMessageSeq.present
            ? oldestCachedMessageSeq.value
            : this.oldestCachedMessageSeq,
    hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
    lastMemberSyncAt:
        lastMemberSyncAt.present
            ? lastMemberSyncAt.value
            : this.lastMemberSyncAt,
    lastFullSyncAt:
        lastFullSyncAt.present ? lastFullSyncAt.value : this.lastFullSyncAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncError:
        lastSyncError.present ? lastSyncError.value : this.lastSyncError,
  );
  ChannelSyncStateRow copyWithCompanion(ChannelSyncStatesCompanion data) {
    return ChannelSyncStateRow(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      newestSyncedMessageSeq:
          data.newestSyncedMessageSeq.present
              ? data.newestSyncedMessageSeq.value
              : this.newestSyncedMessageSeq,
      newestAppliedChangeSeq:
          data.newestAppliedChangeSeq.present
              ? data.newestAppliedChangeSeq.value
              : this.newestAppliedChangeSeq,
      oldestCachedMessageSeq:
          data.oldestCachedMessageSeq.present
              ? data.oldestCachedMessageSeq.value
              : this.oldestCachedMessageSeq,
      hasMoreHistory:
          data.hasMoreHistory.present
              ? data.hasMoreHistory.value
              : this.hasMoreHistory,
      lastMemberSyncAt:
          data.lastMemberSyncAt.present
              ? data.lastMemberSyncAt.value
              : this.lastMemberSyncAt,
      lastFullSyncAt:
          data.lastFullSyncAt.present
              ? data.lastFullSyncAt.value
              : this.lastFullSyncAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      lastSyncError:
          data.lastSyncError.present
              ? data.lastSyncError.value
              : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelSyncStateRow(')
          ..write('channelId: $channelId, ')
          ..write('newestSyncedMessageSeq: $newestSyncedMessageSeq, ')
          ..write('newestAppliedChangeSeq: $newestAppliedChangeSeq, ')
          ..write('oldestCachedMessageSeq: $oldestCachedMessageSeq, ')
          ..write('hasMoreHistory: $hasMoreHistory, ')
          ..write('lastMemberSyncAt: $lastMemberSyncAt, ')
          ..write('lastFullSyncAt: $lastFullSyncAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    channelId,
    newestSyncedMessageSeq,
    newestAppliedChangeSeq,
    oldestCachedMessageSeq,
    hasMoreHistory,
    lastMemberSyncAt,
    lastFullSyncAt,
    syncStatus,
    lastSyncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelSyncStateRow &&
          other.channelId == this.channelId &&
          other.newestSyncedMessageSeq == this.newestSyncedMessageSeq &&
          other.newestAppliedChangeSeq == this.newestAppliedChangeSeq &&
          other.oldestCachedMessageSeq == this.oldestCachedMessageSeq &&
          other.hasMoreHistory == this.hasMoreHistory &&
          other.lastMemberSyncAt == this.lastMemberSyncAt &&
          other.lastFullSyncAt == this.lastFullSyncAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncError == this.lastSyncError);
}

class ChannelSyncStatesCompanion extends UpdateCompanion<ChannelSyncStateRow> {
  final Value<String> channelId;
  final Value<int?> newestSyncedMessageSeq;
  final Value<int?> newestAppliedChangeSeq;
  final Value<int?> oldestCachedMessageSeq;
  final Value<bool> hasMoreHistory;
  final Value<DateTime?> lastMemberSyncAt;
  final Value<DateTime?> lastFullSyncAt;
  final Value<String> syncStatus;
  final Value<String?> lastSyncError;
  final Value<int> rowid;
  const ChannelSyncStatesCompanion({
    this.channelId = const Value.absent(),
    this.newestSyncedMessageSeq = const Value.absent(),
    this.newestAppliedChangeSeq = const Value.absent(),
    this.oldestCachedMessageSeq = const Value.absent(),
    this.hasMoreHistory = const Value.absent(),
    this.lastMemberSyncAt = const Value.absent(),
    this.lastFullSyncAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelSyncStatesCompanion.insert({
    required String channelId,
    this.newestSyncedMessageSeq = const Value.absent(),
    this.newestAppliedChangeSeq = const Value.absent(),
    this.oldestCachedMessageSeq = const Value.absent(),
    this.hasMoreHistory = const Value.absent(),
    this.lastMemberSyncAt = const Value.absent(),
    this.lastFullSyncAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId);
  static Insertable<ChannelSyncStateRow> custom({
    Expression<String>? channelId,
    Expression<int>? newestSyncedMessageSeq,
    Expression<int>? newestAppliedChangeSeq,
    Expression<int>? oldestCachedMessageSeq,
    Expression<bool>? hasMoreHistory,
    Expression<DateTime>? lastMemberSyncAt,
    Expression<DateTime>? lastFullSyncAt,
    Expression<String>? syncStatus,
    Expression<String>? lastSyncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (newestSyncedMessageSeq != null)
        'newest_synced_message_seq': newestSyncedMessageSeq,
      if (newestAppliedChangeSeq != null)
        'newest_applied_change_seq': newestAppliedChangeSeq,
      if (oldestCachedMessageSeq != null)
        'oldest_cached_message_seq': oldestCachedMessageSeq,
      if (hasMoreHistory != null) 'has_more_history': hasMoreHistory,
      if (lastMemberSyncAt != null) 'last_member_sync_at': lastMemberSyncAt,
      if (lastFullSyncAt != null) 'last_full_sync_at': lastFullSyncAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelSyncStatesCompanion copyWith({
    Value<String>? channelId,
    Value<int?>? newestSyncedMessageSeq,
    Value<int?>? newestAppliedChangeSeq,
    Value<int?>? oldestCachedMessageSeq,
    Value<bool>? hasMoreHistory,
    Value<DateTime?>? lastMemberSyncAt,
    Value<DateTime?>? lastFullSyncAt,
    Value<String>? syncStatus,
    Value<String?>? lastSyncError,
    Value<int>? rowid,
  }) {
    return ChannelSyncStatesCompanion(
      channelId: channelId ?? this.channelId,
      newestSyncedMessageSeq:
          newestSyncedMessageSeq ?? this.newestSyncedMessageSeq,
      newestAppliedChangeSeq:
          newestAppliedChangeSeq ?? this.newestAppliedChangeSeq,
      oldestCachedMessageSeq:
          oldestCachedMessageSeq ?? this.oldestCachedMessageSeq,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      lastMemberSyncAt: lastMemberSyncAt ?? this.lastMemberSyncAt,
      lastFullSyncAt: lastFullSyncAt ?? this.lastFullSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (newestSyncedMessageSeq.present) {
      map['newest_synced_message_seq'] = Variable<int>(
        newestSyncedMessageSeq.value,
      );
    }
    if (newestAppliedChangeSeq.present) {
      map['newest_applied_change_seq'] = Variable<int>(
        newestAppliedChangeSeq.value,
      );
    }
    if (oldestCachedMessageSeq.present) {
      map['oldest_cached_message_seq'] = Variable<int>(
        oldestCachedMessageSeq.value,
      );
    }
    if (hasMoreHistory.present) {
      map['has_more_history'] = Variable<bool>(hasMoreHistory.value);
    }
    if (lastMemberSyncAt.present) {
      map['last_member_sync_at'] = Variable<DateTime>(lastMemberSyncAt.value);
    }
    if (lastFullSyncAt.present) {
      map['last_full_sync_at'] = Variable<DateTime>(lastFullSyncAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelSyncStatesCompanion(')
          ..write('channelId: $channelId, ')
          ..write('newestSyncedMessageSeq: $newestSyncedMessageSeq, ')
          ..write('newestAppliedChangeSeq: $newestAppliedChangeSeq, ')
          ..write('oldestCachedMessageSeq: $oldestCachedMessageSeq, ')
          ..write('hasMoreHistory: $hasMoreHistory, ')
          ..write('lastMemberSyncAt: $lastMemberSyncAt, ')
          ..write('lastFullSyncAt: $lastFullSyncAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelDraftsTable extends ChannelDrafts
    with TableInfo<$ChannelDraftsTable, ChannelDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToMessageIdMeta = const VerificationMeta(
    'replyToMessageId',
  );
  @override
  late final GeneratedColumn<String> replyToMessageId = GeneratedColumn<String>(
    'reply_to_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    body,
    replyToMessageId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
        _replyToMessageIdMeta,
        replyToMessageId.isAcceptableOrUnknown(
          data['reply_to_message_id']!,
          _replyToMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  ChannelDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelDraftRow(
      channelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}channel_id'],
          )!,
      body:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}body'],
          )!,
      replyToMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_message_id'],
      ),
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $ChannelDraftsTable createAlias(String alias) {
    return $ChannelDraftsTable(attachedDatabase, alias);
  }
}

class ChannelDraftRow extends DataClass implements Insertable<ChannelDraftRow> {
  final String channelId;
  final String body;
  final String? replyToMessageId;
  final DateTime updatedAt;
  const ChannelDraftRow({
    required this.channelId,
    required this.body,
    this.replyToMessageId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || replyToMessageId != null) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChannelDraftsCompanion toCompanion(bool nullToAbsent) {
    return ChannelDraftsCompanion(
      channelId: Value(channelId),
      body: Value(body),
      replyToMessageId:
          replyToMessageId == null && nullToAbsent
              ? const Value.absent()
              : Value(replyToMessageId),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChannelDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelDraftRow(
      channelId: serializer.fromJson<String>(json['channelId']),
      body: serializer.fromJson<String>(json['body']),
      replyToMessageId: serializer.fromJson<String?>(json['replyToMessageId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'body': serializer.toJson<String>(body),
      'replyToMessageId': serializer.toJson<String?>(replyToMessageId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChannelDraftRow copyWith({
    String? channelId,
    String? body,
    Value<String?> replyToMessageId = const Value.absent(),
    DateTime? updatedAt,
  }) => ChannelDraftRow(
    channelId: channelId ?? this.channelId,
    body: body ?? this.body,
    replyToMessageId:
        replyToMessageId.present
            ? replyToMessageId.value
            : this.replyToMessageId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChannelDraftRow copyWithCompanion(ChannelDraftsCompanion data) {
    return ChannelDraftRow(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      body: data.body.present ? data.body.value : this.body,
      replyToMessageId:
          data.replyToMessageId.present
              ? data.replyToMessageId.value
              : this.replyToMessageId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelDraftRow(')
          ..write('channelId: $channelId, ')
          ..write('body: $body, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(channelId, body, replyToMessageId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelDraftRow &&
          other.channelId == this.channelId &&
          other.body == this.body &&
          other.replyToMessageId == this.replyToMessageId &&
          other.updatedAt == this.updatedAt);
}

class ChannelDraftsCompanion extends UpdateCompanion<ChannelDraftRow> {
  final Value<String> channelId;
  final Value<String> body;
  final Value<String?> replyToMessageId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChannelDraftsCompanion({
    this.channelId = const Value.absent(),
    this.body = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelDraftsCompanion.insert({
    required String channelId,
    required String body,
    this.replyToMessageId = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       body = Value(body),
       updatedAt = Value(updatedAt);
  static Insertable<ChannelDraftRow> custom({
    Expression<String>? channelId,
    Expression<String>? body,
    Expression<String>? replyToMessageId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (body != null) 'body': body,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelDraftsCompanion copyWith({
    Value<String>? channelId,
    Value<String>? body,
    Value<String?>? replyToMessageId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChannelDraftsCompanion(
      channelId: channelId ?? this.channelId,
      body: body ?? this.body,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelDraftsCompanion(')
          ..write('channelId: $channelId, ')
          ..write('body: $body, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoringOpsTable extends ScoringOps
    with TableInfo<$ScoringOpsTable, ScoringOpRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoringOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inningsNumberMeta = const VerificationMeta(
    'inningsNumber',
  );
  @override
  late final GeneratedColumn<int> inningsNumber = GeneratedColumn<int>(
    'innings_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSeqMeta = const VerificationMeta(
    'localSeq',
  );
  @override
  late final GeneratedColumn<int> localSeq = GeneratedColumn<int>(
    'local_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ball'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refusedAtMeta = const VerificationMeta(
    'refusedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refusedAt = GeneratedColumn<DateTime>(
    'refused_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    matchId,
    inningsNumber,
    localSeq,
    kind,
    payload,
    createdAt,
    syncedAt,
    refusedAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scoring_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoringOpRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('innings_number')) {
      context.handle(
        _inningsNumberMeta,
        inningsNumber.isAcceptableOrUnknown(
          data['innings_number']!,
          _inningsNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inningsNumberMeta);
    }
    if (data.containsKey('local_seq')) {
      context.handle(
        _localSeqMeta,
        localSeq.isAcceptableOrUnknown(data['local_seq']!, _localSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_localSeqMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('refused_at')) {
      context.handle(
        _refusedAtMeta,
        refusedAt.isAcceptableOrUnknown(data['refused_at']!, _refusedAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  ScoringOpRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoringOpRow(
      opId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}op_id'],
          )!,
      matchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}match_id'],
          )!,
      inningsNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}innings_number'],
          )!,
      localSeq:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}local_seq'],
          )!,
      kind:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}kind'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      refusedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refused_at'],
      ),
      attempts:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}attempts'],
          )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $ScoringOpsTable createAlias(String alias) {
    return $ScoringOpsTable(attachedDatabase, alias);
  }
}

class ScoringOpRow extends DataClass implements Insertable<ScoringOpRow> {
  final String opId;
  final String matchId;
  final int inningsNumber;
  final int localSeq;
  final String kind;
  final String payload;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final DateTime? refusedAt;
  final int attempts;
  final String? lastError;
  const ScoringOpRow({
    required this.opId,
    required this.matchId,
    required this.inningsNumber,
    required this.localSeq,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.syncedAt,
    this.refusedAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['match_id'] = Variable<String>(matchId);
    map['innings_number'] = Variable<int>(inningsNumber);
    map['local_seq'] = Variable<int>(localSeq);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || refusedAt != null) {
      map['refused_at'] = Variable<DateTime>(refusedAt);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  ScoringOpsCompanion toCompanion(bool nullToAbsent) {
    return ScoringOpsCompanion(
      opId: Value(opId),
      matchId: Value(matchId),
      inningsNumber: Value(inningsNumber),
      localSeq: Value(localSeq),
      kind: Value(kind),
      payload: Value(payload),
      createdAt: Value(createdAt),
      syncedAt:
          syncedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(syncedAt),
      refusedAt:
          refusedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(refusedAt),
      attempts: Value(attempts),
      lastError:
          lastError == null && nullToAbsent
              ? const Value.absent()
              : Value(lastError),
    );
  }

  factory ScoringOpRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoringOpRow(
      opId: serializer.fromJson<String>(json['opId']),
      matchId: serializer.fromJson<String>(json['matchId']),
      inningsNumber: serializer.fromJson<int>(json['inningsNumber']),
      localSeq: serializer.fromJson<int>(json['localSeq']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      refusedAt: serializer.fromJson<DateTime?>(json['refusedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'matchId': serializer.toJson<String>(matchId),
      'inningsNumber': serializer.toJson<int>(inningsNumber),
      'localSeq': serializer.toJson<int>(localSeq),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'refusedAt': serializer.toJson<DateTime?>(refusedAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  ScoringOpRow copyWith({
    String? opId,
    String? matchId,
    int? inningsNumber,
    int? localSeq,
    String? kind,
    String? payload,
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> refusedAt = const Value.absent(),
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => ScoringOpRow(
    opId: opId ?? this.opId,
    matchId: matchId ?? this.matchId,
    inningsNumber: inningsNumber ?? this.inningsNumber,
    localSeq: localSeq ?? this.localSeq,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    refusedAt: refusedAt.present ? refusedAt.value : this.refusedAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  ScoringOpRow copyWithCompanion(ScoringOpsCompanion data) {
    return ScoringOpRow(
      opId: data.opId.present ? data.opId.value : this.opId,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      inningsNumber:
          data.inningsNumber.present
              ? data.inningsNumber.value
              : this.inningsNumber,
      localSeq: data.localSeq.present ? data.localSeq.value : this.localSeq,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      refusedAt: data.refusedAt.present ? data.refusedAt.value : this.refusedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoringOpRow(')
          ..write('opId: $opId, ')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('localSeq: $localSeq, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('refusedAt: $refusedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    matchId,
    inningsNumber,
    localSeq,
    kind,
    payload,
    createdAt,
    syncedAt,
    refusedAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoringOpRow &&
          other.opId == this.opId &&
          other.matchId == this.matchId &&
          other.inningsNumber == this.inningsNumber &&
          other.localSeq == this.localSeq &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.refusedAt == this.refusedAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class ScoringOpsCompanion extends UpdateCompanion<ScoringOpRow> {
  final Value<String> opId;
  final Value<String> matchId;
  final Value<int> inningsNumber;
  final Value<int> localSeq;
  final Value<String> kind;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> refusedAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const ScoringOpsCompanion({
    this.opId = const Value.absent(),
    this.matchId = const Value.absent(),
    this.inningsNumber = const Value.absent(),
    this.localSeq = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.refusedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoringOpsCompanion.insert({
    required String opId,
    required String matchId,
    required int inningsNumber,
    required int localSeq,
    this.kind = const Value.absent(),
    required String payload,
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.refusedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       matchId = Value(matchId),
       inningsNumber = Value(inningsNumber),
       localSeq = Value(localSeq),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<ScoringOpRow> custom({
    Expression<String>? opId,
    Expression<String>? matchId,
    Expression<int>? inningsNumber,
    Expression<int>? localSeq,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? refusedAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (matchId != null) 'match_id': matchId,
      if (inningsNumber != null) 'innings_number': inningsNumber,
      if (localSeq != null) 'local_seq': localSeq,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (refusedAt != null) 'refused_at': refusedAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoringOpsCompanion copyWith({
    Value<String>? opId,
    Value<String>? matchId,
    Value<int>? inningsNumber,
    Value<int>? localSeq,
    Value<String>? kind,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? refusedAt,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return ScoringOpsCompanion(
      opId: opId ?? this.opId,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      localSeq: localSeq ?? this.localSeq,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      refusedAt: refusedAt ?? this.refusedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (inningsNumber.present) {
      map['innings_number'] = Variable<int>(inningsNumber.value);
    }
    if (localSeq.present) {
      map['local_seq'] = Variable<int>(localSeq.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (refusedAt.present) {
      map['refused_at'] = Variable<DateTime>(refusedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoringOpsCompanion(')
          ..write('opId: $opId, ')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('localSeq: $localSeq, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('refusedAt: $refusedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoringSnapshotsTable extends ScoringSnapshots
    with TableInfo<$ScoringSnapshotsTable, ScoringSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoringSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inningsNumberMeta = const VerificationMeta(
    'inningsNumber',
  );
  @override
  late final GeneratedColumn<int> inningsNumber = GeneratedColumn<int>(
    'innings_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _throughSeqMeta = const VerificationMeta(
    'throughSeq',
  );
  @override
  late final GeneratedColumn<int> throughSeq = GeneratedColumn<int>(
    'through_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    matchId,
    inningsNumber,
    state,
    throughSeq,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scoring_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoringSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('innings_number')) {
      context.handle(
        _inningsNumberMeta,
        inningsNumber.isAcceptableOrUnknown(
          data['innings_number']!,
          _inningsNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inningsNumberMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('through_seq')) {
      context.handle(
        _throughSeqMeta,
        throughSeq.isAcceptableOrUnknown(data['through_seq']!, _throughSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_throughSeqMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId, inningsNumber};
  @override
  ScoringSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoringSnapshotRow(
      matchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}match_id'],
          )!,
      inningsNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}innings_number'],
          )!,
      state:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}state'],
          )!,
      throughSeq:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}through_seq'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $ScoringSnapshotsTable createAlias(String alias) {
    return $ScoringSnapshotsTable(attachedDatabase, alias);
  }
}

class ScoringSnapshotRow extends DataClass
    implements Insertable<ScoringSnapshotRow> {
  final String matchId;
  final int inningsNumber;
  final String state;
  final int throughSeq;
  final DateTime updatedAt;
  const ScoringSnapshotRow({
    required this.matchId,
    required this.inningsNumber,
    required this.state,
    required this.throughSeq,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    map['innings_number'] = Variable<int>(inningsNumber);
    map['state'] = Variable<String>(state);
    map['through_seq'] = Variable<int>(throughSeq);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScoringSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return ScoringSnapshotsCompanion(
      matchId: Value(matchId),
      inningsNumber: Value(inningsNumber),
      state: Value(state),
      throughSeq: Value(throughSeq),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScoringSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoringSnapshotRow(
      matchId: serializer.fromJson<String>(json['matchId']),
      inningsNumber: serializer.fromJson<int>(json['inningsNumber']),
      state: serializer.fromJson<String>(json['state']),
      throughSeq: serializer.fromJson<int>(json['throughSeq']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'inningsNumber': serializer.toJson<int>(inningsNumber),
      'state': serializer.toJson<String>(state),
      'throughSeq': serializer.toJson<int>(throughSeq),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ScoringSnapshotRow copyWith({
    String? matchId,
    int? inningsNumber,
    String? state,
    int? throughSeq,
    DateTime? updatedAt,
  }) => ScoringSnapshotRow(
    matchId: matchId ?? this.matchId,
    inningsNumber: inningsNumber ?? this.inningsNumber,
    state: state ?? this.state,
    throughSeq: throughSeq ?? this.throughSeq,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScoringSnapshotRow copyWithCompanion(ScoringSnapshotsCompanion data) {
    return ScoringSnapshotRow(
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      inningsNumber:
          data.inningsNumber.present
              ? data.inningsNumber.value
              : this.inningsNumber,
      state: data.state.present ? data.state.value : this.state,
      throughSeq:
          data.throughSeq.present ? data.throughSeq.value : this.throughSeq,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoringSnapshotRow(')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('state: $state, ')
          ..write('throughSeq: $throughSeq, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(matchId, inningsNumber, state, throughSeq, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoringSnapshotRow &&
          other.matchId == this.matchId &&
          other.inningsNumber == this.inningsNumber &&
          other.state == this.state &&
          other.throughSeq == this.throughSeq &&
          other.updatedAt == this.updatedAt);
}

class ScoringSnapshotsCompanion extends UpdateCompanion<ScoringSnapshotRow> {
  final Value<String> matchId;
  final Value<int> inningsNumber;
  final Value<String> state;
  final Value<int> throughSeq;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ScoringSnapshotsCompanion({
    this.matchId = const Value.absent(),
    this.inningsNumber = const Value.absent(),
    this.state = const Value.absent(),
    this.throughSeq = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoringSnapshotsCompanion.insert({
    required String matchId,
    required int inningsNumber,
    required String state,
    required int throughSeq,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       inningsNumber = Value(inningsNumber),
       state = Value(state),
       throughSeq = Value(throughSeq),
       updatedAt = Value(updatedAt);
  static Insertable<ScoringSnapshotRow> custom({
    Expression<String>? matchId,
    Expression<int>? inningsNumber,
    Expression<String>? state,
    Expression<int>? throughSeq,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (inningsNumber != null) 'innings_number': inningsNumber,
      if (state != null) 'state': state,
      if (throughSeq != null) 'through_seq': throughSeq,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoringSnapshotsCompanion copyWith({
    Value<String>? matchId,
    Value<int>? inningsNumber,
    Value<String>? state,
    Value<int>? throughSeq,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScoringSnapshotsCompanion(
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      state: state ?? this.state,
      throughSeq: throughSeq ?? this.throughSeq,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (inningsNumber.present) {
      map['innings_number'] = Variable<int>(inningsNumber.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (throughSeq.present) {
      map['through_seq'] = Variable<int>(throughSeq.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoringSnapshotsCompanion(')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('state: $state, ')
          ..write('throughSeq: $throughSeq, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMatchesTable extends CachedMatches
    with TableInfo<$CachedMatchesTable, CachedMatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [matchId, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId};
  @override
  CachedMatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMatchRow(
      matchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}match_id'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CachedMatchesTable createAlias(String alias) {
    return $CachedMatchesTable(attachedDatabase, alias);
  }
}

class CachedMatchRow extends DataClass implements Insertable<CachedMatchRow> {
  final String matchId;
  final String payload;
  final DateTime updatedAt;
  const CachedMatchRow({
    required this.matchId,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMatchesCompanion toCompanion(bool nullToAbsent) {
    return CachedMatchesCompanion(
      matchId: Value(matchId),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedMatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMatchRow(
      matchId: serializer.fromJson<String>(json['matchId']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedMatchRow copyWith({
    String? matchId,
    String? payload,
    DateTime? updatedAt,
  }) => CachedMatchRow(
    matchId: matchId ?? this.matchId,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedMatchRow copyWithCompanion(CachedMatchesCompanion data) {
    return CachedMatchRow(
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMatchRow(')
          ..write('matchId: $matchId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(matchId, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMatchRow &&
          other.matchId == this.matchId &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class CachedMatchesCompanion extends UpdateCompanion<CachedMatchRow> {
  final Value<String> matchId;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedMatchesCompanion({
    this.matchId = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMatchesCompanion.insert({
    required String matchId,
    required String payload,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<CachedMatchRow> custom({
    Expression<String>? matchId,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMatchesCompanion copyWith({
    Value<String>? matchId,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedMatchesCompanion(
      matchId: matchId ?? this.matchId,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMatchesCompanion(')
          ..write('matchId: $matchId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMatchPlayersTable extends CachedMatchPlayers
    with TableInfo<$CachedMatchPlayersTable, CachedMatchPlayersRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMatchPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [matchId, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_match_players';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMatchPlayersRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId};
  @override
  CachedMatchPlayersRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMatchPlayersRow(
      matchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}match_id'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CachedMatchPlayersTable createAlias(String alias) {
    return $CachedMatchPlayersTable(attachedDatabase, alias);
  }
}

class CachedMatchPlayersRow extends DataClass
    implements Insertable<CachedMatchPlayersRow> {
  final String matchId;
  final String payload;
  final DateTime updatedAt;
  const CachedMatchPlayersRow({
    required this.matchId,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMatchPlayersCompanion toCompanion(bool nullToAbsent) {
    return CachedMatchPlayersCompanion(
      matchId: Value(matchId),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedMatchPlayersRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMatchPlayersRow(
      matchId: serializer.fromJson<String>(json['matchId']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedMatchPlayersRow copyWith({
    String? matchId,
    String? payload,
    DateTime? updatedAt,
  }) => CachedMatchPlayersRow(
    matchId: matchId ?? this.matchId,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedMatchPlayersRow copyWithCompanion(CachedMatchPlayersCompanion data) {
    return CachedMatchPlayersRow(
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMatchPlayersRow(')
          ..write('matchId: $matchId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(matchId, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMatchPlayersRow &&
          other.matchId == this.matchId &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class CachedMatchPlayersCompanion
    extends UpdateCompanion<CachedMatchPlayersRow> {
  final Value<String> matchId;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedMatchPlayersCompanion({
    this.matchId = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMatchPlayersCompanion.insert({
    required String matchId,
    required String payload,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<CachedMatchPlayersRow> custom({
    Expression<String>? matchId,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMatchPlayersCompanion copyWith({
    Value<String>? matchId,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedMatchPlayersCompanion(
      matchId: matchId ?? this.matchId,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMatchPlayersCompanion(')
          ..write('matchId: $matchId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedInningsStatesTable extends CachedInningsStates
    with TableInfo<$CachedInningsStatesTable, CachedInningsStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedInningsStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inningsNumberMeta = const VerificationMeta(
    'inningsNumber',
  );
  @override
  late final GeneratedColumn<int> inningsNumber = GeneratedColumn<int>(
    'innings_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    matchId,
    inningsNumber,
    payload,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_innings_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedInningsStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('innings_number')) {
      context.handle(
        _inningsNumberMeta,
        inningsNumber.isAcceptableOrUnknown(
          data['innings_number']!,
          _inningsNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inningsNumberMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId, inningsNumber};
  @override
  CachedInningsStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedInningsStateRow(
      matchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}match_id'],
          )!,
      inningsNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}innings_number'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CachedInningsStatesTable createAlias(String alias) {
    return $CachedInningsStatesTable(attachedDatabase, alias);
  }
}

class CachedInningsStateRow extends DataClass
    implements Insertable<CachedInningsStateRow> {
  final String matchId;
  final int inningsNumber;
  final String payload;
  final DateTime updatedAt;
  const CachedInningsStateRow({
    required this.matchId,
    required this.inningsNumber,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    map['innings_number'] = Variable<int>(inningsNumber);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedInningsStatesCompanion toCompanion(bool nullToAbsent) {
    return CachedInningsStatesCompanion(
      matchId: Value(matchId),
      inningsNumber: Value(inningsNumber),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedInningsStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedInningsStateRow(
      matchId: serializer.fromJson<String>(json['matchId']),
      inningsNumber: serializer.fromJson<int>(json['inningsNumber']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'inningsNumber': serializer.toJson<int>(inningsNumber),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedInningsStateRow copyWith({
    String? matchId,
    int? inningsNumber,
    String? payload,
    DateTime? updatedAt,
  }) => CachedInningsStateRow(
    matchId: matchId ?? this.matchId,
    inningsNumber: inningsNumber ?? this.inningsNumber,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedInningsStateRow copyWithCompanion(CachedInningsStatesCompanion data) {
    return CachedInningsStateRow(
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      inningsNumber:
          data.inningsNumber.present
              ? data.inningsNumber.value
              : this.inningsNumber,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedInningsStateRow(')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(matchId, inningsNumber, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedInningsStateRow &&
          other.matchId == this.matchId &&
          other.inningsNumber == this.inningsNumber &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class CachedInningsStatesCompanion
    extends UpdateCompanion<CachedInningsStateRow> {
  final Value<String> matchId;
  final Value<int> inningsNumber;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedInningsStatesCompanion({
    this.matchId = const Value.absent(),
    this.inningsNumber = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedInningsStatesCompanion.insert({
    required String matchId,
    required int inningsNumber,
    required String payload,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       inningsNumber = Value(inningsNumber),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<CachedInningsStateRow> custom({
    Expression<String>? matchId,
    Expression<int>? inningsNumber,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (inningsNumber != null) 'innings_number': inningsNumber,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedInningsStatesCompanion copyWith({
    Value<String>? matchId,
    Value<int>? inningsNumber,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedInningsStatesCompanion(
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (inningsNumber.present) {
      map['innings_number'] = Variable<int>(inningsNumber.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedInningsStatesCompanion(')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WizardDraftsTable wizardDrafts = $WizardDraftsTable(this);
  late final $LocalChannelsTable localChannels = $LocalChannelsTable(this);
  late final $LocalChannelMembersTable localChannelMembers =
      $LocalChannelMembersTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalMessageAttachmentsTable localMessageAttachments =
      $LocalMessageAttachmentsTable(this);
  late final $LocalMessageReactionsTable localMessageReactions =
      $LocalMessageReactionsTable(this);
  late final $LocalMemberRestrictionsTable localMemberRestrictions =
      $LocalMemberRestrictionsTable(this);
  late final $OutboxOperationsTable outboxOperations = $OutboxOperationsTable(
    this,
  );
  late final $ChannelSyncStatesTable channelSyncStates =
      $ChannelSyncStatesTable(this);
  late final $ChannelDraftsTable channelDrafts = $ChannelDraftsTable(this);
  late final $ScoringOpsTable scoringOps = $ScoringOpsTable(this);
  late final $ScoringSnapshotsTable scoringSnapshots = $ScoringSnapshotsTable(
    this,
  );
  late final $CachedMatchesTable cachedMatches = $CachedMatchesTable(this);
  late final $CachedMatchPlayersTable cachedMatchPlayers =
      $CachedMatchPlayersTable(this);
  late final $CachedInningsStatesTable cachedInningsStates =
      $CachedInningsStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wizardDrafts,
    localChannels,
    localChannelMembers,
    localMessages,
    localMessageAttachments,
    localMessageReactions,
    localMemberRestrictions,
    outboxOperations,
    channelSyncStates,
    channelDrafts,
    scoringOps,
    scoringSnapshots,
    cachedMatches,
    cachedMatchPlayers,
    cachedInningsStates,
  ];
}

typedef $$WizardDraftsTableCreateCompanionBuilder =
    WizardDraftsCompanion Function({
      required String key,
      required String payload,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WizardDraftsTableUpdateCompanionBuilder =
    WizardDraftsCompanion Function({
      Value<String> key,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WizardDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $WizardDraftsTable> {
  $$WizardDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WizardDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $WizardDraftsTable> {
  $$WizardDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WizardDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WizardDraftsTable> {
  $$WizardDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WizardDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WizardDraftsTable,
          WizardDraftRow,
          $$WizardDraftsTableFilterComposer,
          $$WizardDraftsTableOrderingComposer,
          $$WizardDraftsTableAnnotationComposer,
          $$WizardDraftsTableCreateCompanionBuilder,
          $$WizardDraftsTableUpdateCompanionBuilder,
          (
            WizardDraftRow,
            BaseReferences<_$AppDatabase, $WizardDraftsTable, WizardDraftRow>,
          ),
          WizardDraftRow,
          PrefetchHooks Function()
        > {
  $$WizardDraftsTableTableManager(_$AppDatabase db, $WizardDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$WizardDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$WizardDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$WizardDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WizardDraftsCompanion(
                key: key,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String payload,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WizardDraftsCompanion.insert(
                key: key,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WizardDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WizardDraftsTable,
      WizardDraftRow,
      $$WizardDraftsTableFilterComposer,
      $$WizardDraftsTableOrderingComposer,
      $$WizardDraftsTableAnnotationComposer,
      $$WizardDraftsTableCreateCompanionBuilder,
      $$WizardDraftsTableUpdateCompanionBuilder,
      (
        WizardDraftRow,
        BaseReferences<_$AppDatabase, $WizardDraftsTable, WizardDraftRow>,
      ),
      WizardDraftRow,
      PrefetchHooks Function()
    >;
typedef $$LocalChannelsTableCreateCompanionBuilder =
    LocalChannelsCompanion Function({
      required String channelId,
      required String channelKey,
      required String kind,
      required String contextType,
      Value<String> visibility,
      Value<String> purpose,
      Value<String?> title,
      Value<String?> description,
      Value<String?> avatarUrl,
      Value<String?> teamId,
      Value<String?> matchId,
      Value<String?> tournamentId,
      Value<String?> clubId,
      Value<int?> lastMessageSeq,
      Value<DateTime?> lastMessageAt,
      Value<String?> lastMessagePreview,
      Value<String?> lastMessageSenderId,
      Value<bool> lastMessageFromMe,
      Value<int> unreadCount,
      required DateTime serverUpdatedAt,
      required DateTime localUpdatedAt,
      Value<int> rowid,
    });
typedef $$LocalChannelsTableUpdateCompanionBuilder =
    LocalChannelsCompanion Function({
      Value<String> channelId,
      Value<String> channelKey,
      Value<String> kind,
      Value<String> contextType,
      Value<String> visibility,
      Value<String> purpose,
      Value<String?> title,
      Value<String?> description,
      Value<String?> avatarUrl,
      Value<String?> teamId,
      Value<String?> matchId,
      Value<String?> tournamentId,
      Value<String?> clubId,
      Value<int?> lastMessageSeq,
      Value<DateTime?> lastMessageAt,
      Value<String?> lastMessagePreview,
      Value<String?> lastMessageSenderId,
      Value<bool> lastMessageFromMe,
      Value<int> unreadCount,
      Value<DateTime> serverUpdatedAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$LocalChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalChannelsTable> {
  $$LocalChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextType => $composableBuilder(
    column: $table.contextType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageSeq => $composableBuilder(
    column: $table.lastMessageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastMessageFromMe => $composableBuilder(
    column: $table.lastMessageFromMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalChannelsTable> {
  $$LocalChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextType => $composableBuilder(
    column: $table.contextType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageSeq => $composableBuilder(
    column: $table.lastMessageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastMessageFromMe => $composableBuilder(
    column: $table.lastMessageFromMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalChannelsTable> {
  $$LocalChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get contextType => $composableBuilder(
    column: $table.contextType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<int> get lastMessageSeq => $composableBuilder(
    column: $table.lastMessageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastMessageFromMe => $composableBuilder(
    column: $table.lastMessageFromMe,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$LocalChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalChannelsTable,
          LocalChannelRow,
          $$LocalChannelsTableFilterComposer,
          $$LocalChannelsTableOrderingComposer,
          $$LocalChannelsTableAnnotationComposer,
          $$LocalChannelsTableCreateCompanionBuilder,
          $$LocalChannelsTableUpdateCompanionBuilder,
          (
            LocalChannelRow,
            BaseReferences<_$AppDatabase, $LocalChannelsTable, LocalChannelRow>,
          ),
          LocalChannelRow,
          PrefetchHooks Function()
        > {
  $$LocalChannelsTableTableManager(_$AppDatabase db, $LocalChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$LocalChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$LocalChannelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<String> channelKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> contextType = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> teamId = const Value.absent(),
                Value<String?> matchId = const Value.absent(),
                Value<String?> tournamentId = const Value.absent(),
                Value<String?> clubId = const Value.absent(),
                Value<int?> lastMessageSeq = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<bool> lastMessageFromMe = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<DateTime> serverUpdatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalChannelsCompanion(
                channelId: channelId,
                channelKey: channelKey,
                kind: kind,
                contextType: contextType,
                visibility: visibility,
                purpose: purpose,
                title: title,
                description: description,
                avatarUrl: avatarUrl,
                teamId: teamId,
                matchId: matchId,
                tournamentId: tournamentId,
                clubId: clubId,
                lastMessageSeq: lastMessageSeq,
                lastMessageAt: lastMessageAt,
                lastMessagePreview: lastMessagePreview,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageFromMe: lastMessageFromMe,
                unreadCount: unreadCount,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                required String channelKey,
                required String kind,
                required String contextType,
                Value<String> visibility = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> teamId = const Value.absent(),
                Value<String?> matchId = const Value.absent(),
                Value<String?> tournamentId = const Value.absent(),
                Value<String?> clubId = const Value.absent(),
                Value<int?> lastMessageSeq = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<bool> lastMessageFromMe = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                required DateTime serverUpdatedAt,
                required DateTime localUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalChannelsCompanion.insert(
                channelId: channelId,
                channelKey: channelKey,
                kind: kind,
                contextType: contextType,
                visibility: visibility,
                purpose: purpose,
                title: title,
                description: description,
                avatarUrl: avatarUrl,
                teamId: teamId,
                matchId: matchId,
                tournamentId: tournamentId,
                clubId: clubId,
                lastMessageSeq: lastMessageSeq,
                lastMessageAt: lastMessageAt,
                lastMessagePreview: lastMessagePreview,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageFromMe: lastMessageFromMe,
                unreadCount: unreadCount,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalChannelsTable,
      LocalChannelRow,
      $$LocalChannelsTableFilterComposer,
      $$LocalChannelsTableOrderingComposer,
      $$LocalChannelsTableAnnotationComposer,
      $$LocalChannelsTableCreateCompanionBuilder,
      $$LocalChannelsTableUpdateCompanionBuilder,
      (
        LocalChannelRow,
        BaseReferences<_$AppDatabase, $LocalChannelsTable, LocalChannelRow>,
      ),
      LocalChannelRow,
      PrefetchHooks Function()
    >;
typedef $$LocalChannelMembersTableCreateCompanionBuilder =
    LocalChannelMembersCompanion Function({
      required String channelId,
      required String userId,
      Value<String> role,
      Value<String> status,
      Value<DateTime?> joinedAt,
      Value<DateTime?> leftAt,
      Value<int?> lastDeliveredMessageSeq,
      Value<DateTime?> lastDeliveredAt,
      Value<int?> lastReadMessageSeq,
      Value<DateTime?> lastReadAt,
      Value<DateTime?> notificationsMutedUntil,
      Value<DateTime?> archivedAt,
      Value<DateTime?> pinnedAt,
      required DateTime serverUpdatedAt,
      Value<int> rowid,
    });
typedef $$LocalChannelMembersTableUpdateCompanionBuilder =
    LocalChannelMembersCompanion Function({
      Value<String> channelId,
      Value<String> userId,
      Value<String> role,
      Value<String> status,
      Value<DateTime?> joinedAt,
      Value<DateTime?> leftAt,
      Value<int?> lastDeliveredMessageSeq,
      Value<DateTime?> lastDeliveredAt,
      Value<int?> lastReadMessageSeq,
      Value<DateTime?> lastReadAt,
      Value<DateTime?> notificationsMutedUntil,
      Value<DateTime?> archivedAt,
      Value<DateTime?> pinnedAt,
      Value<DateTime> serverUpdatedAt,
      Value<int> rowid,
    });

class $$LocalChannelMembersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalChannelMembersTable> {
  $$LocalChannelMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastDeliveredMessageSeq => $composableBuilder(
    column: $table.lastDeliveredMessageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastDeliveredAt => $composableBuilder(
    column: $table.lastDeliveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadMessageSeq => $composableBuilder(
    column: $table.lastReadMessageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get notificationsMutedUntil => $composableBuilder(
    column: $table.notificationsMutedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalChannelMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalChannelMembersTable> {
  $$LocalChannelMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastDeliveredMessageSeq => $composableBuilder(
    column: $table.lastDeliveredMessageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastDeliveredAt => $composableBuilder(
    column: $table.lastDeliveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadMessageSeq => $composableBuilder(
    column: $table.lastReadMessageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get notificationsMutedUntil => $composableBuilder(
    column: $table.notificationsMutedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalChannelMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalChannelMembersTable> {
  $$LocalChannelMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => column);

  GeneratedColumn<int> get lastDeliveredMessageSeq => $composableBuilder(
    column: $table.lastDeliveredMessageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastDeliveredAt => $composableBuilder(
    column: $table.lastDeliveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReadMessageSeq => $composableBuilder(
    column: $table.lastReadMessageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get notificationsMutedUntil => $composableBuilder(
    column: $table.notificationsMutedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );
}

class $$LocalChannelMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalChannelMembersTable,
          LocalChannelMemberRow,
          $$LocalChannelMembersTableFilterComposer,
          $$LocalChannelMembersTableOrderingComposer,
          $$LocalChannelMembersTableAnnotationComposer,
          $$LocalChannelMembersTableCreateCompanionBuilder,
          $$LocalChannelMembersTableUpdateCompanionBuilder,
          (
            LocalChannelMemberRow,
            BaseReferences<
              _$AppDatabase,
              $LocalChannelMembersTable,
              LocalChannelMemberRow
            >,
          ),
          LocalChannelMemberRow,
          PrefetchHooks Function()
        > {
  $$LocalChannelMembersTableTableManager(
    _$AppDatabase db,
    $LocalChannelMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalChannelMembersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalChannelMembersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalChannelMembersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> joinedAt = const Value.absent(),
                Value<DateTime?> leftAt = const Value.absent(),
                Value<int?> lastDeliveredMessageSeq = const Value.absent(),
                Value<DateTime?> lastDeliveredAt = const Value.absent(),
                Value<int?> lastReadMessageSeq = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<DateTime?> notificationsMutedUntil = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime> serverUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalChannelMembersCompanion(
                channelId: channelId,
                userId: userId,
                role: role,
                status: status,
                joinedAt: joinedAt,
                leftAt: leftAt,
                lastDeliveredMessageSeq: lastDeliveredMessageSeq,
                lastDeliveredAt: lastDeliveredAt,
                lastReadMessageSeq: lastReadMessageSeq,
                lastReadAt: lastReadAt,
                notificationsMutedUntil: notificationsMutedUntil,
                archivedAt: archivedAt,
                pinnedAt: pinnedAt,
                serverUpdatedAt: serverUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                required String userId,
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> joinedAt = const Value.absent(),
                Value<DateTime?> leftAt = const Value.absent(),
                Value<int?> lastDeliveredMessageSeq = const Value.absent(),
                Value<DateTime?> lastDeliveredAt = const Value.absent(),
                Value<int?> lastReadMessageSeq = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<DateTime?> notificationsMutedUntil = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                required DateTime serverUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalChannelMembersCompanion.insert(
                channelId: channelId,
                userId: userId,
                role: role,
                status: status,
                joinedAt: joinedAt,
                leftAt: leftAt,
                lastDeliveredMessageSeq: lastDeliveredMessageSeq,
                lastDeliveredAt: lastDeliveredAt,
                lastReadMessageSeq: lastReadMessageSeq,
                lastReadAt: lastReadAt,
                notificationsMutedUntil: notificationsMutedUntil,
                archivedAt: archivedAt,
                pinnedAt: pinnedAt,
                serverUpdatedAt: serverUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalChannelMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalChannelMembersTable,
      LocalChannelMemberRow,
      $$LocalChannelMembersTableFilterComposer,
      $$LocalChannelMembersTableOrderingComposer,
      $$LocalChannelMembersTableAnnotationComposer,
      $$LocalChannelMembersTableCreateCompanionBuilder,
      $$LocalChannelMembersTableUpdateCompanionBuilder,
      (
        LocalChannelMemberRow,
        BaseReferences<
          _$AppDatabase,
          $LocalChannelMembersTable,
          LocalChannelMemberRow
        >,
      ),
      LocalChannelMemberRow,
      PrefetchHooks Function()
    >;
typedef $$LocalMessagesTableCreateCompanionBuilder =
    LocalMessagesCompanion Function({
      required String messageId,
      Value<int?> messageSeq,
      required String channelId,
      Value<String?> senderId,
      Value<String?> senderDisplayName,
      Value<String> messageType,
      Value<String?> body,
      Value<String> payloadJson,
      Value<String?> replyToMessageId,
      Value<int> version,
      Value<bool> countsAsUnread,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      required DateTime localCreatedAt,
      Value<String> syncStatus,
      Value<String?> sendErrorCode,
      Value<String?> sendErrorMessage,
      Value<int> rowid,
    });
typedef $$LocalMessagesTableUpdateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<String> messageId,
      Value<int?> messageSeq,
      Value<String> channelId,
      Value<String?> senderId,
      Value<String?> senderDisplayName,
      Value<String> messageType,
      Value<String?> body,
      Value<String> payloadJson,
      Value<String?> replyToMessageId,
      Value<int> version,
      Value<bool> countsAsUnread,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> localCreatedAt,
      Value<String> syncStatus,
      Value<String?> sendErrorCode,
      Value<String?> sendErrorMessage,
      Value<int> rowid,
    });

class $$LocalMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageSeq => $composableBuilder(
    column: $table.messageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderDisplayName => $composableBuilder(
    column: $table.senderDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsAsUnread => $composableBuilder(
    column: $table.countsAsUnread,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localCreatedAt => $composableBuilder(
    column: $table.localCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sendErrorCode => $composableBuilder(
    column: $table.sendErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sendErrorMessage => $composableBuilder(
    column: $table.sendErrorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageSeq => $composableBuilder(
    column: $table.messageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderDisplayName => $composableBuilder(
    column: $table.senderDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsAsUnread => $composableBuilder(
    column: $table.countsAsUnread,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localCreatedAt => $composableBuilder(
    column: $table.localCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendErrorCode => $composableBuilder(
    column: $table.sendErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendErrorMessage => $composableBuilder(
    column: $table.sendErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get messageSeq => $composableBuilder(
    column: $table.messageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderDisplayName => $composableBuilder(
    column: $table.senderDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get countsAsUnread => $composableBuilder(
    column: $table.countsAsUnread,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localCreatedAt => $composableBuilder(
    column: $table.localCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sendErrorCode => $composableBuilder(
    column: $table.sendErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sendErrorMessage => $composableBuilder(
    column: $table.sendErrorMessage,
    builder: (column) => column,
  );
}

class $$LocalMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessagesTable,
          LocalMessageRow,
          $$LocalMessagesTableFilterComposer,
          $$LocalMessagesTableOrderingComposer,
          $$LocalMessagesTableAnnotationComposer,
          $$LocalMessagesTableCreateCompanionBuilder,
          $$LocalMessagesTableUpdateCompanionBuilder,
          (
            LocalMessageRow,
            BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessageRow>,
          ),
          LocalMessageRow,
          PrefetchHooks Function()
        > {
  $$LocalMessagesTableTableManager(_$AppDatabase db, $LocalMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$LocalMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$LocalMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<int?> messageSeq = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String?> senderId = const Value.absent(),
                Value<String?> senderDisplayName = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> replyToMessageId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> countsAsUnread = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> localCreatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> sendErrorCode = const Value.absent(),
                Value<String?> sendErrorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion(
                messageId: messageId,
                messageSeq: messageSeq,
                channelId: channelId,
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                messageType: messageType,
                body: body,
                payloadJson: payloadJson,
                replyToMessageId: replyToMessageId,
                version: version,
                countsAsUnread: countsAsUnread,
                createdAt: createdAt,
                updatedAt: updatedAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                localCreatedAt: localCreatedAt,
                syncStatus: syncStatus,
                sendErrorCode: sendErrorCode,
                sendErrorMessage: sendErrorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                Value<int?> messageSeq = const Value.absent(),
                required String channelId,
                Value<String?> senderId = const Value.absent(),
                Value<String?> senderDisplayName = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> replyToMessageId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> countsAsUnread = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime localCreatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> sendErrorCode = const Value.absent(),
                Value<String?> sendErrorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion.insert(
                messageId: messageId,
                messageSeq: messageSeq,
                channelId: channelId,
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                messageType: messageType,
                body: body,
                payloadJson: payloadJson,
                replyToMessageId: replyToMessageId,
                version: version,
                countsAsUnread: countsAsUnread,
                createdAt: createdAt,
                updatedAt: updatedAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                localCreatedAt: localCreatedAt,
                syncStatus: syncStatus,
                sendErrorCode: sendErrorCode,
                sendErrorMessage: sendErrorMessage,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessagesTable,
      LocalMessageRow,
      $$LocalMessagesTableFilterComposer,
      $$LocalMessagesTableOrderingComposer,
      $$LocalMessagesTableAnnotationComposer,
      $$LocalMessagesTableCreateCompanionBuilder,
      $$LocalMessagesTableUpdateCompanionBuilder,
      (
        LocalMessageRow,
        BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessageRow>,
      ),
      LocalMessageRow,
      PrefetchHooks Function()
    >;
typedef $$LocalMessageAttachmentsTableCreateCompanionBuilder =
    LocalMessageAttachmentsCompanion Function({
      required String attachmentId,
      required String messageId,
      Value<String?> storagePath,
      required String mimeType,
      Value<String?> fileName,
      Value<int?> sizeBytes,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMs,
      Value<String?> localPath,
      Value<String?> thumbnailLocalPath,
      Value<String> uploadStatus,
      Value<double?> uploadProgress,
      Value<String?> uploadError,
      Value<int> rowid,
    });
typedef $$LocalMessageAttachmentsTableUpdateCompanionBuilder =
    LocalMessageAttachmentsCompanion Function({
      Value<String> attachmentId,
      Value<String> messageId,
      Value<String?> storagePath,
      Value<String> mimeType,
      Value<String?> fileName,
      Value<int?> sizeBytes,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMs,
      Value<String?> localPath,
      Value<String?> thumbnailLocalPath,
      Value<String> uploadStatus,
      Value<double?> uploadProgress,
      Value<String?> uploadError,
      Value<int> rowid,
    });

class $$LocalMessageAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessageAttachmentsTable> {
  $$LocalMessageAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailLocalPath => $composableBuilder(
    column: $table.thumbnailLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get uploadProgress => $composableBuilder(
    column: $table.uploadProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadError => $composableBuilder(
    column: $table.uploadError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessageAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessageAttachmentsTable> {
  $$LocalMessageAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailLocalPath => $composableBuilder(
    column: $table.thumbnailLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get uploadProgress => $composableBuilder(
    column: $table.uploadProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadError => $composableBuilder(
    column: $table.uploadError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessageAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessageAttachmentsTable> {
  $$LocalMessageAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailLocalPath => $composableBuilder(
    column: $table.thumbnailLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get uploadProgress => $composableBuilder(
    column: $table.uploadProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadError => $composableBuilder(
    column: $table.uploadError,
    builder: (column) => column,
  );
}

class $$LocalMessageAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessageAttachmentsTable,
          LocalMessageAttachmentRow,
          $$LocalMessageAttachmentsTableFilterComposer,
          $$LocalMessageAttachmentsTableOrderingComposer,
          $$LocalMessageAttachmentsTableAnnotationComposer,
          $$LocalMessageAttachmentsTableCreateCompanionBuilder,
          $$LocalMessageAttachmentsTableUpdateCompanionBuilder,
          (
            LocalMessageAttachmentRow,
            BaseReferences<
              _$AppDatabase,
              $LocalMessageAttachmentsTable,
              LocalMessageAttachmentRow
            >,
          ),
          LocalMessageAttachmentRow,
          PrefetchHooks Function()
        > {
  $$LocalMessageAttachmentsTableTableManager(
    _$AppDatabase db,
    $LocalMessageAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalMessageAttachmentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalMessageAttachmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalMessageAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> attachmentId = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String?> storagePath = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> thumbnailLocalPath = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<double?> uploadProgress = const Value.absent(),
                Value<String?> uploadError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessageAttachmentsCompanion(
                attachmentId: attachmentId,
                messageId: messageId,
                storagePath: storagePath,
                mimeType: mimeType,
                fileName: fileName,
                sizeBytes: sizeBytes,
                width: width,
                height: height,
                durationMs: durationMs,
                localPath: localPath,
                thumbnailLocalPath: thumbnailLocalPath,
                uploadStatus: uploadStatus,
                uploadProgress: uploadProgress,
                uploadError: uploadError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attachmentId,
                required String messageId,
                Value<String?> storagePath = const Value.absent(),
                required String mimeType,
                Value<String?> fileName = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> thumbnailLocalPath = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<double?> uploadProgress = const Value.absent(),
                Value<String?> uploadError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessageAttachmentsCompanion.insert(
                attachmentId: attachmentId,
                messageId: messageId,
                storagePath: storagePath,
                mimeType: mimeType,
                fileName: fileName,
                sizeBytes: sizeBytes,
                width: width,
                height: height,
                durationMs: durationMs,
                localPath: localPath,
                thumbnailLocalPath: thumbnailLocalPath,
                uploadStatus: uploadStatus,
                uploadProgress: uploadProgress,
                uploadError: uploadError,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessageAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessageAttachmentsTable,
      LocalMessageAttachmentRow,
      $$LocalMessageAttachmentsTableFilterComposer,
      $$LocalMessageAttachmentsTableOrderingComposer,
      $$LocalMessageAttachmentsTableAnnotationComposer,
      $$LocalMessageAttachmentsTableCreateCompanionBuilder,
      $$LocalMessageAttachmentsTableUpdateCompanionBuilder,
      (
        LocalMessageAttachmentRow,
        BaseReferences<
          _$AppDatabase,
          $LocalMessageAttachmentsTable,
          LocalMessageAttachmentRow
        >,
      ),
      LocalMessageAttachmentRow,
      PrefetchHooks Function()
    >;
typedef $$LocalMessageReactionsTableCreateCompanionBuilder =
    LocalMessageReactionsCompanion Function({
      required String messageId,
      required String userId,
      required String reaction,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> removedAt,
      Value<int> rowid,
    });
typedef $$LocalMessageReactionsTableUpdateCompanionBuilder =
    LocalMessageReactionsCompanion Function({
      Value<String> messageId,
      Value<String> userId,
      Value<String> reaction,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> removedAt,
      Value<int> rowid,
    });

class $$LocalMessageReactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessageReactionsTable> {
  $$LocalMessageReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessageReactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessageReactionsTable> {
  $$LocalMessageReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessageReactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessageReactionsTable> {
  $$LocalMessageReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get reaction =>
      $composableBuilder(column: $table.reaction, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => column);
}

class $$LocalMessageReactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessageReactionsTable,
          LocalMessageReactionRow,
          $$LocalMessageReactionsTableFilterComposer,
          $$LocalMessageReactionsTableOrderingComposer,
          $$LocalMessageReactionsTableAnnotationComposer,
          $$LocalMessageReactionsTableCreateCompanionBuilder,
          $$LocalMessageReactionsTableUpdateCompanionBuilder,
          (
            LocalMessageReactionRow,
            BaseReferences<
              _$AppDatabase,
              $LocalMessageReactionsTable,
              LocalMessageReactionRow
            >,
          ),
          LocalMessageReactionRow,
          PrefetchHooks Function()
        > {
  $$LocalMessageReactionsTableTableManager(
    _$AppDatabase db,
    $LocalMessageReactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalMessageReactionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalMessageReactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalMessageReactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> reaction = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> removedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessageReactionsCompanion(
                messageId: messageId,
                userId: userId,
                reaction: reaction,
                createdAt: createdAt,
                updatedAt: updatedAt,
                removedAt: removedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String userId,
                required String reaction,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> removedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessageReactionsCompanion.insert(
                messageId: messageId,
                userId: userId,
                reaction: reaction,
                createdAt: createdAt,
                updatedAt: updatedAt,
                removedAt: removedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessageReactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessageReactionsTable,
      LocalMessageReactionRow,
      $$LocalMessageReactionsTableFilterComposer,
      $$LocalMessageReactionsTableOrderingComposer,
      $$LocalMessageReactionsTableAnnotationComposer,
      $$LocalMessageReactionsTableCreateCompanionBuilder,
      $$LocalMessageReactionsTableUpdateCompanionBuilder,
      (
        LocalMessageReactionRow,
        BaseReferences<
          _$AppDatabase,
          $LocalMessageReactionsTable,
          LocalMessageReactionRow
        >,
      ),
      LocalMessageReactionRow,
      PrefetchHooks Function()
    >;
typedef $$LocalMemberRestrictionsTableCreateCompanionBuilder =
    LocalMemberRestrictionsCompanion Function({
      required String restrictionId,
      required String channelId,
      required String userId,
      required String permission,
      required DateTime startsAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });
typedef $$LocalMemberRestrictionsTableUpdateCompanionBuilder =
    LocalMemberRestrictionsCompanion Function({
      Value<String> restrictionId,
      Value<String> channelId,
      Value<String> userId,
      Value<String> permission,
      Value<DateTime> startsAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });

class $$LocalMemberRestrictionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMemberRestrictionsTable> {
  $$LocalMemberRestrictionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get restrictionId => $composableBuilder(
    column: $table.restrictionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMemberRestrictionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMemberRestrictionsTable> {
  $$LocalMemberRestrictionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get restrictionId => $composableBuilder(
    column: $table.restrictionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMemberRestrictionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMemberRestrictionsTable> {
  $$LocalMemberRestrictionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get restrictionId => $composableBuilder(
    column: $table.restrictionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$LocalMemberRestrictionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMemberRestrictionsTable,
          LocalMemberRestrictionRow,
          $$LocalMemberRestrictionsTableFilterComposer,
          $$LocalMemberRestrictionsTableOrderingComposer,
          $$LocalMemberRestrictionsTableAnnotationComposer,
          $$LocalMemberRestrictionsTableCreateCompanionBuilder,
          $$LocalMemberRestrictionsTableUpdateCompanionBuilder,
          (
            LocalMemberRestrictionRow,
            BaseReferences<
              _$AppDatabase,
              $LocalMemberRestrictionsTable,
              LocalMemberRestrictionRow
            >,
          ),
          LocalMemberRestrictionRow,
          PrefetchHooks Function()
        > {
  $$LocalMemberRestrictionsTableTableManager(
    _$AppDatabase db,
    $LocalMemberRestrictionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalMemberRestrictionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalMemberRestrictionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalMemberRestrictionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> restrictionId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> permission = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMemberRestrictionsCompanion(
                restrictionId: restrictionId,
                channelId: channelId,
                userId: userId,
                permission: permission,
                startsAt: startsAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String restrictionId,
                required String channelId,
                required String userId,
                required String permission,
                required DateTime startsAt,
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMemberRestrictionsCompanion.insert(
                restrictionId: restrictionId,
                channelId: channelId,
                userId: userId,
                permission: permission,
                startsAt: startsAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMemberRestrictionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMemberRestrictionsTable,
      LocalMemberRestrictionRow,
      $$LocalMemberRestrictionsTableFilterComposer,
      $$LocalMemberRestrictionsTableOrderingComposer,
      $$LocalMemberRestrictionsTableAnnotationComposer,
      $$LocalMemberRestrictionsTableCreateCompanionBuilder,
      $$LocalMemberRestrictionsTableUpdateCompanionBuilder,
      (
        LocalMemberRestrictionRow,
        BaseReferences<
          _$AppDatabase,
          $LocalMemberRestrictionsTable,
          LocalMemberRestrictionRow
        >,
      ),
      LocalMemberRestrictionRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxOperationsTableCreateCompanionBuilder =
    OutboxOperationsCompanion Function({
      required String operationId,
      required String channelId,
      Value<String?> entityId,
      required String operationType,
      required String payloadJson,
      Value<String> status,
      Value<String?> coalesceKey,
      Value<String?> dependsOnOperationId,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OutboxOperationsTableUpdateCompanionBuilder =
    OutboxOperationsCompanion Function({
      Value<String> operationId,
      Value<String> channelId,
      Value<String?> entityId,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<String> status,
      Value<String?> coalesceKey,
      Value<String?> dependsOnOperationId,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OutboxOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coalesceKey => $composableBuilder(
    column: $table.coalesceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOnOperationId => $composableBuilder(
    column: $table.dependsOnOperationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coalesceKey => $composableBuilder(
    column: $table.coalesceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOnOperationId => $composableBuilder(
    column: $table.dependsOnOperationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get coalesceKey => $composableBuilder(
    column: $table.coalesceKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependsOnOperationId => $composableBuilder(
    column: $table.dependsOnOperationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxOperationsTable,
          OutboxOperationRow,
          $$OutboxOperationsTableFilterComposer,
          $$OutboxOperationsTableOrderingComposer,
          $$OutboxOperationsTableAnnotationComposer,
          $$OutboxOperationsTableCreateCompanionBuilder,
          $$OutboxOperationsTableUpdateCompanionBuilder,
          (
            OutboxOperationRow,
            BaseReferences<
              _$AppDatabase,
              $OutboxOperationsTable,
              OutboxOperationRow
            >,
          ),
          OutboxOperationRow,
          PrefetchHooks Function()
        > {
  $$OutboxOperationsTableTableManager(
    _$AppDatabase db,
    $OutboxOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$OutboxOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OutboxOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$OutboxOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> coalesceKey = const Value.absent(),
                Value<String?> dependsOnOperationId = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxOperationsCompanion(
                operationId: operationId,
                channelId: channelId,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                coalesceKey: coalesceKey,
                dependsOnOperationId: dependsOnOperationId,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String channelId,
                Value<String?> entityId = const Value.absent(),
                required String operationType,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<String?> coalesceKey = const Value.absent(),
                Value<String?> dependsOnOperationId = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxOperationsCompanion.insert(
                operationId: operationId,
                channelId: channelId,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                coalesceKey: coalesceKey,
                dependsOnOperationId: dependsOnOperationId,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxOperationsTable,
      OutboxOperationRow,
      $$OutboxOperationsTableFilterComposer,
      $$OutboxOperationsTableOrderingComposer,
      $$OutboxOperationsTableAnnotationComposer,
      $$OutboxOperationsTableCreateCompanionBuilder,
      $$OutboxOperationsTableUpdateCompanionBuilder,
      (
        OutboxOperationRow,
        BaseReferences<
          _$AppDatabase,
          $OutboxOperationsTable,
          OutboxOperationRow
        >,
      ),
      OutboxOperationRow,
      PrefetchHooks Function()
    >;
typedef $$ChannelSyncStatesTableCreateCompanionBuilder =
    ChannelSyncStatesCompanion Function({
      required String channelId,
      Value<int?> newestSyncedMessageSeq,
      Value<int?> newestAppliedChangeSeq,
      Value<int?> oldestCachedMessageSeq,
      Value<bool> hasMoreHistory,
      Value<DateTime?> lastMemberSyncAt,
      Value<DateTime?> lastFullSyncAt,
      Value<String> syncStatus,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });
typedef $$ChannelSyncStatesTableUpdateCompanionBuilder =
    ChannelSyncStatesCompanion Function({
      Value<String> channelId,
      Value<int?> newestSyncedMessageSeq,
      Value<int?> newestAppliedChangeSeq,
      Value<int?> oldestCachedMessageSeq,
      Value<bool> hasMoreHistory,
      Value<DateTime?> lastMemberSyncAt,
      Value<DateTime?> lastFullSyncAt,
      Value<String> syncStatus,
      Value<String?> lastSyncError,
      Value<int> rowid,
    });

class $$ChannelSyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelSyncStatesTable> {
  $$ChannelSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newestSyncedMessageSeq => $composableBuilder(
    column: $table.newestSyncedMessageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newestAppliedChangeSeq => $composableBuilder(
    column: $table.newestAppliedChangeSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get oldestCachedMessageSeq => $composableBuilder(
    column: $table.oldestCachedMessageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasMoreHistory => $composableBuilder(
    column: $table.hasMoreHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMemberSyncAt => $composableBuilder(
    column: $table.lastMemberSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFullSyncAt => $composableBuilder(
    column: $table.lastFullSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelSyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelSyncStatesTable> {
  $$ChannelSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newestSyncedMessageSeq => $composableBuilder(
    column: $table.newestSyncedMessageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newestAppliedChangeSeq => $composableBuilder(
    column: $table.newestAppliedChangeSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get oldestCachedMessageSeq => $composableBuilder(
    column: $table.oldestCachedMessageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasMoreHistory => $composableBuilder(
    column: $table.hasMoreHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMemberSyncAt => $composableBuilder(
    column: $table.lastMemberSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFullSyncAt => $composableBuilder(
    column: $table.lastFullSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelSyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelSyncStatesTable> {
  $$ChannelSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<int> get newestSyncedMessageSeq => $composableBuilder(
    column: $table.newestSyncedMessageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newestAppliedChangeSeq => $composableBuilder(
    column: $table.newestAppliedChangeSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get oldestCachedMessageSeq => $composableBuilder(
    column: $table.oldestCachedMessageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasMoreHistory => $composableBuilder(
    column: $table.hasMoreHistory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMemberSyncAt => $composableBuilder(
    column: $table.lastMemberSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFullSyncAt => $composableBuilder(
    column: $table.lastFullSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );
}

class $$ChannelSyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelSyncStatesTable,
          ChannelSyncStateRow,
          $$ChannelSyncStatesTableFilterComposer,
          $$ChannelSyncStatesTableOrderingComposer,
          $$ChannelSyncStatesTableAnnotationComposer,
          $$ChannelSyncStatesTableCreateCompanionBuilder,
          $$ChannelSyncStatesTableUpdateCompanionBuilder,
          (
            ChannelSyncStateRow,
            BaseReferences<
              _$AppDatabase,
              $ChannelSyncStatesTable,
              ChannelSyncStateRow
            >,
          ),
          ChannelSyncStateRow,
          PrefetchHooks Function()
        > {
  $$ChannelSyncStatesTableTableManager(
    _$AppDatabase db,
    $ChannelSyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ChannelSyncStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ChannelSyncStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ChannelSyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<int?> newestSyncedMessageSeq = const Value.absent(),
                Value<int?> newestAppliedChangeSeq = const Value.absent(),
                Value<int?> oldestCachedMessageSeq = const Value.absent(),
                Value<bool> hasMoreHistory = const Value.absent(),
                Value<DateTime?> lastMemberSyncAt = const Value.absent(),
                Value<DateTime?> lastFullSyncAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelSyncStatesCompanion(
                channelId: channelId,
                newestSyncedMessageSeq: newestSyncedMessageSeq,
                newestAppliedChangeSeq: newestAppliedChangeSeq,
                oldestCachedMessageSeq: oldestCachedMessageSeq,
                hasMoreHistory: hasMoreHistory,
                lastMemberSyncAt: lastMemberSyncAt,
                lastFullSyncAt: lastFullSyncAt,
                syncStatus: syncStatus,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                Value<int?> newestSyncedMessageSeq = const Value.absent(),
                Value<int?> newestAppliedChangeSeq = const Value.absent(),
                Value<int?> oldestCachedMessageSeq = const Value.absent(),
                Value<bool> hasMoreHistory = const Value.absent(),
                Value<DateTime?> lastMemberSyncAt = const Value.absent(),
                Value<DateTime?> lastFullSyncAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelSyncStatesCompanion.insert(
                channelId: channelId,
                newestSyncedMessageSeq: newestSyncedMessageSeq,
                newestAppliedChangeSeq: newestAppliedChangeSeq,
                oldestCachedMessageSeq: oldestCachedMessageSeq,
                hasMoreHistory: hasMoreHistory,
                lastMemberSyncAt: lastMemberSyncAt,
                lastFullSyncAt: lastFullSyncAt,
                syncStatus: syncStatus,
                lastSyncError: lastSyncError,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelSyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelSyncStatesTable,
      ChannelSyncStateRow,
      $$ChannelSyncStatesTableFilterComposer,
      $$ChannelSyncStatesTableOrderingComposer,
      $$ChannelSyncStatesTableAnnotationComposer,
      $$ChannelSyncStatesTableCreateCompanionBuilder,
      $$ChannelSyncStatesTableUpdateCompanionBuilder,
      (
        ChannelSyncStateRow,
        BaseReferences<
          _$AppDatabase,
          $ChannelSyncStatesTable,
          ChannelSyncStateRow
        >,
      ),
      ChannelSyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$ChannelDraftsTableCreateCompanionBuilder =
    ChannelDraftsCompanion Function({
      required String channelId,
      required String body,
      Value<String?> replyToMessageId,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChannelDraftsTableUpdateCompanionBuilder =
    ChannelDraftsCompanion Function({
      Value<String> channelId,
      Value<String> body,
      Value<String?> replyToMessageId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ChannelDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelDraftsTable> {
  $$ChannelDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelDraftsTable> {
  $$ChannelDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelDraftsTable> {
  $$ChannelDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChannelDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelDraftsTable,
          ChannelDraftRow,
          $$ChannelDraftsTableFilterComposer,
          $$ChannelDraftsTableOrderingComposer,
          $$ChannelDraftsTableAnnotationComposer,
          $$ChannelDraftsTableCreateCompanionBuilder,
          $$ChannelDraftsTableUpdateCompanionBuilder,
          (
            ChannelDraftRow,
            BaseReferences<_$AppDatabase, $ChannelDraftsTable, ChannelDraftRow>,
          ),
          ChannelDraftRow,
          PrefetchHooks Function()
        > {
  $$ChannelDraftsTableTableManager(_$AppDatabase db, $ChannelDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ChannelDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$ChannelDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ChannelDraftsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> replyToMessageId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelDraftsCompanion(
                channelId: channelId,
                body: body,
                replyToMessageId: replyToMessageId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                required String body,
                Value<String?> replyToMessageId = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChannelDraftsCompanion.insert(
                channelId: channelId,
                body: body,
                replyToMessageId: replyToMessageId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelDraftsTable,
      ChannelDraftRow,
      $$ChannelDraftsTableFilterComposer,
      $$ChannelDraftsTableOrderingComposer,
      $$ChannelDraftsTableAnnotationComposer,
      $$ChannelDraftsTableCreateCompanionBuilder,
      $$ChannelDraftsTableUpdateCompanionBuilder,
      (
        ChannelDraftRow,
        BaseReferences<_$AppDatabase, $ChannelDraftsTable, ChannelDraftRow>,
      ),
      ChannelDraftRow,
      PrefetchHooks Function()
    >;
typedef $$ScoringOpsTableCreateCompanionBuilder =
    ScoringOpsCompanion Function({
      required String opId,
      required String matchId,
      required int inningsNumber,
      required int localSeq,
      Value<String> kind,
      required String payload,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> refusedAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$ScoringOpsTableUpdateCompanionBuilder =
    ScoringOpsCompanion Function({
      Value<String> opId,
      Value<String> matchId,
      Value<int> inningsNumber,
      Value<int> localSeq,
      Value<String> kind,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> refusedAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$ScoringOpsTableFilterComposer
    extends Composer<_$AppDatabase, $ScoringOpsTable> {
  $$ScoringOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSeq => $composableBuilder(
    column: $table.localSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refusedAt => $composableBuilder(
    column: $table.refusedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScoringOpsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoringOpsTable> {
  $$ScoringOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSeq => $composableBuilder(
    column: $table.localSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refusedAt => $composableBuilder(
    column: $table.refusedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoringOpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoringOpsTable> {
  $$ScoringOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localSeq =>
      $composableBuilder(column: $table.localSeq, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get refusedAt =>
      $composableBuilder(column: $table.refusedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$ScoringOpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScoringOpsTable,
          ScoringOpRow,
          $$ScoringOpsTableFilterComposer,
          $$ScoringOpsTableOrderingComposer,
          $$ScoringOpsTableAnnotationComposer,
          $$ScoringOpsTableCreateCompanionBuilder,
          $$ScoringOpsTableUpdateCompanionBuilder,
          (
            ScoringOpRow,
            BaseReferences<_$AppDatabase, $ScoringOpsTable, ScoringOpRow>,
          ),
          ScoringOpRow,
          PrefetchHooks Function()
        > {
  $$ScoringOpsTableTableManager(_$AppDatabase db, $ScoringOpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ScoringOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ScoringOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ScoringOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<int> inningsNumber = const Value.absent(),
                Value<int> localSeq = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> refusedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoringOpsCompanion(
                opId: opId,
                matchId: matchId,
                inningsNumber: inningsNumber,
                localSeq: localSeq,
                kind: kind,
                payload: payload,
                createdAt: createdAt,
                syncedAt: syncedAt,
                refusedAt: refusedAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String matchId,
                required int inningsNumber,
                required int localSeq,
                Value<String> kind = const Value.absent(),
                required String payload,
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> refusedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoringOpsCompanion.insert(
                opId: opId,
                matchId: matchId,
                inningsNumber: inningsNumber,
                localSeq: localSeq,
                kind: kind,
                payload: payload,
                createdAt: createdAt,
                syncedAt: syncedAt,
                refusedAt: refusedAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScoringOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScoringOpsTable,
      ScoringOpRow,
      $$ScoringOpsTableFilterComposer,
      $$ScoringOpsTableOrderingComposer,
      $$ScoringOpsTableAnnotationComposer,
      $$ScoringOpsTableCreateCompanionBuilder,
      $$ScoringOpsTableUpdateCompanionBuilder,
      (
        ScoringOpRow,
        BaseReferences<_$AppDatabase, $ScoringOpsTable, ScoringOpRow>,
      ),
      ScoringOpRow,
      PrefetchHooks Function()
    >;
typedef $$ScoringSnapshotsTableCreateCompanionBuilder =
    ScoringSnapshotsCompanion Function({
      required String matchId,
      required int inningsNumber,
      required String state,
      required int throughSeq,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ScoringSnapshotsTableUpdateCompanionBuilder =
    ScoringSnapshotsCompanion Function({
      Value<String> matchId,
      Value<int> inningsNumber,
      Value<String> state,
      Value<int> throughSeq,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ScoringSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ScoringSnapshotsTable> {
  $$ScoringSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get throughSeq => $composableBuilder(
    column: $table.throughSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScoringSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoringSnapshotsTable> {
  $$ScoringSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get throughSeq => $composableBuilder(
    column: $table.throughSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoringSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoringSnapshotsTable> {
  $$ScoringSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get throughSeq => $composableBuilder(
    column: $table.throughSeq,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ScoringSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScoringSnapshotsTable,
          ScoringSnapshotRow,
          $$ScoringSnapshotsTableFilterComposer,
          $$ScoringSnapshotsTableOrderingComposer,
          $$ScoringSnapshotsTableAnnotationComposer,
          $$ScoringSnapshotsTableCreateCompanionBuilder,
          $$ScoringSnapshotsTableUpdateCompanionBuilder,
          (
            ScoringSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $ScoringSnapshotsTable,
              ScoringSnapshotRow
            >,
          ),
          ScoringSnapshotRow,
          PrefetchHooks Function()
        > {
  $$ScoringSnapshotsTableTableManager(
    _$AppDatabase db,
    $ScoringSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$ScoringSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ScoringSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ScoringSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> matchId = const Value.absent(),
                Value<int> inningsNumber = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> throughSeq = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoringSnapshotsCompanion(
                matchId: matchId,
                inningsNumber: inningsNumber,
                state: state,
                throughSeq: throughSeq,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matchId,
                required int inningsNumber,
                required String state,
                required int throughSeq,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScoringSnapshotsCompanion.insert(
                matchId: matchId,
                inningsNumber: inningsNumber,
                state: state,
                throughSeq: throughSeq,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScoringSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScoringSnapshotsTable,
      ScoringSnapshotRow,
      $$ScoringSnapshotsTableFilterComposer,
      $$ScoringSnapshotsTableOrderingComposer,
      $$ScoringSnapshotsTableAnnotationComposer,
      $$ScoringSnapshotsTableCreateCompanionBuilder,
      $$ScoringSnapshotsTableUpdateCompanionBuilder,
      (
        ScoringSnapshotRow,
        BaseReferences<
          _$AppDatabase,
          $ScoringSnapshotsTable,
          ScoringSnapshotRow
        >,
      ),
      ScoringSnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$CachedMatchesTableCreateCompanionBuilder =
    CachedMatchesCompanion Function({
      required String matchId,
      required String payload,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedMatchesTableUpdateCompanionBuilder =
    CachedMatchesCompanion Function({
      Value<String> matchId,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedMatchesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMatchesTable> {
  $$CachedMatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMatchesTable> {
  $$CachedMatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMatchesTable> {
  $$CachedMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMatchesTable,
          CachedMatchRow,
          $$CachedMatchesTableFilterComposer,
          $$CachedMatchesTableOrderingComposer,
          $$CachedMatchesTableAnnotationComposer,
          $$CachedMatchesTableCreateCompanionBuilder,
          $$CachedMatchesTableUpdateCompanionBuilder,
          (
            CachedMatchRow,
            BaseReferences<_$AppDatabase, $CachedMatchesTable, CachedMatchRow>,
          ),
          CachedMatchRow,
          PrefetchHooks Function()
        > {
  $$CachedMatchesTableTableManager(_$AppDatabase db, $CachedMatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CachedMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$CachedMatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CachedMatchesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> matchId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMatchesCompanion(
                matchId: matchId,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matchId,
                required String payload,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMatchesCompanion.insert(
                matchId: matchId,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMatchesTable,
      CachedMatchRow,
      $$CachedMatchesTableFilterComposer,
      $$CachedMatchesTableOrderingComposer,
      $$CachedMatchesTableAnnotationComposer,
      $$CachedMatchesTableCreateCompanionBuilder,
      $$CachedMatchesTableUpdateCompanionBuilder,
      (
        CachedMatchRow,
        BaseReferences<_$AppDatabase, $CachedMatchesTable, CachedMatchRow>,
      ),
      CachedMatchRow,
      PrefetchHooks Function()
    >;
typedef $$CachedMatchPlayersTableCreateCompanionBuilder =
    CachedMatchPlayersCompanion Function({
      required String matchId,
      required String payload,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedMatchPlayersTableUpdateCompanionBuilder =
    CachedMatchPlayersCompanion Function({
      Value<String> matchId,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedMatchPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMatchPlayersTable> {
  $$CachedMatchPlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMatchPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMatchPlayersTable> {
  $$CachedMatchPlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMatchPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMatchPlayersTable> {
  $$CachedMatchPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMatchPlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMatchPlayersTable,
          CachedMatchPlayersRow,
          $$CachedMatchPlayersTableFilterComposer,
          $$CachedMatchPlayersTableOrderingComposer,
          $$CachedMatchPlayersTableAnnotationComposer,
          $$CachedMatchPlayersTableCreateCompanionBuilder,
          $$CachedMatchPlayersTableUpdateCompanionBuilder,
          (
            CachedMatchPlayersRow,
            BaseReferences<
              _$AppDatabase,
              $CachedMatchPlayersTable,
              CachedMatchPlayersRow
            >,
          ),
          CachedMatchPlayersRow,
          PrefetchHooks Function()
        > {
  $$CachedMatchPlayersTableTableManager(
    _$AppDatabase db,
    $CachedMatchPlayersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CachedMatchPlayersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$CachedMatchPlayersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CachedMatchPlayersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> matchId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMatchPlayersCompanion(
                matchId: matchId,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matchId,
                required String payload,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMatchPlayersCompanion.insert(
                matchId: matchId,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMatchPlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMatchPlayersTable,
      CachedMatchPlayersRow,
      $$CachedMatchPlayersTableFilterComposer,
      $$CachedMatchPlayersTableOrderingComposer,
      $$CachedMatchPlayersTableAnnotationComposer,
      $$CachedMatchPlayersTableCreateCompanionBuilder,
      $$CachedMatchPlayersTableUpdateCompanionBuilder,
      (
        CachedMatchPlayersRow,
        BaseReferences<
          _$AppDatabase,
          $CachedMatchPlayersTable,
          CachedMatchPlayersRow
        >,
      ),
      CachedMatchPlayersRow,
      PrefetchHooks Function()
    >;
typedef $$CachedInningsStatesTableCreateCompanionBuilder =
    CachedInningsStatesCompanion Function({
      required String matchId,
      required int inningsNumber,
      required String payload,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedInningsStatesTableUpdateCompanionBuilder =
    CachedInningsStatesCompanion Function({
      Value<String> matchId,
      Value<int> inningsNumber,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedInningsStatesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedInningsStatesTable> {
  $$CachedInningsStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedInningsStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedInningsStatesTable> {
  $$CachedInningsStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedInningsStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedInningsStatesTable> {
  $$CachedInningsStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedInningsStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedInningsStatesTable,
          CachedInningsStateRow,
          $$CachedInningsStatesTableFilterComposer,
          $$CachedInningsStatesTableOrderingComposer,
          $$CachedInningsStatesTableAnnotationComposer,
          $$CachedInningsStatesTableCreateCompanionBuilder,
          $$CachedInningsStatesTableUpdateCompanionBuilder,
          (
            CachedInningsStateRow,
            BaseReferences<
              _$AppDatabase,
              $CachedInningsStatesTable,
              CachedInningsStateRow
            >,
          ),
          CachedInningsStateRow,
          PrefetchHooks Function()
        > {
  $$CachedInningsStatesTableTableManager(
    _$AppDatabase db,
    $CachedInningsStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CachedInningsStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$CachedInningsStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CachedInningsStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> matchId = const Value.absent(),
                Value<int> inningsNumber = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedInningsStatesCompanion(
                matchId: matchId,
                inningsNumber: inningsNumber,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matchId,
                required int inningsNumber,
                required String payload,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedInningsStatesCompanion.insert(
                matchId: matchId,
                inningsNumber: inningsNumber,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedInningsStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedInningsStatesTable,
      CachedInningsStateRow,
      $$CachedInningsStatesTableFilterComposer,
      $$CachedInningsStatesTableOrderingComposer,
      $$CachedInningsStatesTableAnnotationComposer,
      $$CachedInningsStatesTableCreateCompanionBuilder,
      $$CachedInningsStatesTableUpdateCompanionBuilder,
      (
        CachedInningsStateRow,
        BaseReferences<
          _$AppDatabase,
          $CachedInningsStatesTable,
          CachedInningsStateRow
        >,
      ),
      CachedInningsStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WizardDraftsTableTableManager get wizardDrafts =>
      $$WizardDraftsTableTableManager(_db, _db.wizardDrafts);
  $$LocalChannelsTableTableManager get localChannels =>
      $$LocalChannelsTableTableManager(_db, _db.localChannels);
  $$LocalChannelMembersTableTableManager get localChannelMembers =>
      $$LocalChannelMembersTableTableManager(_db, _db.localChannelMembers);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalMessageAttachmentsTableTableManager get localMessageAttachments =>
      $$LocalMessageAttachmentsTableTableManager(
        _db,
        _db.localMessageAttachments,
      );
  $$LocalMessageReactionsTableTableManager get localMessageReactions =>
      $$LocalMessageReactionsTableTableManager(_db, _db.localMessageReactions);
  $$LocalMemberRestrictionsTableTableManager get localMemberRestrictions =>
      $$LocalMemberRestrictionsTableTableManager(
        _db,
        _db.localMemberRestrictions,
      );
  $$OutboxOperationsTableTableManager get outboxOperations =>
      $$OutboxOperationsTableTableManager(_db, _db.outboxOperations);
  $$ChannelSyncStatesTableTableManager get channelSyncStates =>
      $$ChannelSyncStatesTableTableManager(_db, _db.channelSyncStates);
  $$ChannelDraftsTableTableManager get channelDrafts =>
      $$ChannelDraftsTableTableManager(_db, _db.channelDrafts);
  $$ScoringOpsTableTableManager get scoringOps =>
      $$ScoringOpsTableTableManager(_db, _db.scoringOps);
  $$ScoringSnapshotsTableTableManager get scoringSnapshots =>
      $$ScoringSnapshotsTableTableManager(_db, _db.scoringSnapshots);
  $$CachedMatchesTableTableManager get cachedMatches =>
      $$CachedMatchesTableTableManager(_db, _db.cachedMatches);
  $$CachedMatchPlayersTableTableManager get cachedMatchPlayers =>
      $$CachedMatchPlayersTableTableManager(_db, _db.cachedMatchPlayers);
  $$CachedInningsStatesTableTableManager get cachedInningsStates =>
      $$CachedInningsStatesTableTableManager(_db, _db.cachedInningsStates);
}
