import '../entities/tournament.dart';
import 'draw_plan.dart';

/// Builds the complete draw for a tournament — every round, not just the
/// first.
///
/// Pure Dart, no I/O, deliberately the *only* implementation of pairing in the
/// codebase. The seeding preview and the Lock & Publish action both call it,
/// so the organiser cannot be shown one draw and publish another. Before this
/// existed there were two pairing routines that had already drifted: with an
/// odd field the preview named the top seed as the bye while the lock silently
/// benched the middle team.
///
/// What it generates per type:
///
///  * **knockout** — a full seeded bracket. Round one pairs strongest against
///    weakest; every later round is created as an *unresolved* fixture whose
///    sides are filled by the `match_advance_tournament_bracket` trigger as
///    results land. Without those rows the trigger has nothing to advance
///    into and a cup can never reach a final.
///  * **round_robin / league** — the circle method: every team plays every
///    other once, n(n−1)/2 fixtures across n−1 rounds (n rounds for an odd
///    field, where one team rests each round).
///  * **group_knockout / double_elimination** — reserved enum values with no
///    generator. Returns [DrawPlan.unsupported] rather than quietly producing
///    a bracket of the wrong shape.
///
/// Scheduling: fixtures fill every ground × slot combination on a day, then
/// roll to the next day. A new round always starts on a new day — a side
/// cannot play round two before round one has finished.
DrawPlan buildDraw({
  required TournamentType type,
  required List<String> orderedTeamIds,
  required List<String> grounds,
  required DateTime startDate,
  List<int> dayStartHours = const [9, 13, 18],
}) {
  if (orderedTeamIds.length < 2) return const DrawPlan();

  final venues = grounds.isEmpty ? const ['Ground 1'] : grounds;
  final hours = dayStartHours.isEmpty ? const [9] : dayStartHours;
  final scheduler = _Scheduler(
    startDate: DateTime(startDate.year, startDate.month, startDate.day),
    grounds: venues,
    hours: hours,
  );

  return switch (type) {
    TournamentType.knockout => _knockout(orderedTeamIds, scheduler),
    TournamentType.roundRobin ||
    TournamentType.league =>
      _roundRobin(orderedTeamIds, scheduler),
    TournamentType.groupKnockout => DrawPlan(unsupported: type.label),
    TournamentType.doubleElimination => DrawPlan(unsupported: type.label),
  };
}

// ─── Knockout ────────────────────────────────────────────────────────────────

DrawPlan _knockout(List<String> seeds, _Scheduler scheduler) {
  final bracketSize = _nextPowerOfTwo(seeds.length);
  final roundCount = _log2(bracketSize);

  // Standard bracket seeding: 1 meets 2 only in the final. Positions beyond
  // the field are byes, which is how a non-power-of-two entry list is handled
  // — the strongest seeds get them, the convention every cup uses. Because
  // `bracketSize` is the *next* power of two, more than half the positions
  // are always filled, so no pairing is empty on both sides.
  final positions = _seedOrder(bracketSize)
      .map((seed) => seed <= seeds.length ? seeds[seed - 1] : null)
      .toList();

  final fixtures = <DrawFixture>[];
  final byes = <DrawBye>[];

  // One entry per round-one bracket slot: either the fixture that will decide
  // it, or the team that walked through on a bye.
  var previous = <_Side>[];

  scheduler.startRound();
  var matchNumber = 0;

  for (var slot = 0; slot < bracketSize ~/ 2; slot++) {
    final a = positions[slot * 2];
    final b = positions[slot * 2 + 1];

    if (a == null || b == null) {
      // A bye produces no fixture. A match row with one side null and no
      // feeder is indistinguishable from an unresolved later-round tie and
      // would never resolve, so the team walks straight into round two.
      final through = a ?? b;
      previous.add(through == null ? const _Side.empty() : _Side.team(through));
      if (through != null && roundCount >= 2) {
        byes.add(
          DrawBye(
            teamId: through,
            roundNumber: 1,
            intoSlotId: _slotId(2, slot ~/ 2 + 1),
          ),
        );
      }
      continue;
    }

    matchNumber++;
    final id = _slotId(1, matchNumber);
    final at = scheduler.next();
    fixtures.add(
      DrawFixture(
        slotId: id,
        roundNumber: 1,
        matchNumber: matchNumber,
        roundLabel: _knockoutRoundLabel(1, roundCount),
        scheduledStartTime: at.time,
        venue: at.venue,
        teamAId: a,
        teamBId: b,
      ),
    );
    previous.add(_Side.feeder(id));
  }

  for (var round = 2; round <= roundCount; round++) {
    scheduler.startRound();
    final next = <_Side>[];
    for (var i = 0; i < previous.length; i += 2) {
      final number = i ~/ 2 + 1;
      final id = _slotId(round, number);
      final at = scheduler.next();
      final a = previous[i];
      final b = previous[i + 1];

      fixtures.add(
        DrawFixture(
          slotId: id,
          roundNumber: round,
          matchNumber: number,
          roundLabel: _knockoutRoundLabel(round, roundCount),
          scheduledStartTime: at.time,
          venue: at.venue,
          teamAId: a.teamId,
          teamBId: b.teamId,
          prevSlotAId: a.feederSlotId,
          prevSlotBId: b.feederSlotId,
        ),
      );
      next.add(_Side.feeder(id));
    }
    previous = next;
  }

  return DrawPlan(
    fixtures: fixtures,
    byes: byes,
    roundCount: roundCount,
  );
}

