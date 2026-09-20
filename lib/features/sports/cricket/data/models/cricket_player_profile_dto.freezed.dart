// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cricket_player_profile_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CricketPlayerProfileDto {

@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'sport_id') String get sportId;@JsonKey(name: 'batting_style') String? get battingStyle;@JsonKey(name: 'bowling_style') String? get bowlingStyle;@JsonKey(name: 'player_role') String? get playerRole;@JsonKey(name: 'preferred_ball_types') List<String> get preferredBallTypes;@JsonKey(name: 'years_playing') int? get yearsPlaying;
/// Create a copy of CricketPlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CricketPlayerProfileDtoCopyWith<CricketPlayerProfileDto> get copyWith => _$CricketPlayerProfileDtoCopyWithImpl<CricketPlayerProfileDto>(this as CricketPlayerProfileDto, _$identity);

  /// Serializes this CricketPlayerProfileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CricketPlayerProfileDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sportId, sportId) || other.sportId == sportId)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.playerRole, playerRole) || other.playerRole == playerRole)&&const DeepCollectionEquality().equals(other.preferredBallTypes, preferredBallTypes)&&(identical(other.yearsPlaying, yearsPlaying) || other.yearsPlaying == yearsPlaying));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,sportId,battingStyle,bowlingStyle,playerRole,const DeepCollectionEquality().hash(preferredBallTypes),yearsPlaying);

@override
String toString() {
  return 'CricketPlayerProfileDto(userId: $userId, sportId: $sportId, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, playerRole: $playerRole, preferredBallTypes: $preferredBallTypes, yearsPlaying: $yearsPlaying)';
}


}

