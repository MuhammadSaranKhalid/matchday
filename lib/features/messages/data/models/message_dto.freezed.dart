// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageDto {

@JsonKey(name: 'message_id') String get messageId;@JsonKey(name: 'chat_id') String get chatId;@JsonKey(name: 'sender_id') String? get senderId;@JsonKey(name: 'sender_display_name') String? get senderDisplayName; String get body;@JsonKey(name: 'message_type') String get messageType;@JsonKey(name: 'payload') Map<String, dynamic>? get payload;@JsonKey(name: 'reply_to_id') String? get replyToId;@JsonKey(name: 'reply_to_body') String? get replyToBody;@JsonKey(name: 'reply_to_author') String? get replyToAuthor;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'edited_at') String? get editedAt;@JsonKey(name: 'deleted_at') String? get deletedAt;@JsonKey(name: 'from_me') bool get fromMe;
/// Create a copy of MessageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageDtoCopyWith<MessageDto> get copyWith => _$MessageDtoCopyWithImpl<MessageDto>(this as MessageDto, _$identity);

  /// Serializes this MessageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageDto&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.chatId, chatId) || other.chatId == chatId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.body, body) || other.body == body)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyToBody, replyToBody) || other.replyToBody == replyToBody)&&(identical(other.replyToAuthor, replyToAuthor) || other.replyToAuthor == replyToAuthor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.fromMe, fromMe) || other.fromMe == fromMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,chatId,senderId,senderDisplayName,body,messageType,const DeepCollectionEquality().hash(payload),replyToId,replyToBody,replyToAuthor,createdAt,editedAt,deletedAt,fromMe);

@override
String toString() {
  return 'MessageDto(messageId: $messageId, chatId: $chatId, senderId: $senderId, senderDisplayName: $senderDisplayName, body: $body, messageType: $messageType, payload: $payload, replyToId: $replyToId, replyToBody: $replyToBody, replyToAuthor: $replyToAuthor, createdAt: $createdAt, editedAt: $editedAt, deletedAt: $deletedAt, fromMe: $fromMe)';
}


}

