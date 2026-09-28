import 'package:meta/meta.dart';

/// Someone the organiser can appoint to score a fixture (artboard 27).
@immutable
class ScorerCandidate {
  const ScorerCandidate({
    required this.userId,
    required this.displayName,
    required this.roleLabel,
    this.username,
  });

  final String userId;
  final String displayName;

  /// "Organiser", "Co-organiser" or "Team manager" — why they are on the list.
  final String roleLabel;
  final String? username;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScorerCandidate && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}
