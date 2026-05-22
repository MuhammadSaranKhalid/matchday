import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

/// Read/write the shared pending-operations queue.
///
/// Cross-feature infrastructure (the `pending_operations` table is shared by
/// every offline feature), so it lives in core — features must NOT reach into
/// each other's data layers for it.
///
/// The sync service walks this in FIFO order (by id ASC) and pushes each op to
/// Supabase. Successful ops are deleted; failures bump `attempts` and persist
/// the error message.
class PendingOperationsDataSource {
  PendingOperationsDataSource(this._db);
  final AppDatabase _db;

  /// Generic enqueue used by any feature. [payload] is a JSON-encodable map.
  Future<int> enqueue({
    required OpType opType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
  }) {
    return _db.into(_db.pendingOperations).insert(
          PendingOperationsCompanion.insert(
            opType: opType,
            entityType: entityType,
            entityId: entityId,
            payload:
                payload == null ? const Value.absent() : Value(jsonEncode(payload)),
            createdAt: DateTime.now(),
          ),
        );
  }

  // ─── Todos convenience wrappers (reference feature ONLY) ─────────────────
  // These hard-code entityType:'todo' and the todos payload shape. New
  // features should call the generic enqueue() above instead (see teams).

  Future<int> enqueueCreate({
    required String id,
    required String title,
    required DateTime createdAt,
  }) =>
      enqueue(
        opType: OpType.create,
        entityType: 'todo',
        entityId: id,
        payload: {
          'id': id,
          'title': title,
          'created_at': createdAt.toIso8601String(),
        },
      );

  Future<int> enqueueSetCompleted({
    required String id,
    required bool completed,
  }) =>
      enqueue(
        opType: OpType.toggle,
        entityType: 'todo',
        entityId: id,
        payload: {'completed': completed},
      );

  Future<int> enqueueUpdateTitle({required String id, required String title}) =>
      enqueue(
        opType: OpType.update,
        entityType: 'todo',
        entityId: id,
        payload: {'title': title},
      );

  Future<int> enqueueDelete(String id) =>
      enqueue(opType: OpType.delete, entityType: 'todo', entityId: id);

  // ─── Queue management ────────────────────────────────────────────────────

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
