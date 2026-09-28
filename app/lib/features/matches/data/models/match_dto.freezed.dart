// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchDto {

@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'team_a_id') String get teamAId;@JsonKey(name: 'team_b_id') String get teamBId;@JsonKey(name: 'team_a_captain') String? get teamACaptain;@JsonKey(name: 'team_b_captain') String? get teamBCaptain;@JsonKey(name: 'setup_team_id') String? get setupTeamId; Map<String, dynamic> get format;@JsonKey(name: 'format_code') String? get formatCode; String? get venue;@JsonKey(name: 'scheduled_start_time') String? get scheduledStartTime;@JsonKey(name: 'actual_start_time') String? get actualStartTime; Map<String, dynamic>? get result; String get status;@JsonKey(name: 'match_type') String get matchType;@JsonKey(name: 'toss_won_by') String? get tossWonBy;@JsonKey(name: 'toss_decision') String? get tossDecision;@JsonKey(name: 'toss_face') String? get tossFace;@JsonKey(name: 'toss_recorded_by') String? get tossRecordedBy;@JsonKey(name: 'start_phase') String get startPhase;@JsonKey(name: 'openers_submitted_by') String? get openersSubmittedBy;@JsonKey(name: 'openers_submitted_at') String? get openersSubmittedAt;@JsonKey(name: 'created_by') String? get createdBy;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of MatchDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchDtoCopyWith<MatchDto> get copyWith => _$MatchDtoCopyWithImpl<MatchDto>(this as MatchDto, _$identity);

  /// Serializes this MatchDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.teamAId, teamAId) || other.teamAId == teamAId)&&(identical(other.teamBId, teamBId) || other.teamBId == teamBId)&&(identical(other.teamACaptain, teamACaptain) || other.teamACaptain == teamACaptain)&&(identical(other.teamBCaptain, teamBCaptain) || other.teamBCaptain == teamBCaptain)&&(identical(other.setupTeamId, setupTeamId) || other.setupTeamId == setupTeamId)&&const DeepCollectionEquality().equals(other.format, format)&&(identical(other.formatCode, formatCode) || other.formatCode == formatCode)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime)&&(identical(other.actualStartTime, actualStartTime) || other.actualStartTime == actualStartTime)&&const DeepCollectionEquality().equals(other.result, result)&&(identical(other.status, status) || other.status == status)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.tossWonBy, tossWonBy) || other.tossWonBy == tossWonBy)&&(identical(other.tossDecision, tossDecision) || other.tossDecision == tossDecision)&&(identical(other.tossFace, tossFace) || other.tossFace == tossFace)&&(identical(other.tossRecordedBy, tossRecordedBy) || other.tossRecordedBy == tossRecordedBy)&&(identical(other.startPhase, startPhase) || other.startPhase == startPhase)&&(identical(other.openersSubmittedBy, openersSubmittedBy) || other.openersSubmittedBy == openersSubmittedBy)&&(identical(other.openersSubmittedAt, openersSubmittedAt) || other.openersSubmittedAt == openersSubmittedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,matchId,teamAId,teamBId,teamACaptain,teamBCaptain,setupTeamId,const DeepCollectionEquality().hash(format),formatCode,venue,scheduledStartTime,actualStartTime,const DeepCollectionEquality().hash(result),status,matchType,tossWonBy,tossDecision,tossFace,tossRecordedBy,startPhase,openersSubmittedBy,openersSubmittedAt,createdBy,createdAt]);

