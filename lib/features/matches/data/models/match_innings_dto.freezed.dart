// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_innings_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchInningsDto {

@JsonKey(name: 'innings_id') String get inningsId;@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'innings_number') int get inningsNumber;@JsonKey(name: 'batting_team_side') String get battingTeamSide;@JsonKey(name: 'bowling_team_side') String get bowlingTeamSide;@JsonKey(name: 'overs_allocated') double get oversAllocated;@JsonKey(name: 'is_completed') bool get isCompleted;@JsonKey(name: 'start_time') String? get startTime;@JsonKey(name: 'end_time') String? get endTime;
/// Create a copy of MatchInningsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchInningsDtoCopyWith<MatchInningsDto> get copyWith => _$MatchInningsDtoCopyWithImpl<MatchInningsDto>(this as MatchInningsDto, _$identity);

  /// Serializes this MatchInningsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchInningsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.battingTeamSide, battingTeamSide) || other.battingTeamSide == battingTeamSide)&&(identical(other.bowlingTeamSide, bowlingTeamSide) || other.bowlingTeamSide == bowlingTeamSide)&&(identical(other.oversAllocated, oversAllocated) || other.oversAllocated == oversAllocated)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,matchId,inningsNumber,battingTeamSide,bowlingTeamSide,oversAllocated,isCompleted,startTime,endTime);

@override
String toString() {
  return 'MatchInningsDto(inningsId: $inningsId, matchId: $matchId, inningsNumber: $inningsNumber, battingTeamSide: $battingTeamSide, bowlingTeamSide: $bowlingTeamSide, oversAllocated: $oversAllocated, isCompleted: $isCompleted, startTime: $startTime, endTime: $endTime)';
}


}

