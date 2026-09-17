// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessageDto {

@JsonKey(name: 'message_id') String get messageId;@JsonKey(name: 'message_seq') int? get messageSeq;@JsonKey(name: 'channel_id') String get channelId;@JsonKey(name: 'sender_id') String? get senderId;@JsonKey(name: 'sender_display_name') String? get senderDisplayName;@JsonKey(name: 'message_type') String get messageType;@JsonKey(name: 'body') String? get body;@JsonKey(name: 'payload') Map<String, dynamic> get payload;@JsonKey(name: 'reply_to_message_id') String? get replyToMessageId;@JsonKey(name: 'reply_to_body') String? get replyToBody;@JsonKey(name: 'reply_to_author') String? get replyToAuthor;@JsonKey(name: 'version') int get version;@JsonKey(name: 'counts_as_unread') bool get countsAsUnread;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt;@JsonKey(name: 'edited_at') String? get editedAt;@JsonKey(name: 'deleted_at') String? get deletedAt;@JsonKey(name: 'from_me') bool get fromMe;@JsonKey(name: 'attachments') List<ChatMessageAttachmentDto> get attachments;@JsonKey(name: 'reactions') List<ChatMessageReactionDto> get reactions;
/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageDtoCopyWith<ChatMessageDto> get copyWith => _$ChatMessageDtoCopyWithImpl<ChatMessageDto>(this as ChatMessageDto, _$identity);

  /// Serializes this ChatMessageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageDto&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.messageSeq, messageSeq) || other.messageSeq == messageSeq)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.replyToBody, replyToBody) || other.replyToBody == replyToBody)&&(identical(other.replyToAuthor, replyToAuthor) || other.replyToAuthor == replyToAuthor)&&(identical(other.version, version) || other.version == version)&&(identical(other.countsAsUnread, countsAsUnread) || other.countsAsUnread == countsAsUnread)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.fromMe, fromMe) || other.fromMe == fromMe)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&const DeepCollectionEquality().equals(other.reactions, reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,messageId,messageSeq,channelId,senderId,senderDisplayName,messageType,body,const DeepCollectionEquality().hash(payload),replyToMessageId,replyToBody,replyToAuthor,version,countsAsUnread,createdAt,updatedAt,editedAt,deletedAt,fromMe,const DeepCollectionEquality().hash(attachments),const DeepCollectionEquality().hash(reactions)]);

@override
String toString() {
  return 'ChatMessageDto(messageId: $messageId, messageSeq: $messageSeq, channelId: $channelId, senderId: $senderId, senderDisplayName: $senderDisplayName, messageType: $messageType, body: $body, payload: $payload, replyToMessageId: $replyToMessageId, replyToBody: $replyToBody, replyToAuthor: $replyToAuthor, version: $version, countsAsUnread: $countsAsUnread, createdAt: $createdAt, updatedAt: $updatedAt, editedAt: $editedAt, deletedAt: $deletedAt, fromMe: $fromMe, attachments: $attachments, reactions: $reactions)';
}


}

