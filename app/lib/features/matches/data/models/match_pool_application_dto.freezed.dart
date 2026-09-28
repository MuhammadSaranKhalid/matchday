// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_pool_application_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchPoolApplicationDto {

@JsonKey(name: 'application_id') String get applicationId;@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'applicant_team_id') String get applicantTeamId;@JsonKey(name: 'applicant_user_id') String get applicantUserId;@JsonKey(name: 'applicant_xi') List<String> get applicantXi;@JsonKey(name: 'applicant_keeper_id') String? get applicantKeeperId; String? get message; String get status;@JsonKey(name: 'decision_note') String? get decisionNote;@JsonKey(name: 'decided_at') String? get decidedAt;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of MatchPoolApplicationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchPoolApplicationDtoCopyWith<MatchPoolApplicationDto> get copyWith => _$MatchPoolApplicationDtoCopyWithImpl<MatchPoolApplicationDto>(this as MatchPoolApplicationDto, _$identity);

  /// Serializes this MatchPoolApplicationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchPoolApplicationDto&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.applicantTeamId, applicantTeamId) || other.applicantTeamId == applicantTeamId)&&(identical(other.applicantUserId, applicantUserId) || other.applicantUserId == applicantUserId)&&const DeepCollectionEquality().equals(other.applicantXi, applicantXi)&&(identical(other.applicantKeeperId, applicantKeeperId) || other.applicantKeeperId == applicantKeeperId)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,applicationId,requestId,applicantTeamId,applicantUserId,const DeepCollectionEquality().hash(applicantXi),applicantKeeperId,message,status,decisionNote,decidedAt,createdAt,updatedAt);

@override
String toString() {
  return 'MatchPoolApplicationDto(applicationId: $applicationId, requestId: $requestId, applicantTeamId: $applicantTeamId, applicantUserId: $applicantUserId, applicantXi: $applicantXi, applicantKeeperId: $applicantKeeperId, message: $message, status: $status, decisionNote: $decisionNote, decidedAt: $decidedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MatchPoolApplicationDtoCopyWith<$Res>  {
  factory $MatchPoolApplicationDtoCopyWith(MatchPoolApplicationDto value, $Res Function(MatchPoolApplicationDto) _then) = _$MatchPoolApplicationDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'application_id') String applicationId,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'applicant_team_id') String applicantTeamId,@JsonKey(name: 'applicant_user_id') String applicantUserId,@JsonKey(name: 'applicant_xi') List<String> applicantXi,@JsonKey(name: 'applicant_keeper_id') String? applicantKeeperId, String? message, String status,@JsonKey(name: 'decision_note') String? decisionNote,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$MatchPoolApplicationDtoCopyWithImpl<$Res>
    implements $MatchPoolApplicationDtoCopyWith<$Res> {
  _$MatchPoolApplicationDtoCopyWithImpl(this._self, this._then);

  final MatchPoolApplicationDto _self;
  final $Res Function(MatchPoolApplicationDto) _then;

/// Create a copy of MatchPoolApplicationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? applicationId = null,Object? requestId = null,Object? applicantTeamId = null,Object? applicantUserId = null,Object? applicantXi = null,Object? applicantKeeperId = freezed,Object? message = freezed,Object? status = null,Object? decisionNote = freezed,Object? decidedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,applicantTeamId: null == applicantTeamId ? _self.applicantTeamId : applicantTeamId // ignore: cast_nullable_to_non_nullable
as String,applicantUserId: null == applicantUserId ? _self.applicantUserId : applicantUserId // ignore: cast_nullable_to_non_nullable
as String,applicantXi: null == applicantXi ? _self.applicantXi : applicantXi // ignore: cast_nullable_to_non_nullable
as List<String>,applicantKeeperId: freezed == applicantKeeperId ? _self.applicantKeeperId : applicantKeeperId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchPoolApplicationDto].
extension MatchPoolApplicationDtoPatterns on MatchPoolApplicationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchPoolApplicationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchPoolApplicationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchPoolApplicationDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchPoolApplicationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchPoolApplicationDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchPoolApplicationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'application_id')  String applicationId, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'applicant_team_id')  String applicantTeamId, @JsonKey(name: 'applicant_user_id')  String applicantUserId, @JsonKey(name: 'applicant_xi')  List<String> applicantXi, @JsonKey(name: 'applicant_keeper_id')  String? applicantKeeperId,  String? message,  String status, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchPoolApplicationDto() when $default != null:
return $default(_that.applicationId,_that.requestId,_that.applicantTeamId,_that.applicantUserId,_that.applicantXi,_that.applicantKeeperId,_that.message,_that.status,_that.decisionNote,_that.decidedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'application_id')  String applicationId, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'applicant_team_id')  String applicantTeamId, @JsonKey(name: 'applicant_user_id')  String applicantUserId, @JsonKey(name: 'applicant_xi')  List<String> applicantXi, @JsonKey(name: 'applicant_keeper_id')  String? applicantKeeperId,  String? message,  String status, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MatchPoolApplicationDto():
return $default(_that.applicationId,_that.requestId,_that.applicantTeamId,_that.applicantUserId,_that.applicantXi,_that.applicantKeeperId,_that.message,_that.status,_that.decisionNote,_that.decidedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'application_id')  String applicationId, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'applicant_team_id')  String applicantTeamId, @JsonKey(name: 'applicant_user_id')  String applicantUserId, @JsonKey(name: 'applicant_xi')  List<String> applicantXi, @JsonKey(name: 'applicant_keeper_id')  String? applicantKeeperId,  String? message,  String status, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchPoolApplicationDto() when $default != null:
return $default(_that.applicationId,_that.requestId,_that.applicantTeamId,_that.applicantUserId,_that.applicantXi,_that.applicantKeeperId,_that.message,_that.status,_that.decisionNote,_that.decidedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchPoolApplicationDto extends MatchPoolApplicationDto {
  const _MatchPoolApplicationDto({@JsonKey(name: 'application_id') required this.applicationId, @JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'applicant_team_id') required this.applicantTeamId, @JsonKey(name: 'applicant_user_id') required this.applicantUserId, @JsonKey(name: 'applicant_xi') final  List<String> applicantXi = const <String>[], @JsonKey(name: 'applicant_keeper_id') this.applicantKeeperId, this.message, this.status = 'pending', @JsonKey(name: 'decision_note') this.decisionNote, @JsonKey(name: 'decided_at') this.decidedAt, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _applicantXi = applicantXi,super._();
  factory _MatchPoolApplicationDto.fromJson(Map<String, dynamic> json) => _$MatchPoolApplicationDtoFromJson(json);

@override@JsonKey(name: 'application_id') final  String applicationId;
@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'applicant_team_id') final  String applicantTeamId;
@override@JsonKey(name: 'applicant_user_id') final  String applicantUserId;
 final  List<String> _applicantXi;
@override@JsonKey(name: 'applicant_xi') List<String> get applicantXi {
  if (_applicantXi is EqualUnmodifiableListView) return _applicantXi;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_applicantXi);
}

@override@JsonKey(name: 'applicant_keeper_id') final  String? applicantKeeperId;
@override final  String? message;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'decision_note') final  String? decisionNote;
@override@JsonKey(name: 'decided_at') final  String? decidedAt;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of MatchPoolApplicationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchPoolApplicationDtoCopyWith<_MatchPoolApplicationDto> get copyWith => __$MatchPoolApplicationDtoCopyWithImpl<_MatchPoolApplicationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchPoolApplicationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchPoolApplicationDto&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.applicantTeamId, applicantTeamId) || other.applicantTeamId == applicantTeamId)&&(identical(other.applicantUserId, applicantUserId) || other.applicantUserId == applicantUserId)&&const DeepCollectionEquality().equals(other._applicantXi, _applicantXi)&&(identical(other.applicantKeeperId, applicantKeeperId) || other.applicantKeeperId == applicantKeeperId)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,applicationId,requestId,applicantTeamId,applicantUserId,const DeepCollectionEquality().hash(_applicantXi),applicantKeeperId,message,status,decisionNote,decidedAt,createdAt,updatedAt);

