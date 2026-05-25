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

 OnboardingStep get step; String get displayName; String get username; String get city;// Structured geo for the chosen location. Null when the user hand-typed a
// place that couldn't be resolved (the rare uncovered-village case).
 String? get placeId; double? get lat; double? get lng; String? get countryCode;// Transient autocomplete UI state (not persisted in the draft).
 List<PlaceSuggestion> get citySuggestions; bool get citySearching; bool get locating; bool get resolvingLocation; String? get cityError; String? get citySessionToken; bool get isPlayer; PlayerRole? get role; BattingStyle? get battingStyle; BowlingStyle? get bowlingStyle; BallType? get preferredBall; UsernameStatus get usernameStatus; String? get usernameMessage; bool get submitting; String? get submitError; bool get completed;
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateCopyWith<OnboardingState> get copyWith => _$OnboardingStateCopyWithImpl<OnboardingState>(this as OnboardingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState&&(identical(other.step, step) || other.step == step)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.city, city) || other.city == city)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&const DeepCollectionEquality().equals(other.citySuggestions, citySuggestions)&&(identical(other.citySearching, citySearching) || other.citySearching == citySearching)&&(identical(other.locating, locating) || other.locating == locating)&&(identical(other.resolvingLocation, resolvingLocation) || other.resolvingLocation == resolvingLocation)&&(identical(other.cityError, cityError) || other.cityError == cityError)&&(identical(other.citySessionToken, citySessionToken) || other.citySessionToken == citySessionToken)&&(identical(other.isPlayer, isPlayer) || other.isPlayer == isPlayer)&&(identical(other.role, role) || other.role == role)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.preferredBall, preferredBall) || other.preferredBall == preferredBall)&&(identical(other.usernameStatus, usernameStatus) || other.usernameStatus == usernameStatus)&&(identical(other.usernameMessage, usernameMessage) || other.usernameMessage == usernameMessage)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.completed, completed) || other.completed == completed));
}


@override
int get hashCode => Object.hashAll([runtimeType,step,displayName,username,city,placeId,lat,lng,countryCode,const DeepCollectionEquality().hash(citySuggestions),citySearching,locating,resolvingLocation,cityError,citySessionToken,isPlayer,role,battingStyle,bowlingStyle,preferredBall,usernameStatus,usernameMessage,submitting,submitError,completed]);

