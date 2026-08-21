// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerResultDto {

@JsonKey(name: 'player_type') String get playerType; String get id; String get name; String? get username;@JsonKey(name: 'photo_url') String? get photoUrl; String? get city;@JsonKey(name: 'player_role') String? get playerRole;@JsonKey(name: 'batting_style') String? get battingStyle;@JsonKey(name: 'bowling_style') String? get bowlingStyle;@JsonKey(name: 'team_context') String? get teamContext;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'follower_count') int get followerCount; double get score;
/// Create a copy of PlayerResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerResultDtoCopyWith<PlayerResultDto> get copyWith => _$PlayerResultDtoCopyWithImpl<PlayerResultDto>(this as PlayerResultDto, _$identity);

  /// Serializes this PlayerResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerResultDto&&(identical(other.playerType, playerType) || other.playerType == playerType)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.playerRole, playerRole) || other.playerRole == playerRole)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.teamContext, teamContext) || other.teamContext == teamContext)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerType,id,name,username,photoUrl,city,playerRole,battingStyle,bowlingStyle,teamContext,isVerified,followerCount,score);

@override
String toString() {
  return 'PlayerResultDto(playerType: $playerType, id: $id, name: $name, username: $username, photoUrl: $photoUrl, city: $city, playerRole: $playerRole, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, teamContext: $teamContext, isVerified: $isVerified, followerCount: $followerCount, score: $score)';
}


}

