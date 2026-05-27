// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_unclaimed_player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddUnclaimedPlayerState {

 AddUnclaimedPlayerStep get step; String get name; String get jersey; PlayingRole? get playingRole; BattingStyle? get battingStyle; BowlingStyle? get bowlingStyle; bool get submitting; String? get submitError;
/// Create a copy of AddUnclaimedPlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddUnclaimedPlayerStateCopyWith<AddUnclaimedPlayerState> get copyWith => _$AddUnclaimedPlayerStateCopyWithImpl<AddUnclaimedPlayerState>(this as AddUnclaimedPlayerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddUnclaimedPlayerState&&(identical(other.step, step) || other.step == step)&&(identical(other.name, name) || other.name == name)&&(identical(other.jersey, jersey) || other.jersey == jersey)&&(identical(other.playingRole, playingRole) || other.playingRole == playingRole)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError));
}


@override
int get hashCode => Object.hash(runtimeType,step,name,jersey,playingRole,battingStyle,bowlingStyle,submitting,submitError);

@override
String toString() {
  return 'AddUnclaimedPlayerState(step: $step, name: $name, jersey: $jersey, playingRole: $playingRole, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, submitting: $submitting, submitError: $submitError)';
}


}

/// @nodoc
abstract mixin class $AddUnclaimedPlayerStateCopyWith<$Res>  {
  factory $AddUnclaimedPlayerStateCopyWith(AddUnclaimedPlayerState value, $Res Function(AddUnclaimedPlayerState) _then) = _$AddUnclaimedPlayerStateCopyWithImpl;
@useResult
$Res call({
 AddUnclaimedPlayerStep step, String name, String jersey, PlayingRole? playingRole, BattingStyle? battingStyle, BowlingStyle? bowlingStyle, bool submitting, String? submitError
});




}
/// @nodoc
class _$AddUnclaimedPlayerStateCopyWithImpl<$Res>
    implements $AddUnclaimedPlayerStateCopyWith<$Res> {
  _$AddUnclaimedPlayerStateCopyWithImpl(this._self, this._then);

  final AddUnclaimedPlayerState _self;
  final $Res Function(AddUnclaimedPlayerState) _then;

/// Create a copy of AddUnclaimedPlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? name = null,Object? jersey = null,Object? playingRole = freezed,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? submitting = null,Object? submitError = freezed,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as AddUnclaimedPlayerStep,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,jersey: null == jersey ? _self.jersey : jersey // ignore: cast_nullable_to_non_nullable
as String,playingRole: freezed == playingRole ? _self.playingRole : playingRole // ignore: cast_nullable_to_non_nullable
as PlayingRole?,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as BattingStyle?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as BowlingStyle?,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AddUnclaimedPlayerState].
extension AddUnclaimedPlayerStatePatterns on AddUnclaimedPlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddUnclaimedPlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddUnclaimedPlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddUnclaimedPlayerState value)  $default,){
final _that = this;
switch (_that) {
case _AddUnclaimedPlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddUnclaimedPlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _AddUnclaimedPlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AddUnclaimedPlayerStep step,  String name,  String jersey,  PlayingRole? playingRole,  BattingStyle? battingStyle,  BowlingStyle? bowlingStyle,  bool submitting,  String? submitError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddUnclaimedPlayerState() when $default != null:
return $default(_that.step,_that.name,_that.jersey,_that.playingRole,_that.battingStyle,_that.bowlingStyle,_that.submitting,_that.submitError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AddUnclaimedPlayerStep step,  String name,  String jersey,  PlayingRole? playingRole,  BattingStyle? battingStyle,  BowlingStyle? bowlingStyle,  bool submitting,  String? submitError)  $default,) {final _that = this;
switch (_that) {
case _AddUnclaimedPlayerState():
return $default(_that.step,_that.name,_that.jersey,_that.playingRole,_that.battingStyle,_that.bowlingStyle,_that.submitting,_that.submitError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AddUnclaimedPlayerStep step,  String name,  String jersey,  PlayingRole? playingRole,  BattingStyle? battingStyle,  BowlingStyle? bowlingStyle,  bool submitting,  String? submitError)?  $default,) {final _that = this;
switch (_that) {
case _AddUnclaimedPlayerState() when $default != null:
return $default(_that.step,_that.name,_that.jersey,_that.playingRole,_that.battingStyle,_that.bowlingStyle,_that.submitting,_that.submitError);case _:
  return null;

}
}

}

/// @nodoc


class _AddUnclaimedPlayerState extends AddUnclaimedPlayerState {
  const _AddUnclaimedPlayerState({this.step = AddUnclaimedPlayerStep.name, this.name = '', this.jersey = '', this.playingRole, this.battingStyle, this.bowlingStyle, this.submitting = false, this.submitError}): super._();
  

@override@JsonKey() final  AddUnclaimedPlayerStep step;
@override@JsonKey() final  String name;
@override@JsonKey() final  String jersey;
@override final  PlayingRole? playingRole;
@override final  BattingStyle? battingStyle;
@override final  BowlingStyle? bowlingStyle;
@override@JsonKey() final  bool submitting;
@override final  String? submitError;

/// Create a copy of AddUnclaimedPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddUnclaimedPlayerStateCopyWith<_AddUnclaimedPlayerState> get copyWith => __$AddUnclaimedPlayerStateCopyWithImpl<_AddUnclaimedPlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddUnclaimedPlayerState&&(identical(other.step, step) || other.step == step)&&(identical(other.name, name) || other.name == name)&&(identical(other.jersey, jersey) || other.jersey == jersey)&&(identical(other.playingRole, playingRole) || other.playingRole == playingRole)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError));
}


@override
int get hashCode => Object.hash(runtimeType,step,name,jersey,playingRole,battingStyle,bowlingStyle,submitting,submitError);

@override
String toString() {
  return 'AddUnclaimedPlayerState(step: $step, name: $name, jersey: $jersey, playingRole: $playingRole, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, submitting: $submitting, submitError: $submitError)';
}


}

/// @nodoc
abstract mixin class _$AddUnclaimedPlayerStateCopyWith<$Res> implements $AddUnclaimedPlayerStateCopyWith<$Res> {
  factory _$AddUnclaimedPlayerStateCopyWith(_AddUnclaimedPlayerState value, $Res Function(_AddUnclaimedPlayerState) _then) = __$AddUnclaimedPlayerStateCopyWithImpl;
@override @useResult
$Res call({
 AddUnclaimedPlayerStep step, String name, String jersey, PlayingRole? playingRole, BattingStyle? battingStyle, BowlingStyle? bowlingStyle, bool submitting, String? submitError
});




}
/// @nodoc
class __$AddUnclaimedPlayerStateCopyWithImpl<$Res>
    implements _$AddUnclaimedPlayerStateCopyWith<$Res> {
  __$AddUnclaimedPlayerStateCopyWithImpl(this._self, this._then);

  final _AddUnclaimedPlayerState _self;
  final $Res Function(_AddUnclaimedPlayerState) _then;

/// Create a copy of AddUnclaimedPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? name = null,Object? jersey = null,Object? playingRole = freezed,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? submitting = null,Object? submitError = freezed,}) {
  return _then(_AddUnclaimedPlayerState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as AddUnclaimedPlayerStep,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,jersey: null == jersey ? _self.jersey : jersey // ignore: cast_nullable_to_non_nullable
as String,playingRole: freezed == playingRole ? _self.playingRole : playingRole // ignore: cast_nullable_to_non_nullable
as PlayingRole?,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as BattingStyle?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as BowlingStyle?,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
