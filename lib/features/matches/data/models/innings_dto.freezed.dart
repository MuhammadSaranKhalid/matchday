// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'innings_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InningsDto {

@JsonKey(name: 'innings_id') String get inningsId;@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'innings_number') int get inningsNumber;@JsonKey(name: 'batting_team_id') String get battingTeamId;@JsonKey(name: 'bowling_team_id') String get bowlingTeamId;@JsonKey(name: 'total_runs') int get totalRuns;@JsonKey(name: 'total_wickets') int get totalWickets;@JsonKey(name: 'total_overs') num get totalOvers;@JsonKey(name: 'total_balls_faced') int get totalBallsFaced; int? get target; String get status;@JsonKey(name: 'current_striker_id') String? get currentStrikerId;@JsonKey(name: 'current_non_striker_id') String? get currentNonStrikerId;@JsonKey(name: 'current_bowler_id') String? get currentBowlerId;
/// Create a copy of InningsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InningsDtoCopyWith<InningsDto> get copyWith => _$InningsDtoCopyWithImpl<InningsDto>(this as InningsDto, _$identity);

  /// Serializes this InningsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InningsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.battingTeamId, battingTeamId) || other.battingTeamId == battingTeamId)&&(identical(other.bowlingTeamId, bowlingTeamId) || other.bowlingTeamId == bowlingTeamId)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalWickets, totalWickets) || other.totalWickets == totalWickets)&&(identical(other.totalOvers, totalOvers) || other.totalOvers == totalOvers)&&(identical(other.totalBallsFaced, totalBallsFaced) || other.totalBallsFaced == totalBallsFaced)&&(identical(other.target, target) || other.target == target)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentStrikerId, currentStrikerId) || other.currentStrikerId == currentStrikerId)&&(identical(other.currentNonStrikerId, currentNonStrikerId) || other.currentNonStrikerId == currentNonStrikerId)&&(identical(other.currentBowlerId, currentBowlerId) || other.currentBowlerId == currentBowlerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,matchId,inningsNumber,battingTeamId,bowlingTeamId,totalRuns,totalWickets,totalOvers,totalBallsFaced,target,status,currentStrikerId,currentNonStrikerId,currentBowlerId);

@override
String toString() {
  return 'InningsDto(inningsId: $inningsId, matchId: $matchId, inningsNumber: $inningsNumber, battingTeamId: $battingTeamId, bowlingTeamId: $bowlingTeamId, totalRuns: $totalRuns, totalWickets: $totalWickets, totalOvers: $totalOvers, totalBallsFaced: $totalBallsFaced, target: $target, status: $status, currentStrikerId: $currentStrikerId, currentNonStrikerId: $currentNonStrikerId, currentBowlerId: $currentBowlerId)';
}


}

