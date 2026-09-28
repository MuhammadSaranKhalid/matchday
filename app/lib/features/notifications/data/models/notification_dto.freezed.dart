// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationDto {

@JsonKey(name: 'notification_id') String get notificationId;@JsonKey(name: 'recipient_id') String get recipientId;@JsonKey(name: 'type_key') String get typeKey; String get title; String get body; String? get route; String get tier; String get icon;@JsonKey(name: 'icon_path') String? get iconPath; String get tone;@JsonKey(name: 'actor_id') String? get actorId;@JsonKey(name: 'entity_scope') String? get entityScope;@JsonKey(name: 'entity_id') String? get entityId;@JsonKey(name: 'group_count') int get groupCount; Map<String, dynamic> get payload;@JsonKey(name: 'is_read') bool get isRead;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationDtoCopyWith<NotificationDto> get copyWith => _$NotificationDtoCopyWithImpl<NotificationDto>(this as NotificationDto, _$identity);

  /// Serializes this NotificationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationDto&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.typeKey, typeKey) || other.typeKey == typeKey)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.route, route) || other.route == route)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.iconPath, iconPath) || other.iconPath == iconPath)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.entityScope, entityScope) || other.entityScope == entityScope)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.groupCount, groupCount) || other.groupCount == groupCount)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationId,recipientId,typeKey,title,body,route,tier,icon,iconPath,tone,actorId,entityScope,entityId,groupCount,const DeepCollectionEquality().hash(payload),isRead,createdAt);

@override
String toString() {
  return 'NotificationDto(notificationId: $notificationId, recipientId: $recipientId, typeKey: $typeKey, title: $title, body: $body, route: $route, tier: $tier, icon: $icon, iconPath: $iconPath, tone: $tone, actorId: $actorId, entityScope: $entityScope, entityId: $entityId, groupCount: $groupCount, payload: $payload, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $NotificationDtoCopyWith<$Res>  {
  factory $NotificationDtoCopyWith(NotificationDto value, $Res Function(NotificationDto) _then) = _$NotificationDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'notification_id') String notificationId,@JsonKey(name: 'recipient_id') String recipientId,@JsonKey(name: 'type_key') String typeKey, String title, String body, String? route, String tier, String icon,@JsonKey(name: 'icon_path') String? iconPath, String tone,@JsonKey(name: 'actor_id') String? actorId,@JsonKey(name: 'entity_scope') String? entityScope,@JsonKey(name: 'entity_id') String? entityId,@JsonKey(name: 'group_count') int groupCount, Map<String, dynamic> payload,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$NotificationDtoCopyWithImpl<$Res>
    implements $NotificationDtoCopyWith<$Res> {
  _$NotificationDtoCopyWithImpl(this._self, this._then);

  final NotificationDto _self;
  final $Res Function(NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notificationId = null,Object? recipientId = null,Object? typeKey = null,Object? title = null,Object? body = null,Object? route = freezed,Object? tier = null,Object? icon = null,Object? iconPath = freezed,Object? tone = null,Object? actorId = freezed,Object? entityScope = freezed,Object? entityId = freezed,Object? groupCount = null,Object? payload = null,Object? isRead = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,typeKey: null == typeKey ? _self.typeKey : typeKey // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,iconPath: freezed == iconPath ? _self.iconPath : iconPath // ignore: cast_nullable_to_non_nullable
as String?,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as String,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,entityScope: freezed == entityScope ? _self.entityScope : entityScope // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,groupCount: null == groupCount ? _self.groupCount : groupCount // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationDto].
extension NotificationDtoPatterns on NotificationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'recipient_id')  String recipientId, @JsonKey(name: 'type_key')  String typeKey,  String title,  String body,  String? route,  String tier,  String icon, @JsonKey(name: 'icon_path')  String? iconPath,  String tone, @JsonKey(name: 'actor_id')  String? actorId, @JsonKey(name: 'entity_scope')  String? entityScope, @JsonKey(name: 'entity_id')  String? entityId, @JsonKey(name: 'group_count')  int groupCount,  Map<String, dynamic> payload, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.notificationId,_that.recipientId,_that.typeKey,_that.title,_that.body,_that.route,_that.tier,_that.icon,_that.iconPath,_that.tone,_that.actorId,_that.entityScope,_that.entityId,_that.groupCount,_that.payload,_that.isRead,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'recipient_id')  String recipientId, @JsonKey(name: 'type_key')  String typeKey,  String title,  String body,  String? route,  String tier,  String icon, @JsonKey(name: 'icon_path')  String? iconPath,  String tone, @JsonKey(name: 'actor_id')  String? actorId, @JsonKey(name: 'entity_scope')  String? entityScope, @JsonKey(name: 'entity_id')  String? entityId, @JsonKey(name: 'group_count')  int groupCount,  Map<String, dynamic> payload, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _NotificationDto():
return $default(_that.notificationId,_that.recipientId,_that.typeKey,_that.title,_that.body,_that.route,_that.tier,_that.icon,_that.iconPath,_that.tone,_that.actorId,_that.entityScope,_that.entityId,_that.groupCount,_that.payload,_that.isRead,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'recipient_id')  String recipientId, @JsonKey(name: 'type_key')  String typeKey,  String title,  String body,  String? route,  String tier,  String icon, @JsonKey(name: 'icon_path')  String? iconPath,  String tone, @JsonKey(name: 'actor_id')  String? actorId, @JsonKey(name: 'entity_scope')  String? entityScope, @JsonKey(name: 'entity_id')  String? entityId, @JsonKey(name: 'group_count')  int groupCount,  Map<String, dynamic> payload, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.notificationId,_that.recipientId,_that.typeKey,_that.title,_that.body,_that.route,_that.tier,_that.icon,_that.iconPath,_that.tone,_that.actorId,_that.entityScope,_that.entityId,_that.groupCount,_that.payload,_that.isRead,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationDto extends NotificationDto {
  const _NotificationDto({@JsonKey(name: 'notification_id') required this.notificationId, @JsonKey(name: 'recipient_id') required this.recipientId, @JsonKey(name: 'type_key') required this.typeKey, required this.title, required this.body, this.route, this.tier = 'fyi', this.icon = 'bell', @JsonKey(name: 'icon_path') this.iconPath, this.tone = 'neutral', @JsonKey(name: 'actor_id') this.actorId, @JsonKey(name: 'entity_scope') this.entityScope, @JsonKey(name: 'entity_id') this.entityId, @JsonKey(name: 'group_count') this.groupCount = 1, final  Map<String, dynamic> payload = const <String, dynamic>{}, @JsonKey(name: 'is_read') this.isRead = false, @JsonKey(name: 'created_at') required this.createdAt}): _payload = payload,super._();
  factory _NotificationDto.fromJson(Map<String, dynamic> json) => _$NotificationDtoFromJson(json);

@override@JsonKey(name: 'notification_id') final  String notificationId;
@override@JsonKey(name: 'recipient_id') final  String recipientId;
@override@JsonKey(name: 'type_key') final  String typeKey;
@override final  String title;
@override final  String body;
@override final  String? route;
@override@JsonKey() final  String tier;
@override@JsonKey() final  String icon;
@override@JsonKey(name: 'icon_path') final  String? iconPath;
@override@JsonKey() final  String tone;
@override@JsonKey(name: 'actor_id') final  String? actorId;
@override@JsonKey(name: 'entity_scope') final  String? entityScope;
@override@JsonKey(name: 'entity_id') final  String? entityId;
@override@JsonKey(name: 'group_count') final  int groupCount;
 final  Map<String, dynamic> _payload;
@override@JsonKey() Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override@JsonKey(name: 'is_read') final  bool isRead;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationDtoCopyWith<_NotificationDto> get copyWith => __$NotificationDtoCopyWithImpl<_NotificationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationDto&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.typeKey, typeKey) || other.typeKey == typeKey)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.route, route) || other.route == route)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.iconPath, iconPath) || other.iconPath == iconPath)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.entityScope, entityScope) || other.entityScope == entityScope)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.groupCount, groupCount) || other.groupCount == groupCount)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationId,recipientId,typeKey,title,body,route,tier,icon,iconPath,tone,actorId,entityScope,entityId,groupCount,const DeepCollectionEquality().hash(_payload),isRead,createdAt);

