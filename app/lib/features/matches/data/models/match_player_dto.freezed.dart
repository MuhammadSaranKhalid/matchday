// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_player_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchPlayerDto {

@JsonKey(name: 'match_player_id') String get matchPlayerId;@JsonKey(name: 'match_id') String get matchId;@JsonKey(name: 'team_side') String get teamSide;@JsonKey(name: 'profile_id') String? get profileId;@JsonKey(name: 'unclaimed_id') String? get unclaimedId;@JsonKey(name: 'batting_order') int? get battingOrder;@JsonKey(name: 'jersey_number') int? get jerseyNumber;@JsonKey(name: 'is_captain') bool get isCaptain;@JsonKey(name: 'is_keeper') bool get isKeeper;@JsonKey(name: 'is_substitute') bool get isSubstitute; String get source;@JsonKey(includeToJson: false) Map<String, dynamic>? get profile;@JsonKey(includeToJson: false) Map<String, dynamic>? get unclaimed;
/// Create a copy of MatchPlayerDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchPlayerDtoCopyWith<MatchPlayerDto> get copyWith => _$MatchPlayerDtoCopyWithImpl<MatchPlayerDto>(this as MatchPlayerDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchPlayerDto&&(identical(other.matchPlayerId, matchPlayerId) || other.matchPlayerId == matchPlayerId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.teamSide, teamSide) || other.teamSide == teamSide)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.unclaimedId, unclaimedId) || other.unclaimedId == unclaimedId)&&(identical(other.battingOrder, battingOrder) || other.battingOrder == battingOrder)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.isCaptain, isCaptain) || other.isCaptain == isCaptain)&&(identical(other.isKeeper, isKeeper) || other.isKeeper == isKeeper)&&(identical(other.isSubstitute, isSubstitute) || other.isSubstitute == isSubstitute)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.profile, profile)&&const DeepCollectionEquality().equals(other.unclaimed, unclaimed));
}


@override
int get hashCode => Object.hash(runtimeType,matchPlayerId,matchId,teamSide,profileId,unclaimedId,battingOrder,jerseyNumber,isCaptain,isKeeper,isSubstitute,source,const DeepCollectionEquality().hash(profile),const DeepCollectionEquality().hash(unclaimed));

@override
String toString() {
  return 'MatchPlayerDto(matchPlayerId: $matchPlayerId, matchId: $matchId, teamSide: $teamSide, profileId: $profileId, unclaimedId: $unclaimedId, battingOrder: $battingOrder, jerseyNumber: $jerseyNumber, isCaptain: $isCaptain, isKeeper: $isKeeper, isSubstitute: $isSubstitute, source: $source, profile: $profile, unclaimed: $unclaimed)';
}


}

