// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeamDto {

@JsonKey(name: 'team_id') String get teamId;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'team_name') String get teamName;@JsonKey(name: 'team_type') String get teamType; String? get description;@JsonKey(name: 'home_ground') String? get homeGround; Map<String, dynamic>? get location;@JsonKey(name: 'founded_year') int? get foundedYear;@JsonKey(name: 'team_colors') Map<String, dynamic>? get teamColors; String get privacy; String? get tagline;@JsonKey(name: 'logo_url') String? get logoUrl;@JsonKey(name: 'logo_monogram') String? get logoMonogram;@JsonKey(name: 'is_verified') bool get isVerified; String get status;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of TeamDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamDtoCopyWith<TeamDto> get copyWith => _$TeamDtoCopyWithImpl<TeamDto>(this as TeamDto, _$identity);

  /// Serializes this TeamDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamDto&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.description, description) || other.description == description)&&(identical(other.homeGround, homeGround) || other.homeGround == homeGround)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.foundedYear, foundedYear) || other.foundedYear == foundedYear)&&const DeepCollectionEquality().equals(other.teamColors, teamColors)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.logoMonogram, logoMonogram) || other.logoMonogram == logoMonogram)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,createdBy,teamName,teamType,description,homeGround,const DeepCollectionEquality().hash(location),foundedYear,const DeepCollectionEquality().hash(teamColors),privacy,tagline,logoUrl,logoMonogram,isVerified,status,createdAt,updatedAt);

@override
String toString() {
  return 'TeamDto(teamId: $teamId, createdBy: $createdBy, teamName: $teamName, teamType: $teamType, description: $description, homeGround: $homeGround, location: $location, foundedYear: $foundedYear, teamColors: $teamColors, privacy: $privacy, tagline: $tagline, logoUrl: $logoUrl, logoMonogram: $logoMonogram, isVerified: $isVerified, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TeamDtoCopyWith<$Res>  {
  factory $TeamDtoCopyWith(TeamDto value, $Res Function(TeamDto) _then) = _$TeamDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'team_name') String teamName,@JsonKey(name: 'team_type') String teamType, String? description,@JsonKey(name: 'home_ground') String? homeGround, Map<String, dynamic>? location,@JsonKey(name: 'founded_year') int? foundedYear,@JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors, String privacy, String? tagline,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'logo_monogram') String? logoMonogram,@JsonKey(name: 'is_verified') bool isVerified, String status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$TeamDtoCopyWithImpl<$Res>
    implements $TeamDtoCopyWith<$Res> {
  _$TeamDtoCopyWithImpl(this._self, this._then);

  final TeamDto _self;
  final $Res Function(TeamDto) _then;

/// Create a copy of TeamDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? createdBy = null,Object? teamName = null,Object? teamType = null,Object? description = freezed,Object? homeGround = freezed,Object? location = freezed,Object? foundedYear = freezed,Object? teamColors = freezed,Object? privacy = null,Object? tagline = freezed,Object? logoUrl = freezed,Object? logoMonogram = freezed,Object? isVerified = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,homeGround: freezed == homeGround ? _self.homeGround : homeGround // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,foundedYear: freezed == foundedYear ? _self.foundedYear : foundedYear // ignore: cast_nullable_to_non_nullable
as int?,teamColors: freezed == teamColors ? _self.teamColors : teamColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as String,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,logoMonogram: freezed == logoMonogram ? _self.logoMonogram : logoMonogram // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamDto].
extension TeamDtoPatterns on TeamDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamDto value)  $default,){
final _that = this;
switch (_that) {
case _TeamDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamDto value)?  $default,){
final _that = this;
switch (_that) {
case _TeamDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'team_type')  String teamType,  String? description, @JsonKey(name: 'home_ground')  String? homeGround,  Map<String, dynamic>? location, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  String privacy,  String? tagline, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'logo_monogram')  String? logoMonogram, @JsonKey(name: 'is_verified')  bool isVerified,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamDto() when $default != null:
return $default(_that.teamId,_that.createdBy,_that.teamName,_that.teamType,_that.description,_that.homeGround,_that.location,_that.foundedYear,_that.teamColors,_that.privacy,_that.tagline,_that.logoUrl,_that.logoMonogram,_that.isVerified,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'team_type')  String teamType,  String? description, @JsonKey(name: 'home_ground')  String? homeGround,  Map<String, dynamic>? location, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  String privacy,  String? tagline, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'logo_monogram')  String? logoMonogram, @JsonKey(name: 'is_verified')  bool isVerified,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TeamDto():
return $default(_that.teamId,_that.createdBy,_that.teamName,_that.teamType,_that.description,_that.homeGround,_that.location,_that.foundedYear,_that.teamColors,_that.privacy,_that.tagline,_that.logoUrl,_that.logoMonogram,_that.isVerified,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'team_type')  String teamType,  String? description, @JsonKey(name: 'home_ground')  String? homeGround,  Map<String, dynamic>? location, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  String privacy,  String? tagline, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'logo_monogram')  String? logoMonogram, @JsonKey(name: 'is_verified')  bool isVerified,  String status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TeamDto() when $default != null:
return $default(_that.teamId,_that.createdBy,_that.teamName,_that.teamType,_that.description,_that.homeGround,_that.location,_that.foundedYear,_that.teamColors,_that.privacy,_that.tagline,_that.logoUrl,_that.logoMonogram,_that.isVerified,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamDto extends TeamDto {
  const _TeamDto({@JsonKey(name: 'team_id') required this.teamId, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'team_name') required this.teamName, @JsonKey(name: 'team_type') required this.teamType, this.description, @JsonKey(name: 'home_ground') this.homeGround, final  Map<String, dynamic>? location, @JsonKey(name: 'founded_year') this.foundedYear, @JsonKey(name: 'team_colors') final  Map<String, dynamic>? teamColors, this.privacy = 'public', this.tagline, @JsonKey(name: 'logo_url') this.logoUrl, @JsonKey(name: 'logo_monogram') this.logoMonogram, @JsonKey(name: 'is_verified') this.isVerified = false, this.status = 'active', @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _location = location,_teamColors = teamColors,super._();
  factory _TeamDto.fromJson(Map<String, dynamic> json) => _$TeamDtoFromJson(json);

@override@JsonKey(name: 'team_id') final  String teamId;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'team_name') final  String teamName;
@override@JsonKey(name: 'team_type') final  String teamType;
@override final  String? description;
@override@JsonKey(name: 'home_ground') final  String? homeGround;
 final  Map<String, dynamic>? _location;
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'founded_year') final  int? foundedYear;
 final  Map<String, dynamic>? _teamColors;
@override@JsonKey(name: 'team_colors') Map<String, dynamic>? get teamColors {
  final value = _teamColors;
  if (value == null) return null;
  if (_teamColors is EqualUnmodifiableMapView) return _teamColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  String privacy;
@override final  String? tagline;
@override@JsonKey(name: 'logo_url') final  String? logoUrl;
@override@JsonKey(name: 'logo_monogram') final  String? logoMonogram;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of TeamDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamDtoCopyWith<_TeamDto> get copyWith => __$TeamDtoCopyWithImpl<_TeamDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamDto&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.description, description) || other.description == description)&&(identical(other.homeGround, homeGround) || other.homeGround == homeGround)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.foundedYear, foundedYear) || other.foundedYear == foundedYear)&&const DeepCollectionEquality().equals(other._teamColors, _teamColors)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.logoMonogram, logoMonogram) || other.logoMonogram == logoMonogram)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,createdBy,teamName,teamType,description,homeGround,const DeepCollectionEquality().hash(_location),foundedYear,const DeepCollectionEquality().hash(_teamColors),privacy,tagline,logoUrl,logoMonogram,isVerified,status,createdAt,updatedAt);

