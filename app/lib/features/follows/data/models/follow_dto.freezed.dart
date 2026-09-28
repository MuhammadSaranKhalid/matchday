// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowDto {

@JsonKey(name: 'follow_id') String get followId;@JsonKey(name: 'follower_id') String get followerId;@JsonKey(name: 'target_type') String get targetType;@JsonKey(name: 'target_id') String get targetId; String get status;@JsonKey(name: 'notifications_enabled') bool get notificationsEnabled;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of FollowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowDtoCopyWith<FollowDto> get copyWith => _$FollowDtoCopyWithImpl<FollowDto>(this as FollowDto, _$identity);

  /// Serializes this FollowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowDto&&(identical(other.followId, followId) || other.followId == followId)&&(identical(other.followerId, followerId) || other.followerId == followerId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.status, status) || other.status == status)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,followId,followerId,targetType,targetId,status,notificationsEnabled,createdAt);

@override
String toString() {
  return 'FollowDto(followId: $followId, followerId: $followerId, targetType: $targetType, targetId: $targetId, status: $status, notificationsEnabled: $notificationsEnabled, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FollowDtoCopyWith<$Res>  {
  factory $FollowDtoCopyWith(FollowDto value, $Res Function(FollowDto) _then) = _$FollowDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'follow_id') String followId,@JsonKey(name: 'follower_id') String followerId,@JsonKey(name: 'target_type') String targetType,@JsonKey(name: 'target_id') String targetId, String status,@JsonKey(name: 'notifications_enabled') bool notificationsEnabled,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$FollowDtoCopyWithImpl<$Res>
    implements $FollowDtoCopyWith<$Res> {
  _$FollowDtoCopyWithImpl(this._self, this._then);

  final FollowDto _self;
  final $Res Function(FollowDto) _then;

/// Create a copy of FollowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? followId = null,Object? followerId = null,Object? targetType = null,Object? targetId = null,Object? status = null,Object? notificationsEnabled = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
followId: null == followId ? _self.followId : followId // ignore: cast_nullable_to_non_nullable
as String,followerId: null == followerId ? _self.followerId : followerId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowDto].
extension FollowDtoPatterns on FollowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowDto value)  $default,){
final _that = this;
switch (_that) {
case _FollowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowDto value)?  $default,){
final _that = this;
switch (_that) {
case _FollowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'follow_id')  String followId, @JsonKey(name: 'follower_id')  String followerId, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  String targetId,  String status, @JsonKey(name: 'notifications_enabled')  bool notificationsEnabled, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowDto() when $default != null:
return $default(_that.followId,_that.followerId,_that.targetType,_that.targetId,_that.status,_that.notificationsEnabled,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'follow_id')  String followId, @JsonKey(name: 'follower_id')  String followerId, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  String targetId,  String status, @JsonKey(name: 'notifications_enabled')  bool notificationsEnabled, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _FollowDto():
return $default(_that.followId,_that.followerId,_that.targetType,_that.targetId,_that.status,_that.notificationsEnabled,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'follow_id')  String followId, @JsonKey(name: 'follower_id')  String followerId, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  String targetId,  String status, @JsonKey(name: 'notifications_enabled')  bool notificationsEnabled, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FollowDto() when $default != null:
return $default(_that.followId,_that.followerId,_that.targetType,_that.targetId,_that.status,_that.notificationsEnabled,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowDto extends FollowDto {
  const _FollowDto({@JsonKey(name: 'follow_id') required this.followId, @JsonKey(name: 'follower_id') required this.followerId, @JsonKey(name: 'target_type') required this.targetType, @JsonKey(name: 'target_id') required this.targetId, this.status = 'active', @JsonKey(name: 'notifications_enabled') this.notificationsEnabled = true, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _FollowDto.fromJson(Map<String, dynamic> json) => _$FollowDtoFromJson(json);

@override@JsonKey(name: 'follow_id') final  String followId;
@override@JsonKey(name: 'follower_id') final  String followerId;
@override@JsonKey(name: 'target_type') final  String targetType;
@override@JsonKey(name: 'target_id') final  String targetId;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'notifications_enabled') final  bool notificationsEnabled;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of FollowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowDtoCopyWith<_FollowDto> get copyWith => __$FollowDtoCopyWithImpl<_FollowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowDto&&(identical(other.followId, followId) || other.followId == followId)&&(identical(other.followerId, followerId) || other.followerId == followerId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.status, status) || other.status == status)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,followId,followerId,targetType,targetId,status,notificationsEnabled,createdAt);

@override
String toString() {
  return 'FollowDto(followId: $followId, followerId: $followerId, targetType: $targetType, targetId: $targetId, status: $status, notificationsEnabled: $notificationsEnabled, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FollowDtoCopyWith<$Res> implements $FollowDtoCopyWith<$Res> {
  factory _$FollowDtoCopyWith(_FollowDto value, $Res Function(_FollowDto) _then) = __$FollowDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'follow_id') String followId,@JsonKey(name: 'follower_id') String followerId,@JsonKey(name: 'target_type') String targetType,@JsonKey(name: 'target_id') String targetId, String status,@JsonKey(name: 'notifications_enabled') bool notificationsEnabled,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$FollowDtoCopyWithImpl<$Res>
    implements _$FollowDtoCopyWith<$Res> {
  __$FollowDtoCopyWithImpl(this._self, this._then);

  final _FollowDto _self;
  final $Res Function(_FollowDto) _then;

/// Create a copy of FollowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? followId = null,Object? followerId = null,Object? targetType = null,Object? targetId = null,Object? status = null,Object? notificationsEnabled = null,Object? createdAt = null,}) {
  return _then(_FollowDto(
followId: null == followId ? _self.followId : followId // ignore: cast_nullable_to_non_nullable
as String,followerId: null == followerId ? _self.followerId : followerId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
