import 'player_skills.dart';

/// A player added to a team by name only — no Circk account yet. The claim
/// flow (unclaimed → claimed) is v1.1; for Phase 1 these just hold a name,
/// plus optional playing-skill metadata persisted to `player_profile` jsonb.
class UnclaimedPlayer {
  const UnclaimedPlayer({
    required this.id,
    required this.displayName,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
    this.playingRole,
    this.battingStyle,
    this.bowlingStyle,
  });

  final UnclaimedPlayerId id;
  final String displayName;
  final String addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlayingRole? playingRole;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnclaimedPlayer &&
          other.id == id &&
          other.displayName == displayName &&
          other.addedBy == addedBy &&
          other.updatedAt == updatedAt &&
          other.playingRole == playingRole &&
          other.battingStyle == battingStyle &&
          other.bowlingStyle == bowlingStyle;

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        addedBy,
        updatedAt,
        playingRole,
        battingStyle,
        bowlingStyle,
      );
}

class UnclaimedPlayerId {
  const UnclaimedPlayerId(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      other is UnclaimedPlayerId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
