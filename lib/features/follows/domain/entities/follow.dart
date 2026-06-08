import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../teams/domain/entities/team.dart';

// ---------------------------------------------------------------------------
// FollowTarget — sealed polymorphic union (User / Team / Tournament)
// ---------------------------------------------------------------------------

/// Sealed union representing what a [Follow] points at.
///
/// Tournament is represented with a raw [String] id for P1 because there is
/// no `TournamentId` wrapper type yet (no UI surface for tournament follows).
sealed class FollowTarget extends Equatable {
  const FollowTarget();

  /// The wire string sent to / received from Supabase's `target_type` column.
  String get targetTypeWire;

  /// The UUID of the target entity.
  String get targetId;
}

class UserFollowTarget extends FollowTarget {
  const UserFollowTarget(this.userId);
  final UserId userId;

  @override
  String get targetTypeWire => 'user';

  @override
  String get targetId => userId.value;

  @override
  List<Object?> get props => [userId];
}

class TeamFollowTarget extends FollowTarget {
  const TeamFollowTarget(this.teamId);
  final TeamId teamId;

  @override
  String get targetTypeWire => 'team';

  @override
  String get targetId => teamId.value;

  @override
  List<Object?> get props => [teamId];
}

/// Tournament follow target. Uses a raw [String] id until [TournamentId] is
/// introduced; see CLAUDE.md §6.6 for the documented exception on raw IDs.
class TournamentFollowTarget extends FollowTarget {
  const TournamentFollowTarget(this.tournamentId);

  /// Raw UUID string — no TournamentId wrapper exists yet (P1 stub).
  final String tournamentId;

  @override
  String get targetTypeWire => 'tournament';

  @override
  String get targetId => tournamentId;

  @override
  List<Object?> get props => [tournamentId];
}

// ---------------------------------------------------------------------------
// FollowStatus
// ---------------------------------------------------------------------------

enum FollowStatus {
  active('active'),
  muted('muted');

  const FollowStatus(this.wire);
  final String wire;

  static FollowStatus fromWire(String value) {
    return FollowStatus.values.firstWhere(
      (s) => s.wire == value,
      orElse: () => FollowStatus.active,
    );
  }
}

// ---------------------------------------------------------------------------
// FollowId
// ---------------------------------------------------------------------------

class FollowId extends Equatable {
  const FollowId(this.value);
  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

// ---------------------------------------------------------------------------
// Follow — domain entity
// ---------------------------------------------------------------------------

/// Represents a single follow relationship.
///
/// [target] is a sealed [FollowTarget] so the UI can switch on the concrete
/// type without raw string comparisons.
class Follow extends Equatable {
  const Follow({
    required this.id,
    required this.followerId,
    required this.target,
    required this.status,
    required this.notificationsEnabled,
    required this.createdAt,
  });

  final FollowId id;
  final UserId followerId;
  final FollowTarget target;
  final FollowStatus status;
  final bool notificationsEnabled;
  final DateTime createdAt;

  Follow copyWith({
    FollowStatus? status,
    bool? notificationsEnabled,
  }) =>
      Follow(
        id: id,
        followerId: followerId,
        target: target,
        status: status ?? this.status,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        followerId,
        target,
        status,
        notificationsEnabled,
        createdAt,
      ];
}
