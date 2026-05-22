import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/pending_operations_datasource.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todos_repository.dart';
import '../datasources/todos_local_datasource.dart';

/// Offline-first Todos repository.
///
/// Reads ALWAYS go to the local DB — the UI never blocks on the network.
/// Writes ALWAYS go to the local DB first, get enqueued in the pending
/// ops queue, then nudge the sync service to push immediately.
///
/// The Supabase client is consulted only for the current user_id; all
/// actual Supabase round-trips happen inside SyncService.
class TodosRepositoryImpl implements TodosRepository {
  TodosRepositoryImpl({
    required TodosLocalDataSource local,
    required PendingOperationsDataSource pendingOps,
    required SyncService syncService,
    required SupabaseClient supabase,
    Uuid? uuid,
  })  : _local = local,
        _pending = pendingOps,
        _sync = syncService,
        _supabase = supabase,
        _uuid = uuid ?? const Uuid();

  final TodosLocalDataSource _local;
  final PendingOperationsDataSource _pending;
  final SyncService _sync;
  final SupabaseClient _supabase;
  final Uuid _uuid;

  String _requireUserId() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No signed-in user — cannot mutate todos');
    }
    return id;
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Todo>>> getAll() async {
    try {
      final todos = await _local.getAll();
      return Right(todos);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<Todo>> watchAll() => _local.watchAll().handleError(
        // Translate raw drift/cache errors into a typed Failure carried across
        // the stream boundary, so the UI can render `failure.message` instead
        // of a raw exception string (see FailureWrapper in core/error).
        (Object e) => throw FailureWrapper(CacheFailure(e.toString())),
      );

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Todo>> add(String title) async {
    try {
      final userId = _requireUserId();
      final now = DateTime.now();
      final todo = Todo(
        id: TodoId(_uuid.v4()),
        title: title,
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      await _local.upsert(todo, userId: userId);
      await _pending.enqueueCreate(
        id: todo.id.value,
        title: title,
        createdAt: now,
      );

      // Fire-and-forget — UI doesn't wait for the network.
      // If offline, sync() is a no-op until connectivity returns.
      unawaited(_sync.sync());

      return Right(todo);
    } on StateError catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Todo>> toggle(TodoId id) async {
    try {
      final current = await _local.getById(id.value);
      if (current == null) {
        return const Left(NotFoundFailure('Todo not found locally'));
      }
      final newCompleted = !current.completed;
      await _local.updateCompleted(id.value, newCompleted);
      await _pending.enqueueSetCompleted(
        id: id.value,
        completed: newCompleted,
      );
      unawaited(_sync.sync());

      // Read back to return the canonical local row (with new updatedAt).
      final updated = await _local.getById(id.value);
      return Right(updated!);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(TodoId id) async {
    try {
      await _local.deleteById(id.value);
      await _pending.enqueueDelete(id.value);
      unawaited(_sync.sync());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
