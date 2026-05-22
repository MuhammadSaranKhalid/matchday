/// A player's self-described cricketing style, captured (optionally) during
/// onboarding so teams can scout them. Persisted as the `player_profile` jsonb
/// on the profiles row.
///
/// Pure Dart: each enum carries only its stable [wire] value (used by the DTO
/// at the data boundary). Human-readable labels live in the presentation layer.
class PlayerProfile {
  const PlayerProfile({
    this.role,
    this.battingStyle,
    this.bowlingStyle,
    this.preferredBall,
  });

  final PlayerRole? role;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;
  final BallType? preferredBall;

  /// True when at least one attribute was chosen — i.e. the user opted in as a
  /// player rather than skipping ("I just watch").
  bool get hasAny =>
      role != null ||
      battingStyle != null ||
      bowlingStyle != null ||
      preferredBall != null;

  PlayerProfile copyWith({
    PlayerRole? role,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    BallType? preferredBall,
  }) =>
      PlayerProfile(
        role: role ?? this.role,
        battingStyle: battingStyle ?? this.battingStyle,
        bowlingStyle: bowlingStyle ?? this.bowlingStyle,
        preferredBall: preferredBall ?? this.preferredBall,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfile &&
          other.role == role &&
          other.battingStyle == battingStyle &&
          other.bowlingStyle == bowlingStyle &&
          other.preferredBall == preferredBall;

  @override
  int get hashCode =>
      Object.hash(role, battingStyle, bowlingStyle, preferredBall);
}

enum PlayerRole {
  batter('batter'),
  bowler('bowler'),
  allRounder('all_rounder'),
  keeper('keeper');

  const PlayerRole(this.wire);
  final String wire;

  static PlayerRole? fromWire(String? wire) =>
      values.where((r) => r.wire == wire).firstOrNull;
}

enum BattingStyle {
  rightHand('right_hand'),
  leftHand('left_hand');

  const BattingStyle(this.wire);
  final String wire;

  static BattingStyle? fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull;
}

enum BowlingStyle {
  rightArmFast('right_arm_fast'),
  rightArmSpin('right_arm_spin'),
  leftArmFast('left_arm_fast'),
  leftArmSpin('left_arm_spin'),
  doesntBowl('doesnt_bowl');

  const BowlingStyle(this.wire);
  final String wire;

  static BowlingStyle? fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull;
}

enum BallType {
  leather('leather'),
  tape('tape'),
  tennis('tennis');

  const BallType(this.wire);
  final String wire;

  static BallType? fromWire(String? wire) =>
      values.where((b) => b.wire == wire).firstOrNull;
}