@override
String toString() {
  return 'TeamDto(teamId: $teamId, createdBy: $createdBy, teamName: $teamName, teamType: $teamType, description: $description, homeGround: $homeGround, location: $location, foundedYear: $foundedYear, teamColors: $teamColors, privacy: $privacy, tagline: $tagline, logoUrl: $logoUrl, logoMonogram: $logoMonogram, isVerified: $isVerified, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TeamDtoCopyWith<$Res> implements $TeamDtoCopyWith<$Res> {
  factory _$TeamDtoCopyWith(_TeamDto value, $Res Function(_TeamDto) _then) = __$TeamDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'team_name') String teamName,@JsonKey(name: 'team_type') String teamType, String? description,@JsonKey(name: 'home_ground') String? homeGround, Map<String, dynamic>? location,@JsonKey(name: 'founded_year') int? foundedYear,@JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors, String privacy, String? tagline,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'logo_monogram') String? logoMonogram,@JsonKey(name: 'is_verified') bool isVerified, String status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$TeamDtoCopyWithImpl<$Res>
    implements _$TeamDtoCopyWith<$Res> {
  __$TeamDtoCopyWithImpl(this._self, this._then);

  final _TeamDto _self;
  final $Res Function(_TeamDto) _then;

/// Create a copy of TeamDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? createdBy = null,Object? teamName = null,Object? teamType = null,Object? description = freezed,Object? homeGround = freezed,Object? location = freezed,Object? foundedYear = freezed,Object? teamColors = freezed,Object? privacy = null,Object? tagline = freezed,Object? logoUrl = freezed,Object? logoMonogram = freezed,Object? isVerified = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TeamDto(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,homeGround: freezed == homeGround ? _self.homeGround : homeGround // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,foundedYear: freezed == foundedYear ? _self.foundedYear : foundedYear // ignore: cast_nullable_to_non_nullable
as int?,teamColors: freezed == teamColors ? _self._teamColors : teamColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as String,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,logoMonogram: freezed == logoMonogram ? _self.logoMonogram : logoMonogram // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
