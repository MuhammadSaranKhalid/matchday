import 'package:equatable/equatable.dart';

import '../../../teams/domain/entities/team_search_result.dart';
import 'match_result.dart';
import 'player_result.dart';
import 'tournament_result.dart';

/// The categories Explore searches.
///
/// Tournaments joined in once the create wizard shipped — `search-all` had
/// returned the group from the start, but with no client able to create a
/// tournament the table was empty and the group would never have rendered.
enum ExploreCategory { players, teams, matches, tournaments }

extension ExploreCategoryX on ExploreCategory {
  /// Wire value for the edge function's `kind` narrowing parameter.
  String get wireName => switch (this) {
        ExploreCategory.players => 'players',
        ExploreCategory.teams => 'teams',
        ExploreCategory.matches => 'matches',
        ExploreCategory.tournaments => 'tournaments',
      };

  /// Group heading, e.g. "PLAYERS".
  String get label => switch (this) {
        ExploreCategory.players => 'Players',
        ExploreCategory.teams => 'Teams',
        ExploreCategory.matches => 'Matches',
        ExploreCategory.tournaments => 'Tournaments',
      };
}

/// One round-trip's worth of grouped results.
///
/// Groups travel together rather than as three independent providers so the
/// screen renders one coherent snapshot — a partially-updated set (new teams,
/// stale players) would show counts that disagree with the list.
class ExploreResults extends Equatable {
  const ExploreResults({
    this.players = const [],
    this.teams = const [],
    this.matches = const [],
    this.tournaments = const [],
  });

  static const empty = ExploreResults();

  final List<PlayerResult> players;
  final List<TeamSearchResult> teams;
  final List<MatchResult> matches;
  final List<TournamentResult> tournaments;

  int get totalCount =>
      players.length + teams.length + matches.length + tournaments.length;

  bool get isEmpty => totalCount == 0;

  int countFor(ExploreCategory category) => switch (category) {
        ExploreCategory.players => players.length,
        ExploreCategory.teams => teams.length,
        ExploreCategory.matches => matches.length,
        ExploreCategory.tournaments => tournaments.length,
      };

  /// Categories that actually have hits, in the order the screen renders
  /// them. Teams lead: a name query in this app is most often a team.
  /// Tournaments sit second — a cup name is the next most likely query, and
  /// it is the object a searcher is most likely to want to act on.
  List<ExploreCategory> get nonEmptyCategories => [
        ExploreCategory.teams,
        ExploreCategory.tournaments,
        ExploreCategory.players,
        ExploreCategory.matches,
      ].where((c) => countFor(c) > 0).toList();

  @override
  List<Object?> get props => [players, teams, matches, tournaments];
}

/// The no-query discovery state.
///
/// Leads with live matches — real data, and the most compelling object in
/// the app — then open tournaments, recently-active teams and players to
/// follow. This replaces the design's proximity sections ("Teams near you")
/// until coordinates are captured; ordering an empty distance dimension
/// would be a lie.
class ExploreBrowse extends Equatable {
  const ExploreBrowse({
    this.live = const [],
    this.tournaments = const [],
    this.teams = const [],
    this.players = const [],
  });

  static const empty = ExploreBrowse();

  final List<MatchResult> live;

  /// Cups in `registration`, `upcoming` or `live`, live-first. The closest
  /// thing to the design's "Featured grassroots cups" that real data allows.
  final List<TournamentResult> tournaments;

  final List<TeamSearchResult> teams;
  final List<PlayerResult> players;

  bool get isEmpty =>
      live.isEmpty && tournaments.isEmpty && teams.isEmpty && players.isEmpty;

  @override
  List<Object?> get props => [live, tournaments, teams, players];
}
