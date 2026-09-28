// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchResultDto {

@JsonKey(name: 'match_id') String get matchId; String get status; String? get venue;@JsonKey(name: 'tournament_name') String? get tournamentName;@JsonKey(name: 'scheduled_start_time') String? get scheduledStartTime;@JsonKey(name: 'actual_start_time') String? get actualStartTime;@JsonKey(name: 'team_a_id') String? get teamAId;@JsonKey(name: 'team_a_name') String? get teamAName;@JsonKey(name: 'team_a_colors') Map<String, dynamic>? get teamAColors;@JsonKey(name: 'team_a_logo') String? get teamALogo;@JsonKey(name: 'team_b_id') String? get teamBId;@JsonKey(name: 'team_b_name') String? get teamBName;@JsonKey(name: 'team_b_colors') Map<String, dynamic>? get teamBColors;@JsonKey(name: 'team_b_logo') String? get teamBLogo;@JsonKey(name: 'innings_number') int? get inningsNumber;@JsonKey(name: 'total_runs') int? get totalRuns;@JsonKey(name: 'total_wickets') int? get totalWickets;@JsonKey(name: 'legal_ball_count') int? get legalBallCount; int? get target;@JsonKey(name: 'batting_team_id') String? get battingTeamId;
/// Create a copy of MatchResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchResultDtoCopyWith<MatchResultDto> get copyWith => _$MatchResultDtoCopyWithImpl<MatchResultDto>(this as MatchResultDto, _$identity);

  /// Serializes this MatchResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchResultDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.status, status) || other.status == status)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.tournamentName, tournamentName) || other.tournamentName == tournamentName)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime)&&(identical(other.actualStartTime, actualStartTime) || other.actualStartTime == actualStartTime)&&(identical(other.teamAId, teamAId) || other.teamAId == teamAId)&&(identical(other.teamAName, teamAName) || other.teamAName == teamAName)&&const DeepCollectionEquality().equals(other.teamAColors, teamAColors)&&(identical(other.teamALogo, teamALogo) || other.teamALogo == teamALogo)&&(identical(other.teamBId, teamBId) || other.teamBId == teamBId)&&(identical(other.teamBName, teamBName) || other.teamBName == teamBName)&&const DeepCollectionEquality().equals(other.teamBColors, teamBColors)&&(identical(other.teamBLogo, teamBLogo) || other.teamBLogo == teamBLogo)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalWickets, totalWickets) || other.totalWickets == totalWickets)&&(identical(other.legalBallCount, legalBallCount) || other.legalBallCount == legalBallCount)&&(identical(other.target, target) || other.target == target)&&(identical(other.battingTeamId, battingTeamId) || other.battingTeamId == battingTeamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,matchId,status,venue,tournamentName,scheduledStartTime,actualStartTime,teamAId,teamAName,const DeepCollectionEquality().hash(teamAColors),teamALogo,teamBId,teamBName,const DeepCollectionEquality().hash(teamBColors),teamBLogo,inningsNumber,totalRuns,totalWickets,legalBallCount,target,battingTeamId]);

@override
String toString() {
  return 'MatchResultDto(matchId: $matchId, status: $status, venue: $venue, tournamentName: $tournamentName, scheduledStartTime: $scheduledStartTime, actualStartTime: $actualStartTime, teamAId: $teamAId, teamAName: $teamAName, teamAColors: $teamAColors, teamALogo: $teamALogo, teamBId: $teamBId, teamBName: $teamBName, teamBColors: $teamBColors, teamBLogo: $teamBLogo, inningsNumber: $inningsNumber, totalRuns: $totalRuns, totalWickets: $totalWickets, legalBallCount: $legalBallCount, target: $target, battingTeamId: $battingTeamId)';
}


}

