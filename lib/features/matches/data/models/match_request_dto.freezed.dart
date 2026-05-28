// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchRequestDto {

@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'from_team_id') String get fromTeamId;@JsonKey(name: 'to_team_id') String? get toTeamId;@JsonKey(name: 'requested_by') String get requestedBy;@JsonKey(name: 'proposed_start_time') String? get proposedStartTime;@JsonKey(name: 'proposed_venue') String? get proposedVenue;@JsonKey(name: 'proposed_format') Map<String, dynamic>? get proposedFormat; String? get message;@JsonKey(name: 'players_per_side') int get playersPerSide;@JsonKey(name: 'from_team_xi') List<String> get fromTeamXi;@JsonKey(name: 'from_team_keeper_id') String? get fromTeamKeeperId;@JsonKey(name: 'countered_start_time') String? get counteredStartTime;@JsonKey(name: 'countered_venue') String? get counteredVenue;@JsonKey(name: 'countered_format') Map<String, dynamic>? get counteredFormat;@JsonKey(name: 'countered_players_per_side') int? get counteredPlayersPerSide; String get status;@JsonKey(name: 'decided_by') String? get decidedBy;@JsonKey(name: 'decided_at') String? get decidedAt;@JsonKey(name: 'decision_note') String? get decisionNote;@JsonKey(name: 'decision_reason') String? get decisionReason;@JsonKey(name: 'match_id') String? get matchId;@JsonKey(name: 'share_code') String? get shareCode;@JsonKey(name: 'code_expires_at') String? get codeExpiresAt;@JsonKey(name: 'proposal_expires_at') String? get proposalExpiresAt;@JsonKey(name: 'counter_expires_at') String? get counterExpiresAt;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of MatchRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchRequestDtoCopyWith<MatchRequestDto> get copyWith => _$MatchRequestDtoCopyWithImpl<MatchRequestDto>(this as MatchRequestDto, _$identity);

  /// Serializes this MatchRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchRequestDto&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.fromTeamId, fromTeamId) || other.fromTeamId == fromTeamId)&&(identical(other.toTeamId, toTeamId) || other.toTeamId == toTeamId)&&(identical(other.requestedBy, requestedBy) || other.requestedBy == requestedBy)&&(identical(other.proposedStartTime, proposedStartTime) || other.proposedStartTime == proposedStartTime)&&(identical(other.proposedVenue, proposedVenue) || other.proposedVenue == proposedVenue)&&const DeepCollectionEquality().equals(other.proposedFormat, proposedFormat)&&(identical(other.message, message) || other.message == message)&&(identical(other.playersPerSide, playersPerSide) || other.playersPerSide == playersPerSide)&&const DeepCollectionEquality().equals(other.fromTeamXi, fromTeamXi)&&(identical(other.fromTeamKeeperId, fromTeamKeeperId) || other.fromTeamKeeperId == fromTeamKeeperId)&&(identical(other.counteredStartTime, counteredStartTime) || other.counteredStartTime == counteredStartTime)&&(identical(other.counteredVenue, counteredVenue) || other.counteredVenue == counteredVenue)&&const DeepCollectionEquality().equals(other.counteredFormat, counteredFormat)&&(identical(other.counteredPlayersPerSide, counteredPlayersPerSide) || other.counteredPlayersPerSide == counteredPlayersPerSide)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decisionReason, decisionReason) || other.decisionReason == decisionReason)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.shareCode, shareCode) || other.shareCode == shareCode)&&(identical(other.codeExpiresAt, codeExpiresAt) || other.codeExpiresAt == codeExpiresAt)&&(identical(other.proposalExpiresAt, proposalExpiresAt) || other.proposalExpiresAt == proposalExpiresAt)&&(identical(other.counterExpiresAt, counterExpiresAt) || other.counterExpiresAt == counterExpiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,requestId,fromTeamId,toTeamId,requestedBy,proposedStartTime,proposedVenue,const DeepCollectionEquality().hash(proposedFormat),message,playersPerSide,const DeepCollectionEquality().hash(fromTeamXi),fromTeamKeeperId,counteredStartTime,counteredVenue,const DeepCollectionEquality().hash(counteredFormat),counteredPlayersPerSide,status,decidedBy,decidedAt,decisionNote,decisionReason,matchId,shareCode,codeExpiresAt,proposalExpiresAt,counterExpiresAt,createdAt,updatedAt]);

