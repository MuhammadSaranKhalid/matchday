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

 String get displayName; String get username; String get bio; String get city;// Seeded from the loaded profile; passed through on save so we don't wipe geo
// or trip the username cooldown on an unchanged handle.
 String? get originalUsername; String? get placeId; double? get latitude; double? get longitude; String? get countryCode;/// Newly-picked avatar (square-cropped, resized) awaiting upload on save.
 File? get avatar; String? get currentAvatarUrl; bool get saving; Failure? get error;
/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileEditStateCopyWith<ProfileEditState> get copyWith => _$ProfileEditStateCopyWithImpl<ProfileEditState>(this as ProfileEditState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileEditState&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.city, city) || other.city == city)&&(identical(other.originalUsername, originalUsername) || other.originalUsername == originalUsername)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.currentAvatarUrl, currentAvatarUrl) || other.currentAvatarUrl == currentAvatarUrl)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,username,bio,city,originalUsername,placeId,latitude,longitude,countryCode,avatar,currentAvatarUrl,saving,error);

@override
String toString() {
  return 'ProfileEditState(displayName: $displayName, username: $username, bio: $bio, city: $city, originalUsername: $originalUsername, placeId: $placeId, latitude: $latitude, longitude: $longitude, countryCode: $countryCode, avatar: $avatar, currentAvatarUrl: $currentAvatarUrl, saving: $saving, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProfileEditStateCopyWith<$Res>  {
  factory $ProfileEditStateCopyWith(ProfileEditState value, $Res Function(ProfileEditState) _then) = _$ProfileEditStateCopyWithImpl;
@useResult
$Res call({
 String displayName, String username, String bio, String city, String? originalUsername, String? placeId, double? latitude, double? longitude, String? countryCode, File? avatar, String? currentAvatarUrl, bool saving, Failure? error
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
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? username = null,Object? bio = null,Object? city = null,Object? originalUsername = freezed,Object? placeId = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? countryCode = freezed,Object? avatar = freezed,Object? currentAvatarUrl = freezed,Object? saving = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,originalUsername: freezed == originalUsername ? _self.originalUsername : originalUsername // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as File?,currentAvatarUrl: freezed == currentAvatarUrl ? _self.currentAvatarUrl : currentAvatarUrl // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String username,  String bio,  String city,  String? originalUsername,  String? placeId,  double? latitude,  double? longitude,  String? countryCode,  File? avatar,  String? currentAvatarUrl,  bool saving,  Failure? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
return $default(_that.displayName,_that.username,_that.bio,_that.city,_that.originalUsername,_that.placeId,_that.latitude,_that.longitude,_that.countryCode,_that.avatar,_that.currentAvatarUrl,_that.saving,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String username,  String bio,  String city,  String? originalUsername,  String? placeId,  double? latitude,  double? longitude,  String? countryCode,  File? avatar,  String? currentAvatarUrl,  bool saving,  Failure? error)  $default,) {final _that = this;
switch (_that) {
case _ProfileEditState():
return $default(_that.displayName,_that.username,_that.bio,_that.city,_that.originalUsername,_that.placeId,_that.latitude,_that.longitude,_that.countryCode,_that.avatar,_that.currentAvatarUrl,_that.saving,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String username,  String bio,  String city,  String? originalUsername,  String? placeId,  double? latitude,  double? longitude,  String? countryCode,  File? avatar,  String? currentAvatarUrl,  bool saving,  Failure? error)?  $default,) {final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
return $default(_that.displayName,_that.username,_that.bio,_that.city,_that.originalUsername,_that.placeId,_that.latitude,_that.longitude,_that.countryCode,_that.avatar,_that.currentAvatarUrl,_that.saving,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileEditState implements ProfileEditState {
  const _ProfileEditState({this.displayName = '', this.username = '', this.bio = '', this.city = '', this.originalUsername, this.placeId, this.latitude, this.longitude, this.countryCode, this.avatar, this.currentAvatarUrl, this.saving = false, this.error});
  

@override@JsonKey() final  String displayName;
@override@JsonKey() final  String username;
@override@JsonKey() final  String bio;
@override@JsonKey() final  String city;
// Seeded from the loaded profile; passed through on save so we don't wipe geo
// or trip the username cooldown on an unchanged handle.
@override final  String? originalUsername;
@override final  String? placeId;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? countryCode;
/// Newly-picked avatar (square-cropped, resized) awaiting upload on save.
@override final  File? avatar;
@override final  String? currentAvatarUrl;
@override@JsonKey() final  bool saving;
@override final  Failure? error;

/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileEditStateCopyWith<_ProfileEditState> get copyWith => __$ProfileEditStateCopyWithImpl<_ProfileEditState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileEditState&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.city, city) || other.city == city)&&(identical(other.originalUsername, originalUsername) || other.originalUsername == originalUsername)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.currentAvatarUrl, currentAvatarUrl) || other.currentAvatarUrl == currentAvatarUrl)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,username,bio,city,originalUsername,placeId,latitude,longitude,countryCode,avatar,currentAvatarUrl,saving,error);

@override
String toString() {
  return 'ProfileEditState(displayName: $displayName, username: $username, bio: $bio, city: $city, originalUsername: $originalUsername, placeId: $placeId, latitude: $latitude, longitude: $longitude, countryCode: $countryCode, avatar: $avatar, currentAvatarUrl: $currentAvatarUrl, saving: $saving, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProfileEditStateCopyWith<$Res> implements $ProfileEditStateCopyWith<$Res> {
  factory _$ProfileEditStateCopyWith(_ProfileEditState value, $Res Function(_ProfileEditState) _then) = __$ProfileEditStateCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String username, String bio, String city, String? originalUsername, String? placeId, double? latitude, double? longitude, String? countryCode, File? avatar, String? currentAvatarUrl, bool saving, Failure? error
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
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? username = null,Object? bio = null,Object? city = null,Object? originalUsername = freezed,Object? placeId = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? countryCode = freezed,Object? avatar = freezed,Object? currentAvatarUrl = freezed,Object? saving = null,Object? error = freezed,}) {
  return _then(_ProfileEditState(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,originalUsername: freezed == originalUsername ? _self.originalUsername : originalUsername // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as File?,currentAvatarUrl: freezed == currentAvatarUrl ? _self.currentAvatarUrl : currentAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
