// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_bowler_stats_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchBowlerStatsDto {

@JsonKey(name: 'innings_id') String get inningsId;@JsonKey(name: 'player_id') String get playerId;@JsonKey(name: 'bowling_position') int? get bowlingPosition;@JsonKey(name: 'legal_balls_bowled') int get legalBallsBowled;@JsonKey(name: 'maidens') int get maidens;@JsonKey(name: 'runs_conceded') int get runsConceded;@JsonKey(name: 'wickets') int get wickets;@JsonKey(name: 'wides_conceded') int get widesConceded;@JsonKey(name: 'no_balls_conceded') int get noBallsConceded;@JsonKey(name: 'dot_balls_bowled') int get dotBallsBowled;
/// Create a copy of MatchBowlerStatsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchBowlerStatsDtoCopyWith<MatchBowlerStatsDto> get copyWith => _$MatchBowlerStatsDtoCopyWithImpl<MatchBowlerStatsDto>(this as MatchBowlerStatsDto, _$identity);

  /// Serializes this MatchBowlerStatsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchBowlerStatsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.bowlingPosition, bowlingPosition) || other.bowlingPosition == bowlingPosition)&&(identical(other.legalBallsBowled, legalBallsBowled) || other.legalBallsBowled == legalBallsBowled)&&(identical(other.maidens, maidens) || other.maidens == maidens)&&(identical(other.runsConceded, runsConceded) || other.runsConceded == runsConceded)&&(identical(other.wickets, wickets) || other.wickets == wickets)&&(identical(other.widesConceded, widesConceded) || other.widesConceded == widesConceded)&&(identical(other.noBallsConceded, noBallsConceded) || other.noBallsConceded == noBallsConceded)&&(identical(other.dotBallsBowled, dotBallsBowled) || other.dotBallsBowled == dotBallsBowled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,playerId,bowlingPosition,legalBallsBowled,maidens,runsConceded,wickets,widesConceded,noBallsConceded,dotBallsBowled);

@override
String toString() {
  return 'MatchBowlerStatsDto(inningsId: $inningsId, playerId: $playerId, bowlingPosition: $bowlingPosition, legalBallsBowled: $legalBallsBowled, maidens: $maidens, runsConceded: $runsConceded, wickets: $wickets, widesConceded: $widesConceded, noBallsConceded: $noBallsConceded, dotBallsBowled: $dotBallsBowled)';
}


}

