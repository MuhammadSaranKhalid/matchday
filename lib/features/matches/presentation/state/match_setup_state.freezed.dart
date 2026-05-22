// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_setup_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchSetupState {

 MatchSetupStep get step; String? get opponentId; String? get opponentName; int get overs; int get playersPerTeam; MatchBallType get ballType; int get maxOversPerBowler; DateTime? get when; String get venueGround; String get venueCity; Set<String> get selectedPlayers; String? get captainId; String? get keeperId; bool get submitting; String? get submitError; String? get createdMatchId;
/// Create a copy of MatchSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchSetupStateCopyWith<MatchSetupState> get copyWith => _$MatchSetupStateCopyWithImpl<MatchSetupState>(this as MatchSetupState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchSetupState&&(identical(other.step, step) || other.step == step)&&(identical(other.opponentId, opponentId) || other.opponentId == opponentId)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName)&&(identical(other.overs, overs) || other.overs == overs)&&(identical(other.playersPerTeam, playersPerTeam) || other.playersPerTeam == playersPerTeam)&&(identical(other.ballType, ballType) || other.ballType == ballType)&&(identical(other.maxOversPerBowler, maxOversPerBowler) || other.maxOversPerBowler == maxOversPerBowler)&&(identical(other.when, when) || other.when == when)&&(identical(other.venueGround, venueGround) || other.venueGround == venueGround)&&(identical(other.venueCity, venueCity) || other.venueCity == venueCity)&&const DeepCollectionEquality().equals(other.selectedPlayers, selectedPlayers)&&(identical(other.captainId, captainId) || other.captainId == captainId)&&(identical(other.keeperId, keeperId) || other.keeperId == keeperId)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.createdMatchId, createdMatchId) || other.createdMatchId == createdMatchId));
}


@override
int get hashCode => Object.hash(runtimeType,step,opponentId,opponentName,overs,playersPerTeam,ballType,maxOversPerBowler,when,venueGround,venueCity,const DeepCollectionEquality().hash(selectedPlayers),captainId,keeperId,submitting,submitError,createdMatchId);

@override
String toString() {
  return 'MatchSetupState(step: $step, opponentId: $opponentId, opponentName: $opponentName, overs: $overs, playersPerTeam: $playersPerTeam, ballType: $ballType, maxOversPerBowler: $maxOversPerBowler, when: $when, venueGround: $venueGround, venueCity: $venueCity, selectedPlayers: $selectedPlayers, captainId: $captainId, keeperId: $keeperId, submitting: $submitting, submitError: $submitError, createdMatchId: $createdMatchId)';
}


}