@override
String toString() {
  return 'MatchDto(matchId: $matchId, teamAId: $teamAId, teamBId: $teamBId, teamACaptain: $teamACaptain, teamBCaptain: $teamBCaptain, setupTeamId: $setupTeamId, format: $format, formatCode: $formatCode, venue: $venue, scheduledStartTime: $scheduledStartTime, actualStartTime: $actualStartTime, result: $result, status: $status, matchType: $matchType, tossWonBy: $tossWonBy, tossDecision: $tossDecision, tossFace: $tossFace, tossRecordedBy: $tossRecordedBy, startPhase: $startPhase, openersSubmittedBy: $openersSubmittedBy, openersSubmittedAt: $openersSubmittedAt, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MatchDtoCopyWith<$Res>  {
  factory $MatchDtoCopyWith(MatchDto value, $Res Function(MatchDto) _then) = _$MatchDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'team_a_id') String teamAId,@JsonKey(name: 'team_b_id') String teamBId,@JsonKey(name: 'team_a_captain') String? teamACaptain,@JsonKey(name: 'team_b_captain') String? teamBCaptain,@JsonKey(name: 'setup_team_id') String? setupTeamId, Map<String, dynamic> format,@JsonKey(name: 'format_code') String? formatCode, String? venue,@JsonKey(name: 'scheduled_start_time') String? scheduledStartTime,@JsonKey(name: 'actual_start_time') String? actualStartTime, Map<String, dynamic>? result, String status,@JsonKey(name: 'match_type') String matchType,@JsonKey(name: 'toss_won_by') String? tossWonBy,@JsonKey(name: 'toss_decision') String? tossDecision,@JsonKey(name: 'toss_face') String? tossFace,@JsonKey(name: 'toss_recorded_by') String? tossRecordedBy,@JsonKey(name: 'start_phase') String startPhase,@JsonKey(name: 'openers_submitted_by') String? openersSubmittedBy,@JsonKey(name: 'openers_submitted_at') String? openersSubmittedAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$MatchDtoCopyWithImpl<$Res>
    implements $MatchDtoCopyWith<$Res> {
  _$MatchDtoCopyWithImpl(this._self, this._then);

  final MatchDto _self;
  final $Res Function(MatchDto) _then;

/// Create a copy of MatchDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchId = null,Object? teamAId = null,Object? teamBId = null,Object? teamACaptain = freezed,Object? teamBCaptain = freezed,Object? setupTeamId = freezed,Object? format = null,Object? formatCode = freezed,Object? venue = freezed,Object? scheduledStartTime = freezed,Object? actualStartTime = freezed,Object? result = freezed,Object? status = null,Object? matchType = null,Object? tossWonBy = freezed,Object? tossDecision = freezed,Object? tossFace = freezed,Object? tossRecordedBy = freezed,Object? startPhase = null,Object? openersSubmittedBy = freezed,Object? openersSubmittedAt = freezed,Object? createdBy = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,teamAId: null == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String,teamBId: null == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String,teamACaptain: freezed == teamACaptain ? _self.teamACaptain : teamACaptain // ignore: cast_nullable_to_non_nullable
as String?,teamBCaptain: freezed == teamBCaptain ? _self.teamBCaptain : teamBCaptain // ignore: cast_nullable_to_non_nullable
as String?,setupTeamId: freezed == setupTeamId ? _self.setupTeamId : setupTeamId // ignore: cast_nullable_to_non_nullable
as String?,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,formatCode: freezed == formatCode ? _self.formatCode : formatCode // ignore: cast_nullable_to_non_nullable
as String?,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as String?,actualStartTime: freezed == actualStartTime ? _self.actualStartTime : actualStartTime // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,tossWonBy: freezed == tossWonBy ? _self.tossWonBy : tossWonBy // ignore: cast_nullable_to_non_nullable
as String?,tossDecision: freezed == tossDecision ? _self.tossDecision : tossDecision // ignore: cast_nullable_to_non_nullable
as String?,tossFace: freezed == tossFace ? _self.tossFace : tossFace // ignore: cast_nullable_to_non_nullable
as String?,tossRecordedBy: freezed == tossRecordedBy ? _self.tossRecordedBy : tossRecordedBy // ignore: cast_nullable_to_non_nullable
as String?,startPhase: null == startPhase ? _self.startPhase : startPhase // ignore: cast_nullable_to_non_nullable
as String,openersSubmittedBy: freezed == openersSubmittedBy ? _self.openersSubmittedBy : openersSubmittedBy // ignore: cast_nullable_to_non_nullable
as String?,openersSubmittedAt: freezed == openersSubmittedAt ? _self.openersSubmittedAt : openersSubmittedAt // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchDto].
extension MatchDtoPatterns on MatchDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_a_id')  String teamAId, @JsonKey(name: 'team_b_id')  String teamBId, @JsonKey(name: 'team_a_captain')  String? teamACaptain, @JsonKey(name: 'team_b_captain')  String? teamBCaptain, @JsonKey(name: 'setup_team_id')  String? setupTeamId,  Map<String, dynamic> format, @JsonKey(name: 'format_code')  String? formatCode,  String? venue, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime, @JsonKey(name: 'actual_start_time')  String? actualStartTime,  Map<String, dynamic>? result,  String status, @JsonKey(name: 'match_type')  String matchType, @JsonKey(name: 'toss_won_by')  String? tossWonBy, @JsonKey(name: 'toss_decision')  String? tossDecision, @JsonKey(name: 'toss_face')  String? tossFace, @JsonKey(name: 'toss_recorded_by')  String? tossRecordedBy, @JsonKey(name: 'start_phase')  String startPhase, @JsonKey(name: 'openers_submitted_by')  String? openersSubmittedBy, @JsonKey(name: 'openers_submitted_at')  String? openersSubmittedAt, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchDto() when $default != null:
return $default(_that.matchId,_that.teamAId,_that.teamBId,_that.teamACaptain,_that.teamBCaptain,_that.setupTeamId,_that.format,_that.formatCode,_that.venue,_that.scheduledStartTime,_that.actualStartTime,_that.result,_that.status,_that.matchType,_that.tossWonBy,_that.tossDecision,_that.tossFace,_that.tossRecordedBy,_that.startPhase,_that.openersSubmittedBy,_that.openersSubmittedAt,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_a_id')  String teamAId, @JsonKey(name: 'team_b_id')  String teamBId, @JsonKey(name: 'team_a_captain')  String? teamACaptain, @JsonKey(name: 'team_b_captain')  String? teamBCaptain, @JsonKey(name: 'setup_team_id')  String? setupTeamId,  Map<String, dynamic> format, @JsonKey(name: 'format_code')  String? formatCode,  String? venue, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime, @JsonKey(name: 'actual_start_time')  String? actualStartTime,  Map<String, dynamic>? result,  String status, @JsonKey(name: 'match_type')  String matchType, @JsonKey(name: 'toss_won_by')  String? tossWonBy, @JsonKey(name: 'toss_decision')  String? tossDecision, @JsonKey(name: 'toss_face')  String? tossFace, @JsonKey(name: 'toss_recorded_by')  String? tossRecordedBy, @JsonKey(name: 'start_phase')  String startPhase, @JsonKey(name: 'openers_submitted_by')  String? openersSubmittedBy, @JsonKey(name: 'openers_submitted_at')  String? openersSubmittedAt, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _MatchDto():
return $default(_that.matchId,_that.teamAId,_that.teamBId,_that.teamACaptain,_that.teamBCaptain,_that.setupTeamId,_that.format,_that.formatCode,_that.venue,_that.scheduledStartTime,_that.actualStartTime,_that.result,_that.status,_that.matchType,_that.tossWonBy,_that.tossDecision,_that.tossFace,_that.tossRecordedBy,_that.startPhase,_that.openersSubmittedBy,_that.openersSubmittedAt,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_a_id')  String teamAId, @JsonKey(name: 'team_b_id')  String teamBId, @JsonKey(name: 'team_a_captain')  String? teamACaptain, @JsonKey(name: 'team_b_captain')  String? teamBCaptain, @JsonKey(name: 'setup_team_id')  String? setupTeamId,  Map<String, dynamic> format, @JsonKey(name: 'format_code')  String? formatCode,  String? venue, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime, @JsonKey(name: 'actual_start_time')  String? actualStartTime,  Map<String, dynamic>? result,  String status, @JsonKey(name: 'match_type')  String matchType, @JsonKey(name: 'toss_won_by')  String? tossWonBy, @JsonKey(name: 'toss_decision')  String? tossDecision, @JsonKey(name: 'toss_face')  String? tossFace, @JsonKey(name: 'toss_recorded_by')  String? tossRecordedBy, @JsonKey(name: 'start_phase')  String startPhase, @JsonKey(name: 'openers_submitted_by')  String? openersSubmittedBy, @JsonKey(name: 'openers_submitted_at')  String? openersSubmittedAt, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchDto() when $default != null:
return $default(_that.matchId,_that.teamAId,_that.teamBId,_that.teamACaptain,_that.teamBCaptain,_that.setupTeamId,_that.format,_that.formatCode,_that.venue,_that.scheduledStartTime,_that.actualStartTime,_that.result,_that.status,_that.matchType,_that.tossWonBy,_that.tossDecision,_that.tossFace,_that.tossRecordedBy,_that.startPhase,_that.openersSubmittedBy,_that.openersSubmittedAt,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchDto extends MatchDto {
  const _MatchDto({@JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'team_a_id') required this.teamAId, @JsonKey(name: 'team_b_id') required this.teamBId, @JsonKey(name: 'team_a_captain') this.teamACaptain, @JsonKey(name: 'team_b_captain') this.teamBCaptain, @JsonKey(name: 'setup_team_id') this.setupTeamId, required final  Map<String, dynamic> format, @JsonKey(name: 'format_code') this.formatCode, this.venue, @JsonKey(name: 'scheduled_start_time') this.scheduledStartTime, @JsonKey(name: 'actual_start_time') this.actualStartTime, final  Map<String, dynamic>? result, this.status = 'scheduled', @JsonKey(name: 'match_type') this.matchType = 'friendly', @JsonKey(name: 'toss_won_by') this.tossWonBy, @JsonKey(name: 'toss_decision') this.tossDecision, @JsonKey(name: 'toss_face') this.tossFace, @JsonKey(name: 'toss_recorded_by') this.tossRecordedBy, @JsonKey(name: 'start_phase') this.startPhase = 'toss', @JsonKey(name: 'openers_submitted_by') this.openersSubmittedBy, @JsonKey(name: 'openers_submitted_at') this.openersSubmittedAt, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'created_at') required this.createdAt}): _format = format,_result = result,super._();
  factory _MatchDto.fromJson(Map<String, dynamic> json) => _$MatchDtoFromJson(json);

@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'team_a_id') final  String teamAId;
@override@JsonKey(name: 'team_b_id') final  String teamBId;
@override@JsonKey(name: 'team_a_captain') final  String? teamACaptain;
@override@JsonKey(name: 'team_b_captain') final  String? teamBCaptain;
@override@JsonKey(name: 'setup_team_id') final  String? setupTeamId;
 final  Map<String, dynamic> _format;
@override Map<String, dynamic> get format {
  if (_format is EqualUnmodifiableMapView) return _format;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_format);
}

@override@JsonKey(name: 'format_code') final  String? formatCode;
@override final  String? venue;
@override@JsonKey(name: 'scheduled_start_time') final  String? scheduledStartTime;
@override@JsonKey(name: 'actual_start_time') final  String? actualStartTime;
 final  Map<String, dynamic>? _result;
@override Map<String, dynamic>? get result {
  final value = _result;
  if (value == null) return null;
  if (_result is EqualUnmodifiableMapView) return _result;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  String status;
@override@JsonKey(name: 'match_type') final  String matchType;
@override@JsonKey(name: 'toss_won_by') final  String? tossWonBy;
@override@JsonKey(name: 'toss_decision') final  String? tossDecision;
@override@JsonKey(name: 'toss_face') final  String? tossFace;
@override@JsonKey(name: 'toss_recorded_by') final  String? tossRecordedBy;
@override@JsonKey(name: 'start_phase') final  String startPhase;
@override@JsonKey(name: 'openers_submitted_by') final  String? openersSubmittedBy;
@override@JsonKey(name: 'openers_submitted_at') final  String? openersSubmittedAt;
@override@JsonKey(name: 'created_by') final  String? createdBy;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of MatchDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchDtoCopyWith<_MatchDto> get copyWith => __$MatchDtoCopyWithImpl<_MatchDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.teamAId, teamAId) || other.teamAId == teamAId)&&(identical(other.teamBId, teamBId) || other.teamBId == teamBId)&&(identical(other.teamACaptain, teamACaptain) || other.teamACaptain == teamACaptain)&&(identical(other.teamBCaptain, teamBCaptain) || other.teamBCaptain == teamBCaptain)&&(identical(other.setupTeamId, setupTeamId) || other.setupTeamId == setupTeamId)&&const DeepCollectionEquality().equals(other._format, _format)&&(identical(other.formatCode, formatCode) || other.formatCode == formatCode)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime)&&(identical(other.actualStartTime, actualStartTime) || other.actualStartTime == actualStartTime)&&const DeepCollectionEquality().equals(other._result, _result)&&(identical(other.status, status) || other.status == status)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.tossWonBy, tossWonBy) || other.tossWonBy == tossWonBy)&&(identical(other.tossDecision, tossDecision) || other.tossDecision == tossDecision)&&(identical(other.tossFace, tossFace) || other.tossFace == tossFace)&&(identical(other.tossRecordedBy, tossRecordedBy) || other.tossRecordedBy == tossRecordedBy)&&(identical(other.startPhase, startPhase) || other.startPhase == startPhase)&&(identical(other.openersSubmittedBy, openersSubmittedBy) || other.openersSubmittedBy == openersSubmittedBy)&&(identical(other.openersSubmittedAt, openersSubmittedAt) || other.openersSubmittedAt == openersSubmittedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,matchId,teamAId,teamBId,teamACaptain,teamBCaptain,setupTeamId,const DeepCollectionEquality().hash(_format),formatCode,venue,scheduledStartTime,actualStartTime,const DeepCollectionEquality().hash(_result),status,matchType,tossWonBy,tossDecision,tossFace,tossRecordedBy,startPhase,openersSubmittedBy,openersSubmittedAt,createdBy,createdAt]);

