// MatchesLocalDataSource tests against a real SQLite in-memory database.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/features/matches/data/datasources/matches_local_datasource.dart';

const _match = 'match-1';

Map<String, dynamic> _delivery(int runs) => {
      'ballKind': 'legal',
      'runsScored': runs,
      'extras': 0,
      'isWicket': false,
    };

void main() {
  late AppDatabase db;
  late MatchesLocalDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = MatchesLocalDataSourceImpl(db);
  });
  tearDown(() => db.close());

  group('appendOp', () {
    test('a delivery survives being written', () async {
      await ds.appendOp(
        opId: 'op-1',
        matchId: _match,
        inningsNumber: 1,
        kind: 'ball',
        payload: _delivery(4),
      );

      final pending = await ds.pendingOps(matchId: _match, inningsNumber: 1);
      expect(pending, hasLength(1));
      expect(pending.single.payload['runsScored'], 4);
      expect(pending.single.isPending, isTrue);
    });

    test('localSeq increments per innings, preserving entry order', () async {
      for (var i = 1; i <= 5; i++) {
        await ds.appendOp(
          opId: 'op-$i',
          matchId: _match,
          inningsNumber: 1,
          kind: 'ball',
          payload: _delivery(i),
        );
      }

      final pending = await ds.pendingOps(matchId: _match, inningsNumber: 1);
      expect(pending.map((o) => o.localSeq), [1, 2, 3, 4, 5]);
      expect(pending.map((o) => o.payload['runsScored']), [1, 2, 3, 4, 5]);
    });

    test('concurrent appends never share a localSeq', () async {
      await Future.wait([
        for (var i = 1; i <= 10; i++)
          ds.appendOp(
            opId: 'race-$i',
            matchId: _match,
            inningsNumber: 1,
            kind: 'ball',
            payload: _delivery(i),
          ),
      ]);

      final pending = await ds.pendingOps(matchId: _match, inningsNumber: 1);
      final seqs = pending.map((o) => o.localSeq).toList();
      expect(seqs.toSet().length, 10, reason: 'every op got its own position');
      expect(seqs, List.generate(10, (i) => i + 1));
    });

    test('innings are numbered independently', () async {
      await ds.appendOp(
        opId: 'i1', matchId: _match, inningsNumber: 1,
        kind: 'ball', payload: _delivery(1),
      );
      await ds.appendOp(
        opId: 'i2', matchId: _match, inningsNumber: 2,
        kind: 'ball', payload: _delivery(1),
      );

      expect((await ds.pendingOps(matchId: _match, inningsNumber: 2)).single.localSeq, 1);
    });
  });

  group('sync lifecycle', () {
    test('a synced op stops being owed', () async {
      await ds.appendOp(
        opId: 'op-1', matchId: _match, inningsNumber: 1,
        kind: 'ball', payload: _delivery(1),
      );
      await ds.markOpSynced('op-1');

      expect(await ds.pendingOps(matchId: _match, inningsNumber: 1), isEmpty);
    });

    test('markOpFailed increments attempts and records error message', () async {
      await ds.appendOp(
        opId: 'op-1', matchId: _match, inningsNumber: 1,
        kind: 'ball', payload: _delivery(1),
      );
      await ds.markOpFailed('op-1', 'network drop');

      final pending = await ds.pendingOps(matchId: _match, inningsNumber: 1);
      expect(pending.single.attempts, 1);
      expect(pending.single.lastError, 'network drop');
    });

    test('discardOp removes the op completely', () async {
      await ds.appendOp(
        opId: 'op-1', matchId: _match, inningsNumber: 1,
        kind: 'ball', payload: _delivery(1),
      );
      await ds.discardOp('op-1');

      expect(await ds.pendingOps(matchId: _match, inningsNumber: 1), isEmpty);
    });

    test('pruneOps drops synced ops only', () async {
      await ds.appendOp(
        opId: 'synced', matchId: _match, inningsNumber: 1,
        kind: 'ball', payload: _delivery(1),
      );
      await ds.markOpSynced('synced');
      await ds.appendOp(
        opId: 'pending', matchId: _match, inningsNumber: 1,
        kind: 'ball', payload: _delivery(2),
      );

      await ds.pruneOps(matchId: _match, inningsNumber: 1);
      final remaining = await ds.pendingOps(matchId: _match, inningsNumber: 1);
      expect(remaining.single.opId, 'pending');
    });
  });

  group('snapshots', () {
    test('saving a snapshot updates throughSeq and state', () async {
      await ds.saveSnapshot(
        matchId: _match,
        inningsNumber: 1,
        state: {'score': '100/2'},
        throughSeq: 15,
      );

      final snap = await ds.getSnapshot(matchId: _match, inningsNumber: 1);
      expect(snap, isNotNull);
      expect(snap!.throughSeq, 15);
      expect(snap.state['score'], '100/2');
    });
  });
}
