import 'package:flutter_test/flutter_test.dart';
import 'package:novex_clean_arch/features/matches/domain/entities/match.dart';
import 'package:novex_clean_arch/features/teams/domain/entities/team.dart';

void main() {
  test('MatchStatus.isActive is true only for open/in-play/recent statuses', () {
    const active = {
      MatchStatus.pending,
      MatchStatus.accepted,
      MatchStatus.live,
      MatchStatus.completed,
    };
    for (final s in MatchStatus.values) {
      expect(s.isActive, active.contains(s), reason: '${s.name}.isActive');
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

    expect(build(MatchStatus.pending).isActive, isTrue);
    expect(build(MatchStatus.accepted).isActive, isTrue);
    expect(build(MatchStatus.live).isActive, isTrue);
    expect(build(MatchStatus.completed).isActive, isTrue);
    expect(build(MatchStatus.declined).isActive, isFalse);
    expect(build(MatchStatus.cancelled).isActive, isFalse);
  });
}