/// @nodoc
abstract mixin class $InningsDtoCopyWith<$Res>  {
  factory $InningsDtoCopyWith(InningsDto value, $Res Function(InningsDto) _then) = _$InningsDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber,@JsonKey(name: 'batting_team_id') String battingTeamId,@JsonKey(name: 'bowling_team_id') String bowlingTeamId,@JsonKey(name: 'total_runs') int totalRuns,@JsonKey(name: 'total_wickets') int totalWickets,@JsonKey(name: 'total_overs') num totalOvers,@JsonKey(name: 'total_balls_faced') int totalBallsFaced, int? target, String status,@JsonKey(name: 'current_striker_id') String? currentStrikerId,@JsonKey(name: 'current_non_striker_id') String? currentNonStrikerId,@JsonKey(name: 'current_bowler_id') String? currentBowlerId
});




}
/// @nodoc
class _$InningsDtoCopyWithImpl<$Res>
    implements $InningsDtoCopyWith<$Res> {
  _$InningsDtoCopyWithImpl(this._self, this._then);

  final InningsDto _self;
  final $Res Function(InningsDto) _then;

/// Create a copy of InningsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inningsId = null,Object? matchId = null,Object? inningsNumber = null,Object? battingTeamId = null,Object? bowlingTeamId = null,Object? totalRuns = null,Object? totalWickets = null,Object? totalOvers = null,Object? totalBallsFaced = null,Object? target = freezed,Object? status = null,Object? currentStrikerId = freezed,Object? currentNonStrikerId = freezed,Object? currentBowlerId = freezed,}) {
  return _then(_self.copyWith(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,battingTeamId: null == battingTeamId ? _self.battingTeamId : battingTeamId // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamId: null == bowlingTeamId ? _self.bowlingTeamId : bowlingTeamId // ignore: cast_nullable_to_non_nullable
as String,totalRuns: null == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int,totalWickets: null == totalWickets ? _self.totalWickets : totalWickets // ignore: cast_nullable_to_non_nullable
as int,totalOvers: null == totalOvers ? _self.totalOvers : totalOvers // ignore: cast_nullable_to_non_nullable
as num,totalBallsFaced: null == totalBallsFaced ? _self.totalBallsFaced : totalBallsFaced // ignore: cast_nullable_to_non_nullable
as int,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,currentStrikerId: freezed == currentStrikerId ? _self.currentStrikerId : currentStrikerId // ignore: cast_nullable_to_non_nullable
as String?,currentNonStrikerId: freezed == currentNonStrikerId ? _self.currentNonStrikerId : currentNonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,currentBowlerId: freezed == currentBowlerId ? _self.currentBowlerId : currentBowlerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InningsDto].
extension InningsDtoPatterns on InningsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InningsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InningsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InningsDto value)  $default,){
final _that = this;
switch (_that) {
case _InningsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InningsDto value)?  $default,){
final _that = this;
switch (_that) {
case _InningsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'batting_team_id')  String battingTeamId, @JsonKey(name: 'bowling_team_id')  String bowlingTeamId, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'total_wickets')  int totalWickets, @JsonKey(name: 'total_overs')  num totalOvers, @JsonKey(name: 'total_balls_faced')  int totalBallsFaced,  int? target,  String status, @JsonKey(name: 'current_striker_id')  String? currentStrikerId, @JsonKey(name: 'current_non_striker_id')  String? currentNonStrikerId, @JsonKey(name: 'current_bowler_id')  String? currentBowlerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InningsDto() when $default != null:
return $default(_that.inningsId,_that.matchId,_that.inningsNumber,_that.battingTeamId,_that.bowlingTeamId,_that.totalRuns,_that.totalWickets,_that.totalOvers,_that.totalBallsFaced,_that.target,_that.status,_that.currentStrikerId,_that.currentNonStrikerId,_that.currentBowlerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'batting_team_id')  String battingTeamId, @JsonKey(name: 'bowling_team_id')  String bowlingTeamId, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'total_wickets')  int totalWickets, @JsonKey(name: 'total_overs')  num totalOvers, @JsonKey(name: 'total_balls_faced')  int totalBallsFaced,  int? target,  String status, @JsonKey(name: 'current_striker_id')  String? currentStrikerId, @JsonKey(name: 'current_non_striker_id')  String? currentNonStrikerId, @JsonKey(name: 'current_bowler_id')  String? currentBowlerId)  $default,) {final _that = this;
switch (_that) {
case _InningsDto():
return $default(_that.inningsId,_that.matchId,_that.inningsNumber,_that.battingTeamId,_that.bowlingTeamId,_that.totalRuns,_that.totalWickets,_that.totalOvers,_that.totalBallsFaced,_that.target,_that.status,_that.currentStrikerId,_that.currentNonStrikerId,_that.currentBowlerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'batting_team_id')  String battingTeamId, @JsonKey(name: 'bowling_team_id')  String bowlingTeamId, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'total_wickets')  int totalWickets, @JsonKey(name: 'total_overs')  num totalOvers, @JsonKey(name: 'total_balls_faced')  int totalBallsFaced,  int? target,  String status, @JsonKey(name: 'current_striker_id')  String? currentStrikerId, @JsonKey(name: 'current_non_striker_id')  String? currentNonStrikerId, @JsonKey(name: 'current_bowler_id')  String? currentBowlerId)?  $default,) {final _that = this;
switch (_that) {
case _InningsDto() when $default != null:
return $default(_that.inningsId,_that.matchId,_that.inningsNumber,_that.battingTeamId,_that.bowlingTeamId,_that.totalRuns,_that.totalWickets,_that.totalOvers,_that.totalBallsFaced,_that.target,_that.status,_that.currentStrikerId,_that.currentNonStrikerId,_that.currentBowlerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InningsDto extends InningsDto {
  const _InningsDto({@JsonKey(name: 'innings_id') required this.inningsId, @JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'innings_number') required this.inningsNumber, @JsonKey(name: 'batting_team_id') required this.battingTeamId, @JsonKey(name: 'bowling_team_id') required this.bowlingTeamId, @JsonKey(name: 'total_runs') this.totalRuns = 0, @JsonKey(name: 'total_wickets') this.totalWickets = 0, @JsonKey(name: 'total_overs') this.totalOvers = 0, @JsonKey(name: 'total_balls_faced') this.totalBallsFaced = 0, this.target, this.status = 'in_progress', @JsonKey(name: 'current_striker_id') this.currentStrikerId, @JsonKey(name: 'current_non_striker_id') this.currentNonStrikerId, @JsonKey(name: 'current_bowler_id') this.currentBowlerId}): super._();
  factory _InningsDto.fromJson(Map<String, dynamic> json) => _$InningsDtoFromJson(json);

@override@JsonKey(name: 'innings_id') final  String inningsId;
@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'innings_number') final  int inningsNumber;
@override@JsonKey(name: 'batting_team_id') final  String battingTeamId;
@override@JsonKey(name: 'bowling_team_id') final  String bowlingTeamId;
@override@JsonKey(name: 'total_runs') final  int totalRuns;
@override@JsonKey(name: 'total_wickets') final  int totalWickets;
@override@JsonKey(name: 'total_overs') final  num totalOvers;
@override@JsonKey(name: 'total_balls_faced') final  int totalBallsFaced;
@override final  int? target;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'current_striker_id') final  String? currentStrikerId;
@override@JsonKey(name: 'current_non_striker_id') final  String? currentNonStrikerId;
@override@JsonKey(name: 'current_bowler_id') final  String? currentBowlerId;

/// Create a copy of InningsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InningsDtoCopyWith<_InningsDto> get copyWith => __$InningsDtoCopyWithImpl<_InningsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InningsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InningsDto&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.battingTeamId, battingTeamId) || other.battingTeamId == battingTeamId)&&(identical(other.bowlingTeamId, bowlingTeamId) || other.bowlingTeamId == bowlingTeamId)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalWickets, totalWickets) || other.totalWickets == totalWickets)&&(identical(other.totalOvers, totalOvers) || other.totalOvers == totalOvers)&&(identical(other.totalBallsFaced, totalBallsFaced) || other.totalBallsFaced == totalBallsFaced)&&(identical(other.target, target) || other.target == target)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentStrikerId, currentStrikerId) || other.currentStrikerId == currentStrikerId)&&(identical(other.currentNonStrikerId, currentNonStrikerId) || other.currentNonStrikerId == currentNonStrikerId)&&(identical(other.currentBowlerId, currentBowlerId) || other.currentBowlerId == currentBowlerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inningsId,matchId,inningsNumber,battingTeamId,bowlingTeamId,totalRuns,totalWickets,totalOvers,totalBallsFaced,target,status,currentStrikerId,currentNonStrikerId,currentBowlerId);

@override
String toString() {
  return 'InningsDto(inningsId: $inningsId, matchId: $matchId, inningsNumber: $inningsNumber, battingTeamId: $battingTeamId, bowlingTeamId: $bowlingTeamId, totalRuns: $totalRuns, totalWickets: $totalWickets, totalOvers: $totalOvers, totalBallsFaced: $totalBallsFaced, target: $target, status: $status, currentStrikerId: $currentStrikerId, currentNonStrikerId: $currentNonStrikerId, currentBowlerId: $currentBowlerId)';
}


}

