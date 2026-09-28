// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_edit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileEditState {

 String get displayName; String get username; String get bio;/// Seeded from the loaded profile. Save compares against these to decide
/// whether anything actually changed, and passes the username through only
/// when it differs so an unchanged handle never trips the cooldown.
 String get originalDisplayName; String get originalUsername; String get originalBio;/// Newly-picked images awaiting upload on save.
 File? get avatar; File? get cover; String? get currentAvatarUrl; String? get currentCoverUrl; UsernameStatus get usernameStatus;/// Set when the username is invalid or taken, or when a save came back
/// with a field-specific reason. Rendered under the offending field.
 String? get usernameError; String? get nameError; bool get saving; Failure? get error;
/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileEditStateCopyWith<ProfileEditState> get copyWith => _$ProfileEditStateCopyWithImpl<ProfileEditState>(this as ProfileEditState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileEditState&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.originalDisplayName, originalDisplayName) || other.originalDisplayName == originalDisplayName)&&(identical(other.originalUsername, originalUsername) || other.originalUsername == originalUsername)&&(identical(other.originalBio, originalBio) || other.originalBio == originalBio)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.currentAvatarUrl, currentAvatarUrl) || other.currentAvatarUrl == currentAvatarUrl)&&(identical(other.currentCoverUrl, currentCoverUrl) || other.currentCoverUrl == currentCoverUrl)&&(identical(other.usernameStatus, usernameStatus) || other.usernameStatus == usernameStatus)&&(identical(other.usernameError, usernameError) || other.usernameError == usernameError)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,username,bio,originalDisplayName,originalUsername,originalBio,avatar,cover,currentAvatarUrl,currentCoverUrl,usernameStatus,usernameError,nameError,saving,error);

@override
String toString() {
  return 'ProfileEditState(displayName: $displayName, username: $username, bio: $bio, originalDisplayName: $originalDisplayName, originalUsername: $originalUsername, originalBio: $originalBio, avatar: $avatar, cover: $cover, currentAvatarUrl: $currentAvatarUrl, currentCoverUrl: $currentCoverUrl, usernameStatus: $usernameStatus, usernameError: $usernameError, nameError: $nameError, saving: $saving, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProfileEditStateCopyWith<$Res>  {
  factory $ProfileEditStateCopyWith(ProfileEditState value, $Res Function(ProfileEditState) _then) = _$ProfileEditStateCopyWithImpl;
@useResult
$Res call({
 String displayName, String username, String bio, String originalDisplayName, String originalUsername, String originalBio, File? avatar, File? cover, String? currentAvatarUrl, String? currentCoverUrl, UsernameStatus usernameStatus, String? usernameError, String? nameError, bool saving, Failure? error
});




}
/// @nodoc
class _$ProfileEditStateCopyWithImpl<$Res>
    implements $ProfileEditStateCopyWith<$Res> {
  _$ProfileEditStateCopyWithImpl(this._self, this._then);

  final ProfileEditState _self;
  final $Res Function(ProfileEditState) _then;

/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? username = null,Object? bio = null,Object? originalDisplayName = null,Object? originalUsername = null,Object? originalBio = null,Object? avatar = freezed,Object? cover = freezed,Object? currentAvatarUrl = freezed,Object? currentCoverUrl = freezed,Object? usernameStatus = null,Object? usernameError = freezed,Object? nameError = freezed,Object? saving = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,originalDisplayName: null == originalDisplayName ? _self.originalDisplayName : originalDisplayName // ignore: cast_nullable_to_non_nullable
as String,originalUsername: null == originalUsername ? _self.originalUsername : originalUsername // ignore: cast_nullable_to_non_nullable
as String,originalBio: null == originalBio ? _self.originalBio : originalBio // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as File?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as File?,currentAvatarUrl: freezed == currentAvatarUrl ? _self.currentAvatarUrl : currentAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,currentCoverUrl: freezed == currentCoverUrl ? _self.currentCoverUrl : currentCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
as UsernameStatus,usernameError: freezed == usernameError ? _self.usernameError : usernameError // ignore: cast_nullable_to_non_nullable
as String?,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileEditState].
extension ProfileEditStatePatterns on ProfileEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileEditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileEditState value)  $default,){
final _that = this;
switch (_that) {
case _ProfileEditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileEditState value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String username,  String bio,  String originalDisplayName,  String originalUsername,  String originalBio,  File? avatar,  File? cover,  String? currentAvatarUrl,  String? currentCoverUrl,  UsernameStatus usernameStatus,  String? usernameError,  String? nameError,  bool saving,  Failure? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
return $default(_that.displayName,_that.username,_that.bio,_that.originalDisplayName,_that.originalUsername,_that.originalBio,_that.avatar,_that.cover,_that.currentAvatarUrl,_that.currentCoverUrl,_that.usernameStatus,_that.usernameError,_that.nameError,_that.saving,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String username,  String bio,  String originalDisplayName,  String originalUsername,  String originalBio,  File? avatar,  File? cover,  String? currentAvatarUrl,  String? currentCoverUrl,  UsernameStatus usernameStatus,  String? usernameError,  String? nameError,  bool saving,  Failure? error)  $default,) {final _that = this;
switch (_that) {
case _ProfileEditState():
return $default(_that.displayName,_that.username,_that.bio,_that.originalDisplayName,_that.originalUsername,_that.originalBio,_that.avatar,_that.cover,_that.currentAvatarUrl,_that.currentCoverUrl,_that.usernameStatus,_that.usernameError,_that.nameError,_that.saving,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String username,  String bio,  String originalDisplayName,  String originalUsername,  String originalBio,  File? avatar,  File? cover,  String? currentAvatarUrl,  String? currentCoverUrl,  UsernameStatus usernameStatus,  String? usernameError,  String? nameError,  bool saving,  Failure? error)?  $default,) {final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
return $default(_that.displayName,_that.username,_that.bio,_that.originalDisplayName,_that.originalUsername,_that.originalBio,_that.avatar,_that.cover,_that.currentAvatarUrl,_that.currentCoverUrl,_that.usernameStatus,_that.usernameError,_that.nameError,_that.saving,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileEditState extends ProfileEditState {
  const _ProfileEditState({this.displayName = '', this.username = '', this.bio = '', this.originalDisplayName = '', this.originalUsername = '', this.originalBio = '', this.avatar, this.cover, this.currentAvatarUrl, this.currentCoverUrl, this.usernameStatus = UsernameStatus.untouched, this.usernameError, this.nameError, this.saving = false, this.error}): super._();
  

@override@JsonKey() final  String displayName;
@override@JsonKey() final  String username;
@override@JsonKey() final  String bio;
/// Seeded from the loaded profile. Save compares against these to decide
/// whether anything actually changed, and passes the username through only
/// when it differs so an unchanged handle never trips the cooldown.
@override@JsonKey() final  String originalDisplayName;
@override@JsonKey() final  String originalUsername;
@override@JsonKey() final  String originalBio;
/// Newly-picked images awaiting upload on save.
@override final  File? avatar;
@override final  File? cover;
@override final  String? currentAvatarUrl;
@override final  String? currentCoverUrl;
@override@JsonKey() final  UsernameStatus usernameStatus;
/// Set when the username is invalid or taken, or when a save came back
/// with a field-specific reason. Rendered under the offending field.
@override final  String? usernameError;
@override final  String? nameError;
@override@JsonKey() final  bool saving;
@override final  Failure? error;

/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileEditStateCopyWith<_ProfileEditState> get copyWith => __$ProfileEditStateCopyWithImpl<_ProfileEditState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileEditState&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.originalDisplayName, originalDisplayName) || other.originalDisplayName == originalDisplayName)&&(identical(other.originalUsername, originalUsername) || other.originalUsername == originalUsername)&&(identical(other.originalBio, originalBio) || other.originalBio == originalBio)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.currentAvatarUrl, currentAvatarUrl) || other.currentAvatarUrl == currentAvatarUrl)&&(identical(other.currentCoverUrl, currentCoverUrl) || other.currentCoverUrl == currentCoverUrl)&&(identical(other.usernameStatus, usernameStatus) || other.usernameStatus == usernameStatus)&&(identical(other.usernameError, usernameError) || other.usernameError == usernameError)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,username,bio,originalDisplayName,originalUsername,originalBio,avatar,cover,currentAvatarUrl,currentCoverUrl,usernameStatus,usernameError,nameError,saving,error);

