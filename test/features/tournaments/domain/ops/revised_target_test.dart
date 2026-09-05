import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/ops/revised_target.dart';

void main() {
  group('quotaFor', () {
    test('is a fifth of the innings, rounded up', () {
      // The three the design states outright: 20 → 4 (27m "originally"),
      // 15 → 3 (27m revised), 14 → 3 (28b "Max 3 overs each").
      expect(RevisedTargetCalculator.quotaFor(20), 4);
      expect(RevisedTargetCalculator.quotaFor(15), 3);
      expect(RevisedTargetCalculator.quotaFor(14), 3);
      expect(RevisedTargetCalculator.quotaFor(50), 10);
      expect(RevisedTargetCalculator.quotaFor(5), 1);
    });

    test('never returns zero for a playable innings', () {
      for (var overs = 1; overs <= 50; overs++) {
        expect(RevisedTargetCalculator.quotaFor(overs), greaterThanOrEqualTo(1));
      }
    });

    test('five bowlers can always cover the innings', () {
      for (var overs = 1; overs <= 50; overs++) {
        final quota = RevisedTargetCalculator.quotaFor(overs);
        expect(quota * 5, greaterThanOrEqualTo(overs));
      }
    });
  });

  group('runRateTarget', () {
    test('scales the first innings and adds one to win', () {
      // 148 in 20 → 14 overs: 103.6 rounds up to 104, +1 = 105.
      expect(
        RevisedTargetCalculator.runRateTarget(
          firstInningsRuns: 148,
          originalOvers: 20,
          revisedOvers: 14,
        ),
        105,
      );
    });

    test('an uninterrupted innings needs one more than the score', () {
      expect(
        RevisedTargetCalculator.runRateTarget(
          firstInningsRuns: 148,
          originalOvers: 20,
          revisedOvers: 20,
        ),
        149, // 28b: "target was 149"
      );
    });

    test('is monotonic in the revised length', () {
      var previous = 0;
      for (var overs = 5; overs <= 20; overs++) {
        final t = RevisedTargetCalculator.runRateTarget(
          firstInningsRuns: 148,
          originalOvers: 20,
          revisedOvers: overs,
        );
        expect(t, greaterThanOrEqualTo(previous));
        previous = t;
      }
    });
  });

  group('preview — artboard 28b', () {
    // "1st innings 148/4 in 20 ov — target was 149. Panthers are 96/3 after
    // 11.4. New match length 14 overs. Revised target 112 (DLS)."
    const context = StoppageContext(
      originalOvers: 20,
      originalQuota: 4,
      inningsNumber: 2,
      firstInningsRuns: 148,
      chasingRuns: 96,
      chasingWickets: 3,
      chasingLegalBalls: 70, // 11.4 overs
    );

    test('reproduces the balls left, par and quota the design prints', () {
      final p = RevisedTargetCalculator.preview(
        context: context,
        revisedOvers: 14,
        method: TargetMethod.dls,
        enteredTarget: 112,
      );

      expect(p.isValid, isTrue);
      expect(p.target, 112);
      expect(p.ballsRemaining, 14); // 84 - 70, the design's "14 balls left"
      expect(p.bowlerQuota, 3); // "Max 3 overs each"
      expect(p.parScore, 93); // "Par at 11.4 · 93"
      expect(p.parDifference, 3); // "Panthers +3"
      expect(p.runsRequired, 16);
    });

    test('required run rate follows from runs and balls left', () {
      final p = RevisedTargetCalculator.preview(
        context: context,
        revisedOvers: 14,
        method: TargetMethod.dls,
        enteredTarget: 112,
      );
      expect(p.requiredRunRate, closeTo(16 * 6 / 14, 0.001));
    });

    test('run-rate method derives its own target and ignores the entry', () {
      final p = RevisedTargetCalculator.preview(
        context: context,
        revisedOvers: 14,
        method: TargetMethod.runRate,
        enteredTarget: 999,
      );
      expect(p.target, 105);
    });

    test('DLS without an entered figure is not applicable', () {
      final p = RevisedTargetCalculator.preview(
        context: context,
        revisedOvers: 14,
        method: TargetMethod.dls,
      );
      expect(p.isValid, isFalse);
      expect(p.invalidReason, contains('official DLS table'));
    });
  });

  group('preview — guards', () {
    const chase = StoppageContext(
      originalOvers: 20,
      originalQuota: 4,
      inningsNumber: 2,
      firstInningsRuns: 148,
      chasingRuns: 96,
      chasingLegalBalls: 70,
    );

    test('rejects fewer than five overs a side', () {
      final p = RevisedTargetCalculator.preview(
        context: chase,
        revisedOvers: 4,
        method: TargetMethod.runRate,
      );
      expect(p.isValid, isFalse);
      expect(p.invalidReason, contains('5 overs'));
    });

    test('refuses to extend the match', () {
      final p = RevisedTargetCalculator.preview(
        context: chase,
        revisedOvers: 25,
        method: TargetMethod.runRate,
      );
      expect(p.isValid, isFalse);
      expect(p.invalidReason, contains('reduced'));
    });

    test('refuses a length the chase has already passed', () {
      // 11.4 bowled; 11 overs would end the innings retroactively.
      final p = RevisedTargetCalculator.preview(
        context: chase,
        revisedOvers: 11,
        method: TargetMethod.runRate,
      );
      expect(p.isValid, isFalse);
      expect(p.invalidReason, contains('already reached'));
      expect(RevisedTargetCalculator.minimumSelectableOvers(chase), 12);
    });

    test('balls remaining never goes negative', () {
      for (var overs = 5; overs <= 20; overs++) {
        final p = RevisedTargetCalculator.preview(
          context: chase,
          revisedOvers: overs,
          method: TargetMethod.runRate,
        );
        expect(p.ballsRemaining, greaterThanOrEqualTo(0));
      }
    });

    test('runs required never goes negative once the target is passed', () {
      const won = StoppageContext(
        originalOvers: 20,
        originalQuota: 4,
        inningsNumber: 2,
        firstInningsRuns: 100,
        chasingRuns: 140,
        chasingLegalBalls: 70,
      );
      final p = RevisedTargetCalculator.preview(
        context: won,
        revisedOvers: 14,
        method: TargetMethod.runRate,
      );
      expect(p.runsRequired, 0);
      expect(p.requiredRunRate, 0);
    });
  });

  group('preview — first-innings stoppage (artboard 27m)', () {
    // Stopped at 12.4 in the FIRST innings: there is nothing to chase yet, so
    // the sheet offers the overs reduction only.
    const first = StoppageContext(
      originalOvers: 20,
      originalQuota: 4,
      inningsNumber: 1,
      chasingLegalBalls: 76,
    );

    test('has no target, but still reduces the quota', () {
      final p = RevisedTargetCalculator.preview(
        context: first,
        revisedOvers: 15,
        method: TargetMethod.runRate,
      );
      expect(p.isValid, isTrue);
      expect(p.target, isNull);
      expect(p.runsRequired, isNull);
      expect(p.parScore, isNull);
      expect(p.bowlerQuota, 3); // 27m: "4 → 3"
      expect(p.ballsRemaining, 90);
    });

    test('minimum selectable length is the five-over floor', () {
      expect(RevisedTargetCalculator.minimumSelectableOvers(first), 5);
    });
  });
}
