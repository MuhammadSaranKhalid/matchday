/// Cricket-specific player identity: a user's self-described cricketing
/// attributes, captured optionally during onboarding so teams can scout them.
///
/// Persisted in [cricket_player_profiles] (keyed by [CricketPlayerUserId]).
/// A row requires the corresponding (user_id, 'cricket') identity in
/// [player_sports] — the row's existence is independent of whether any
/// attributes have been filled in.
///
/// Pure Dart: each enum carries only its stable [wire] value (matching the
/// Postgres enum labels). Human-readable labels live in the presentation layer.
class CricketPlayerProfile {
  const CricketPlayerProfile({
    required this.userId,
    this.role,
    this.battingStyle,
    this.bowlingStyle,
    this.preferredBallTypes = const [],
    this.yearsPlaying,
  });

  final CricketPlayerUserId userId;

  final PlayerRole? role;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;

  /// Ball materials the player is comfortable with (`cricket_player_profiles
  /// .preferred_ball_types`, a Postgres `ball_type[]`). May be empty.
  final List<BallType> preferredBallTypes;

  final int? yearsPlaying;

  /// True when at least one attribute was chosen — i.e. the user opted in as a
  /// player rather than skipping ("I just watch").
  bool get hasAny =>
      role != null ||
      battingStyle != null ||
      bowlingStyle != null ||
      preferredBallTypes.isNotEmpty ||
      yearsPlaying != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CricketPlayerProfile &&
          other.userId == userId &&
          other.role == role &&
          other.battingStyle == battingStyle &&
          other.bowlingStyle == bowlingStyle &&
          _listEq(other.preferredBallTypes, preferredBallTypes) &&
          other.yearsPlaying == yearsPlaying;

  @override
  int get hashCode => Object.hash(
        userId,
        role,
        battingStyle,
        bowlingStyle,
        Object.hashAll(preferredBallTypes),
        yearsPlaying,
      );

  static bool _listEq(List<BallType> a, List<BallType> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Typed wrapper around the `cricket_player_profiles.user_id` primary key.
/// Ensures the cricket identity is never confused with a raw auth uid string.
class CricketPlayerUserId {
  const CricketPlayerUserId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is CricketPlayerUserId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

// =============================================================================
// Cricket enums — Postgres enum vocabulary, moved from profile feature.
// =============================================================================

/// Maps to the `player_role` Postgres enum.
enum PlayerRole {
  batter('batter'),
  bowler('bowler'),
  allRounder('all_rounder'),
  wicketKeeper('wicket_keeper');

  const PlayerRole(this.wire);
  final String wire;

  static PlayerRole? fromWire(String? wire) =>
      values.where((r) => r.wire == wire).firstOrNull;
}

/// Maps to the `batting_style` Postgres enum.
enum BattingStyle {
  rightHand('right_hand'),
  leftHand('left_hand');

  const BattingStyle(this.wire);
  final String wire;

  static BattingStyle? fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull;
}

/// Maps to the `bowling_style` Postgres enum.
enum BowlingStyle {
  rightArmFast('right_arm_fast'),
  rightArmMedium('right_arm_medium'),
  rightArmSpin('right_arm_spin'),
  leftArmFast('left_arm_fast'),
  leftArmSpin('left_arm_spin'),
  doesntBowl('doesnt_bowl');

  const BowlingStyle(this.wire);
  final String wire;

  static BowlingStyle? fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull;
}

/// Maps to the `ball_type` Postgres enum (the ball *material* — distinct from
/// the per-delivery `ball_kind`).
enum BallType {
  leather('leather'),
  tape('tape'),
  tennis('tennis');

  const BallType(this.wire);
  final String wire;

  static BallType? fromWire(String? wire) =>
      values.where((b) => b.wire == wire).firstOrNull;
}