/// @nodoc
abstract mixin class $MatchBowlerStatsDtoCopyWith<$Res>  {
  factory $MatchBowlerStatsDtoCopyWith(MatchBowlerStatsDto value, $Res Function(MatchBowlerStatsDto) _then) = _$MatchBowlerStatsDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'bowling_position') int? bowlingPosition,@JsonKey(name: 'legal_balls_bowled') int legalBallsBowled,@JsonKey(name: 'maidens') int maidens,@JsonKey(name: 'runs_conceded') int runsConceded,@JsonKey(name: 'wickets') int wickets,@JsonKey(name: 'wides_conceded') int widesConceded,@JsonKey(name: 'no_balls_conceded') int noBallsConceded,@JsonKey(name: 'dot_balls_bowled') int dotBallsBowled
});




}
/// @nodoc
class _$MatchBowlerStatsDtoCopyWithImpl<$Res>
    implements $MatchBowlerStatsDtoCopyWith<$Res> {
  _$MatchBowlerStatsDtoCopyWithImpl(this._self, this._then);

  final MatchBowlerStatsDto _self;
  final $Res Function(MatchBowlerStatsDto) _then;

/// Create a copy of MatchBowlerStatsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inningsId = null,Object? playerId = null,Object? bowlingPosition = freezed,Object? legalBallsBowled = null,Object? maidens = null,Object? runsConceded = null,Object? wickets = null,Object? widesConceded = null,Object? noBallsConceded = null,Object? dotBallsBowled = null,}) {
  return _then(_self.copyWith(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,bowlingPosition: freezed == bowlingPosition ? _self.bowlingPosition : bowlingPosition // ignore: cast_nullable_to_non_nullable
as int?,legalBallsBowled: null == legalBallsBowled ? _self.legalBallsBowled : legalBallsBowled // ignore: cast_nullable_to_non_nullable
as int,maidens: null == maidens ? _self.maidens : maidens // ignore: cast_nullable_to_non_nullable
as int,runsConceded: null == runsConceded ? _self.runsConceded : runsConceded // ignore: cast_nullable_to_non_nullable
as int,wickets: null == wickets ? _self.wickets : wickets // ignore: cast_nullable_to_non_nullable
as int,widesConceded: null == widesConceded ? _self.widesConceded : widesConceded // ignore: cast_nullable_to_non_nullable
as int,noBallsConceded: null == noBallsConceded ? _self.noBallsConceded : noBallsConceded // ignore: cast_nullable_to_non_nullable
as int,dotBallsBowled: null == dotBallsBowled ? _self.dotBallsBowled : dotBallsBowled // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchBowlerStatsDto].
extension MatchBowlerStatsDtoPatterns on MatchBowlerStatsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchBowlerStatsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchBowlerStatsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchBowlerStatsDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchBowlerStatsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchBowlerStatsDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchBowlerStatsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'bowling_position')  int? bowlingPosition, @JsonKey(name: 'legal_balls_bowled')  int legalBallsBowled, @JsonKey(name: 'maidens')  int maidens, @JsonKey(name: 'runs_conceded')  int runsConceded, @JsonKey(name: 'wickets')  int wickets, @JsonKey(name: 'wides_conceded')  int widesConceded, @JsonKey(name: 'no_balls_conceded')  int noBallsConceded, @JsonKey(name: 'dot_balls_bowled')  int dotBallsBowled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchBowlerStatsDto() when $default != null:
return $default(_that.inningsId,_that.playerId,_that.bowlingPosition,_that.legalBallsBowled,_that.maidens,_that.runsConceded,_that.wickets,_that.widesConceded,_that.noBallsConceded,_that.dotBallsBowled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'bowling_position')  int? bowlingPosition, @JsonKey(name: 'legal_balls_bowled')  int legalBallsBowled, @JsonKey(name: 'maidens')  int maidens, @JsonKey(name: 'runs_conceded')  int runsConceded, @JsonKey(name: 'wickets')  int wickets, @JsonKey(name: 'wides_conceded')  int widesConceded, @JsonKey(name: 'no_balls_conceded')  int noBallsConceded, @JsonKey(name: 'dot_balls_bowled')  int dotBallsBowled)  $default,) {final _that = this;
switch (_that) {
case _MatchBowlerStatsDto():
return $default(_that.inningsId,_that.playerId,_that.bowlingPosition,_that.legalBallsBowled,_that.maidens,_that.runsConceded,_that.wickets,_that.widesConceded,_that.noBallsConceded,_that.dotBallsBowled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'bowling_position')  int? bowlingPosition, @JsonKey(name: 'legal_balls_bowled')  int legalBallsBowled, @JsonKey(name: 'maidens')  int maidens, @JsonKey(name: 'runs_conceded')  int runsConceded, @JsonKey(name: 'wickets')  int wickets, @JsonKey(name: 'wides_conceded')  int widesConceded, @JsonKey(name: 'no_balls_conceded')  int noBallsConceded, @JsonKey(name: 'dot_balls_bowled')  int dotBallsBowled)?  $default,) {final _that = this;
switch (_that) {
case _MatchBowlerStatsDto() when $default != null:
return $default(_that.inningsId,_that.playerId,_that.bowlingPosition,_that.legalBallsBowled,_that.maidens,_that.runsConceded,_that.wickets,_that.widesConceded,_that.noBallsConceded,_that.dotBallsBowled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchBowlerStatsDto extends MatchBowlerStatsDto {
  const _MatchBowlerStatsDto({@JsonKey(name: 'innings_id') required this.inningsId, @JsonKey(name: 'player_id') required this.playerId, @JsonKey(name: 'bowling_position') this.bowlingPosition, @JsonKey(name: 'legal_balls_bowled') this.legalBallsBowled = 0, @JsonKey(name: 'maidens') this.maidens = 0, @JsonKey(name: 'runs_conceded') this.runsConceded = 0, @JsonKey(name: 'wickets') this.wickets = 0, @JsonKey(name: 'wides_conceded') this.widesConceded = 0, @JsonKey(name: 'no_balls_conceded') this.noBallsConceded = 0, @JsonKey(name: 'dot_balls_bowled') this.dotBallsBowled = 0}): super._();
  factory _MatchBowlerStatsDto.fromJson(Map<String, dynamic> json) => _$MatchBowlerStatsDtoFromJson(json);

@override@JsonKey(name: 'innings_id') final  String inningsId;
@override@JsonKey(name: 'player_id') final  String playerId;
@override@JsonKey(name: 'bowling_position') final  int? bowlingPosition;
@override@JsonKey(name: 'legal_balls_bowled') final  int legalBallsBowled;
@override@JsonKey(name: 'maidens') final  int maidens;
@override@JsonKey(name: 'runs_conceded') final  int runsConceded;
@override@JsonKey(name: 'wickets') final  int wickets;
@override@JsonKey(name: 'wides_conceded') final  int widesConceded;
@override@JsonKey(name: 'no_balls_conceded') final  int noBallsConceded;
@override@JsonKey(name: 'dot_balls_bowled') final  int dotBallsBowled;

/// Create a copy of MatchBowlerStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchBowlerStatsDtoCopyWith<_MatchBowlerStatsDto> get copyWith => __$MatchBowlerStatsDtoCopyWithImpl<_MatchBowlerStatsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchBowlerStatsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchBowlerStatsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.bowlingPosition, bowlingPosition) || other.bowlingPosition == bowlingPosition)&&(identical(other.legalBallsBowled, legalBallsBowled) || other.legalBallsBowled == legalBallsBowled)&&(identical(other.maidens, maidens) || other.maidens == maidens)&&(identical(other.runsConceded, runsConceded) || other.runsConceded == runsConceded)&&(identical(other.wickets, wickets) || other.wickets == wickets)&&(identical(other.widesConceded, widesConceded) || other.widesConceded == widesConceded)&&(identical(other.noBallsConceded, noBallsConceded) || other.noBallsConceded == noBallsConceded)&&(identical(other.dotBallsBowled, dotBallsBowled) || other.dotBallsBowled == dotBallsBowled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,playerId,bowlingPosition,legalBallsBowled,maidens,runsConceded,wickets,widesConceded,noBallsConceded,dotBallsBowled);

@override
String toString() {
  return 'MatchBowlerStatsDto(inningsId: $inningsId, playerId: $playerId, bowlingPosition: $bowlingPosition, legalBallsBowled: $legalBallsBowled, maidens: $maidens, runsConceded: $runsConceded, wickets: $wickets, widesConceded: $widesConceded, noBallsConceded: $noBallsConceded, dotBallsBowled: $dotBallsBowled)';
}


}

/// @nodoc
abstract mixin class _$MatchBowlerStatsDtoCopyWith<$Res> implements $MatchBowlerStatsDtoCopyWith<$Res> {
  factory _$MatchBowlerStatsDtoCopyWith(_MatchBowlerStatsDto value, $Res Function(_MatchBowlerStatsDto) _then) = __$MatchBowlerStatsDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'bowling_position') int? bowlingPosition,@JsonKey(name: 'legal_balls_bowled') int legalBallsBowled,@JsonKey(name: 'maidens') int maidens,@JsonKey(name: 'runs_conceded') int runsConceded,@JsonKey(name: 'wickets') int wickets,@JsonKey(name: 'wides_conceded') int widesConceded,@JsonKey(name: 'no_balls_conceded') int noBallsConceded,@JsonKey(name: 'dot_balls_bowled') int dotBallsBowled
});




}
/// @nodoc
class __$MatchBowlerStatsDtoCopyWithImpl<$Res>
    implements _$MatchBowlerStatsDtoCopyWith<$Res> {
  __$MatchBowlerStatsDtoCopyWithImpl(this._self, this._then);

  final _MatchBowlerStatsDto _self;
  final $Res Function(_MatchBowlerStatsDto) _then;

/// Create a copy of MatchBowlerStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inningsId = null,Object? playerId = null,Object? bowlingPosition = freezed,Object? legalBallsBowled = null,Object? maidens = null,Object? runsConceded = null,Object? wickets = null,Object? widesConceded = null,Object? noBallsConceded = null,Object? dotBallsBowled = null,}) {
  return _then(_MatchBowlerStatsDto(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,bowlingPosition: freezed == bowlingPosition ? _self.bowlingPosition : bowlingPosition // ignore: cast_nullable_to_non_nullable
as int?,legalBallsBowled: null == legalBallsBowled ? _self.legalBallsBowled : legalBallsBowled // ignore: cast_nullable_to_non_nullable
as int,maidens: null == maidens ? _self.maidens : maidens // ignore: cast_nullable_to_non_nullable
as int,runsConceded: null == runsConceded ? _self.runsConceded : runsConceded // ignore: cast_nullable_to_non_nullable
as int,wickets: null == wickets ? _self.wickets : wickets // ignore: cast_nullable_to_non_nullable
as int,widesConceded: null == widesConceded ? _self.widesConceded : widesConceded // ignore: cast_nullable_to_non_nullable
as int,noBallsConceded: null == noBallsConceded ? _self.noBallsConceded : noBallsConceded // ignore: cast_nullable_to_non_nullable
as int,dotBallsBowled: null == dotBallsBowled ? _self.dotBallsBowled : dotBallsBowled // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
