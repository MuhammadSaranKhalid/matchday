// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tournament_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TournamentResultDto {

@JsonKey(name: 'tournament_id') String get tournamentId;@JsonKey(name: 'tournament_name') String get tournamentName;@JsonKey(name: 'tournament_type') String get tournamentType; String get status;@JsonKey(name: 'banner_image_url') String? get bannerImageUrl;@JsonKey(name: 'logo_url') String? get logoUrl;@JsonKey(name: 'start_date') String? get startDate;@JsonKey(name: 'end_date') String? get endDate; Map<String, dynamic>? get location;// numeric(10,2) can arrive as either a JSON number or a string depending
// on the driver, so it is decoded loosely and coerced in toEntity.
@JsonKey(name: 'entry_fee') Object? get entryFee;@JsonKey(name: 'max_teams') int? get maxTeams;@JsonKey(name: 'approved_teams_count') int? get approvedTeamsCount;
/// Create a copy of TournamentResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TournamentResultDtoCopyWith<TournamentResultDto> get copyWith => _$TournamentResultDtoCopyWithImpl<TournamentResultDto>(this as TournamentResultDto, _$identity);

  /// Serializes this TournamentResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TournamentResultDto&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.tournamentName, tournamentName) || other.tournamentName == tournamentName)&&(identical(other.tournamentType, tournamentType) || other.tournamentType == tournamentType)&&(identical(other.status, status) || other.status == status)&&(identical(other.bannerImageUrl, bannerImageUrl) || other.bannerImageUrl == bannerImageUrl)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.location, location)&&const DeepCollectionEquality().equals(other.entryFee, entryFee)&&(identical(other.maxTeams, maxTeams) || other.maxTeams == maxTeams)&&(identical(other.approvedTeamsCount, approvedTeamsCount) || other.approvedTeamsCount == approvedTeamsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tournamentId,tournamentName,tournamentType,status,bannerImageUrl,logoUrl,startDate,endDate,const DeepCollectionEquality().hash(location),const DeepCollectionEquality().hash(entryFee),maxTeams,approvedTeamsCount);

@override
String toString() {
  return 'TournamentResultDto(tournamentId: $tournamentId, tournamentName: $tournamentName, tournamentType: $tournamentType, status: $status, bannerImageUrl: $bannerImageUrl, logoUrl: $logoUrl, startDate: $startDate, endDate: $endDate, location: $location, entryFee: $entryFee, maxTeams: $maxTeams, approvedTeamsCount: $approvedTeamsCount)';
}


}