@override
String toString() {
  return 'MatchRequestDto(requestId: $requestId, fromTeamId: $fromTeamId, toTeamId: $toTeamId, requestedBy: $requestedBy, proposedStartTime: $proposedStartTime, proposedVenue: $proposedVenue, proposedFormat: $proposedFormat, message: $message, playersPerSide: $playersPerSide, fromTeamXi: $fromTeamXi, fromTeamKeeperId: $fromTeamKeeperId, counteredStartTime: $counteredStartTime, counteredVenue: $counteredVenue, counteredFormat: $counteredFormat, counteredPlayersPerSide: $counteredPlayersPerSide, status: $status, decidedBy: $decidedBy, decidedAt: $decidedAt, decisionNote: $decisionNote, decisionReason: $decisionReason, matchId: $matchId, shareCode: $shareCode, codeExpiresAt: $codeExpiresAt, proposalExpiresAt: $proposalExpiresAt, counterExpiresAt: $counterExpiresAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MatchRequestDtoCopyWith<$Res>  {
  factory $MatchRequestDtoCopyWith(MatchRequestDto value, $Res Function(MatchRequestDto) _then) = _$MatchRequestDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'from_team_id') String fromTeamId,@JsonKey(name: 'to_team_id') String? toTeamId,@JsonKey(name: 'requested_by') String requestedBy,@JsonKey(name: 'proposed_start_time') String? proposedStartTime,@JsonKey(name: 'proposed_venue') String? proposedVenue,@JsonKey(name: 'proposed_format') Map<String, dynamic>? proposedFormat, String? message,@JsonKey(name: 'players_per_side') int playersPerSide,@JsonKey(name: 'from_team_xi') List<String> fromTeamXi,@JsonKey(name: 'from_team_keeper_id') String? fromTeamKeeperId,@JsonKey(name: 'countered_start_time') String? counteredStartTime,@JsonKey(name: 'countered_venue') String? counteredVenue,@JsonKey(name: 'countered_format') Map<String, dynamic>? counteredFormat,@JsonKey(name: 'countered_players_per_side') int? counteredPlayersPerSide, String status,@JsonKey(name: 'decided_by') String? decidedBy,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'decision_note') String? decisionNote,@JsonKey(name: 'decision_reason') String? decisionReason,@JsonKey(name: 'match_id') String? matchId,@JsonKey(name: 'share_code') String? shareCode,@JsonKey(name: 'code_expires_at') String? codeExpiresAt,@JsonKey(name: 'proposal_expires_at') String? proposalExpiresAt,@JsonKey(name: 'counter_expires_at') String? counterExpiresAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$MatchRequestDtoCopyWithImpl<$Res>
    implements $MatchRequestDtoCopyWith<$Res> {
  _$MatchRequestDtoCopyWithImpl(this._self, this._then);

  final MatchRequestDto _self;
  final $Res Function(MatchRequestDto) _then;

/// Create a copy of MatchRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? fromTeamId = null,Object? toTeamId = freezed,Object? requestedBy = null,Object? proposedStartTime = freezed,Object? proposedVenue = freezed,Object? proposedFormat = freezed,Object? message = freezed,Object? playersPerSide = null,Object? fromTeamXi = null,Object? fromTeamKeeperId = freezed,Object? counteredStartTime = freezed,Object? counteredVenue = freezed,Object? counteredFormat = freezed,Object? counteredPlayersPerSide = freezed,Object? status = null,Object? decidedBy = freezed,Object? decidedAt = freezed,Object? decisionNote = freezed,Object? decisionReason = freezed,Object? matchId = freezed,Object? shareCode = freezed,Object? codeExpiresAt = freezed,Object? proposalExpiresAt = freezed,Object? counterExpiresAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,fromTeamId: null == fromTeamId ? _self.fromTeamId : fromTeamId // ignore: cast_nullable_to_non_nullable
as String,toTeamId: freezed == toTeamId ? _self.toTeamId : toTeamId // ignore: cast_nullable_to_non_nullable
as String?,requestedBy: null == requestedBy ? _self.requestedBy : requestedBy // ignore: cast_nullable_to_non_nullable
as String,proposedStartTime: freezed == proposedStartTime ? _self.proposedStartTime : proposedStartTime // ignore: cast_nullable_to_non_nullable
as String?,proposedVenue: freezed == proposedVenue ? _self.proposedVenue : proposedVenue // ignore: cast_nullable_to_non_nullable
as String?,proposedFormat: freezed == proposedFormat ? _self.proposedFormat : proposedFormat // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,playersPerSide: null == playersPerSide ? _self.playersPerSide : playersPerSide // ignore: cast_nullable_to_non_nullable
as int,fromTeamXi: null == fromTeamXi ? _self.fromTeamXi : fromTeamXi // ignore: cast_nullable_to_non_nullable
as List<String>,fromTeamKeeperId: freezed == fromTeamKeeperId ? _self.fromTeamKeeperId : fromTeamKeeperId // ignore: cast_nullable_to_non_nullable
as String?,counteredStartTime: freezed == counteredStartTime ? _self.counteredStartTime : counteredStartTime // ignore: cast_nullable_to_non_nullable
as String?,counteredVenue: freezed == counteredVenue ? _self.counteredVenue : counteredVenue // ignore: cast_nullable_to_non_nullable
as String?,counteredFormat: freezed == counteredFormat ? _self.counteredFormat : counteredFormat // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,counteredPlayersPerSide: freezed == counteredPlayersPerSide ? _self.counteredPlayersPerSide : counteredPlayersPerSide // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decisionReason: freezed == decisionReason ? _self.decisionReason : decisionReason // ignore: cast_nullable_to_non_nullable
as String?,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,shareCode: freezed == shareCode ? _self.shareCode : shareCode // ignore: cast_nullable_to_non_nullable
as String?,codeExpiresAt: freezed == codeExpiresAt ? _self.codeExpiresAt : codeExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,proposalExpiresAt: freezed == proposalExpiresAt ? _self.proposalExpiresAt : proposalExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,counterExpiresAt: freezed == counterExpiresAt ? _self.counterExpiresAt : counterExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchRequestDto].
extension MatchRequestDtoPatterns on MatchRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _MatchRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _MatchRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'from_team_id')  String fromTeamId, @JsonKey(name: 'to_team_id')  String? toTeamId, @JsonKey(name: 'requested_by')  String requestedBy, @JsonKey(name: 'proposed_start_time')  String? proposedStartTime, @JsonKey(name: 'proposed_venue')  String? proposedVenue, @JsonKey(name: 'proposed_format')  Map<String, dynamic>? proposedFormat,  String? message, @JsonKey(name: 'players_per_side')  int playersPerSide, @JsonKey(name: 'from_team_xi')  List<String> fromTeamXi, @JsonKey(name: 'from_team_keeper_id')  String? fromTeamKeeperId, @JsonKey(name: 'countered_start_time')  String? counteredStartTime, @JsonKey(name: 'countered_venue')  String? counteredVenue, @JsonKey(name: 'countered_format')  Map<String, dynamic>? counteredFormat, @JsonKey(name: 'countered_players_per_side')  int? counteredPlayersPerSide,  String status, @JsonKey(name: 'decided_by')  String? decidedBy, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'decision_reason')  String? decisionReason, @JsonKey(name: 'match_id')  String? matchId, @JsonKey(name: 'share_code')  String? shareCode, @JsonKey(name: 'code_expires_at')  String? codeExpiresAt, @JsonKey(name: 'proposal_expires_at')  String? proposalExpiresAt, @JsonKey(name: 'counter_expires_at')  String? counterExpiresAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchRequestDto() when $default != null:
return $default(_that.requestId,_that.fromTeamId,_that.toTeamId,_that.requestedBy,_that.proposedStartTime,_that.proposedVenue,_that.proposedFormat,_that.message,_that.playersPerSide,_that.fromTeamXi,_that.fromTeamKeeperId,_that.counteredStartTime,_that.counteredVenue,_that.counteredFormat,_that.counteredPlayersPerSide,_that.status,_that.decidedBy,_that.decidedAt,_that.decisionNote,_that.decisionReason,_that.matchId,_that.shareCode,_that.codeExpiresAt,_that.proposalExpiresAt,_that.counterExpiresAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'from_team_id')  String fromTeamId, @JsonKey(name: 'to_team_id')  String? toTeamId, @JsonKey(name: 'requested_by')  String requestedBy, @JsonKey(name: 'proposed_start_time')  String? proposedStartTime, @JsonKey(name: 'proposed_venue')  String? proposedVenue, @JsonKey(name: 'proposed_format')  Map<String, dynamic>? proposedFormat,  String? message, @JsonKey(name: 'players_per_side')  int playersPerSide, @JsonKey(name: 'from_team_xi')  List<String> fromTeamXi, @JsonKey(name: 'from_team_keeper_id')  String? fromTeamKeeperId, @JsonKey(name: 'countered_start_time')  String? counteredStartTime, @JsonKey(name: 'countered_venue')  String? counteredVenue, @JsonKey(name: 'countered_format')  Map<String, dynamic>? counteredFormat, @JsonKey(name: 'countered_players_per_side')  int? counteredPlayersPerSide,  String status, @JsonKey(name: 'decided_by')  String? decidedBy, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'decision_reason')  String? decisionReason, @JsonKey(name: 'match_id')  String? matchId, @JsonKey(name: 'share_code')  String? shareCode, @JsonKey(name: 'code_expires_at')  String? codeExpiresAt, @JsonKey(name: 'proposal_expires_at')  String? proposalExpiresAt, @JsonKey(name: 'counter_expires_at')  String? counterExpiresAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MatchRequestDto():
return $default(_that.requestId,_that.fromTeamId,_that.toTeamId,_that.requestedBy,_that.proposedStartTime,_that.proposedVenue,_that.proposedFormat,_that.message,_that.playersPerSide,_that.fromTeamXi,_that.fromTeamKeeperId,_that.counteredStartTime,_that.counteredVenue,_that.counteredFormat,_that.counteredPlayersPerSide,_that.status,_that.decidedBy,_that.decidedAt,_that.decisionNote,_that.decisionReason,_that.matchId,_that.shareCode,_that.codeExpiresAt,_that.proposalExpiresAt,_that.counterExpiresAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'from_team_id')  String fromTeamId, @JsonKey(name: 'to_team_id')  String? toTeamId, @JsonKey(name: 'requested_by')  String requestedBy, @JsonKey(name: 'proposed_start_time')  String? proposedStartTime, @JsonKey(name: 'proposed_venue')  String? proposedVenue, @JsonKey(name: 'proposed_format')  Map<String, dynamic>? proposedFormat,  String? message, @JsonKey(name: 'players_per_side')  int playersPerSide, @JsonKey(name: 'from_team_xi')  List<String> fromTeamXi, @JsonKey(name: 'from_team_keeper_id')  String? fromTeamKeeperId, @JsonKey(name: 'countered_start_time')  String? counteredStartTime, @JsonKey(name: 'countered_venue')  String? counteredVenue, @JsonKey(name: 'countered_format')  Map<String, dynamic>? counteredFormat, @JsonKey(name: 'countered_players_per_side')  int? counteredPlayersPerSide,  String status, @JsonKey(name: 'decided_by')  String? decidedBy, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'decision_reason')  String? decisionReason, @JsonKey(name: 'match_id')  String? matchId, @JsonKey(name: 'share_code')  String? shareCode, @JsonKey(name: 'code_expires_at')  String? codeExpiresAt, @JsonKey(name: 'proposal_expires_at')  String? proposalExpiresAt, @JsonKey(name: 'counter_expires_at')  String? counterExpiresAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchRequestDto() when $default != null:
return $default(_that.requestId,_that.fromTeamId,_that.toTeamId,_that.requestedBy,_that.proposedStartTime,_that.proposedVenue,_that.proposedFormat,_that.message,_that.playersPerSide,_that.fromTeamXi,_that.fromTeamKeeperId,_that.counteredStartTime,_that.counteredVenue,_that.counteredFormat,_that.counteredPlayersPerSide,_that.status,_that.decidedBy,_that.decidedAt,_that.decisionNote,_that.decisionReason,_that.matchId,_that.shareCode,_that.codeExpiresAt,_that.proposalExpiresAt,_that.counterExpiresAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchRequestDto extends MatchRequestDto {
  const _MatchRequestDto({@JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'from_team_id') required this.fromTeamId, @JsonKey(name: 'to_team_id') this.toTeamId, @JsonKey(name: 'requested_by') required this.requestedBy, @JsonKey(name: 'proposed_start_time') this.proposedStartTime, @JsonKey(name: 'proposed_venue') this.proposedVenue, @JsonKey(name: 'proposed_format') final  Map<String, dynamic>? proposedFormat, this.message, @JsonKey(name: 'players_per_side') this.playersPerSide = 11, @JsonKey(name: 'from_team_xi') final  List<String> fromTeamXi = const <String>[], @JsonKey(name: 'from_team_keeper_id') this.fromTeamKeeperId, @JsonKey(name: 'countered_start_time') this.counteredStartTime, @JsonKey(name: 'countered_venue') this.counteredVenue, @JsonKey(name: 'countered_format') final  Map<String, dynamic>? counteredFormat, @JsonKey(name: 'countered_players_per_side') this.counteredPlayersPerSide, this.status = 'pending', @JsonKey(name: 'decided_by') this.decidedBy, @JsonKey(name: 'decided_at') this.decidedAt, @JsonKey(name: 'decision_note') this.decisionNote, @JsonKey(name: 'decision_reason') this.decisionReason, @JsonKey(name: 'match_id') this.matchId, @JsonKey(name: 'share_code') this.shareCode, @JsonKey(name: 'code_expires_at') this.codeExpiresAt, @JsonKey(name: 'proposal_expires_at') this.proposalExpiresAt, @JsonKey(name: 'counter_expires_at') this.counterExpiresAt, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _proposedFormat = proposedFormat,_fromTeamXi = fromTeamXi,_counteredFormat = counteredFormat,super._();
  factory _MatchRequestDto.fromJson(Map<String, dynamic> json) => _$MatchRequestDtoFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'from_team_id') final  String fromTeamId;
@override@JsonKey(name: 'to_team_id') final  String? toTeamId;
@override@JsonKey(name: 'requested_by') final  String requestedBy;
@override@JsonKey(name: 'proposed_start_time') final  String? proposedStartTime;
@override@JsonKey(name: 'proposed_venue') final  String? proposedVenue;
 final  Map<String, dynamic>? _proposedFormat;
@override@JsonKey(name: 'proposed_format') Map<String, dynamic>? get proposedFormat {
  final value = _proposedFormat;
  if (value == null) return null;
  if (_proposedFormat is EqualUnmodifiableMapView) return _proposedFormat;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? message;
@override@JsonKey(name: 'players_per_side') final  int playersPerSide;
 final  List<String> _fromTeamXi;
@override@JsonKey(name: 'from_team_xi') List<String> get fromTeamXi {
  if (_fromTeamXi is EqualUnmodifiableListView) return _fromTeamXi;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fromTeamXi);
}

@override@JsonKey(name: 'from_team_keeper_id') final  String? fromTeamKeeperId;
@override@JsonKey(name: 'countered_start_time') final  String? counteredStartTime;
@override@JsonKey(name: 'countered_venue') final  String? counteredVenue;
 final  Map<String, dynamic>? _counteredFormat;
@override@JsonKey(name: 'countered_format') Map<String, dynamic>? get counteredFormat {
  final value = _counteredFormat;
  if (value == null) return null;
  if (_counteredFormat is EqualUnmodifiableMapView) return _counteredFormat;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'countered_players_per_side') final  int? counteredPlayersPerSide;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'decided_by') final  String? decidedBy;
@override@JsonKey(name: 'decided_at') final  String? decidedAt;
@override@JsonKey(name: 'decision_note') final  String? decisionNote;
@override@JsonKey(name: 'decision_reason') final  String? decisionReason;
@override@JsonKey(name: 'match_id') final  String? matchId;
@override@JsonKey(name: 'share_code') final  String? shareCode;
@override@JsonKey(name: 'code_expires_at') final  String? codeExpiresAt;
@override@JsonKey(name: 'proposal_expires_at') final  String? proposalExpiresAt;
@override@JsonKey(name: 'counter_expires_at') final  String? counterExpiresAt;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of MatchRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchRequestDtoCopyWith<_MatchRequestDto> get copyWith => __$MatchRequestDtoCopyWithImpl<_MatchRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchRequestDto&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.fromTeamId, fromTeamId) || other.fromTeamId == fromTeamId)&&(identical(other.toTeamId, toTeamId) || other.toTeamId == toTeamId)&&(identical(other.requestedBy, requestedBy) || other.requestedBy == requestedBy)&&(identical(other.proposedStartTime, proposedStartTime) || other.proposedStartTime == proposedStartTime)&&(identical(other.proposedVenue, proposedVenue) || other.proposedVenue == proposedVenue)&&const DeepCollectionEquality().equals(other._proposedFormat, _proposedFormat)&&(identical(other.message, message) || other.message == message)&&(identical(other.playersPerSide, playersPerSide) || other.playersPerSide == playersPerSide)&&const DeepCollectionEquality().equals(other._fromTeamXi, _fromTeamXi)&&(identical(other.fromTeamKeeperId, fromTeamKeeperId) || other.fromTeamKeeperId == fromTeamKeeperId)&&(identical(other.counteredStartTime, counteredStartTime) || other.counteredStartTime == counteredStartTime)&&(identical(other.counteredVenue, counteredVenue) || other.counteredVenue == counteredVenue)&&const DeepCollectionEquality().equals(other._counteredFormat, _counteredFormat)&&(identical(other.counteredPlayersPerSide, counteredPlayersPerSide) || other.counteredPlayersPerSide == counteredPlayersPerSide)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.decisionReason, decisionReason) || other.decisionReason == decisionReason)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.shareCode, shareCode) || other.shareCode == shareCode)&&(identical(other.codeExpiresAt, codeExpiresAt) || other.codeExpiresAt == codeExpiresAt)&&(identical(other.proposalExpiresAt, proposalExpiresAt) || other.proposalExpiresAt == proposalExpiresAt)&&(identical(other.counterExpiresAt, counterExpiresAt) || other.counterExpiresAt == counterExpiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,requestId,fromTeamId,toTeamId,requestedBy,proposedStartTime,proposedVenue,const DeepCollectionEquality().hash(_proposedFormat),message,playersPerSide,const DeepCollectionEquality().hash(_fromTeamXi),fromTeamKeeperId,counteredStartTime,counteredVenue,const DeepCollectionEquality().hash(_counteredFormat),counteredPlayersPerSide,status,decidedBy,decidedAt,decisionNote,decisionReason,matchId,shareCode,codeExpiresAt,proposalExpiresAt,counterExpiresAt,createdAt,updatedAt]);

