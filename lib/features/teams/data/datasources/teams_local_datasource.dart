import 'dart:convert';

import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/unclaimed_player.dart';

/// Local cache for the three teams tables. Returns/streams domain entities.
/// LWW upserts mirror the todos reference (`upsertManyLww`).
class TeamsLocalDataSource {
  TeamsLocalDataSource(this._db);
  final AppDatabase _db;

  // ─── Teams ─────────────────────────────────────────────────────────────

  // Phase 1 limitation: filters by owner only. Managed-but-not-owned teams
  // can't be created yet (no add-manager flow), so this is complete for now;
  // when managers are addable, filter the sync pull to teams the user owns or
  // manages and/or query inside the `managers` JSON.
  Stream<List<Team>> watchMyTeams(String userId) {
    final q = _db.select(_db.teams)
      ..where((t) => t.ownerId.equals(userId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_toTeam).toList());
  }

  /// All cached teams (sync pulls public teams + the user's own), name-sorted.
  /// Used by match setup's opponent picker.
  Stream<List<Team>> watchAllTeams() {
    final q = _db.select(_db.teams)
      ..orderBy([(t) => OrderingTerm.asc(t.teamName)]);
    return q.watch().map((rows) => rows.map(_toTeam).toList());
  }

  Stream<Team?> watchTeam(String id) {
    final q = _db.select(_db.teams)..where((t) => t.id.equals(id));
    return q.watchSingleOrNull().map((row) => row == null ? null : _toTeam(row));
  }

