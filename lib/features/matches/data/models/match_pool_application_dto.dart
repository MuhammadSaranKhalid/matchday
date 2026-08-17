import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match_pool_application.dart';

part 'match_pool_application_dto.freezed.dart';
part 'match_pool_application_dto.g.dart';

@freezed
abstract class MatchPoolApplicationDto with _$MatchPoolApplicationDto {
  const factory MatchPoolApplicationDto({
    @JsonKey(name: 'application_id') required String applicationId,
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'applicant_team_id') required String applicantTeamId,
    @JsonKey(name: 'applicant_user_id') required String applicantUserId,
    @JsonKey(name: 'applicant_xi') @Default(<String>[]) List<String> applicantXi,
    @JsonKey(name: 'applicant_keeper_id') String? applicantKeeperId,
    String? message,
    @Default('pending') String status,
    @JsonKey(name: 'decision_note') String? decisionNote,
    @JsonKey(name: 'decided_at') String? decidedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _MatchPoolApplicationDto;

  const MatchPoolApplicationDto._();

  factory MatchPoolApplicationDto.fromJson(Map<String, dynamic> json) =>
      _$MatchPoolApplicationDtoFromJson(json);

  MatchPoolApplication toEntity() => MatchPoolApplication(
        id: applicationId,
        requestId: requestId,
        applicantTeamId: TeamId(applicantTeamId),
        applicantUserId: applicantUserId,
        applicantXi: applicantXi,
        applicantKeeperId: applicantKeeperId,
        message: message,
        status: PoolApplicationStatus.fromWire(status),
        decisionNote: decisionNote,
        decidedAt: decidedAt == null ? null : DateTime.tryParse(decidedAt!),
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
