import 'package:drift/drift.dart';
import '../sync/op_type.dart';

export '../sync/op_type.dart' show OpType;

/// Local mirror of the Supabase `todos` table.
///
/// IDs are UUIDs generated client-side so an offline create can produce
/// the same id the server will eventually accept (avoids the "temp id"
/// swap dance).
@DataClassName('LocalTodo')
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 1, max: 140)();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  /// LWW conflict-resolution key. Local edits set this to DateTime.now().
  /// Sync uses this to decide whether server or local is the winning version.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Operations made while offline (or that failed while online).
///
/// The sync service walks this table in creation order and pushes each
/// op to Supabase. Successful ops are deleted; failures bump `attempts`
/// and write `lastError` for visibility.
///
/// One pending op per id-action pair would be ideal (so quick toggles
/// collapse into one), but that's an optimization for later.
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get opType => textEnum<OpType>()();
  TextColumn get entityType => text()(); // 'todo' | 'team' | 'team_member' | 'unclaimed_player'
  TextColumn get entityId => text()();   // UUID of the affected row
  TextColumn get payload => text().nullable()(); // JSON for create/update
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

// ─── Teams (offline-first, Feature 3) ─────────────────────────────────────────
//
// Three local mirrors of the Supabase teams schema. All carry updated_at for
// LWW. `managers` is stored as a JSON-encoded uuid list (drift has no native
// array column); Phase 1 only ever has the owner in it.

// Enum-ish columns store the domain enum's snake_case `wire` string (plain
// text, not drift textEnum) so the single source of truth stays in the teams
// domain and there's no enum name clash between this file and the domain.

@DataClassName('LocalTeam')
class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get teamName => text().withLength(min: 3, max: 50)();
  TextColumn get teamType => text()();
  TextColumn get description => text().nullable()();
  TextColumn get homeGround => text().nullable()();
  TextColumn get city => text().nullable()();
  IntColumn get foundedYear => integer().nullable()();
  TextColumn get primaryColor => text().nullable()();
  TextColumn get secondaryColor => text().nullable()();
  TextColumn get managers => text().withDefault(const Constant('[]'))();
  TextColumn get privacy => text().withDefault(const Constant('public'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalTeamMember')
class TeamMembers extends Table {
  TextColumn get id => text()(); // membership_id
  TextColumn get teamId => text()();
  TextColumn get playerId => text()(); // profiles.user_id OR unclaimed_id
  TextColumn get playerType => text()();
  IntColumn get jerseyNumber => integer().nullable()();
  TextColumn get role => text().withDefault(const Constant('player'))();
  TextColumn get addedBy => text()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalUnclaimedPlayer')
class UnclaimedPlayers extends Table {
  TextColumn get id => text()(); // unclaimed_id
  TextColumn get displayName => text()();
  TextColumn get addedBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local-only persistence for in-progress multi-step wizards (onboarding,
/// team-create, match-setup). Lets a user resume a half-filled flow after
/// killing the app. Keyed by a caller-defined string (e.g.
/// `onboarding:<userId>`); [payload] is the wizard's JSON-encoded draft.
///
/// Never synced — these rows hold transient client state, not domain data, so
/// they carry no `user_id`/`updated_at` LWW columns and never enqueue a
/// pending op. Cleared on sign-out alongside everything else.
@DataClassName('WizardDraftRow')
class WizardDrafts extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