/// @nodoc
abstract mixin class $MatchPlayerDtoCopyWith<$Res>  {
  factory $MatchPlayerDtoCopyWith(MatchPlayerDto value, $Res Function(MatchPlayerDto) _then) = _$MatchPlayerDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'match_player_id') String matchPlayerId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'team_side') String teamSide,@JsonKey(name: 'profile_id') String? profileId,@JsonKey(name: 'unclaimed_id') String? unclaimedId,@JsonKey(name: 'batting_order') int? battingOrder,@JsonKey(name: 'jersey_number') int? jerseyNumber,@JsonKey(name: 'is_captain') bool isCaptain,@JsonKey(name: 'is_keeper') bool isKeeper,@JsonKey(name: 'is_substitute') bool isSubstitute, String source,@JsonKey(includeToJson: false) Map<String, dynamic>? profile,@JsonKey(includeToJson: false) Map<String, dynamic>? unclaimed
});




}
/// @nodoc
class _$MatchPlayerDtoCopyWithImpl<$Res>
    implements $MatchPlayerDtoCopyWith<$Res> {
  _$MatchPlayerDtoCopyWithImpl(this._self, this._then);

  final MatchPlayerDto _self;
  final $Res Function(MatchPlayerDto) _then;

/// Create a copy of MatchPlayerDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchPlayerId = null,Object? matchId = null,Object? teamSide = null,Object? profileId = freezed,Object? unclaimedId = freezed,Object? battingOrder = freezed,Object? jerseyNumber = freezed,Object? isCaptain = null,Object? isKeeper = null,Object? isSubstitute = null,Object? source = null,Object? profile = freezed,Object? unclaimed = freezed,}) {
  return _then(_self.copyWith(
matchPlayerId: null == matchPlayerId ? _self.matchPlayerId : matchPlayerId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,teamSide: null == teamSide ? _self.teamSide : teamSide // ignore: cast_nullable_to_non_nullable
as String,profileId: freezed == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String?,unclaimedId: freezed == unclaimedId ? _self.unclaimedId : unclaimedId // ignore: cast_nullable_to_non_nullable
as String?,battingOrder: freezed == battingOrder ? _self.battingOrder : battingOrder // ignore: cast_nullable_to_non_nullable
as int?,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int?,isCaptain: null == isCaptain ? _self.isCaptain : isCaptain // ignore: cast_nullable_to_non_nullable
as bool,isKeeper: null == isKeeper ? _self.isKeeper : isKeeper // ignore: cast_nullable_to_non_nullable
as bool,isSubstitute: null == isSubstitute ? _self.isSubstitute : isSubstitute // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,unclaimed: freezed == unclaimed ? _self.unclaimed : unclaimed // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchPlayerDto].
extension MatchPlayerDtoPatterns on MatchPlayerDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchPlayerDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchPlayerDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchPlayerDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchPlayerDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchPlayerDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchPlayerDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_player_id')  String matchPlayerId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_side')  String teamSide, @JsonKey(name: 'profile_id')  String? profileId, @JsonKey(name: 'unclaimed_id')  String? unclaimedId, @JsonKey(name: 'batting_order')  int? battingOrder, @JsonKey(name: 'jersey_number')  int? jerseyNumber, @JsonKey(name: 'is_captain')  bool isCaptain, @JsonKey(name: 'is_keeper')  bool isKeeper, @JsonKey(name: 'is_substitute')  bool isSubstitute,  String source, @JsonKey(includeToJson: false)  Map<String, dynamic>? profile, @JsonKey(includeToJson: false)  Map<String, dynamic>? unclaimed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchPlayerDto() when $default != null:
return $default(_that.matchPlayerId,_that.matchId,_that.teamSide,_that.profileId,_that.unclaimedId,_that.battingOrder,_that.jerseyNumber,_that.isCaptain,_that.isKeeper,_that.isSubstitute,_that.source,_that.profile,_that.unclaimed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'match_player_id')  String matchPlayerId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_side')  String teamSide, @JsonKey(name: 'profile_id')  String? profileId, @JsonKey(name: 'unclaimed_id')  String? unclaimedId, @JsonKey(name: 'batting_order')  int? battingOrder, @JsonKey(name: 'jersey_number')  int? jerseyNumber, @JsonKey(name: 'is_captain')  bool isCaptain, @JsonKey(name: 'is_keeper')  bool isKeeper, @JsonKey(name: 'is_substitute')  bool isSubstitute,  String source, @JsonKey(includeToJson: false)  Map<String, dynamic>? profile, @JsonKey(includeToJson: false)  Map<String, dynamic>? unclaimed)  $default,) {final _that = this;
switch (_that) {
case _MatchPlayerDto():
return $default(_that.matchPlayerId,_that.matchId,_that.teamSide,_that.profileId,_that.unclaimedId,_that.battingOrder,_that.jerseyNumber,_that.isCaptain,_that.isKeeper,_that.isSubstitute,_that.source,_that.profile,_that.unclaimed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'match_player_id')  String matchPlayerId, @JsonKey(name: 'match_id')  String matchId, @JsonKey(name: 'team_side')  String teamSide, @JsonKey(name: 'profile_id')  String? profileId, @JsonKey(name: 'unclaimed_id')  String? unclaimedId, @JsonKey(name: 'batting_order')  int? battingOrder, @JsonKey(name: 'jersey_number')  int? jerseyNumber, @JsonKey(name: 'is_captain')  bool isCaptain, @JsonKey(name: 'is_keeper')  bool isKeeper, @JsonKey(name: 'is_substitute')  bool isSubstitute,  String source, @JsonKey(includeToJson: false)  Map<String, dynamic>? profile, @JsonKey(includeToJson: false)  Map<String, dynamic>? unclaimed)?  $default,) {final _that = this;
switch (_that) {
case _MatchPlayerDto() when $default != null:
return $default(_that.matchPlayerId,_that.matchId,_that.teamSide,_that.profileId,_that.unclaimedId,_that.battingOrder,_that.jerseyNumber,_that.isCaptain,_that.isKeeper,_that.isSubstitute,_that.source,_that.profile,_that.unclaimed);case _:
  return null;

}
}

}

