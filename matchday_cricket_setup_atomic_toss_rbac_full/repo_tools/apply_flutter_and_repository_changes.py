#!/usr/bin/env python3
"""
Apply the Cricket setup-side + atomic-toss + RBAC Flutter/repository cutover.

Run from the Matchday repository root:

    python3 /path/to/apply_flutter_and_repository_changes.py

The script is intentionally strict: every replacement must match the expected
current main-branch source exactly once. If the repository has drifted, it
stops rather than silently producing a partial architecture.
"""

from pathlib import Path
import shutil
import sys

REPO = Path.cwd()
PACKAGE = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    path = REPO / rel
    if not path.exists():
        raise SystemExit(f"Missing expected file: {rel}")
    return path.read_text(encoding="utf-8")


def write(rel: str, content: str) -> None:
    path = REPO / rel
    path.write_text(content, encoding="utf-8")
    print(f"updated  {rel}")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"{label}: expected exactly one match, found {count}. "
            "Repository has drifted; review manually."
        )
    return text.replace(old, new, 1)


# ---------------------------------------------------------------------------
# Complete Match Start replacements
# ---------------------------------------------------------------------------

replacements = {
    "flutter_replacements/match_start_state.dart":
        "lib/features/matches/presentation/state/match_start_state.dart",
    "flutter_replacements/match_start_controller.dart":
        "lib/features/matches/presentation/controllers/match_start_controller.dart",
    "flutter_replacements/stage_toss.dart":
        "lib/features/matches/presentation/widgets/match_start/stage_toss.dart",
    "flutter_replacements/stage_lineup.dart":
        "lib/features/matches/presentation/widgets/match_start/stage_lineup.dart",
}