/// @nodoc
abstract mixin class $MatchSetupStateCopyWith<$Res>  {
  factory $MatchSetupStateCopyWith(MatchSetupState value, $Res Function(MatchSetupState) _then) = _$MatchSetupStateCopyWithImpl;
@useResult
$Res call({
 MatchSetupStep step, String? opponentId, String? opponentName, int overs, int playersPerTeam, MatchBallType ballType, int maxOversPerBowler, DateTime? when, String venueGround, String venueCity, Set<String> selectedPlayers, String? captainId, String? keeperId, bool submitting, String? submitError, String? createdMatchId
});




}
/// @nodoc
class _$MatchSetupStateCopyWithImpl<$Res>
    implements $MatchSetupStateCopyWith<$Res> {
  _$MatchSetupStateCopyWithImpl(this._self, this._then);

  final MatchSetupState _self;
  final $Res Function(MatchSetupState) _then;

/// Create a copy of MatchSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? opponentId = freezed,Object? opponentName = freezed,Object? overs = null,Object? playersPerTeam = null,Object? ballType = null,Object? maxOversPerBowler = null,Object? when = freezed,Object? venueGround = null,Object? venueCity = null,Object? selectedPlayers = null,Object? captainId = freezed,Object? keeperId = freezed,Object? submitting = null,Object? submitError = freezed,Object? createdMatchId = freezed,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as MatchSetupStep,opponentId: freezed == opponentId ? _self.opponentId : opponentId // ignore: cast_nullable_to_non_nullable
as String?,opponentName: freezed == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String?,overs: null == overs ? _self.overs : overs // ignore: cast_nullable_to_non_nullable
as int,playersPerTeam: null == playersPerTeam ? _self.playersPerTeam : playersPerTeam // ignore: cast_nullable_to_non_nullable
as int,ballType: null == ballType ? _self.ballType : ballType // ignore: cast_nullable_to_non_nullable
as MatchBallType,maxOversPerBowler: null == maxOversPerBowler ? _self.maxOversPerBowler : maxOversPerBowler // ignore: cast_nullable_to_non_nullable
as int,when: freezed == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as DateTime?,venueGround: null == venueGround ? _self.venueGround : venueGround // ignore: cast_nullable_to_non_nullable
as String,venueCity: null == venueCity ? _self.venueCity : venueCity // ignore: cast_nullable_to_non_nullable
as String,selectedPlayers: null == selectedPlayers ? _self.selectedPlayers : selectedPlayers // ignore: cast_nullable_to_non_nullable
as Set<String>,captainId: freezed == captainId ? _self.captainId : captainId // ignore: cast_nullable_to_non_nullable
as String?,keeperId: freezed == keeperId ? _self.keeperId : keeperId // ignore: cast_nullable_to_non_nullable
as String?,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,createdMatchId: freezed == createdMatchId ? _self.createdMatchId : createdMatchId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchSetupState].
extension MatchSetupStatePatterns on MatchSetupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchSetupState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchSetupState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchSetupState value)  $default,){
final _that = this;
switch (_that) {
case _MatchSetupState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchSetupState value)?  $default,){
final _that = this;
switch (_that) {
case _MatchSetupState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MatchSetupStep step,  String? opponentId,  String? opponentName,  int overs,  int playersPerTeam,  MatchBallType ballType,  int maxOversPerBowler,  DateTime? when,  String venueGround,  String venueCity,  Set<String> selectedPlayers,  String? captainId,  String? keeperId,  bool submitting,  String? submitError,  String? createdMatchId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchSetupState() when $default != null:
return $default(_that.step,_that.opponentId,_that.opponentName,_that.overs,_that.playersPerTeam,_that.ballType,_that.maxOversPerBowler,_that.when,_that.venueGround,_that.venueCity,_that.selectedPlayers,_that.captainId,_that.keeperId,_that.submitting,_that.submitError,_that.createdMatchId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MatchSetupStep step,  String? opponentId,  String? opponentName,  int overs,  int playersPerTeam,  MatchBallType ballType,  int maxOversPerBowler,  DateTime? when,  String venueGround,  String venueCity,  Set<String> selectedPlayers,  String? captainId,  String? keeperId,  bool submitting,  String? submitError,  String? createdMatchId)  $default,) {final _that = this;
switch (_that) {
case _MatchSetupState():
return $default(_that.step,_that.opponentId,_that.opponentName,_that.overs,_that.playersPerTeam,_that.ballType,_that.maxOversPerBowler,_that.when,_that.venueGround,_that.venueCity,_that.selectedPlayers,_that.captainId,_that.keeperId,_that.submitting,_that.submitError,_that.createdMatchId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MatchSetupStep step,  String? opponentId,  String? opponentName,  int overs,  int playersPerTeam,  MatchBallType ballType,  int maxOversPerBowler,  DateTime? when,  String venueGround,  String venueCity,  Set<String> selectedPlayers,  String? captainId,  String? keeperId,  bool submitting,  String? submitError,  String? createdMatchId)?  $default,) {final _that = this;
switch (_that) {
case _MatchSetupState() when $default != null:
return $default(_that.step,_that.opponentId,_that.opponentName,_that.overs,_that.playersPerTeam,_that.ballType,_that.maxOversPerBowler,_that.when,_that.venueGround,_that.venueCity,_that.selectedPlayers,_that.captainId,_that.keeperId,_that.submitting,_that.submitError,_that.createdMatchId);case _:
  return null;

}
}

}

/// @nodoc


class _MatchSetupState extends MatchSetupState {
  const _MatchSetupState({this.step = MatchSetupStep.type, this.opponentId, this.opponentName, this.overs = 20, this.playersPerTeam = 11, this.ballType = MatchBallType.tape, this.maxOversPerBowler = 4, this.when, this.venueGround = '', this.venueCity = '', final  Set<String> selectedPlayers = const <String>{}, this.captainId, this.keeperId, this.submitting = false, this.submitError, this.createdMatchId}): _selectedPlayers = selectedPlayers,super._();
  

@override@JsonKey() final  MatchSetupStep step;
@override final  String? opponentId;
@override final  String? opponentName;
@override@JsonKey() final  int overs;
@override@JsonKey() final  int playersPerTeam;
@override@JsonKey() final  MatchBallType ballType;
@override@JsonKey() final  int maxOversPerBowler;
@override final  DateTime? when;
@override@JsonKey() final  String venueGround;
@override@JsonKey() final  String venueCity;
 final  Set<String> _selectedPlayers;
@override@JsonKey() Set<String> get selectedPlayers {
  if (_selectedPlayers is EqualUnmodifiableSetView) return _selectedPlayers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedPlayers);
}

@override final  String? captainId;
@override final  String? keeperId;
@override@JsonKey() final  bool submitting;
@override final  String? submitError;
@override final  String? createdMatchId;

/// Create a copy of MatchSetupState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchSetupStateCopyWith<_MatchSetupState> get copyWith => __$MatchSetupStateCopyWithImpl<_MatchSetupState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchSetupState&&(identical(other.step, step) || other.step == step)&&(identical(other.opponentId, opponentId) || other.opponentId == opponentId)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName)&&(identical(other.overs, overs) || other.overs == overs)&&(identical(other.playersPerTeam, playersPerTeam) || other.playersPerTeam == playersPerTeam)&&(identical(other.ballType, ballType) || other.ballType == ballType)&&(identical(other.maxOversPerBowler, maxOversPerBowler) || other.maxOversPerBowler == maxOversPerBowler)&&(identical(other.when, when) || other.when == when)&&(identical(other.venueGround, venueGround) || other.venueGround == venueGround)&&(identical(other.venueCity, venueCity) || other.venueCity == venueCity)&&const DeepCollectionEquality().equals(other._selectedPlayers, _selectedPlayers)&&(identical(other.captainId, captainId) || other.captainId == captainId)&&(identical(other.keeperId, keeperId) || other.keeperId == keeperId)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.createdMatchId, createdMatchId) || other.createdMatchId == createdMatchId));
}


