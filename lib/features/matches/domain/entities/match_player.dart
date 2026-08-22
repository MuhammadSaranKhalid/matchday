import 'package:equatable/equatable.dart';

import 'match.dart';

/// A player slotted into a specific match's XI.
///
/// This is the per-match materialised row of the `match_players` table —
/// the single polymorphism boundary for the match/balls domain. Every
/// downstream player reference (balls.batsman_id, MatchInningsState's
/// on-field trio, etc.) holds a [matchPlayerId], a clean uuid that
/// resolves here to either a profile (claimed user) or an unclaimed
/// placeholder via the XOR pair below.
///
/// Lifetime: one match. Distinct from team_members (the permanent roster
/// row): a player can be on Team A's roster but appear in only some of
/// the team's matches, can guest for another side in a friendly, or come
/// in as a substitute mid-match. Jersey number / captain / keeper /
/// substitute status all vary per match and live here, not on the roster.
class MatchPlayer extends Equatable {
  const MatchPlayer({
    required this.id,
    required this.matchId,
    required this.teamSide,
    required this.displayName,
    this.profileId,
    this.unclaimedId,
    this.photoUrl,
    this.battingOrder,
    this.jerseyNumber,
    this.isCaptain = false,
    this.isKeeper = false,
    this.isSubstitute = false,
  }) : assert(
          (profileId == null) != (unclaimedId == null),
          'Exactly one of profileId / unclaimedId must be set (XOR).',
        );

  /// Stable per-match identity. The same uuid is used by balls.batsmanId,
  /// MatchInningsState.strikerId, etc. — never changes for the lifetime
  /// of the match.
  final MatchPlayerId id;

  /// Which match this lineup row belongs to.
  final MatchId matchId;

  /// 'a' or 'b'. Matches the `team_a_*` / `team_b_*` naming used on the
  /// matches row.
  final MatchTeamSide teamSide;

  /// Claimed player. Exactly one of [profileId] / [unclaimedId] is set.
  final String? profileId;

  /// Unclaimed-placeholder player. Exactly one of [profileId] /
  /// [unclaimedId] is set.
  final String? unclaimedId;

  /// The player's name as of this match, resolved at the data boundary from
  /// whichever side of the XOR is set.
  ///
  /// It lives here rather than being looked up against the team roster by the
  /// caller because the XI and the roster are different sets: guests,
  /// substitutes and players since removed from the roster are in the XI but
  /// absent from it. Resolving against the roster left them rendering as
  /// "Player 3f2a" on the scoring screen. Never empty.
  final String displayName;

  /// Avatar URL into the public `avatars` bucket, or null when the player has
  /// not uploaded one — and always null for unclaimed placeholders, who have
  /// no photo column at all. Callers fall back to the monogram.
  final String? photoUrl;

  /// 1 = opener, 2 = second in, etc. Null until the captain locks the
  /// batting order. Supports up to 15 to accommodate substitutes and
  /// impact players.
  final int? battingOrder;

  /// Jersey for THIS match — may differ from the player's permanent team
  /// jersey (e.g. a guest player wears whatever's free).
  final int? jerseyNumber;

  /// Captain of this match specifically (the team's permanent captain may
  /// be unavailable on the day).
  final bool isCaptain;

  /// Wicket-keeper for this match.
  final bool isKeeper;

  /// Substitute / impact player added mid-match.
  final bool isSubstitute;

  /// True if this row references a real profile (the user has an account).
  /// False means an unclaimed placeholder.
  bool get isClaimed => profileId != null;

  /// Whichever id is set — useful for identifying the same person whether
  /// they're claimed or not. The name and avatar are already resolved on
  /// [displayName] / [photoUrl]; this is for keying and lookups.
  String get playerRefId => profileId ?? unclaimedId ?? id.value;

  @override
  List<Object?> get props => [
        id,
        matchId,
        teamSide,
        profileId,
        unclaimedId,
        displayName,
        photoUrl,
        battingOrder,
        jerseyNumber,
        isCaptain,
        isKeeper,
        isSubstitute,
      ];
}

/// Translation between the two id spaces a match deals in: the per-match
/// [MatchPlayerId] (what balls / innings-state reference) and the underlying
/// [MatchPlayer.playerRefId] (what rosters and pickers reference).
///
/// Every screen that renders the on-field trio needs both directions, so the
/// lookup lives here rather than being re-scanned inline at each call site.
extension MatchPlayerLookup on List<MatchPlayer> {
  /// The underlying player ref id for a `match_players.id`, or null when the
  /// id is absent from this lineup.
  String? playerRefIdOf(String? matchPlayerId) {
    if (matchPlayerId == null) return null;
    for (final p in this) {
      if (p.id.value == matchPlayerId) return p.playerRefId;
    }
    return null;
  }

  /// The `match_players.id` for an underlying player ref id, or null when the
  /// player was never materialised into this match's XI.
  String? matchPlayerIdOf(String? playerRefId) {
    if (playerRefId == null) return null;
    for (final p in this) {
      if (p.playerRefId == playerRefId) return p.id.value;
    }
    return null;
  }

  /// The lineup row for an underlying player ref id, or null when absent.
  MatchPlayer? byRefId(String? playerRefId) {
    if (playerRefId == null) return null;
    for (final p in this) {
      if (p.playerRefId == playerRefId) return p;
    }
    return null;
  }

  /// The lineup row for a `match_players.id`, or null when absent.
  MatchPlayer? byMatchPlayerId(String? matchPlayerId) {
    if (matchPlayerId == null) return null;
    for (final p in this) {
      if (p.id.value == matchPlayerId) return p;
    }
    return null;
  }
}

/// The surrogate uuid stored in match_players.match_player_id. Stable
/// across the match's lifetime; survives the unclaimed → claimed identity
/// flip (the row's profile_id / unclaimed_id swap, the PK does not).
class MatchPlayerId extends Equatable {
  const MatchPlayerId(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value;
}

/// 'a' or 'b' — which side of the match the player is in. Mirrors the
/// `team_a_*` / `team_b_*` naming on the matches row.
enum MatchTeamSide {
  a('a'),
  b('b');

  const MatchTeamSide(this.wire);
  final String wire;

  static MatchTeamSide fromWire(String? w) {
    if (w == null) return MatchTeamSide.a;
    final clean = w.trim().toLowerCase();
    if (clean == 'team_b' || clean == 'b') return MatchTeamSide.b;
    return MatchTeamSide.a;
  }
}