/// @nodoc
abstract mixin class $PlayerResultDtoCopyWith<$Res>  {
  factory $PlayerResultDtoCopyWith(PlayerResultDto value, $Res Function(PlayerResultDto) _then) = _$PlayerResultDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'player_type') String playerType, String id, String name, String? username,@JsonKey(name: 'photo_url') String? photoUrl, String? city,@JsonKey(name: 'player_role') String? playerRole,@JsonKey(name: 'batting_style') String? battingStyle,@JsonKey(name: 'bowling_style') String? bowlingStyle,@JsonKey(name: 'team_context') String? teamContext,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'follower_count') int followerCount, double score
});




}
/// @nodoc
class _$PlayerResultDtoCopyWithImpl<$Res>
    implements $PlayerResultDtoCopyWith<$Res> {
  _$PlayerResultDtoCopyWithImpl(this._self, this._then);

  final PlayerResultDto _self;
  final $Res Function(PlayerResultDto) _then;

/// Create a copy of PlayerResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerType = null,Object? id = null,Object? name = null,Object? username = freezed,Object? photoUrl = freezed,Object? city = freezed,Object? playerRole = freezed,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? teamContext = freezed,Object? isVerified = null,Object? followerCount = null,Object? score = null,}) {
  return _then(_self.copyWith(
playerType: null == playerType ? _self.playerType : playerType // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,playerRole: freezed == playerRole ? _self.playerRole : playerRole // ignore: cast_nullable_to_non_nullable
as String?,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as String?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as String?,teamContext: freezed == teamContext ? _self.teamContext : teamContext // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerResultDto].
extension PlayerResultDtoPatterns on PlayerResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerResultDto value)  $default,){
final _that = this;
switch (_that) {
case _PlayerResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'player_type')  String playerType,  String id,  String name,  String? username, @JsonKey(name: 'photo_url')  String? photoUrl,  String? city, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'team_context')  String? teamContext, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'follower_count')  int followerCount,  double score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerResultDto() when $default != null:
return $default(_that.playerType,_that.id,_that.name,_that.username,_that.photoUrl,_that.city,_that.playerRole,_that.battingStyle,_that.bowlingStyle,_that.teamContext,_that.isVerified,_that.followerCount,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'player_type')  String playerType,  String id,  String name,  String? username, @JsonKey(name: 'photo_url')  String? photoUrl,  String? city, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'team_context')  String? teamContext, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'follower_count')  int followerCount,  double score)  $default,) {final _that = this;
switch (_that) {
case _PlayerResultDto():
return $default(_that.playerType,_that.id,_that.name,_that.username,_that.photoUrl,_that.city,_that.playerRole,_that.battingStyle,_that.bowlingStyle,_that.teamContext,_that.isVerified,_that.followerCount,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'player_type')  String playerType,  String id,  String name,  String? username, @JsonKey(name: 'photo_url')  String? photoUrl,  String? city, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'team_context')  String? teamContext, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'follower_count')  int followerCount,  double score)?  $default,) {final _that = this;
switch (_that) {
case _PlayerResultDto() when $default != null:
return $default(_that.playerType,_that.id,_that.name,_that.username,_that.photoUrl,_that.city,_that.playerRole,_that.battingStyle,_that.bowlingStyle,_that.teamContext,_that.isVerified,_that.followerCount,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerResultDto extends PlayerResultDto {
  const _PlayerResultDto({@JsonKey(name: 'player_type') required this.playerType, required this.id, required this.name, this.username, @JsonKey(name: 'photo_url') this.photoUrl, this.city, @JsonKey(name: 'player_role') this.playerRole, @JsonKey(name: 'batting_style') this.battingStyle, @JsonKey(name: 'bowling_style') this.bowlingStyle, @JsonKey(name: 'team_context') this.teamContext, @JsonKey(name: 'is_verified') this.isVerified = false, @JsonKey(name: 'follower_count') this.followerCount = 0, this.score = 0.0}): super._();
  factory _PlayerResultDto.fromJson(Map<String, dynamic> json) => _$PlayerResultDtoFromJson(json);

@override@JsonKey(name: 'player_type') final  String playerType;
@override final  String id;
@override final  String name;
@override final  String? username;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override final  String? city;
@override@JsonKey(name: 'player_role') final  String? playerRole;
@override@JsonKey(name: 'batting_style') final  String? battingStyle;
@override@JsonKey(name: 'bowling_style') final  String? bowlingStyle;
@override@JsonKey(name: 'team_context') final  String? teamContext;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'follower_count') final  int followerCount;
@override@JsonKey() final  double score;

/// Create a copy of PlayerResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerResultDtoCopyWith<_PlayerResultDto> get copyWith => __$PlayerResultDtoCopyWithImpl<_PlayerResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerResultDto&&(identical(other.playerType, playerType) || other.playerType == playerType)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.playerRole, playerRole) || other.playerRole == playerRole)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.teamContext, teamContext) || other.teamContext == teamContext)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerType,id,name,username,photoUrl,city,playerRole,battingStyle,bowlingStyle,teamContext,isVerified,followerCount,score);

@override
String toString() {
  return 'PlayerResultDto(playerType: $playerType, id: $id, name: $name, username: $username, photoUrl: $photoUrl, city: $city, playerRole: $playerRole, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, teamContext: $teamContext, isVerified: $isVerified, followerCount: $followerCount, score: $score)';
}


}

/// @nodoc
abstract mixin class _$PlayerResultDtoCopyWith<$Res> implements $PlayerResultDtoCopyWith<$Res> {
  factory _$PlayerResultDtoCopyWith(_PlayerResultDto value, $Res Function(_PlayerResultDto) _then) = __$PlayerResultDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'player_type') String playerType, String id, String name, String? username,@JsonKey(name: 'photo_url') String? photoUrl, String? city,@JsonKey(name: 'player_role') String? playerRole,@JsonKey(name: 'batting_style') String? battingStyle,@JsonKey(name: 'bowling_style') String? bowlingStyle,@JsonKey(name: 'team_context') String? teamContext,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'follower_count') int followerCount, double score
});




}
/// @nodoc
class __$PlayerResultDtoCopyWithImpl<$Res>
    implements _$PlayerResultDtoCopyWith<$Res> {
  __$PlayerResultDtoCopyWithImpl(this._self, this._then);

  final _PlayerResultDto _self;
  final $Res Function(_PlayerResultDto) _then;

/// Create a copy of PlayerResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerType = null,Object? id = null,Object? name = null,Object? username = freezed,Object? photoUrl = freezed,Object? city = freezed,Object? playerRole = freezed,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? teamContext = freezed,Object? isVerified = null,Object? followerCount = null,Object? score = null,}) {
  return _then(_PlayerResultDto(
playerType: null == playerType ? _self.playerType : playerType // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,playerRole: freezed == playerRole ? _self.playerRole : playerRole // ignore: cast_nullable_to_non_nullable
as String?,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as String?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as String?,teamContext: freezed == teamContext ? _self.teamContext : teamContext // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