@override
int get hashCode => Object.hash(runtimeType,step,opponentId,opponentName,overs,playersPerTeam,ballType,maxOversPerBowler,when,venueGround,venueCity,const DeepCollectionEquality().hash(_selectedPlayers),captainId,keeperId,submitting,submitError,createdMatchId);

@override
String toString() {
  return 'MatchSetupState(step: $step, opponentId: $opponentId, opponentName: $opponentName, overs: $overs, playersPerTeam: $playersPerTeam, ballType: $ballType, maxOversPerBowler: $maxOversPerBowler, when: $when, venueGround: $venueGround, venueCity: $venueCity, selectedPlayers: $selectedPlayers, captainId: $captainId, keeperId: $keeperId, submitting: $submitting, submitError: $submitError, createdMatchId: $createdMatchId)';
}


}

/// @nodoc
abstract mixin class _$MatchSetupStateCopyWith<$Res> implements $MatchSetupStateCopyWith<$Res> {
  factory _$MatchSetupStateCopyWith(_MatchSetupState value, $Res Function(_MatchSetupState) _then) = __$MatchSetupStateCopyWithImpl;
@override @useResult
$Res call({
 MatchSetupStep step, String? opponentId, String? opponentName, int overs, int playersPerTeam, MatchBallType ballType, int maxOversPerBowler, DateTime? when, String venueGround, String venueCity, Set<String> selectedPlayers, String? captainId, String? keeperId, bool submitting, String? submitError, String? createdMatchId
});




}
/// @nodoc
class __$MatchSetupStateCopyWithImpl<$Res>
    implements _$MatchSetupStateCopyWith<$Res> {
  __$MatchSetupStateCopyWithImpl(this._self, this._then);

  final _MatchSetupState _self;
  final $Res Function(_MatchSetupState) _then;

/// Create a copy of MatchSetupState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? opponentId = freezed,Object? opponentName = freezed,Object? overs = null,Object? playersPerTeam = null,Object? ballType = null,Object? maxOversPerBowler = null,Object? when = freezed,Object? venueGround = null,Object? venueCity = null,Object? selectedPlayers = null,Object? captainId = freezed,Object? keeperId = freezed,Object? submitting = null,Object? submitError = freezed,Object? createdMatchId = freezed,}) {
  return _then(_MatchSetupState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as MatchSetupStep,opponentId: freezed == opponentId ? _self.opponentId : opponentId // ignore: cast_nullable_to_non_nullable
as String?,opponentName: freezed == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String?,overs: null == overs ? _self.overs : overs // ignore: cast_nullable_to_non_nullable
as int,playersPerTeam: null == playersPerTeam ? _self.playersPerTeam : playersPerTeam // ignore: cast_nullable_to_non_nullable
as int,ballType: null == ballType ? _self.ballType : ballType // ignore: cast_nullable_to_non_nullable
as MatchBallType,maxOversPerBowler: null == maxOversPerBowler ? _self.maxOversPerBowler : maxOversPerBowler // ignore: cast_nullable_to_non_nullable
as int,when: freezed == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as DateTime?,venueGround: null == venueGround ? _self.venueGround : venueGround // ignore: cast_nullable_to_non_nullable
as String,venueCity: null == venueCity ? _self.venueCity : venueCity // ignore: cast_nullable_to_non_nullable
as String,selectedPlayers: null == selectedPlayers ? _self._selectedPlayers : selectedPlayers // ignore: cast_nullable_to_non_nullable
as Set<String>,captainId: freezed == captainId ? _self.captainId : captainId // ignore: cast_nullable_to_non_nullable
as String?,keeperId: freezed == keeperId ? _self.keeperId : keeperId // ignore: cast_nullable_to_non_nullable
as String?,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,createdMatchId: freezed == createdMatchId ? _self.createdMatchId : createdMatchId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
