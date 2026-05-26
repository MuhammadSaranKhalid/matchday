import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/team.dart';

/// One active match surfaced on the "My teams" screen, with the cross-feature
/// data already resolved by the controller so the widget renders, not derives.
class TeamMatchEntry {
  const TeamMatchEntry({
    required this.match,
    required this.incoming,
    this.opponent,
  });

  /// The active match (status passes [MatchStatus.isActive]).
  final Match match;

  /// True when the signed-in user's team is teamB — i.e. the request recipient.
  final bool incoming;

  /// The opposing team, resolved from the teams cache. Null when that team
  /// isn't cached locally (the card falls back to a neutral crest/label).
  final Team? opponent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMatchEntry &&
          other.match == match &&
          other.incoming == incoming &&
          other.opponent == opponent;

  @override
  int get hashCode => Object.hash(match, incoming, opponent);
}

/// The composed view for the "My teams" screen: the user's teams plus the
/// active matches their teams are involved in. Built by [TeamsListController].
class TeamsListView {
  const TeamsListView({required this.teams, required this.activeMatches});

  final List<Team> teams;
  final List<TeamMatchEntry> activeMatches;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamsListView &&
          _listEq(other.teams, teams) &&
          _listEq(other.activeMatches, activeMatches);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(teams), Object.hashAll(activeMatches));

  static bool _listEq(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
