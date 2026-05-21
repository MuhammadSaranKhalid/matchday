import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';

/// Read/write the pending operations queue.
///
/// The sync service walks this in FIFO order (by id ASC) and pushes
/// each op to Supabase. Successful ops are deleted; failures bump
/// `attempts` and persist the error message.
class PendingOperationsDataSource {
  PendingOperationsDataSource(this._db);
  final AppDatabase _db;

  Future<int> enqueueCreate({
    required String id,
    required String title,
    required DateTime createdAt,
  }) {
    return _db.into(_db.pendingOperations).insert(
          PendingOperationsCompanion.insert(
            opType: OpType.create,
            entityType: 'todo',
            entityId: id,
            payload: Value(jsonEncode({
              'id': id,
              'title': title,
              'created_at': createdAt.toIso8601String(),
            })),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<int> enqueueSetCompleted({
    required String id,
    required bool completed,
  }) {
    return _db.into(_db.pendingOperations).insert(
          PendingOperationsCompanion.insert(
            opType: OpType.toggle,
            entityType: 'todo',
            entityId: id,
            payload: Value(jsonEncode({'completed': completed})),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<int> enqueueUpdateTitle({
    required String id,
    required String title,
  }) {
    return _db.into(_db.pendingOperations).insert(
          PendingOperationsCompanion.insert(
            opType: OpType.update,
            entityType: 'todo',
            entityId: id,
            payload: Value(jsonEncode({'title': title})),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<int> enqueueDelete(String id) {
    return _db.into(_db.pendingOperations).insert(
          PendingOperationsCompanion.insert(
            opType: OpType.delete,
            entityType: 'todo',
            entityId: id,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// All pending ops, oldest first.
  Future<List<PendingOperation>> getAll() {
    final query = _db.select(_db.pendingOperations)
      ..orderBy([(o) => OrderingTerm.asc(o.id)]);
    return query.get();
  }

  Future<void> deleteById(int id) async {
    await (_db.delete(_db.pendingOperations)..where((o) => o.id.equals(id)))
        .go();
  }

  Future<void> recordFailure(int id, String error) async {
    final row = await (_db.select(_db.pendingOperations)
          ..where((o) => o.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.pendingOperations)..where((o) => o.id.equals(id)))
        .write(
      PendingOperationsCompanion(
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }
}
