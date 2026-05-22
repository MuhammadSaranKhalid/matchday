// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ball_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BallDto {

@JsonKey(name: 'ball_id') String get ballId;@JsonKey(name: 'innings_id') String get inningsId;@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'over_number') int get overNumber;@JsonKey(name: 'ball_number') int get ballNumber;@JsonKey(name: 'legal_ball_number') int get legalBallNumber;@JsonKey(name: 'bowler_id') String get bowlerId;@JsonKey(name: 'striker_id') String get strikerId;@JsonKey(name: 'non_striker_id') String get nonStrikerId;@JsonKey(name: 'runs_scored') int get runsScored;@JsonKey(name: 'extra_runs') int get extraRuns;@JsonKey(name: 'extra_type') String? get extraType;@JsonKey(name: 'total_runs') int get totalRuns;@JsonKey(name: 'is_four') bool get isFour;@JsonKey(name: 'is_six') bool get isSix;@JsonKey(name: 'is_wicket') bool get isWicket;@JsonKey(name: 'wicket_type') String? get wicketType;@JsonKey(name: 'dismissed_player_id') String? get dismissedPlayerId;
/// Create a copy of BallDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BallDtoCopyWith<BallDto> get copyWith => _$BallDtoCopyWithImpl<BallDto>(this as BallDto, _$identity);

  /// Serializes this BallDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BallDto&&(identical(other.ballId, ballId) || other.ballId == ballId)&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.overNumber, overNumber) || other.overNumber == overNumber)&&(identical(other.ballNumber, ballNumber) || other.ballNumber == ballNumber)&&(identical(other.legalBallNumber, legalBallNumber) || other.legalBallNumber == legalBallNumber)&&(identical(other.bowlerId, bowlerId) || other.bowlerId == bowlerId)&&(identical(other.strikerId, strikerId) || other.strikerId == strikerId)&&(identical(other.nonStrikerId, nonStrikerId) || other.nonStrikerId == nonStrikerId)&&(identical(other.runsScored, runsScored) || other.runsScored == runsScored)&&(identical(other.extraRuns, extraRuns) || other.extraRuns == extraRuns)&&(identical(other.extraType, extraType) || other.extraType == extraType)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.isFour, isFour) || other.isFour == isFour)&&(identical(other.isSix, isSix) || other.isSix == isSix)&&(identical(other.isWicket, isWicket) || other.isWicket == isWicket)&&(identical(other.wicketType, wicketType) || other.wicketType == wicketType)&&(identical(other.dismissedPlayerId, dismissedPlayerId) || other.dismissedPlayerId == dismissedPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ballId,inningsId,matchId,overNumber,ballNumber,legalBallNumber,bowlerId,strikerId,nonStrikerId,runsScored,extraRuns,extraType,totalRuns,isFour,isSix,isWicket,wicketType,dismissedPlayerId);

@override
String toString() {
  return 'BallDto(ballId: $ballId, inningsId: $inningsId, matchId: $matchId, overNumber: $overNumber, ballNumber: $ballNumber, legalBallNumber: $legalBallNumber, bowlerId: $bowlerId, strikerId: $strikerId, nonStrikerId: $nonStrikerId, runsScored: $runsScored, extraRuns: $extraRuns, extraType: $extraType, totalRuns: $totalRuns, isFour: $isFour, isSix: $isSix, isWicket: $isWicket, wicketType: $wicketType, dismissedPlayerId: $dismissedPlayerId)';
}


}