@override
String toString() {
  return 'NotificationDto(notificationId: $notificationId, recipientId: $recipientId, typeKey: $typeKey, title: $title, body: $body, route: $route, tier: $tier, icon: $icon, iconPath: $iconPath, tone: $tone, actorId: $actorId, entityScope: $entityScope, entityId: $entityId, groupCount: $groupCount, payload: $payload, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationDtoCopyWith<$Res> implements $NotificationDtoCopyWith<$Res> {
  factory _$NotificationDtoCopyWith(_NotificationDto value, $Res Function(_NotificationDto) _then) = __$NotificationDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'notification_id') String notificationId,@JsonKey(name: 'recipient_id') String recipientId,@JsonKey(name: 'type_key') String typeKey, String title, String body, String? route, String tier, String icon,@JsonKey(name: 'icon_path') String? iconPath, String tone,@JsonKey(name: 'actor_id') String? actorId,@JsonKey(name: 'entity_scope') String? entityScope,@JsonKey(name: 'entity_id') String? entityId,@JsonKey(name: 'group_count') int groupCount, Map<String, dynamic> payload,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$NotificationDtoCopyWithImpl<$Res>
    implements _$NotificationDtoCopyWith<$Res> {
  __$NotificationDtoCopyWithImpl(this._self, this._then);

  final _NotificationDto _self;
  final $Res Function(_NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notificationId = null,Object? recipientId = null,Object? typeKey = null,Object? title = null,Object? body = null,Object? route = freezed,Object? tier = null,Object? icon = null,Object? iconPath = freezed,Object? tone = null,Object? actorId = freezed,Object? entityScope = freezed,Object? entityId = freezed,Object? groupCount = null,Object? payload = null,Object? isRead = null,Object? createdAt = null,}) {
  return _then(_NotificationDto(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,typeKey: null == typeKey ? _self.typeKey : typeKey // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,iconPath: freezed == iconPath ? _self.iconPath : iconPath // ignore: cast_nullable_to_non_nullable
as String?,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as String,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,entityScope: freezed == entityScope ? _self.entityScope : entityScope // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,groupCount: null == groupCount ? _self.groupCount : groupCount // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