/// @nodoc
abstract mixin class $ChatMessageDtoCopyWith<$Res>  {
  factory $ChatMessageDtoCopyWith(ChatMessageDto value, $Res Function(ChatMessageDto) _then) = _$ChatMessageDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'message_seq') int? messageSeq,@JsonKey(name: 'channel_id') String channelId,@JsonKey(name: 'sender_id') String? senderId,@JsonKey(name: 'sender_display_name') String? senderDisplayName,@JsonKey(name: 'message_type') String messageType,@JsonKey(name: 'body') String? body,@JsonKey(name: 'payload') Map<String, dynamic> payload,@JsonKey(name: 'reply_to_message_id') String? replyToMessageId,@JsonKey(name: 'reply_to_body') String? replyToBody,@JsonKey(name: 'reply_to_author') String? replyToAuthor,@JsonKey(name: 'version') int version,@JsonKey(name: 'counts_as_unread') bool countsAsUnread,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'edited_at') String? editedAt,@JsonKey(name: 'deleted_at') String? deletedAt,@JsonKey(name: 'from_me') bool fromMe,@JsonKey(name: 'attachments') List<ChatMessageAttachmentDto> attachments,@JsonKey(name: 'reactions') List<ChatMessageReactionDto> reactions
});




}
/// @nodoc
class _$ChatMessageDtoCopyWithImpl<$Res>
    implements $ChatMessageDtoCopyWith<$Res> {
  _$ChatMessageDtoCopyWithImpl(this._self, this._then);

  final ChatMessageDto _self;
  final $Res Function(ChatMessageDto) _then;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? messageSeq = freezed,Object? channelId = null,Object? senderId = freezed,Object? senderDisplayName = freezed,Object? messageType = null,Object? body = freezed,Object? payload = null,Object? replyToMessageId = freezed,Object? replyToBody = freezed,Object? replyToAuthor = freezed,Object? version = null,Object? countsAsUnread = null,Object? createdAt = null,Object? updatedAt = freezed,Object? editedAt = freezed,Object? deletedAt = freezed,Object? fromMe = null,Object? attachments = null,Object? reactions = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,messageSeq: freezed == messageSeq ? _self.messageSeq : messageSeq // ignore: cast_nullable_to_non_nullable
as int?,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,senderDisplayName: freezed == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,replyToBody: freezed == replyToBody ? _self.replyToBody : replyToBody // ignore: cast_nullable_to_non_nullable
as String?,replyToAuthor: freezed == replyToAuthor ? _self.replyToAuthor : replyToAuthor // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,countsAsUnread: null == countsAsUnread ? _self.countsAsUnread : countsAsUnread // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as String?,fromMe: null == fromMe ? _self.fromMe : fromMe // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ChatMessageAttachmentDto>,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<ChatMessageReactionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageDto].
extension ChatMessageDtoPatterns on ChatMessageDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'message_seq')  int? messageSeq, @JsonKey(name: 'channel_id')  String channelId, @JsonKey(name: 'sender_id')  String? senderId, @JsonKey(name: 'sender_display_name')  String? senderDisplayName, @JsonKey(name: 'message_type')  String messageType, @JsonKey(name: 'body')  String? body, @JsonKey(name: 'payload')  Map<String, dynamic> payload, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'reply_to_body')  String? replyToBody, @JsonKey(name: 'reply_to_author')  String? replyToAuthor, @JsonKey(name: 'version')  int version, @JsonKey(name: 'counts_as_unread')  bool countsAsUnread, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'edited_at')  String? editedAt, @JsonKey(name: 'deleted_at')  String? deletedAt, @JsonKey(name: 'from_me')  bool fromMe, @JsonKey(name: 'attachments')  List<ChatMessageAttachmentDto> attachments, @JsonKey(name: 'reactions')  List<ChatMessageReactionDto> reactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that.messageId,_that.messageSeq,_that.channelId,_that.senderId,_that.senderDisplayName,_that.messageType,_that.body,_that.payload,_that.replyToMessageId,_that.replyToBody,_that.replyToAuthor,_that.version,_that.countsAsUnread,_that.createdAt,_that.updatedAt,_that.editedAt,_that.deletedAt,_that.fromMe,_that.attachments,_that.reactions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'message_seq')  int? messageSeq, @JsonKey(name: 'channel_id')  String channelId, @JsonKey(name: 'sender_id')  String? senderId, @JsonKey(name: 'sender_display_name')  String? senderDisplayName, @JsonKey(name: 'message_type')  String messageType, @JsonKey(name: 'body')  String? body, @JsonKey(name: 'payload')  Map<String, dynamic> payload, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'reply_to_body')  String? replyToBody, @JsonKey(name: 'reply_to_author')  String? replyToAuthor, @JsonKey(name: 'version')  int version, @JsonKey(name: 'counts_as_unread')  bool countsAsUnread, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'edited_at')  String? editedAt, @JsonKey(name: 'deleted_at')  String? deletedAt, @JsonKey(name: 'from_me')  bool fromMe, @JsonKey(name: 'attachments')  List<ChatMessageAttachmentDto> attachments, @JsonKey(name: 'reactions')  List<ChatMessageReactionDto> reactions)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDto():
return $default(_that.messageId,_that.messageSeq,_that.channelId,_that.senderId,_that.senderDisplayName,_that.messageType,_that.body,_that.payload,_that.replyToMessageId,_that.replyToBody,_that.replyToAuthor,_that.version,_that.countsAsUnread,_that.createdAt,_that.updatedAt,_that.editedAt,_that.deletedAt,_that.fromMe,_that.attachments,_that.reactions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'message_seq')  int? messageSeq, @JsonKey(name: 'channel_id')  String channelId, @JsonKey(name: 'sender_id')  String? senderId, @JsonKey(name: 'sender_display_name')  String? senderDisplayName, @JsonKey(name: 'message_type')  String messageType, @JsonKey(name: 'body')  String? body, @JsonKey(name: 'payload')  Map<String, dynamic> payload, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'reply_to_body')  String? replyToBody, @JsonKey(name: 'reply_to_author')  String? replyToAuthor, @JsonKey(name: 'version')  int version, @JsonKey(name: 'counts_as_unread')  bool countsAsUnread, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'edited_at')  String? editedAt, @JsonKey(name: 'deleted_at')  String? deletedAt, @JsonKey(name: 'from_me')  bool fromMe, @JsonKey(name: 'attachments')  List<ChatMessageAttachmentDto> attachments, @JsonKey(name: 'reactions')  List<ChatMessageReactionDto> reactions)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that.messageId,_that.messageSeq,_that.channelId,_that.senderId,_that.senderDisplayName,_that.messageType,_that.body,_that.payload,_that.replyToMessageId,_that.replyToBody,_that.replyToAuthor,_that.version,_that.countsAsUnread,_that.createdAt,_that.updatedAt,_that.editedAt,_that.deletedAt,_that.fromMe,_that.attachments,_that.reactions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessageDto extends ChatMessageDto {
  const _ChatMessageDto({@JsonKey(name: 'message_id') required this.messageId, @JsonKey(name: 'message_seq') this.messageSeq, @JsonKey(name: 'channel_id') required this.channelId, @JsonKey(name: 'sender_id') this.senderId, @JsonKey(name: 'sender_display_name') this.senderDisplayName, @JsonKey(name: 'message_type') this.messageType = 'text', @JsonKey(name: 'body') this.body, @JsonKey(name: 'payload') final  Map<String, dynamic> payload = const {}, @JsonKey(name: 'reply_to_message_id') this.replyToMessageId, @JsonKey(name: 'reply_to_body') this.replyToBody, @JsonKey(name: 'reply_to_author') this.replyToAuthor, @JsonKey(name: 'version') this.version = 1, @JsonKey(name: 'counts_as_unread') this.countsAsUnread = true, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'edited_at') this.editedAt, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'from_me') this.fromMe = false, @JsonKey(name: 'attachments') final  List<ChatMessageAttachmentDto> attachments = const [], @JsonKey(name: 'reactions') final  List<ChatMessageReactionDto> reactions = const []}): _payload = payload,_attachments = attachments,_reactions = reactions,super._();
  factory _ChatMessageDto.fromJson(Map<String, dynamic> json) => _$ChatMessageDtoFromJson(json);