/// @nodoc
abstract mixin class _$InningsDtoCopyWith<$Res> implements $InningsDtoCopyWith<$Res> {
  factory _$InningsDtoCopyWith(_InningsDto value, $Res Function(_InningsDto) _then) = __$InningsDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber,@JsonKey(name: 'batting_team_id') String battingTeamId,@JsonKey(name: 'bowling_team_id') String bowlingTeamId,@JsonKey(name: 'total_runs') int totalRuns,@JsonKey(name: 'total_wickets') int totalWickets,@JsonKey(name: 'total_overs') num totalOvers,@JsonKey(name: 'total_balls_faced') int totalBallsFaced, int? target, String status,@JsonKey(name: 'current_striker_id') String? currentStrikerId,@JsonKey(name: 'current_non_striker_id') String? currentNonStrikerId,@JsonKey(name: 'current_bowler_id') String? currentBowlerId
});




}
/// @nodoc
class __$InningsDtoCopyWithImpl<$Res>
    implements _$InningsDtoCopyWith<$Res> {
  __$InningsDtoCopyWithImpl(this._self, this._then);

  final _InningsDto _self;
  final $Res Function(_InningsDto) _then;

/// Create a copy of InningsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inningsId = null,Object? matchId = null,Object? inningsNumber = null,Object? battingTeamId = null,Object? bowlingTeamId = null,Object? totalRuns = null,Object? totalWickets = null,Object? totalOvers = null,Object? totalBallsFaced = null,Object? target = freezed,Object? status = null,Object? currentStrikerId = freezed,Object? currentNonStrikerId = freezed,Object? currentBowlerId = freezed,}) {
  return _then(_InningsDto(
inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,battingTeamId: null == battingTeamId ? _self.battingTeamId : battingTeamId // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamId: null == bowlingTeamId ? _self.bowlingTeamId : bowlingTeamId // ignore: cast_nullable_to_non_nullable
as String,totalRuns: null == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int,totalWickets: null == totalWickets ? _self.totalWickets : totalWickets // ignore: cast_nullable_to_non_nullable
as int,totalOvers: null == totalOvers ? _self.totalOvers : totalOvers // ignore: cast_nullable_to_non_nullable
as num,totalBallsFaced: null == totalBallsFaced ? _self.totalBallsFaced : totalBallsFaced // ignore: cast_nullable_to_non_nullable
as int,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,currentStrikerId: freezed == currentStrikerId ? _self.currentStrikerId : currentStrikerId // ignore: cast_nullable_to_non_nullable
as String?,currentNonStrikerId: freezed == currentNonStrikerId ? _self.currentNonStrikerId : currentNonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,currentBowlerId: freezed == currentBowlerId ? _self.currentBowlerId : currentBowlerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
