// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unclaimed_player_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnclaimedPlayerDto {

@JsonKey(name: 'unclaimed_id') String get unclaimedId;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'added_by') String get addedBy;@JsonKey(name: 'phone_number') String? get phoneNumber;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;@JsonKey(name: 'player_profile') Map<String, dynamic> get playerProfile;
/// Create a copy of UnclaimedPlayerDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnclaimedPlayerDtoCopyWith<UnclaimedPlayerDto> get copyWith => _$UnclaimedPlayerDtoCopyWithImpl<UnclaimedPlayerDto>(this as UnclaimedPlayerDto, _$identity);

  /// Serializes this UnclaimedPlayerDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnclaimedPlayerDto&&(identical(other.unclaimedId, unclaimedId) || other.unclaimedId == unclaimedId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.playerProfile, playerProfile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unclaimedId,displayName,addedBy,phoneNumber,createdAt,updatedAt,const DeepCollectionEquality().hash(playerProfile));

@override
String toString() {
  return 'UnclaimedPlayerDto(unclaimedId: $unclaimedId, displayName: $displayName, addedBy: $addedBy, phoneNumber: $phoneNumber, createdAt: $createdAt, updatedAt: $updatedAt, playerProfile: $playerProfile)';
}


}

/// @nodoc
abstract mixin class $UnclaimedPlayerDtoCopyWith<$Res>  {
  factory $UnclaimedPlayerDtoCopyWith(UnclaimedPlayerDto value, $Res Function(UnclaimedPlayerDto) _then) = _$UnclaimedPlayerDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'unclaimed_id') String unclaimedId,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'added_by') String addedBy,@JsonKey(name: 'phone_number') String? phoneNumber,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'player_profile') Map<String, dynamic> playerProfile
});




}
/// @nodoc
class _$UnclaimedPlayerDtoCopyWithImpl<$Res>
    implements $UnclaimedPlayerDtoCopyWith<$Res> {
  _$UnclaimedPlayerDtoCopyWithImpl(this._self, this._then);

  final UnclaimedPlayerDto _self;
  final $Res Function(UnclaimedPlayerDto) _then;

/// Create a copy of UnclaimedPlayerDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unclaimedId = null,Object? displayName = null,Object? addedBy = null,Object? phoneNumber = freezed,Object? createdAt = null,Object? updatedAt = null,Object? playerProfile = null,}) {
  return _then(_self.copyWith(
unclaimedId: null == unclaimedId ? _self.unclaimedId : unclaimedId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,playerProfile: null == playerProfile ? _self.playerProfile : playerProfile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [UnclaimedPlayerDto].
extension UnclaimedPlayerDtoPatterns on UnclaimedPlayerDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnclaimedPlayerDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnclaimedPlayerDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnclaimedPlayerDto value)  $default,){
final _that = this;
switch (_that) {
case _UnclaimedPlayerDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnclaimedPlayerDto value)?  $default,){
final _that = this;
switch (_that) {
case _UnclaimedPlayerDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'unclaimed_id')  String unclaimedId, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'added_by')  String addedBy, @JsonKey(name: 'phone_number')  String? phoneNumber, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'player_profile')  Map<String, dynamic> playerProfile)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnclaimedPlayerDto() when $default != null:
return $default(_that.unclaimedId,_that.displayName,_that.addedBy,_that.phoneNumber,_that.createdAt,_that.updatedAt,_that.playerProfile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'unclaimed_id')  String unclaimedId, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'added_by')  String addedBy, @JsonKey(name: 'phone_number')  String? phoneNumber, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'player_profile')  Map<String, dynamic> playerProfile)  $default,) {final _that = this;
switch (_that) {
case _UnclaimedPlayerDto():
return $default(_that.unclaimedId,_that.displayName,_that.addedBy,_that.phoneNumber,_that.createdAt,_that.updatedAt,_that.playerProfile);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'unclaimed_id')  String unclaimedId, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'added_by')  String addedBy, @JsonKey(name: 'phone_number')  String? phoneNumber, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'player_profile')  Map<String, dynamic> playerProfile)?  $default,) {final _that = this;
switch (_that) {
case _UnclaimedPlayerDto() when $default != null:
return $default(_that.unclaimedId,_that.displayName,_that.addedBy,_that.phoneNumber,_that.createdAt,_that.updatedAt,_that.playerProfile);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnclaimedPlayerDto extends UnclaimedPlayerDto {
  const _UnclaimedPlayerDto({@JsonKey(name: 'unclaimed_id') required this.unclaimedId, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'added_by') required this.addedBy, @JsonKey(name: 'phone_number') this.phoneNumber, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'player_profile') final  Map<String, dynamic> playerProfile = const <String, dynamic>{}}): _playerProfile = playerProfile,super._();
  factory _UnclaimedPlayerDto.fromJson(Map<String, dynamic> json) => _$UnclaimedPlayerDtoFromJson(json);

@override@JsonKey(name: 'unclaimed_id') final  String unclaimedId;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'added_by') final  String addedBy;
@override@JsonKey(name: 'phone_number') final  String? phoneNumber;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;
 final  Map<String, dynamic> _playerProfile;
@override@JsonKey(name: 'player_profile') Map<String, dynamic> get playerProfile {
  if (_playerProfile is EqualUnmodifiableMapView) return _playerProfile;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playerProfile);
}


/// Create a copy of UnclaimedPlayerDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnclaimedPlayerDtoCopyWith<_UnclaimedPlayerDto> get copyWith => __$UnclaimedPlayerDtoCopyWithImpl<_UnclaimedPlayerDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnclaimedPlayerDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnclaimedPlayerDto&&(identical(other.unclaimedId, unclaimedId) || other.unclaimedId == unclaimedId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._playerProfile, _playerProfile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unclaimedId,displayName,addedBy,phoneNumber,createdAt,updatedAt,const DeepCollectionEquality().hash(_playerProfile));

@override
String toString() {
  return 'UnclaimedPlayerDto(unclaimedId: $unclaimedId, displayName: $displayName, addedBy: $addedBy, phoneNumber: $phoneNumber, createdAt: $createdAt, updatedAt: $updatedAt, playerProfile: $playerProfile)';
}


}

/// @nodoc
abstract mixin class _$UnclaimedPlayerDtoCopyWith<$Res> implements $UnclaimedPlayerDtoCopyWith<$Res> {
  factory _$UnclaimedPlayerDtoCopyWith(_UnclaimedPlayerDto value, $Res Function(_UnclaimedPlayerDto) _then) = __$UnclaimedPlayerDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'unclaimed_id') String unclaimedId,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'added_by') String addedBy,@JsonKey(name: 'phone_number') String? phoneNumber,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'player_profile') Map<String, dynamic> playerProfile
});




}
/// @nodoc
class __$UnclaimedPlayerDtoCopyWithImpl<$Res>
    implements _$UnclaimedPlayerDtoCopyWith<$Res> {
  __$UnclaimedPlayerDtoCopyWithImpl(this._self, this._then);

  final _UnclaimedPlayerDto _self;
  final $Res Function(_UnclaimedPlayerDto) _then;

/// Create a copy of UnclaimedPlayerDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unclaimedId = null,Object? displayName = null,Object? addedBy = null,Object? phoneNumber = freezed,Object? createdAt = null,Object? updatedAt = null,Object? playerProfile = null,}) {
  return _then(_UnclaimedPlayerDto(
unclaimedId: null == unclaimedId ? _self.unclaimedId : unclaimedId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,playerProfile: null == playerProfile ? _self._playerProfile : playerProfile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
