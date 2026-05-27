// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_member_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeamMemberDto {

@JsonKey(name: 'membership_id') String get membershipId;@JsonKey(name: 'team_id') String get teamId;@JsonKey(name: 'user_id') String? get userId;@JsonKey(name: 'unclaimed_id') String? get unclaimedId;@JsonKey(name: 'jersey_number') int? get jerseyNumber; String get role;@JsonKey(name: 'added_by') String get addedBy;@JsonKey(name: 'joined_at') String get joinedAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of TeamMemberDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamMemberDtoCopyWith<TeamMemberDto> get copyWith => _$TeamMemberDtoCopyWithImpl<TeamMemberDto>(this as TeamMemberDto, _$identity);

  /// Serializes this TeamMemberDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamMemberDto&&(identical(other.membershipId, membershipId) || other.membershipId == membershipId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.unclaimedId, unclaimedId) || other.unclaimedId == unclaimedId)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.role, role) || other.role == role)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membershipId,teamId,userId,unclaimedId,jerseyNumber,role,addedBy,joinedAt,updatedAt);

@override
String toString() {
  return 'TeamMemberDto(membershipId: $membershipId, teamId: $teamId, userId: $userId, unclaimedId: $unclaimedId, jerseyNumber: $jerseyNumber, role: $role, addedBy: $addedBy, joinedAt: $joinedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TeamMemberDtoCopyWith<$Res>  {
  factory $TeamMemberDtoCopyWith(TeamMemberDto value, $Res Function(TeamMemberDto) _then) = _$TeamMemberDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'membership_id') String membershipId,@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'unclaimed_id') String? unclaimedId,@JsonKey(name: 'jersey_number') int? jerseyNumber, String role,@JsonKey(name: 'added_by') String addedBy,@JsonKey(name: 'joined_at') String joinedAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$TeamMemberDtoCopyWithImpl<$Res>
    implements $TeamMemberDtoCopyWith<$Res> {
  _$TeamMemberDtoCopyWithImpl(this._self, this._then);

  final TeamMemberDto _self;
  final $Res Function(TeamMemberDto) _then;

/// Create a copy of TeamMemberDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? membershipId = null,Object? teamId = null,Object? userId = freezed,Object? unclaimedId = freezed,Object? jerseyNumber = freezed,Object? role = null,Object? addedBy = null,Object? joinedAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
membershipId: null == membershipId ? _self.membershipId : membershipId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,unclaimedId: freezed == unclaimedId ? _self.unclaimedId : unclaimedId // ignore: cast_nullable_to_non_nullable
as String?,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamMemberDto].
extension TeamMemberDtoPatterns on TeamMemberDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamMemberDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamMemberDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamMemberDto value)  $default,){
final _that = this;
switch (_that) {
case _TeamMemberDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamMemberDto value)?  $default,){
final _that = this;
switch (_that) {
case _TeamMemberDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'membership_id')  String membershipId, @JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'unclaimed_id')  String? unclaimedId, @JsonKey(name: 'jersey_number')  int? jerseyNumber,  String role, @JsonKey(name: 'added_by')  String addedBy, @JsonKey(name: 'joined_at')  String joinedAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamMemberDto() when $default != null:
return $default(_that.membershipId,_that.teamId,_that.userId,_that.unclaimedId,_that.jerseyNumber,_that.role,_that.addedBy,_that.joinedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'membership_id')  String membershipId, @JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'unclaimed_id')  String? unclaimedId, @JsonKey(name: 'jersey_number')  int? jerseyNumber,  String role, @JsonKey(name: 'added_by')  String addedBy, @JsonKey(name: 'joined_at')  String joinedAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TeamMemberDto():
return $default(_that.membershipId,_that.teamId,_that.userId,_that.unclaimedId,_that.jerseyNumber,_that.role,_that.addedBy,_that.joinedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'membership_id')  String membershipId, @JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'unclaimed_id')  String? unclaimedId, @JsonKey(name: 'jersey_number')  int? jerseyNumber,  String role, @JsonKey(name: 'added_by')  String addedBy, @JsonKey(name: 'joined_at')  String joinedAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TeamMemberDto() when $default != null:
return $default(_that.membershipId,_that.teamId,_that.userId,_that.unclaimedId,_that.jerseyNumber,_that.role,_that.addedBy,_that.joinedAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamMemberDto extends TeamMemberDto {
  const _TeamMemberDto({@JsonKey(name: 'membership_id') required this.membershipId, @JsonKey(name: 'team_id') required this.teamId, @JsonKey(name: 'user_id') this.userId, @JsonKey(name: 'unclaimed_id') this.unclaimedId, @JsonKey(name: 'jersey_number') this.jerseyNumber, this.role = 'player', @JsonKey(name: 'added_by') required this.addedBy, @JsonKey(name: 'joined_at') required this.joinedAt, @JsonKey(name: 'updated_at') required this.updatedAt}): super._();
  factory _TeamMemberDto.fromJson(Map<String, dynamic> json) => _$TeamMemberDtoFromJson(json);

@override@JsonKey(name: 'membership_id') final  String membershipId;
@override@JsonKey(name: 'team_id') final  String teamId;
@override@JsonKey(name: 'user_id') final  String? userId;
@override@JsonKey(name: 'unclaimed_id') final  String? unclaimedId;
@override@JsonKey(name: 'jersey_number') final  int? jerseyNumber;
@override@JsonKey() final  String role;
@override@JsonKey(name: 'added_by') final  String addedBy;
@override@JsonKey(name: 'joined_at') final  String joinedAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of TeamMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamMemberDtoCopyWith<_TeamMemberDto> get copyWith => __$TeamMemberDtoCopyWithImpl<_TeamMemberDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamMemberDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamMemberDto&&(identical(other.membershipId, membershipId) || other.membershipId == membershipId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.unclaimedId, unclaimedId) || other.unclaimedId == unclaimedId)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.role, role) || other.role == role)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membershipId,teamId,userId,unclaimedId,jerseyNumber,role,addedBy,joinedAt,updatedAt);

