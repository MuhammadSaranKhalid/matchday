import 'package:drift/drift.dart';

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
  TextColumn get entityType => text()(); // "todo" for now
  TextColumn get entityId => text()();   // UUID of the affected row
  TextColumn get payload => text().nullable()(); // JSON for create/update
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

enum OpType { create, update, toggle, delete }
