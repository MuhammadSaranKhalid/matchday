// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileDto {

@JsonKey(name: 'user_id') String get userId; String? get username;@JsonKey(name: 'display_name') String? get displayName; String? get bio;@JsonKey(name: 'profile_photo_url') String? get profilePhotoUrl;@JsonKey(name: 'cover_photo_url') String? get coverPhotoUrl; Map<String, dynamic>? get location;@JsonKey(name: 'onboarded_at') String? get onboardedAt;@JsonKey(name: 'player_profile') PlayerProfileDto? get playerProfile;
/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileDtoCopyWith<ProfileDto> get copyWith => _$ProfileDtoCopyWithImpl<ProfileDto>(this as ProfileDto, _$identity);

  /// Serializes this ProfileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.profilePhotoUrl, profilePhotoUrl) || other.profilePhotoUrl == profilePhotoUrl)&&(identical(other.coverPhotoUrl, coverPhotoUrl) || other.coverPhotoUrl == coverPhotoUrl)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.onboardedAt, onboardedAt) || other.onboardedAt == onboardedAt)&&(identical(other.playerProfile, playerProfile) || other.playerProfile == playerProfile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,displayName,bio,profilePhotoUrl,coverPhotoUrl,const DeepCollectionEquality().hash(location),onboardedAt,playerProfile);

@override
String toString() {
  return 'ProfileDto(userId: $userId, username: $username, displayName: $displayName, bio: $bio, profilePhotoUrl: $profilePhotoUrl, coverPhotoUrl: $coverPhotoUrl, location: $location, onboardedAt: $onboardedAt, playerProfile: $playerProfile)';
}


}

/// @nodoc
abstract mixin class $ProfileDtoCopyWith<$Res>  {
  factory $ProfileDtoCopyWith(ProfileDto value, $Res Function(ProfileDto) _then) = _$ProfileDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId, String? username,@JsonKey(name: 'display_name') String? displayName, String? bio,@JsonKey(name: 'profile_photo_url') String? profilePhotoUrl,@JsonKey(name: 'cover_photo_url') String? coverPhotoUrl, Map<String, dynamic>? location,@JsonKey(name: 'onboarded_at') String? onboardedAt,@JsonKey(name: 'player_profile') PlayerProfileDto? playerProfile
});


$PlayerProfileDtoCopyWith<$Res>? get playerProfile;

}
/// @nodoc
class _$ProfileDtoCopyWithImpl<$Res>
    implements $ProfileDtoCopyWith<$Res> {
  _$ProfileDtoCopyWithImpl(this._self, this._then);

  final ProfileDto _self;
  final $Res Function(ProfileDto) _then;

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = freezed,Object? displayName = freezed,Object? bio = freezed,Object? profilePhotoUrl = freezed,Object? coverPhotoUrl = freezed,Object? location = freezed,Object? onboardedAt = freezed,Object? playerProfile = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,profilePhotoUrl: freezed == profilePhotoUrl ? _self.profilePhotoUrl : profilePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverPhotoUrl: freezed == coverPhotoUrl ? _self.coverPhotoUrl : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,onboardedAt: freezed == onboardedAt ? _self.onboardedAt : onboardedAt // ignore: cast_nullable_to_non_nullable
as String?,playerProfile: freezed == playerProfile ? _self.playerProfile : playerProfile // ignore: cast_nullable_to_non_nullable
as PlayerProfileDto?,
  ));
}
/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerProfileDtoCopyWith<$Res>? get playerProfile {
    if (_self.playerProfile == null) {
    return null;
  }

  return $PlayerProfileDtoCopyWith<$Res>(_self.playerProfile!, (value) {
    return _then(_self.copyWith(playerProfile: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProfileDto].
extension ProfileDtoPatterns on ProfileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileDto value)  $default,){
final _that = this;
switch (_that) {
case _ProfileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String? bio, @JsonKey(name: 'profile_photo_url')  String? profilePhotoUrl, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl,  Map<String, dynamic>? location, @JsonKey(name: 'onboarded_at')  String? onboardedAt, @JsonKey(name: 'player_profile')  PlayerProfileDto? playerProfile)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
return $default(_that.userId,_that.username,_that.displayName,_that.bio,_that.profilePhotoUrl,_that.coverPhotoUrl,_that.location,_that.onboardedAt,_that.playerProfile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String? bio, @JsonKey(name: 'profile_photo_url')  String? profilePhotoUrl, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl,  Map<String, dynamic>? location, @JsonKey(name: 'onboarded_at')  String? onboardedAt, @JsonKey(name: 'player_profile')  PlayerProfileDto? playerProfile)  $default,) {final _that = this;
switch (_that) {
case _ProfileDto():
return $default(_that.userId,_that.username,_that.displayName,_that.bio,_that.profilePhotoUrl,_that.coverPhotoUrl,_that.location,_that.onboardedAt,_that.playerProfile);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String? bio, @JsonKey(name: 'profile_photo_url')  String? profilePhotoUrl, @JsonKey(name: 'cover_photo_url')  String? coverPhotoUrl,  Map<String, dynamic>? location, @JsonKey(name: 'onboarded_at')  String? onboardedAt, @JsonKey(name: 'player_profile')  PlayerProfileDto? playerProfile)?  $default,) {final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
return $default(_that.userId,_that.username,_that.displayName,_that.bio,_that.profilePhotoUrl,_that.coverPhotoUrl,_that.location,_that.onboardedAt,_that.playerProfile);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileDto extends ProfileDto {
  const _ProfileDto({@JsonKey(name: 'user_id') required this.userId, this.username, @JsonKey(name: 'display_name') this.displayName, this.bio, @JsonKey(name: 'profile_photo_url') this.profilePhotoUrl, @JsonKey(name: 'cover_photo_url') this.coverPhotoUrl, final  Map<String, dynamic>? location, @JsonKey(name: 'onboarded_at') this.onboardedAt, @JsonKey(name: 'player_profile') this.playerProfile}): _location = location,super._();
  factory _ProfileDto.fromJson(Map<String, dynamic> json) => _$ProfileDtoFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override final  String? username;
@override@JsonKey(name: 'display_name') final  String? displayName;
@override final  String? bio;
@override@JsonKey(name: 'profile_photo_url') final  String? profilePhotoUrl;
@override@JsonKey(name: 'cover_photo_url') final  String? coverPhotoUrl;
 final  Map<String, dynamic>? _location;
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'onboarded_at') final  String? onboardedAt;
@override@JsonKey(name: 'player_profile') final  PlayerProfileDto? playerProfile;

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileDtoCopyWith<_ProfileDto> get copyWith => __$ProfileDtoCopyWithImpl<_ProfileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.profilePhotoUrl, profilePhotoUrl) || other.profilePhotoUrl == profilePhotoUrl)&&(identical(other.coverPhotoUrl, coverPhotoUrl) || other.coverPhotoUrl == coverPhotoUrl)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.onboardedAt, onboardedAt) || other.onboardedAt == onboardedAt)&&(identical(other.playerProfile, playerProfile) || other.playerProfile == playerProfile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,displayName,bio,profilePhotoUrl,coverPhotoUrl,const DeepCollectionEquality().hash(_location),onboardedAt,playerProfile);

