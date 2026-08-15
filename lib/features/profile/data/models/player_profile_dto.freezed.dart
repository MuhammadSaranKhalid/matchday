// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_profile_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerProfileDto {

@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'batting_style') String? get battingStyle;@JsonKey(name: 'bowling_style') String? get bowlingStyle;@JsonKey(name: 'player_role') String? get playerRole;@JsonKey(name: 'preferred_ball_types') List<String> get preferredBallTypes;@JsonKey(name: 'years_playing') int? get yearsPlaying;
/// Create a copy of PlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerProfileDtoCopyWith<PlayerProfileDto> get copyWith => _$PlayerProfileDtoCopyWithImpl<PlayerProfileDto>(this as PlayerProfileDto, _$identity);

  /// Serializes this PlayerProfileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerProfileDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.playerRole, playerRole) || other.playerRole == playerRole)&&const DeepCollectionEquality().equals(other.preferredBallTypes, preferredBallTypes)&&(identical(other.yearsPlaying, yearsPlaying) || other.yearsPlaying == yearsPlaying));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,battingStyle,bowlingStyle,playerRole,const DeepCollectionEquality().hash(preferredBallTypes),yearsPlaying);

@override
String toString() {
  return 'PlayerProfileDto(userId: $userId, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, playerRole: $playerRole, preferredBallTypes: $preferredBallTypes, yearsPlaying: $yearsPlaying)';
}


}

/// @nodoc
abstract mixin class $PlayerProfileDtoCopyWith<$Res>  {
  factory $PlayerProfileDtoCopyWith(PlayerProfileDto value, $Res Function(PlayerProfileDto) _then) = _$PlayerProfileDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'batting_style') String? battingStyle,@JsonKey(name: 'bowling_style') String? bowlingStyle,@JsonKey(name: 'player_role') String? playerRole,@JsonKey(name: 'preferred_ball_types') List<String> preferredBallTypes,@JsonKey(name: 'years_playing') int? yearsPlaying
});




}
/// @nodoc
class _$PlayerProfileDtoCopyWithImpl<$Res>
    implements $PlayerProfileDtoCopyWith<$Res> {
  _$PlayerProfileDtoCopyWithImpl(this._self, this._then);

  final PlayerProfileDto _self;
  final $Res Function(PlayerProfileDto) _then;

/// Create a copy of PlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? playerRole = freezed,Object? preferredBallTypes = null,Object? yearsPlaying = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as String?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as String?,playerRole: freezed == playerRole ? _self.playerRole : playerRole // ignore: cast_nullable_to_non_nullable
as String?,preferredBallTypes: null == preferredBallTypes ? _self.preferredBallTypes : preferredBallTypes // ignore: cast_nullable_to_non_nullable
as List<String>,yearsPlaying: freezed == yearsPlaying ? _self.yearsPlaying : yearsPlaying // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerProfileDto].
extension PlayerProfileDtoPatterns on PlayerProfileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerProfileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerProfileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerProfileDto value)  $default,){
final _that = this;
switch (_that) {
case _PlayerProfileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerProfileDto value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerProfileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'preferred_ball_types')  List<String> preferredBallTypes, @JsonKey(name: 'years_playing')  int? yearsPlaying)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerProfileDto() when $default != null:
return $default(_that.userId,_that.battingStyle,_that.bowlingStyle,_that.playerRole,_that.preferredBallTypes,_that.yearsPlaying);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'preferred_ball_types')  List<String> preferredBallTypes, @JsonKey(name: 'years_playing')  int? yearsPlaying)  $default,) {final _that = this;
switch (_that) {
case _PlayerProfileDto():
return $default(_that.userId,_that.battingStyle,_that.bowlingStyle,_that.playerRole,_that.preferredBallTypes,_that.yearsPlaying);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'preferred_ball_types')  List<String> preferredBallTypes, @JsonKey(name: 'years_playing')  int? yearsPlaying)?  $default,) {final _that = this;
switch (_that) {
case _PlayerProfileDto() when $default != null:
return $default(_that.userId,_that.battingStyle,_that.bowlingStyle,_that.playerRole,_that.preferredBallTypes,_that.yearsPlaying);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerProfileDto extends PlayerProfileDto {
  const _PlayerProfileDto({@JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'batting_style') this.battingStyle, @JsonKey(name: 'bowling_style') this.bowlingStyle, @JsonKey(name: 'player_role') this.playerRole, @JsonKey(name: 'preferred_ball_types') final  List<String> preferredBallTypes = const <String>[], @JsonKey(name: 'years_playing') this.yearsPlaying}): _preferredBallTypes = preferredBallTypes,super._();
  factory _PlayerProfileDto.fromJson(Map<String, dynamic> json) => _$PlayerProfileDtoFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'batting_style') final  String? battingStyle;
@override@JsonKey(name: 'bowling_style') final  String? bowlingStyle;
@override@JsonKey(name: 'player_role') final  String? playerRole;
 final  List<String> _preferredBallTypes;
@override@JsonKey(name: 'preferred_ball_types') List<String> get preferredBallTypes {
  if (_preferredBallTypes is EqualUnmodifiableListView) return _preferredBallTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredBallTypes);
}

@override@JsonKey(name: 'years_playing') final  int? yearsPlaying;

/// Create a copy of PlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerProfileDtoCopyWith<_PlayerProfileDto> get copyWith => __$PlayerProfileDtoCopyWithImpl<_PlayerProfileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerProfileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerProfileDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.playerRole, playerRole) || other.playerRole == playerRole)&&const DeepCollectionEquality().equals(other._preferredBallTypes, _preferredBallTypes)&&(identical(other.yearsPlaying, yearsPlaying) || other.yearsPlaying == yearsPlaying));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,battingStyle,bowlingStyle,playerRole,const DeepCollectionEquality().hash(_preferredBallTypes),yearsPlaying);

@override
String toString() {
  return 'PlayerProfileDto(userId: $userId, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, playerRole: $playerRole, preferredBallTypes: $preferredBallTypes, yearsPlaying: $yearsPlaying)';
}


}

/// @nodoc
abstract mixin class _$PlayerProfileDtoCopyWith<$Res> implements $PlayerProfileDtoCopyWith<$Res> {
  factory _$PlayerProfileDtoCopyWith(_PlayerProfileDto value, $Res Function(_PlayerProfileDto) _then) = __$PlayerProfileDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'batting_style') String? battingStyle,@JsonKey(name: 'bowling_style') String? bowlingStyle,@JsonKey(name: 'player_role') String? playerRole,@JsonKey(name: 'preferred_ball_types') List<String> preferredBallTypes,@JsonKey(name: 'years_playing') int? yearsPlaying
});




}
/// @nodoc
class __$PlayerProfileDtoCopyWithImpl<$Res>
    implements _$PlayerProfileDtoCopyWith<$Res> {
  __$PlayerProfileDtoCopyWithImpl(this._self, this._then);

  final _PlayerProfileDto _self;
  final $Res Function(_PlayerProfileDto) _then;

/// Create a copy of PlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? playerRole = freezed,Object? preferredBallTypes = null,Object? yearsPlaying = freezed,}) {
  return _then(_PlayerProfileDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as String?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as String?,playerRole: freezed == playerRole ? _self.playerRole : playerRole // ignore: cast_nullable_to_non_nullable
as String?,preferredBallTypes: null == preferredBallTypes ? _self._preferredBallTypes : preferredBallTypes // ignore: cast_nullable_to_non_nullable
as List<String>,yearsPlaying: freezed == yearsPlaying ? _self.yearsPlaying : yearsPlaying // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