/// Seed positions for a bracket of [size], such that seeds 1 and 2 can only
/// meet in the final. `[1, 8, 4, 5, 2, 7, 3, 6]` for eight.
List<int> _seedOrder(int size) {
  var order = <int>[1];
  while (order.length < size) {
    final n = order.length * 2;
    final next = <int>[];
    for (final s in order) {
      next
        ..add(s)
        ..add(n + 1 - s);
    }
    order = next;
  }
  return order;
}

String _knockoutRoundLabel(int round, int roundCount) {
  final fromEnd = roundCount - round;
  return switch (fromEnd) {
    0 => 'Final',
    1 => 'Semi-Final',
    2 => 'Quarter-Final',
    _ => 'Round $round',
  };
}

// ─── Round robin / league ────────────────────────────────────────────────────

DrawPlan _roundRobin(List<String> teams, _Scheduler scheduler) {
  // Circle method. An odd field gets a phantom entry so one real team rests
  // each round rather than being dropped from the tournament.
  final rotation = <String?>[...teams];
  if (rotation.length.isOdd) rotation.add(null);

  final n = rotation.length;
  final roundCount = n - 1;
  final fixtures = <DrawFixture>[];

  for (var round = 1; round <= roundCount; round++) {
    scheduler.startRound();
    var number = 0;
    for (var i = 0; i < n ~/ 2; i++) {
      final a = rotation[i];
      final b = rotation[n - 1 - i];
      if (a == null || b == null) continue; // the resting team

      number++;
      final at = scheduler.next();
      fixtures.add(
        DrawFixture(
          slotId: _slotId(round, number),
          roundNumber: round,
          matchNumber: number,
          roundLabel: 'Round $round',
          scheduledStartTime: at.time,
          venue: at.venue,
          teamAId: a,
          teamBId: b,
        ),
      );
    }

    // Rotate everything but the first entry.
    final last = rotation.removeLast();
    rotation.insert(1, last);
  }

  return DrawPlan(fixtures: fixtures, roundCount: roundCount);
}

// ─── Scheduling ──────────────────────────────────────────────────────────────

/// Walks ground × slot combinations, rolling to the next day when a day is
/// full. [startRound] forces a fresh day, because a side cannot play the next
/// round before the previous one has been played.
class _Scheduler {
  _Scheduler({
    required this.startDate,
    required this.grounds,
    required this.hours,
  });

  final DateTime startDate;
  final List<String> grounds;
  final List<int> hours;

  int _dayOffset = 0;
  int _cursor = 0;

  /// The first day no fixture has been placed on. A round that overflows its
  /// first day must not hand the next round a day it is still using — that is
  /// how the old scheduler double-booked ground 1 at 09:00.
  int _nextFreeDay = 0;

  void startRound() {
    _dayOffset = _nextFreeDay;
    _cursor = 0;
  }

  ({DateTime time, String venue}) next() {
    final perDay = grounds.length * hours.length;
    final day = _dayOffset + _cursor ~/ perDay;
    final within = _cursor % perDay;
    _cursor++;
    if (day + 1 > _nextFreeDay) _nextFreeDay = day + 1;

    final date = startDate.add(Duration(days: day));
    return (
      time: DateTime(
        date.year,
        date.month,
        date.day,
        hours[within ~/ grounds.length],
      ),
      venue: grounds[within % grounds.length],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Either a known team or the slot whose winner arrives later.
class _Side {
  const _Side.team(String this.teamId) : feederSlotId = null;
  const _Side.feeder(String this.feederSlotId) : teamId = null;

  /// Neither — unreachable with standard seeding, kept so the bracket keeps
  /// its slot count if the seeding rule is ever changed.
  const _Side.empty()
      : teamId = null,
        feederSlotId = null;

  final String? teamId;
  final String? feederSlotId;
}

String _slotId(int round, int match) => 'r${round}m$match';

int _nextPowerOfTwo(int n) {
  var p = 1;
  while (p < n) {
    p *= 2;
  }
  return p;
}

int _log2(int n) {
  var v = n;
  var r = 0;
  while (v > 1) {
    v ~/= 2;
    r++;
  }
  return r;
}
