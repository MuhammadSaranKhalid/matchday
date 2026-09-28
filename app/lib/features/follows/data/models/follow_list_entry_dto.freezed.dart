// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_list_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowListEntryDto {

@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'display_name') String get displayName; String get username;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'you_follow') bool get youFollow;@JsonKey(name: 'they_follow_you') bool get theyFollowYou;
/// Create a copy of FollowListEntryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowListEntryDtoCopyWith<FollowListEntryDto> get copyWith => _$FollowListEntryDtoCopyWithImpl<FollowListEntryDto>(this as FollowListEntryDto, _$identity);

  /// Serializes this FollowListEntryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowListEntryDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.youFollow, youFollow) || other.youFollow == youFollow)&&(identical(other.theyFollowYou, theyFollowYou) || other.theyFollowYou == theyFollowYou));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,username,avatarUrl,youFollow,theyFollowYou);

@override
String toString() {
  return 'FollowListEntryDto(userId: $userId, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, youFollow: $youFollow, theyFollowYou: $theyFollowYou)';
}


}

/// @nodoc
abstract mixin class $FollowListEntryDtoCopyWith<$Res>  {
  factory $FollowListEntryDtoCopyWith(FollowListEntryDto value, $Res Function(FollowListEntryDto) _then) = _$FollowListEntryDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'display_name') String displayName, String username,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'you_follow') bool youFollow,@JsonKey(name: 'they_follow_you') bool theyFollowYou
});




}
/// @nodoc
class _$FollowListEntryDtoCopyWithImpl<$Res>
    implements $FollowListEntryDtoCopyWith<$Res> {
  _$FollowListEntryDtoCopyWithImpl(this._self, this._then);

  final FollowListEntryDto _self;
  final $Res Function(FollowListEntryDto) _then;

/// Create a copy of FollowListEntryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? youFollow = null,Object? theyFollowYou = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,youFollow: null == youFollow ? _self.youFollow : youFollow // ignore: cast_nullable_to_non_nullable
as bool,theyFollowYou: null == theyFollowYou ? _self.theyFollowYou : theyFollowYou // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowListEntryDto].
extension FollowListEntryDtoPatterns on FollowListEntryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowListEntryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowListEntryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowListEntryDto value)  $default,){
final _that = this;
switch (_that) {
case _FollowListEntryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowListEntryDto value)?  $default,){
final _that = this;
switch (_that) {
case _FollowListEntryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name')  String displayName,  String username, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'you_follow')  bool youFollow, @JsonKey(name: 'they_follow_you')  bool theyFollowYou)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowListEntryDto() when $default != null:
return $default(_that.userId,_that.displayName,_that.username,_that.avatarUrl,_that.youFollow,_that.theyFollowYou);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name')  String displayName,  String username, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'you_follow')  bool youFollow, @JsonKey(name: 'they_follow_you')  bool theyFollowYou)  $default,) {final _that = this;
switch (_that) {
case _FollowListEntryDto():
return $default(_that.userId,_that.displayName,_that.username,_that.avatarUrl,_that.youFollow,_that.theyFollowYou);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name')  String displayName,  String username, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'you_follow')  bool youFollow, @JsonKey(name: 'they_follow_you')  bool theyFollowYou)?  $default,) {final _that = this;
switch (_that) {
case _FollowListEntryDto() when $default != null:
return $default(_that.userId,_that.displayName,_that.username,_that.avatarUrl,_that.youFollow,_that.theyFollowYou);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowListEntryDto extends FollowListEntryDto {
  const _FollowListEntryDto({@JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'display_name') required this.displayName, required this.username, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'you_follow') required this.youFollow, @JsonKey(name: 'they_follow_you') required this.theyFollowYou}): super._();
  factory _FollowListEntryDto.fromJson(Map<String, dynamic> json) => _$FollowListEntryDtoFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'display_name') final  String displayName;
@override final  String username;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'you_follow') final  bool youFollow;
@override@JsonKey(name: 'they_follow_you') final  bool theyFollowYou;

/// Create a copy of FollowListEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowListEntryDtoCopyWith<_FollowListEntryDto> get copyWith => __$FollowListEntryDtoCopyWithImpl<_FollowListEntryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowListEntryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowListEntryDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.youFollow, youFollow) || other.youFollow == youFollow)&&(identical(other.theyFollowYou, theyFollowYou) || other.theyFollowYou == theyFollowYou));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,username,avatarUrl,youFollow,theyFollowYou);

@override
String toString() {
  return 'FollowListEntryDto(userId: $userId, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, youFollow: $youFollow, theyFollowYou: $theyFollowYou)';
}


}

/// @nodoc
abstract mixin class _$FollowListEntryDtoCopyWith<$Res> implements $FollowListEntryDtoCopyWith<$Res> {
  factory _$FollowListEntryDtoCopyWith(_FollowListEntryDto value, $Res Function(_FollowListEntryDto) _then) = __$FollowListEntryDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'display_name') String displayName, String username,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'you_follow') bool youFollow,@JsonKey(name: 'they_follow_you') bool theyFollowYou
});




}
/// @nodoc
class __$FollowListEntryDtoCopyWithImpl<$Res>
    implements _$FollowListEntryDtoCopyWith<$Res> {
  __$FollowListEntryDtoCopyWithImpl(this._self, this._then);

  final _FollowListEntryDto _self;
  final $Res Function(_FollowListEntryDto) _then;

/// Create a copy of FollowListEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? youFollow = null,Object? theyFollowYou = null,}) {
  return _then(_FollowListEntryDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,youFollow: null == youFollow ? _self.youFollow : youFollow // ignore: cast_nullable_to_non_nullable
as bool,theyFollowYou: null == theyFollowYou ? _self.theyFollowYou : theyFollowYou // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