@override
String toString() {
  return 'ProfileDto(userId: $userId, username: $username, displayName: $displayName, bio: $bio, profilePhotoUrl: $profilePhotoUrl, coverPhotoUrl: $coverPhotoUrl, location: $location, onboardedAt: $onboardedAt, playerProfile: $playerProfile)';
}


}

/// @nodoc
abstract mixin class _$ProfileDtoCopyWith<$Res> implements $ProfileDtoCopyWith<$Res> {
  factory _$ProfileDtoCopyWith(_ProfileDto value, $Res Function(_ProfileDto) _then) = __$ProfileDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId, String? username,@JsonKey(name: 'display_name') String? displayName, String? bio,@JsonKey(name: 'profile_photo_url') String? profilePhotoUrl,@JsonKey(name: 'cover_photo_url') String? coverPhotoUrl, Map<String, dynamic>? location,@JsonKey(name: 'onboarded_at') String? onboardedAt,@JsonKey(name: 'player_profile') PlayerProfileDto? playerProfile
});


@override $PlayerProfileDtoCopyWith<$Res>? get playerProfile;

}
/// @nodoc
class __$ProfileDtoCopyWithImpl<$Res>
    implements _$ProfileDtoCopyWith<$Res> {
  __$ProfileDtoCopyWithImpl(this._self, this._then);

  final _ProfileDto _self;
  final $Res Function(_ProfileDto) _then;

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = freezed,Object? displayName = freezed,Object? bio = freezed,Object? profilePhotoUrl = freezed,Object? coverPhotoUrl = freezed,Object? location = freezed,Object? onboardedAt = freezed,Object? playerProfile = freezed,}) {
  return _then(_ProfileDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,profilePhotoUrl: freezed == profilePhotoUrl ? _self.profilePhotoUrl : profilePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverPhotoUrl: freezed == coverPhotoUrl ? _self.coverPhotoUrl : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,onboardedAt: freezed == onboardedAt ? _self.onboardedAt : onboardedAt // ignore: cast_nullable_to_non_nullable
as String?,playerProfile: freezed == playerProfile ? _self.playerProfile : playerProfile // ignore: cast_nullable_to_non_nullable
as PlayerProfileDto?,
  ));
}

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerProfileDtoCopyWith<$Res>? get playerProfile {
    if (_self.playerProfile == null) {
    return null;
  }

  return $PlayerProfileDtoCopyWith<$Res>(_self.playerProfile!, (value) {
    return _then(_self.copyWith(playerProfile: value));
  });
}
}

// dart format on
