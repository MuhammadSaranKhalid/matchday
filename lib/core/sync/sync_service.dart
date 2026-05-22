import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import 'pending_operations_datasource.dart';
import '../../features/todos/data/datasources/todos_local_datasource.dart';
import '../../features/todos/data/datasources/todos_remote_datasource.dart';
import '../../features/teams/data/datasources/teams_local_datasource.dart';
import '../../features/teams/data/datasources/teams_remote_datasource.dart';

/// Orchestrates the offline-first lifecycle for every synced feature.
///
/// Responsibilities:
///  1. Replay pending ops to Supabase in FIFO order (dispatched by entityType).
///  2. Pull remote changes and merge into local with LWW conflict resolution.
///  3. Subscribe to Supabase real-time and mirror server pushes into local.
///
/// NOTE (CLAUDE.md §6.4): this now handles two features (todos + teams), and
/// teams alone spans three entity types — the threshold at which the documented
/// `SyncHandler` interface refactor becomes due. The next synced feature should
/// trigger that refactor rather than adding another `entityType` branch here.
class SyncService {
  SyncService({
    required TodosLocalDataSource todosLocal,
    required TodosRemoteDataSource todosRemote,
    required TeamsLocalDataSource teamsLocal,
    required TeamsRemoteDataSource teamsRemote,
    required PendingOperationsDataSource pendingOps,
    required SupabaseClient supabase,
  })  : _todosLocal = todosLocal,
        _todosRemote = todosRemote,
        _teamsLocal = teamsLocal,
        _teamsRemote = teamsRemote,
        _pending = pendingOps,
        _supabase = supabase;

  final TodosLocalDataSource _todosLocal;
  final TodosRemoteDataSource _todosRemote;
  final TeamsLocalDataSource _teamsLocal;
  final TeamsRemoteDataSource _teamsRemote;
  final PendingOperationsDataSource _pending;
  final SupabaseClient _supabase;

