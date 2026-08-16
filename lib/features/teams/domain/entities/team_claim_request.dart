/// Represents a request from a user to claim an unclaimed roster spot.
class TeamClaimRequest {
  const TeamClaimRequest({
    required this.requestId,
    required this.unclaimedId,
    required this.requesterId,
    required this.status,
    required this.createdAt,
    this.message,
    this.unclaimedPlayerName,
    this.unclaimedJerseyNumber,
    this.requesterName,
    this.requesterUsername,
    this.requesterPhotoUrl,
  });

  final String requestId;
  final String unclaimedId;
  final String requesterId;
  final String status;
  final DateTime createdAt;
  final String? message;
  final String? unclaimedPlayerName;
  final int? unclaimedJerseyNumber;
  final String? requesterName;
  final String? requesterUsername;
  final String? requesterPhotoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamClaimRequest && other.requestId == requestId;

  @override
  int get hashCode => requestId.hashCode;
}
