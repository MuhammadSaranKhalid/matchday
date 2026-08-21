import 'package:equatable/equatable.dart';

import '../../../teams/domain/entities/team_search_result.dart';
import 'match_result.dart';
import 'player_result.dart';

/// The categories Explore searches. Tournaments are deliberately absent in
/// v1: the backend is complete but no client can create a tournament, so the
/// table is empty and a tournaments group would never render.
enum ExploreCategory { players, teams, matches }

extension ExploreCategoryX on ExploreCategory {
  /// Wire value for the edge function's `kind` narrowing parameter.
  String get wireName => switch (this) {
        ExploreCategory.players => 'players',
        ExploreCategory.teams => 'teams',
        ExploreCategory.matches => 'matches',
      };

  /// Group heading, e.g. "PLAYERS".
  String get label => switch (this) {
        ExploreCategory.players => 'Players',
        ExploreCategory.teams => 'Teams',
        ExploreCategory.matches => 'Matches',
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
  });

  static const empty = ExploreResults();

  final List<PlayerResult> players;
  final List<TeamSearchResult> teams;
  final List<MatchResult> matches;

  int get totalCount => players.length + teams.length + matches.length;

  bool get isEmpty => totalCount == 0;

  int countFor(ExploreCategory category) => switch (category) {
        ExploreCategory.players => players.length,
        ExploreCategory.teams => teams.length,
        ExploreCategory.matches => matches.length,
      };

  /// Categories that actually have hits, in the order the screen renders
  /// them. Teams lead: a name query in this app is most often a team.
  List<ExploreCategory> get nonEmptyCategories => [
        ExploreCategory.teams,
        ExploreCategory.players,
        ExploreCategory.matches,
      ].where((c) => countFor(c) > 0).toList();

  @override
  List<Object?> get props => [players, teams, matches];
}

/// The no-query discovery state.
///
/// v1 leads with live matches — real data, and the most compelling object in
/// the app — then recently-active teams and players to follow. This replaces
/// the design's proximity sections ("Teams near you") until coordinates are
/// captured; ordering an empty distance dimension would be a lie.
class ExploreBrowse extends Equatable {
  const ExploreBrowse({
    this.live = const [],
    this.teams = const [],
    this.players = const [],
  });

  static const empty = ExploreBrowse();

  final List<MatchResult> live;
  final List<TeamSearchResult> teams;
  final List<PlayerResult> players;

  bool get isEmpty => live.isEmpty && teams.isEmpty && players.isEmpty;

  @override
  List<Object?> get props => [live, teams, players];
}