/// @nodoc
abstract mixin class $BallDtoCopyWith<$Res>  {
  factory $BallDtoCopyWith(BallDto value, $Res Function(BallDto) _then) = _$BallDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'ball_id') String ballId,@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'over_number') int overNumber,@JsonKey(name: 'ball_number') int ballNumber,@JsonKey(name: 'legal_ball_number') int legalBallNumber,@JsonKey(name: 'bowler_id') String bowlerId,@JsonKey(name: 'striker_id') String strikerId,@JsonKey(name: 'non_striker_id') String nonStrikerId,@JsonKey(name: 'runs_scored') int runsScored,@JsonKey(name: 'extra_runs') int extraRuns,@JsonKey(name: 'extra_type') String? extraType,@JsonKey(name: 'total_runs') int totalRuns,@JsonKey(name: 'is_four') bool isFour,@JsonKey(name: 'is_six') bool isSix,@JsonKey(name: 'is_wicket') bool isWicket,@JsonKey(name: 'wicket_type') String? wicketType,@JsonKey(name: 'dismissed_player_id') String? dismissedPlayerId
});




}
/// @nodoc
class _$BallDtoCopyWithImpl<$Res>
    implements $BallDtoCopyWith<$Res> {
  _$BallDtoCopyWithImpl(this._self, this._then);

  final BallDto _self;
  final $Res Function(BallDto) _then;

/// Create a copy of BallDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ballId = null,Object? inningsId = null,Object? matchId = null,Object? overNumber = null,Object? ballNumber = null,Object? legalBallNumber = null,Object? bowlerId = null,Object? strikerId = null,Object? nonStrikerId = null,Object? runsScored = null,Object? extraRuns = null,Object? extraType = freezed,Object? totalRuns = null,Object? isFour = null,Object? isSix = null,Object? isWicket = null,Object? wicketType = freezed,Object? dismissedPlayerId = freezed,}) {
  return _then(_self.copyWith(
ballId: null == ballId ? _self.ballId : ballId // ignore: cast_nullable_to_non_nullable
as String,inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,overNumber: null == overNumber ? _self.overNumber : overNumber // ignore: cast_nullable_to_non_nullable
as int,ballNumber: null == ballNumber ? _self.ballNumber : ballNumber // ignore: cast_nullable_to_non_nullable
as int,legalBallNumber: null == legalBallNumber ? _self.legalBallNumber : legalBallNumber // ignore: cast_nullable_to_non_nullable
as int,bowlerId: null == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String,strikerId: null == strikerId ? _self.strikerId : strikerId // ignore: cast_nullable_to_non_nullable
as String,nonStrikerId: null == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String,runsScored: null == runsScored ? _self.runsScored : runsScored // ignore: cast_nullable_to_non_nullable
as int,extraRuns: null == extraRuns ? _self.extraRuns : extraRuns // ignore: cast_nullable_to_non_nullable
as int,extraType: freezed == extraType ? _self.extraType : extraType // ignore: cast_nullable_to_non_nullable
as String?,totalRuns: null == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int,isFour: null == isFour ? _self.isFour : isFour // ignore: cast_nullable_to_non_nullable
as bool,isSix: null == isSix ? _self.isSix : isSix // ignore: cast_nullable_to_non_nullable
as bool,isWicket: null == isWicket ? _self.isWicket : isWicket // ignore: cast_nullable_to_non_nullable
as bool,wicketType: freezed == wicketType ? _self.wicketType : wicketType // ignore: cast_nullable_to_non_nullable
as String?,dismissedPlayerId: freezed == dismissedPlayerId ? _self.dismissedPlayerId : dismissedPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BallDto].
extension BallDtoPatterns on BallDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BallDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BallDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BallDto value)  $default,){
final _that = this;
switch (_that) {
case _BallDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BallDto value)?  $default,){
final _that = this;
switch (_that) {
case _BallDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'ball_id')  String ballId, @JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'over_number')  int overNumber, @JsonKey(name: 'ball_number')  int ballNumber, @JsonKey(name: 'legal_ball_number')  int legalBallNumber, @JsonKey(name: 'bowler_id')  String bowlerId, @JsonKey(name: 'striker_id')  String strikerId, @JsonKey(name: 'non_striker_id')  String nonStrikerId, @JsonKey(name: 'runs_scored')  int runsScored, @JsonKey(name: 'extra_runs')  int extraRuns, @JsonKey(name: 'extra_type')  String? extraType, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'is_four')  bool isFour, @JsonKey(name: 'is_six')  bool isSix, @JsonKey(name: 'is_wicket')  bool isWicket, @JsonKey(name: 'wicket_type')  String? wicketType, @JsonKey(name: 'dismissed_player_id')  String? dismissedPlayerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BallDto() when $default != null:
return $default(_that.ballId,_that.inningsId,_that.matchId,_that.overNumber,_that.ballNumber,_that.legalBallNumber,_that.bowlerId,_that.strikerId,_that.nonStrikerId,_that.runsScored,_that.extraRuns,_that.extraType,_that.totalRuns,_that.isFour,_that.isSix,_that.isWicket,_that.wicketType,_that.dismissedPlayerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'ball_id')  String ballId, @JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'over_number')  int overNumber, @JsonKey(name: 'ball_number')  int ballNumber, @JsonKey(name: 'legal_ball_number')  int legalBallNumber, @JsonKey(name: 'bowler_id')  String bowlerId, @JsonKey(name: 'striker_id')  String strikerId, @JsonKey(name: 'non_striker_id')  String nonStrikerId, @JsonKey(name: 'runs_scored')  int runsScored, @JsonKey(name: 'extra_runs')  int extraRuns, @JsonKey(name: 'extra_type')  String? extraType, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'is_four')  bool isFour, @JsonKey(name: 'is_six')  bool isSix, @JsonKey(name: 'is_wicket')  bool isWicket, @JsonKey(name: 'wicket_type')  String? wicketType, @JsonKey(name: 'dismissed_player_id')  String? dismissedPlayerId)  $default,) {final _that = this;
switch (_that) {
case _BallDto():
return $default(_that.ballId,_that.inningsId,_that.matchId,_that.overNumber,_that.ballNumber,_that.legalBallNumber,_that.bowlerId,_that.strikerId,_that.nonStrikerId,_that.runsScored,_that.extraRuns,_that.extraType,_that.totalRuns,_that.isFour,_that.isSix,_that.isWicket,_that.wicketType,_that.dismissedPlayerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'ball_id')  String ballId, @JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'over_number')  int overNumber, @JsonKey(name: 'ball_number')  int ballNumber, @JsonKey(name: 'legal_ball_number')  int legalBallNumber, @JsonKey(name: 'bowler_id')  String bowlerId, @JsonKey(name: 'striker_id')  String strikerId, @JsonKey(name: 'non_striker_id')  String nonStrikerId, @JsonKey(name: 'runs_scored')  int runsScored, @JsonKey(name: 'extra_runs')  int extraRuns, @JsonKey(name: 'extra_type')  String? extraType, @JsonKey(name: 'total_runs')  int totalRuns, @JsonKey(name: 'is_four')  bool isFour, @JsonKey(name: 'is_six')  bool isSix, @JsonKey(name: 'is_wicket')  bool isWicket, @JsonKey(name: 'wicket_type')  String? wicketType, @JsonKey(name: 'dismissed_player_id')  String? dismissedPlayerId)?  $default,) {final _that = this;
switch (_that) {
case _BallDto() when $default != null:
return $default(_that.ballId,_that.inningsId,_that.matchId,_that.overNumber,_that.ballNumber,_that.legalBallNumber,_that.bowlerId,_that.strikerId,_that.nonStrikerId,_that.runsScored,_that.extraRuns,_that.extraType,_that.totalRuns,_that.isFour,_that.isSix,_that.isWicket,_that.wicketType,_that.dismissedPlayerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BallDto extends BallDto {
  const _BallDto({@JsonKey(name: 'ball_id') required this.ballId, @JsonKey(name: 'innings_id') required this.inningsId, @JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'over_number') required this.overNumber, @JsonKey(name: 'ball_number') required this.ballNumber, @JsonKey(name: 'legal_ball_number') required this.legalBallNumber, @JsonKey(name: 'bowler_id') required this.bowlerId, @JsonKey(name: 'striker_id') required this.strikerId, @JsonKey(name: 'non_striker_id') required this.nonStrikerId, @JsonKey(name: 'runs_scored') this.runsScored = 0, @JsonKey(name: 'extra_runs') this.extraRuns = 0, @JsonKey(name: 'extra_type') this.extraType, @JsonKey(name: 'total_runs') this.totalRuns = 0, @JsonKey(name: 'is_four') this.isFour = false, @JsonKey(name: 'is_six') this.isSix = false, @JsonKey(name: 'is_wicket') this.isWicket = false, @JsonKey(name: 'wicket_type') this.wicketType, @JsonKey(name: 'dismissed_player_id') this.dismissedPlayerId}): super._();
  factory _BallDto.fromJson(Map<String, dynamic> json) => _$BallDtoFromJson(json);

@override@JsonKey(name: 'ball_id') final  String ballId;
@override@JsonKey(name: 'innings_id') final  String inningsId;
@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'over_number') final  int overNumber;
@override@JsonKey(name: 'ball_number') final  int ballNumber;
@override@JsonKey(name: 'legal_ball_number') final  int legalBallNumber;
@override@JsonKey(name: 'bowler_id') final  String bowlerId;
@override@JsonKey(name: 'striker_id') final  String strikerId;
@override@JsonKey(name: 'non_striker_id') final  String nonStrikerId;
@override@JsonKey(name: 'runs_scored') final  int runsScored;
@override@JsonKey(name: 'extra_runs') final  int extraRuns;
@override@JsonKey(name: 'extra_type') final  String? extraType;
@override@JsonKey(name: 'total_runs') final  int totalRuns;
@override@JsonKey(name: 'is_four') final  bool isFour;
@override@JsonKey(name: 'is_six') final  bool isSix;
@override@JsonKey(name: 'is_wicket') final  bool isWicket;
@override@JsonKey(name: 'wicket_type') final  String? wicketType;
@override@JsonKey(name: 'dismissed_player_id') final  String? dismissedPlayerId;

/// Create a copy of BallDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BallDtoCopyWith<_BallDto> get copyWith => __$BallDtoCopyWithImpl<_BallDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BallDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BallDto&&(identical(other.ballId, ballId) || other.ballId == ballId)&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.overNumber, overNumber) || other.overNumber == overNumber)&&(identical(other.ballNumber, ballNumber) || other.ballNumber == ballNumber)&&(identical(other.legalBallNumber, legalBallNumber) || other.legalBallNumber == legalBallNumber)&&(identical(other.bowlerId, bowlerId) || other.bowlerId == bowlerId)&&(identical(other.strikerId, strikerId) || other.strikerId == strikerId)&&(identical(other.nonStrikerId, nonStrikerId) || other.nonStrikerId == nonStrikerId)&&(identical(other.runsScored, runsScored) || other.runsScored == runsScored)&&(identical(other.extraRuns, extraRuns) || other.extraRuns == extraRuns)&&(identical(other.extraType, extraType) || other.extraType == extraType)&&(identical(other.totalRuns, totalRuns) || other.totalRuns == totalRuns)&&(identical(other.isFour, isFour) || other.isFour == isFour)&&(identical(other.isSix, isSix) || other.isSix == isSix)&&(identical(other.isWicket, isWicket) || other.isWicket == isWicket)&&(identical(other.wicketType, wicketType) || other.wicketType == wicketType)&&(identical(other.dismissedPlayerId, dismissedPlayerId) || other.dismissedPlayerId == dismissedPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ballId,inningsId,matchId,overNumber,ballNumber,legalBallNumber,bowlerId,strikerId,nonStrikerId,runsScored,extraRuns,extraType,totalRuns,isFour,isSix,isWicket,wicketType,dismissedPlayerId);

@override
String toString() {
  return 'BallDto(ballId: $ballId, inningsId: $inningsId, matchId: $matchId, overNumber: $overNumber, ballNumber: $ballNumber, legalBallNumber: $legalBallNumber, bowlerId: $bowlerId, strikerId: $strikerId, nonStrikerId: $nonStrikerId, runsScored: $runsScored, extraRuns: $extraRuns, extraType: $extraType, totalRuns: $totalRuns, isFour: $isFour, isSix: $isSix, isWicket: $isWicket, wicketType: $wicketType, dismissedPlayerId: $dismissedPlayerId)';
}


}

/// @nodoc
abstract mixin class _$BallDtoCopyWith<$Res> implements $BallDtoCopyWith<$Res> {
  factory _$BallDtoCopyWith(_BallDto value, $Res Function(_BallDto) _then) = __$BallDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'ball_id') String ballId,@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'over_number') int overNumber,@JsonKey(name: 'ball_number') int ballNumber,@JsonKey(name: 'legal_ball_number') int legalBallNumber,@JsonKey(name: 'bowler_id') String bowlerId,@JsonKey(name: 'striker_id') String strikerId,@JsonKey(name: 'non_striker_id') String nonStrikerId,@JsonKey(name: 'runs_scored') int runsScored,@JsonKey(name: 'extra_runs') int extraRuns,@JsonKey(name: 'extra_type') String? extraType,@JsonKey(name: 'total_runs') int totalRuns,@JsonKey(name: 'is_four') bool isFour,@JsonKey(name: 'is_six') bool isSix,@JsonKey(name: 'is_wicket') bool isWicket,@JsonKey(name: 'wicket_type') String? wicketType,@JsonKey(name: 'dismissed_player_id') String? dismissedPlayerId
});




}
/// @nodoc
class __$BallDtoCopyWithImpl<$Res>
    implements _$BallDtoCopyWith<$Res> {
  __$BallDtoCopyWithImpl(this._self, this._then);

  final _BallDto _self;
  final $Res Function(_BallDto) _then;

/// Create a copy of BallDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ballId = null,Object? inningsId = null,Object? matchId = null,Object? overNumber = null,Object? ballNumber = null,Object? legalBallNumber = null,Object? bowlerId = null,Object? strikerId = null,Object? nonStrikerId = null,Object? runsScored = null,Object? extraRuns = null,Object? extraType = freezed,Object? totalRuns = null,Object? isFour = null,Object? isSix = null,Object? isWicket = null,Object? wicketType = freezed,Object? dismissedPlayerId = freezed,}) {
  return _then(_BallDto(
ballId: null == ballId ? _self.ballId : ballId // ignore: cast_nullable_to_non_nullable
as String,inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,overNumber: null == overNumber ? _self.overNumber : overNumber // ignore: cast_nullable_to_non_nullable
as int,ballNumber: null == ballNumber ? _self.ballNumber : ballNumber // ignore: cast_nullable_to_non_nullable
as int,legalBallNumber: null == legalBallNumber ? _self.legalBallNumber : legalBallNumber // ignore: cast_nullable_to_non_nullable
as int,bowlerId: null == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String,strikerId: null == strikerId ? _self.strikerId : strikerId // ignore: cast_nullable_to_non_nullable
as String,nonStrikerId: null == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String,runsScored: null == runsScored ? _self.runsScored : runsScored // ignore: cast_nullable_to_non_nullable
as int,extraRuns: null == extraRuns ? _self.extraRuns : extraRuns // ignore: cast_nullable_to_non_nullable
as int,extraType: freezed == extraType ? _self.extraType : extraType // ignore: cast_nullable_to_non_nullable
as String?,totalRuns: null == totalRuns ? _self.totalRuns : totalRuns // ignore: cast_nullable_to_non_nullable
as int,isFour: null == isFour ? _self.isFour : isFour // ignore: cast_nullable_to_non_nullable
as bool,isSix: null == isSix ? _self.isSix : isSix // ignore: cast_nullable_to_non_nullable
as bool,isWicket: null == isWicket ? _self.isWicket : isWicket // ignore: cast_nullable_to_non_nullable
as bool,wicketType: freezed == wicketType ? _self.wicketType : wicketType // ignore: cast_nullable_to_non_nullable
as String?,dismissedPlayerId: freezed == dismissedPlayerId ? _self.dismissedPlayerId : dismissedPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