/// @nodoc
abstract mixin class $MessageDtoCopyWith<$Res>  {
  factory $MessageDtoCopyWith(MessageDto value, $Res Function(MessageDto) _then) = _$MessageDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'chat_id') String chatId,@JsonKey(name: 'sender_id') String? senderId,@JsonKey(name: 'sender_display_name') String? senderDisplayName, String body,@JsonKey(name: 'message_type') String messageType,@JsonKey(name: 'payload') Map<String, dynamic>? payload,@JsonKey(name: 'reply_to_id') String? replyToId,@JsonKey(name: 'reply_to_body') String? replyToBody,@JsonKey(name: 'reply_to_author') String? replyToAuthor,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'edited_at') String? editedAt,@JsonKey(name: 'deleted_at') String? deletedAt,@JsonKey(name: 'from_me') bool fromMe
});




}
/// @nodoc
class _$MessageDtoCopyWithImpl<$Res>
    implements $MessageDtoCopyWith<$Res> {
  _$MessageDtoCopyWithImpl(this._self, this._then);

  final MessageDto _self;
  final $Res Function(MessageDto) _then;

/// Create a copy of MessageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? chatId = null,Object? senderId = freezed,Object? senderDisplayName = freezed,Object? body = null,Object? messageType = null,Object? payload = freezed,Object? replyToId = freezed,Object? replyToBody = freezed,Object? replyToAuthor = freezed,Object? createdAt = null,Object? editedAt = freezed,Object? deletedAt = freezed,Object? fromMe = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,chatId: null == chatId ? _self.chatId : chatId // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,senderDisplayName: freezed == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyToBody: freezed == replyToBody ? _self.replyToBody : replyToBody // ignore: cast_nullable_to_non_nullable
as String?,replyToAuthor: freezed == replyToAuthor ? _self.replyToAuthor : replyToAuthor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as String?,fromMe: null == fromMe ? _self.fromMe : fromMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageDto].
extension MessageDtoPatterns on MessageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageDto value)  $default,){
final _that = this;
switch (_that) {
case _MessageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageDto value)?  $default,){
final _that = this;
switch (_that) {
case _MessageDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'chat_id')  String chatId, @JsonKey(name: 'sender_id')  String? senderId, @JsonKey(name: 'sender_display_name')  String? senderDisplayName,  String body, @JsonKey(name: 'message_type')  String messageType, @JsonKey(name: 'payload')  Map<String, dynamic>? payload, @JsonKey(name: 'reply_to_id')  String? replyToId, @JsonKey(name: 'reply_to_body')  String? replyToBody, @JsonKey(name: 'reply_to_author')  String? replyToAuthor, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'edited_at')  String? editedAt, @JsonKey(name: 'deleted_at')  String? deletedAt, @JsonKey(name: 'from_me')  bool fromMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageDto() when $default != null:
return $default(_that.messageId,_that.chatId,_that.senderId,_that.senderDisplayName,_that.body,_that.messageType,_that.payload,_that.replyToId,_that.replyToBody,_that.replyToAuthor,_that.createdAt,_that.editedAt,_that.deletedAt,_that.fromMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'chat_id')  String chatId, @JsonKey(name: 'sender_id')  String? senderId, @JsonKey(name: 'sender_display_name')  String? senderDisplayName,  String body, @JsonKey(name: 'message_type')  String messageType, @JsonKey(name: 'payload')  Map<String, dynamic>? payload, @JsonKey(name: 'reply_to_id')  String? replyToId, @JsonKey(name: 'reply_to_body')  String? replyToBody, @JsonKey(name: 'reply_to_author')  String? replyToAuthor, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'edited_at')  String? editedAt, @JsonKey(name: 'deleted_at')  String? deletedAt, @JsonKey(name: 'from_me')  bool fromMe)  $default,) {final _that = this;
switch (_that) {
case _MessageDto():
return $default(_that.messageId,_that.chatId,_that.senderId,_that.senderDisplayName,_that.body,_that.messageType,_that.payload,_that.replyToId,_that.replyToBody,_that.replyToAuthor,_that.createdAt,_that.editedAt,_that.deletedAt,_that.fromMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'chat_id')  String chatId, @JsonKey(name: 'sender_id')  String? senderId, @JsonKey(name: 'sender_display_name')  String? senderDisplayName,  String body, @JsonKey(name: 'message_type')  String messageType, @JsonKey(name: 'payload')  Map<String, dynamic>? payload, @JsonKey(name: 'reply_to_id')  String? replyToId, @JsonKey(name: 'reply_to_body')  String? replyToBody, @JsonKey(name: 'reply_to_author')  String? replyToAuthor, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'edited_at')  String? editedAt, @JsonKey(name: 'deleted_at')  String? deletedAt, @JsonKey(name: 'from_me')  bool fromMe)?  $default,) {final _that = this;
switch (_that) {
case _MessageDto() when $default != null:
return $default(_that.messageId,_that.chatId,_that.senderId,_that.senderDisplayName,_that.body,_that.messageType,_that.payload,_that.replyToId,_that.replyToBody,_that.replyToAuthor,_that.createdAt,_that.editedAt,_that.deletedAt,_that.fromMe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageDto extends MessageDto {
  const _MessageDto({@JsonKey(name: 'message_id') required this.messageId, @JsonKey(name: 'chat_id') required this.chatId, @JsonKey(name: 'sender_id') this.senderId, @JsonKey(name: 'sender_display_name') this.senderDisplayName, required this.body, @JsonKey(name: 'message_type') this.messageType = 'text', @JsonKey(name: 'payload') final  Map<String, dynamic>? payload, @JsonKey(name: 'reply_to_id') this.replyToId, @JsonKey(name: 'reply_to_body') this.replyToBody, @JsonKey(name: 'reply_to_author') this.replyToAuthor, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'edited_at') this.editedAt, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'from_me') this.fromMe = false}): _payload = payload,super._();
  factory _MessageDto.fromJson(Map<String, dynamic> json) => _$MessageDtoFromJson(json);

@override@JsonKey(name: 'message_id') final  String messageId;
@override@JsonKey(name: 'chat_id') final  String chatId;
@override@JsonKey(name: 'sender_id') final  String? senderId;
@override@JsonKey(name: 'sender_display_name') final  String? senderDisplayName;
@override final  String body;
@override@JsonKey(name: 'message_type') final  String messageType;
 final  Map<String, dynamic>? _payload;
@override@JsonKey(name: 'payload') Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'reply_to_id') final  String? replyToId;
@override@JsonKey(name: 'reply_to_body') final  String? replyToBody;
@override@JsonKey(name: 'reply_to_author') final  String? replyToAuthor;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'edited_at') final  String? editedAt;
@override@JsonKey(name: 'deleted_at') final  String? deletedAt;
@override@JsonKey(name: 'from_me') final  bool fromMe;

