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

@JsonKey(name: 'ball_id') String get ballId;@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'innings_number') int get inningsNumber; int get seq;@JsonKey(name: 'over_number') int get overNumber;@JsonKey(name: 'ball_in_over') int get ballInOver;@JsonKey(name: 'is_legal_delivery') bool get isLegalDelivery;@JsonKey(name: 'ball_type') String get ballType;@JsonKey(name: 'runs_scored') int get runsScored; int get extras;@JsonKey(name: 'is_wicket') bool get isWicket;@JsonKey(name: 'wicket_type') String? get wicketType;@JsonKey(name: 'is_free_hit') bool get isFreeHit;@JsonKey(name: 'batsman_id') String? get batsmanId;@JsonKey(name: 'non_striker_id') String? get nonStrikerId;@JsonKey(name: 'bowler_id') String? get bowlerId;@JsonKey(name: 'fielder_id') String? get fielderId; String? get commentary;
/// Create a copy of BallDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BallDtoCopyWith<BallDto> get copyWith => _$BallDtoCopyWithImpl<BallDto>(this as BallDto, _$identity);

  /// Serializes this BallDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BallDto&&(identical(other.ballId, ballId) || other.ballId == ballId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.overNumber, overNumber) || other.overNumber == overNumber)&&(identical(other.ballInOver, ballInOver) || other.ballInOver == ballInOver)&&(identical(other.isLegalDelivery, isLegalDelivery) || other.isLegalDelivery == isLegalDelivery)&&(identical(other.ballType, ballType) || other.ballType == ballType)&&(identical(other.runsScored, runsScored) || other.runsScored == runsScored)&&(identical(other.extras, extras) || other.extras == extras)&&(identical(other.isWicket, isWicket) || other.isWicket == isWicket)&&(identical(other.wicketType, wicketType) || other.wicketType == wicketType)&&(identical(other.isFreeHit, isFreeHit) || other.isFreeHit == isFreeHit)&&(identical(other.batsmanId, batsmanId) || other.batsmanId == batsmanId)&&(identical(other.nonStrikerId, nonStrikerId) || other.nonStrikerId == nonStrikerId)&&(identical(other.bowlerId, bowlerId) || other.bowlerId == bowlerId)&&(identical(other.fielderId, fielderId) || other.fielderId == fielderId)&&(identical(other.commentary, commentary) || other.commentary == commentary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ballId,matchId,inningsNumber,seq,overNumber,ballInOver,isLegalDelivery,ballType,runsScored,extras,isWicket,wicketType,isFreeHit,batsmanId,nonStrikerId,bowlerId,fielderId,commentary);

@override
String toString() {
  return 'BallDto(ballId: $ballId, matchId: $matchId, inningsNumber: $inningsNumber, seq: $seq, overNumber: $overNumber, ballInOver: $ballInOver, isLegalDelivery: $isLegalDelivery, ballType: $ballType, runsScored: $runsScored, extras: $extras, isWicket: $isWicket, wicketType: $wicketType, isFreeHit: $isFreeHit, batsmanId: $batsmanId, nonStrikerId: $nonStrikerId, bowlerId: $bowlerId, fielderId: $fielderId, commentary: $commentary)';
}


}