@override@JsonKey(name: 'message_id') final  String messageId;
@override@JsonKey(name: 'message_seq') final  int? messageSeq;
@override@JsonKey(name: 'channel_id') final  String channelId;
@override@JsonKey(name: 'sender_id') final  String? senderId;
@override@JsonKey(name: 'sender_display_name') final  String? senderDisplayName;
@override@JsonKey(name: 'message_type') final  String messageType;
@override@JsonKey(name: 'body') final  String? body;
 final  Map<String, dynamic> _payload;
@override@JsonKey(name: 'payload') Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override@JsonKey(name: 'reply_to_message_id') final  String? replyToMessageId;
@override@JsonKey(name: 'reply_to_body') final  String? replyToBody;
@override@JsonKey(name: 'reply_to_author') final  String? replyToAuthor;
@override@JsonKey(name: 'version') final  int version;
@override@JsonKey(name: 'counts_as_unread') final  bool countsAsUnread;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;
@override@JsonKey(name: 'edited_at') final  String? editedAt;
@override@JsonKey(name: 'deleted_at') final  String? deletedAt;
@override@JsonKey(name: 'from_me') final  bool fromMe;
 final  List<ChatMessageAttachmentDto> _attachments;
@override@JsonKey(name: 'attachments') List<ChatMessageAttachmentDto> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

 final  List<ChatMessageReactionDto> _reactions;
@override@JsonKey(name: 'reactions') List<ChatMessageReactionDto> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}


