// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {

 OnboardingStep get step;// Identity fields
 String get displayName; String? get avatarPath;// Local file path selected via image_picker
// Google can provide a photo before the user has selected a local file.
// The local file, when present, always takes precedence.
 String? get remoteAvatarUrl;// Username fields
 String get username; UsernameStatus get usernameStatus; String? get usernameMessage;// Form fields
 bool get submitting; String? get submitError; bool get completed;
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateCopyWith<OnboardingState> get copyWith => _$OnboardingStateCopyWithImpl<OnboardingState>(this as OnboardingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState&&(identical(other.step, step) || other.step == step)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarPath, avatarPath) || other.avatarPath == avatarPath)&&(identical(other.remoteAvatarUrl, remoteAvatarUrl) || other.remoteAvatarUrl == remoteAvatarUrl)&&(identical(other.username, username) || other.username == username)&&(identical(other.usernameStatus, usernameStatus) || other.usernameStatus == usernameStatus)&&(identical(other.usernameMessage, usernameMessage) || other.usernameMessage == usernameMessage)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.completed, completed) || other.completed == completed));
}


@override
int get hashCode => Object.hash(runtimeType,step,displayName,avatarPath,remoteAvatarUrl,username,usernameStatus,usernameMessage,submitting,submitError,completed);

@override
String toString() {
  return 'OnboardingState(step: $step, displayName: $displayName, avatarPath: $avatarPath, remoteAvatarUrl: $remoteAvatarUrl, username: $username, usernameStatus: $usernameStatus, usernameMessage: $usernameMessage, submitting: $submitting, submitError: $submitError, completed: $completed)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res>  {
  factory $OnboardingStateCopyWith(OnboardingState value, $Res Function(OnboardingState) _then) = _$OnboardingStateCopyWithImpl;
@useResult
$Res call({
 OnboardingStep step, String displayName, String? avatarPath, String? remoteAvatarUrl, String username, UsernameStatus usernameStatus, String? usernameMessage, bool submitting, String? submitError, bool completed
});




}
/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._self, this._then);

  final OnboardingState _self;
  final $Res Function(OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? displayName = null,Object? avatarPath = freezed,Object? remoteAvatarUrl = freezed,Object? username = null,Object? usernameStatus = null,Object? usernameMessage = freezed,Object? submitting = null,Object? submitError = freezed,Object? completed = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarPath: freezed == avatarPath ? _self.avatarPath : avatarPath // ignore: cast_nullable_to_non_nullable
as String?,remoteAvatarUrl: freezed == remoteAvatarUrl ? _self.remoteAvatarUrl : remoteAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
as UsernameStatus,usernameMessage: freezed == usernameMessage ? _self.usernameMessage : usernameMessage // ignore: cast_nullable_to_non_nullable
as String?,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OnboardingStep step,  String displayName,  String? avatarPath,  String? remoteAvatarUrl,  String username,  UsernameStatus usernameStatus,  String? usernameMessage,  bool submitting,  String? submitError,  bool completed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.step,_that.displayName,_that.avatarPath,_that.remoteAvatarUrl,_that.username,_that.usernameStatus,_that.usernameMessage,_that.submitting,_that.submitError,_that.completed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OnboardingStep step,  String displayName,  String? avatarPath,  String? remoteAvatarUrl,  String username,  UsernameStatus usernameStatus,  String? usernameMessage,  bool submitting,  String? submitError,  bool completed)  $default,) {final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that.step,_that.displayName,_that.avatarPath,_that.remoteAvatarUrl,_that.username,_that.usernameStatus,_that.usernameMessage,_that.submitting,_that.submitError,_that.completed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OnboardingStep step,  String displayName,  String? avatarPath,  String? remoteAvatarUrl,  String username,  UsernameStatus usernameStatus,  String? usernameMessage,  bool submitting,  String? submitError,  bool completed)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.step,_that.displayName,_that.avatarPath,_that.remoteAvatarUrl,_that.username,_that.usernameStatus,_that.usernameMessage,_that.submitting,_that.submitError,_that.completed);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingState extends OnboardingState {
  const _OnboardingState({this.step = OnboardingStep.identity, this.displayName = '', this.avatarPath, this.remoteAvatarUrl, this.username = '', this.usernameStatus = UsernameStatus.idle, this.usernameMessage, this.submitting = false, this.submitError, this.completed = false}): super._();
  

@override@JsonKey() final  OnboardingStep step;
// Identity fields
@override@JsonKey() final  String displayName;
@override final  String? avatarPath;
// Local file path selected via image_picker
// Google can provide a photo before the user has selected a local file.
// The local file, when present, always takes precedence.
@override final  String? remoteAvatarUrl;
// Username fields
@override@JsonKey() final  String username;
@override@JsonKey() final  UsernameStatus usernameStatus;
@override final  String? usernameMessage;
// Form fields
@override@JsonKey() final  bool submitting;
@override final  String? submitError;
@override@JsonKey() final  bool completed;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingStateCopyWith<_OnboardingState> get copyWith => __$OnboardingStateCopyWithImpl<_OnboardingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingState&&(identical(other.step, step) || other.step == step)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarPath, avatarPath) || other.avatarPath == avatarPath)&&(identical(other.remoteAvatarUrl, remoteAvatarUrl) || other.remoteAvatarUrl == remoteAvatarUrl)&&(identical(other.username, username) || other.username == username)&&(identical(other.usernameStatus, usernameStatus) || other.usernameStatus == usernameStatus)&&(identical(other.usernameMessage, usernameMessage) || other.usernameMessage == usernameMessage)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.completed, completed) || other.completed == completed));
}


@override
int get hashCode => Object.hash(runtimeType,step,displayName,avatarPath,remoteAvatarUrl,username,usernameStatus,usernameMessage,submitting,submitError,completed);

@override
String toString() {
  return 'OnboardingState(step: $step, displayName: $displayName, avatarPath: $avatarPath, remoteAvatarUrl: $remoteAvatarUrl, username: $username, usernameStatus: $usernameStatus, usernameMessage: $usernameMessage, submitting: $submitting, submitError: $submitError, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(_OnboardingState value, $Res Function(_OnboardingState) _then) = __$OnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 OnboardingStep step, String displayName, String? avatarPath, String? remoteAvatarUrl, String username, UsernameStatus usernameStatus, String? usernameMessage, bool submitting, String? submitError, bool completed
});




}
/// @nodoc
class __$OnboardingStateCopyWithImpl<$Res>
    implements _$OnboardingStateCopyWith<$Res> {
  __$OnboardingStateCopyWithImpl(this._self, this._then);

  final _OnboardingState _self;
  final $Res Function(_OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? displayName = null,Object? avatarPath = freezed,Object? remoteAvatarUrl = freezed,Object? username = null,Object? usernameStatus = null,Object? usernameMessage = freezed,Object? submitting = null,Object? submitError = freezed,Object? completed = null,}) {
  return _then(_OnboardingState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarPath: freezed == avatarPath ? _self.avatarPath : avatarPath // ignore: cast_nullable_to_non_nullable
as String?,remoteAvatarUrl: freezed == remoteAvatarUrl ? _self.remoteAvatarUrl : remoteAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
as UsernameStatus,usernameMessage: freezed == usernameMessage ? _self.usernameMessage : usernameMessage // ignore: cast_nullable_to_non_nullable
as String?,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
