import 'package:flutter_test/flutter_test.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';

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
}