/// @nodoc
abstract mixin class $MatchResultDtoCopyWith<$Res>  {
  factory $MatchResultDtoCopyWith(MatchResultDto value, $Res Function(MatchResultDto) _then) = _$MatchResultDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'match_id') String matchId, String status, String? venue,@JsonKey(name: 'tournament_name') String? tournamentName,@JsonKey(name: 'scheduled_start_time') String? scheduledStartTime,@JsonKey(name: 'actual_start_time') String? actualStartTime,@JsonKey(name: 'team_a_id') String? teamAId,@JsonKey(name: 'team_a_name') String? teamAName,@JsonKey(name: 'team_a_colors') Map<String, dynamic>? teamAColors,@JsonKey(name: 'team_a_logo') String? teamALogo,@JsonKey(name: 'team_b_id') String? teamBId,@JsonKey(name: 'team_b_name') String? teamBName,@JsonKey(name: 'team_b_colors') Map<String, dynamic>? teamBColors,@JsonKey(name: 'team_b_logo') String? teamBLogo,@JsonKey(name: 'innings_number') int? inningsNumber,@JsonKey(name: 'total_runs') int? totalRuns,@JsonKey(name: 'total_wickets') int? totalWickets,@JsonKey(name: 'legal_ball_count') int? legalBallCount, int? target,@JsonKey(name: 'batting_team_id') String? battingTeamId
});




}
/// @nodoc
class _$MatchResultDtoCopyWithImpl<$Res>
    implements $MatchResultDtoCopyWith<$Res> {
  _$MatchResultDtoCopyWithImpl(this._self, this._then);

  final MatchResultDto _self;
  final $Res Function(MatchResultDto) _then;

/// Create a copy of MatchResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchId = null,Object? status = null,Object? venue = freezed,Object? tournamentName = freezed,Object? scheduledStartTime = freezed,Object? actualStartTime = freezed,Object? teamAId = freezed,Object? teamAName = freezed,Object? teamAColors = freezed,Object? teamALogo = freezed,Object? teamBId = freezed,Object? teamBName = freezed,Object? teamBColors = freezed,Object? teamBLogo = freezed,Object? inningsNumber = freezed,Object? totalRuns = freezed,Object? totalWickets = freezed,Object? legalBallCount = freezed,Object? target = freezed,Object? battingTeamId = freezed,}) {
  return _then(_self.copyWith(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String?,tournamentName: freezed == tournamentName ? _self.tournamentName : tournamentName // ignore: cast_nullable_to_non_nullable
as String?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as String?,actualStartTime: freezed == actualStartTime ? _self.actualStartTime : actualStartTime // ignore: cast_nullable_to_non_nullable
as String?,teamAId: freezed == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String?,teamAName: freezed == teamAName ? _self.teamAName : teamAName // ignore: cast_nullable_to_non_nullable
as String?,teamAColors: freezed == teamAColors ? _self.teamAColors : teamAColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,teamALogo: freezed == teamALogo ? _self.teamALogo : teamALogo // ignore: cast_nullable_to_non_nullable
as String?,teamBId: freezed == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String?,teamBName: freezed == teamBName ? _self.teamBName : teamBName // ignore: cast_nullable_to_non_nullable
as String?,teamBColors: freezed == teamBColors ? _self.teamBColors : teamBColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,teamBLogo: freezed == teamBLogo ? _self.teamBLogo : teamBLogo // ignore: cast_nullable_to_non_nullable
as String?,inningsNumber: freezed == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int?,totalRuns: freezed == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int?,totalWickets: freezed == totalWickets ? _self.totalWickets : totalWickets // ignore: cast_nullable_to_non_nullable
as int?,legalBallCount: freezed == legalBallCount ? _self.legalBallCount : legalBallCount // ignore: cast_nullable_to_non_nullable
as int?,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int?,battingTeamId: freezed == battingTeamId ? _self.battingTeamId : battingTeamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchResultDto].
extension MatchResultDtoPatterns on MatchResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchResultDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId,  String status,  String? venue, @JsonKey(name: 'tournament_name')  String? tournamentName, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime, @JsonKey(name: 'actual_start_time')  String? actualStartTime, @JsonKey(name: 'team_a_id')  String? teamAId, @JsonKey(name: 'team_a_name')  String? teamAName, @JsonKey(name: 'team_a_colors')  Map<String, dynamic>? teamAColors, @JsonKey(name: 'team_a_logo')  String? teamALogo, @JsonKey(name: 'team_b_id')  String? teamBId, @JsonKey(name: 'team_b_name')  String? teamBName, @JsonKey(name: 'team_b_colors')  Map<String, dynamic>? teamBColors, @JsonKey(name: 'team_b_logo')  String? teamBLogo, @JsonKey(name: 'innings_number')  int? inningsNumber, @JsonKey(name: 'total_runs')  int? totalRuns, @JsonKey(name: 'total_wickets')  int? totalWickets, @JsonKey(name: 'legal_ball_count')  int? legalBallCount,  int? target, @JsonKey(name: 'batting_team_id')  String? battingTeamId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchResultDto() when $default != null:
return $default(_that.matchId,_that.status,_that.venue,_that.tournamentName,_that.scheduledStartTime,_that.actualStartTime,_that.teamAId,_that.teamAName,_that.teamAColors,_that.teamALogo,_that.teamBId,_that.teamBName,_that.teamBColors,_that.teamBLogo,_that.inningsNumber,_that.totalRuns,_that.totalWickets,_that.legalBallCount,_that.target,_that.battingTeamId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId,  String status,  String? venue, @JsonKey(name: 'tournament_name')  String? tournamentName, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime, @JsonKey(name: 'actual_start_time')  String? actualStartTime, @JsonKey(name: 'team_a_id')  String? teamAId, @JsonKey(name: 'team_a_name')  String? teamAName, @JsonKey(name: 'team_a_colors')  Map<String, dynamic>? teamAColors, @JsonKey(name: 'team_a_logo')  String? teamALogo, @JsonKey(name: 'team_b_id')  String? teamBId, @JsonKey(name: 'team_b_name')  String? teamBName, @JsonKey(name: 'team_b_colors')  Map<String, dynamic>? teamBColors, @JsonKey(name: 'team_b_logo')  String? teamBLogo, @JsonKey(name: 'innings_number')  int? inningsNumber, @JsonKey(name: 'total_runs')  int? totalRuns, @JsonKey(name: 'total_wickets')  int? totalWickets, @JsonKey(name: 'legal_ball_count')  int? legalBallCount,  int? target, @JsonKey(name: 'batting_team_id')  String? battingTeamId)  $default,) {final _that = this;
switch (_that) {
case _MatchResultDto():
return $default(_that.matchId,_that.status,_that.venue,_that.tournamentName,_that.scheduledStartTime,_that.actualStartTime,_that.teamAId,_that.teamAName,_that.teamAColors,_that.teamALogo,_that.teamBId,_that.teamBName,_that.teamBColors,_that.teamBLogo,_that.inningsNumber,_that.totalRuns,_that.totalWickets,_that.legalBallCount,_that.target,_that.battingTeamId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'match_id')  String matchId,  String status,  String? venue, @JsonKey(name: 'tournament_name')  String? tournamentName, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime, @JsonKey(name: 'actual_start_time')  String? actualStartTime, @JsonKey(name: 'team_a_id')  String? teamAId, @JsonKey(name: 'team_a_name')  String? teamAName, @JsonKey(name: 'team_a_colors')  Map<String, dynamic>? teamAColors, @JsonKey(name: 'team_a_logo')  String? teamALogo, @JsonKey(name: 'team_b_id')  String? teamBId, @JsonKey(name: 'team_b_name')  String? teamBName, @JsonKey(name: 'team_b_colors')  Map<String, dynamic>? teamBColors, @JsonKey(name: 'team_b_logo')  String? teamBLogo, @JsonKey(name: 'innings_number')  int? inningsNumber, @JsonKey(name: 'total_runs')  int? totalRuns, @JsonKey(name: 'total_wickets')  int? totalWickets, @JsonKey(name: 'legal_ball_count')  int? legalBallCount,  int? target, @JsonKey(name: 'batting_team_id')  String? battingTeamId)?  $default,) {final _that = this;
switch (_that) {
case _MatchResultDto() when $default != null:
return $default(_that.matchId,_that.status,_that.venue,_that.tournamentName,_that.scheduledStartTime,_that.actualStartTime,_that.teamAId,_that.teamAName,_that.teamAColors,_that.teamALogo,_that.teamBId,_that.teamBName,_that.teamBColors,_that.teamBLogo,_that.inningsNumber,_that.totalRuns,_that.totalWickets,_that.legalBallCount,_that.target,_that.battingTeamId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchResultDto extends MatchResultDto {
  const _MatchResultDto({@JsonKey(name: 'match_id') required this.matchId, required this.status, this.venue, @JsonKey(name: 'tournament_name') this.tournamentName, @JsonKey(name: 'scheduled_start_time') this.scheduledStartTime, @JsonKey(name: 'actual_start_time') this.actualStartTime, @JsonKey(name: 'team_a_id') this.teamAId, @JsonKey(name: 'team_a_name') this.teamAName, @JsonKey(name: 'team_a_colors') final  Map<String, dynamic>? teamAColors, @JsonKey(name: 'team_a_logo') this.teamALogo, @JsonKey(name: 'team_b_id') this.teamBId, @JsonKey(name: 'team_b_name') this.teamBName, @JsonKey(name: 'team_b_colors') final  Map<String, dynamic>? teamBColors, @JsonKey(name: 'team_b_logo') this.teamBLogo, @JsonKey(name: 'innings_number') this.inningsNumber, @JsonKey(name: 'total_runs') this.totalRuns, @JsonKey(name: 'total_wickets') this.totalWickets, @JsonKey(name: 'legal_ball_count') this.legalBallCount, this.target, @JsonKey(name: 'batting_team_id') this.battingTeamId}): _teamAColors = teamAColors,_teamBColors = teamBColors,super._();
  factory _MatchResultDto.fromJson(Map<String, dynamic> json) => _$MatchResultDtoFromJson(json);

@override@JsonKey(name: 'match_id') final  String matchId;
@override final  String status;
@override final  String? venue;
@override@JsonKey(name: 'tournament_name') final  String? tournamentName;
@override@JsonKey(name: 'scheduled_start_time') final  String? scheduledStartTime;
@override@JsonKey(name: 'actual_start_time') final  String? actualStartTime;
@override@JsonKey(name: 'team_a_id') final  String? teamAId;
@override@JsonKey(name: 'team_a_name') final  String? teamAName;
 final  Map<String, dynamic>? _teamAColors;
@override@JsonKey(name: 'team_a_colors') Map<String, dynamic>? get teamAColors {
  final value = _teamAColors;
  if (value == null) return null;
  if (_teamAColors is EqualUnmodifiableMapView) return _teamAColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'team_a_logo') final  String? teamALogo;
@override@JsonKey(name: 'team_b_id') final  String? teamBId;
@override@JsonKey(name: 'team_b_name') final  String? teamBName;
 final  Map<String, dynamic>? _teamBColors;
@override@JsonKey(name: 'team_b_colors') Map<String, dynamic>? get teamBColors {
  final value = _teamBColors;
  if (value == null) return null;
  if (_teamBColors is EqualUnmodifiableMapView) return _teamBColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'team_b_logo') final  String? teamBLogo;
@override@JsonKey(name: 'innings_number') final  int? inningsNumber;
@override@JsonKey(name: 'total_runs') final  int? totalRuns;
@override@JsonKey(name: 'total_wickets') final  int? totalWickets;
@override@JsonKey(name: 'legal_ball_count') final  int? legalBallCount;
@override final  int? target;
@override@JsonKey(name: 'batting_team_id') final  String? battingTeamId;

/// Create a copy of MatchResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchResultDtoCopyWith<_MatchResultDto> get copyWith => __$MatchResultDtoCopyWithImpl<_MatchResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchResultDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.status, status) || other.status == status)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.tournamentName, tournamentName) || other.tournamentName == tournamentName)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime)&&(identical(other.actualStartTime, actualStartTime) || other.actualStartTime == actualStartTime)&&(identical(other.teamAId, teamAId) || other.teamAId == teamAId)&&(identical(other.teamAName, teamAName) || other.teamAName == teamAName)&&const DeepCollectionEquality().equals(other._teamAColors, _teamAColors)&&(identical(other.teamALogo, teamALogo) || other.teamALogo == teamALogo)&&(identical(other.teamBId, teamBId) || other.teamBId == teamBId)&&(identical(other.teamBName, teamBName) || other.teamBName == teamBName)&&const DeepCollectionEquality().equals(other._teamBColors, _teamBColors)&&(identical(other.teamBLogo, teamBLogo) || other.teamBLogo == teamBLogo)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalWickets, totalWickets) || other.totalWickets == totalWickets)&&(identical(other.legalBallCount, legalBallCount) || other.legalBallCount == legalBallCount)&&(identical(other.target, target) || other.target == target)&&(identical(other.battingTeamId, battingTeamId) || other.battingTeamId == battingTeamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,matchId,status,venue,tournamentName,scheduledStartTime,actualStartTime,teamAId,teamAName,const DeepCollectionEquality().hash(_teamAColors),teamALogo,teamBId,teamBName,const DeepCollectionEquality().hash(_teamBColors),teamBLogo,inningsNumber,totalRuns,totalWickets,legalBallCount,target,battingTeamId]);

@override
String toString() {
  return 'MatchResultDto(matchId: $matchId, status: $status, venue: $venue, tournamentName: $tournamentName, scheduledStartTime: $scheduledStartTime, actualStartTime: $actualStartTime, teamAId: $teamAId, teamAName: $teamAName, teamAColors: $teamAColors, teamALogo: $teamALogo, teamBId: $teamBId, teamBName: $teamBName, teamBColors: $teamBColors, teamBLogo: $teamBLogo, inningsNumber: $inningsNumber, totalRuns: $totalRuns, totalWickets: $totalWickets, legalBallCount: $legalBallCount, target: $target, battingTeamId: $battingTeamId)';
}


}

/// @nodoc
abstract mixin class _$MatchResultDtoCopyWith<$Res> implements $MatchResultDtoCopyWith<$Res> {
  factory _$MatchResultDtoCopyWith(_MatchResultDto value, $Res Function(_MatchResultDto) _then) = __$MatchResultDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'match_id') String matchId, String status, String? venue,@JsonKey(name: 'tournament_name') String? tournamentName,@JsonKey(name: 'scheduled_start_time') String? scheduledStartTime,@JsonKey(name: 'actual_start_time') String? actualStartTime,@JsonKey(name: 'team_a_id') String? teamAId,@JsonKey(name: 'team_a_name') String? teamAName,@JsonKey(name: 'team_a_colors') Map<String, dynamic>? teamAColors,@JsonKey(name: 'team_a_logo') String? teamALogo,@JsonKey(name: 'team_b_id') String? teamBId,@JsonKey(name: 'team_b_name') String? teamBName,@JsonKey(name: 'team_b_colors') Map<String, dynamic>? teamBColors,@JsonKey(name: 'team_b_logo') String? teamBLogo,@JsonKey(name: 'innings_number') int? inningsNumber,@JsonKey(name: 'total_runs') int? totalRuns,@JsonKey(name: 'total_wickets') int? totalWickets,@JsonKey(name: 'legal_ball_count') int? legalBallCount, int? target,@JsonKey(name: 'batting_team_id') String? battingTeamId
});




}
/// @nodoc
class __$MatchResultDtoCopyWithImpl<$Res>
    implements _$MatchResultDtoCopyWith<$Res> {
  __$MatchResultDtoCopyWithImpl(this._self, this._then);

  final _MatchResultDto _self;
  final $Res Function(_MatchResultDto) _then;

/// Create a copy of MatchResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchId = null,Object? status = null,Object? venue = freezed,Object? tournamentName = freezed,Object? scheduledStartTime = freezed,Object? actualStartTime = freezed,Object? teamAId = freezed,Object? teamAName = freezed,Object? teamAColors = freezed,Object? teamALogo = freezed,Object? teamBId = freezed,Object? teamBName = freezed,Object? teamBColors = freezed,Object? teamBLogo = freezed,Object? inningsNumber = freezed,Object? totalRuns = freezed,Object? totalWickets = freezed,Object? legalBallCount = freezed,Object? target = freezed,Object? battingTeamId = freezed,}) {
  return _then(_MatchResultDto(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String?,tournamentName: freezed == tournamentName ? _self.tournamentName : tournamentName // ignore: cast_nullable_to_non_nullable
as String?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as String?,actualStartTime: freezed == actualStartTime ? _self.actualStartTime : actualStartTime // ignore: cast_nullable_to_non_nullable
as String?,teamAId: freezed == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String?,teamAName: freezed == teamAName ? _self.teamAName : teamAName // ignore: cast_nullable_to_non_nullable
as String?,teamAColors: freezed == teamAColors ? _self._teamAColors : teamAColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,teamALogo: freezed == teamALogo ? _self.teamALogo : teamALogo // ignore: cast_nullable_to_non_nullable
as String?,teamBId: freezed == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String?,teamBName: freezed == teamBName ? _self.teamBName : teamBName // ignore: cast_nullable_to_non_nullable
as String?,teamBColors: freezed == teamBColors ? _self._teamBColors : teamBColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,teamBLogo: freezed == teamBLogo ? _self.teamBLogo : teamBLogo // ignore: cast_nullable_to_non_nullable
as String?,inningsNumber: freezed == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int?,totalRuns: freezed == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int?,totalWickets: freezed == totalWickets ? _self.totalWickets : totalWickets // ignore: cast_nullable_to_non_nullable
as int?,legalBallCount: freezed == legalBallCount ? _self.legalBallCount : legalBallCount // ignore: cast_nullable_to_non_nullable
as int?,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int?,battingTeamId: freezed == battingTeamId ? _self.battingTeamId : battingTeamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