/// @nodoc


class _MatchPlayerDto extends MatchPlayerDto {
  const _MatchPlayerDto({@JsonKey(name: 'match_player_id') required this.matchPlayerId, @JsonKey(name: 'match_id') required this.matchId, @JsonKey(name: 'team_side') required this.teamSide, @JsonKey(name: 'profile_id') this.profileId, @JsonKey(name: 'unclaimed_id') this.unclaimedId, @JsonKey(name: 'batting_order') this.battingOrder, @JsonKey(name: 'jersey_number') this.jerseyNumber, @JsonKey(name: 'is_captain') this.isCaptain = false, @JsonKey(name: 'is_keeper') this.isKeeper = false, @JsonKey(name: 'is_substitute') this.isSubstitute = false, this.source = 'team_snapshot', @JsonKey(includeToJson: false) final  Map<String, dynamic>? profile, @JsonKey(includeToJson: false) final  Map<String, dynamic>? unclaimed}): _profile = profile,_unclaimed = unclaimed,super._();
  

@override@JsonKey(name: 'match_player_id') final  String matchPlayerId;
@override@JsonKey(name: 'match_id') final  String matchId;
@override@JsonKey(name: 'team_side') final  String teamSide;
@override@JsonKey(name: 'profile_id') final  String? profileId;
@override@JsonKey(name: 'unclaimed_id') final  String? unclaimedId;
@override@JsonKey(name: 'batting_order') final  int? battingOrder;
@override@JsonKey(name: 'jersey_number') final  int? jerseyNumber;
@override@JsonKey(name: 'is_captain') final  bool isCaptain;
@override@JsonKey(name: 'is_keeper') final  bool isKeeper;
@override@JsonKey(name: 'is_substitute') final  bool isSubstitute;
@override@JsonKey() final  String source;
 final  Map<String, dynamic>? _profile;
@override@JsonKey(includeToJson: false) Map<String, dynamic>? get profile {
  final value = _profile;
  if (value == null) return null;
  if (_profile is EqualUnmodifiableMapView) return _profile;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _unclaimed;
@override@JsonKey(includeToJson: false) Map<String, dynamic>? get unclaimed {
  final value = _unclaimed;
  if (value == null) return null;
  if (_unclaimed is EqualUnmodifiableMapView) return _unclaimed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of MatchPlayerDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchPlayerDtoCopyWith<_MatchPlayerDto> get copyWith => __$MatchPlayerDtoCopyWithImpl<_MatchPlayerDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchPlayerDto&&(identical(other.matchPlayerId, matchPlayerId) || other.matchPlayerId == matchPlayerId)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.teamSide, teamSide) || other.teamSide == teamSide)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.unclaimedId, unclaimedId) || other.unclaimedId == unclaimedId)&&(identical(other.battingOrder, battingOrder) || other.battingOrder == battingOrder)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.isCaptain, isCaptain) || other.isCaptain == isCaptain)&&(identical(other.isKeeper, isKeeper) || other.isKeeper == isKeeper)&&(identical(other.isSubstitute, isSubstitute) || other.isSubstitute == isSubstitute)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._profile, _profile)&&const DeepCollectionEquality().equals(other._unclaimed, _unclaimed));
}


