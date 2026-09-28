import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../models/match_dto.dart';
import '../models/match_innings_state_dto.dart';
import '../models/match_player_dto.dart';

part 'matches_local_datasource.g.dart';

/// Local entity representing a pending or synced scoring write-ahead log entry.
class LocalScoringOp {
  const LocalScoringOp({
    required this.opId,
    required this.matchId,
    required this.inningsNumber,
    required this.localSeq,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.syncedAt,
    this.refusedAt,
    this.attempts = 0,
    this.lastError,
  });

  final String opId;
  final String matchId;
  final int inningsNumber;
  final int localSeq;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final DateTime? refusedAt;
  final int attempts;
  final String? lastError;

  /// Still owed to the server. A refused op is NOT pending — the server
  /// answered, and retrying a no produces another no.
  bool get isPending => syncedAt == null && refusedAt == null;

  /// The server answered and rejected this one. Terminal, and kept rather
  /// than deleted so the scorer can still read what did not apply.
  bool get isRefused => refusedAt != null;
}

abstract class MatchesLocalDataSource {
  Future<LocalScoringOp> appendOp({
    required String opId,
    required String matchId,
    required int inningsNumber,
    required String kind,
    required Map<String, dynamic> payload,
  });

  Future<List<LocalScoringOp>> pendingOps({
    required String matchId,
    required int inningsNumber,
  });

  /// Unsent ops for ONE innings.
  ///
  /// Scoped deliberately. A device-wide count means a single op that will never
  /// drain — a delivery the server refused months ago in another match — makes
  /// every future innings look permanently unsaved, which disables undo forever.
  Future<int> pendingOpsCount({
    required String matchId,
    required int inningsNumber,
  });

  Future<void> markOpSynced(String opId);

  /// A transport failure: bump the attempt count and keep the op queued.
  /// Use ONLY when the server never answered — a refusal is [markOpRefused].
  Future<void> markOpFailed(String opId, String error);

  /// The server answered and said no. Terminal: the op leaves the queue but
  /// stays in the table so it remains readable (design doc §19.3 — a refused
  /// write is never discarded).
  Future<void> markOpRefused(String opId, String reason);

  /// Ops the server refused, oldest first. Feeds any surface that shows the
  /// scorer what could not be applied.
  Future<List<LocalScoringOp>> refusedOps({
    required String matchId,
    required int inningsNumber,
  });

  Future<void> discardOp(String opId);

  Future<void> saveSnapshot({
    required String matchId,
    required int inningsNumber,
    required Map<String, dynamic> state,
    required int throughSeq,
  });

  Future<({Map<String, dynamic> state, int throughSeq})?> getSnapshot({
    required String matchId,
    required int inningsNumber,
  });

  Future<void> pruneOps({required String matchId, required int inningsNumber});

  // ── Match Hydration Cache (Offline-First) ────────────────────────────────

  Future<void> cacheMatch(MatchDto match);

  Future<MatchDto?> getCachedMatch(String matchId);

  Future<void> cacheMatchPlayers(String matchId, List<MatchPlayerDto> players);

  Future<List<MatchPlayerDto>> getCachedMatchPlayers(String matchId);

  Future<void> cacheInningsState(String matchId, MatchInningsStateDto state);

  Future<MatchInningsStateDto?> getCachedInningsState({
    required String matchId,
    required int inningsNumber,
  });
}

class MatchesLocalDataSourceImpl implements MatchesLocalDataSource {
  MatchesLocalDataSourceImpl(this._db);
  final AppDatabase _db;

  LocalScoringOp _toOp(ScoringOpRow r) => LocalScoringOp(
    opId: r.opId,
    matchId: r.matchId,
    inningsNumber: r.inningsNumber,
    localSeq: r.localSeq,
    kind: r.kind,
    payload: jsonDecode(r.payload) as Map<String, dynamic>,
    createdAt: r.createdAt,
    syncedAt: r.syncedAt,
    refusedAt: r.refusedAt,
    attempts: r.attempts,
    lastError: r.lastError,
  );

  @override
  Future<LocalScoringOp> appendOp({
    required String opId,
    required String matchId,
    required int inningsNumber,
    required String kind,
    required Map<String, dynamic> payload,
  }) => _db.transaction(() async {
    final last =
        await (_db.select(_db.scoringOps)
              ..where(
                (t) =>
                    t.matchId.equals(matchId) &
                    t.inningsNumber.equals(inningsNumber),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.localSeq)])
              ..limit(1))
            .getSingleOrNull();