/// @nodoc
abstract mixin class $BallDtoCopyWith<$Res>  {
  factory $BallDtoCopyWith(BallDto value, $Res Function(BallDto) _then) = _$BallDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'ball_id') String ballId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber, int seq,@JsonKey(name: 'over_number') int overNumber,@JsonKey(name: 'ball_in_over') int ballInOver,@JsonKey(name: 'is_legal_delivery') bool isLegalDelivery,@JsonKey(name: 'ball_type') String ballType,@JsonKey(name: 'runs_scored') int runsScored, int extras,@JsonKey(name: 'is_wicket') bool isWicket,@JsonKey(name: 'wicket_type') String? wicketType,@JsonKey(name: 'is_free_hit') bool isFreeHit,@JsonKey(name: 'batsman_id') String? batsmanId,@JsonKey(name: 'non_striker_id') String? nonStrikerId,@JsonKey(name: 'bowler_id') String? bowlerId,@JsonKey(name: 'fielder_id') String? fielderId, String? commentary
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
@pragma('vm:prefer-inline') @override $Res call({Object? ballId = null,Object? matchId = null,Object? inningsNumber = null,Object? seq = null,Object? overNumber = null,Object? ballInOver = null,Object? isLegalDelivery = null,Object? ballType = null,Object? runsScored = null,Object? extras = null,Object? isWicket = null,Object? wicketType = freezed,Object? isFreeHit = null,Object? batsmanId = freezed,Object? nonStrikerId = freezed,Object? bowlerId = freezed,Object? fielderId = freezed,Object? commentary = freezed,}) {
  return _then(_self.copyWith(
ballId: null == ballId ? _self.ballId : ballId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,overNumber: null == overNumber ? _self.overNumber : overNumber // ignore: cast_nullable_to_non_nullable
as int,ballInOver: null == ballInOver ? _self.ballInOver : ballInOver // ignore: cast_nullable_to_non_nullable
as int,isLegalDelivery: null == isLegalDelivery ? _self.isLegalDelivery : isLegalDelivery // ignore: cast_nullable_to_non_nullable
as bool,ballType: null == ballType ? _self.ballType : ballType // ignore: cast_nullable_to_non_nullable
as String,runsScored: null == runsScored ? _self.runsScored : runsScored // ignore: cast_nullable_to_non_nullable
as int,extras: null == extras ? _self.extras : extras // ignore: cast_nullable_to_non_nullable
as int,isWicket: null == isWicket ? _self.isWicket : isWicket // ignore: cast_nullable_to_non_nullable
as bool,wicketType: freezed == wicketType ? _self.wicketType : wicketType // ignore: cast_nullable_to_non_nullable
as String?,isFreeHit: null == isFreeHit ? _self.isFreeHit : isFreeHit // ignore: cast_nullable_to_non_nullable
as bool,batsmanId: freezed == batsmanId ? _self.batsmanId : batsmanId // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerId: freezed == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,bowlerId: freezed == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String?,fielderId: freezed == fielderId ? _self.fielderId : fielderId // ignore: cast_nullable_to_non_nullable
as String?,commentary: freezed == commentary ? _self.commentary : commentary // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'ball_id')  String ballId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber,  int seq, @JsonKey(name: 'over_number')  int overNumber, @JsonKey(name: 'ball_in_over')  int ballInOver, @JsonKey(name: 'is_legal_delivery')  bool isLegalDelivery, @JsonKey(name: 'ball_type')  String ballType, @JsonKey(name: 'runs_scored')  int runsScored,  int extras, @JsonKey(name: 'is_wicket')  bool isWicket, @JsonKey(name: 'wicket_type')  String? wicketType, @JsonKey(name: 'is_free_hit')  bool isFreeHit, @JsonKey(name: 'batsman_id')  String? batsmanId, @JsonKey(name: 'non_striker_id')  String? nonStrikerId, @JsonKey(name: 'bowler_id')  String? bowlerId, @JsonKey(name: 'fielder_id')  String? fielderId,  String? commentary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BallDto() when $default != null:
return $default(_that.ballId,_that.matchId,_that.inningsNumber,_that.seq,_that.overNumber,_that.ballInOver,_that.isLegalDelivery,_that.ballType,_that.runsScored,_that.extras,_that.isWicket,_that.wicketType,_that.isFreeHit,_that.batsmanId,_that.nonStrikerId,_that.bowlerId,_that.fielderId,_that.commentary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'ball_id')  String ballId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber,  int seq, @JsonKey(name: 'over_number')  int overNumber, @JsonKey(name: 'ball_in_over')  int ballInOver, @JsonKey(name: 'is_legal_delivery')  bool isLegalDelivery, @JsonKey(name: 'ball_type')  String ballType, @JsonKey(name: 'runs_scored')  int runsScored,  int extras, @JsonKey(name: 'is_wicket')  bool isWicket, @JsonKey(name: 'wicket_type')  String? wicketType, @JsonKey(name: 'is_free_hit')  bool isFreeHit, @JsonKey(name: 'batsman_id')  String? batsmanId, @JsonKey(name: 'non_striker_id')  String? nonStrikerId, @JsonKey(name: 'bowler_id')  String? bowlerId, @JsonKey(name: 'fielder_id')  String? fielderId,  String? commentary)  $default,) {final _that = this;
switch (_that) {
case _BallDto():
return $default(_that.ballId,_that.matchId,_that.inningsNumber,_that.seq,_that.overNumber,_that.ballInOver,_that.isLegalDelivery,_that.ballType,_that.runsScored,_that.extras,_that.isWicket,_that.wicketType,_that.isFreeHit,_that.batsmanId,_that.nonStrikerId,_that.bowlerId,_that.fielderId,_that.commentary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'ball_id')  String ballId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'innings_number')  int inningsNumber,  int seq, @JsonKey(name: 'over_number')  int overNumber, @JsonKey(name: 'ball_in_over')  int ballInOver, @JsonKey(name: 'is_legal_delivery')  bool isLegalDelivery, @JsonKey(name: 'ball_type')  String ballType, @JsonKey(name: 'runs_scored')  int runsScored,  int extras, @JsonKey(name: 'is_wicket')  bool isWicket, @JsonKey(name: 'wicket_type')  String? wicketType, @JsonKey(name: 'is_free_hit')  bool isFreeHit, @JsonKey(name: 'batsman_id')  String? batsmanId, @JsonKey(name: 'non_striker_id')  String? nonStrikerId, @JsonKey(name: 'bowler_id')  String? bowlerId, @JsonKey(name: 'fielder_id')  String? fielderId,  String? commentary)?  $default,) {final _that = this;
switch (_that) {
case _BallDto() when $default != null:
return $default(_that.ballId,_that.matchId,_that.inningsNumber,_that.seq,_that.overNumber,_that.ballInOver,_that.isLegalDelivery,_that.ballType,_that.runsScored,_that.extras,_that.isWicket,_that.wicketType,_that.isFreeHit,_that.batsmanId,_that.nonStrikerId,_that.bowlerId,_that.fielderId,_that.commentary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BallDto extends BallDto {
  const _BallDto({@JsonKey(name: 'ball_id') required this.ballId, @JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'innings_number') required this.inningsNumber, required this.seq, @JsonKey(name: 'over_number') required this.overNumber, @JsonKey(name: 'ball_in_over') required this.ballInOver, @JsonKey(name: 'is_legal_delivery') this.isLegalDelivery = true, @JsonKey(name: 'ball_type') this.ballType = 'legal', @JsonKey(name: 'runs_scored') this.runsScored = 0, this.extras = 0, @JsonKey(name: 'is_wicket') this.isWicket = false, @JsonKey(name: 'wicket_type') this.wicketType, @JsonKey(name: 'is_free_hit') this.isFreeHit = false, @JsonKey(name: 'batsman_id') this.batsmanId, @JsonKey(name: 'non_striker_id') this.nonStrikerId, @JsonKey(name: 'bowler_id') this.bowlerId, @JsonKey(name: 'fielder_id') this.fielderId, this.commentary}): super._();
  factory _BallDto.fromJson(Map<String, dynamic> json) => _$BallDtoFromJson(json);

@override@JsonKey(name: 'ball_id') final  String ballId;
@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'innings_number') final  int inningsNumber;
@override final  int seq;
@override@JsonKey(name: 'over_number') final  int overNumber;
@override@JsonKey(name: 'ball_in_over') final  int ballInOver;
@override@JsonKey(name: 'is_legal_delivery') final  bool isLegalDelivery;
@override@JsonKey(name: 'ball_type') final  String ballType;
@override@JsonKey(name: 'runs_scored') final  int runsScored;
@override@JsonKey() final  int extras;
@override@JsonKey(name: 'is_wicket') final  bool isWicket;
@override@JsonKey(name: 'wicket_type') final  String? wicketType;
@override@JsonKey(name: 'is_free_hit') final  bool isFreeHit;
@override@JsonKey(name: 'batsman_id') final  String? batsmanId;
@override@JsonKey(name: 'non_striker_id') final  String? nonStrikerId;
@override@JsonKey(name: 'bowler_id') final  String? bowlerId;
@override@JsonKey(name: 'fielder_id') final  String? fielderId;
@override final  String? commentary;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BallDto&&(identical(other.ballId, ballId) || other.ballId == ballId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.overNumber, overNumber) || other.overNumber == overNumber)&&(identical(other.ballInOver, ballInOver) || other.ballInOver == ballInOver)&&(identical(other.isLegalDelivery, isLegalDelivery) || other.isLegalDelivery == isLegalDelivery)&&(identical(other.ballType, ballType) || other.ballType == ballType)&&(identical(other.runsScored, runsScored) || other.runsScored == runsScored)&&(identical(other.extras, extras) || other.extras == extras)&&(identical(other.isWicket, isWicket) || other.isWicket == isWicket)&&(identical(other.wicketType, wicketType) || other.wicketType == wicketType)&&(identical(other.isFreeHit, isFreeHit) || other.isFreeHit == isFreeHit)&&(identical(other.batsmanId, batsmanId) || other.batsmanId == batsmanId)&&(identical(other.nonStrikerId, nonStrikerId) || other.nonStrikerId == nonStrikerId)&&(identical(other.bowlerId, bowlerId) || other.bowlerId == bowlerId)&&(identical(other.fielderId, fielderId) || other.fielderId == fielderId)&&(identical(other.commentary, commentary) || other.commentary == commentary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ballId,matchId,inningsNumber,seq,overNumber,ballInOver,isLegalDelivery,ballType,runsScored,extras,isWicket,wicketType,isFreeHit,batsmanId,nonStrikerId,bowlerId,fielderId,commentary);

@override
String toString() {
  return 'BallDto(ballId: $ballId, matchId: $matchId, inningsNumber: $inningsNumber, seq: $seq, overNumber: $overNumber, ballInOver: $ballInOver, isLegalDelivery: $isLegalDelivery, ballType: $ballType, runsScored: $runsScored, extras: $extras, isWicket: $isWicket, wicketType: $wicketType, isFreeHit: $isFreeHit, batsmanId: $batsmanId, nonStrikerId: $nonStrikerId, bowlerId: $bowlerId, fielderId: $fielderId, commentary: $commentary)';
}


}