@override
String toString() {
  return 'OnboardingState(step: $step, displayName: $displayName, username: $username, city: $city, placeId: $placeId, lat: $lat, lng: $lng, countryCode: $countryCode, citySuggestions: $citySuggestions, citySearching: $citySearching, locating: $locating, resolvingLocation: $resolvingLocation, cityError: $cityError, citySessionToken: $citySessionToken, isPlayer: $isPlayer, role: $role, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, preferredBall: $preferredBall, usernameStatus: $usernameStatus, usernameMessage: $usernameMessage, submitting: $submitting, submitError: $submitError, completed: $completed)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res>  {
  factory $OnboardingStateCopyWith(OnboardingState value, $Res Function(OnboardingState) _then) = _$OnboardingStateCopyWithImpl;
@useResult
$Res call({
 OnboardingStep step, String displayName, String username, String city, String? placeId, double? lat, double? lng, String? countryCode, List<PlaceSuggestion> citySuggestions, bool citySearching, bool locating, bool resolvingLocation, String? cityError, String? citySessionToken, bool isPlayer, PlayerRole? role, BattingStyle? battingStyle, BowlingStyle? bowlingStyle, BallType? preferredBall, UsernameStatus usernameStatus, String? usernameMessage, bool submitting, String? submitError, bool completed
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
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? displayName = null,Object? username = null,Object? city = null,Object? placeId = freezed,Object? lat = freezed,Object? lng = freezed,Object? countryCode = freezed,Object? citySuggestions = null,Object? citySearching = null,Object? locating = null,Object? resolvingLocation = null,Object? cityError = freezed,Object? citySessionToken = freezed,Object? isPlayer = null,Object? role = freezed,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? preferredBall = freezed,Object? usernameStatus = null,Object? usernameMessage = freezed,Object? submitting = null,Object? submitError = freezed,Object? completed = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,citySuggestions: null == citySuggestions ? _self.citySuggestions : citySuggestions // ignore: cast_nullable_to_non_nullable
as List<PlaceSuggestion>,citySearching: null == citySearching ? _self.citySearching : citySearching // ignore: cast_nullable_to_non_nullable
as bool,locating: null == locating ? _self.locating : locating // ignore: cast_nullable_to_non_nullable
as bool,resolvingLocation: null == resolvingLocation ? _self.resolvingLocation : resolvingLocation // ignore: cast_nullable_to_non_nullable
as bool,cityError: freezed == cityError ? _self.cityError : cityError // ignore: cast_nullable_to_non_nullable
as String?,citySessionToken: freezed == citySessionToken ? _self.citySessionToken : citySessionToken // ignore: cast_nullable_to_non_nullable
as String?,isPlayer: null == isPlayer ? _self.isPlayer : isPlayer // ignore: cast_nullable_to_non_nullable
as bool,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as PlayerRole?,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as BattingStyle?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as BowlingStyle?,preferredBall: freezed == preferredBall ? _self.preferredBall : preferredBall // ignore: cast_nullable_to_non_nullable
as BallType?,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OnboardingStep step,  String displayName,  String username,  String city,  String? placeId,  double? lat,  double? lng,  String? countryCode,  List<PlaceSuggestion> citySuggestions,  bool citySearching,  bool locating,  bool resolvingLocation,  String? cityError,  String? citySessionToken,  bool isPlayer,  PlayerRole? role,  BattingStyle? battingStyle,  BowlingStyle? bowlingStyle,  BallType? preferredBall,  UsernameStatus usernameStatus,  String? usernameMessage,  bool submitting,  String? submitError,  bool completed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.step,_that.displayName,_that.username,_that.city,_that.placeId,_that.lat,_that.lng,_that.countryCode,_that.citySuggestions,_that.citySearching,_that.locating,_that.resolvingLocation,_that.cityError,_that.citySessionToken,_that.isPlayer,_that.role,_that.battingStyle,_that.bowlingStyle,_that.preferredBall,_that.usernameStatus,_that.usernameMessage,_that.submitting,_that.submitError,_that.completed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OnboardingStep step,  String displayName,  String username,  String city,  String? placeId,  double? lat,  double? lng,  String? countryCode,  List<PlaceSuggestion> citySuggestions,  bool citySearching,  bool locating,  bool resolvingLocation,  String? cityError,  String? citySessionToken,  bool isPlayer,  PlayerRole? role,  BattingStyle? battingStyle,  BowlingStyle? bowlingStyle,  BallType? preferredBall,  UsernameStatus usernameStatus,  String? usernameMessage,  bool submitting,  String? submitError,  bool completed)  $default,) {final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that.step,_that.displayName,_that.username,_that.city,_that.placeId,_that.lat,_that.lng,_that.countryCode,_that.citySuggestions,_that.citySearching,_that.locating,_that.resolvingLocation,_that.cityError,_that.citySessionToken,_that.isPlayer,_that.role,_that.battingStyle,_that.bowlingStyle,_that.preferredBall,_that.usernameStatus,_that.usernameMessage,_that.submitting,_that.submitError,_that.completed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OnboardingStep step,  String displayName,  String username,  String city,  String? placeId,  double? lat,  double? lng,  String? countryCode,  List<PlaceSuggestion> citySuggestions,  bool citySearching,  bool locating,  bool resolvingLocation,  String? cityError,  String? citySessionToken,  bool isPlayer,  PlayerRole? role,  BattingStyle? battingStyle,  BowlingStyle? bowlingStyle,  BallType? preferredBall,  UsernameStatus usernameStatus,  String? usernameMessage,  bool submitting,  String? submitError,  bool completed)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.step,_that.displayName,_that.username,_that.city,_that.placeId,_that.lat,_that.lng,_that.countryCode,_that.citySuggestions,_that.citySearching,_that.locating,_that.resolvingLocation,_that.cityError,_that.citySessionToken,_that.isPlayer,_that.role,_that.battingStyle,_that.bowlingStyle,_that.preferredBall,_that.usernameStatus,_that.usernameMessage,_that.submitting,_that.submitError,_that.completed);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingState extends OnboardingState {
  const _OnboardingState({this.step = OnboardingStep.profile, this.displayName = '', this.username = '', this.city = '', this.placeId, this.lat, this.lng, this.countryCode, final  List<PlaceSuggestion> citySuggestions = const <PlaceSuggestion>[], this.citySearching = false, this.locating = false, this.resolvingLocation = false, this.cityError, this.citySessionToken, this.isPlayer = false, this.role, this.battingStyle, this.bowlingStyle, this.preferredBall, this.usernameStatus = UsernameStatus.idle, this.usernameMessage, this.submitting = false, this.submitError, this.completed = false}): _citySuggestions = citySuggestions,super._();
  

@override@JsonKey() final  OnboardingStep step;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String username;
@override@JsonKey() final  String city;
// Structured geo for the chosen location. Null when the user hand-typed a
// place that couldn't be resolved (the rare uncovered-village case).
@override final  String? placeId;
@override final  double? lat;
@override final  double? lng;
@override final  String? countryCode;
// Transient autocomplete UI state (not persisted in the draft).
 final  List<PlaceSuggestion> _citySuggestions;
// Transient autocomplete UI state (not persisted in the draft).
@override@JsonKey() List<PlaceSuggestion> get citySuggestions {
  if (_citySuggestions is EqualUnmodifiableListView) return _citySuggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citySuggestions);
}

