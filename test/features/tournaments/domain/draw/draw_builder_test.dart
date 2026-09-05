import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/draw/draw_builder.dart';
import 'package:matchday/features/tournaments/domain/draw/draw_plan.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';

/// The draw builder is the single implementation of pairing in the app: the
/// seeding preview and Lock & Publish both call it. Before it existed the
/// console generated round one only, so a knockout could never reach a final
/// and a round robin published n/2 of its n(n-1)/2 fixtures.
void main() {
  final start = DateTime(2026, 4, 11);

  List<String> teams(int n) => [for (var i = 1; i <= n; i++) 't$i'];

  DrawPlan plan(
    TournamentType type,
    int n, {
    List<String> grounds = const ['G1', 'G2'],
  }) =>
      buildDraw(
        type: type,
        orderedTeamIds: teams(n),
        grounds: grounds,
        startDate: start,
      );

  group('knockout', () {
    test('generates every round, not just the first', () {
      final p = plan(TournamentType.knockout, 8);

      expect(p.roundCount, 3);
      expect(p.fixturesInRound(1), hasLength(4));
      expect(p.fixturesInRound(2), hasLength(2));
      expect(p.fixturesInRound(3), hasLength(1));
      expect(p.fixtures.last.roundLabel, 'Final');
      expect(p.fixturesInRound(2).first.roundLabel, 'Semi-Final');
      expect(p.fixturesInRound(1).first.roundLabel, 'Quarter-Final');
    });

    test('a knockout always resolves in exactly n-1 matches', () {
      for (final n in [2, 3, 4, 5, 6, 7, 8, 9, 11, 16, 17, 24, 32]) {
        expect(
          plan(TournamentType.knockout, n).fixtures.length,
          n - 1,
          reason: '$n teams must produce ${n - 1} fixtures',
        );
      }
    });

    test('round one pairs strongest against weakest', () {
      final r1 = plan(TournamentType.knockout, 8).fixturesInRound(1);
      expect(
        r1.map((f) => '${f.teamAId}v${f.teamBId}'),
        ['t1vt8', 't4vt5', 't2vt7', 't3vt6'],
      );
    });

    test('seeds 1 and 2 can only meet in the final', () {
      // Chalk result: every higher seed wins. Walk the bracket and check the
      // two top seeds never share a fixture before the last round.
      final p = plan(TournamentType.knockout, 8);
      final winner = <String, String>{};

      for (var round = 1; round <= p.roundCount; round++) {
        for (final f in p.fixturesInRound(round)) {
          final a = f.teamAId ?? winner[f.prevSlotAId]!;
          final b = f.teamBId ?? winner[f.prevSlotBId]!;
          if (round < p.roundCount) {
            expect({a, b}, isNot(equals({'t1', 't2'})));
          }
          // Lower number = better seed.
          final seedOf = (String t) => int.parse(t.substring(1));
          winner[f.slotId] = seedOf(a) < seedOf(b) ? a : b;
        }
      }

      final finalFixture = p.fixturesInRound(p.roundCount).single;
      final fa = winner[finalFixture.prevSlotAId]!;
      final fb = winner[finalFixture.prevSlotBId]!;
      expect({fa, fb}, {'t1', 't2'});
    });

    test('later rounds are unresolved and linked to their feeders', () {
      final p = plan(TournamentType.knockout, 8);
      final ids = p.fixtures.map((f) => f.slotId).toSet();

      for (final f in p.fixtures.where((f) => f.roundNumber > 1)) {
        expect(f.teamAId, isNull);
        expect(f.teamBId, isNull);
        expect(f.isResolved, isFalse);
        expect(ids, contains(f.prevSlotAId));
        expect(ids, contains(f.prevSlotBId));
      }
    });

    test('every fixture feeds exactly one later fixture, except the final', () {
      final p = plan(TournamentType.knockout, 8);
      final fed = <String>[];
      for (final f in p.fixtures) {
        if (f.prevSlotAId != null) fed.add(f.prevSlotAId!);
        if (f.prevSlotBId != null) fed.add(f.prevSlotBId!);
      }

      expect(fed.toSet(), hasLength(fed.length), reason: 'no slot feeds twice');
      final unfed =
          p.fixtures.map((f) => f.slotId).where((id) => !fed.contains(id));
      expect(unfed, [p.fixtures.last.slotId]);
    });

    test('an odd field gives byes to the top seeds and creates no half-match',
        () {
      final p = plan(TournamentType.knockout, 5);

      // 5 teams in an 8-bracket: three byes, one real tie in round one.
      expect(p.byes.map((b) => b.teamId), containsAll(['t1', 't2', 't3']));
      expect(p.fixturesInRound(1), hasLength(1));
      expect(p.fixturesInRound(1).single.isResolved, isTrue);

      // Round two carries the bye teams directly — never a null side with no
      // feeder, which would be a fixture that can never resolve.
      for (final f in p.fixtures) {
        expect(
          (f.teamAId != null) || (f.prevSlotAId != null),
          isTrue,
          reason: '${f.slotId} side A is neither a team nor a feeder',
        );
        expect(
          (f.teamBId != null) || (f.prevSlotBId != null),
          isTrue,
          reason: '${f.slotId} side B is neither a team nor a feeder',
        );
      }
    });

    test('a bye walks into the round-two slot it is recorded against', () {
      final p = plan(TournamentType.knockout, 5);
      final slots = p.fixtures.map((f) => f.slotId).toSet();
      for (final bye in p.byes) {
        expect(slots, contains(bye.intoSlotId));
        final into =
            p.fixtures.firstWhere((f) => f.slotId == bye.intoSlotId);
        expect([into.teamAId, into.teamBId], contains(bye.teamId));
      }
    });

    test('two teams is a single final', () {
      final p = plan(TournamentType.knockout, 2);
      expect(p.fixtures, hasLength(1));
      expect(p.fixtures.single.roundLabel, 'Final');
      expect(p.byes, isEmpty);
    });
  });

  group('round robin', () {
    test('everyone plays everyone exactly once', () {
      for (final n in [4, 5, 6, 7, 8]) {
        final p = plan(TournamentType.roundRobin, n);
        expect(p.fixtures.length, n * (n - 1) ~/ 2,
            reason: '$n teams must produce ${n * (n - 1) ~/ 2} fixtures');

        final pairs = p.fixtures
            .map((f) => ({f.teamAId, f.teamBId}).toList()..sort())
            .map((p) => p.join('-'))
            .toList();
        expect(pairs.toSet(), hasLength(pairs.length),
            reason: 'no pair may repeat');
      }
    });

    test('an even field plays n-1 rounds, an odd field n', () {
      expect(plan(TournamentType.roundRobin, 6).roundCount, 5);
      expect(plan(TournamentType.roundRobin, 5).roundCount, 5);
    });

    test('no team appears twice in the same round', () {
      final p = plan(TournamentType.roundRobin, 6);
      for (var r = 1; r <= p.roundCount; r++) {
        final seen = <String>[];
        for (final f in p.fixturesInRound(r)) {
          seen..add(f.teamAId!)..add(f.teamBId!);
        }
        expect(seen.toSet(), hasLength(seen.length),
            reason: 'round $r double-books a team');
      }
    });

    test('league uses the same generator as round robin', () {
      expect(
        plan(TournamentType.league, 6).fixtures.length,
        plan(TournamentType.roundRobin, 6).fixtures.length,
      );
    });

    test('every fixture is resolved — nothing to advance into', () {
      for (final f in plan(TournamentType.roundRobin, 6).fixtures) {
        expect(f.isResolved, isTrue);
        expect(f.prevSlotAId, isNull);
      }
    });
  });

  group('scheduling', () {
    test('never double-books a ground and time, even when a round overflows',
        () {
      // 12 first-round ties across 2 grounds x 3 slots = 6 per day, so round
      // one spans two days and round two must not start on the second of them.
      final p = plan(TournamentType.knockout, 24);
      final taken = p.fixtures
          .map((f) => '${f.scheduledStartTime.toIso8601String()}@${f.venue}')
          .toList();
      expect(taken.toSet(), hasLength(taken.length));
    });

    test('a round never starts before the previous round has finished', () {
      final p = plan(TournamentType.knockout, 24);
      for (var r = 2; r <= p.roundCount; r++) {
        final prevEnd = p
            .fixturesInRound(r - 1)
            .map((f) => f.scheduledStartTime)
            .reduce((a, b) => b.isAfter(a) ? b : a);
        final thisStart = p
            .fixturesInRound(r)
            .map((f) => f.scheduledStartTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        expect(thisStart.isAfter(prevEnd), isTrue,
            reason: 'round $r starts before round ${r - 1} is done');
      }
    });

    test('falls back to a single named ground when none are configured', () {
      final p = plan(TournamentType.knockout, 4, grounds: const []);
      expect(p.fixtures.map((f) => f.venue).toSet(), {'Ground 1'});
    });

    test('the first fixture is on the tournament start date', () {
      final p = plan(TournamentType.roundRobin, 4);
      final first = p.fixtures.first.scheduledStartTime;
      expect(first.year, 2026);
      expect(first.month, 4);
      expect(first.day, 11);
    });
  });

  group('guards', () {
    test('fewer than two teams produces nothing', () {
      expect(plan(TournamentType.knockout, 1).isEmpty, isTrue);
      expect(plan(TournamentType.knockout, 0).isEmpty, isTrue);
    });

    test('reserved types are refused rather than drawn wrongly', () {
      for (final t in [
        TournamentType.groupKnockout,
        TournamentType.doubleElimination,
      ]) {
        final p = plan(t, 8);
        expect(p.isEmpty, isTrue);
        expect(p.unsupported, isNotNull);
      }
    });
  });
}
