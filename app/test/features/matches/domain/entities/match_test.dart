import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

void main() {
  test('MatchStatus.isActive covers upcoming, in-play, completed + legacy',
      () {
    const active = {
      // Upcoming
      MatchStatus.scheduled,
      MatchStatus.toss,
      MatchStatus.rescheduled,
      // In-play
      MatchStatus.live,
      MatchStatus.inningsBreak,
      MatchStatus.superOver,
      // Recently concluded
      MatchStatus.completed,
      // Legacy (kept reachable so older clients/teams-list keep working)
      MatchStatus.pending,
      MatchStatus.accepted,
    };
    for (final s in MatchStatus.values) {
      expect(s.isActive, active.contains(s), reason: '${s.name}.isActive');
    }
  });

  test('MatchStatus partitions cleanly across upcoming/live/past', () {
    // Each status is in at most one bucket (live is in-play but not past).
    for (final s in MatchStatus.values) {
      final inBuckets =
          [s.isUpcoming, s.isLive, s.isPast].where((b) => b).length;
      expect(inBuckets, lessThanOrEqualTo(1),
          reason: '${s.name} is in multiple state buckets');
    }
  });

  test('Match.isActive delegates to its status', () {
    Match build(MatchStatus status) => Match(
          id: const MatchId('m1'),
          teamAId: const TeamId('a'),
          teamBId: const TeamId('b'),
          format: const MatchFormat(
            oversPerInnings: 20,
            playersPerTeam: 11,
            ballType: MatchBallType.tape,
            maxOversPerBowler: 4,
          ),
          status: status,
          createdBy: 'u1',
          createdAt: DateTime(2026),
        );

    expect(build(MatchStatus.scheduled).isActive, isTrue);
    expect(build(MatchStatus.live).isActive, isTrue);
    expect(build(MatchStatus.completed).isActive, isTrue);
    expect(build(MatchStatus.abandoned).isActive, isFalse);
    expect(build(MatchStatus.walkover).isActive, isFalse);
  });

  group('MatchType', () {
    test('maps every deployed wire value', () {
      expect(MatchType.fromWire('tournament'), MatchType.tournament);
      expect(MatchType.fromWire('friendly'), MatchType.friendly);
      expect(MatchType.fromWire('practice'), MatchType.practice);
    });

    test('falls back to friendly on unknown or missing', () {
      // The scoring top bar used to hardcode "FRIENDLY"; the label is now
      // driven by this, so an unmapped value must not blank the header.
      expect(MatchType.fromWire(null), MatchType.friendly);
      expect(MatchType.fromWire('exhibition'), MatchType.friendly);
    });

    test('labels are the uppercase display forms the top bar renders', () {
      expect(MatchType.tournament.label, 'TOURNAMENT');
      expect(MatchType.friendly.label, 'FRIENDLY');
      expect(MatchType.practice.label, 'PRACTICE');
    });
  });
}