@override@JsonKey() final  bool citySearching;
@override@JsonKey() final  bool locating;
@override@JsonKey() final  bool resolvingLocation;
@override final  String? cityError;
@override final  String? citySessionToken;
@override@JsonKey() final  bool isPlayer;
@override final  PlayerRole? role;
@override final  BattingStyle? battingStyle;
@override final  BowlingStyle? bowlingStyle;
@override final  BallType? preferredBall;
@override@JsonKey() final  UsernameStatus usernameStatus;
@override final  String? usernameMessage;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingState&&(identical(other.step, step) || other.step == step)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.city, city) || other.city == city)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&const DeepCollectionEquality().equals(other._citySuggestions, _citySuggestions)&&(identical(other.citySearching, citySearching) || other.citySearching == citySearching)&&(identical(other.locating, locating) || other.locating == locating)&&(identical(other.resolvingLocation, resolvingLocation) || other.resolvingLocation == resolvingLocation)&&(identical(other.cityError, cityError) || other.cityError == cityError)&&(identical(other.citySessionToken, citySessionToken) || other.citySessionToken == citySessionToken)&&(identical(other.isPlayer, isPlayer) || other.isPlayer == isPlayer)&&(identical(other.role, role) || other.role == role)&&(identical(other.battingStyle, battingStyle) || other.battingStyle == battingStyle)&&(identical(other.bowlingStyle, bowlingStyle) || other.bowlingStyle == bowlingStyle)&&(identical(other.preferredBall, preferredBall) || other.preferredBall == preferredBall)&&(identical(other.usernameStatus, usernameStatus) || other.usernameStatus == usernameStatus)&&(identical(other.usernameMessage, usernameMessage) || other.usernameMessage == usernameMessage)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.completed, completed) || other.completed == completed));
}


