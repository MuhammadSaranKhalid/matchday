import 'team_member.dart';

class TeamJoinRequest {
  const TeamJoinRequest({
    required this.requestId,
    required this.teamId,
    required this.applicantId,
    required this.role,
    required this.status,
    required this.createdAt,
    this.message,
    this.applicantName,
    this.applicantUsername,
    this.applicantPhotoUrl,
  });

  final String requestId;
  final String teamId;
  final String applicantId;
  final MemberRole role;
  final String status;
  final DateTime createdAt;
  final String? message;
  final String? applicantName;
  final String? applicantUsername;
  final String? applicantPhotoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamJoinRequest && other.requestId == requestId;

  @override
  int get hashCode => requestId.hashCode;
}