/// @nodoc
abstract mixin class $CricketPlayerProfileDtoCopyWith<$Res>  {
  factory $CricketPlayerProfileDtoCopyWith(CricketPlayerProfileDto value, $Res Function(CricketPlayerProfileDto) _then) = _$CricketPlayerProfileDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'sport_id') String sportId,@JsonKey(name: 'batting_style') String? battingStyle,@JsonKey(name: 'bowling_style') String? bowlingStyle,@JsonKey(name: 'player_role') String? playerRole,@JsonKey(name: 'preferred_ball_types') List<String> preferredBallTypes,@JsonKey(name: 'years_playing') int? yearsPlaying
});




}
/// @nodoc
class _$CricketPlayerProfileDtoCopyWithImpl<$Res>
    implements $CricketPlayerProfileDtoCopyWith<$Res> {
  _$CricketPlayerProfileDtoCopyWithImpl(this._self, this._then);

  final CricketPlayerProfileDto _self;
  final $Res Function(CricketPlayerProfileDto) _then;

/// Create a copy of CricketPlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? sportId = null,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? playerRole = freezed,Object? preferredBallTypes = null,Object? yearsPlaying = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,sportId: null == sportId ? _self.sportId : sportId // ignore: cast_nullable_to_non_nullable
as String,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as String?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as String?,playerRole: freezed == playerRole ? _self.playerRole : playerRole // ignore: cast_nullable_to_non_nullable
as String?,preferredBallTypes: null == preferredBallTypes ? _self.preferredBallTypes : preferredBallTypes // ignore: cast_nullable_to_non_nullable
as List<String>,yearsPlaying: freezed == yearsPlaying ? _self.yearsPlaying : yearsPlaying // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CricketPlayerProfileDto].
extension CricketPlayerProfileDtoPatterns on CricketPlayerProfileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CricketPlayerProfileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CricketPlayerProfileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CricketPlayerProfileDto value)  $default,){
final _that = this;
switch (_that) {
case _CricketPlayerProfileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CricketPlayerProfileDto value)?  $default,){
final _that = this;
switch (_that) {
case _CricketPlayerProfileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'sport_id')  String sportId, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'preferred_ball_types')  List<String> preferredBallTypes, @JsonKey(name: 'years_playing')  int? yearsPlaying)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CricketPlayerProfileDto() when $default != null:
return $default(_that.userId,_that.sportId,_that.battingStyle,_that.bowlingStyle,_that.playerRole,_that.preferredBallTypes,_that.yearsPlaying);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'sport_id')  String sportId, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'preferred_ball_types')  List<String> preferredBallTypes, @JsonKey(name: 'years_playing')  int? yearsPlaying)  $default,) {final _that = this;
switch (_that) {
case _CricketPlayerProfileDto():
return $default(_that.userId,_that.sportId,_that.battingStyle,_that.bowlingStyle,_that.playerRole,_that.preferredBallTypes,_that.yearsPlaying);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'sport_id')  String sportId, @JsonKey(name: 'batting_style')  String? battingStyle, @JsonKey(name: 'bowling_style')  String? bowlingStyle, @JsonKey(name: 'player_role')  String? playerRole, @JsonKey(name: 'preferred_ball_types')  List<String> preferredBallTypes, @JsonKey(name: 'years_playing')  int? yearsPlaying)?  $default,) {final _that = this;
switch (_that) {
case _CricketPlayerProfileDto() when $default != null:
return $default(_that.userId,_that.sportId,_that.battingStyle,_that.bowlingStyle,_that.playerRole,_that.preferredBallTypes,_that.yearsPlaying);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CricketPlayerProfileDto extends CricketPlayerProfileDto {
  const _CricketPlayerProfileDto({@JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'sport_id') this.sportId = 'cricket', @JsonKey(name: 'batting_style') this.battingStyle, @JsonKey(name: 'bowling_style') this.bowlingStyle, @JsonKey(name: 'player_role') this.playerRole, @JsonKey(name: 'preferred_ball_types') final  List<String> preferredBallTypes = const <String>[], @JsonKey(name: 'years_playing') this.yearsPlaying}): _preferredBallTypes = preferredBallTypes,super._();
  factory _CricketPlayerProfileDto.fromJson(Map<String, dynamic> json) => _$CricketPlayerProfileDtoFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'sport_id') final  String sportId;
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

/// Create a copy of CricketPlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CricketPlayerProfileDtoCopyWith<_CricketPlayerProfileDto> get copyWith => __$CricketPlayerProfileDtoCopyWithImpl<_CricketPlayerProfileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CricketPlayerProfileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CricketPlayerProfileDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sportId, sportId) || other.sportId == sportId)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.playerRole, playerRole) || other.playerRole == playerRole)&&const DeepCollectionEquality().equals(other._preferredBallTypes, _preferredBallTypes)&&(identical(other.yearsPlaying, yearsPlaying) || other.yearsPlaying == yearsPlaying));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,sportId,battingStyle,bowlingStyle,playerRole,const DeepCollectionEquality().hash(_preferredBallTypes),yearsPlaying);

@override
String toString() {
  return 'CricketPlayerProfileDto(userId: $userId, sportId: $sportId, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, playerRole: $playerRole, preferredBallTypes: $preferredBallTypes, yearsPlaying: $yearsPlaying)';
}


}

/// @nodoc
abstract mixin class _$CricketPlayerProfileDtoCopyWith<$Res> implements $CricketPlayerProfileDtoCopyWith<$Res> {
  factory _$CricketPlayerProfileDtoCopyWith(_CricketPlayerProfileDto value, $Res Function(_CricketPlayerProfileDto) _then) = __$CricketPlayerProfileDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'sport_id') String sportId,@JsonKey(name: 'batting_style') String? battingStyle,@JsonKey(name: 'bowling_style') String? bowlingStyle,@JsonKey(name: 'player_role') String? playerRole,@JsonKey(name: 'preferred_ball_types') List<String> preferredBallTypes,@JsonKey(name: 'years_playing') int? yearsPlaying
});




}
/// @nodoc
class __$CricketPlayerProfileDtoCopyWithImpl<$Res>
    implements _$CricketPlayerProfileDtoCopyWith<$Res> {
  __$CricketPlayerProfileDtoCopyWithImpl(this._self, this._then);

  final _CricketPlayerProfileDto _self;
  final $Res Function(_CricketPlayerProfileDto) _then;

/// Create a copy of CricketPlayerProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? sportId = null,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? playerRole = freezed,Object? preferredBallTypes = null,Object? yearsPlaying = freezed,}) {
  return _then(_CricketPlayerProfileDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,sportId: null == sportId ? _self.sportId : sportId // ignore: cast_nullable_to_non_nullable
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
