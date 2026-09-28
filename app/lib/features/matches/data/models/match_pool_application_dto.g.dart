// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_pool_application_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchPoolApplicationDto _$MatchPoolApplicationDtoFromJson(
  Map<String, dynamic> json,
) => _MatchPoolApplicationDto(
  applicationId: json['application_id'] as String,
  requestId: json['request_id'] as String,
  applicantTeamId: json['applicant_team_id'] as String,
  applicantUserId: json['applicant_user_id'] as String,
  applicantXi:
      (json['applicant_xi'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  applicantKeeperId: json['applicant_keeper_id'] as String?,
  message: json['message'] as String?,
  status: json['status'] as String? ?? 'pending',
  decisionNote: json['decision_note'] as String?,
  decidedAt: json['decided_at'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$MatchPoolApplicationDtoToJson(
  _MatchPoolApplicationDto instance,
) => <String, dynamic>{
  'application_id': instance.applicationId,
  'request_id': instance.requestId,
  'applicant_team_id': instance.applicantTeamId,
  'applicant_user_id': instance.applicantUserId,
  'applicant_xi': instance.applicantXi,
  'applicant_keeper_id': instance.applicantKeeperId,
  'message': instance.message,
  'status': instance.status,
  'decision_note': instance.decisionNote,
  'decided_at': instance.decidedAt,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