/// @nodoc
abstract mixin class $TournamentResultDtoCopyWith<$Res>  {
  factory $TournamentResultDtoCopyWith(TournamentResultDto value, $Res Function(TournamentResultDto) _then) = _$TournamentResultDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'tournament_id') String tournamentId,@JsonKey(name: 'tournament_name') String tournamentName,@JsonKey(name: 'tournament_type') String tournamentType, String status,@JsonKey(name: 'banner_image_url') String? bannerImageUrl,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'end_date') String? endDate, Map<String, dynamic>? location,@JsonKey(name: 'entry_fee') Object? entryFee,@JsonKey(name: 'max_teams') int? maxTeams,@JsonKey(name: 'approved_teams_count') int? approvedTeamsCount
});




}
/// @nodoc
class _$TournamentResultDtoCopyWithImpl<$Res>
    implements $TournamentResultDtoCopyWith<$Res> {
  _$TournamentResultDtoCopyWithImpl(this._self, this._then);

  final TournamentResultDto _self;
  final $Res Function(TournamentResultDto) _then;

/// Create a copy of TournamentResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tournamentId = null,Object? tournamentName = null,Object? tournamentType = null,Object? status = null,Object? bannerImageUrl = freezed,Object? logoUrl = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? location = freezed,Object? entryFee = freezed,Object? maxTeams = freezed,Object? approvedTeamsCount = freezed,}) {
  return _then(_self.copyWith(
tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,tournamentName: null == tournamentName ? _self.tournamentName : tournamentName // ignore: cast_nullable_to_non_nullable
as String,tournamentType: null == tournamentType ? _self.tournamentType : tournamentType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,bannerImageUrl: freezed == bannerImageUrl ? _self.bannerImageUrl : bannerImageUrl // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,entryFee: freezed == entryFee ? _self.entryFee : entryFee ,maxTeams: freezed == maxTeams ? _self.maxTeams : maxTeams // ignore: cast_nullable_to_non_nullable
as int?,approvedTeamsCount: freezed == approvedTeamsCount ? _self.approvedTeamsCount : approvedTeamsCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TournamentResultDto].
extension TournamentResultDtoPatterns on TournamentResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TournamentResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TournamentResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TournamentResultDto value)  $default,){
final _that = this;
switch (_that) {
case _TournamentResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TournamentResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _TournamentResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'tournament_id')  String tournamentId, @JsonKey(name: 'tournament_name')  String tournamentName, @JsonKey(name: 'tournament_type')  String tournamentType,  String status, @JsonKey(name: 'banner_image_url')  String? bannerImageUrl, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'end_date')  String? endDate,  Map<String, dynamic>? location, @JsonKey(name: 'entry_fee')  Object? entryFee, @JsonKey(name: 'max_teams')  int? maxTeams, @JsonKey(name: 'approved_teams_count')  int? approvedTeamsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TournamentResultDto() when $default != null:
return $default(_that.tournamentId,_that.tournamentName,_that.tournamentType,_that.status,_that.bannerImageUrl,_that.logoUrl,_that.startDate,_that.endDate,_that.location,_that.entryFee,_that.maxTeams,_that.approvedTeamsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'tournament_id')  String tournamentId, @JsonKey(name: 'tournament_name')  String tournamentName, @JsonKey(name: 'tournament_type')  String tournamentType,  String status, @JsonKey(name: 'banner_image_url')  String? bannerImageUrl, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'end_date')  String? endDate,  Map<String, dynamic>? location, @JsonKey(name: 'entry_fee')  Object? entryFee, @JsonKey(name: 'max_teams')  int? maxTeams, @JsonKey(name: 'approved_teams_count')  int? approvedTeamsCount)  $default,) {final _that = this;
switch (_that) {
case _TournamentResultDto():
return $default(_that.tournamentId,_that.tournamentName,_that.tournamentType,_that.status,_that.bannerImageUrl,_that.logoUrl,_that.startDate,_that.endDate,_that.location,_that.entryFee,_that.maxTeams,_that.approvedTeamsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'tournament_id')  String tournamentId, @JsonKey(name: 'tournament_name')  String tournamentName, @JsonKey(name: 'tournament_type')  String tournamentType,  String status, @JsonKey(name: 'banner_image_url')  String? bannerImageUrl, @JsonKey(name: 'logo_url')  String? logoUrl, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'end_date')  String? endDate,  Map<String, dynamic>? location, @JsonKey(name: 'entry_fee')  Object? entryFee, @JsonKey(name: 'max_teams')  int? maxTeams, @JsonKey(name: 'approved_teams_count')  int? approvedTeamsCount)?  $default,) {final _that = this;
switch (_that) {
case _TournamentResultDto() when $default != null:
return $default(_that.tournamentId,_that.tournamentName,_that.tournamentType,_that.status,_that.bannerImageUrl,_that.logoUrl,_that.startDate,_that.endDate,_that.location,_that.entryFee,_that.maxTeams,_that.approvedTeamsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TournamentResultDto extends TournamentResultDto {
  const _TournamentResultDto({@JsonKey(name: 'tournament_id') required this.tournamentId, @JsonKey(name: 'tournament_name') required this.tournamentName, @JsonKey(name: 'tournament_type') required this.tournamentType, required this.status, @JsonKey(name: 'banner_image_url') this.bannerImageUrl, @JsonKey(name: 'logo_url') this.logoUrl, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'end_date') this.endDate, final  Map<String, dynamic>? location, @JsonKey(name: 'entry_fee') this.entryFee, @JsonKey(name: 'max_teams') this.maxTeams, @JsonKey(name: 'approved_teams_count') this.approvedTeamsCount}): _location = location,super._();
  factory _TournamentResultDto.fromJson(Map<String, dynamic> json) => _$TournamentResultDtoFromJson(json);

@override@JsonKey(name: 'tournament_id') final  String tournamentId;
@override@JsonKey(name: 'tournament_name') final  String tournamentName;
@override@JsonKey(name: 'tournament_type') final  String tournamentType;
@override final  String status;
@override@JsonKey(name: 'banner_image_url') final  String? bannerImageUrl;
@override@JsonKey(name: 'logo_url') final  String? logoUrl;
@override@JsonKey(name: 'start_date') final  String? startDate;
@override@JsonKey(name: 'end_date') final  String? endDate;
 final  Map<String, dynamic>? _location;
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// numeric(10,2) can arrive as either a JSON number or a string depending
// on the driver, so it is decoded loosely and coerced in toEntity.
@override@JsonKey(name: 'entry_fee') final  Object? entryFee;
@override@JsonKey(name: 'max_teams') final  int? maxTeams;
@override@JsonKey(name: 'approved_teams_count') final  int? approvedTeamsCount;

/// Create a copy of TournamentResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TournamentResultDtoCopyWith<_TournamentResultDto> get copyWith => __$TournamentResultDtoCopyWithImpl<_TournamentResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TournamentResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TournamentResultDto&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.tournamentName, tournamentName) || other.tournamentName == tournamentName)&&(identical(other.tournamentType, tournamentType) || other.tournamentType == tournamentType)&&(identical(other.status, status) || other.status == status)&&(identical(other.bannerImageUrl, bannerImageUrl) || other.bannerImageUrl == bannerImageUrl)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other._location, _location)&&const DeepCollectionEquality().equals(other.entryFee, entryFee)&&(identical(other.maxTeams, maxTeams) || other.maxTeams == maxTeams)&&(identical(other.approvedTeamsCount, approvedTeamsCount) || other.approvedTeamsCount == approvedTeamsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tournamentId,tournamentName,tournamentType,status,bannerImageUrl,logoUrl,startDate,endDate,const DeepCollectionEquality().hash(_location),const DeepCollectionEquality().hash(entryFee),maxTeams,approvedTeamsCount);

@override
String toString() {
  return 'TournamentResultDto(tournamentId: $tournamentId, tournamentName: $tournamentName, tournamentType: $tournamentType, status: $status, bannerImageUrl: $bannerImageUrl, logoUrl: $logoUrl, startDate: $startDate, endDate: $endDate, location: $location, entryFee: $entryFee, maxTeams: $maxTeams, approvedTeamsCount: $approvedTeamsCount)';
}


}

/// @nodoc
abstract mixin class _$TournamentResultDtoCopyWith<$Res> implements $TournamentResultDtoCopyWith<$Res> {
  factory _$TournamentResultDtoCopyWith(_TournamentResultDto value, $Res Function(_TournamentResultDto) _then) = __$TournamentResultDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'tournament_id') String tournamentId,@JsonKey(name: 'tournament_name') String tournamentName,@JsonKey(name: 'tournament_type') String tournamentType, String status,@JsonKey(name: 'banner_image_url') String? bannerImageUrl,@JsonKey(name: 'logo_url') String? logoUrl,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'end_date') String? endDate, Map<String, dynamic>? location,@JsonKey(name: 'entry_fee') Object? entryFee,@JsonKey(name: 'max_teams') int? maxTeams,@JsonKey(name: 'approved_teams_count') int? approvedTeamsCount
});




}
/// @nodoc
class __$TournamentResultDtoCopyWithImpl<$Res>
    implements _$TournamentResultDtoCopyWith<$Res> {
  __$TournamentResultDtoCopyWithImpl(this._self, this._then);

  final _TournamentResultDto _self;
  final $Res Function(_TournamentResultDto) _then;

/// Create a copy of TournamentResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tournamentId = null,Object? tournamentName = null,Object? tournamentType = null,Object? status = null,Object? bannerImageUrl = freezed,Object? logoUrl = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? location = freezed,Object? entryFee = freezed,Object? maxTeams = freezed,Object? approvedTeamsCount = freezed,}) {
  return _then(_TournamentResultDto(
tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,tournamentName: null == tournamentName ? _self.tournamentName : tournamentName // ignore: cast_nullable_to_non_nullable
as String,tournamentType: null == tournamentType ? _self.tournamentType : tournamentType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,bannerImageUrl: freezed == bannerImageUrl ? _self.bannerImageUrl : bannerImageUrl // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,entryFee: freezed == entryFee ? _self.entryFee : entryFee ,maxTeams: freezed == maxTeams ? _self.maxTeams : maxTeams // ignore: cast_nullable_to_non_nullable
as int?,approvedTeamsCount: freezed == approvedTeamsCount ? _self.approvedTeamsCount : approvedTeamsCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