@override
String toString() {
  return 'MatchRequestDto(requestId: $requestId, fromTeamId: $fromTeamId, toTeamId: $toTeamId, requestedBy: $requestedBy, proposedStartTime: $proposedStartTime, proposedVenue: $proposedVenue, proposedFormat: $proposedFormat, message: $message, playersPerSide: $playersPerSide, fromTeamXi: $fromTeamXi, fromTeamKeeperId: $fromTeamKeeperId, counteredStartTime: $counteredStartTime, counteredVenue: $counteredVenue, counteredFormat: $counteredFormat, counteredPlayersPerSide: $counteredPlayersPerSide, status: $status, decidedBy: $decidedBy, decidedAt: $decidedAt, decisionNote: $decisionNote, decisionReason: $decisionReason, matchId: $matchId, shareCode: $shareCode, codeExpiresAt: $codeExpiresAt, proposalExpiresAt: $proposalExpiresAt, counterExpiresAt: $counterExpiresAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MatchRequestDtoCopyWith<$Res> implements $MatchRequestDtoCopyWith<$Res> {
  factory _$MatchRequestDtoCopyWith(_MatchRequestDto value, $Res Function(_MatchRequestDto) _then) = __$MatchRequestDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'from_team_id') String fromTeamId,@JsonKey(name: 'to_team_id') String? toTeamId,@JsonKey(name: 'requested_by') String requestedBy,@JsonKey(name: 'proposed_start_time') String? proposedStartTime,@JsonKey(name: 'proposed_venue') String? proposedVenue,@JsonKey(name: 'proposed_format') Map<String, dynamic>? proposedFormat, String? message,@JsonKey(name: 'players_per_side') int playersPerSide,@JsonKey(name: 'from_team_xi') List<String> fromTeamXi,@JsonKey(name: 'from_team_keeper_id') String? fromTeamKeeperId,@JsonKey(name: 'countered_start_time') String? counteredStartTime,@JsonKey(name: 'countered_venue') String? counteredVenue,@JsonKey(name: 'countered_format') Map<String, dynamic>? counteredFormat,@JsonKey(name: 'countered_players_per_side') int? counteredPlayersPerSide, String status,@JsonKey(name: 'decided_by') String? decidedBy,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'decision_note') String? decisionNote,@JsonKey(name: 'decision_reason') String? decisionReason,@JsonKey(name: 'match_id') String? matchId,@JsonKey(name: 'share_code') String? shareCode,@JsonKey(name: 'code_expires_at') String? codeExpiresAt,@JsonKey(name: 'proposal_expires_at') String? proposalExpiresAt,@JsonKey(name: 'counter_expires_at') String? counterExpiresAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$MatchRequestDtoCopyWithImpl<$Res>
    implements _$MatchRequestDtoCopyWith<$Res> {
  __$MatchRequestDtoCopyWithImpl(this._self, this._then);

  final _MatchRequestDto _self;
  final $Res Function(_MatchRequestDto) _then;

/// Create a copy of MatchRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? fromTeamId = null,Object? toTeamId = freezed,Object? requestedBy = null,Object? proposedStartTime = freezed,Object? proposedVenue = freezed,Object? proposedFormat = freezed,Object? message = freezed,Object? playersPerSide = null,Object? fromTeamXi = null,Object? fromTeamKeeperId = freezed,Object? counteredStartTime = freezed,Object? counteredVenue = freezed,Object? counteredFormat = freezed,Object? counteredPlayersPerSide = freezed,Object? status = null,Object? decidedBy = freezed,Object? decidedAt = freezed,Object? decisionNote = freezed,Object? decisionReason = freezed,Object? matchId = freezed,Object? shareCode = freezed,Object? codeExpiresAt = freezed,Object? proposalExpiresAt = freezed,Object? counterExpiresAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MatchRequestDto(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,fromTeamId: null == fromTeamId ? _self.fromTeamId : fromTeamId // ignore: cast_nullable_to_non_nullable
as String,toTeamId: freezed == toTeamId ? _self.toTeamId : toTeamId // ignore: cast_nullable_to_non_nullable
as String?,requestedBy: null == requestedBy ? _self.requestedBy : requestedBy // ignore: cast_nullable_to_non_nullable
as String,proposedStartTime: freezed == proposedStartTime ? _self.proposedStartTime : proposedStartTime // ignore: cast_nullable_to_non_nullable
as String?,proposedVenue: freezed == proposedVenue ? _self.proposedVenue : proposedVenue // ignore: cast_nullable_to_non_nullable
as String?,proposedFormat: freezed == proposedFormat ? _self._proposedFormat : proposedFormat // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,playersPerSide: null == playersPerSide ? _self.playersPerSide : playersPerSide // ignore: cast_nullable_to_non_nullable
as int,fromTeamXi: null == fromTeamXi ? _self._fromTeamXi : fromTeamXi // ignore: cast_nullable_to_non_nullable
as List<String>,fromTeamKeeperId: freezed == fromTeamKeeperId ? _self.fromTeamKeeperId : fromTeamKeeperId // ignore: cast_nullable_to_non_nullable
as String?,counteredStartTime: freezed == counteredStartTime ? _self.counteredStartTime : counteredStartTime // ignore: cast_nullable_to_non_nullable
as String?,counteredVenue: freezed == counteredVenue ? _self.counteredVenue : counteredVenue // ignore: cast_nullable_to_non_nullable
as String?,counteredFormat: freezed == counteredFormat ? _self._counteredFormat : counteredFormat // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,counteredPlayersPerSide: freezed == counteredPlayersPerSide ? _self.counteredPlayersPerSide : counteredPlayersPerSide // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,decisionReason: freezed == decisionReason ? _self.decisionReason : decisionReason // ignore: cast_nullable_to_non_nullable
as String?,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,shareCode: freezed == shareCode ? _self.shareCode : shareCode // ignore: cast_nullable_to_non_nullable
as String?,codeExpiresAt: freezed == codeExpiresAt ? _self.codeExpiresAt : codeExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,proposalExpiresAt: freezed == proposalExpiresAt ? _self.proposalExpiresAt : proposalExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,counterExpiresAt: freezed == counterExpiresAt ? _self.counterExpiresAt : counterExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