/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageDtoCopyWith<_ChatMessageDto> get copyWith => __$ChatMessageDtoCopyWithImpl<_ChatMessageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageDto&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.messageSeq, messageSeq) || other.messageSeq == messageSeq)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.replyToBody, replyToBody) || other.replyToBody == replyToBody)&&(identical(other.replyToAuthor, replyToAuthor) || other.replyToAuthor == replyToAuthor)&&(identical(other.version, version) || other.version == version)&&(identical(other.countsAsUnread, countsAsUnread) || other.countsAsUnread == countsAsUnread)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.fromMe, fromMe) || other.fromMe == fromMe)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&const DeepCollectionEquality().equals(other._reactions, _reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,messageId,messageSeq,channelId,senderId,senderDisplayName,messageType,body,const DeepCollectionEquality().hash(_payload),replyToMessageId,replyToBody,replyToAuthor,version,countsAsUnread,createdAt,updatedAt,editedAt,deletedAt,fromMe,const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_reactions)]);

@override
String toString() {
  return 'ChatMessageDto(messageId: $messageId, messageSeq: $messageSeq, channelId: $channelId, senderId: $senderId, senderDisplayName: $senderDisplayName, messageType: $messageType, body: $body, payload: $payload, replyToMessageId: $replyToMessageId, replyToBody: $replyToBody, replyToAuthor: $replyToAuthor, version: $version, countsAsUnread: $countsAsUnread, createdAt: $createdAt, updatedAt: $updatedAt, editedAt: $editedAt, deletedAt: $deletedAt, fromMe: $fromMe, attachments: $attachments, reactions: $reactions)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageDtoCopyWith<$Res> implements $ChatMessageDtoCopyWith<$Res> {
  factory _$ChatMessageDtoCopyWith(_ChatMessageDto value, $Res Function(_ChatMessageDto) _then) = __$ChatMessageDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'message_seq') int? messageSeq,@JsonKey(name: 'channel_id') String channelId,@JsonKey(name: 'sender_id') String? senderId,@JsonKey(name: 'sender_display_name') String? senderDisplayName,@JsonKey(name: 'message_type') String messageType,@JsonKey(name: 'body') String? body,@JsonKey(name: 'payload') Map<String, dynamic> payload,@JsonKey(name: 'reply_to_message_id') String? replyToMessageId,@JsonKey(name: 'reply_to_body') String? replyToBody,@JsonKey(name: 'reply_to_author') String? replyToAuthor,@JsonKey(name: 'version') int version,@JsonKey(name: 'counts_as_unread') bool countsAsUnread,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'edited_at') String? editedAt,@JsonKey(name: 'deleted_at') String? deletedAt,@JsonKey(name: 'from_me') bool fromMe,@JsonKey(name: 'attachments') List<ChatMessageAttachmentDto> attachments,@JsonKey(name: 'reactions') List<ChatMessageReactionDto> reactions
});




}
/// @nodoc
class __$ChatMessageDtoCopyWithImpl<$Res>
    implements _$ChatMessageDtoCopyWith<$Res> {
  __$ChatMessageDtoCopyWithImpl(this._self, this._then);

  final _ChatMessageDto _self;
  final $Res Function(_ChatMessageDto) _then;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? messageSeq = freezed,Object? channelId = null,Object? senderId = freezed,Object? senderDisplayName = freezed,Object? messageType = null,Object? body = freezed,Object? payload = null,Object? replyToMessageId = freezed,Object? replyToBody = freezed,Object? replyToAuthor = freezed,Object? version = null,Object? countsAsUnread = null,Object? createdAt = null,Object? updatedAt = freezed,Object? editedAt = freezed,Object? deletedAt = freezed,Object? fromMe = null,Object? attachments = null,Object? reactions = null,}) {
  return _then(_ChatMessageDto(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,messageSeq: freezed == messageSeq ? _self.messageSeq : messageSeq // ignore: cast_nullable_to_non_nullable
as int?,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,senderDisplayName: freezed == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,replyToBody: freezed == replyToBody ? _self.replyToBody : replyToBody // ignore: cast_nullable_to_non_nullable
as String?,replyToAuthor: freezed == replyToAuthor ? _self.replyToAuthor : replyToAuthor // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,countsAsUnread: null == countsAsUnread ? _self.countsAsUnread : countsAsUnread // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as String?,fromMe: null == fromMe ? _self.fromMe : fromMe // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ChatMessageAttachmentDto>,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<ChatMessageReactionDto>,
  ));
}


}


