// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_facet_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaceFacetDto {

 String get city; double? get lat; double? get lng;@JsonKey(name: 'team_count') int get teamCount;
/// Create a copy of PlaceFacetDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceFacetDtoCopyWith<PlaceFacetDto> get copyWith => _$PlaceFacetDtoCopyWithImpl<PlaceFacetDto>(this as PlaceFacetDto, _$identity);

  /// Serializes this PlaceFacetDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceFacetDto&&(identical(other.city, city) || other.city == city)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.teamCount, teamCount) || other.teamCount == teamCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,lat,lng,teamCount);

@override
String toString() {
  return 'PlaceFacetDto(city: $city, lat: $lat, lng: $lng, teamCount: $teamCount)';
}


}

/// @nodoc
abstract mixin class $PlaceFacetDtoCopyWith<$Res>  {
  factory $PlaceFacetDtoCopyWith(PlaceFacetDto value, $Res Function(PlaceFacetDto) _then) = _$PlaceFacetDtoCopyWithImpl;
@useResult
$Res call({
 String city, double? lat, double? lng,@JsonKey(name: 'team_count') int teamCount
});




}
/// @nodoc
class _$PlaceFacetDtoCopyWithImpl<$Res>
    implements $PlaceFacetDtoCopyWith<$Res> {
  _$PlaceFacetDtoCopyWithImpl(this._self, this._then);

  final PlaceFacetDto _self;
  final $Res Function(PlaceFacetDto) _then;

/// Create a copy of PlaceFacetDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = null,Object? lat = freezed,Object? lng = freezed,Object? teamCount = null,}) {
  return _then(_self.copyWith(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,teamCount: null == teamCount ? _self.teamCount : teamCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceFacetDto].
extension PlaceFacetDtoPatterns on PlaceFacetDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceFacetDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceFacetDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceFacetDto value)  $default,){
final _that = this;
switch (_that) {
case _PlaceFacetDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceFacetDto value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceFacetDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String city,  double? lat,  double? lng, @JsonKey(name: 'team_count')  int teamCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceFacetDto() when $default != null:
return $default(_that.city,_that.lat,_that.lng,_that.teamCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String city,  double? lat,  double? lng, @JsonKey(name: 'team_count')  int teamCount)  $default,) {final _that = this;
switch (_that) {
case _PlaceFacetDto():
return $default(_that.city,_that.lat,_that.lng,_that.teamCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String city,  double? lat,  double? lng, @JsonKey(name: 'team_count')  int teamCount)?  $default,) {final _that = this;
switch (_that) {
case _PlaceFacetDto() when $default != null:
return $default(_that.city,_that.lat,_that.lng,_that.teamCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceFacetDto extends PlaceFacetDto {
  const _PlaceFacetDto({required this.city, this.lat, this.lng, @JsonKey(name: 'team_count') required this.teamCount}): super._();
  factory _PlaceFacetDto.fromJson(Map<String, dynamic> json) => _$PlaceFacetDtoFromJson(json);

@override final  String city;
@override final  double? lat;
@override final  double? lng;
@override@JsonKey(name: 'team_count') final  int teamCount;

/// Create a copy of PlaceFacetDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceFacetDtoCopyWith<_PlaceFacetDto> get copyWith => __$PlaceFacetDtoCopyWithImpl<_PlaceFacetDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceFacetDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceFacetDto&&(identical(other.city, city) || other.city == city)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.teamCount, teamCount) || other.teamCount == teamCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,lat,lng,teamCount);

@override
String toString() {
  return 'PlaceFacetDto(city: $city, lat: $lat, lng: $lng, teamCount: $teamCount)';
}


}

/// @nodoc
abstract mixin class _$PlaceFacetDtoCopyWith<$Res> implements $PlaceFacetDtoCopyWith<$Res> {
  factory _$PlaceFacetDtoCopyWith(_PlaceFacetDto value, $Res Function(_PlaceFacetDto) _then) = __$PlaceFacetDtoCopyWithImpl;
@override @useResult
$Res call({
 String city, double? lat, double? lng,@JsonKey(name: 'team_count') int teamCount
});




}
/// @nodoc
class __$PlaceFacetDtoCopyWithImpl<$Res>
    implements _$PlaceFacetDtoCopyWith<$Res> {
  __$PlaceFacetDtoCopyWithImpl(this._self, this._then);

  final _PlaceFacetDto _self;
  final $Res Function(_PlaceFacetDto) _then;

/// Create a copy of PlaceFacetDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = null,Object? lat = freezed,Object? lng = freezed,Object? teamCount = null,}) {
  return _then(_PlaceFacetDto(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,teamCount: null == teamCount ? _self.teamCount : teamCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