@override
int get hashCode => Object.hashAll([runtimeType,step,displayName,username,city,placeId,lat,lng,countryCode,const DeepCollectionEquality().hash(_citySuggestions),citySearching,locating,resolvingLocation,cityError,citySessionToken,isPlayer,role,battingStyle,bowlingStyle,preferredBall,usernameStatus,usernameMessage,submitting,submitError,completed]);

@override
String toString() {
  return 'OnboardingState(step: $step, displayName: $displayName, username: $username, city: $city, placeId: $placeId, lat: $lat, lng: $lng, countryCode: $countryCode, citySuggestions: $citySuggestions, citySearching: $citySearching, locating: $locating, resolvingLocation: $resolvingLocation, cityError: $cityError, citySessionToken: $citySessionToken, isPlayer: $isPlayer, role: $role, battingStyle: $battingStyle, bowlingStyle: $bowlingStyle, preferredBall: $preferredBall, usernameStatus: $usernameStatus, usernameMessage: $usernameMessage, submitting: $submitting, submitError: $submitError, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(_OnboardingState value, $Res Function(_OnboardingState) _then) = __$OnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 OnboardingStep step, String displayName, String username, String city, String? placeId, double? lat, double? lng, String? countryCode, List<PlaceSuggestion> citySuggestions, bool citySearching, bool locating, bool resolvingLocation, String? cityError, String? citySessionToken, bool isPlayer, PlayerRole? role, BattingStyle? battingStyle, BowlingStyle? bowlingStyle, BallType? preferredBall, UsernameStatus usernameStatus, String? usernameMessage, bool submitting, String? submitError, bool completed
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
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? displayName = null,Object? username = null,Object? city = null,Object? placeId = freezed,Object? lat = freezed,Object? lng = freezed,Object? countryCode = freezed,Object? citySuggestions = null,Object? citySearching = null,Object? locating = null,Object? resolvingLocation = null,Object? cityError = freezed,Object? citySessionToken = freezed,Object? isPlayer = null,Object? role = freezed,Object? battingStyle = freezed,Object? bowlingStyle = freezed,Object? preferredBall = freezed,Object? usernameStatus = null,Object? usernameMessage = freezed,Object? submitting = null,Object? submitError = freezed,Object? completed = null,}) {
  return _then(_OnboardingState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,citySuggestions: null == citySuggestions ? _self._citySuggestions : citySuggestions // ignore: cast_nullable_to_non_nullable
as List<PlaceSuggestion>,citySearching: null == citySearching ? _self.citySearching : citySearching // ignore: cast_nullable_to_non_nullable
as bool,locating: null == locating ? _self.locating : locating // ignore: cast_nullable_to_non_nullable
as bool,resolvingLocation: null == resolvingLocation ? _self.resolvingLocation : resolvingLocation // ignore: cast_nullable_to_non_nullable
as bool,cityError: freezed == cityError ? _self.cityError : cityError // ignore: cast_nullable_to_non_nullable
as String?,citySessionToken: freezed == citySessionToken ? _self.citySessionToken : citySessionToken // ignore: cast_nullable_to_non_nullable
as String?,isPlayer: null == isPlayer ? _self.isPlayer : isPlayer // ignore: cast_nullable_to_non_nullable
as bool,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as PlayerRole?,battingStyle: freezed == battingStyle ? _self.battingStyle : battingStyle // ignore: cast_nullable_to_non_nullable
as BattingStyle?,bowlingStyle: freezed == bowlingStyle ? _self.bowlingStyle : bowlingStyle // ignore: cast_nullable_to_non_nullable
as BowlingStyle?,preferredBall: freezed == preferredBall ? _self.preferredBall : preferredBall // ignore: cast_nullable_to_non_nullable
as BallType?,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
as UsernameStatus,usernameMessage: freezed == usernameMessage ? _self.usernameMessage : usernameMessage // ignore: cast_nullable_to_non_nullable
as String?,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
