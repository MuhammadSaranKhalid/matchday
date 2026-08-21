// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlacePickerState {

/// What the user has typed. Not necessarily a resolved place.
 String get query;/// Live predictions for [query].
 List<PlaceSuggestion> get suggestions;/// The resolved place, once a suggestion is picked or GPS returns.
/// Null while the user is still typing free text.
 GeoPlace? get picked;/// An autocomplete request is in flight.
 bool get searching;/// A place-details or GPS resolution is in flight — distinct from
/// [searching] because it blocks the field while the coordinate lands.
 bool get resolving; Failure? get error;
/// Create a copy of PlacePickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlacePickerStateCopyWith<PlacePickerState> get copyWith => _$PlacePickerStateCopyWithImpl<PlacePickerState>(this as PlacePickerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlacePickerState&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&(identical(other.picked, picked) || other.picked == picked)&&(identical(other.searching, searching) || other.searching == searching)&&(identical(other.resolving, resolving) || other.resolving == resolving)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(suggestions),picked,searching,resolving,error);

@override
String toString() {
  return 'PlacePickerState(query: $query, suggestions: $suggestions, picked: $picked, searching: $searching, resolving: $resolving, error: $error)';
}


}

/// @nodoc
abstract mixin class $PlacePickerStateCopyWith<$Res>  {
  factory $PlacePickerStateCopyWith(PlacePickerState value, $Res Function(PlacePickerState) _then) = _$PlacePickerStateCopyWithImpl;
@useResult
$Res call({
 String query, List<PlaceSuggestion> suggestions, GeoPlace? picked, bool searching, bool resolving, Failure? error
});




}
/// @nodoc
class _$PlacePickerStateCopyWithImpl<$Res>
    implements $PlacePickerStateCopyWith<$Res> {
  _$PlacePickerStateCopyWithImpl(this._self, this._then);

  final PlacePickerState _self;
  final $Res Function(PlacePickerState) _then;

/// Create a copy of PlacePickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? suggestions = null,Object? picked = freezed,Object? searching = null,Object? resolving = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<PlaceSuggestion>,picked: freezed == picked ? _self.picked : picked // ignore: cast_nullable_to_non_nullable
as GeoPlace?,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,resolving: null == resolving ? _self.resolving : resolving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlacePickerState].
extension PlacePickerStatePatterns on PlacePickerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlacePickerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlacePickerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlacePickerState value)  $default,){
final _that = this;
switch (_that) {
case _PlacePickerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlacePickerState value)?  $default,){
final _that = this;
switch (_that) {
case _PlacePickerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  List<PlaceSuggestion> suggestions,  GeoPlace? picked,  bool searching,  bool resolving,  Failure? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlacePickerState() when $default != null:
return $default(_that.query,_that.suggestions,_that.picked,_that.searching,_that.resolving,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  List<PlaceSuggestion> suggestions,  GeoPlace? picked,  bool searching,  bool resolving,  Failure? error)  $default,) {final _that = this;
switch (_that) {
case _PlacePickerState():
return $default(_that.query,_that.suggestions,_that.picked,_that.searching,_that.resolving,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  List<PlaceSuggestion> suggestions,  GeoPlace? picked,  bool searching,  bool resolving,  Failure? error)?  $default,) {final _that = this;
switch (_that) {
case _PlacePickerState() when $default != null:
return $default(_that.query,_that.suggestions,_that.picked,_that.searching,_that.resolving,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _PlacePickerState extends PlacePickerState {
  const _PlacePickerState({this.query = '', final  List<PlaceSuggestion> suggestions = const <PlaceSuggestion>[], this.picked, this.searching = false, this.resolving = false, this.error}): _suggestions = suggestions,super._();
  

/// What the user has typed. Not necessarily a resolved place.
@override@JsonKey() final  String query;
/// Live predictions for [query].
 final  List<PlaceSuggestion> _suggestions;
/// Live predictions for [query].
@override@JsonKey() List<PlaceSuggestion> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

/// The resolved place, once a suggestion is picked or GPS returns.
/// Null while the user is still typing free text.
@override final  GeoPlace? picked;
/// An autocomplete request is in flight.
@override@JsonKey() final  bool searching;
/// A place-details or GPS resolution is in flight — distinct from
/// [searching] because it blocks the field while the coordinate lands.
@override@JsonKey() final  bool resolving;
@override final  Failure? error;

/// Create a copy of PlacePickerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlacePickerStateCopyWith<_PlacePickerState> get copyWith => __$PlacePickerStateCopyWithImpl<_PlacePickerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlacePickerState&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.picked, picked) || other.picked == picked)&&(identical(other.searching, searching) || other.searching == searching)&&(identical(other.resolving, resolving) || other.resolving == resolving)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_suggestions),picked,searching,resolving,error);

@override
String toString() {
  return 'PlacePickerState(query: $query, suggestions: $suggestions, picked: $picked, searching: $searching, resolving: $resolving, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PlacePickerStateCopyWith<$Res> implements $PlacePickerStateCopyWith<$Res> {
  factory _$PlacePickerStateCopyWith(_PlacePickerState value, $Res Function(_PlacePickerState) _then) = __$PlacePickerStateCopyWithImpl;
@override @useResult
$Res call({
 String query, List<PlaceSuggestion> suggestions, GeoPlace? picked, bool searching, bool resolving, Failure? error
});




}
/// @nodoc
class __$PlacePickerStateCopyWithImpl<$Res>
    implements _$PlacePickerStateCopyWith<$Res> {
  __$PlacePickerStateCopyWithImpl(this._self, this._then);

  final _PlacePickerState _self;
  final $Res Function(_PlacePickerState) _then;

/// Create a copy of PlacePickerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? suggestions = null,Object? picked = freezed,Object? searching = null,Object? resolving = null,Object? error = freezed,}) {
  return _then(_PlacePickerState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<PlaceSuggestion>,picked: freezed == picked ? _self.picked : picked // ignore: cast_nullable_to_non_nullable
as GeoPlace?,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,resolving: null == resolving ? _self.resolving : resolving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
