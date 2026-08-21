// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExploreState {

 String get query;/// The query the currently-displayed [results] were fetched for. Used to
/// highlight matched substrings — highlighting against the live [query]
/// would flicker the highlight ahead of the data during the debounce.
 String get resultsQuery;/// Last successfully loaded search results. Retained under [loading] so
/// the list does not blank on every keystroke.
 ExploreResults get results;/// True while the field is focused with no query — shows recents and
/// suggestions instead of browse content (artboard 04).
 bool get searchFocused;/// A request is in flight. Render as a thin indeterminate bar over the
/// existing list; as a skeleton only when there is nothing to keep.
 bool get loading;/// Most recent failure. Cleared at the start of every request.
 Failure? get error;
/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreStateCopyWith<ExploreState> get copyWith => _$ExploreStateCopyWithImpl<ExploreState>(this as ExploreState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreState&&(identical(other.query, query) || other.query == query)&&(identical(other.resultsQuery, resultsQuery) || other.resultsQuery == resultsQuery)&&(identical(other.results, results) || other.results == results)&&(identical(other.searchFocused, searchFocused) || other.searchFocused == searchFocused)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,query,resultsQuery,results,searchFocused,loading,error);

@override
String toString() {
  return 'ExploreState(query: $query, resultsQuery: $resultsQuery, results: $results, searchFocused: $searchFocused, loading: $loading, error: $error)';
}


}

/// @nodoc
abstract mixin class $ExploreStateCopyWith<$Res>  {
  factory $ExploreStateCopyWith(ExploreState value, $Res Function(ExploreState) _then) = _$ExploreStateCopyWithImpl;
@useResult
$Res call({
 String query, String resultsQuery, ExploreResults results, bool searchFocused, bool loading, Failure? error
});




}
/// @nodoc
class _$ExploreStateCopyWithImpl<$Res>
    implements $ExploreStateCopyWith<$Res> {
  _$ExploreStateCopyWithImpl(this._self, this._then);

  final ExploreState _self;
  final $Res Function(ExploreState) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? resultsQuery = null,Object? results = null,Object? searchFocused = null,Object? loading = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,resultsQuery: null == resultsQuery ? _self.resultsQuery : resultsQuery // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as ExploreResults,searchFocused: null == searchFocused ? _self.searchFocused : searchFocused // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExploreState].
extension ExploreStatePatterns on ExploreState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExploreState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExploreState value)  $default,){
final _that = this;
switch (_that) {
case _ExploreState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExploreState value)?  $default,){
final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  String resultsQuery,  ExploreResults results,  bool searchFocused,  bool loading,  Failure? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that.query,_that.resultsQuery,_that.results,_that.searchFocused,_that.loading,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  String resultsQuery,  ExploreResults results,  bool searchFocused,  bool loading,  Failure? error)  $default,) {final _that = this;
switch (_that) {
case _ExploreState():
return $default(_that.query,_that.resultsQuery,_that.results,_that.searchFocused,_that.loading,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  String resultsQuery,  ExploreResults results,  bool searchFocused,  bool loading,  Failure? error)?  $default,) {final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that.query,_that.resultsQuery,_that.results,_that.searchFocused,_that.loading,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ExploreState extends ExploreState {
  const _ExploreState({this.query = '', this.resultsQuery = '', this.results = ExploreResults.empty, this.searchFocused = false, this.loading = false, this.error}): super._();
  

@override@JsonKey() final  String query;
/// The query the currently-displayed [results] were fetched for. Used to
/// highlight matched substrings — highlighting against the live [query]
/// would flicker the highlight ahead of the data during the debounce.
@override@JsonKey() final  String resultsQuery;
/// Last successfully loaded search results. Retained under [loading] so
/// the list does not blank on every keystroke.
@override@JsonKey() final  ExploreResults results;
/// True while the field is focused with no query — shows recents and
/// suggestions instead of browse content (artboard 04).
@override@JsonKey() final  bool searchFocused;
/// A request is in flight. Render as a thin indeterminate bar over the
/// existing list; as a skeleton only when there is nothing to keep.
@override@JsonKey() final  bool loading;
/// Most recent failure. Cleared at the start of every request.
@override final  Failure? error;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreStateCopyWith<_ExploreState> get copyWith => __$ExploreStateCopyWithImpl<_ExploreState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreState&&(identical(other.query, query) || other.query == query)&&(identical(other.resultsQuery, resultsQuery) || other.resultsQuery == resultsQuery)&&(identical(other.results, results) || other.results == results)&&(identical(other.searchFocused, searchFocused) || other.searchFocused == searchFocused)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,query,resultsQuery,results,searchFocused,loading,error);

@override
String toString() {
  return 'ExploreState(query: $query, resultsQuery: $resultsQuery, results: $results, searchFocused: $searchFocused, loading: $loading, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ExploreStateCopyWith<$Res> implements $ExploreStateCopyWith<$Res> {
  factory _$ExploreStateCopyWith(_ExploreState value, $Res Function(_ExploreState) _then) = __$ExploreStateCopyWithImpl;
@override @useResult
$Res call({
 String query, String resultsQuery, ExploreResults results, bool searchFocused, bool loading, Failure? error
});




}
/// @nodoc
class __$ExploreStateCopyWithImpl<$Res>
    implements _$ExploreStateCopyWith<$Res> {
  __$ExploreStateCopyWithImpl(this._self, this._then);

  final _ExploreState _self;
  final $Res Function(_ExploreState) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? resultsQuery = null,Object? results = null,Object? searchFocused = null,Object? loading = null,Object? error = freezed,}) {
  return _then(_ExploreState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,resultsQuery: null == resultsQuery ? _self.resultsQuery : resultsQuery // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as ExploreResults,searchFocused: null == searchFocused ? _self.searchFocused : searchFocused // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
