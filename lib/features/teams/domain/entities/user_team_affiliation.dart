/// A team affiliation for a user, indicating whether they captain or play for the team.
class UserTeamAffiliation {
  const UserTeamAffiliation({
    required this.teamId,
    required this.teamName,
    required this.logoMonogram,
    this.logoUrl,
    this.primaryColor,
    required this.role,
    required this.isCaptain,
  });

  final String teamId;
  final String teamName;
  final String logoMonogram;
  final String? logoUrl;
  final String? primaryColor;
  final String role;
  final bool isCaptain;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTeamAffiliation &&
          other.teamId == teamId &&
          other.teamName == teamName &&
          other.logoMonogram == logoMonogram &&
          other.logoUrl == logoUrl &&
          other.primaryColor == primaryColor &&
          other.role == role &&
          other.isCaptain == isCaptain;

  @override
  int get hashCode => Object.hash(
        teamId,
        teamName,
        logoMonogram,
        logoUrl,
        primaryColor,
        role,
        isCaptain,
      );
}