/// Create a copy of MessageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageDtoCopyWith<_MessageDto> get copyWith => __$MessageDtoCopyWithImpl<_MessageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageDto&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.chatId, chatId) || other.chatId == chatId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.body, body) || other.body == body)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyToBody, replyToBody) || other.replyToBody == replyToBody)&&(identical(other.replyToAuthor, replyToAuthor) || other.replyToAuthor == replyToAuthor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.fromMe, fromMe) || other.fromMe == fromMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,chatId,senderId,senderDisplayName,body,messageType,const DeepCollectionEquality().hash(_payload),replyToId,replyToBody,replyToAuthor,createdAt,editedAt,deletedAt,fromMe);

@override
String toString() {
  return 'MessageDto(messageId: $messageId, chatId: $chatId, senderId: $senderId, senderDisplayName: $senderDisplayName, body: $body, messageType: $messageType, payload: $payload, replyToId: $replyToId, replyToBody: $replyToBody, replyToAuthor: $replyToAuthor, createdAt: $createdAt, editedAt: $editedAt, deletedAt: $deletedAt, fromMe: $fromMe)';
}


}

/// @nodoc
abstract mixin class _$MessageDtoCopyWith<$Res> implements $MessageDtoCopyWith<$Res> {
  factory _$MessageDtoCopyWith(_MessageDto value, $Res Function(_MessageDto) _then) = __$MessageDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'chat_id') String chatId,@JsonKey(name: 'sender_id') String? senderId,@JsonKey(name: 'sender_display_name') String? senderDisplayName, String body,@JsonKey(name: 'message_type') String messageType,@JsonKey(name: 'payload') Map<String, dynamic>? payload,@JsonKey(name: 'reply_to_id') String? replyToId,@JsonKey(name: 'reply_to_body') String? replyToBody,@JsonKey(name: 'reply_to_author') String? replyToAuthor,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'edited_at') String? editedAt,@JsonKey(name: 'deleted_at') String? deletedAt,@JsonKey(name: 'from_me') bool fromMe
});




}
/// @nodoc
class __$MessageDtoCopyWithImpl<$Res>
    implements _$MessageDtoCopyWith<$Res> {
  __$MessageDtoCopyWithImpl(this._self, this._then);

  final _MessageDto _self;
  final $Res Function(_MessageDto) _then;

/// Create a copy of MessageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? chatId = null,Object? senderId = freezed,Object? senderDisplayName = freezed,Object? body = null,Object? messageType = null,Object? payload = freezed,Object? replyToId = freezed,Object? replyToBody = freezed,Object? replyToAuthor = freezed,Object? createdAt = null,Object? editedAt = freezed,Object? deletedAt = freezed,Object? fromMe = null,}) {
  return _then(_MessageDto(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,chatId: null == chatId ? _self.chatId : chatId // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,senderDisplayName: freezed == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyToBody: freezed == replyToBody ? _self.replyToBody : replyToBody // ignore: cast_nullable_to_non_nullable
as String?,replyToAuthor: freezed == replyToAuthor ? _self.replyToAuthor : replyToAuthor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as String?,fromMe: null == fromMe ? _self.fromMe : fromMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