  Future<Team?> getTeam(String id) async {
    final row =
        await (_db.select(_db.teams)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _toTeam(row);
  }

  Future<void> upsertTeam(Team team) =>
      _db.into(_db.teams).insertOnConflictUpdate(_teamCompanion(team));

  Future<void> upsertManyTeamsLww(List<Team> remote) async {
    final toUpsert = <Team>[];
    for (final r in remote) {
      final local = await (_db.select(_db.teams)
            ..where((t) => t.id.equals(r.id.value)))
          .getSingleOrNull();
      if (local != null && local.updatedAt.isAfter(r.updatedAt)) continue;
      toUpsert.add(r);
    }
    if (toUpsert.isEmpty) return;
    await _db.batch((b) {
      for (final r in toUpsert) {
        b.insert(_db.teams, _teamCompanion(r), mode: InsertMode.insertOrReplace);
      }
    });
  }

  // ─── Members ───────────────────────────────────────────────────────────

  /// Active roster, joined with unclaimed player names (Phase 1 = all unclaimed).
  Stream<List<RosterMember>> watchRoster(String teamId) {
    final q = _db.select(_db.teamMembers).join([
      leftOuterJoin(
        _db.unclaimedPlayers,
        _db.unclaimedPlayers.id.equalsExp(_db.teamMembers.playerId),
      ),
    ])
      ..where(_db.teamMembers.teamId.equals(teamId))
      ..orderBy([OrderingTerm.asc(_db.teamMembers.joinedAt)]);
    return q.watch().map((rows) => rows.map((row) {
          final m = row.readTable(_db.teamMembers);
          final u = row.readTableOrNull(_db.unclaimedPlayers);
          return RosterMember(
            member: _toMember(m),
            displayName: u?.displayName ?? 'Unknown player',
          );
        }).toList());
  }

  Future<TeamMember?> getMember(String id) async {
    final row = await (_db.select(_db.teamMembers)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toMember(row);
  }

  Future<List<TeamMember>> getMembersForTeam(String teamId) async {
    final rows = await (_db.select(_db.teamMembers)
          ..where((t) => t.teamId.equals(teamId)))
        .get();
    return rows.map(_toMember).toList();
  }

  Future<void> upsertMember(TeamMember m) =>
      _db.into(_db.teamMembers).insertOnConflictUpdate(_memberCompanion(m));

  Future<void> upsertManyMembersLww(List<TeamMember> remote) async {
    final toUpsert = <TeamMember>[];
    for (final r in remote) {
      final local = await (_db.select(_db.teamMembers)
            ..where((t) => t.id.equals(r.id.value)))
          .getSingleOrNull();
      if (local != null && local.updatedAt.isAfter(r.updatedAt)) continue;
      toUpsert.add(r);
    }
    if (toUpsert.isEmpty) return;
    await _db.batch((b) {
      for (final r in toUpsert) {
        b.insert(_db.teamMembers, _memberCompanion(r),
            mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<void> deleteMember(String id) =>
      (_db.delete(_db.teamMembers)..where((t) => t.id.equals(id))).go();

  // ─── Unclaimed players ───────────────────────────────────────────────────

  Future<void> upsertUnclaimed(UnclaimedPlayer p) => _db
      .into(_db.unclaimedPlayers)
      .insertOnConflictUpdate(_unclaimedCompanion(p));

  Future<void> upsertManyUnclaimedLww(List<UnclaimedPlayer> remote) async {
    final toUpsert = <UnclaimedPlayer>[];
    for (final r in remote) {
      final local = await (_db.select(_db.unclaimedPlayers)
            ..where((t) => t.id.equals(r.id.value)))
          .getSingleOrNull();
      if (local != null && local.updatedAt.isAfter(r.updatedAt)) continue;
      toUpsert.add(r);
    }
    if (toUpsert.isEmpty) return;
    await _db.batch((b) {
      for (final r in toUpsert) {
        b.insert(_db.unclaimedPlayers, _unclaimedCompanion(r),
            mode: InsertMode.insertOrReplace);
      }
    });
  }

  // ─── Companions + mappers ─────────────────────────────────────────────────

  TeamsCompanion _teamCompanion(Team t) => TeamsCompanion.insert(
        id: t.id.value,
        ownerId: t.ownerId,
        teamName: t.name,
        teamType: t.type.wire,
        description: Value(t.description),
        homeGround: Value(t.homeGround),
        city: Value(t.city),
        foundedYear: Value(t.foundedYear),
        primaryColor: Value(t.primaryColor),
        secondaryColor: Value(t.secondaryColor),
        managers: Value(jsonEncode(t.managers)),
        privacy: Value(t.privacy.wire),
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  TeamMembersCompanion _memberCompanion(TeamMember m) =>
      TeamMembersCompanion.insert(
        id: m.id.value,
        teamId: m.teamId.value,
        playerId: m.playerId,
        playerType: m.playerType.wire,
        jerseyNumber: Value(m.jerseyNumber),
        role: Value(m.role.wire),
        addedBy: m.addedBy,
        joinedAt: m.joinedAt,
        updatedAt: m.updatedAt,
      );

  UnclaimedPlayersCompanion _unclaimedCompanion(UnclaimedPlayer p) =>
      UnclaimedPlayersCompanion.insert(
        id: p.id.value,
        displayName: p.displayName,
        addedBy: p.addedBy,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      );

  Team _toTeam(LocalTeam row) => Team(
        id: TeamId(row.id),
        ownerId: row.ownerId,
        name: row.teamName,
        type: TeamType.fromWire(row.teamType),
        privacy: TeamPrivacy.fromWire(row.privacy),
        managers: (jsonDecode(row.managers) as List).cast<String>(),
        description: row.description,
        homeGround: row.homeGround,
        city: row.city,
        foundedYear: row.foundedYear,
        primaryColor: row.primaryColor,
        secondaryColor: row.secondaryColor,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  TeamMember _toMember(LocalTeamMember row) => TeamMember(
        id: MembershipId(row.id),
        teamId: TeamId(row.teamId),
        playerId: row.playerId,
        playerType: PlayerType.fromWire(row.playerType),
        role: MemberRole.fromWire(row.role),
        jerseyNumber: row.jerseyNumber,
        addedBy: row.addedBy,
        joinedAt: row.joinedAt,
        updatedAt: row.updatedAt,
      );
}
