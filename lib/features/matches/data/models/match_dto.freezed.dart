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

@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'team_a_id') String get teamAId;@JsonKey(name: 'team_b_id') String get teamBId;@JsonKey(name: 'team_a_squad') List<String> get teamASquad;@JsonKey(name: 'team_b_squad') List<String> get teamBSquad;@JsonKey(name: 'team_a_captain') String? get teamACaptain;@JsonKey(name: 'team_b_captain') String? get teamBCaptain;@JsonKey(name: 'team_a_keeper') String? get teamAKeeper;@JsonKey(name: 'team_b_keeper') String? get teamBKeeper; Map<String, dynamic> get format; Map<String, dynamic>? get venue;@JsonKey(name: 'scheduled_start_time') String? get scheduledStartTime; String get status;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of MatchDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchDtoCopyWith<MatchDto> get copyWith => _$MatchDtoCopyWithImpl<MatchDto>(this as MatchDto, _$identity);

  /// Serializes this MatchDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.teamAId, teamAId) || other.teamAId == teamAId)&&(identical(other.teamBId, teamBId) || other.teamBId == teamBId)&&const DeepCollectionEquality().equals(other.teamASquad, teamASquad)&&const DeepCollectionEquality().equals(other.teamBSquad, teamBSquad)&&(identical(other.teamACaptain, teamACaptain) || other.teamACaptain == teamACaptain)&&(identical(other.teamBCaptain, teamBCaptain) || other.teamBCaptain == teamBCaptain)&&(identical(other.teamAKeeper, teamAKeeper) || other.teamAKeeper == teamAKeeper)&&(identical(other.teamBKeeper, teamBKeeper) || other.teamBKeeper == teamBKeeper)&&const DeepCollectionEquality().equals(other.format, format)&&const DeepCollectionEquality().equals(other.venue, venue)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchId,teamAId,teamBId,const DeepCollectionEquality().hash(teamASquad),const DeepCollectionEquality().hash(teamBSquad),teamACaptain,teamBCaptain,teamAKeeper,teamBKeeper,const DeepCollectionEquality().hash(format),const DeepCollectionEquality().hash(venue),scheduledStartTime,status,createdBy,createdAt);

@override
String toString() {
  return 'MatchDto(matchId: $matchId, teamAId: $teamAId, teamBId: $teamBId, teamASquad: $teamASquad, teamBSquad: $teamBSquad, teamACaptain: $teamACaptain, teamBCaptain: $teamBCaptain, teamAKeeper: $teamAKeeper, teamBKeeper: $teamBKeeper, format: $format, venue: $venue, scheduledStartTime: $scheduledStartTime, status: $status, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MatchDtoCopyWith<$Res>  {
  factory $MatchDtoCopyWith(MatchDto value, $Res Function(MatchDto) _then) = _$MatchDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'team_a_id') String teamAId,@JsonKey(name: 'team_b_id') String teamBId,@JsonKey(name: 'team_a_squad') List<String> teamASquad,@JsonKey(name: 'team_b_squad') List<String> teamBSquad,@JsonKey(name: 'team_a_captain') String? teamACaptain,@JsonKey(name: 'team_b_captain') String? teamBCaptain,@JsonKey(name: 'team_a_keeper') String? teamAKeeper,@JsonKey(name: 'team_b_keeper') String? teamBKeeper, Map<String, dynamic> format, Map<String, dynamic>? venue,@JsonKey(name: 'scheduled_start_time') String? scheduledStartTime, String status,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'created_at') String createdAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? matchId = null,Object? teamAId = null,Object? teamBId = null,Object? teamASquad = null,Object? teamBSquad = null,Object? teamACaptain = freezed,Object? teamBCaptain = freezed,Object? teamAKeeper = freezed,Object? teamBKeeper = freezed,Object? format = null,Object? venue = freezed,Object? scheduledStartTime = freezed,Object? status = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,teamAId: null == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String,teamBId: null == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String,teamASquad: null == teamASquad ? _self.teamASquad : teamASquad // ignore: cast_nullable_to_non_nullable