    final row = ScoringOpRow(
      opId: opId,
      matchId: matchId,
      inningsNumber: inningsNumber,
      localSeq: (last?.localSeq ?? 0) + 1,
      kind: kind,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
      attempts: 0,
    );
    await _db.into(_db.scoringOps).insert(row);
    return _toOp(row);
  });

  @override
  Future<List<LocalScoringOp>> pendingOps({
    required String matchId,
    required int inningsNumber,
  }) async {
    final rows =
        await (_db.select(_db.scoringOps)
              ..where(
                (t) =>
                    t.matchId.equals(matchId) &
                    t.inningsNumber.equals(inningsNumber) &
                    t.syncedAt.isNull() &
                    t.refusedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.localSeq)]))
            .get();
    return rows.map(_toOp).toList();
  }

  @override
  Future<List<LocalScoringOp>> refusedOps({
    required String matchId,
    required int inningsNumber,
  }) async {
    final rows =
        await (_db.select(_db.scoringOps)
              ..where(
                (t) =>
                    t.matchId.equals(matchId) &
                    t.inningsNumber.equals(inningsNumber) &
                    t.refusedAt.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.localSeq)]))
            .get();
    return rows.map(_toOp).toList();
  }

  @override
  Future<int> pendingOpsCount({
    required String matchId,
    required int inningsNumber,
  }) => _db.pendingScoringOps(matchId: matchId, inningsNumber: inningsNumber);

  @override
  Future<void> markOpSynced(String opId) => (_db.update(_db.scoringOps)..where(
    (t) => t.opId.equals(opId),
  )).write(ScoringOpsCompanion(syncedAt: Value(DateTime.now())));

  @override
  Future<void> markOpFailed(String opId, String error) async {
    final row =
        await (_db.select(_db.scoringOps)
          ..where((t) => t.opId.equals(opId))).getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.scoringOps)..where((t) => t.opId.equals(opId))).write(
      ScoringOpsCompanion(
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  @override
  Future<void> markOpRefused(String opId, String reason) =>
      (_db.update(_db.scoringOps)..where((t) => t.opId.equals(opId))).write(
        ScoringOpsCompanion(
          refusedAt: Value(DateTime.now()),
          lastError: Value(reason),
        ),
      );

  @override
  Future<void> discardOp(String opId) =>
      (_db.delete(_db.scoringOps)..where((t) => t.opId.equals(opId))).go();

  @override
  Future<void> saveSnapshot({
    required String matchId,
    required int inningsNumber,
    required Map<String, dynamic> state,
    required int throughSeq,
  }) => _db
      .into(_db.scoringSnapshots)
      .insertOnConflictUpdate(
        ScoringSnapshotRow(
          matchId: matchId,
          inningsNumber: inningsNumber,
          state: jsonEncode(state),
          throughSeq: throughSeq,
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<({Map<String, dynamic> state, int throughSeq})?> getSnapshot({
    required String matchId,
    required int inningsNumber,
  }) async {
    final row =
        await (_db.select(_db.scoringSnapshots)..where(
          (t) =>
              t.matchId.equals(matchId) & t.inningsNumber.equals(inningsNumber),
        )).getSingleOrNull();
    if (row == null) return null;
    return (
      state: jsonDecode(row.state) as Map<String, dynamic>,
      throughSeq: row.throughSeq,
    );
  }

  @override
  /// Drops ops the server has confirmed. Refused ops survive pruning — they
  /// are the record of what could not be applied, and §19.3 forbids
  /// discarding them.
  Future<void> pruneOps({
    required String matchId,
    required int inningsNumber,
  }) async {
    await (_db.delete(_db.scoringOps)..where(
      (t) =>
          t.matchId.equals(matchId) &
          t.inningsNumber.equals(inningsNumber) &
          t.syncedAt.isNotNull(),
    )).go();
  }

  // ── Match Hydration Cache Implementation ──────────────────────────────────

  @override
  Future<void> cacheMatch(MatchDto match) => _db
      .into(_db.cachedMatches)
      .insertOnConflictUpdate(
        CachedMatchRow(
          matchId: match.matchId,
          payload: jsonEncode(match.toJson()),
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<MatchDto?> getCachedMatch(String matchId) async {
    final row =
        await (_db.select(_db.cachedMatches)
          ..where((t) => t.matchId.equals(matchId))).getSingleOrNull();
    if (row == null) return null;
    try {
      return MatchDto.fromJson(jsonDecode(row.payload) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheMatchPlayers(
    String matchId,
    List<MatchPlayerDto> players,
  ) => _db
      .into(_db.cachedMatchPlayers)
      .insertOnConflictUpdate(
        CachedMatchPlayersRow(
          matchId: matchId,
          payload: jsonEncode(players.map((p) => p.toJson()).toList()),
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<List<MatchPlayerDto>> getCachedMatchPlayers(String matchId) async {
    final row =
        await (_db.select(_db.cachedMatchPlayers)
          ..where((t) => t.matchId.equals(matchId))).getSingleOrNull();
    if (row == null) return const [];
    try {
      final list = jsonDecode(row.payload) as List<dynamic>;
      return list
          .map((item) => MatchPlayerDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> cacheInningsState(String matchId, MatchInningsStateDto state) =>
      _db
          .into(_db.cachedInningsStates)
          .insertOnConflictUpdate(
            CachedInningsStateRow(
              matchId: matchId,
              inningsNumber: state.inningsNumber,
              payload: jsonEncode(state.toJson()),
              updatedAt: DateTime.now(),
            ),
          );

  @override
  Future<MatchInningsStateDto?> getCachedInningsState({
    required String matchId,
    required int inningsNumber,
  }) async {
    final row =
        await (_db.select(_db.cachedInningsStates)..where(
          (t) =>
              t.matchId.equals(matchId) & t.inningsNumber.equals(inningsNumber),
        )).getSingleOrNull();
    if (row == null) return null;
    try {
      return MatchInningsStateDto.fromJson(
        jsonDecode(row.payload) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
MatchesLocalDataSource matchesLocalDataSource(Ref ref) =>
    MatchesLocalDataSourceImpl(ref.watch(appDatabaseProvider));
