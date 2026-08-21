// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_innings_state_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchInningsStateDto {

@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'innings_number') int get inningsNumber;@JsonKey(name: 'striker_id') String? get strikerId;@JsonKey(name: 'non_striker_id') String? get nonStrikerId;@JsonKey(name: 'bowler_id') String? get bowlerId;@JsonKey(name: 'legal_ball_count') int get legalBallCount;@JsonKey(name: 'total_runs') int get totalRuns;@JsonKey(name: 'total_wickets') int get totalWickets;@JsonKey(name: 'total_extras') int get totalExtras;@JsonKey(name: 'is_declared') bool get isDeclared;@JsonKey(name: 'is_all_out') bool get isAllOut; int? get target;@JsonKey(fromJson: intFromWire) int get version;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of MatchInningsStateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchInningsStateDtoCopyWith<MatchInningsStateDto> get copyWith => _$MatchInningsStateDtoCopyWithImpl<MatchInningsStateDto>(this as MatchInningsStateDto, _$identity);

  /// Serializes this MatchInningsStateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchInningsStateDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.strikerId, strikerId) || other.strikerId == strikerId)&&(identical(other.nonStrikerId, nonStrikerId) || other.nonStrikerId == nonStrikerId)&&(identical(other.bowlerId, bowlerId) || other.bowlerId == bowlerId)&&(identical(other.legalBallCount, legalBallCount) || other.legalBallCount == legalBallCount)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalWickets, totalWickets) || other.totalWickets == totalWickets)&&(identical(other.totalExtras, totalExtras) || other.totalExtras == totalExtras)&&(identical(other.isDeclared, isDeclared) || other.isDeclared == isDeclared)&&(identical(other.isAllOut, isAllOut) || other.isAllOut == isAllOut)&&(identical(other.target, target) || other.target == target)&&(identical(other.version, version) || other.version == version)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchId,inningsNumber,strikerId,nonStrikerId,bowlerId,legalBallCount,totalRuns,totalWickets,totalExtras,isDeclared,isAllOut,target,version,updatedAt);

