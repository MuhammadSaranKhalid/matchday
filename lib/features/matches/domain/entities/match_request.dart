import '../../../teams/domain/entities/team.dart';
import 'match.dart';

/// A friendly-match challenge between two teams. Written by sender via
/// `send_match_request`; transitions through `pending → countered → accepted
/// | declined | cancelled | expired` driven by the 5 SECURITY DEFINER RPCs
/// in migration 0600. The matches row is materialised only on accept.
class MatchRequest {
  const MatchRequest({
    required this.id,
    required this.fromTeamId,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.toTeamId,
    this.proposedStartTime,
    this.proposedVenue,
    this.proposedFormat,
    this.message,
    this.playersPerSide = 11,
    this.fromTeamXi = const [],
    this.fromTeamKeeperId,
    this.counteredStartTime,
    this.counteredVenue,
    this.counteredFormat,
    this.counteredPlayersPerSide,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
    this.decisionReason,
    this.matchId,
    this.shareCode,
    this.codeExpiresAt,
    this.proposalExpiresAt,
    this.counterExpiresAt,
  });

  final MatchRequestId id;
  final TeamId fromTeamId;

  /// Null = open challenge (any nearby team can claim with the share code).
  final TeamId? toTeamId;
  final String requestedBy;

  // Proposed terms (sender side).
  final DateTime? proposedStartTime;
  final String? proposedVenue;
  final MatchFormat? proposedFormat;

  /// Optional message attached at send time. Max 500 chars (server-side
  /// check). The Challenge Flow design caps at 280 chars.
  final String? message;

  final int playersPerSide;
  final List<String> fromTeamXi;
  final String? fromTeamKeeperId;

  // Counter-proposal terms (receiver side, set when status is `countered`).
  final DateTime? counteredStartTime;
  final String? counteredVenue;
  final MatchFormat? counteredFormat;
  final int? counteredPlayersPerSide;

  final MatchRequestStatus status;

  // Decision metadata.
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;
  final DeclineReason? decisionReason;

  /// Set on accept — points to the materialised matches row.
  final MatchId? matchId;

  /// 6-digit code (alive for 24h) for in-person Adil-shows-Bilal-the-code.
  final String? shareCode;
  final DateTime? codeExpiresAt;

  /// Hard expiry for a pending request (48h after send).
  final DateTime? proposalExpiresAt;

  /// Hard expiry for a countered request (24h restarted on each counter).
  final DateTime? counterExpiresAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Most-recent terms — counter takes precedence over proposed, since accept
  /// materialises the match with `coalesce(countered_*, proposed_*)`.
  DateTime? get effectiveStartTime =>
      counteredStartTime ?? proposedStartTime;
  String? get effectiveVenue => counteredVenue ?? proposedVenue;
  MatchFormat? get effectiveFormat => counteredFormat ?? proposedFormat;
  int get effectivePlayersPerSide =>
      counteredPlayersPerSide ?? playersPerSide;

  /// True when the request is still actionable — can be accepted, declined,
  /// countered or cancelled.
  bool get isPending =>
      status == MatchRequestStatus.pending ||
      status == MatchRequestStatus.countered;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchRequest &&
          other.id == id &&
          other.status == status &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, status, updatedAt);
}

class MatchRequestId {
  const MatchRequestId(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      other is MatchRequestId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

enum MatchRequestStatus {
  pending('pending'),
  countered('countered'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled'),
  expired('expired');

  const MatchRequestStatus(this.wire);
  final String wire;
  static MatchRequestStatus fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ??
      MatchRequestStatus.pending;
}

/// Mirrors the deployed `decline_reason` enum (post 0615 rename). The Accept
/// Challenge Flow surfaces 6 reasons; `noInterest` was originally named
/// `unknown` and renamed in migration 0615 so the wire value matches the
/// design copy.
enum DeclineReason {
  roster('roster', 'Squad not available'),
  format('format', 'Wrong format'),
  busy('busy', 'Date / time clash'),
  venue('venue', 'Venue too far'),
  noInterest('no_interest', 'No interest right now'),
  other('other', 'Other');

  const DeclineReason(this.wire, this.label);
  final String wire;
  final String label;
  static DeclineReason fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ?? DeclineReason.other;
}
