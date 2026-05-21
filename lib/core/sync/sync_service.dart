import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/tables.dart';
import '../../features/todos/data/datasources/pending_operations_datasource.dart';
import '../../features/todos/data/datasources/todos_local_datasource.dart';
import '../../features/todos/data/datasources/todos_remote_datasource.dart';

/// Orchestrates the offline-first lifecycle for the Todos feature.
///
/// Responsibilities:
///  1. Replay pending ops to Supabase in FIFO order.
///  2. Pull remote changes and merge into local with LWW conflict resolution.
///  3. Subscribe to Supabase real-time and mirror server pushes into local.
///
/// Not a Notifier — just a class held alive by a provider. The provider
/// wires connectivity transitions to trigger sync automatically.
class SyncService {
  SyncService({
    required TodosLocalDataSource local,
    required TodosRemoteDataSource remote,
    required PendingOperationsDataSource pendingOps,
    required SupabaseClient supabase,
  })  : _local = local,
        _remote = remote,
        _pending = pendingOps,
        _supabase = supabase;

  final TodosLocalDataSource _local;
  final TodosRemoteDataSource _remote;
  final PendingOperationsDataSource _pending;
  final SupabaseClient _supabase;

  StreamSubscription<List<dynamic>>? _realtimeSub;
  bool _running = false;

  /// Run a full sync cycle. Idempotent — re-entrant calls are dropped
  /// so connectivity flapping doesn't queue infinite syncs.
  Future<void> sync() async {
    if (_running) return;
    _running = true;
    try {
      await _replayPendingOps();
      await _pullAndMerge();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Sync failed: $e\n$st');
      }
    } finally {
      _running = false;
    }
  }

  /// Walk the pending queue and push each op to Supabase.
  /// Successful ops are deleted; failures are recorded but don't block
  /// the rest of the queue.
  Future<void> _replayPendingOps() async {
    final ops = await _pending.getAll();
    for (final op in ops) {
      try {
        await _executeOp(op);
        await _pending.deleteById(op.id);
      } catch (e) {
        await _pending.recordFailure(op.id, e.toString());
        // Continue with the next op rather than aborting the whole sweep.
        // The op will be retried on the next sync cycle.
      }
    }
  }

  Future<void> _executeOp(PendingOperation op) async {
    switch (op.opType) {
      case OpType.create:
        final data = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto = await _remote.create(
          id: data['id'] as String,
          title: data['title'] as String,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
        // Write the server-returned row back so updated_at matches.
        await _local.upsert(
          dto.toEntity(),
          userId: dto.userId,
        );
      case OpType.toggle:
        final data = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto = await _remote.setCompleted(
          id: op.entityId,
          completed: data['completed'] as bool,
        );
        await _local.upsert(dto.toEntity(), userId: dto.userId);
      case OpType.update:
        final data = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto = await _remote.updateTitle(
          id: op.entityId,
          title: data['title'] as String,
        );
        await _local.upsert(dto.toEntity(), userId: dto.userId);
      case OpType.delete:
        await _remote.delete(op.entityId);
        // Local was already deleted optimistically; nothing else to do.
    }
  }

  /// Pull all (recent) rows from Supabase and merge into local using LWW.
  Future<void> _pullAndMerge() async {
    final dtos = await _remote.list();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _local.upsertManyLww(
      dtos.map((d) => d.toEntity()).toList(),
      userId: userId,
    );
  }

  /// Start mirroring Supabase real-time pushes into the local DB.
  /// Idempotent — calling twice is a no-op.
  void startRealtimeMirror() {
    if (_realtimeSub != null) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeSub = _remote.watchStream().listen(
      (dtos) async {
        await _local.upsertManyLww(
          dtos.map((d) => d.toEntity()).toList(),
          userId: userId,
        );
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) debugPrint('Realtime stream error: $e');
      },
    );
  }

  void stopRealtimeMirror() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  void dispose() {
    stopRealtimeMirror();
  }
}