  final List<StreamSubscription<dynamic>> _realtimeSubs = [];
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
      developer.log('Sync failed', name: 'SyncService', error: e, stackTrace: st);
    } finally {
      _running = false;
    }
  }

  /// After this many failed attempts an op is treated as permanently failing
  /// and is skipped rather than replayed forever.
  static const _maxAttempts = 10;

  Future<void> _replayPendingOps() async {
    final ops = await _pending.getAll();
    for (final op in ops) {
      if (op.attempts >= _maxAttempts) {
        developer.log(
          'Skipping poison pending op ${op.id} '
          '(${op.entityType}/${op.entityId}) after ${op.attempts} attempts; '
          'last error: ${op.lastError}',
          name: 'SyncService',
        );
        continue;
      }
      try {
        await _executeOp(op);
        await _pending.deleteById(op.id);
      } catch (e) {
        await _pending.recordFailure(op.id, e.toString());
        // Continue with the next op; it'll retry next cycle.
      }
    }
  }

  Future<void> _executeOp(PendingOperation op) async {
    switch (op.entityType) {
      case 'todo':
        await _executeTodoOp(op);
      case 'team':
        await _executeTeamOp(op);
      case 'team_member':
        await _executeTeamMemberOp(op);
      case 'unclaimed_player':
        await _executeUnclaimedOp(op);
      default:
        developer.log('Unknown pending op entityType: ${op.entityType}',
            name: 'SyncService');
    }
  }

  // ─── Todos ─────────────────────────────────────────────────────────────

  Future<void> _executeTodoOp(PendingOperation op) async {
    switch (op.opType) {
      case OpType.create:
        final data = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto = await _todosRemote.create(
          id: data['id'] as String,
          title: data['title'] as String,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
        await _todosLocal.upsert(dto.toEntity(), userId: dto.userId);
      case OpType.toggle:
        final data = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto = await _todosRemote.setCompleted(
          id: op.entityId,
          completed: data['completed'] as bool,
        );
        await _todosLocal.upsert(dto.toEntity(), userId: dto.userId);
      case OpType.update:
        final data = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto =
            await _todosRemote.updateTitle(id: op.entityId, title: data['title'] as String);
        await _todosLocal.upsert(dto.toEntity(), userId: dto.userId);
      case OpType.delete:
        await _todosRemote.delete(op.entityId);
    }
  }

  // ─── Teams ─────────────────────────────────────────────────────────────

  Future<void> _executeTeamOp(PendingOperation op) async {
    // Only create is enqueued for teams in Phase 1.
    if (op.opType == OpType.create) {
      final data = jsonDecode(op.payload!) as Map<String, dynamic>;
      final dto = await _teamsRemote.createTeam(data);
      await _teamsLocal.upsertTeam(dto.toEntity());
    }
  }

  Future<void> _executeUnclaimedOp(PendingOperation op) async {
    if (op.opType == OpType.create) {
      final data = jsonDecode(op.payload!) as Map<String, dynamic>;
      final dto = await _teamsRemote.createUnclaimed(data);
      await _teamsLocal.upsertUnclaimed(dto.toEntity());
    }
  }

  Future<void> _executeTeamMemberOp(PendingOperation op) async {
    switch (op.opType) {
      case OpType.create:
        final data = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto = await _teamsRemote.createMember(data);
        await _teamsLocal.upsertMember(dto.toEntity());
      case OpType.update:
        final changes = jsonDecode(op.payload!) as Map<String, dynamic>;
        final dto = await _teamsRemote.updateMember(op.entityId, changes);
        await _teamsLocal.upsertMember(dto.toEntity());
      case OpType.delete:
        await _teamsRemote.deleteMember(op.entityId);
      case OpType.toggle:
        break; // not used by teams
    }
  }

  /// Pull recent rows from Supabase and merge into local using LWW.
  Future<void> _pullAndMerge() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final todos = await _todosRemote.list();
    await _todosLocal.upsertManyLww(
      todos.map((d) => d.toEntity()).toList(),
      userId: userId,
    );

    final teams = await _teamsRemote.listTeams();
    await _teamsLocal.upsertManyTeamsLww(teams.map((d) => d.toEntity()).toList());

    final unclaimed = await _teamsRemote.listUnclaimed();
    await _teamsLocal
        .upsertManyUnclaimedLww(unclaimed.map((d) => d.toEntity()).toList());

    final members = await _teamsRemote.listMembers();
    await _teamsLocal
        .upsertManyMembersLww(members.map((d) => d.toEntity()).toList());
  }

  /// Start mirroring Supabase real-time pushes into the local DB.
  /// Idempotent — calling twice is a no-op.
  void startRealtimeMirror() {
    if (_realtimeSubs.isNotEmpty) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeSubs.add(_todosRemote.watchStream().listen(
          (dtos) => _todosLocal.upsertManyLww(
            dtos.map((d) => d.toEntity()).toList(),
            userId: userId,
          ),
          onError: _logRealtimeError,
        ));
    _realtimeSubs.add(_teamsRemote.watchTeams().listen(
          (dtos) =>
              _teamsLocal.upsertManyTeamsLww(dtos.map((d) => d.toEntity()).toList()),
          onError: _logRealtimeError,
        ));
    _realtimeSubs.add(_teamsRemote.watchUnclaimed().listen(
          (dtos) => _teamsLocal
              .upsertManyUnclaimedLww(dtos.map((d) => d.toEntity()).toList()),
          onError: _logRealtimeError,
        ));
    _realtimeSubs.add(_teamsRemote.watchMembers().listen(
          (dtos) => _teamsLocal
              .upsertManyMembersLww(dtos.map((d) => d.toEntity()).toList()),
          onError: _logRealtimeError,
        ));
  }

  void _logRealtimeError(Object e, StackTrace st) {
    developer.log('Realtime stream error',
        name: 'SyncService', error: e, stackTrace: st);
  }

  void stopRealtimeMirror() {
    for (final sub in _realtimeSubs) {
      sub.cancel();
    }
    _realtimeSubs.clear();
  }

  void dispose() {
    stopRealtimeMirror();
  }
}