/// @nodoc
abstract mixin class _$BallDtoCopyWith<$Res> implements $BallDtoCopyWith<$Res> {
  factory _$BallDtoCopyWith(_BallDto value, $Res Function(_BallDto) _then) = __$BallDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'ball_id') String ballId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'innings_number') int inningsNumber, int seq,@JsonKey(name: 'over_number') int overNumber,@JsonKey(name: 'ball_in_over') int ballInOver,@JsonKey(name: 'is_legal_delivery') bool isLegalDelivery,@JsonKey(name: 'ball_type') String ballType,@JsonKey(name: 'runs_scored') int runsScored, int extras,@JsonKey(name: 'is_wicket') bool isWicket,@JsonKey(name: 'wicket_type') String? wicketType,@JsonKey(name: 'is_free_hit') bool isFreeHit,@JsonKey(name: 'batsman_id') String? batsmanId,@JsonKey(name: 'non_striker_id') String? nonStrikerId,@JsonKey(name: 'bowler_id') String? bowlerId,@JsonKey(name: 'fielder_id') String? fielderId, String? commentary
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
@override @pragma('vm:prefer-inline') $Res call({Object? ballId = null,Object? matchId = null,Object? inningsNumber = null,Object? seq = null,Object? overNumber = null,Object? ballInOver = null,Object? isLegalDelivery = null,Object? ballType = null,Object? runsScored = null,Object? extras = null,Object? isWicket = null,Object? wicketType = freezed,Object? isFreeHit = null,Object? batsmanId = freezed,Object? nonStrikerId = freezed,Object? bowlerId = freezed,Object? fielderId = freezed,Object? commentary = freezed,}) {
  return _then(_BallDto(
ballId: null == ballId ? _self.ballId : ballId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,overNumber: null == overNumber ? _self.overNumber : overNumber // ignore: cast_nullable_to_non_nullable
as int,ballInOver: null == ballInOver ? _self.ballInOver : ballInOver // ignore: cast_nullable_to_non_nullable
as int,isLegalDelivery: null == isLegalDelivery ? _self.isLegalDelivery : isLegalDelivery // ignore: cast_nullable_to_non_nullable
as bool,ballType: null == ballType ? _self.ballType : ballType // ignore: cast_nullable_to_non_nullable
as String,runsScored: null == runsScored ? _self.runsScored : runsScored // ignore: cast_nullable_to_non_nullable
as int,extras: null == extras ? _self.extras : extras // ignore: cast_nullable_to_non_nullable
as int,isWicket: null == isWicket ? _self.isWicket : isWicket // ignore: cast_nullable_to_non_nullable
as bool,wicketType: freezed == wicketType ? _self.wicketType : wicketType // ignore: cast_nullable_to_non_nullable
as String?,isFreeHit: null == isFreeHit ? _self.isFreeHit : isFreeHit // ignore: cast_nullable_to_non_nullable
as bool,batsmanId: freezed == batsmanId ? _self.batsmanId : batsmanId // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerId: freezed == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,bowlerId: freezed == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String?,fielderId: freezed == fielderId ? _self.fielderId : fielderId // ignore: cast_nullable_to_non_nullable
as String?,commentary: freezed == commentary ? _self.commentary : commentary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