@override
String toString() {
  return 'MatchDto(matchId: $matchId, teamAId: $teamAId, teamBId: $teamBId, teamACaptain: $teamACaptain, teamBCaptain: $teamBCaptain, setupTeamId: $setupTeamId, format: $format, formatCode: $formatCode, venue: $venue, scheduledStartTime: $scheduledStartTime, actualStartTime: $actualStartTime, result: $result, status: $status, matchType: $matchType, tossWonBy: $tossWonBy, tossDecision: $tossDecision, tossFace: $tossFace, tossRecordedBy: $tossRecordedBy, startPhase: $startPhase, openersSubmittedBy: $openersSubmittedBy, openersSubmittedAt: $openersSubmittedAt, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MatchDtoCopyWith<$Res> implements $MatchDtoCopyWith<$Res> {
  factory _$MatchDtoCopyWith(_MatchDto value, $Res Function(_MatchDto) _then) = __$MatchDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'team_a_id') String teamAId,@JsonKey(name: 'team_b_id') String teamBId,@JsonKey(name: 'team_a_captain') String? teamACaptain,@JsonKey(name: 'team_b_captain') String? teamBCaptain,@JsonKey(name: 'setup_team_id') String? setupTeamId, Map<String, dynamic> format,@JsonKey(name: 'format_code') String? formatCode, String? venue,@JsonKey(name: 'scheduled_start_time') String? scheduledStartTime,@JsonKey(name: 'actual_start_time') String? actualStartTime, Map<String, dynamic>? result, String status,@JsonKey(name: 'match_type') String matchType,@JsonKey(name: 'toss_won_by') String? tossWonBy,@JsonKey(name: 'toss_decision') String? tossDecision,@JsonKey(name: 'toss_face') String? tossFace,@JsonKey(name: 'toss_recorded_by') String? tossRecordedBy,@JsonKey(name: 'start_phase') String startPhase,@JsonKey(name: 'openers_submitted_by') String? openersSubmittedBy,@JsonKey(name: 'openers_submitted_at') String? openersSubmittedAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$MatchDtoCopyWithImpl<$Res>
    implements _$MatchDtoCopyWith<$Res> {
  __$MatchDtoCopyWithImpl(this._self, this._then);

  final _MatchDto _self;
  final $Res Function(_MatchDto) _then;

/// Create a copy of MatchDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchId = null,Object? teamAId = null,Object? teamBId = null,Object? teamACaptain = freezed,Object? teamBCaptain = freezed,Object? setupTeamId = freezed,Object? format = null,Object? formatCode = freezed,Object? venue = freezed,Object? scheduledStartTime = freezed,Object? actualStartTime = freezed,Object? result = freezed,Object? status = null,Object? matchType = null,Object? tossWonBy = freezed,Object? tossDecision = freezed,Object? tossFace = freezed,Object? tossRecordedBy = freezed,Object? startPhase = null,Object? openersSubmittedBy = freezed,Object? openersSubmittedAt = freezed,Object? createdBy = freezed,Object? createdAt = null,}) {
  return _then(_MatchDto(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,teamAId: null == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String,teamBId: null == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String,teamACaptain: freezed == teamACaptain ? _self.teamACaptain : teamACaptain // ignore: cast_nullable_to_non_nullable
as String?,teamBCaptain: freezed == teamBCaptain ? _self.teamBCaptain : teamBCaptain // ignore: cast_nullable_to_non_nullable
as String?,setupTeamId: freezed == setupTeamId ? _self.setupTeamId : setupTeamId // ignore: cast_nullable_to_non_nullable
as String?,format: null == format ? _self._format : format // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,formatCode: freezed == formatCode ? _self.formatCode : formatCode // ignore: cast_nullable_to_non_nullable
as String?,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as String?,actualStartTime: freezed == actualStartTime ? _self.actualStartTime : actualStartTime // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self._result : result // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,tossWonBy: freezed == tossWonBy ? _self.tossWonBy : tossWonBy // ignore: cast_nullable_to_non_nullable
as String?,tossDecision: freezed == tossDecision ? _self.tossDecision : tossDecision // ignore: cast_nullable_to_non_nullable
as String?,tossFace: freezed == tossFace ? _self.tossFace : tossFace // ignore: cast_nullable_to_non_nullable
as String?,tossRecordedBy: freezed == tossRecordedBy ? _self.tossRecordedBy : tossRecordedBy // ignore: cast_nullable_to_non_nullable
as String?,startPhase: null == startPhase ? _self.startPhase : startPhase // ignore: cast_nullable_to_non_nullable
as String,openersSubmittedBy: freezed == openersSubmittedBy ? _self.openersSubmittedBy : openersSubmittedBy // ignore: cast_nullable_to_non_nullable
as String?,openersSubmittedAt: freezed == openersSubmittedAt ? _self.openersSubmittedAt : openersSubmittedAt // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
