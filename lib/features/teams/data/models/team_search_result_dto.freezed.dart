// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_search_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeamSearchResultDto {

@JsonKey(name: 'team_id') String get teamId;@JsonKey(name: 'team_name') String get teamName;@JsonKey(name: 'logo_url') String? get logoUrl;@JsonKey(name: 'logo_monogram') String? get logoMonogram;@JsonKey(name: 'team_colors') Map<String, dynamic>? get teamColors; Map<String, dynamic>? get location;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'distance_km') double? get distanceKm;// Returned by `search-all` only; `search-teams` does not select them.
@JsonKey(name: 'founded_year') int? get foundedYear;@JsonKey(name: 'team_type') String? get teamType; double get score;
/// Create a copy of TeamSearchResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamSearchResultDtoCopyWith<TeamSearchResultDto> get copyWith => _$TeamSearchResultDtoCopyWithImpl<TeamSearchResultDto>(this as TeamSearchResultDto, _$identity);

  /// Serializes this TeamSearchResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamSearchResultDto&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.logoMonogram, logoMonogram) || other.logoMonogram == logoMonogram)&&const DeepCollectionEquality().equals(other.teamColors, teamColors)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.foundedYear, foundedYear) || other.foundedYear == foundedYear)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,teamName,logoUrl,logoMonogram,const DeepCollectionEquality().hash(teamColors),const DeepCollectionEquality().hash(location),isVerified,distanceKm,foundedYear,teamType,score);

@override
String toString() {
  return 'TeamSearchResultDto(teamId: $teamId, teamName: $teamName, logoUrl: $logoUrl, logoMonogram: $logoMonogram, teamColors: $teamColors, location: $location, isVerified: $isVerified, distanceKm: $distanceKm, foundedYear: $foundedYear, teamType: $teamType, score: $score)';
}


}

