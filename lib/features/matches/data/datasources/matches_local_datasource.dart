import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';

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
  final int attempts;
  final String? lastError;

  bool get isPending => syncedAt == null;
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

  Future<int> pendingOpsCount();

  Future<void> markOpSynced(String opId);

  Future<void> markOpFailed(String opId, String error);

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

  Future<void> pruneOps({
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
  }) =>
      _db.transaction(() async {
        final last = await (_db.select(_db.scoringOps)
              ..where((t) =>
                  t.matchId.equals(matchId) &
                  t.inningsNumber.equals(inningsNumber))
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
    final rows = await (_db.select(_db.scoringOps)
          ..where((t) =>
              t.matchId.equals(matchId) &
              t.inningsNumber.equals(inningsNumber) &
              t.syncedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.localSeq)]))
        .get();
    return rows.map(_toOp).toList();
  }

  @override
  Future<int> pendingOpsCount() => _db.pendingScoringOps();

  @override
  Future<void> markOpSynced(String opId) =>
      (_db.update(_db.scoringOps)..where((t) => t.opId.equals(opId)))
          .write(ScoringOpsCompanion(syncedAt: Value(DateTime.now())));

  @override
  Future<void> markOpFailed(String opId, String error) async {
    final row = await (_db.select(_db.scoringOps)
          ..where((t) => t.opId.equals(opId)))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.scoringOps)..where((t) => t.opId.equals(opId)))
        .write(ScoringOpsCompanion(
      attempts: Value(row.attempts + 1),
      lastError: Value(error),
    ));
  }

  @override
  Future<void> discardOp(String opId) =>
      (_db.delete(_db.scoringOps)..where((t) => t.opId.equals(opId))).go();

  @override
  Future<void> saveSnapshot({
    required String matchId,
    required int inningsNumber,
    required Map<String, dynamic> state,
    required int throughSeq,
  }) =>
      _db.into(_db.scoringSnapshots).insertOnConflictUpdate(
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
    final row = await (_db.select(_db.scoringSnapshots)
          ..where((t) =>
              t.matchId.equals(matchId) &
              t.inningsNumber.equals(inningsNumber)))
        .getSingleOrNull();
    if (row == null) return null;
    return (
      state: jsonDecode(row.state) as Map<String, dynamic>,
      throughSeq: row.throughSeq,
    );
  }

  @override
  Future<void> pruneOps({
    required String matchId,
    required int inningsNumber,
  }) async {
    await (_db.delete(_db.scoringOps)
          ..where((t) =>
              t.matchId.equals(matchId) &
              t.inningsNumber.equals(inningsNumber) &
              t.syncedAt.isNotNull()))
        .go();
  }
}

@Riverpod(keepAlive: true)
MatchesLocalDataSource matchesLocalDataSource(Ref ref) =>
    MatchesLocalDataSourceImpl(ref.watch(appDatabaseProvider));