/// @nodoc
mixin _$ChatMessageAttachmentDto {

@JsonKey(name: 'attachment_id') String get attachmentId;@JsonKey(name: 'message_id') String get messageId;@JsonKey(name: 'storage_path') String? get storagePath;@JsonKey(name: 'mime_type') String get mimeType;@JsonKey(name: 'file_name') String? get fileName;@JsonKey(name: 'size_bytes') int? get sizeBytes;@JsonKey(name: 'width') int? get width;@JsonKey(name: 'height') int? get height;@JsonKey(name: 'duration_ms') int? get durationMs;
/// Create a copy of ChatMessageAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageAttachmentDtoCopyWith<ChatMessageAttachmentDto> get copyWith => _$ChatMessageAttachmentDtoCopyWithImpl<ChatMessageAttachmentDto>(this as ChatMessageAttachmentDto, _$identity);

  /// Serializes this ChatMessageAttachmentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageAttachmentDto&&(identical(other.attachmentId, attachmentId) || other.attachmentId == attachmentId)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attachmentId,messageId,storagePath,mimeType,fileName,sizeBytes,width,height,durationMs);

@override
String toString() {
  return 'ChatMessageAttachmentDto(attachmentId: $attachmentId, messageId: $messageId, storagePath: $storagePath, mimeType: $mimeType, fileName: $fileName, sizeBytes: $sizeBytes, width: $width, height: $height, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $ChatMessageAttachmentDtoCopyWith<$Res>  {
  factory $ChatMessageAttachmentDtoCopyWith(ChatMessageAttachmentDto value, $Res Function(ChatMessageAttachmentDto) _then) = _$ChatMessageAttachmentDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'attachment_id') String attachmentId,@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'storage_path') String? storagePath,@JsonKey(name: 'mime_type') String mimeType,@JsonKey(name: 'file_name') String? fileName,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width') int? width,@JsonKey(name: 'height') int? height,@JsonKey(name: 'duration_ms') int? durationMs
});




}
/// @nodoc
class _$ChatMessageAttachmentDtoCopyWithImpl<$Res>
    implements $ChatMessageAttachmentDtoCopyWith<$Res> {
  _$ChatMessageAttachmentDtoCopyWithImpl(this._self, this._then);

  final ChatMessageAttachmentDto _self;
  final $Res Function(ChatMessageAttachmentDto) _then;

/// Create a copy of ChatMessageAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attachmentId = null,Object? messageId = null,Object? storagePath = freezed,Object? mimeType = null,Object? fileName = freezed,Object? sizeBytes = freezed,Object? width = freezed,Object? height = freezed,Object? durationMs = freezed,}) {
  return _then(_self.copyWith(
attachmentId: null == attachmentId ? _self.attachmentId : attachmentId // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,storagePath: freezed == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String?,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageAttachmentDto].
extension ChatMessageAttachmentDtoPatterns on ChatMessageAttachmentDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageAttachmentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageAttachmentDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageAttachmentDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageAttachmentDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageAttachmentDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageAttachmentDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'attachment_id')  String attachmentId, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'storage_path')  String? storagePath, @JsonKey(name: 'mime_type')  String mimeType, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width')  int? width, @JsonKey(name: 'height')  int? height, @JsonKey(name: 'duration_ms')  int? durationMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageAttachmentDto() when $default != null:
return $default(_that.attachmentId,_that.messageId,_that.storagePath,_that.mimeType,_that.fileName,_that.sizeBytes,_that.width,_that.height,_that.durationMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'attachment_id')  String attachmentId, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'storage_path')  String? storagePath, @JsonKey(name: 'mime_type')  String mimeType, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width')  int? width, @JsonKey(name: 'height')  int? height, @JsonKey(name: 'duration_ms')  int? durationMs)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageAttachmentDto():
return $default(_that.attachmentId,_that.messageId,_that.storagePath,_that.mimeType,_that.fileName,_that.sizeBytes,_that.width,_that.height,_that.durationMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'attachment_id')  String attachmentId, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'storage_path')  String? storagePath, @JsonKey(name: 'mime_type')  String mimeType, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width')  int? width, @JsonKey(name: 'height')  int? height, @JsonKey(name: 'duration_ms')  int? durationMs)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageAttachmentDto() when $default != null:
return $default(_that.attachmentId,_that.messageId,_that.storagePath,_that.mimeType,_that.fileName,_that.sizeBytes,_that.width,_that.height,_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessageAttachmentDto extends ChatMessageAttachmentDto {
  const _ChatMessageAttachmentDto({@JsonKey(name: 'attachment_id') required this.attachmentId, @JsonKey(name: 'message_id') required this.messageId, @JsonKey(name: 'storage_path') this.storagePath, @JsonKey(name: 'mime_type') required this.mimeType, @JsonKey(name: 'file_name') this.fileName, @JsonKey(name: 'size_bytes') this.sizeBytes, @JsonKey(name: 'width') this.width, @JsonKey(name: 'height') this.height, @JsonKey(name: 'duration_ms') this.durationMs}): super._();
  factory _ChatMessageAttachmentDto.fromJson(Map<String, dynamic> json) => _$ChatMessageAttachmentDtoFromJson(json);

@override@JsonKey(name: 'attachment_id') final  String attachmentId;
@override@JsonKey(name: 'message_id') final  String messageId;
@override@JsonKey(name: 'storage_path') final  String? storagePath;
@override@JsonKey(name: 'mime_type') final  String mimeType;
@override@JsonKey(name: 'file_name') final  String? fileName;
@override@JsonKey(name: 'size_bytes') final  int? sizeBytes;
@override@JsonKey(name: 'width') final  int? width;
@override@JsonKey(name: 'height') final  int? height;
@override@JsonKey(name: 'duration_ms') final  int? durationMs;

/// Create a copy of ChatMessageAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageAttachmentDtoCopyWith<_ChatMessageAttachmentDto> get copyWith => __$ChatMessageAttachmentDtoCopyWithImpl<_ChatMessageAttachmentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageAttachmentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageAttachmentDto&&(identical(other.attachmentId, attachmentId) || other.attachmentId == attachmentId)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attachmentId,messageId,storagePath,mimeType,fileName,sizeBytes,width,height,durationMs);

@override
String toString() {
  return 'ChatMessageAttachmentDto(attachmentId: $attachmentId, messageId: $messageId, storagePath: $storagePath, mimeType: $mimeType, fileName: $fileName, sizeBytes: $sizeBytes, width: $width, height: $height, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageAttachmentDtoCopyWith<$Res> implements $ChatMessageAttachmentDtoCopyWith<$Res> {
  factory _$ChatMessageAttachmentDtoCopyWith(_ChatMessageAttachmentDto value, $Res Function(_ChatMessageAttachmentDto) _then) = __$ChatMessageAttachmentDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'attachment_id') String attachmentId,@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'storage_path') String? storagePath,@JsonKey(name: 'mime_type') String mimeType,@JsonKey(name: 'file_name') String? fileName,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width') int? width,@JsonKey(name: 'height') int? height,@JsonKey(name: 'duration_ms') int? durationMs
});




}
/// @nodoc
class __$ChatMessageAttachmentDtoCopyWithImpl<$Res>
    implements _$ChatMessageAttachmentDtoCopyWith<$Res> {
  __$ChatMessageAttachmentDtoCopyWithImpl(this._self, this._then);

  final _ChatMessageAttachmentDto _self;
  final $Res Function(_ChatMessageAttachmentDto) _then;

/// Create a copy of ChatMessageAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attachmentId = null,Object? messageId = null,Object? storagePath = freezed,Object? mimeType = null,Object? fileName = freezed,Object? sizeBytes = freezed,Object? width = freezed,Object? height = freezed,Object? durationMs = freezed,}) {
  return _then(_ChatMessageAttachmentDto(
attachmentId: null == attachmentId ? _self.attachmentId : attachmentId // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,storagePath: freezed == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String?,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ChatMessageReactionDto {

@JsonKey(name: 'message_id') String get messageId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'reaction') String get reaction;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'removed_at') String? get removedAt;
/// Create a copy of ChatMessageReactionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageReactionDtoCopyWith<ChatMessageReactionDto> get copyWith => _$ChatMessageReactionDtoCopyWithImpl<ChatMessageReactionDto>(this as ChatMessageReactionDto, _$identity);

  /// Serializes this ChatMessageReactionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageReactionDto&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.reaction, reaction) || other.reaction == reaction)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.removedAt, removedAt) || other.removedAt == removedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userId,reaction,createdAt,removedAt);

@override
String toString() {
  return 'ChatMessageReactionDto(messageId: $messageId, userId: $userId, reaction: $reaction, createdAt: $createdAt, removedAt: $removedAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageReactionDtoCopyWith<$Res>  {
  factory $ChatMessageReactionDtoCopyWith(ChatMessageReactionDto value, $Res Function(ChatMessageReactionDto) _then) = _$ChatMessageReactionDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'reaction') String reaction,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'removed_at') String? removedAt
});




}
/// @nodoc
class _$ChatMessageReactionDtoCopyWithImpl<$Res>
    implements $ChatMessageReactionDtoCopyWith<$Res> {
  _$ChatMessageReactionDtoCopyWithImpl(this._self, this._then);

  final ChatMessageReactionDto _self;
  final $Res Function(ChatMessageReactionDto) _then;

/// Create a copy of ChatMessageReactionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? userId = null,Object? reaction = null,Object? createdAt = null,Object? removedAt = freezed,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,reaction: null == reaction ? _self.reaction : reaction // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,removedAt: freezed == removedAt ? _self.removedAt : removedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageReactionDto].
extension ChatMessageReactionDtoPatterns on ChatMessageReactionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageReactionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageReactionDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageReactionDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageReactionDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageReactionDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageReactionDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'reaction')  String reaction, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'removed_at')  String? removedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageReactionDto() when $default != null:
return $default(_that.messageId,_that.userId,_that.reaction,_that.createdAt,_that.removedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'reaction')  String reaction, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'removed_at')  String? removedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageReactionDto():
return $default(_that.messageId,_that.userId,_that.reaction,_that.createdAt,_that.removedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'reaction')  String reaction, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'removed_at')  String? removedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageReactionDto() when $default != null:
return $default(_that.messageId,_that.userId,_that.reaction,_that.createdAt,_that.removedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessageReactionDto extends ChatMessageReactionDto {
  const _ChatMessageReactionDto({@JsonKey(name: 'message_id') required this.messageId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'reaction') required this.reaction, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'removed_at') this.removedAt}): super._();
  factory _ChatMessageReactionDto.fromJson(Map<String, dynamic> json) => _$ChatMessageReactionDtoFromJson(json);