@override
int get hashCode => Object.hash(runtimeType,matchPlayerId,matchId,teamSide,profileId,unclaimedId,battingOrder,jerseyNumber,isCaptain,isKeeper,isSubstitute,source,const DeepCollectionEquality().hash(_profile),const DeepCollectionEquality().hash(_unclaimed));

@override
String toString() {
  return 'MatchPlayerDto(matchPlayerId: $matchPlayerId, matchId: $matchId, teamSide: $teamSide, profileId: $profileId, unclaimedId: $unclaimedId, battingOrder: $battingOrder, jerseyNumber: $jerseyNumber, isCaptain: $isCaptain, isKeeper: $isKeeper, isSubstitute: $isSubstitute, source: $source, profile: $profile, unclaimed: $unclaimed)';
}


}

/// @nodoc
abstract mixin class _$MatchPlayerDtoCopyWith<$Res> implements $MatchPlayerDtoCopyWith<$Res> {
  factory _$MatchPlayerDtoCopyWith(_MatchPlayerDto value, $Res Function(_MatchPlayerDto) _then) = __$MatchPlayerDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'match_player_id') String matchPlayerId,@JsonKey(name: 'match_id') String matchId,@JsonKey(name: 'team_side') String teamSide,@JsonKey(name: 'profile_id') String? profileId,@JsonKey(name: 'unclaimed_id') String? unclaimedId,@JsonKey(name: 'batting_order') int? battingOrder,@JsonKey(name: 'jersey_number') int? jerseyNumber,@JsonKey(name: 'is_captain') bool isCaptain,@JsonKey(name: 'is_keeper') bool isKeeper,@JsonKey(name: 'is_substitute') bool isSubstitute, String source,@JsonKey(includeToJson: false) Map<String, dynamic>? profile,@JsonKey(includeToJson: false) Map<String, dynamic>? unclaimed
});




}
/// @nodoc
class __$MatchPlayerDtoCopyWithImpl<$Res>
    implements _$MatchPlayerDtoCopyWith<$Res> {
  __$MatchPlayerDtoCopyWithImpl(this._self, this._then);

  final _MatchPlayerDto _self;
  final $Res Function(_MatchPlayerDto) _then;

/// Create a copy of MatchPlayerDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchPlayerId = null,Object? matchId = null,Object? teamSide = null,Object? profileId = freezed,Object? unclaimedId = freezed,Object? battingOrder = freezed,Object? jerseyNumber = freezed,Object? isCaptain = null,Object? isKeeper = null,Object? isSubstitute = null,Object? source = null,Object? profile = freezed,Object? unclaimed = freezed,}) {
  return _then(_MatchPlayerDto(
matchPlayerId: null == matchPlayerId ? _self.matchPlayerId : matchPlayerId // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,teamSide: null == teamSide ? _self.teamSide : teamSide // ignore: cast_nullable_to_non_nullable
as String,profileId: freezed == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String?,unclaimedId: freezed == unclaimedId ? _self.unclaimedId : unclaimedId // ignore: cast_nullable_to_non_nullable
as String?,battingOrder: freezed == battingOrder ? _self.battingOrder : battingOrder // ignore: cast_nullable_to_non_nullable
as int?,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int?,isCaptain: null == isCaptain ? _self.isCaptain : isCaptain // ignore: cast_nullable_to_non_nullable
as bool,isKeeper: null == isKeeper ? _self.isKeeper : isKeeper // ignore: cast_nullable_to_non_nullable
as bool,isSubstitute: null == isSubstitute ? _self.isSubstitute : isSubstitute // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,profile: freezed == profile ? _self._profile : profile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,unclaimed: freezed == unclaimed ? _self._unclaimed : unclaimed // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