@override
String toString() {
  return 'TeamMemberDto(membershipId: $membershipId, teamId: $teamId, userId: $userId, unclaimedId: $unclaimedId, jerseyNumber: $jerseyNumber, role: $role, addedBy: $addedBy, joinedAt: $joinedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TeamMemberDtoCopyWith<$Res> implements $TeamMemberDtoCopyWith<$Res> {
  factory _$TeamMemberDtoCopyWith(_TeamMemberDto value, $Res Function(_TeamMemberDto) _then) = __$TeamMemberDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'membership_id') String membershipId,@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'unclaimed_id') String? unclaimedId,@JsonKey(name: 'jersey_number') int? jerseyNumber, String role,@JsonKey(name: 'added_by') String addedBy,@JsonKey(name: 'joined_at') String joinedAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$TeamMemberDtoCopyWithImpl<$Res>
    implements _$TeamMemberDtoCopyWith<$Res> {
  __$TeamMemberDtoCopyWithImpl(this._self, this._then);

  final _TeamMemberDto _self;
  final $Res Function(_TeamMemberDto) _then;

/// Create a copy of TeamMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? membershipId = null,Object? teamId = null,Object? userId = freezed,Object? unclaimedId = freezed,Object? jerseyNumber = freezed,Object? role = null,Object? addedBy = null,Object? joinedAt = null,Object? updatedAt = null,}) {
  return _then(_TeamMemberDto(
membershipId: null == membershipId ? _self.membershipId : membershipId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,unclaimedId: freezed == unclaimedId ? _self.unclaimedId : unclaimedId // ignore: cast_nullable_to_non_nullable
as String?,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as int?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,addedBy: null == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
