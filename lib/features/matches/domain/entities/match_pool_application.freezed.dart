// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_pool_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchPoolApplication {

 String get id; String get requestId; TeamId get applicantTeamId; String get applicantUserId; List<String> get applicantXi; String? get applicantKeeperId; String? get message; PoolApplicationStatus get status; String? get decisionNote; DateTime? get decidedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of MatchPoolApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchPoolApplicationCopyWith<MatchPoolApplication> get copyWith => _$MatchPoolApplicationCopyWithImpl<MatchPoolApplication>(this as MatchPoolApplication, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchPoolApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.applicantTeamId, applicantTeamId) || other.applicantTeamId == applicantTeamId)&&(identical(other.applicantUserId, applicantUserId) || other.applicantUserId == applicantUserId)&&const DeepCollectionEquality().equals(other.applicantXi, applicantXi)&&(identical(other.applicantKeeperId, applicantKeeperId) || other.applicantKeeperId == applicantKeeperId)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,requestId,applicantTeamId,applicantUserId,const DeepCollectionEquality().hash(applicantXi),applicantKeeperId,message,status,decisionNote,decidedAt,createdAt,updatedAt);

@override
String toString() {
  return 'MatchPoolApplication(id: $id, requestId: $requestId, applicantTeamId: $applicantTeamId, applicantUserId: $applicantUserId, applicantXi: $applicantXi, applicantKeeperId: $applicantKeeperId, message: $message, status: $status, decisionNote: $decisionNote, decidedAt: $decidedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MatchPoolApplicationCopyWith<$Res>  {
  factory $MatchPoolApplicationCopyWith(MatchPoolApplication value, $Res Function(MatchPoolApplication) _then) = _$MatchPoolApplicationCopyWithImpl;
@useResult
$Res call({
 String id, String requestId, TeamId applicantTeamId, String applicantUserId, List<String> applicantXi, String? applicantKeeperId, String? message, PoolApplicationStatus status, String? decisionNote, DateTime? decidedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$MatchPoolApplicationCopyWithImpl<$Res>
    implements $MatchPoolApplicationCopyWith<$Res> {
  _$MatchPoolApplicationCopyWithImpl(this._self, this._then);

  final MatchPoolApplication _self;
  final $Res Function(MatchPoolApplication) _then;

/// Create a copy of MatchPoolApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestId = null,Object? applicantTeamId = null,Object? applicantUserId = null,Object? applicantXi = null,Object? applicantKeeperId = freezed,Object? message = freezed,Object? status = null,Object? decisionNote = freezed,Object? decidedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,applicantTeamId: null == applicantTeamId ? _self.applicantTeamId : applicantTeamId // ignore: cast_nullable_to_non_nullable
as TeamId,applicantUserId: null == applicantUserId ? _self.applicantUserId : applicantUserId // ignore: cast_nullable_to_non_nullable
as String,applicantXi: null == applicantXi ? _self.applicantXi : applicantXi // ignore: cast_nullable_to_non_nullable
as List<String>,applicantKeeperId: freezed == applicantKeeperId ? _self.applicantKeeperId : applicantKeeperId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PoolApplicationStatus,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchPoolApplication].
extension MatchPoolApplicationPatterns on MatchPoolApplication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchPoolApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchPoolApplication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchPoolApplication value)  $default,){
final _that = this;
switch (_that) {
case _MatchPoolApplication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchPoolApplication value)?  $default,){
final _that = this;
switch (_that) {
case _MatchPoolApplication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String requestId,  TeamId applicantTeamId,  String applicantUserId,  List<String> applicantXi,  String? applicantKeeperId,  String? message,  PoolApplicationStatus status,  String? decisionNote,  DateTime? decidedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchPoolApplication() when $default != null:
return $default(_that.id,_that.requestId,_that.applicantTeamId,_that.applicantUserId,_that.applicantXi,_that.applicantKeeperId,_that.message,_that.status,_that.decisionNote,_that.decidedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String requestId,  TeamId applicantTeamId,  String applicantUserId,  List<String> applicantXi,  String? applicantKeeperId,  String? message,  PoolApplicationStatus status,  String? decisionNote,  DateTime? decidedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MatchPoolApplication():
return $default(_that.id,_that.requestId,_that.applicantTeamId,_that.applicantUserId,_that.applicantXi,_that.applicantKeeperId,_that.message,_that.status,_that.decisionNote,_that.decidedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String requestId,  TeamId applicantTeamId,  String applicantUserId,  List<String> applicantXi,  String? applicantKeeperId,  String? message,  PoolApplicationStatus status,  String? decisionNote,  DateTime? decidedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchPoolApplication() when $default != null:
return $default(_that.id,_that.requestId,_that.applicantTeamId,_that.applicantUserId,_that.applicantXi,_that.applicantKeeperId,_that.message,_that.status,_that.decisionNote,_that.decidedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MatchPoolApplication implements MatchPoolApplication {
  const _MatchPoolApplication({required this.id, required this.requestId, required this.applicantTeamId, required this.applicantUserId, final  List<String> applicantXi = const <String>[], this.applicantKeeperId, this.message, required this.status, this.decisionNote, this.decidedAt, required this.createdAt, required this.updatedAt}): _applicantXi = applicantXi;
  

@override final  String id;
@override final  String requestId;
@override final  TeamId applicantTeamId;
@override final  String applicantUserId;
 final  List<String> _applicantXi;
@override@JsonKey() List<String> get applicantXi {
  if (_applicantXi is EqualUnmodifiableListView) return _applicantXi;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_applicantXi);
}

@override final  String? applicantKeeperId;
@override final  String? message;
@override final  PoolApplicationStatus status;
@override final  String? decisionNote;
@override final  DateTime? decidedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of MatchPoolApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchPoolApplicationCopyWith<_MatchPoolApplication> get copyWith => __$MatchPoolApplicationCopyWithImpl<_MatchPoolApplication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchPoolApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.applicantTeamId, applicantTeamId) || other.applicantTeamId == applicantTeamId)&&(identical(other.applicantUserId, applicantUserId) || other.applicantUserId == applicantUserId)&&const DeepCollectionEquality().equals(other._applicantXi, _applicantXi)&&(identical(other.applicantKeeperId, applicantKeeperId) || other.applicantKeeperId == applicantKeeperId)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,requestId,applicantTeamId,applicantUserId,const DeepCollectionEquality().hash(_applicantXi),applicantKeeperId,message,status,decisionNote,decidedAt,createdAt,updatedAt);

@override
String toString() {
  return 'MatchPoolApplication(id: $id, requestId: $requestId, applicantTeamId: $applicantTeamId, applicantUserId: $applicantUserId, applicantXi: $applicantXi, applicantKeeperId: $applicantKeeperId, message: $message, status: $status, decisionNote: $decisionNote, decidedAt: $decidedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MatchPoolApplicationCopyWith<$Res> implements $MatchPoolApplicationCopyWith<$Res> {
  factory _$MatchPoolApplicationCopyWith(_MatchPoolApplication value, $Res Function(_MatchPoolApplication) _then) = __$MatchPoolApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String requestId, TeamId applicantTeamId, String applicantUserId, List<String> applicantXi, String? applicantKeeperId, String? message, PoolApplicationStatus status, String? decisionNote, DateTime? decidedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$MatchPoolApplicationCopyWithImpl<$Res>
    implements _$MatchPoolApplicationCopyWith<$Res> {
  __$MatchPoolApplicationCopyWithImpl(this._self, this._then);

  final _MatchPoolApplication _self;
  final $Res Function(_MatchPoolApplication) _then;

/// Create a copy of MatchPoolApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestId = null,Object? applicantTeamId = null,Object? applicantUserId = null,Object? applicantXi = null,Object? applicantKeeperId = freezed,Object? message = freezed,Object? status = null,Object? decisionNote = freezed,Object? decidedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MatchPoolApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,applicantTeamId: null == applicantTeamId ? _self.applicantTeamId : applicantTeamId // ignore: cast_nullable_to_non_nullable
as TeamId,applicantUserId: null == applicantUserId ? _self.applicantUserId : applicantUserId // ignore: cast_nullable_to_non_nullable
as String,applicantXi: null == applicantXi ? _self._applicantXi : applicantXi // ignore: cast_nullable_to_non_nullable
as List<String>,applicantKeeperId: freezed == applicantKeeperId ? _self.applicantKeeperId : applicantKeeperId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PoolApplicationStatus,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
