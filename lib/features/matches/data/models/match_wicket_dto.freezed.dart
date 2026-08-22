// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_wicket_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchWicketDto {

@JsonKey(name: 'wicket_id') String get wicketId;@JsonKey(name: 'delivery_id') String get deliveryId;@JsonKey(name: 'innings_id') String get inningsId;@JsonKey(name: 'player_out_id') String get playerOutId;@JsonKey(name: 'dismissal_kind') String get dismissalKind;@JsonKey(name: 'is_bowler_credited') bool get isBowlerCredited;@JsonKey(name: 'credited_bowler_id') String? get creditedBowlerId;@JsonKey(name: 'primary_fielder_id') String? get primaryFielderId;@JsonKey(name: 'assisted_fielder_id') String? get assistedFielderId;@JsonKey(name: 'fall_of_wicket_score') int get fallOfWicketScore;@JsonKey(name: 'fall_of_wicket_number') int get fallOfWicketNumber;@JsonKey(name: 'fall_of_wicket_overs') double get fallOfWicketOvers;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of MatchWicketDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchWicketDtoCopyWith<MatchWicketDto> get copyWith => _$MatchWicketDtoCopyWithImpl<MatchWicketDto>(this as MatchWicketDto, _$identity);

  /// Serializes this MatchWicketDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchWicketDto&&(identical(other.wicketId, wicketId) || other.wicketId == wicketId)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.playerOutId, playerOutId) || other.playerOutId == playerOutId)&&(identical(other.dismissalKind, dismissalKind) || other.dismissalKind == dismissalKind)&&(identical(other.isBowlerCredited, isBowlerCredited) || other.isBowlerCredited == isBowlerCredited)&&(identical(other.creditedBowlerId, creditedBowlerId) || other.creditedBowlerId == creditedBowlerId)&&(identical(other.primaryFielderId, primaryFielderId) || other.primaryFielderId == primaryFielderId)&&(identical(other.assistedFielderId, assistedFielderId) || other.assistedFielderId == assistedFielderId)&&(identical(other.fallOfWicketScore, fallOfWicketScore) || other.fallOfWicketScore == fallOfWicketScore)&&(identical(other.fallOfWicketNumber, fallOfWicketNumber) || other.fallOfWicketNumber == fallOfWicketNumber)&&(identical(other.fallOfWicketOvers, fallOfWicketOvers) || other.fallOfWicketOvers == fallOfWicketOvers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wicketId,deliveryId,inningsId,playerOutId,dismissalKind,isBowlerCredited,creditedBowlerId,primaryFielderId,assistedFielderId,fallOfWicketScore,fallOfWicketNumber,fallOfWicketOvers,createdAt);

