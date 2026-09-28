import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_leader.dart';

TournamentLeader bowler({
  required String key,
  required String name,
  int wickets = 0,
  int bestW = 0,
  int bestR = 0,
}) =>
    TournamentLeader(
      playerKey: key,
      displayName: name,
      isUnclaimed: false,
      primaryValue: wickets,
      rateValue: 6,
      bestWickets: bestW,
      bestRuns: bestR,
    );

void main() {
  group('bestBowlingFigures (artboard 15)', () {
    test('picks the biggest haul, then the fewest runs for it', () {
      const boards = TournamentLeaderboards(bowling: []);
      expect(boards.bestBowlingFigures, isNull);

      final many = TournamentLeaderboards(
        bowling: [
          // Most wickets overall, but a worse single haul.
          bowler(key: 'a', name: 'A', wickets: 14, bestW: 4, bestR: 20),
          bowler(key: 'b', name: 'B', wickets: 9, bestW: 5, bestR: 14),
          bowler(key: 'c', name: 'C', wickets: 8, bestW: 5, bestR: 22),
        ],
      );

      expect(many.bestBowlingFigures?.displayName, 'B');
      expect(many.bestBowlingFigures?.bestFigures, '5/14');
    });

    test('is null when nobody has taken a wicket', () {
      final none = TournamentLeaderboards(
        bowling: [bowler(key: 'a', name: 'A', wickets: 0)],
      );
      expect(none.bestBowlingFigures, isNull);
    });

    test('does not reorder the board it was given', () {
      final board = [
        bowler(key: 'a', name: 'A', wickets: 14, bestW: 4, bestR: 20),
        bowler(key: 'b', name: 'B', wickets: 9, bestW: 5, bestR: 14),
      ];
      final boards = TournamentLeaderboards(bowling: board);
      boards.bestBowlingFigures;
      // The purple cap is still whoever has the most wickets overall.
      expect(boards.purpleCap?.displayName, 'A');
      expect(board.first.displayName, 'A');
    });
  });

  group('caps', () {
    test('the cap is the head of each board', () {
      final boards = TournamentLeaderboards(
        batting: const [
          TournamentLeader(
            playerKey: 'u:1',
            displayName: 'Babar Azam',
            isUnclaimed: false,
            primaryValue: 342,
            rateValue: 154.2,
          ),
        ],
        bowling: [bowler(key: 'u:2', name: 'Shaheen', wickets: 14)],
      );

      expect(boards.orangeCap?.primaryValue, 342);
      expect(boards.purpleCap?.primaryValue, 14);
      expect(boards.isEmpty, isFalse);
    });

    test('an empty cup has no caps', () {
      const boards = TournamentLeaderboards();
      expect(boards.orangeCap, isNull);
      expect(boards.purpleCap, isNull);
      expect(boards.isEmpty, isTrue);
    });
  });

  test('monogram falls back to the first two letters of a single name', () {
    final one = bowler(key: 'u:1', name: 'Shaheen');
    final two = bowler(key: 'u:2', name: 'Babar Azam');
    expect(one.monogram, 'SH');
    expect(two.monogram, 'BA');
  });
}
