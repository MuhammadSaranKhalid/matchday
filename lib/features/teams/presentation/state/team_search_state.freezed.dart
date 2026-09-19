// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TeamSearchState {

 String get query; double? get centerLat; double? get centerLng; String? get selectedFacetCity; double get radiusKm; List<TeamSearchResult> get results; bool get loading; Failure? get error;
/// Create a copy of TeamSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamSearchStateCopyWith<TeamSearchState> get copyWith => _$TeamSearchStateCopyWithImpl<TeamSearchState>(this as TeamSearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamSearchState&&(identical(other.query, query) || other.query == query)&&(identical(other.centerLat, centerLat) || other.centerLat == centerLat)&&(identical(other.centerLng, centerLng) || other.centerLng == centerLng)&&(identical(other.selectedFacetCity, selectedFacetCity) || other.selectedFacetCity == selectedFacetCity)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,query,centerLat,centerLng,selectedFacetCity,radiusKm,const DeepCollectionEquality().hash(results),loading,error);

@override
String toString() {
  return 'TeamSearchState(query: $query, centerLat: $centerLat, centerLng: $centerLng, selectedFacetCity: $selectedFacetCity, radiusKm: $radiusKm, results: $results, loading: $loading, error: $error)';
}


}

/// @nodoc
abstract mixin class $TeamSearchStateCopyWith<$Res>  {
  factory $TeamSearchStateCopyWith(TeamSearchState value, $Res Function(TeamSearchState) _then) = _$TeamSearchStateCopyWithImpl;
@useResult
$Res call({
 String query, double? centerLat, double? centerLng, String? selectedFacetCity, double radiusKm, List<TeamSearchResult> results, bool loading, Failure? error
});




}
/// @nodoc
class _$TeamSearchStateCopyWithImpl<$Res>
    implements $TeamSearchStateCopyWith<$Res> {
  _$TeamSearchStateCopyWithImpl(this._self, this._then);

  final TeamSearchState _self;
  final $Res Function(TeamSearchState) _then;

/// Create a copy of TeamSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? centerLat = freezed,Object? centerLng = freezed,Object? selectedFacetCity = freezed,Object? radiusKm = null,Object? results = null,Object? loading = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,centerLat: freezed == centerLat ? _self.centerLat : centerLat // ignore: cast_nullable_to_non_nullable
as double?,centerLng: freezed == centerLng ? _self.centerLng : centerLng // ignore: cast_nullable_to_non_nullable
as double?,selectedFacetCity: freezed == selectedFacetCity ? _self.selectedFacetCity : selectedFacetCity // ignore: cast_nullable_to_non_nullable
as String?,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<TeamSearchResult>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamSearchState].
extension TeamSearchStatePatterns on TeamSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamSearchState value)  $default,){
final _that = this;
switch (_that) {
case _TeamSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _TeamSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  double? centerLat,  double? centerLng,  String? selectedFacetCity,  double radiusKm,  List<TeamSearchResult> results,  bool loading,  Failure? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamSearchState() when $default != null:
return $default(_that.query,_that.centerLat,_that.centerLng,_that.selectedFacetCity,_that.radiusKm,_that.results,_that.loading,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  double? centerLat,  double? centerLng,  String? selectedFacetCity,  double radiusKm,  List<TeamSearchResult> results,  bool loading,  Failure? error)  $default,) {final _that = this;
switch (_that) {
case _TeamSearchState():
return $default(_that.query,_that.centerLat,_that.centerLng,_that.selectedFacetCity,_that.radiusKm,_that.results,_that.loading,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  double? centerLat,  double? centerLng,  String? selectedFacetCity,  double radiusKm,  List<TeamSearchResult> results,  bool loading,  Failure? error)?  $default,) {final _that = this;
switch (_that) {
case _TeamSearchState() when $default != null:
return $default(_that.query,_that.centerLat,_that.centerLng,_that.selectedFacetCity,_that.radiusKm,_that.results,_that.loading,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _TeamSearchState extends TeamSearchState {
  const _TeamSearchState({this.query = '', this.centerLat, this.centerLng, this.selectedFacetCity, this.radiusKm = 25.0, final  List<TeamSearchResult> results = const <TeamSearchResult>[], this.loading = false, this.error}): _results = results,super._();
  

@override@JsonKey() final  String query;
@override final  double? centerLat;
@override final  double? centerLng;
@override final  String? selectedFacetCity;
@override@JsonKey() final  double radiusKm;
 final  List<TeamSearchResult> _results;
@override@JsonKey() List<TeamSearchResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey() final  bool loading;
@override final  Failure? error;

/// Create a copy of TeamSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamSearchStateCopyWith<_TeamSearchState> get copyWith => __$TeamSearchStateCopyWithImpl<_TeamSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamSearchState&&(identical(other.query, query) || other.query == query)&&(identical(other.centerLat, centerLat) || other.centerLat == centerLat)&&(identical(other.centerLng, centerLng) || other.centerLng == centerLng)&&(identical(other.selectedFacetCity, selectedFacetCity) || other.selectedFacetCity == selectedFacetCity)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,query,centerLat,centerLng,selectedFacetCity,radiusKm,const DeepCollectionEquality().hash(_results),loading,error);

@override
String toString() {
  return 'TeamSearchState(query: $query, centerLat: $centerLat, centerLng: $centerLng, selectedFacetCity: $selectedFacetCity, radiusKm: $radiusKm, results: $results, loading: $loading, error: $error)';
}


}

/// @nodoc
abstract mixin class _$TeamSearchStateCopyWith<$Res> implements $TeamSearchStateCopyWith<$Res> {
  factory _$TeamSearchStateCopyWith(_TeamSearchState value, $Res Function(_TeamSearchState) _then) = __$TeamSearchStateCopyWithImpl;
@override @useResult
$Res call({
 String query, double? centerLat, double? centerLng, String? selectedFacetCity, double radiusKm, List<TeamSearchResult> results, bool loading, Failure? error
});




}
/// @nodoc
class __$TeamSearchStateCopyWithImpl<$Res>
    implements _$TeamSearchStateCopyWith<$Res> {
  __$TeamSearchStateCopyWithImpl(this._self, this._then);

  final _TeamSearchState _self;
  final $Res Function(_TeamSearchState) _then;

/// Create a copy of TeamSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? centerLat = freezed,Object? centerLng = freezed,Object? selectedFacetCity = freezed,Object? radiusKm = null,Object? results = null,Object? loading = null,Object? error = freezed,}) {
  return _then(_TeamSearchState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,centerLat: freezed == centerLat ? _self.centerLat : centerLat // ignore: cast_nullable_to_non_nullable
as double?,centerLng: freezed == centerLng ? _self.centerLng : centerLng // ignore: cast_nullable_to_non_nullable
as double?,selectedFacetCity: freezed == selectedFacetCity ? _self.selectedFacetCity : selectedFacetCity // ignore: cast_nullable_to_non_nullable
as String?,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<TeamSearchResult>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
