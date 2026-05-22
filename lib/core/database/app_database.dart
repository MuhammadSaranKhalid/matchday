import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Todos, PendingOperations, WizardDrafts, Teams, TeamMembers, UnclaimedPlayers],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes(m);
          await _createTeamIndexes(m);
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: add indexes for the columns we ORDER BY / filter on.
          if (from < 2) {
            await _createIndexes(m);
          }
          // v2 → v3: wizard draft persistence (onboarding, team-create, ...).
          if (from < 3) {
            await m.createTable(wizardDrafts);
          }
          // v3 → v4: offline-first teams (Feature 3).
          if (from < 4) {
            await m.createTable(teams);
            await m.createTable(teamMembers);
            await m.createTable(unclaimedPlayers);
            await _createTeamIndexes(m);
          }
          // Future migrations go here.
        },
      );

  /// Indexes for the columns the app reads against: `created_at` (every
  /// `watchAll`/`getAll` orders by it) and `user_id` (future per-user filters).
  /// `IF NOT EXISTS` keeps onCreate + onUpgrade idempotent.
  Future<void> _createIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS todos_created_at ON todos (created_at)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS todos_user_id ON todos (user_id)',
    );
  }

  /// Indexes for the teams reads: members are listed/filtered by team.
  Future<void> _createTeamIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS team_members_team_id ON team_members (team_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS teams_owner_id ON teams (owner_id)',
    );
  }

  /// Wipe the local DB on sign-out so a different user on the same
  /// device never sees the previous user's cached todos.
  ///
  /// Called from the auth flow when sign-out completes.
  Future<void> clear() async {
    await batch((b) {
      b.deleteAll(todos);
      b.deleteAll(pendingOperations);
      b.deleteAll(wizardDrafts);
      b.deleteAll(teams);
      b.deleteAll(teamMembers);
      b.deleteAll(unclaimedPlayers);
    });
  }
}

/// drift_flutter handles native sqlite3 setup, path resolution, and
/// background isolate creation. The DB file lives in the app's
/// documents directory.
QueryExecutor _openConnection() => driftDatabase(name: 'novex_clean_arch');
