import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../teams/domain/entities/team.dart';

part 'match_pool_application.freezed.dart';

enum PoolApplicationStatus {
  pending,
  accepted,
  rejected,
  withdrawn;

  static PoolApplicationStatus fromWire(String raw) {
    switch (raw.toLowerCase()) {
      case 'accepted':
        return PoolApplicationStatus.accepted;
      case 'rejected':
        return PoolApplicationStatus.rejected;
      case 'withdrawn':
        return PoolApplicationStatus.withdrawn;
      case 'pending':
      default:
        return PoolApplicationStatus.pending;
    }
  }

  String get wire => name;
}

@freezed
abstract class MatchPoolApplication with _$MatchPoolApplication {
  const factory MatchPoolApplication({
    required String id,
    required String requestId,
    required TeamId applicantTeamId,
    required String applicantUserId,
    @Default(<String>[]) List<String> applicantXi,
    String? applicantKeeperId,
    String? message,
    required PoolApplicationStatus status,
    String? decisionNote,
    DateTime? decidedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MatchPoolApplication;
}
