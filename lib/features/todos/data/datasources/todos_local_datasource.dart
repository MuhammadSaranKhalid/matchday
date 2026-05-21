import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../domain/entities/todo.dart';

/// Local cache of todos, backed by drift.
///
/// Always returns / streams Entity objects so the repository doesn't
/// have to deal with drift's generated row classes.
class TodosLocalDataSource {
  TodosLocalDataSource(this._db);
  final AppDatabase _db;

  Stream<List<Todo>> watchAll() {
    final query = _db.select(_db.todos)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  Future<List<Todo>> getAll() async {
    final rows = await _db.select(_db.todos).get();
    return rows.map(_toEntity).toList();
  }

  Future<Todo?> getById(String id) async {
    final row = await (_db.select(_db.todos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// Insert or replace. Used for both user-initiated creates and
  /// sync-down upserts.
  Future<void> upsert(Todo todo, {required String userId}) {
    return _db.into(_db.todos).insertOnConflictUpdate(
          TodosCompanion.insert(
            id: todo.id.value,
            userId: userId,
            title: todo.title,
            completed: Value(todo.completed),
            createdAt: todo.createdAt,
            updatedAt: todo.updatedAt,
          ),
        );
  }

  /// Bulk upsert used by sync after pulling from remote.
  /// Applies LWW: skips rows whose local updatedAt is newer.
  Future<void> upsertManyLww(
    List<Todo> remoteTodos, {
    required String userId,
  }) async {
    await _db.batch((batch) async {
      for (final remote in remoteTodos) {
        final localRow = await (_db.select(_db.todos)
              ..where((t) => t.id.equals(remote.id.value)))
            .getSingleOrNull();

        if (localRow != null &&
            localRow.updatedAt.isAfter(remote.updatedAt)) {
          // Local is newer — pending op will push it to remote. Skip.
          continue;
        }

        batch.insert(
          _db.todos,
          TodosCompanion.insert(
            id: remote.id.value,
            userId: userId,
            title: remote.title,
            completed: Value(remote.completed),
            createdAt: remote.createdAt,
            updatedAt: remote.updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> updateCompleted(String id, bool completed) async {
    final now = DateTime.now();
    await (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        completed: Value(completed),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateTitle(String id, String title) async {
    final now = DateTime.now();
    await (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        title: Value(title),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
  }

  Todo _toEntity(LocalTodo row) => Todo(
        id: TodoId(row.id),
        title: row.title,
        completed: row.completed,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