@override@JsonKey(name: 'message_id') final  String messageId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'reaction') final  String reaction;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'removed_at') final  String? removedAt;

/// Create a copy of ChatMessageReactionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageReactionDtoCopyWith<_ChatMessageReactionDto> get copyWith => __$ChatMessageReactionDtoCopyWithImpl<_ChatMessageReactionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageReactionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageReactionDto&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.reaction, reaction) || other.reaction == reaction)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.removedAt, removedAt) || other.removedAt == removedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userId,reaction,createdAt,removedAt);

@override
String toString() {
  return 'ChatMessageReactionDto(messageId: $messageId, userId: $userId, reaction: $reaction, createdAt: $createdAt, removedAt: $removedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageReactionDtoCopyWith<$Res> implements $ChatMessageReactionDtoCopyWith<$Res> {
  factory _$ChatMessageReactionDtoCopyWith(_ChatMessageReactionDto value, $Res Function(_ChatMessageReactionDto) _then) = __$ChatMessageReactionDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'reaction') String reaction,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'removed_at') String? removedAt
});




}
/// @nodoc
class __$ChatMessageReactionDtoCopyWithImpl<$Res>
    implements _$ChatMessageReactionDtoCopyWith<$Res> {
  __$ChatMessageReactionDtoCopyWithImpl(this._self, this._then);

  final _ChatMessageReactionDto _self;
  final $Res Function(_ChatMessageReactionDto) _then;

/// Create a copy of ChatMessageReactionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? userId = null,Object? reaction = null,Object? createdAt = null,Object? removedAt = freezed,}) {
  return _then(_ChatMessageReactionDto(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,reaction: null == reaction ? _self.reaction : reaction // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,removedAt: freezed == removedAt ? _self.removedAt : removedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
