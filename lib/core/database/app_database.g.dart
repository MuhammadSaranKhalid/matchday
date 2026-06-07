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

class $ChatsTable extends Chats with TableInfo<$ChatsTable, ChatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _teamNameMeta = const VerificationMeta(
    'teamName',
  );
  @override
  late final GeneratedColumn<String> teamName = GeneratedColumn<String>(
    'team_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamLogoUrlMeta = const VerificationMeta(
    'teamLogoUrl',
  );
  @override
  late final GeneratedColumn<String> teamLogoUrl = GeneratedColumn<String>(
    'team_logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamLogoMonogramMeta = const VerificationMeta(
    'teamLogoMonogram',
  );
  @override
  late final GeneratedColumn<String> teamLogoMonogram = GeneratedColumn<String>(
    'team_logo_monogram',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamPrimaryColorHexMeta =
      const VerificationMeta('teamPrimaryColorHex');
  @override
  late final GeneratedColumn<String> teamPrimaryColorHex =
      GeneratedColumn<String>(
        'team_primary_color_hex',
        aliasedName,
        true,
        type: DriftSqlType.string,
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
  static const VerificationMeta _lastMessageBodyMeta = const VerificationMeta(
    'lastMessageBody',
  );
  @override
  late final GeneratedColumn<String> lastMessageBody = GeneratedColumn<String>(
    'last_message_body',
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
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    chatId,
    type,
    teamId,
    teamName,
    teamLogoUrl,
    teamLogoMonogram,
    teamPrimaryColorHex,
    lastMessageAt,
    lastMessageBody,
    lastMessageSenderId,
    lastMessageFromMe,
    unreadCount,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('team_name')) {
      context.handle(
        _teamNameMeta,
        teamName.isAcceptableOrUnknown(data['team_name']!, _teamNameMeta),
      );
    }
    if (data.containsKey('team_logo_url')) {
      context.handle(
        _teamLogoUrlMeta,
        teamLogoUrl.isAcceptableOrUnknown(
          data['team_logo_url']!,
          _teamLogoUrlMeta,
        ),
      );
    }
    if (data.containsKey('team_logo_monogram')) {
      context.handle(
        _teamLogoMonogramMeta,
        teamLogoMonogram.isAcceptableOrUnknown(
          data['team_logo_monogram']!,
          _teamLogoMonogramMeta,
        ),
      );
    }
    if (data.containsKey('team_primary_color_hex')) {
      context.handle(
        _teamPrimaryColorHexMeta,
        teamPrimaryColorHex.isAcceptableOrUnknown(
          data['team_primary_color_hex']!,
          _teamPrimaryColorHexMeta,
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
    if (data.containsKey('last_message_body')) {
      context.handle(
        _lastMessageBodyMeta,
        lastMessageBody.isAcceptableOrUnknown(
          data['last_message_body']!,
          _lastMessageBodyMeta,
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
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId};
  @override
  ChatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatRow(
      chatId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}chat_id'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      ),
      teamName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_name'],
      ),
      teamLogoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_logo_url'],
      ),
      teamLogoMonogram: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_logo_monogram'],
      ),
      teamPrimaryColorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_primary_color_hex'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      lastMessageBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_body'],
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
      cachedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}cached_at'],
          )!,
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class ChatRow extends DataClass implements Insertable<ChatRow> {
  final String chatId;
  final String type;
  final String? teamId;
  final String? teamName;
  final String? teamLogoUrl;
  final String? teamLogoMonogram;
  final String? teamPrimaryColorHex;
  final DateTime? lastMessageAt;
  final String? lastMessageBody;
  final String? lastMessageSenderId;
  final bool lastMessageFromMe;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime cachedAt;
  const ChatRow({
    required this.chatId,
    required this.type,
    this.teamId,
    this.teamName,
    this.teamLogoUrl,
    this.teamLogoMonogram,
    this.teamPrimaryColorHex,
    this.lastMessageAt,
    this.lastMessageBody,
    this.lastMessageSenderId,
    required this.lastMessageFromMe,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || teamName != null) {
      map['team_name'] = Variable<String>(teamName);
    }
    if (!nullToAbsent || teamLogoUrl != null) {
      map['team_logo_url'] = Variable<String>(teamLogoUrl);
    }
    if (!nullToAbsent || teamLogoMonogram != null) {
      map['team_logo_monogram'] = Variable<String>(teamLogoMonogram);
    }
    if (!nullToAbsent || teamPrimaryColorHex != null) {
      map['team_primary_color_hex'] = Variable<String>(teamPrimaryColorHex);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    if (!nullToAbsent || lastMessageBody != null) {
      map['last_message_body'] = Variable<String>(lastMessageBody);
    }
    if (!nullToAbsent || lastMessageSenderId != null) {
      map['last_message_sender_id'] = Variable<String>(lastMessageSenderId);
    }
    map['last_message_from_me'] = Variable<bool>(lastMessageFromMe);
    map['unread_count'] = Variable<int>(unreadCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      chatId: Value(chatId),
      type: Value(type),
      teamId:
          teamId == null && nullToAbsent ? const Value.absent() : Value(teamId),
      teamName:
          teamName == null && nullToAbsent
              ? const Value.absent()
              : Value(teamName),
      teamLogoUrl:
          teamLogoUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(teamLogoUrl),
      teamLogoMonogram:
          teamLogoMonogram == null && nullToAbsent
              ? const Value.absent()
              : Value(teamLogoMonogram),
      teamPrimaryColorHex:
          teamPrimaryColorHex == null && nullToAbsent
              ? const Value.absent()
              : Value(teamPrimaryColorHex),
      lastMessageAt:
          lastMessageAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessageAt),
      lastMessageBody:
          lastMessageBody == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessageBody),
      lastMessageSenderId:
          lastMessageSenderId == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessageSenderId),
      lastMessageFromMe: Value(lastMessageFromMe),
      unreadCount: Value(unreadCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory ChatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatRow(
      chatId: serializer.fromJson<String>(json['chatId']),
      type: serializer.fromJson<String>(json['type']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      teamName: serializer.fromJson<String?>(json['teamName']),
      teamLogoUrl: serializer.fromJson<String?>(json['teamLogoUrl']),
      teamLogoMonogram: serializer.fromJson<String?>(json['teamLogoMonogram']),
      teamPrimaryColorHex: serializer.fromJson<String?>(
        json['teamPrimaryColorHex'],
      ),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      lastMessageBody: serializer.fromJson<String?>(json['lastMessageBody']),
      lastMessageSenderId: serializer.fromJson<String?>(
        json['lastMessageSenderId'],
      ),
      lastMessageFromMe: serializer.fromJson<bool>(json['lastMessageFromMe']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'type': serializer.toJson<String>(type),
      'teamId': serializer.toJson<String?>(teamId),
      'teamName': serializer.toJson<String?>(teamName),
      'teamLogoUrl': serializer.toJson<String?>(teamLogoUrl),
      'teamLogoMonogram': serializer.toJson<String?>(teamLogoMonogram),
      'teamPrimaryColorHex': serializer.toJson<String?>(teamPrimaryColorHex),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'lastMessageBody': serializer.toJson<String?>(lastMessageBody),
      'lastMessageSenderId': serializer.toJson<String?>(lastMessageSenderId),
      'lastMessageFromMe': serializer.toJson<bool>(lastMessageFromMe),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ChatRow copyWith({
    String? chatId,
    String? type,
    Value<String?> teamId = const Value.absent(),
    Value<String?> teamName = const Value.absent(),
    Value<String?> teamLogoUrl = const Value.absent(),
    Value<String?> teamLogoMonogram = const Value.absent(),
    Value<String?> teamPrimaryColorHex = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    Value<String?> lastMessageBody = const Value.absent(),
    Value<String?> lastMessageSenderId = const Value.absent(),
    bool? lastMessageFromMe,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) => ChatRow(
    chatId: chatId ?? this.chatId,
    type: type ?? this.type,
    teamId: teamId.present ? teamId.value : this.teamId,
    teamName: teamName.present ? teamName.value : this.teamName,
    teamLogoUrl: teamLogoUrl.present ? teamLogoUrl.value : this.teamLogoUrl,
    teamLogoMonogram:
        teamLogoMonogram.present
            ? teamLogoMonogram.value
            : this.teamLogoMonogram,
    teamPrimaryColorHex:
        teamPrimaryColorHex.present
            ? teamPrimaryColorHex.value
            : this.teamPrimaryColorHex,
    lastMessageAt:
        lastMessageAt.present ? lastMessageAt.value : this.lastMessageAt,
    lastMessageBody:
        lastMessageBody.present ? lastMessageBody.value : this.lastMessageBody,
    lastMessageSenderId:
        lastMessageSenderId.present
            ? lastMessageSenderId.value
            : this.lastMessageSenderId,
    lastMessageFromMe: lastMessageFromMe ?? this.lastMessageFromMe,
    unreadCount: unreadCount ?? this.unreadCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ChatRow copyWithCompanion(ChatsCompanion data) {
    return ChatRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      type: data.type.present ? data.type.value : this.type,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      teamName: data.teamName.present ? data.teamName.value : this.teamName,
      teamLogoUrl:
          data.teamLogoUrl.present ? data.teamLogoUrl.value : this.teamLogoUrl,
      teamLogoMonogram:
          data.teamLogoMonogram.present
              ? data.teamLogoMonogram.value
              : this.teamLogoMonogram,
      teamPrimaryColorHex:
          data.teamPrimaryColorHex.present
              ? data.teamPrimaryColorHex.value
              : this.teamPrimaryColorHex,
      lastMessageAt:
          data.lastMessageAt.present
              ? data.lastMessageAt.value
              : this.lastMessageAt,
      lastMessageBody:
          data.lastMessageBody.present
              ? data.lastMessageBody.value
              : this.lastMessageBody,
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
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatRow(')
          ..write('chatId: $chatId, ')
          ..write('type: $type, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('teamLogoUrl: $teamLogoUrl, ')
          ..write('teamLogoMonogram: $teamLogoMonogram, ')
          ..write('teamPrimaryColorHex: $teamPrimaryColorHex, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessageBody: $lastMessageBody, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageFromMe: $lastMessageFromMe, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    chatId,
    type,
    teamId,
    teamName,
    teamLogoUrl,
    teamLogoMonogram,
    teamPrimaryColorHex,
    lastMessageAt,
    lastMessageBody,
    lastMessageSenderId,
    lastMessageFromMe,
    unreadCount,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatRow &&
          other.chatId == this.chatId &&
          other.type == this.type &&
          other.teamId == this.teamId &&
          other.teamName == this.teamName &&
          other.teamLogoUrl == this.teamLogoUrl &&
          other.teamLogoMonogram == this.teamLogoMonogram &&
          other.teamPrimaryColorHex == this.teamPrimaryColorHex &&
          other.lastMessageAt == this.lastMessageAt &&
          other.lastMessageBody == this.lastMessageBody &&
          other.lastMessageSenderId == this.lastMessageSenderId &&
          other.lastMessageFromMe == this.lastMessageFromMe &&
          other.unreadCount == this.unreadCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class ChatsCompanion extends UpdateCompanion<ChatRow> {
  final Value<String> chatId;
  final Value<String> type;
  final Value<String?> teamId;
  final Value<String?> teamName;
  final Value<String?> teamLogoUrl;
  final Value<String?> teamLogoMonogram;
  final Value<String?> teamPrimaryColorHex;
  final Value<DateTime?> lastMessageAt;
  final Value<String?> lastMessageBody;
  final Value<String?> lastMessageSenderId;
  final Value<bool> lastMessageFromMe;
  final Value<int> unreadCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ChatsCompanion({
    this.chatId = const Value.absent(),
    this.type = const Value.absent(),
    this.teamId = const Value.absent(),
    this.teamName = const Value.absent(),
    this.teamLogoUrl = const Value.absent(),
    this.teamLogoMonogram = const Value.absent(),
    this.teamPrimaryColorHex = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessageBody = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageFromMe = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatsCompanion.insert({
    required String chatId,
    required String type,
    this.teamId = const Value.absent(),
    this.teamName = const Value.absent(),
    this.teamLogoUrl = const Value.absent(),
    this.teamLogoMonogram = const Value.absent(),
    this.teamPrimaryColorHex = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessageBody = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageFromMe = const Value.absent(),
    this.unreadCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : chatId = Value(chatId),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<ChatRow> custom({
    Expression<String>? chatId,
    Expression<String>? type,
    Expression<String>? teamId,
    Expression<String>? teamName,
    Expression<String>? teamLogoUrl,
    Expression<String>? teamLogoMonogram,
    Expression<String>? teamPrimaryColorHex,
    Expression<DateTime>? lastMessageAt,
    Expression<String>? lastMessageBody,
    Expression<String>? lastMessageSenderId,
    Expression<bool>? lastMessageFromMe,
    Expression<int>? unreadCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (type != null) 'type': type,
      if (teamId != null) 'team_id': teamId,
      if (teamName != null) 'team_name': teamName,
      if (teamLogoUrl != null) 'team_logo_url': teamLogoUrl,
      if (teamLogoMonogram != null) 'team_logo_monogram': teamLogoMonogram,
      if (teamPrimaryColorHex != null)
        'team_primary_color_hex': teamPrimaryColorHex,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (lastMessageBody != null) 'last_message_body': lastMessageBody,
      if (lastMessageSenderId != null)
        'last_message_sender_id': lastMessageSenderId,
      if (lastMessageFromMe != null) 'last_message_from_me': lastMessageFromMe,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatsCompanion copyWith({
    Value<String>? chatId,
    Value<String>? type,
    Value<String?>? teamId,
    Value<String?>? teamName,
    Value<String?>? teamLogoUrl,
    Value<String?>? teamLogoMonogram,
    Value<String?>? teamPrimaryColorHex,
    Value<DateTime?>? lastMessageAt,
    Value<String?>? lastMessageBody,
    Value<String?>? lastMessageSenderId,
    Value<bool>? lastMessageFromMe,
    Value<int>? unreadCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return ChatsCompanion(
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
      teamLogoMonogram: teamLogoMonogram ?? this.teamLogoMonogram,
      teamPrimaryColorHex: teamPrimaryColorHex ?? this.teamPrimaryColorHex,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageBody: lastMessageBody ?? this.lastMessageBody,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageFromMe: lastMessageFromMe ?? this.lastMessageFromMe,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (teamName.present) {
      map['team_name'] = Variable<String>(teamName.value);
    }
    if (teamLogoUrl.present) {
      map['team_logo_url'] = Variable<String>(teamLogoUrl.value);
    }
    if (teamLogoMonogram.present) {
      map['team_logo_monogram'] = Variable<String>(teamLogoMonogram.value);
    }
    if (teamPrimaryColorHex.present) {
      map['team_primary_color_hex'] = Variable<String>(
        teamPrimaryColorHex.value,
      );
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (lastMessageBody.present) {
      map['last_message_body'] = Variable<String>(lastMessageBody.value);
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('type: $type, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('teamLogoUrl: $teamLogoUrl, ')
          ..write('teamLogoMonogram: $teamLogoMonogram, ')
          ..write('teamPrimaryColorHex: $teamPrimaryColorHex, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessageBody: $lastMessageBody, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageFromMe: $lastMessageFromMe, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
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
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
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
  static const VerificationMeta _fromMeMeta = const VerificationMeta('fromMe');
  @override
  late final GeneratedColumn<bool> fromMe = GeneratedColumn<bool>(
    'from_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("from_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    chatId,
    senderId,
    senderDisplayName,
    body,
    createdAt,
    editedAt,
    deletedAt,
    fromMe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
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
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
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
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
    if (data.containsKey('from_me')) {
      context.handle(
        _fromMeMeta,
        fromMe.isAcceptableOrUnknown(data['from_me']!, _fromMeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      messageId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message_id'],
          )!,
      chatId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}chat_id'],
          )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      ),
      senderDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_display_name'],
      ),
      body:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}body'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}edited_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      fromMe:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}from_me'],
          )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final String messageId;
  final String chatId;
  final String? senderId;
  final String? senderDisplayName;
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final bool fromMe;
  const MessageRow({
    required this.messageId,
    required this.chatId,
    this.senderId,
    this.senderDisplayName,
    required this.body,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    required this.fromMe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['chat_id'] = Variable<String>(chatId);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<String>(senderId);
    }
    if (!nullToAbsent || senderDisplayName != null) {
      map['sender_display_name'] = Variable<String>(senderDisplayName);
    }
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['from_me'] = Variable<bool>(fromMe);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: Value(messageId),
      chatId: Value(chatId),
      senderId:
          senderId == null && nullToAbsent
              ? const Value.absent()
              : Value(senderId),
      senderDisplayName:
          senderDisplayName == null && nullToAbsent
              ? const Value.absent()
              : Value(senderDisplayName),
      body: Value(body),
      createdAt: Value(createdAt),
      editedAt:
          editedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(editedAt),
      deletedAt:
          deletedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(deletedAt),
      fromMe: Value(fromMe),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      messageId: serializer.fromJson<String>(json['messageId']),
      chatId: serializer.fromJson<String>(json['chatId']),
      senderId: serializer.fromJson<String?>(json['senderId']),
      senderDisplayName: serializer.fromJson<String?>(
        json['senderDisplayName'],
      ),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      fromMe: serializer.fromJson<bool>(json['fromMe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'chatId': serializer.toJson<String>(chatId),
      'senderId': serializer.toJson<String?>(senderId),
      'senderDisplayName': serializer.toJson<String?>(senderDisplayName),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'fromMe': serializer.toJson<bool>(fromMe),
    };
  }

  MessageRow copyWith({
    String? messageId,
    String? chatId,
    Value<String?> senderId = const Value.absent(),
    Value<String?> senderDisplayName = const Value.absent(),
    String? body,
    DateTime? createdAt,
    Value<DateTime?> editedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? fromMe,
  }) => MessageRow(
    messageId: messageId ?? this.messageId,
    chatId: chatId ?? this.chatId,
    senderId: senderId.present ? senderId.value : this.senderId,
    senderDisplayName:
        senderDisplayName.present
            ? senderDisplayName.value
            : this.senderDisplayName,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    fromMe: fromMe ?? this.fromMe,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderDisplayName:
          data.senderDisplayName.present
              ? data.senderDisplayName.value
              : this.senderDisplayName,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      fromMe: data.fromMe.present ? data.fromMe.value : this.fromMe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('senderDisplayName: $senderDisplayName, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fromMe: $fromMe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    chatId,
    senderId,
    senderDisplayName,
    body,
    createdAt,
    editedAt,
    deletedAt,
    fromMe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.messageId == this.messageId &&
          other.chatId == this.chatId &&
          other.senderId == this.senderId &&
          other.senderDisplayName == this.senderDisplayName &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt &&
          other.fromMe == this.fromMe);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> messageId;
  final Value<String> chatId;
  final Value<String?> senderId;
  final Value<String?> senderDisplayName;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime?> editedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> fromMe;
  final Value<int> rowid;
  const MessagesCompanion({
    this.messageId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderDisplayName = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.fromMe = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    required String chatId,
    this.senderId = const Value.absent(),
    this.senderDisplayName = const Value.absent(),
    required String body,
    required DateTime createdAt,
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.fromMe = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       chatId = Value(chatId),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<MessageRow> custom({
    Expression<String>? messageId,
    Expression<String>? chatId,
    Expression<String>? senderId,
    Expression<String>? senderDisplayName,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? editedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? fromMe,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (chatId != null) 'chat_id': chatId,
      if (senderId != null) 'sender_id': senderId,
      if (senderDisplayName != null) 'sender_display_name': senderDisplayName,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (fromMe != null) 'from_me': fromMe,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? chatId,
    Value<String?>? senderId,
    Value<String?>? senderDisplayName,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime?>? editedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? fromMe,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      fromMe: fromMe ?? this.fromMe,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderDisplayName.present) {
      map['sender_display_name'] = Variable<String>(senderDisplayName.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (fromMe.present) {
      map['from_me'] = Variable<bool>(fromMe.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('senderDisplayName: $senderDisplayName, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fromMe: $fromMe, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageDraftsTable extends MessageDrafts
    with TableInfo<$MessageDraftsTable, MessageDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
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
  List<GeneratedColumn> get $columns => [chatId, body, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {chatId};
  @override
  MessageDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageDraftRow(
      chatId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}chat_id'],
          )!,
      body:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}body'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $MessageDraftsTable createAlias(String alias) {
    return $MessageDraftsTable(attachedDatabase, alias);
  }
}

class MessageDraftRow extends DataClass implements Insertable<MessageDraftRow> {
  final String chatId;
  final String body;
  final DateTime updatedAt;
  const MessageDraftRow({
    required this.chatId,
    required this.body,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['body'] = Variable<String>(body);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MessageDraftsCompanion toCompanion(bool nullToAbsent) {
    return MessageDraftsCompanion(
      chatId: Value(chatId),
      body: Value(body),
      updatedAt: Value(updatedAt),
    );
  }

  factory MessageDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageDraftRow(
      chatId: serializer.fromJson<String>(json['chatId']),
      body: serializer.fromJson<String>(json['body']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'body': serializer.toJson<String>(body),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MessageDraftRow copyWith({
    String? chatId,
    String? body,
    DateTime? updatedAt,
  }) => MessageDraftRow(
    chatId: chatId ?? this.chatId,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MessageDraftRow copyWithCompanion(MessageDraftsCompanion data) {
    return MessageDraftRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      body: data.body.present ? data.body.value : this.body,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageDraftRow(')
          ..write('chatId: $chatId, ')
          ..write('body: $body, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chatId, body, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageDraftRow &&
          other.chatId == this.chatId &&
          other.body == this.body &&
          other.updatedAt == this.updatedAt);
}

class MessageDraftsCompanion extends UpdateCompanion<MessageDraftRow> {
  final Value<String> chatId;
  final Value<String> body;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MessageDraftsCompanion({
    this.chatId = const Value.absent(),
    this.body = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageDraftsCompanion.insert({
    required String chatId,
    required String body,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : chatId = Value(chatId),
       body = Value(body),
       updatedAt = Value(updatedAt);
  static Insertable<MessageDraftRow> custom({
    Expression<String>? chatId,
    Expression<String>? body,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (body != null) 'body': body,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageDraftsCompanion copyWith({
    Value<String>? chatId,
    Value<String>? body,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MessageDraftsCompanion(
      chatId: chatId ?? this.chatId,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
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
    return (StringBuffer('MessageDraftsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('body: $body, ')
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
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageDraftsTable messageDrafts = $MessageDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wizardDrafts,
    chats,
    messages,
    messageDrafts,
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
typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({
      required String chatId,
      required String type,
      Value<String?> teamId,
      Value<String?> teamName,
      Value<String?> teamLogoUrl,
      Value<String?> teamLogoMonogram,
      Value<String?> teamPrimaryColorHex,
      Value<DateTime?> lastMessageAt,
      Value<String?> lastMessageBody,
      Value<String?> lastMessageSenderId,
      Value<bool> lastMessageFromMe,
      Value<int> unreadCount,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({
      Value<String> chatId,
      Value<String> type,
      Value<String?> teamId,
      Value<String?> teamName,
      Value<String?> teamLogoUrl,
      Value<String?> teamLogoMonogram,
      Value<String?> teamPrimaryColorHex,
      Value<DateTime?> lastMessageAt,
      Value<String?> lastMessageBody,
      Value<String?> lastMessageSenderId,
      Value<bool> lastMessageFromMe,
      Value<int> unreadCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$ChatsTableFilterComposer extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamLogoUrl => $composableBuilder(
    column: $table.teamLogoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamLogoMonogram => $composableBuilder(
    column: $table.teamLogoMonogram,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamPrimaryColorHex => $composableBuilder(
    column: $table.teamPrimaryColorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageBody => $composableBuilder(
    column: $table.lastMessageBody,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamLogoUrl => $composableBuilder(
    column: $table.teamLogoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamLogoMonogram => $composableBuilder(
    column: $table.teamLogoMonogram,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamPrimaryColorHex => $composableBuilder(
    column: $table.teamPrimaryColorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageBody => $composableBuilder(
    column: $table.lastMessageBody,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get teamName =>
      $composableBuilder(column: $table.teamName, builder: (column) => column);

  GeneratedColumn<String> get teamLogoUrl => $composableBuilder(
    column: $table.teamLogoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamLogoMonogram => $composableBuilder(
    column: $table.teamLogoMonogram,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamPrimaryColorHex => $composableBuilder(
    column: $table.teamPrimaryColorHex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageBody => $composableBuilder(
    column: $table.lastMessageBody,
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTable,
          ChatRow,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (ChatRow, BaseReferences<_$AppDatabase, $ChatsTable, ChatRow>),
          ChatRow,
          PrefetchHooks Function()
        > {
  $$ChatsTableTableManager(_$AppDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chatId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> teamId = const Value.absent(),
                Value<String?> teamName = const Value.absent(),
                Value<String?> teamLogoUrl = const Value.absent(),
                Value<String?> teamLogoMonogram = const Value.absent(),
                Value<String?> teamPrimaryColorHex = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> lastMessageBody = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<bool> lastMessageFromMe = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion(
                chatId: chatId,
                type: type,
                teamId: teamId,
                teamName: teamName,
                teamLogoUrl: teamLogoUrl,
                teamLogoMonogram: teamLogoMonogram,
                teamPrimaryColorHex: teamPrimaryColorHex,
                lastMessageAt: lastMessageAt,
                lastMessageBody: lastMessageBody,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageFromMe: lastMessageFromMe,
                unreadCount: unreadCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chatId,
                required String type,
                Value<String?> teamId = const Value.absent(),
                Value<String?> teamName = const Value.absent(),
                Value<String?> teamLogoUrl = const Value.absent(),
                Value<String?> teamLogoMonogram = const Value.absent(),
                Value<String?> teamPrimaryColorHex = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> lastMessageBody = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<bool> lastMessageFromMe = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion.insert(
                chatId: chatId,
                type: type,
                teamId: teamId,
                teamName: teamName,
                teamLogoUrl: teamLogoUrl,
                teamLogoMonogram: teamLogoMonogram,
                teamPrimaryColorHex: teamPrimaryColorHex,
                lastMessageAt: lastMessageAt,
                lastMessageBody: lastMessageBody,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageFromMe: lastMessageFromMe,
                unreadCount: unreadCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
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

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTable,
      ChatRow,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (ChatRow, BaseReferences<_$AppDatabase, $ChatsTable, ChatRow>),
      ChatRow,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String messageId,
      required String chatId,
      Value<String?> senderId,
      Value<String?> senderDisplayName,
      required String body,
      required DateTime createdAt,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      Value<bool> fromMe,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> messageId,
      Value<String> chatId,
      Value<String?> senderId,
      Value<String?> senderDisplayName,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      Value<bool> fromMe,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
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

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  ColumnFilters<bool> get fromMe => $composableBuilder(
    column: $table.fromMe,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
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

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  ColumnOrderings<bool> get fromMe => $composableBuilder(
    column: $table.fromMe,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderDisplayName => $composableBuilder(
    column: $table.senderDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get fromMe =>
      $composableBuilder(column: $table.fromMe, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageRow,
            BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>,
          ),
          MessageRow,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<String?> senderId = const Value.absent(),
                Value<String?> senderDisplayName = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> fromMe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                messageId: messageId,
                chatId: chatId,
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                body: body,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                fromMe: fromMe,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String chatId,
                Value<String?> senderId = const Value.absent(),
                Value<String?> senderDisplayName = const Value.absent(),
                required String body,
                required DateTime createdAt,
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> fromMe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                messageId: messageId,
                chatId: chatId,
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                body: body,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                fromMe: fromMe,
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

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>),
      MessageRow,
      PrefetchHooks Function()
    >;
typedef $$MessageDraftsTableCreateCompanionBuilder =
    MessageDraftsCompanion Function({
      required String chatId,
      required String body,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MessageDraftsTableUpdateCompanionBuilder =
    MessageDraftsCompanion Function({
      Value<String> chatId,
      Value<String> body,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MessageDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageDraftsTable> {
  $$MessageDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageDraftsTable> {
  $$MessageDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageDraftsTable> {
  $$MessageDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MessageDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageDraftsTable,
          MessageDraftRow,
          $$MessageDraftsTableFilterComposer,
          $$MessageDraftsTableOrderingComposer,
          $$MessageDraftsTableAnnotationComposer,
          $$MessageDraftsTableCreateCompanionBuilder,
          $$MessageDraftsTableUpdateCompanionBuilder,
          (
            MessageDraftRow,
            BaseReferences<_$AppDatabase, $MessageDraftsTable, MessageDraftRow>,
          ),
          MessageDraftRow,
          PrefetchHooks Function()
        > {
  $$MessageDraftsTableTableManager(_$AppDatabase db, $MessageDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MessageDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$MessageDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$MessageDraftsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> chatId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageDraftsCompanion(
                chatId: chatId,
                body: body,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chatId,
                required String body,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MessageDraftsCompanion.insert(
                chatId: chatId,
                body: body,
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

typedef $$MessageDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageDraftsTable,
      MessageDraftRow,
      $$MessageDraftsTableFilterComposer,
      $$MessageDraftsTableOrderingComposer,
      $$MessageDraftsTableAnnotationComposer,
      $$MessageDraftsTableCreateCompanionBuilder,
      $$MessageDraftsTableUpdateCompanionBuilder,
      (
        MessageDraftRow,
        BaseReferences<_$AppDatabase, $MessageDraftsTable, MessageDraftRow>,
      ),
      MessageDraftRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WizardDraftsTableTableManager get wizardDrafts =>
      $$WizardDraftsTableTableManager(_db, _db.wizardDrafts);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageDraftsTableTableManager get messageDrafts =>
      $$MessageDraftsTableTableManager(_db, _db.messageDrafts);
}
