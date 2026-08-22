// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_batsman_stats_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchBatsmanStatsDto {

@JsonKey(name: 'innings_id') String get inningsId;@JsonKey(name: 'player_id') String get playerId;@JsonKey(name: 'batting_position') int? get battingPosition;@JsonKey(name: 'runs') int get runs;@JsonKey(name: 'balls_faced') int get ballsFaced;@JsonKey(name: 'dots') int get dots;@JsonKey(name: 'fours') int get fours;@JsonKey(name: 'sixes') int get sixes;@JsonKey(name: 'singles') int get singles;@JsonKey(name: 'doubles') int get doubles;@JsonKey(name: 'triples') int get triples;@JsonKey(name: 'is_out') bool get isOut;@JsonKey(name: 'dismissal_text') String? get dismissalText;@JsonKey(name: 'minutes_batted') int? get minutesBatted;
/// Create a copy of MatchBatsmanStatsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchBatsmanStatsDtoCopyWith<MatchBatsmanStatsDto> get copyWith => _$MatchBatsmanStatsDtoCopyWithImpl<MatchBatsmanStatsDto>(this as MatchBatsmanStatsDto, _$identity);

  /// Serializes this MatchBatsmanStatsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchBatsmanStatsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.battingPosition, battingPosition) || other.battingPosition == battingPosition)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.ballsFaced, ballsFaced) || other.ballsFaced == ballsFaced)&&(identical(other.dots, dots) || other.dots == dots)&&(identical(other.fours, fours) || other.fours == fours)&&(identical(other.sixes, sixes) || other.sixes == sixes)&&(identical(other.singles, singles) || other.singles == singles)&&(identical(other.doubles, doubles) || other.doubles == doubles)&&(identical(other.triples, triples) || other.triples == triples)&&(identical(other.isOut, isOut) || other.isOut == isOut)&&(identical(other.dismissalText, dismissalText) || other.dismissalText == dismissalText)&&(identical(other.minutesBatted, minutesBatted) || other.minutesBatted == minutesBatted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,playerId,battingPosition,runs,ballsFaced,dots,fours,sixes,singles,doubles,triples,isOut,dismissalText,minutesBatted);

@override
String toString() {
  return 'MatchBatsmanStatsDto(inningsId: $inningsId, playerId: $playerId, battingPosition: $battingPosition, runs: $runs, ballsFaced: $ballsFaced, dots: $dots, fours: $fours, sixes: $sixes, singles: $singles, doubles: $doubles, triples: $triples, isOut: $isOut, dismissalText: $dismissalText, minutesBatted: $minutesBatted)';
}


}

