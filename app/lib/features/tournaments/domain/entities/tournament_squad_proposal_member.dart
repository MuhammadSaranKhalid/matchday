/// Identity of one Team roster member proposed for a Tournament squad.
///
/// Team roster membership is polymorphic:
///
/// - claimed player   -> [userId]
/// - unclaimed player -> [unclaimedId]
///
/// Exactly one identity must exist.
class TournamentSquadProposalMember {
  const TournamentSquadProposalMember.claimed(this.userId) : unclaimedId = null;

  const TournamentSquadProposalMember.unclaimed(this.unclaimedId)
    : userId = null;

  final String? userId;
  final String? unclaimedId;

  bool get isClaimed => userId != null;
  bool get isUnclaimed => unclaimedId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentSquadProposalMember &&
          other.userId == userId &&
          other.unclaimedId == unclaimedId;

  @override
  int get hashCode => Object.hash(userId, unclaimedId);
}