@override
String toString() {
  return 'MatchPoolApplicationDto(applicationId: $applicationId, requestId: $requestId, applicantTeamId: $applicantTeamId, applicantUserId: $applicantUserId, applicantXi: $applicantXi, applicantKeeperId: $applicantKeeperId, message: $message, status: $status, decisionNote: $decisionNote, decidedAt: $decidedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MatchPoolApplicationDtoCopyWith<$Res> implements $MatchPoolApplicationDtoCopyWith<$Res> {
  factory _$MatchPoolApplicationDtoCopyWith(_MatchPoolApplicationDto value, $Res Function(_MatchPoolApplicationDto) _then) = __$MatchPoolApplicationDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'application_id') String applicationId,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'applicant_team_id') String applicantTeamId,@JsonKey(name: 'applicant_user_id') String applicantUserId,@JsonKey(name: 'applicant_xi') List<String> applicantXi,@JsonKey(name: 'applicant_keeper_id') String? applicantKeeperId, String? message, String status,@JsonKey(name: 'decision_note') String? decisionNote,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$MatchPoolApplicationDtoCopyWithImpl<$Res>
    implements _$MatchPoolApplicationDtoCopyWith<$Res> {
  __$MatchPoolApplicationDtoCopyWithImpl(this._self, this._then);

  final _MatchPoolApplicationDto _self;
  final $Res Function(_MatchPoolApplicationDto) _then;

/// Create a copy of MatchPoolApplicationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? applicationId = null,Object? requestId = null,Object? applicantTeamId = null,Object? applicantUserId = null,Object? applicantXi = null,Object? applicantKeeperId = freezed,Object? message = freezed,Object? status = null,Object? decisionNote = freezed,Object? decidedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MatchPoolApplicationDto(
applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,applicantTeamId: null == applicantTeamId ? _self.applicantTeamId : applicantTeamId // ignore: cast_nullable_to_non_nullable
as String,applicantUserId: null == applicantUserId ? _self.applicantUserId : applicantUserId // ignore: cast_nullable_to_non_nullable
as String,applicantXi: null == applicantXi ? _self._applicantXi : applicantXi // ignore: cast_nullable_to_non_nullable
as List<String>,applicantKeeperId: freezed == applicantKeeperId ? _self.applicantKeeperId : applicantKeeperId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
