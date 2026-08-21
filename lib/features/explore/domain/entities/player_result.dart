import 'package:equatable/equatable.dart';

/// Which kind of person a [PlayerResult] refers to.
///
/// Players are polymorphic in this product: a person may exist as a signed-up
/// `profiles` row, or as an `unclaimed_players` row a captain created so they
/// could be fielded before joining. Explore surfaces both — the unclaimed one
/// so the person can find and claim their own record (design/spec.txt §3.1,
/// "Path B: search-and-claim").
enum PlayerKind {
  /// A registered profile. [PlayerResult.id] is a `profiles.user_id`.
  profile,

  /// A captain-created placeholder. [PlayerResult.id] is an `unclaimed_id`.
  unclaimed,
}

/// One person in Explore's results — a registered player or an unclaimed one.
///
/// Deliberately a search projection, not the full profile: the row renders a
/// name, a handle, a one-line meta string and a follower count. Pulling the
/// whole [Profile] would make the function return fields no row displays.
///
/// Contact details (phone, email) captured on unclaimed players are NEVER
/// part of this entity — they are not selected server-side either.
class PlayerResult extends Equatable {
  const PlayerResult({
    required this.id,
    required this.kind,
    required this.name,
    required this.score,
    this.username,
    this.photoUrl,
    this.city,
    this.playerRole,
    this.battingStyle,
    this.bowlingStyle,
    this.teamContext,
    this.isVerified = false,
    this.followerCount = 0,
  });

  /// `profiles.user_id` when [kind] is [PlayerKind.profile]; `unclaimed_id`
  /// when [PlayerKind.unclaimed]. Raw String because the id is polymorphic —
  /// the documented exception to the wrap-all-ids rule (CLAUDE.md §6.6).
  final String id;
  final PlayerKind kind;
  final String name;

  /// 0..1 text relevance, ordered DESC by the server. Not rendered.
  final double score;

  /// Null for unclaimed players — they have no handle until they sign up.
  final String? username;
  final String? photoUrl;
  final String? city;
  final String? playerRole;
  final String? battingStyle;
  final String? bowlingStyle;

  /// For unclaimed players: the team they were added to, so the person can
  /// recognise their own record ("Ahmed Khan in Lahore Lions").
  final String? teamContext;

  final bool isVerified;
  final int followerCount;

  bool get isUnclaimed => kind == PlayerKind.unclaimed;

  /// The mono sub-line under the name. Composed here rather than in the
  /// widget so the search row and the see-all row cannot drift apart.
  String get metaLine {
    final parts = <String>[
      if (username != null && username!.isNotEmpty) '@$username',
      if (teamContext != null && teamContext!.isNotEmpty) teamContext!,
      if (playerRole != null && playerRole!.isNotEmpty) _pretty(playerRole!),
      if (battingStyle != null && battingStyle!.isNotEmpty)
        _pretty(battingStyle!),
    ];
    return parts.join(' · ');
  }

  /// Enum values arrive as snake_case (`all_rounder`, `right_hand`). Render
  /// them as words.
  static String _pretty(String raw) =>
      raw.replaceAll('_', ' ').replaceAll('-', ' ');

  @override
  List<Object?> get props => [
        id,
        kind,
        name,
        score,
        username,
        photoUrl,
        city,
        playerRole,
        battingStyle,
        bowlingStyle,
        teamContext,
        isVerified,
        followerCount,
      ];
}
