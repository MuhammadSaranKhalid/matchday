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
  /// Client-generated uuid, created ONCE when the scorer taps and reused on
  /// every retry. This is the idempotency key the server dedupes on, and it is
  /// why "the server committed it but the reply was lost" is safe to retry.
  final String opId;
  final String matchId;
  final int inningsNumber;

  /// Monotonic per (match, innings) — the order the scorer entered them, which
  /// is the order the server must receive them. Deliveries are sequential; out
  /// of order they are meaningless.
  final int localSeq;

  /// 'ball' | 'undo'.
  final String kind;

  /// The delivery as entered, JSON-encoded.
  final String payload;
  final DateTime createdAt;

  /// Null while the server still owes us this one. The outbox drains exactly
  /// the null rows, in localSeq order.
  final DateTime? syncedAt;

  /// Set when the server REFUSED this op — it answered, and the answer was no
  /// (a rule violation, a closed innings, a match already finished). Distinct
  /// from a transport failure, which leaves both timestamps null so the outbox
  /// retries.
  ///
  /// A refusal is terminal: no amount of retrying changes a no. The row is
  /// kept rather than deleted because design doc §19.3 forbids discarding a
  /// refused write — the scorer must still be able to read what could not be
  /// applied. Excluding it from `pendingOps` is what stops one permanently
  /// refused delivery from blocking the queue behind it (and, via
  /// `pendingOpsCount`, disabling undo forever).
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

  /// JSON-encoded innings state as of [throughSeq].
  final String state;

  /// The localSeq this snapshot already accounts for.
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
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageDraftsTable messageDrafts = $MessageDraftsTable(this);
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
    chats,
    messages,
    messageDrafts,
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
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageDraftsTableTableManager get messageDrafts =>
      $$MessageDraftsTableTableManager(_db, _db.messageDrafts);
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