as List<String>,teamBSquad: null == teamBSquad ? _self.teamBSquad : teamBSquad // ignore: cast_nullable_to_non_nullable
as List<String>,teamACaptain: freezed == teamACaptain ? _self.teamACaptain : teamACaptain // ignore: cast_nullable_to_non_nullable
as String?,teamBCaptain: freezed == teamBCaptain ? _self.teamBCaptain : teamBCaptain // ignore: cast_nullable_to_non_nullable
as String?,teamAKeeper: freezed == teamAKeeper ? _self.teamAKeeper : teamAKeeper // ignore: cast_nullable_to_non_nullable
as String?,teamBKeeper: freezed == teamBKeeper ? _self.teamBKeeper : teamBKeeper // ignore: cast_nullable_to_non_nullable
as String?,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_a_id')  String teamAId, @JsonKey(name: 'team_b_id')  String teamBId, @JsonKey(name: 'team_a_squad')  List<String> teamASquad, @JsonKey(name: 'team_b_squad')  List<String> teamBSquad, @JsonKey(name: 'team_a_captain')  String? teamACaptain, @JsonKey(name: 'team_b_captain')  String? teamBCaptain, @JsonKey(name: 'team_a_keeper')  String? teamAKeeper, @JsonKey(name: 'team_b_keeper')  String? teamBKeeper,  Map<String, dynamic> format,  Map<String, dynamic>? venue, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime,  String status, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchDto() when $default != null:
return $default(_that.matchId,_that.teamAId,_that.teamBId,_that.teamASquad,_that.teamBSquad,_that.teamACaptain,_that.teamBCaptain,_that.teamAKeeper,_that.teamBKeeper,_that.format,_that.venue,_that.scheduledStartTime,_that.status,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_a_id')  String teamAId, @JsonKey(name: 'team_b_id')  String teamBId, @JsonKey(name: 'team_a_squad')  List<String> teamASquad, @JsonKey(name: 'team_b_squad')  List<String> teamBSquad, @JsonKey(name: 'team_a_captain')  String? teamACaptain, @JsonKey(name: 'team_b_captain')  String? teamBCaptain, @JsonKey(name: 'team_a_keeper')  String? teamAKeeper, @JsonKey(name: 'team_b_keeper')  String? teamBKeeper,  Map<String, dynamic> format,  Map<String, dynamic>? venue, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime,  String status, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _MatchDto():
return $default(_that.matchId,_that.teamAId,_that.teamBId,_that.teamASquad,_that.teamBSquad,_that.teamACaptain,_that.teamBCaptain,_that.teamAKeeper,_that.teamBKeeper,_that.format,_that.venue,_that.scheduledStartTime,_that.status,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_a_id')  String teamAId, @JsonKey(name: 'team_b_id')  String teamBId, @JsonKey(name: 'team_a_squad')  List<String> teamASquad, @JsonKey(name: 'team_b_squad')  List<String> teamBSquad, @JsonKey(name: 'team_a_captain')  String? teamACaptain, @JsonKey(name: 'team_b_captain')  String? teamBCaptain, @JsonKey(name: 'team_a_keeper')  String? teamAKeeper, @JsonKey(name: 'team_b_keeper')  String? teamBKeeper,  Map<String, dynamic> format,  Map<String, dynamic>? venue, @JsonKey(name: 'scheduled_start_time')  String? scheduledStartTime,  String status, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchDto() when $default != null:
return $default(_that.matchId,_that.teamAId,_that.teamBId,_that.teamASquad,_that.teamBSquad,_that.teamACaptain,_that.teamBCaptain,_that.teamAKeeper,_that.teamBKeeper,_that.format,_that.venue,_that.scheduledStartTime,_that.status,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchDto extends MatchDto {
  const _MatchDto({@JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'team_a_id') required this.teamAId, @JsonKey(name: 'team_b_id') required this.teamBId, @JsonKey(name: 'team_a_squad') final  List<String> teamASquad = const <String>[], @JsonKey(name: 'team_b_squad') final  List<String> teamBSquad = const <String>[], @JsonKey(name: 'team_a_captain') this.teamACaptain, @JsonKey(name: 'team_b_captain') this.teamBCaptain, @JsonKey(name: 'team_a_keeper') this.teamAKeeper, @JsonKey(name: 'team_b_keeper') this.teamBKeeper, required final  Map<String, dynamic> format, final  Map<String, dynamic>? venue, @JsonKey(name: 'scheduled_start_time') this.scheduledStartTime, this.status = 'pending', @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'created_at') required this.createdAt}): _teamASquad = teamASquad,_teamBSquad = teamBSquad,_format = format,_venue = venue,super._();
  factory _MatchDto.fromJson(Map<String, dynamic> json) => _$MatchDtoFromJson(json);

@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'team_a_id') final  String teamAId;
@override@JsonKey(name: 'team_b_id') final  String teamBId;
 final  List<String> _teamASquad;
@override@JsonKey(name: 'team_a_squad') List<String> get teamASquad {
  if (_teamASquad is EqualUnmodifiableListView) return _teamASquad;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teamASquad);
}

 final  List<String> _teamBSquad;
@override@JsonKey(name: 'team_b_squad') List<String> get teamBSquad {
  if (_teamBSquad is EqualUnmodifiableListView) return _teamBSquad;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teamBSquad);
}

