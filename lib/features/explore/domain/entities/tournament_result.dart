import 'package:equatable/equatable.dart';

/// One tournament in Explore — a search hit or a row in the browse list.
///
/// A search projection over `tournaments`, not the full [Tournament] entity
/// (which carries the format/rules maps, venues, organiser array and the
/// awards blob that no list row renders). Kept in this feature's domain for
/// the same reason [MatchResult] is: the shape is owned by the `search-all`
/// projection, not by the tournaments feature.
class TournamentResult extends Equatable {
  const TournamentResult({
    required this.tournamentId,
    required this.name,
    required this.type,
    required this.status,
    this.bannerImageUrl,
    this.logoUrl,
    this.startDate,
    this.endDate,
    this.city,
    this.entryFee,
    this.maxTeams,
    this.approvedTeamsCount = 0,
  });

  final String tournamentId;
  final String name;

  /// Raw `tournament_type` value: knockout · round_robin · league ·
  /// group_knockout · double_elimination.
  final String type;

  /// Raw `tournament_status` value: registration · upcoming · live ·
  /// completed · cancelled · abandoned. `draft` never reaches a client here —
  /// the function excludes it.
  final String status;

  final String? bannerImageUrl;
  final String? logoUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? city;
  final double? entryFee;
  final int? maxTeams;

  /// Approved registrations only — the function filters on
  /// `tournament_teams.status = 'approved'`, so this is the number of teams
  /// actually in the cup, not the number who applied.
  final int approvedTeamsCount;

  bool get isLive => status == 'live';

  bool get isRegistrationOpen => status == 'registration';

  bool get isCompleted => status == 'completed';

  /// "Knockout", "Round robin" — the wire enum made readable without pulling
  /// the tournaments feature's own label extension across the seam.
  String get typeLabel => switch (type) {
        'knockout' => 'Knockout',
        'round_robin' => 'Round robin',
        'league' => 'League',
        'group_knockout' => 'Groups + knockout',
        'double_elimination' => 'Double elimination',
        _ => type.replaceAll('_', ' '),
      };

  /// "6 / 8 teams" when the cap is known, otherwise "6 teams". Singular at
  /// one, and omitted entirely at zero — "0 teams" reads as a failure rather
  /// than as a cup that has not filled yet.
  String? get teamsLine {
    if (approvedTeamsCount == 0 && maxTeams == null) return null;
    if (maxTeams != null) return '$approvedTeamsCount / $maxTeams teams';
    return '$approvedTeamsCount team${approvedTeamsCount == 1 ? '' : 's'}';
  }

  @override
  List<Object?> get props => [
        tournamentId,
        name,
        type,
        status,
        bannerImageUrl,
        logoUrl,
        startDate,
        endDate,
        city,
        entryFee,
        maxTeams,
        approvedTeamsCount,
      ];
}