@override
String toString() {
  return 'MatchWicketDto(wicketId: $wicketId, deliveryId: $deliveryId, inningsId: $inningsId, playerOutId: $playerOutId, dismissalKind: $dismissalKind, isBowlerCredited: $isBowlerCredited, creditedBowlerId: $creditedBowlerId, primaryFielderId: $primaryFielderId, assistedFielderId: $assistedFielderId, fallOfWicketScore: $fallOfWicketScore, fallOfWicketNumber: $fallOfWicketNumber, fallOfWicketOvers: $fallOfWicketOvers, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MatchWicketDtoCopyWith<$Res>  {
  factory $MatchWicketDtoCopyWith(MatchWicketDto value, $Res Function(MatchWicketDto) _then) = _$MatchWicketDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'wicket_id') String wicketId,@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'player_out_id') String playerOutId,@JsonKey(name: 'dismissal_kind') String dismissalKind,@JsonKey(name: 'is_bowler_credited') bool isBowlerCredited,@JsonKey(name: 'credited_bowler_id') String? creditedBowlerId,@JsonKey(name: 'primary_fielder_id') String? primaryFielderId,@JsonKey(name: 'assisted_fielder_id') String? assistedFielderId,@JsonKey(name: 'fall_of_wicket_score') int fallOfWicketScore,@JsonKey(name: 'fall_of_wicket_number') int fallOfWicketNumber,@JsonKey(name: 'fall_of_wicket_overs') double fallOfWicketOvers,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$MatchWicketDtoCopyWithImpl<$Res>
    implements $MatchWicketDtoCopyWith<$Res> {
  _$MatchWicketDtoCopyWithImpl(this._self, this._then);

  final MatchWicketDto _self;
  final $Res Function(MatchWicketDto) _then;

/// Create a copy of MatchWicketDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wicketId = null,Object? deliveryId = null,Object? inningsId = null,Object? playerOutId = null,Object? dismissalKind = null,Object? isBowlerCredited = null,Object? creditedBowlerId = freezed,Object? primaryFielderId = freezed,Object? assistedFielderId = freezed,Object? fallOfWicketScore = null,Object? fallOfWicketNumber = null,Object? fallOfWicketOvers = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
wicketId: null == wicketId ? _self.wicketId : wicketId // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,playerOutId: null == playerOutId ? _self.playerOutId : playerOutId // ignore: cast_nullable_to_non_nullable
as String,dismissalKind: null == dismissalKind ? _self.dismissalKind : dismissalKind // ignore: cast_nullable_to_non_nullable
as String,isBowlerCredited: null == isBowlerCredited ? _self.isBowlerCredited : isBowlerCredited // ignore: cast_nullable_to_non_nullable
as bool,creditedBowlerId: freezed == creditedBowlerId ? _self.creditedBowlerId : creditedBowlerId // ignore: cast_nullable_to_non_nullable
as String?,primaryFielderId: freezed == primaryFielderId ? _self.primaryFielderId : primaryFielderId // ignore: cast_nullable_to_non_nullable
as String?,assistedFielderId: freezed == assistedFielderId ? _self.assistedFielderId : assistedFielderId // ignore: cast_nullable_to_non_nullable
as String?,fallOfWicketScore: null == fallOfWicketScore ? _self.fallOfWicketScore : fallOfWicketScore // ignore: cast_nullable_to_non_nullable
as int,fallOfWicketNumber: null == fallOfWicketNumber ? _self.fallOfWicketNumber : fallOfWicketNumber // ignore: cast_nullable_to_non_nullable
as int,fallOfWicketOvers: null == fallOfWicketOvers ? _self.fallOfWicketOvers : fallOfWicketOvers // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchWicketDto].
extension MatchWicketDtoPatterns on MatchWicketDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchWicketDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchWicketDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchWicketDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchWicketDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchWicketDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchWicketDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'wicket_id')  String wicketId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_out_id')  String playerOutId, @JsonKey(name: 'dismissal_kind')  String dismissalKind, @JsonKey(name: 'is_bowler_credited')  bool isBowlerCredited, @JsonKey(name: 'credited_bowler_id')  String? creditedBowlerId, @JsonKey(name: 'primary_fielder_id')  String? primaryFielderId, @JsonKey(name: 'assisted_fielder_id')  String? assistedFielderId, @JsonKey(name: 'fall_of_wicket_score')  int fallOfWicketScore, @JsonKey(name: 'fall_of_wicket_number')  int fallOfWicketNumber, @JsonKey(name: 'fall_of_wicket_overs')  double fallOfWicketOvers, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchWicketDto() when $default != null:
return $default(_that.wicketId,_that.deliveryId,_that.inningsId,_that.playerOutId,_that.dismissalKind,_that.isBowlerCredited,_that.creditedBowlerId,_that.primaryFielderId,_that.assistedFielderId,_that.fallOfWicketScore,_that.fallOfWicketNumber,_that.fallOfWicketOvers,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'wicket_id')  String wicketId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_out_id')  String playerOutId, @JsonKey(name: 'dismissal_kind')  String dismissalKind, @JsonKey(name: 'is_bowler_credited')  bool isBowlerCredited, @JsonKey(name: 'credited_bowler_id')  String? creditedBowlerId, @JsonKey(name: 'primary_fielder_id')  String? primaryFielderId, @JsonKey(name: 'assisted_fielder_id')  String? assistedFielderId, @JsonKey(name: 'fall_of_wicket_score')  int fallOfWicketScore, @JsonKey(name: 'fall_of_wicket_number')  int fallOfWicketNumber, @JsonKey(name: 'fall_of_wicket_overs')  double fallOfWicketOvers, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _MatchWicketDto():
return $default(_that.wicketId,_that.deliveryId,_that.inningsId,_that.playerOutId,_that.dismissalKind,_that.isBowlerCredited,_that.creditedBowlerId,_that.primaryFielderId,_that.assistedFielderId,_that.fallOfWicketScore,_that.fallOfWicketNumber,_that.fallOfWicketOvers,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'wicket_id')  String wicketId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'innings_id')  String inningsId, @JsonKey(name: 'player_out_id')  String playerOutId, @JsonKey(name: 'dismissal_kind')  String dismissalKind, @JsonKey(name: 'is_bowler_credited')  bool isBowlerCredited, @JsonKey(name: 'credited_bowler_id')  String? creditedBowlerId, @JsonKey(name: 'primary_fielder_id')  String? primaryFielderId, @JsonKey(name: 'assisted_fielder_id')  String? assistedFielderId, @JsonKey(name: 'fall_of_wicket_score')  int fallOfWicketScore, @JsonKey(name: 'fall_of_wicket_number')  int fallOfWicketNumber, @JsonKey(name: 'fall_of_wicket_overs')  double fallOfWicketOvers, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchWicketDto() when $default != null:
return $default(_that.wicketId,_that.deliveryId,_that.inningsId,_that.playerOutId,_that.dismissalKind,_that.isBowlerCredited,_that.creditedBowlerId,_that.primaryFielderId,_that.assistedFielderId,_that.fallOfWicketScore,_that.fallOfWicketNumber,_that.fallOfWicketOvers,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchWicketDto extends MatchWicketDto {
  const _MatchWicketDto({@JsonKey(name: 'wicket_id') required this.wicketId, @JsonKey(name: 'delivery_id') required this.deliveryId, @JsonKey(name: 'innings_id') required this.inningsId, @JsonKey(name: 'player_out_id') required this.playerOutId, @JsonKey(name: 'dismissal_kind') required this.dismissalKind, @JsonKey(name: 'is_bowler_credited') this.isBowlerCredited = true, @JsonKey(name: 'credited_bowler_id') this.creditedBowlerId, @JsonKey(name: 'primary_fielder_id') this.primaryFielderId, @JsonKey(name: 'assisted_fielder_id') this.assistedFielderId, @JsonKey(name: 'fall_of_wicket_score') required this.fallOfWicketScore, @JsonKey(name: 'fall_of_wicket_number') required this.fallOfWicketNumber, @JsonKey(name: 'fall_of_wicket_overs') required this.fallOfWicketOvers, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _MatchWicketDto.fromJson(Map<String, dynamic> json) => _$MatchWicketDtoFromJson(json);

@override@JsonKey(name: 'wicket_id') final  String wicketId;
@override@JsonKey(name: 'delivery_id') final  String deliveryId;
@override@JsonKey(name: 'innings_id') final  String inningsId;
@override@JsonKey(name: 'player_out_id') final  String playerOutId;
@override@JsonKey(name: 'dismissal_kind') final  String dismissalKind;
@override@JsonKey(name: 'is_bowler_credited') final  bool isBowlerCredited;
@override@JsonKey(name: 'credited_bowler_id') final  String? creditedBowlerId;
@override@JsonKey(name: 'primary_fielder_id') final  String? primaryFielderId;
@override@JsonKey(name: 'assisted_fielder_id') final  String? assistedFielderId;
@override@JsonKey(name: 'fall_of_wicket_score') final  int fallOfWicketScore;
@override@JsonKey(name: 'fall_of_wicket_number') final  int fallOfWicketNumber;
@override@JsonKey(name: 'fall_of_wicket_overs') final  double fallOfWicketOvers;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of MatchWicketDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchWicketDtoCopyWith<_MatchWicketDto> get copyWith => __$MatchWicketDtoCopyWithImpl<_MatchWicketDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchWicketDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchWicketDto&&(identical(other.wicketId, wicketId) || other.wicketId == wicketId)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.inningsId, inningsId) || other.inningsId == inningsId)&&(identical(other.playerOutId, playerOutId) || other.playerOutId == playerOutId)&&(identical(other.dismissalKind, dismissalKind) || other.dismissalKind == dismissalKind)&&(identical(other.isBowlerCredited, isBowlerCredited) || other.isBowlerCredited == isBowlerCredited)&&(identical(other.creditedBowlerId, creditedBowlerId) || other.creditedBowlerId == creditedBowlerId)&&(identical(other.primaryFielderId, primaryFielderId) || other.primaryFielderId == primaryFielderId)&&(identical(other.assistedFielderId, assistedFielderId) || other.assistedFielderId == assistedFielderId)&&(identical(other.fallOfWicketScore, fallOfWicketScore) || other.fallOfWicketScore == fallOfWicketScore)&&(identical(other.fallOfWicketNumber, fallOfWicketNumber) || other.fallOfWicketNumber == fallOfWicketNumber)&&(identical(other.fallOfWicketOvers, fallOfWicketOvers) || other.fallOfWicketOvers == fallOfWicketOvers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wicketId,deliveryId,inningsId,playerOutId,dismissalKind,isBowlerCredited,creditedBowlerId,primaryFielderId,assistedFielderId,fallOfWicketScore,fallOfWicketNumber,fallOfWicketOvers,createdAt);

@override
String toString() {
  return 'MatchWicketDto(wicketId: $wicketId, deliveryId: $deliveryId, inningsId: $inningsId, playerOutId: $playerOutId, dismissalKind: $dismissalKind, isBowlerCredited: $isBowlerCredited, creditedBowlerId: $creditedBowlerId, primaryFielderId: $primaryFielderId, assistedFielderId: $assistedFielderId, fallOfWicketScore: $fallOfWicketScore, fallOfWicketNumber: $fallOfWicketNumber, fallOfWicketOvers: $fallOfWicketOvers, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MatchWicketDtoCopyWith<$Res> implements $MatchWicketDtoCopyWith<$Res> {
  factory _$MatchWicketDtoCopyWith(_MatchWicketDto value, $Res Function(_MatchWicketDto) _then) = __$MatchWicketDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'wicket_id') String wicketId,@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'innings_id') String inningsId,@JsonKey(name: 'player_out_id') String playerOutId,@JsonKey(name: 'dismissal_kind') String dismissalKind,@JsonKey(name: 'is_bowler_credited') bool isBowlerCredited,@JsonKey(name: 'credited_bowler_id') String? creditedBowlerId,@JsonKey(name: 'primary_fielder_id') String? primaryFielderId,@JsonKey(name: 'assisted_fielder_id') String? assistedFielderId,@JsonKey(name: 'fall_of_wicket_score') int fallOfWicketScore,@JsonKey(name: 'fall_of_wicket_number') int fallOfWicketNumber,@JsonKey(name: 'fall_of_wicket_overs') double fallOfWicketOvers,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$MatchWicketDtoCopyWithImpl<$Res>
    implements _$MatchWicketDtoCopyWith<$Res> {
  __$MatchWicketDtoCopyWithImpl(this._self, this._then);

  final _MatchWicketDto _self;
  final $Res Function(_MatchWicketDto) _then;

/// Create a copy of MatchWicketDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wicketId = null,Object? deliveryId = null,Object? inningsId = null,Object? playerOutId = null,Object? dismissalKind = null,Object? isBowlerCredited = null,Object? creditedBowlerId = freezed,Object? primaryFielderId = freezed,Object? assistedFielderId = freezed,Object? fallOfWicketScore = null,Object? fallOfWicketNumber = null,Object? fallOfWicketOvers = null,Object? createdAt = null,}) {
  return _then(_MatchWicketDto(
wicketId: null == wicketId ? _self.wicketId : wicketId // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,inningsId: null == inningsId ? _self.inningsId : inningsId // ignore: cast_nullable_to_non_nullable
as String,playerOutId: null == playerOutId ? _self.playerOutId : playerOutId // ignore: cast_nullable_to_non_nullable
as String,dismissalKind: null == dismissalKind ? _self.dismissalKind : dismissalKind // ignore: cast_nullable_to_non_nullable
as String,isBowlerCredited: null == isBowlerCredited ? _self.isBowlerCredited : isBowlerCredited // ignore: cast_nullable_to_non_nullable
as bool,creditedBowlerId: freezed == creditedBowlerId ? _self.creditedBowlerId : creditedBowlerId // ignore: cast_nullable_to_non_nullable
as String?,primaryFielderId: freezed == primaryFielderId ? _self.primaryFielderId : primaryFielderId // ignore: cast_nullable_to_non_nullable
as String?,assistedFielderId: freezed == assistedFielderId ? _self.assistedFielderId : assistedFielderId // ignore: cast_nullable_to_non_nullable
as String?,fallOfWicketScore: null == fallOfWicketScore ? _self.fallOfWicketScore : fallOfWicketScore // ignore: cast_nullable_to_non_nullable
as int,fallOfWicketNumber: null == fallOfWicketNumber ? _self.fallOfWicketNumber : fallOfWicketNumber // ignore: cast_nullable_to_non_nullable
as int,fallOfWicketOvers: null == fallOfWicketOvers ? _self.fallOfWicketOvers : fallOfWicketOvers // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