@override
String toString() {
  return 'MatchInningsStateDto(matchId: $matchId, inningsNumber: $inningsNumber, strikerId: $strikerId, nonStrikerId: $nonStrikerId, bowlerId: $bowlerId, legalBallCount: $legalBallCount, totalRuns: $totalRuns, totalWickets: $totalWickets, totalExtras: $totalExtras, isDeclared: $isDeclared, isAllOut: $isAllOut, target: $target, version: $version, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MatchInningsStateDtoCopyWith<$Res>  {
  factory $MatchInningsStateDtoCopyWith(MatchInningsStateDto value, $Res Function(MatchInningsStateDto) _then) = _$MatchInningsStateDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber,@JsonKey(name: 'striker_id') String? strikerId,@JsonKey(name: 'non_striker_id') String? nonStrikerId,@JsonKey(name: 'bowler_id') String? bowlerId,@JsonKey(name: 'legal_ball_count') int legalBallCount,@JsonKey(name: 'total_runs') int totalRuns,@JsonKey(name: 'total_wickets') int totalWickets,@JsonKey(name: 'total_extras') int totalExtras,@JsonKey(name: 'is_declared') bool isDeclared,@JsonKey(name: 'is_all_out') bool isAllOut, int? target,@JsonKey(fromJson: intFromWire) int version,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$MatchInningsStateDtoCopyWithImpl<$Res>
    implements $MatchInningsStateDtoCopyWith<$Res> {
  _$MatchInningsStateDtoCopyWithImpl(this._self, this._then);

  final MatchInningsStateDto _self;
  final $Res Function(MatchInningsStateDto) _then;

/// Create a copy of MatchInningsStateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchId = null,Object? inningsNumber = null,Object? strikerId = freezed,Object? nonStrikerId = freezed,Object? bowlerId = freezed,Object? legalBallCount = null,Object? totalRuns = null,Object? totalWickets = null,Object? totalExtras = null,Object? isDeclared = null,Object? isAllOut = null,Object? target = freezed,Object? version = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,strikerId: freezed == strikerId ? _self.strikerId : strikerId // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerId: freezed == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,bowlerId: freezed == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String?,legalBallCount: null == legalBallCount ? _self.legalBallCount : legalBallCount // ignore: cast_nullable_to_non_nullable
as int,totalRuns: null == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int,totalWickets: null == totalWickets ? _self.totalWickets : totalWickets // ignore: cast_nullable_to_non_nullable
as int,totalExtras: null == totalExtras ? _self.totalExtras : totalExtras // ignore: cast_nullable_to_non_nullable
as int,isDeclared: null == isDeclared ? _self.isDeclared : isDeclared // ignore: cast_nullable_to_non_nullable
as bool,isAllOut: null == isAllOut ? _self.isAllOut : isAllOut // ignore: cast_nullable_to_non_nullable
as bool,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchInningsStateDto].
extension MatchInningsStateDtoPatterns on MatchInningsStateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchInningsStateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchInningsStateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchInningsStateDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchInningsStateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchInningsStateDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchInningsStateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'striker_id')  String? strikerId, @JsonKey(name: 'non_striker_id')  String? nonStrikerId, @JsonKey(name: 'bowler_id')  String? bowlerId, @JsonKey(name: 'legal_ball_count')  int legalBallCount, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'total_wickets')  int totalWickets, @JsonKey(name: 'total_extras')  int totalExtras, @JsonKey(name: 'is_declared')  bool isDeclared, @JsonKey(name: 'is_all_out')  bool isAllOut,  int? target, @JsonKey(fromJson: intFromWire)  int version, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchInningsStateDto() when $default != null:
return $default(_that.matchId,_that.inningsNumber,_that.strikerId,_that.nonStrikerId,_that.bowlerId,_that.legalBallCount,_that.totalRuns,_that.totalWickets,_that.totalExtras,_that.isDeclared,_that.isAllOut,_that.target,_that.version,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'striker_id')  String? strikerId, @JsonKey(name: 'non_striker_id')  String? nonStrikerId, @JsonKey(name: 'bowler_id')  String? bowlerId, @JsonKey(name: 'legal_ball_count')  int legalBallCount, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'total_wickets')  int totalWickets, @JsonKey(name: 'total_extras')  int totalExtras, @JsonKey(name: 'is_declared')  bool isDeclared, @JsonKey(name: 'is_all_out')  bool isAllOut,  int? target, @JsonKey(fromJson: intFromWire)  int version, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MatchInningsStateDto():
return $default(_that.matchId,_that.inningsNumber,_that.strikerId,_that.nonStrikerId,_that.bowlerId,_that.legalBallCount,_that.totalRuns,_that.totalWickets,_that.totalExtras,_that.isDeclared,_that.isAllOut,_that.target,_that.version,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber, @JsonKey(name: 'striker_id')  String? strikerId, @JsonKey(name: 'non_striker_id')  String? nonStrikerId, @JsonKey(name: 'bowler_id')  String? bowlerId, @JsonKey(name: 'legal_ball_count')  int legalBallCount, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'total_wickets')  int totalWickets, @JsonKey(name: 'total_extras')  int totalExtras, @JsonKey(name: 'is_declared')  bool isDeclared, @JsonKey(name: 'is_all_out')  bool isAllOut,  int? target, @JsonKey(fromJson: intFromWire)  int version, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchInningsStateDto() when $default != null:
return $default(_that.matchId,_that.inningsNumber,_that.strikerId,_that.nonStrikerId,_that.bowlerId,_that.legalBallCount,_that.totalRuns,_that.totalWickets,_that.totalExtras,_that.isDeclared,_that.isAllOut,_that.target,_that.version,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchInningsStateDto extends MatchInningsStateDto {
  const _MatchInningsStateDto({@JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'innings_number') required this.inningsNumber, @JsonKey(name: 'striker_id') this.strikerId, @JsonKey(name: 'non_striker_id') this.nonStrikerId, @JsonKey(name: 'bowler_id') this.bowlerId, @JsonKey(name: 'legal_ball_count') this.legalBallCount = 0, @JsonKey(name: 'total_runs') this.totalRuns = 0, @JsonKey(name: 'total_wickets') this.totalWickets = 0, @JsonKey(name: 'total_extras') this.totalExtras = 0, @JsonKey(name: 'is_declared') this.isDeclared = false, @JsonKey(name: 'is_all_out') this.isAllOut = false, this.target, @JsonKey(fromJson: intFromWire) this.version = 0, @JsonKey(name: 'updated_at') required this.updatedAt}): super._();
  factory _MatchInningsStateDto.fromJson(Map<String, dynamic> json) => _$MatchInningsStateDtoFromJson(json);

@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'innings_number') final  int inningsNumber;
@override@JsonKey(name: 'striker_id') final  String? strikerId;
@override@JsonKey(name: 'non_striker_id') final  String? nonStrikerId;
@override@JsonKey(name: 'bowler_id') final  String? bowlerId;
@override@JsonKey(name: 'legal_ball_count') final  int legalBallCount;
@override@JsonKey(name: 'total_runs') final  int totalRuns;
@override@JsonKey(name: 'total_wickets') final  int totalWickets;
@override@JsonKey(name: 'total_extras') final  int totalExtras;
@override@JsonKey(name: 'is_declared') final  bool isDeclared;
@override@JsonKey(name: 'is_all_out') final  bool isAllOut;
@override final  int? target;
@override@JsonKey(fromJson: intFromWire) final  int version;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of MatchInningsStateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchInningsStateDtoCopyWith<_MatchInningsStateDto> get copyWith => __$MatchInningsStateDtoCopyWithImpl<_MatchInningsStateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchInningsStateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchInningsStateDto&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.strikerId, strikerId) || other.strikerId == strikerId)&&(identical(other.nonStrikerId, nonStrikerId) || other.nonStrikerId == nonStrikerId)&&(identical(other.bowlerId, bowlerId) || other.bowlerId == bowlerId)&&(identical(other.legalBallCount, legalBallCount) || other.legalBallCount == legalBallCount)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.totalWickets, totalWickets) || other.totalWickets == totalWickets)&&(identical(other.totalExtras, totalExtras) || other.totalExtras == totalExtras)&&(identical(other.isDeclared, isDeclared) || other.isDeclared == isDeclared)&&(identical(other.isAllOut, isAllOut) || other.isAllOut == isAllOut)&&(identical(other.target, target) || other.target == target)&&(identical(other.version, version) || other.version == version)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchId,inningsNumber,strikerId,nonStrikerId,bowlerId,legalBallCount,totalRuns,totalWickets,totalExtras,isDeclared,isAllOut,target,version,updatedAt);