@override@JsonKey(name: 'team_a_captain') final  String? teamACaptain;
@override@JsonKey(name: 'team_b_captain') final  String? teamBCaptain;
@override@JsonKey(name: 'team_a_keeper') final  String? teamAKeeper;
@override@JsonKey(name: 'team_b_keeper') final  String? teamBKeeper;
 final  Map<String, dynamic> _format;
@override Map<String, dynamic> get format {
  if (_format is EqualUnmodifiableMapView) return _format;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_format);
}

 final  Map<String, dynamic>? _venue;
@override Map<String, dynamic>? get venue {
  final value = _venue;
  if (value == null) return null;
  if (_venue is EqualUnmodifiableMapView) return _venue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'scheduled_start_time') final  String? scheduledStartTime;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'created_by') final  String createdBy;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.teamAId, teamAId) || other.teamAId == teamAId)&&(identical(other.teamBId, teamBId) || other.teamBId == teamBId)&&const DeepCollectionEquality().equals(other._teamASquad, _teamASquad)&&const DeepCollectionEquality().equals(other._teamBSquad, _teamBSquad)&&(identical(other.teamACaptain, teamACaptain) || other.teamACaptain == teamACaptain)&&(identical(other.teamBCaptain, teamBCaptain) || other.teamBCaptain == teamBCaptain)&&(identical(other.teamAKeeper, teamAKeeper) || other.teamAKeeper == teamAKeeper)&&(identical(other.teamBKeeper, teamBKeeper) || other.teamBKeeper == teamBKeeper)&&const DeepCollectionEquality().equals(other._format, _format)&&const DeepCollectionEquality().equals(other._venue, _venue)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchId,teamAId,teamBId,const DeepCollectionEquality().hash(_teamASquad),const DeepCollectionEquality().hash(_teamBSquad),teamACaptain,teamBCaptain,teamAKeeper,teamBKeeper,const DeepCollectionEquality().hash(_format),const DeepCollectionEquality().hash(_venue),scheduledStartTime,status,createdBy,createdAt);

@override
String toString() {
  return 'MatchDto(matchId: $matchId, teamAId: $teamAId, teamBId: $teamBId, teamASquad: $teamASquad, teamBSquad: $teamBSquad, teamACaptain: $teamACaptain, teamBCaptain: $teamBCaptain, teamAKeeper: $teamAKeeper, teamBKeeper: $teamBKeeper, format: $format, venue: $venue, scheduledStartTime: $scheduledStartTime, status: $status, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MatchDtoCopyWith<$Res> implements $MatchDtoCopyWith<$Res> {
  factory _$MatchDtoCopyWith(_MatchDto value, $Res Function(_MatchDto) _then) = __$MatchDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'team_a_id') String teamAId,@JsonKey(name: 'team_b_id') String teamBId,@JsonKey(name: 'team_a_squad') List<String> teamASquad,@JsonKey(name: 'team_b_squad') List<String> teamBSquad,@JsonKey(name: 'team_a_captain') String? teamACaptain,@JsonKey(name: 'team_b_captain') String? teamBCaptain,@JsonKey(name: 'team_a_keeper') String? teamAKeeper,@JsonKey(name: 'team_b_keeper') String? teamBKeeper, Map<String, dynamic> format, Map<String, dynamic>? venue,@JsonKey(name: 'scheduled_start_time') String? scheduledStartTime, String status,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'created_at') String createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? matchId = null,Object? teamAId = null,Object? teamBId = null,Object? teamASquad = null,Object? teamBSquad = null,Object? teamACaptain = freezed,Object? teamBCaptain = freezed,Object? teamAKeeper = freezed,Object? teamBKeeper = freezed,Object? format = null,Object? venue = freezed,Object? scheduledStartTime = freezed,Object? status = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_MatchDto(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,teamAId: null == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String,teamBId: null == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String,teamASquad: null == teamASquad ? _self._teamASquad : teamASquad // ignore: cast_nullable_to_non_nullable
as List<String>,teamBSquad: null == teamBSquad ? _self._teamBSquad : teamBSquad // ignore: cast_nullable_to_non_nullable
as List<String>,teamACaptain: freezed == teamACaptain ? _self.teamACaptain : teamACaptain // ignore: cast_nullable_to_non_nullable
as String?,teamBCaptain: freezed == teamBCaptain ? _self.teamBCaptain : teamBCaptain // ignore: cast_nullable_to_non_nullable
as String?,teamAKeeper: freezed == teamAKeeper ? _self.teamAKeeper : teamAKeeper // ignore: cast_nullable_to_non_nullable
as String?,teamBKeeper: freezed == teamBKeeper ? _self.teamBKeeper : teamBKeeper // ignore: cast_nullable_to_non_nullable
as String?,format: null == format ? _self._format : format // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,venue: freezed == venue ? _self._venue : venue // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