@override
String toString() {
  return 'ProfileEditState(displayName: $displayName, username: $username, bio: $bio, originalDisplayName: $originalDisplayName, originalUsername: $originalUsername, originalBio: $originalBio, avatar: $avatar, cover: $cover, currentAvatarUrl: $currentAvatarUrl, currentCoverUrl: $currentCoverUrl, usernameStatus: $usernameStatus, usernameError: $usernameError, nameError: $nameError, saving: $saving, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProfileEditStateCopyWith<$Res> implements $ProfileEditStateCopyWith<$Res> {
  factory _$ProfileEditStateCopyWith(_ProfileEditState value, $Res Function(_ProfileEditState) _then) = __$ProfileEditStateCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String username, String bio, String originalDisplayName, String originalUsername, String originalBio, File? avatar, File? cover, String? currentAvatarUrl, String? currentCoverUrl, UsernameStatus usernameStatus, String? usernameError, String? nameError, bool saving, Failure? error
});




}
/// @nodoc
class __$ProfileEditStateCopyWithImpl<$Res>
    implements _$ProfileEditStateCopyWith<$Res> {
  __$ProfileEditStateCopyWithImpl(this._self, this._then);

  final _ProfileEditState _self;
  final $Res Function(_ProfileEditState) _then;

/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? username = null,Object? bio = null,Object? originalDisplayName = null,Object? originalUsername = null,Object? originalBio = null,Object? avatar = freezed,Object? cover = freezed,Object? currentAvatarUrl = freezed,Object? currentCoverUrl = freezed,Object? usernameStatus = null,Object? usernameError = freezed,Object? nameError = freezed,Object? saving = null,Object? error = freezed,}) {
  return _then(_ProfileEditState(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,originalDisplayName: null == originalDisplayName ? _self.originalDisplayName : originalDisplayName // ignore: cast_nullable_to_non_nullable
as String,originalUsername: null == originalUsername ? _self.originalUsername : originalUsername // ignore: cast_nullable_to_non_nullable
as String,originalBio: null == originalBio ? _self.originalBio : originalBio // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as File?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as File?,currentAvatarUrl: freezed == currentAvatarUrl ? _self.currentAvatarUrl : currentAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,currentCoverUrl: freezed == currentCoverUrl ? _self.currentCoverUrl : currentCoverUrl // ignore: cast_nullable_to_non_nullable
as String?,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
as UsernameStatus,usernameError: freezed == usernameError ? _self.usernameError : usernameError // ignore: cast_nullable_to_non_nullable
as String?,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
