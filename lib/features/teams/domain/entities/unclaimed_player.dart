/// A player added to a team by name only — no Circk account yet. The claim
/// flow (unclaimed → claimed) is v1.1; for Phase 1 these just hold a name.
class UnclaimedPlayer {
  const UnclaimedPlayer({
    required this.id,
    required this.displayName,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final UnclaimedPlayerId id;
  final String displayName;
  final String addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnclaimedPlayer &&
          other.id == id &&
          other.displayName == displayName &&
          other.addedBy == addedBy &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, displayName, addedBy, updatedAt);
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
