import 'package:equatable/equatable.dart';

import 'team.dart';

/// A single result from the `search-teams` edge function.
///
/// Lightweight by design: the search list never needs the full [Team] (no
/// roster, no managers, no description), so this carries only the display
/// fields the result card renders. The doc (§14) shows this as `Team team +
/// distance + score`; in practice the edge function returns a flat row and
/// the card needs city/logo/verified/etc. directly — embedding [Team] would
/// either force the function to return fields the card never uses, or force
/// the card to navigate a `result.team.*` indirection for every read.
class TeamSearchResult extends Equatable {
  const TeamSearchResult({
    required this.teamId,
    required this.name,
    required this.score,
    this.logoUrl,
    this.logoMonogram,
    this.primaryColor,
    this.secondaryColor,
    this.city,
    this.isVerified = false,
    this.distanceKm,
    this.foundedYear,
    this.teamType,
  });

  final TeamId teamId;
  final String name;

  /// 0..1 blended relevance × distance-decay score, ordered DESC by the
  /// server. Exposed so the UI can debug ranking or surface a "best match"
  /// affordance; not shown in the result card.
  final double score;

  final String? logoUrl;
  final String? logoMonogram;
  final String? primaryColor;
  final String? secondaryColor;

  /// Locality, NOT the full address. Display verbatim under the team name.
  final String? city;

  final bool isVerified;

  /// Distance from the user-provided search center, in kilometres. Null
  /// when no center was passed OR the team has no coordinate. Show as a
  /// coarse band ("in Lahore", "~15 km") in the UI — not a literal value
  /// (city-centroid teams collide at distance ≈ 0; see §12).
  final double? distanceKm;

  /// Year the team was founded. Rendered as "FD 2019" in the Explore result
  /// row's meta line. Null from `search-teams`, which does not select it —
  /// only `search-all` returns it.
  final int? foundedYear;

  /// Raw `team_type` enum value (e.g. `tape_ball`). Same nullability note as
  /// [foundedYear].
  final String? teamType;

  /// The mono sub-line under the team name: "Lahore · FD 2019 · Tape-ball".
  /// Composed here so the Explore row and the team-search row cannot drift.
  String get metaLine {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (foundedYear != null) 'FD $foundedYear',
      if (teamType != null && teamType!.isNotEmpty)
        teamType!.replaceAll('_', '-'),
    ];
    return parts.join(' · ');
  }

  @override
  List<Object?> get props => [
        teamId,
        name,
        score,
        logoUrl,
        logoMonogram,
        primaryColor,
        secondaryColor,
        city,
        isVerified,
        distanceKm,
        foundedYear,
        teamType,
      ];
}