/// @nodoc
abstract mixin class $MatchBatsmanStatsDtoCopyWith<$Res>  {
  factory $MatchBatsmanStatsDtoCopyWith(MatchBatsmanStatsDto value, $Res Function(MatchBatsmanStatsDto) _then) = _$MatchBatsmanStatsDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'batting_position') int? battingPosition,@JsonKey(name: 'runs') int runs,@JsonKey(name: 'balls_faced') int ballsFaced,@JsonKey(name: 'dots') int dots,@JsonKey(name: 'fours') int fours,@JsonKey(name: 'sixes') int sixes,@JsonKey(name: 'singles') int singles,@JsonKey(name: 'doubles') int doubles,@JsonKey(name: 'triples') int triples,@JsonKey(name: 'is_out') bool isOut,@JsonKey(name: 'dismissal_text') String? dismissalText,@JsonKey(name: 'minutes_batted') int? minutesBatted
});




}
/// @nodoc
class _$MatchBatsmanStatsDtoCopyWithImpl<$Res>
    implements $MatchBatsmanStatsDtoCopyWith<$Res> {
  _$MatchBatsmanStatsDtoCopyWithImpl(this._self, this._then);

  final MatchBatsmanStatsDto _self;
  final $Res Function(MatchBatsmanStatsDto) _then;

/// Create a copy of MatchBatsmanStatsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inningsId = null,Object? playerId = null,Object? battingPosition = freezed,Object? runs = null,Object? ballsFaced = null,Object? dots = null,Object? fours = null,Object? sixes = null,Object? singles = null,Object? doubles = null,Object? triples = null,Object? isOut = null,Object? dismissalText = freezed,Object? minutesBatted = freezed,}) {
  return _then(_self.copyWith(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,battingPosition: freezed == battingPosition ? _self.battingPosition : battingPosition // ignore: cast_nullable_to_non_nullable
as int?,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,ballsFaced: null == ballsFaced ? _self.ballsFaced : ballsFaced // ignore: cast_nullable_to_non_nullable
as int,dots: null == dots ? _self.dots : dots // ignore: cast_nullable_to_non_nullable
as int,fours: null == fours ? _self.fours : fours // ignore: cast_nullable_to_non_nullable
as int,sixes: null == sixes ? _self.sixes : sixes // ignore: cast_nullable_to_non_nullable
as int,singles: null == singles ? _self.singles : singles // ignore: cast_nullable_to_non_nullable
as int,doubles: null == doubles ? _self.doubles : doubles // ignore: cast_nullable_to_non_nullable
as int,triples: null == triples ? _self.triples : triples // ignore: cast_nullable_to_non_nullable
as int,isOut: null == isOut ? _self.isOut : isOut // ignore: cast_nullable_to_non_nullable
as bool,dismissalText: freezed == dismissalText ? _self.dismissalText : dismissalText // ignore: cast_nullable_to_non_nullable
as String?,minutesBatted: freezed == minutesBatted ? _self.minutesBatted : minutesBatted // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchBatsmanStatsDto].
extension MatchBatsmanStatsDtoPatterns on MatchBatsmanStatsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchBatsmanStatsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchBatsmanStatsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchBatsmanStatsDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchBatsmanStatsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchBatsmanStatsDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchBatsmanStatsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'batting_position')  int? battingPosition, @JsonKey(name: 'runs')  int runs, @JsonKey(name: 'balls_faced')  int ballsFaced, @JsonKey(name: 'dots')  int dots, @JsonKey(name: 'fours')  int fours, @JsonKey(name: 'sixes')  int sixes, @JsonKey(name: 'singles')  int singles, @JsonKey(name: 'doubles')  int doubles, @JsonKey(name: 'triples')  int triples, @JsonKey(name: 'is_out')  bool isOut, @JsonKey(name: 'dismissal_text')  String? dismissalText, @JsonKey(name: 'minutes_batted')  int? minutesBatted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchBatsmanStatsDto() when $default != null:
return $default(_that.inningsId,_that.playerId,_that.battingPosition,_that.runs,_that.ballsFaced,_that.dots,_that.fours,_that.sixes,_that.singles,_that.doubles,_that.triples,_that.isOut,_that.dismissalText,_that.minutesBatted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'batting_position')  int? battingPosition, @JsonKey(name: 'runs')  int runs, @JsonKey(name: 'balls_faced')  int ballsFaced, @JsonKey(name: 'dots')  int dots, @JsonKey(name: 'fours')  int fours, @JsonKey(name: 'sixes')  int sixes, @JsonKey(name: 'singles')  int singles, @JsonKey(name: 'doubles')  int doubles, @JsonKey(name: 'triples')  int triples, @JsonKey(name: 'is_out')  bool isOut, @JsonKey(name: 'dismissal_text')  String? dismissalText, @JsonKey(name: 'minutes_batted')  int? minutesBatted)  $default,) {final _that = this;
switch (_that) {
case _MatchBatsmanStatsDto():
return $default(_that.inningsId,_that.playerId,_that.battingPosition,_that.runs,_that.ballsFaced,_that.dots,_that.fours,_that.sixes,_that.singles,_that.doubles,_that.triples,_that.isOut,_that.dismissalText,_that.minutesBatted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'batting_position')  int? battingPosition, @JsonKey(name: 'runs')  int runs, @JsonKey(name: 'balls_faced')  int ballsFaced, @JsonKey(name: 'dots')  int dots, @JsonKey(name: 'fours')  int fours, @JsonKey(name: 'sixes')  int sixes, @JsonKey(name: 'singles')  int singles, @JsonKey(name: 'doubles')  int doubles, @JsonKey(name: 'triples')  int triples, @JsonKey(name: 'is_out')  bool isOut, @JsonKey(name: 'dismissal_text')  String? dismissalText, @JsonKey(name: 'minutes_batted')  int? minutesBatted)?  $default,) {final _that = this;
switch (_that) {
case _MatchBatsmanStatsDto() when $default != null:
return $default(_that.inningsId,_that.playerId,_that.battingPosition,_that.runs,_that.ballsFaced,_that.dots,_that.fours,_that.sixes,_that.singles,_that.doubles,_that.triples,_that.isOut,_that.dismissalText,_that.minutesBatted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchBatsmanStatsDto extends MatchBatsmanStatsDto {
  const _MatchBatsmanStatsDto({@JsonKey(name: 'innings_id') required this.inningsId, @JsonKey(name: 'player_id') required this.playerId, @JsonKey(name: 'batting_position') this.battingPosition, @JsonKey(name: 'runs') this.runs = 0, @JsonKey(name: 'balls_faced') this.ballsFaced = 0, @JsonKey(name: 'dots') this.dots = 0, @JsonKey(name: 'fours') this.fours = 0, @JsonKey(name: 'sixes') this.sixes = 0, @JsonKey(name: 'singles') this.singles = 0, @JsonKey(name: 'doubles') this.doubles = 0, @JsonKey(name: 'triples') this.triples = 0, @JsonKey(name: 'is_out') this.isOut = false, @JsonKey(name: 'dismissal_text') this.dismissalText, @JsonKey(name: 'minutes_batted') this.minutesBatted}): super._();
  factory _MatchBatsmanStatsDto.fromJson(Map<String, dynamic> json) => _$MatchBatsmanStatsDtoFromJson(json);

@override@JsonKey(name: 'innings_id') final  String inningsId;
@override@JsonKey(name: 'player_id') final  String playerId;
@override@JsonKey(name: 'batting_position') final  int? battingPosition;
@override@JsonKey(name: 'runs') final  int runs;
@override@JsonKey(name: 'balls_faced') final  int ballsFaced;
@override@JsonKey(name: 'dots') final  int dots;
@override@JsonKey(name: 'fours') final  int fours;
@override@JsonKey(name: 'sixes') final  int sixes;
@override@JsonKey(name: 'singles') final  int singles;
@override@JsonKey(name: 'doubles') final  int doubles;
@override@JsonKey(name: 'triples') final  int triples;
@override@JsonKey(name: 'is_out') final  bool isOut;
@override@JsonKey(name: 'dismissal_text') final  String? dismissalText;
@override@JsonKey(name: 'minutes_batted') final  int? minutesBatted;

/// Create a copy of MatchBatsmanStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchBatsmanStatsDtoCopyWith<_MatchBatsmanStatsDto> get copyWith => __$MatchBatsmanStatsDtoCopyWithImpl<_MatchBatsmanStatsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchBatsmanStatsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchBatsmanStatsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.battingPosition, battingPosition) || other.battingPosition == battingPosition)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.ballsFaced, ballsFaced) || other.ballsFaced == ballsFaced)&&(identical(other.dots, dots) || other.dots == dots)&&(identical(other.fours, fours) || other.fours == fours)&&(identical(other.sixes, sixes) || other.sixes == sixes)&&(identical(other.singles, singles) || other.singles == singles)&&(identical(other.doubles, doubles) || other.doubles == doubles)&&(identical(other.triples, triples) || other.triples == triples)&&(identical(other.isOut, isOut) || other.isOut == isOut)&&(identical(other.dismissalText, dismissalText) || other.dismissalText == dismissalText)&&(identical(other.minutesBatted, minutesBatted) || other.minutesBatted == minutesBatted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,playerId,battingPosition,runs,ballsFaced,dots,fours,sixes,singles,doubles,triples,isOut,dismissalText,minutesBatted);

@override
String toString() {
  return 'MatchBatsmanStatsDto(inningsId: $inningsId, playerId: $playerId, battingPosition: $battingPosition, runs: $runs, ballsFaced: $ballsFaced, dots: $dots, fours: $fours, sixes: $sixes, singles: $singles, doubles: $doubles, triples: $triples, isOut: $isOut, dismissalText: $dismissalText, minutesBatted: $minutesBatted)';
}


}

/// @nodoc
abstract mixin class _$MatchBatsmanStatsDtoCopyWith<$Res> implements $MatchBatsmanStatsDtoCopyWith<$Res> {
  factory _$MatchBatsmanStatsDtoCopyWith(_MatchBatsmanStatsDto value, $Res Function(_MatchBatsmanStatsDto) _then) = __$MatchBatsmanStatsDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'batting_position') int? battingPosition,@JsonKey(name: 'runs') int runs,@JsonKey(name: 'balls_faced') int ballsFaced,@JsonKey(name: 'dots') int dots,@JsonKey(name: 'fours') int fours,@JsonKey(name: 'sixes') int sixes,@JsonKey(name: 'singles') int singles,@JsonKey(name: 'doubles') int doubles,@JsonKey(name: 'triples') int triples,@JsonKey(name: 'is_out') bool isOut,@JsonKey(name: 'dismissal_text') String? dismissalText,@JsonKey(name: 'minutes_batted') int? minutesBatted
});




}
/// @nodoc
class __$MatchBatsmanStatsDtoCopyWithImpl<$Res>
    implements _$MatchBatsmanStatsDtoCopyWith<$Res> {
  __$MatchBatsmanStatsDtoCopyWithImpl(this._self, this._then);

  final _MatchBatsmanStatsDto _self;
  final $Res Function(_MatchBatsmanStatsDto) _then;

/// Create a copy of MatchBatsmanStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inningsId = null,Object? playerId = null,Object? battingPosition = freezed,Object? runs = null,Object? ballsFaced = null,Object? dots = null,Object? fours = null,Object? sixes = null,Object? singles = null,Object? doubles = null,Object? triples = null,Object? isOut = null,Object? dismissalText = freezed,Object? minutesBatted = freezed,}) {
  return _then(_MatchBatsmanStatsDto(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,battingPosition: freezed == battingPosition ? _self.battingPosition : battingPosition // ignore: cast_nullable_to_non_nullable
as int?,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,ballsFaced: null == ballsFaced ? _self.ballsFaced : ballsFaced // ignore: cast_nullable_to_non_nullable
as int,dots: null == dots ? _self.dots : dots // ignore: cast_nullable_to_non_nullable
as int,fours: null == fours ? _self.fours : fours // ignore: cast_nullable_to_non_nullable
as int,sixes: null == sixes ? _self.sixes : sixes // ignore: cast_nullable_to_non_nullable
as int,singles: null == singles ? _self.singles : singles // ignore: cast_nullable_to_non_nullable
as int,doubles: null == doubles ? _self.doubles : doubles // ignore: cast_nullable_to_non_nullable
as int,triples: null == triples ? _self.triples : triples // ignore: cast_nullable_to_non_nullable
as int,isOut: null == isOut ? _self.isOut : isOut // ignore: cast_nullable_to_non_nullable
as bool,dismissalText: freezed == dismissalText ? _self.dismissalText : dismissalText // ignore: cast_nullable_to_non_nullable
as String?,minutesBatted: freezed == minutesBatted ? _self.minutesBatted : minutesBatted // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