@override
String toString() {
  return 'MatchInningsStateDto(matchId: $matchId, inningsNumber: $inningsNumber, strikerId: $strikerId, nonStrikerId: $nonStrikerId, bowlerId: $bowlerId, legalBallCount: $legalBallCount, totalRuns: $totalRuns, totalWickets: $totalWickets, totalExtras: $totalExtras, isDeclared: $isDeclared, isAllOut: $isAllOut, target: $target, version: $version, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MatchInningsStateDtoCopyWith<$Res> implements $MatchInningsStateDtoCopyWith<$Res> {
  factory _$MatchInningsStateDtoCopyWith(_MatchInningsStateDto value, $Res Function(_MatchInningsStateDto) _then) = __$MatchInningsStateDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber,@JsonKey(name: 'striker_id') String? strikerId,@JsonKey(name: 'non_striker_id') String? nonStrikerId,@JsonKey(name: 'bowler_id') String? bowlerId,@JsonKey(name: 'legal_ball_count') int legalBallCount,@JsonKey(name: 'total_runs') int totalRuns,@JsonKey(name: 'total_wickets') int totalWickets,@JsonKey(name: 'total_extras') int totalExtras,@JsonKey(name: 'is_declared') bool isDeclared,@JsonKey(name: 'is_all_out') bool isAllOut, int? target,@JsonKey(fromJson: intFromWire) int version,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$MatchInningsStateDtoCopyWithImpl<$Res>
    implements _$MatchInningsStateDtoCopyWith<$Res> {
  __$MatchInningsStateDtoCopyWithImpl(this._self, this._then);

  final _MatchInningsStateDto _self;
  final $Res Function(_MatchInningsStateDto) _then;

/// Create a copy of MatchInningsStateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchId = null,Object? inningsNumber = null,Object? strikerId = freezed,Object? nonStrikerId = freezed,Object? bowlerId = freezed,Object? legalBallCount = null,Object? totalRuns = null,Object? totalWickets = null,Object? totalExtras = null,Object? isDeclared = null,Object? isAllOut = null,Object? target = freezed,Object? version = null,Object? updatedAt = null,}) {
  return _then(_MatchInningsStateDto(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,strikerId: freezed == strikerId ? _self.strikerId : strikerId // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerId: freezed == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,bowlerId: freezed == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String?,legalBallCount: null == legalBallCount ? _self.legalBallCount : legalBallCount // ignore: cast_nullable_to_non_nullable
as int,totalRuns: null == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int,totalWickets: null == totalWickets ? _self.totalWickets : totalWickets // ignore: cast_nullable_to_non_nullable
as int,totalExtras: null == totalExtras ? _self.totalExtras : totalExtras // ignore: cast_nullable_to_non_nullable
as int,isDeclared: null == isDeclared ? _self.isDeclared : isDeclared // ignore: cast_nullable_to_non_nullable
as bool,isAllOut: null == isAllOut ? _self.isAllOut : isAllOut // ignore: cast_nullable_to_non_nullable
as bool,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
