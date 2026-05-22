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

@JsonKey(name: 'team_id') String get teamId;@JsonKey(name: 'owner_id') String get ownerId;@JsonKey(name: 'team_name') String get teamName;@JsonKey(name: 'team_type') String get teamType; String? get description;@JsonKey(name: 'home_ground') String? get homeGround; Map<String, dynamic>? get location;@JsonKey(name: 'founded_year') int? get foundedYear;@JsonKey(name: 'team_colors') Map<String, dynamic>? get teamColors; List<String> get managers; String get privacy;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of TeamDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamDtoCopyWith<TeamDto> get copyWith => _$TeamDtoCopyWithImpl<TeamDto>(this as TeamDto, _$identity);

  /// Serializes this TeamDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamDto&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.description, description) || other.description == description)&&(identical(other.homeGround, homeGround) || other.homeGround == homeGround)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.foundedYear, foundedYear) || other.foundedYear == foundedYear)&&const DeepCollectionEquality().equals(other.teamColors, teamColors)&&const DeepCollectionEquality().equals(other.managers, managers)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,ownerId,teamName,teamType,description,homeGround,const DeepCollectionEquality().hash(location),foundedYear,const DeepCollectionEquality().hash(teamColors),const DeepCollectionEquality().hash(managers),privacy,createdAt,updatedAt);

@override
String toString() {
  return 'TeamDto(teamId: $teamId, ownerId: $ownerId, teamName: $teamName, teamType: $teamType, description: $description, homeGround: $homeGround, location: $location, foundedYear: $foundedYear, teamColors: $teamColors, managers: $managers, privacy: $privacy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TeamDtoCopyWith<$Res>  {
  factory $TeamDtoCopyWith(TeamDto value, $Res Function(TeamDto) _then) = _$TeamDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'team_name') String teamName,@JsonKey(name: 'team_type') String teamType, String? description,@JsonKey(name: 'home_ground') String? homeGround, Map<String, dynamic>? location,@JsonKey(name: 'founded_year') int? foundedYear,@JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors, List<String> managers, String privacy,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? ownerId = null,Object? teamName = null,Object? teamType = null,Object? description = freezed,Object? homeGround = freezed,Object? location = freezed,Object? foundedYear = freezed,Object? teamColors = freezed,Object? managers = null,Object? privacy = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,homeGround: freezed == homeGround ? _self.homeGround : homeGround // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,foundedYear: freezed == foundedYear ? _self.foundedYear : foundedYear // ignore: cast_nullable_to_non_nullable
as int?,teamColors: freezed == teamColors ? _self.teamColors : teamColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,managers: null == managers ? _self.managers : managers // ignore: cast_nullable_to_non_nullable
as List<String>,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'team_type')  String teamType,  String? description, @JsonKey(name: 'home_ground')  String? homeGround,  Map<String, dynamic>? location, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  List<String> managers,  String privacy, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamDto() when $default != null:
return $default(_that.teamId,_that.ownerId,_that.teamName,_that.teamType,_that.description,_that.homeGround,_that.location,_that.foundedYear,_that.teamColors,_that.managers,_that.privacy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'team_type')  String teamType,  String? description, @JsonKey(name: 'home_ground')  String? homeGround,  Map<String, dynamic>? location, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  List<String> managers,  String privacy, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TeamDto():
return $default(_that.teamId,_that.ownerId,_that.teamName,_that.teamType,_that.description,_that.homeGround,_that.location,_that.foundedYear,_that.teamColors,_that.managers,_that.privacy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'team_name')  String teamName, @JsonKey(name: 'team_type')  String teamType,  String? description, @JsonKey(name: 'home_ground')  String? homeGround,  Map<String, dynamic>? location, @JsonKey(name: 'founded_year')  int? foundedYear, @JsonKey(name: 'team_colors')  Map<String, dynamic>? teamColors,  List<String> managers,  String privacy, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TeamDto() when $default != null:
return $default(_that.teamId,_that.ownerId,_that.teamName,_that.teamType,_that.description,_that.homeGround,_that.location,_that.foundedYear,_that.teamColors,_that.managers,_that.privacy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamDto extends TeamDto {
  const _TeamDto({@JsonKey(name: 'team_id') required this.teamId, @JsonKey(name: 'owner_id') required this.ownerId, @JsonKey(name: 'team_name') required this.teamName, @JsonKey(name: 'team_type') required this.teamType, this.description, @JsonKey(name: 'home_ground') this.homeGround, final  Map<String, dynamic>? location, @JsonKey(name: 'founded_year') this.foundedYear, @JsonKey(name: 'team_colors') final  Map<String, dynamic>? teamColors, final  List<String> managers = const <String>[], this.privacy = 'public', @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _location = location,_teamColors = teamColors,_managers = managers,super._();
  factory _TeamDto.fromJson(Map<String, dynamic> json) => _$TeamDtoFromJson(json);

@override@JsonKey(name: 'team_id') final  String teamId;
@override@JsonKey(name: 'owner_id') final  String ownerId;
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

 final  List<String> _managers;
@override@JsonKey() List<String> get managers {
  if (_managers is EqualUnmodifiableListView) return _managers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_managers);
}

@override@JsonKey() final  String privacy;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamDto&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.description, description) || other.description == description)&&(identical(other.homeGround, homeGround) || other.homeGround == homeGround)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.foundedYear, foundedYear) || other.foundedYear == foundedYear)&&const DeepCollectionEquality().equals(other._teamColors, _teamColors)&&const DeepCollectionEquality().equals(other._managers, _managers)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,ownerId,teamName,teamType,description,homeGround,const DeepCollectionEquality().hash(_location),foundedYear,const DeepCollectionEquality().hash(_teamColors),const DeepCollectionEquality().hash(_managers),privacy,createdAt,updatedAt);

@override
String toString() {
  return 'TeamDto(teamId: $teamId, ownerId: $ownerId, teamName: $teamName, teamType: $teamType, description: $description, homeGround: $homeGround, location: $location, foundedYear: $foundedYear, teamColors: $teamColors, managers: $managers, privacy: $privacy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TeamDtoCopyWith<$Res> implements $TeamDtoCopyWith<$Res> {
  factory _$TeamDtoCopyWith(_TeamDto value, $Res Function(_TeamDto) _then) = __$TeamDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'team_name') String teamName,@JsonKey(name: 'team_type') String teamType, String? description,@JsonKey(name: 'home_ground') String? homeGround, Map<String, dynamic>? location,@JsonKey(name: 'founded_year') int? foundedYear,@JsonKey(name: 'team_colors') Map<String, dynamic>? teamColors, List<String> managers, String privacy,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? ownerId = null,Object? teamName = null,Object? teamType = null,Object? description = freezed,Object? homeGround = freezed,Object? location = freezed,Object? foundedYear = freezed,Object? teamColors = freezed,Object? managers = null,Object? privacy = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TeamDto(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,homeGround: freezed == homeGround ? _self.homeGround : homeGround // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,foundedYear: freezed == foundedYear ? _self.foundedYear : foundedYear // ignore: cast_nullable_to_non_nullable
as int?,teamColors: freezed == teamColors ? _self._teamColors : teamColors // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,managers: null == managers ? _self._managers : managers // ignore: cast_nullable_to_non_nullable
as List<String>,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