for src_rel, dst_rel in replacements.items():
    src = PACKAGE / src_rel
    if not src.exists():
        raise SystemExit(f"Package file missing: {src_rel}")
    write(dst_rel, src.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# Match entity
# ---------------------------------------------------------------------------

rel = "lib/features/matches/domain/entities/match.dart"
text = read(rel)

text = replace_once(
    text,
    """    this.teamACaptain,
    this.teamBCaptain,
    this.venue,""",
    """    this.teamACaptain,
    this.teamBCaptain,
    this.setupTeamId,
    this.venue,""",
    "Match constructor setupTeamId",
)

text = replace_once(
    text,
    """    this.tossFace,
    this.startPhase = MatchStartPhase.toss,""",
    """    this.tossFace,
    this.tossRecordedBy,
    this.startPhase = MatchStartPhase.toss,""",
    "Match constructor tossRecordedBy",
)

text = replace_once(
    text,
    """  final String? teamACaptain;
  final String? teamBCaptain;
  final Venue? venue;""",
    """  final String? teamACaptain;
  final String? teamBCaptain;

  /// Team currently occupying `cricket_matches.setup_side`, projected through
  /// `cricket_match_details`. This is Cricket workflow state, not a column on
  /// the sport-neutral `matches` shell.
  ///
  /// It is NOT the same thing as createdBy.
  final TeamId? setupTeamId;

  final Venue? venue;""",
    "Match setupTeamId field",
)

text = replace_once(
    text,
    """  /// Coin face the host phone observed. Cosmetic — used by the result banner.
  final String? tossFace;

  /// Where the match is in the pre-live → live progression.""",
    """  /// Coin face the host phone observed. Cosmetic — used by the result banner.
  final String? tossFace;

  /// User who entered the complete physical toss result.
  final String? tossRecordedBy;

  /// Where the match is in the pre-live → live progression.""",
    "Match tossRecordedBy field",
)

text = replace_once(
    text,
    """    String? teamACaptain,
    String? teamBCaptain,
    Venue? venue,""",
    """    String? teamACaptain,
    String? teamBCaptain,
    TeamId? setupTeamId,
    Venue? venue,""",
    "Match copyWith setup arg",
)

text = replace_once(
    text,
    """    TossDecision? tossDecision,
    String? tossFace,
    MatchStartPhase? startPhase,""",
    """    TossDecision? tossDecision,
    String? tossFace,
    String? tossRecordedBy,
    MatchStartPhase? startPhase,""",
    "Match copyWith toss actor arg",
)

text = replace_once(
    text,
    """        teamACaptain: teamACaptain ?? this.teamACaptain,
        teamBCaptain: teamBCaptain ?? this.teamBCaptain,
        venue: venue ?? this.venue,""",
    """        teamACaptain: teamACaptain ?? this.teamACaptain,
        teamBCaptain: teamBCaptain ?? this.teamBCaptain,
        setupTeamId: setupTeamId ?? this.setupTeamId,
        venue: venue ?? this.venue,""",
    "Match copyWith setup assignment",
)

text = replace_once(
    text,
    """        tossDecision: tossDecision ?? this.tossDecision,
        tossFace: tossFace ?? this.tossFace,
        startPhase: startPhase ?? this.startPhase,""",
    """        tossDecision: tossDecision ?? this.tossDecision,
        tossFace: tossFace ?? this.tossFace,
        tossRecordedBy: tossRecordedBy ?? this.tossRecordedBy,
        startPhase: startPhase ?? this.startPhase,""",
    "Match copyWith toss actor assignment",
)

text = replace_once(
    text,
    """        teamBId,
        status,""",
    """        teamBId,
        setupTeamId,
        status,""",
    "Match props setup",
)

write(rel, text)


# ---------------------------------------------------------------------------
# Match DTO
# ---------------------------------------------------------------------------

rel = "lib/features/matches/data/models/match_dto.dart"
text = read(rel)

text = replace_once(
    text,
    """    @JsonKey(name: 'team_b_captain') String? teamBCaptain,
    required Map<String, dynamic> format,""",
    """    @JsonKey(name: 'team_b_captain') String? teamBCaptain,
    @JsonKey(name: 'setup_team_id') String? setupTeamId,
    required Map<String, dynamic> format,""",
    "MatchDto setup field",
)

text = replace_once(
    text,
    """    @JsonKey(name: 'toss_face') String? tossFace,
    @JsonKey(name: 'start_phase') @Default('toss') String startPhase,""",
    """    @JsonKey(name: 'toss_face') String? tossFace,
    @JsonKey(name: 'toss_recorded_by') String? tossRecordedBy,
    @JsonKey(name: 'start_phase') @Default('toss') String startPhase,""",
    "MatchDto toss actor field",
)

text = replace_once(
    text,
    """        teamACaptain: teamACaptain,
        teamBCaptain: teamBCaptain,
        format: MatchFormat(""",
    """        teamACaptain: teamACaptain,
        teamBCaptain: teamBCaptain,
        setupTeamId: setupTeamId == null ? null : TeamId(setupTeamId!),
        format: MatchFormat(""",
    "MatchDto setup mapping",
)

text = replace_once(
    text,
    """        tossFace: tossFace,
        startPhase: MatchStartPhase.fromWire(startPhase),""",
    """        tossFace: tossFace,
        tossRecordedBy: tossRecordedBy,
        startPhase: MatchStartPhase.fromWire(startPhase),""",
    "MatchDto toss actor mapping",
)

write(rel, text)


# ---------------------------------------------------------------------------
# Repository contract
# ---------------------------------------------------------------------------

rel = "lib/features/matches/domain/repositories/matches_repository.dart"
text = read(rel)

old = """  /// The match creator records who won the toss — their one action in the
  /// flow. Leaves `start_phase` on 'toss': the call itself belongs to the
  /// winner, not to whoever held the coin.
  ///
  /// Correcting a misrecord is allowed until the openers are locked, and
  /// clears any decision already made against the previous winner.
  Future<Either<Failure, Unit>> recordTossWinner({
    required MatchId id,
    required TeamId wonBy,
    String? face,
  });

  /// The winning side's captain chooses to bat or bowl. Advances
  /// `start_phase: toss → lineup`, handing the flow to the batting side.
  Future<Either<Failure, Unit>> recordTossDecision({
    required MatchId id,
    required TossDecision decision,
  });

"""
new = """  /// Record the complete physical toss atomically.
  ///
  /// The authorized Cricket setup-side member/official records both the winner and the winning
  /// side's verbal bat/bowl choice. The server authorizes this through
  /// `cricket.match.setup`; role names and `created_by` are not authorization.
  Future<Either<Failure, Unit>> recordToss({
    required MatchId id,
    required TeamId wonBy,
    required TossDecision decision,
    String? face,
  });

  /// Effective generic RBAC check used only to render the correct UI.
  /// The Edge Function independently re-checks the same permission on write.
  Future<Either<Failure, bool>> canTeamPermission({
    required TeamId teamId,
    required String permission,
  });

  /// Match-scoped effective permission, used for assigned officials.
  Future<Either<Failure, bool>> canMatchPermission({
    required MatchId matchId,
    required String permission,
  });

"""
text = replace_once(text, old, new, "MatchesRepository toss contract")

text = text.replace(
    "  /// Batting captain locks the opening pair. Advances\n",
    "  /// A user with `cricket.match.setup` for the batting team (or a match-scoped\n"
    "  /// setup grant) locks the opening pair. Advances\n",
    1,
).replace(
    "  /// Batting captain taps Start. Promotes status → live, start_phase → live,\n",
    "  /// A user with batting-side/match `cricket.match.setup` taps Start. Promotes\n"
    "  /// status → live, start_phase → live,\n",
    1,
)

write(rel, text)


# ---------------------------------------------------------------------------
# Remote datasource
# ---------------------------------------------------------------------------

rel = "lib/features/matches/data/datasources/matches_remote_datasource.dart"
text = read(rel)

old = """  Future<void> recordTossWinner({
    required String matchId,
    required String wonBy,
    String? face,
  }) =>
      _startRpc('record_toss_winner', {
        'p_match_id': matchId,
        'p_won_by': wonBy,
        if (face != null) 'p_face': face,
      });

  Future<void> recordTossDecision({
    required String matchId,
    required String decision,
  }) =>
      _startRpc('record_toss_decision', {
        'p_match_id': matchId,
        'p_decision': decision,
      });

"""
new = """  Future<void> recordToss({
    required String matchId,
    required String wonBy,
    required String decision,
    String? face,
  }) =>
      _startRpc('record_toss', {
        'p_match_id': matchId,
        'p_won_by': wonBy,
        'p_decision': decision,
        if (face != null) 'p_face': face,
      });

  Future<bool> canTeamPermission({
    required String teamId,
    required String permission,
  }) async {
    try {
      final allowed = await _supabase.rpc<dynamic>(
        'team_can',
        params: {
          'p_team_id': teamId,
          'p_permission': permission,
        },
      );
      return allowed == true;
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<bool> canMatchPermission({
    required String matchId,
    required String permission,
  }) async {
    try {
      final allowed = await _supabase.rpc<dynamic>(
        'can',
        params: {
          'p_scope': 'match',
          'p_entity_id': matchId,
          'p_permission': permission,
        },
      );
      return allowed == true;
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

"""
text = replace_once(text, old, new, "MatchesRemoteDataSource toss + permission methods")
write(rel, text)


# ---------------------------------------------------------------------------
# Repository implementation
# ---------------------------------------------------------------------------

rel = "lib/features/matches/data/repositories/matches_repository_impl.dart"
text = read(rel)

old = """  @override
  Future<Either<Failure, Unit>> recordTossWinner({
    required MatchId id,
    required TeamId wonBy,
    String? face,
  }) async {
    try {
      await _remote.recordTossWinner(
        matchId: id.value,
        wonBy: wonBy.value,
        face: face,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> recordTossDecision({
    required MatchId id,
    required TossDecision decision,
  }) async {
    try {
      await _remote.recordTossDecision(
        matchId: id.value,
        decision: decision.wire,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

"""
new = """  @override
  Future<Either<Failure, Unit>> recordToss({
    required MatchId id,
    required TeamId wonBy,
    required TossDecision decision,
    String? face,
  }) async {
    try {
      await _remote.recordToss(
        matchId: id.value,
        wonBy: wonBy.value,
        decision: decision.wire,
        face: face,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canTeamPermission({
    required TeamId teamId,
    required String permission,
  }) async {
    try {
      return Right(
        await _remote.canTeamPermission(
          teamId: teamId.value,
          permission: permission,
        ),
      );
    } on UnauthorizedException {
      return const Right(false);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canMatchPermission({
    required MatchId matchId,
    required String permission,
  }) async {
    try {
      return Right(
        await _remote.canMatchPermission(
          matchId: matchId.value,
          permission: permission,
        ),
      );
    } on UnauthorizedException {
      return const Right(false);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

"""
text = replace_once(text, old, new, "MatchesRepositoryImpl toss + permission methods")
write(rel, text)


# ---------------------------------------------------------------------------
# My Matches: capability-driven start card
# ---------------------------------------------------------------------------

rel = "lib/features/matches/presentation/providers/my_matches_providers.dart"
text = read(rel)

old = """  // Past sorted by recency descending (createdAt as proxy when end_time not
  // surfaced on the entity).
  past.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final confirmedRows = [
    for (final m in upcoming)
      _confirmedFor(m, teamsById,
          currentUserId: userId,
          myRoles: myRoles,
          tournamentNames: tournamentNames),
  ];
"""
new = """  // Past sorted by recency descending (createdAt as proxy when end_time not
  // surfaced on the entity).
  past.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Match Start UI authority comes from the generic RBAC system, not role
  // names. Ask the same capability system the Edge Function enforces.
  const setupPermission = 'cricket.match.setup';
  final repo = ref.read(matchesRepositoryProvider);
  final canSetupByMatchId = <String, bool>{};

  await Future.wait(
    upcoming.map((m) async {
      final matchScoped = await repo.canMatchPermission(
        matchId: m.id,
        permission: setupPermission,
      );
      final canMatch = matchScoped.fold((_) => false, (v) => v);

      final teamId = _setupAuthorityTeam(m);
      var canTeam = false;
      if (teamId != null) {
        final teamScoped = await repo.canTeamPermission(
          teamId: teamId,
          permission: setupPermission,
        );
        canTeam = teamScoped.fold((_) => false, (v) => v);
      }

      canSetupByMatchId[m.id.value] = canMatch || canTeam;
    }),
  );

  final confirmedRows = [
    for (final m in upcoming)
      _confirmedFor(m, teamsById,
          currentUserId: userId,
          myRoles: myRoles,
          canSetup: canSetupByMatchId[m.id.value] ?? false,
          tournamentNames: tournamentNames),
  ];
"""
text = replace_once(text, old, new, "myMatches capability prefetch")

old = """int _byScheduledThenCreated(Match a, Match b) {
  final aT = a.scheduledStartTime ?? a.createdAt;
  final bT = b.scheduledStartTime ?? b.createdAt;
  return aT.compareTo(bT);
}

MyMatchConfirmed _confirmedFor(
"""
new = """int _byScheduledThenCreated(Match a, Match b) {
  final aT = a.scheduledStartTime ?? a.createdAt;
  final bT = b.scheduledStartTime ?? b.createdAt;
  return aT.compareTo(bT);
}

/// Team whose role matrix controls the current pre-live setup action.
///
/// Toss -> Cricket setup team.
/// Lineup/ready -> batting team.
/// Match-scoped official authority is checked separately.
TeamId? _setupAuthorityTeam(Match m) {
  if (m.startPhase == MatchStartPhase.toss) {
    return m.setupTeamId;
  }

  if (m.startPhase == MatchStartPhase.lineup ||
      m.startPhase == MatchStartPhase.ready) {
    final won = m.tossWonBy;
    final decision = m.tossDecision;
    if (won == null || decision == null) return null;
    if (decision == TossDecision.bat) return won;
    if (won == m.teamAId) return m.teamBId;
    if (won == m.teamBId) return m.teamAId;
  }

  return null;
}

MyMatchConfirmed _confirmedFor(
"""
text = replace_once(text, old, new, "myMatches setup authority helper")

text = replace_once(
    text,
    """  required String currentUserId,
  required Map<String, TeamRelationship> myRoles,
  Map<String, String> tournamentNames = const {},
}) {""",
    """  required String currentUserId,
  required Map<String, TeamRelationship> myRoles,
  required bool canSetup,
  Map<String, String> tournamentNames = const {},
}) {""",
    "myMatches confirmed signature",
)

old = """  // Toss-time detection — design's Case 03b. The card flips to "tap to
  // start" when the captain is approximately AT match time, not just
  // because a row was created with a default start_phase. Triggers when:
  //   (a) Captain has actively opened Match Start (status = toss), OR
  //   (b) We're within 30 min before scheduled start and up to 6h after
  //       (covering "I'm at the ground but late") on a still-pre-live row.
  // Excludes future-scheduled matches that just happen to have start_phase
  // defaulting to 'toss' on the row.
  final now = DateTime.now();
  final timeBracket = start != null &&
      now.isAfter(start.subtract(const Duration(minutes: 30))) &&
      now.isBefore(start.add(const Duration(hours: 6)));
  final isCaptain = role == MatchRoleKind.captain;
  final tossInProgress = m.status == MatchStatus.toss && isCaptain;
  final tossReady = tossInProgress ||
      (isCaptain &&
          (m.status == MatchStatus.scheduled ||
              m.status == MatchStatus.rescheduled) &&
          timeBracket);

  final when = tossReady
      ? 'Toss · ${_hhmm(start ?? DateTime.now())}'
      : _formatWhen(start, m.createdAt);
  final role0 = tossReady ? 'Captain · ready when you are' : roleLine.label;
  final countdown =
      tossReady ? 'Now' : _countdown(start, status: m.status);
  final urgent = tossReady || roleLine.urgent || _isUrgent(start, status: m.status);
  final helper = tossReady
      ? 'Both captains here. Tap to flip the coin together.'
      : null;
"""
new = """  // Match Start CTA is capability-driven. A team-specific role override may
  // allow or deny owner/manager/captain independently, and an assigned match
  // official may act through a match-scoped grant.
  final now = DateTime.now();
  final timeBracket = start != null &&
      now.isAfter(start.subtract(const Duration(minutes: 30))) &&
      now.isBefore(start.add(const Duration(hours: 6)));

  final setupInProgress =
      canSetup &&
      (m.status == MatchStatus.toss ||
          m.startPhase == MatchStartPhase.lineup ||
          m.startPhase == MatchStartPhase.ready);

  final tossReady = setupInProgress ||
      (canSetup &&
          (m.status == MatchStatus.scheduled ||
              m.status == MatchStatus.rescheduled) &&
          timeBracket);

  final when = tossReady
      ? 'Match setup · ${_hhmm(start ?? DateTime.now())}'
      : _formatWhen(start, m.createdAt);
  final role0 = tossReady ? 'Match setup · ready when you are' : roleLine.label;
  final countdown =
      tossReady ? 'Now' : _countdown(start, status: m.status);
  final urgent = tossReady || roleLine.urgent || _isUrgent(start, status: m.status);
  final helper = tossReady
      ? (m.startPhase == MatchStartPhase.toss
          ? 'The Cricket setup side records the complete toss: winner plus bat/bowl choice.'
          : 'The batting side selects the openers and starts the match.')
      : null;
"""
text = replace_once(text, old, new, "myMatches tossReady logic")

text = replace_once(
    text,
    """    // Duties route somewhere and take a trailing arrow; states do not. A
    // captain always owes something; a scorer only owes once play is on.
    roleIsDuty: role == MatchRoleKind.captain ||
        (role == MatchRoleKind.scoring && m.status.isLive),""",
    """    // Match Start duty is capability-based. Live scoring duty keeps its
    // existing presentation role until the scoring UI is capability-refactored.
    roleIsDuty: tossReady ||
        (role == MatchRoleKind.scoring && m.status.isLive),""",
    "myMatches roleIsDuty",
)

write(rel, text)


# ---------------------------------------------------------------------------
# Remove stale authorization comments from Match / TeamRelationship
# ---------------------------------------------------------------------------

rel = "lib/features/matches/domain/entities/match.dart"
text = read(rel)
text = replace_once(
    text,
    """  /// Permanent captain pinned on the matches row. Drives the toss-time
  /// auth check (`_is_match_captain`) before any match_players rows
  /// exist. The per-match captain flag for a single fixture lives on
  /// `MatchPlayer.isCaptain`.
""",
    """  /// Captain snapshot used for display/relationship context.
  ///
  /// IMPORTANT: captain identity does not authorize Match Start. Effective
  /// authorization is resolved by the generic RBAC permission matrix.
""",
    "Match captain authorization comment",
)
text = replace_once(
    text,
    """  /// User_id of the captain who locked the openers. Drives the "Locked by
  /// Imran" caption + the EDIT PICKS affordance (only the locker can edit).
  /// The actual opener match_player_ids live on `match_innings_state` —
  /// see `MatchInningsState.strikerId` / `nonStrikerId`.
  final String? openersSubmittedBy;""",
    """  /// User_id of the person who most recently locked the openers. Useful
  /// for audit/display only; any caller with effective match setup capability
  /// may perform the server-authorized setup operation.
  /// The actual opener match_player_ids live on `match_innings_state` —
  /// see `MatchInningsState.strikerId` / `nonStrikerId`.
  final String? openersSubmittedBy;""",
    "Match opener locker comment",
)
write(rel, text)

rel = "lib/features/teams/domain/entities/team_relationship.dart"
text = read(rel)
text = replace_once(
    text,
    """/// The signed-in user's relationship to a team.
///
/// This is the single client-side vocabulary for team authority. Presentation
/// may add orthogonal state such as `isFollowing` or `hasPendingInvite`, but it
/// must not invent another role enum.
""",
    """/// The signed-in user's display/relationship identity on a team.
///
/// IMPORTANT: role identity is not the authorization source of truth.
/// Effective permissions come from the generic RBAC engine (`can` / `team_can`)
/// because each team may override its role-permission matrix. Convenience
/// booleans below are presentation/default-policy hints only and must not gate
/// privileged writes.
""",
    "TeamRelationship authorization comment",
)
write(rel, text)


print()
print("Flutter/data-layer patch completed.")
print("NEXT: dart run build_runner build --delete-conflicting-outputs")