/// @nodoc
abstract mixin class $MatchInningsDtoCopyWith<$Res>  {
  factory $MatchInningsDtoCopyWith(MatchInningsDto value, $Res Function(MatchInningsDto) _then) = _$MatchInningsDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber,@JsonKey(name: 'batting_team_side') String battingTeamSide,@JsonKey(name: 'bowling_team_side') String bowlingTeamSide,@JsonKey(name: 'overs_allocated') double oversAllocated,@JsonKey(name: 'is_completed') bool isCompleted,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime
});




}
/// @nodoc
class _$MatchInningsDtoCopyWithImpl<$Res>
    implements $MatchInningsDtoCopyWith<$Res> {
  _$MatchInningsDtoCopyWithImpl(this._self, this._then);

  final MatchInningsDto _self;
  final $Res Function(MatchInningsDto) _then;

/// Create a copy of MatchInningsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inningsId = null,Object? matchId = null,Object? inningsNumber = null,Object? battingTeamSide = null,Object? bowlingTeamSide = null,Object? oversAllocated = null,Object? isCompleted = null,Object? startTime = freezed,Object? endTime = freezed,}) {
  return _then(_self.copyWith(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,battingTeamSide: null == battingTeamSide ? _self.battingTeamSide : battingTeamSide // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamSide: null == bowlingTeamSide ? _self.bowlingTeamSide : bowlingTeamSide // ignore: cast_nullable_to_non_nullable
as String,oversAllocated: null == oversAllocated ? _self.oversAllocated : oversAllocated // ignore: cast_nullable_to_non_nullable
as double,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchInningsDto].
extension MatchInningsDtoPatterns on MatchInningsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchInningsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchInningsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchInningsDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchInningsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchInningsDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchInningsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'batting_team_side')  String battingTeamSide, @JsonKey(name: 'bowling_team_side')  String bowlingTeamSide, @JsonKey(name: 'overs_allocated')  double oversAllocated, @JsonKey(name: 'is_completed')  bool isCompleted, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchInningsDto() when $default != null:
return $default(_that.inningsId,_that.matchId,_that.inningsNumber,_that.battingTeamSide,_that.bowlingTeamSide,_that.oversAllocated,_that.isCompleted,_that.startTime,_that.endTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'batting_team_side')  String battingTeamSide, @JsonKey(name: 'bowling_team_side')  String bowlingTeamSide, @JsonKey(name: 'overs_allocated')  double oversAllocated, @JsonKey(name: 'is_completed')  bool isCompleted, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime)  $default,) {final _that = this;
switch (_that) {
case _MatchInningsDto():
return $default(_that.inningsId,_that.matchId,_that.inningsNumber,_that.battingTeamSide,_that.bowlingTeamSide,_that.oversAllocated,_that.isCompleted,_that.startTime,_that.endTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'batting_team_side')  String battingTeamSide, @JsonKey(name: 'bowling_team_side')  String bowlingTeamSide, @JsonKey(name: 'overs_allocated')  double oversAllocated, @JsonKey(name: 'is_completed')  bool isCompleted, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime)?  $default,) {final _that = this;
switch (_that) {
case _MatchInningsDto() when $default != null:
return $default(_that.inningsId,_that.matchId,_that.inningsNumber,_that.battingTeamSide,_that.bowlingTeamSide,_that.oversAllocated,_that.isCompleted,_that.startTime,_that.endTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchInningsDto extends MatchInningsDto {
  const _MatchInningsDto({@JsonKey(name: 'innings_id') required this.inningsId, @JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'innings_number') required this.inningsNumber, @JsonKey(name: 'batting_team_side') required this.battingTeamSide, @JsonKey(name: 'bowling_team_side') required this.bowlingTeamSide, @JsonKey(name: 'overs_allocated') this.oversAllocated = 20.0, @JsonKey(name: 'is_completed') this.isCompleted = false, @JsonKey(name: 'start_time') this.startTime, @JsonKey(name: 'end_time') this.endTime}): super._();
  factory _MatchInningsDto.fromJson(Map<String, dynamic> json) => _$MatchInningsDtoFromJson(json);

@override@JsonKey(name: 'innings_id') final  String inningsId;
@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'innings_number') final  int inningsNumber;
@override@JsonKey(name: 'batting_team_side') final  String battingTeamSide;
@override@JsonKey(name: 'bowling_team_side') final  String bowlingTeamSide;
@override@JsonKey(name: 'overs_allocated') final  double oversAllocated;
@override@JsonKey(name: 'is_completed') final  bool isCompleted;
@override@JsonKey(name: 'start_time') final  String? startTime;
@override@JsonKey(name: 'end_time') final  String? endTime;

/// Create a copy of MatchInningsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchInningsDtoCopyWith<_MatchInningsDto> get copyWith => __$MatchInningsDtoCopyWithImpl<_MatchInningsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchInningsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchInningsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.battingTeamSide, battingTeamSide) || other.battingTeamSide == battingTeamSide)&&(identical(other.bowlingTeamSide, bowlingTeamSide) || other.bowlingTeamSide == bowlingTeamSide)&&(identical(other.oversAllocated, oversAllocated) || other.oversAllocated == oversAllocated)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,matchId,inningsNumber,battingTeamSide,bowlingTeamSide,oversAllocated,isCompleted,startTime,endTime);

@override
String toString() {
  return 'MatchInningsDto(inningsId: $inningsId, matchId: $matchId, inningsNumber: $inningsNumber, battingTeamSide: $battingTeamSide, bowlingTeamSide: $bowlingTeamSide, oversAllocated: $oversAllocated, isCompleted: $isCompleted, startTime: $startTime, endTime: $endTime)';
}


}

/// @nodoc
abstract mixin class _$MatchInningsDtoCopyWith<$Res> implements $MatchInningsDtoCopyWith<$Res> {
  factory _$MatchInningsDtoCopyWith(_MatchInningsDto value, $Res Function(_MatchInningsDto) _then) = __$MatchInningsDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber,@JsonKey(name: 'batting_team_side') String battingTeamSide,@JsonKey(name: 'bowling_team_side') String bowlingTeamSide,@JsonKey(name: 'overs_allocated') double oversAllocated,@JsonKey(name: 'is_completed') bool isCompleted,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime
});




}
/// @nodoc
class __$MatchInningsDtoCopyWithImpl<$Res>
    implements _$MatchInningsDtoCopyWith<$Res> {
  __$MatchInningsDtoCopyWithImpl(this._self, this._then);

  final _MatchInningsDto _self;
  final $Res Function(_MatchInningsDto) _then;

/// Create a copy of MatchInningsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inningsId = null,Object? matchId = null,Object? inningsNumber = null,Object? battingTeamSide = null,Object? bowlingTeamSide = null,Object? oversAllocated = null,Object? isCompleted = null,Object? startTime = freezed,Object? endTime = freezed,}) {
  return _then(_MatchInningsDto(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,battingTeamSide: null == battingTeamSide ? _self.battingTeamSide : battingTeamSide // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamSide: null == bowlingTeamSide ? _self.bowlingTeamSide : bowlingTeamSide // ignore: cast_nullable_to_non_nullable
as String,oversAllocated: null == oversAllocated ? _self.oversAllocated : oversAllocated // ignore: cast_nullable_to_non_nullable
as double,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