/// @nodoc
abstract mixin class $TeamSearchResultDtoCopyWith<$Res>  {
  factory $TeamSearchResultDtoCopyWith(TeamSearchResultDto value, $Res Function(TeamSearchResultDto) _then) = _$TeamSearchResultDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'team_name') String teamName,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'logo_monogram') String? logoMonogram,@JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors, Map<String, dynamic>? location,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'distance_km') double? distanceKm,@JsonKey(name: 'founded_year') int? foundedYear,@JsonKey(name: 'team_type') String? teamType, double score
});




}
/// @nodoc
class _$TeamSearchResultDtoCopyWithImpl<$Res>
    implements $TeamSearchResultDtoCopyWith<$Res> {
  _$TeamSearchResultDtoCopyWithImpl(this._self, this._then);

  final TeamSearchResultDto _self;
  final $Res Function(TeamSearchResultDto) _then;

/// Create a copy of TeamSearchResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? teamName = null,Object? logoUrl = freezed,Object? logoMonogram = freezed,Object? teamColors = freezed,Object? location = freezed,Object? isVerified = null,Object? distanceKm = freezed,Object? foundedYear = freezed,Object? teamType = freezed,Object? score = null,}) {
  return _then(_self.copyWith(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,logoMonogram: freezed == logoMonogram ? _self.logoMonogram : logoMonogram // ignore: cast_nullable_to_non_nullable
as String?,teamColors: freezed == teamColors ? _self.teamColors : teamColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,foundedYear: freezed == foundedYear ? _self.foundedYear : foundedYear // ignore: cast_nullable_to_non_nullable
as int?,teamType: freezed == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as String?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamSearchResultDto].
extension TeamSearchResultDtoPatterns on TeamSearchResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamSearchResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamSearchResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamSearchResultDto value)  $default,){
final _that = this;
switch (_that) {
case _TeamSearchResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamSearchResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _TeamSearchResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'logo_monogram')  String? logoMonogram, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  Map<String, dynamic>? location, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_type')  String? teamType,  double score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamSearchResultDto() when $default != null:
return $default(_that.teamId,_that.teamName,_that.logoUrl,_that.logoMonogram,_that.teamColors,_that.location,_that.isVerified,_that.distanceKm,_that.foundedYear,_that.teamType,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'logo_monogram')  String? logoMonogram, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  Map<String, dynamic>? location, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_type')  String? teamType,  double score)  $default,) {final _that = this;
switch (_that) {
case _TeamSearchResultDto():
return $default(_that.teamId,_that.teamName,_that.logoUrl,_that.logoMonogram,_that.teamColors,_that.location,_that.isVerified,_that.distanceKm,_that.foundedYear,_that.teamType,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'logo_monogram')  String? logoMonogram, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  Map<String, dynamic>? location, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_type')  String? teamType,  double score)?  $default,) {final _that = this;
switch (_that) {
case _TeamSearchResultDto() when $default != null:
return $default(_that.teamId,_that.teamName,_that.logoUrl,_that.logoMonogram,_that.teamColors,_that.location,_that.isVerified,_that.distanceKm,_that.foundedYear,_that.teamType,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamSearchResultDto extends TeamSearchResultDto {
  const _TeamSearchResultDto({@JsonKey(name: 'team_id') required this.teamId, @JsonKey(name: 'team_name') required this.teamName, @JsonKey(name: 'logo_url') this.logoUrl, @JsonKey(name: 'logo_monogram') this.logoMonogram, @JsonKey(name: 'team_colors') final  Map<String, dynamic>? teamColors, final  Map<String, dynamic>? location, @JsonKey(name: 'is_verified') this.isVerified = false, @JsonKey(name: 'distance_km') this.distanceKm, @JsonKey(name: 'founded_year') this.foundedYear, @JsonKey(name: 'team_type') this.teamType, this.score = 0.0}): _teamColors = teamColors,_location = location,super._();
  factory _TeamSearchResultDto.fromJson(Map<String, dynamic> json) => _$TeamSearchResultDtoFromJson(json);

@override@JsonKey(name: 'team_id') final  String teamId;
@override@JsonKey(name: 'team_name') final  String teamName;
@override@JsonKey(name: 'logo_url') final  String? logoUrl;
@override@JsonKey(name: 'logo_monogram') final  String? logoMonogram;
 final  Map<String, dynamic>? _teamColors;
@override@JsonKey(name: 'team_colors') Map<String, dynamic>? get teamColors {
  final value = _teamColors;
  if (value == null) return null;
  if (_teamColors is EqualUnmodifiableMapView) return _teamColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _location;
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'distance_km') final  double? distanceKm;
// Returned by `search-all` only; `search-teams` does not select them.
@override@JsonKey(name: 'founded_year') final  int? foundedYear;
@override@JsonKey(name: 'team_type') final  String? teamType;
@override@JsonKey() final  double score;

/// Create a copy of TeamSearchResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamSearchResultDtoCopyWith<_TeamSearchResultDto> get copyWith => __$TeamSearchResultDtoCopyWithImpl<_TeamSearchResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamSearchResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamSearchResultDto&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.logoMonogram, logoMonogram) || other.logoMonogram == logoMonogram)&&const DeepCollectionEquality().equals(other._teamColors, _teamColors)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.foundedYear, foundedYear) || other.foundedYear == foundedYear)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,teamName,logoUrl,logoMonogram,const DeepCollectionEquality().hash(_teamColors),const DeepCollectionEquality().hash(_location),isVerified,distanceKm,foundedYear,teamType,score);

@override
String toString() {
  return 'TeamSearchResultDto(teamId: $teamId, teamName: $teamName, logoUrl: $logoUrl, logoMonogram: $logoMonogram, teamColors: $teamColors, location: $location, isVerified: $isVerified, distanceKm: $distanceKm, foundedYear: $foundedYear, teamType: $teamType, score: $score)';
}


}

/// @nodoc
abstract mixin class _$TeamSearchResultDtoCopyWith<$Res> implements $TeamSearchResultDtoCopyWith<$Res> {
  factory _$TeamSearchResultDtoCopyWith(_TeamSearchResultDto value, $Res Function(_TeamSearchResultDto) _then) = __$TeamSearchResultDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'team_name') String teamName,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'logo_monogram') String? logoMonogram,@JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors, Map<String, dynamic>? location,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'distance_km') double? distanceKm,@JsonKey(name: 'founded_year') int? foundedYear,@JsonKey(name: 'team_type') String? teamType, double score
});




}
/// @nodoc
class __$TeamSearchResultDtoCopyWithImpl<$Res>
    implements _$TeamSearchResultDtoCopyWith<$Res> {
  __$TeamSearchResultDtoCopyWithImpl(this._self, this._then);

  final _TeamSearchResultDto _self;
  final $Res Function(_TeamSearchResultDto) _then;

/// Create a copy of TeamSearchResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? teamName = null,Object? logoUrl = freezed,Object? logoMonogram = freezed,Object? teamColors = freezed,Object? location = freezed,Object? isVerified = null,Object? distanceKm = freezed,Object? foundedYear = freezed,Object? teamType = freezed,Object? score = null,}) {
  return _then(_TeamSearchResultDto(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,logoMonogram: freezed == logoMonogram ? _self.logoMonogram : logoMonogram // ignore: cast_nullable_to_non_nullable
as String?,teamColors: freezed == teamColors ? _self._teamColors : teamColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,foundedYear: freezed == foundedYear ? _self.foundedYear : foundedYear // ignore: cast_nullable_to_non_nullable
as int?,teamType: freezed == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as String?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
