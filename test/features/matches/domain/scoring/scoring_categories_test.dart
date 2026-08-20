// Coverage classification, and the contract that keeps it meaningful.
//
// The S3 soak exits on "every vector category observed in production with no
// parity alarm", which is a set subtraction: spec categories minus observed
// categories. That subtraction is only meaningful while both sides use the
// same vocabulary — so the vocabulary itself is asserted against the vector
// file here, not assumed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_categories.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_engine.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_types.dart';

const _format = EngineFormat();
const _hundred = EngineFormat(ballsPerOver: 5, endChangeBalls: 10);

Set<String> _categorise(
  EngineBallInput input, {
  EngineFormat format = _format,
  EngineInningsState state = const EngineInningsState(
    strikerId: 'S',
    nonStrikerId: 'N',
    bowlerId: 'B',
  ),
  EngineContext ctx = const EngineContext(),
}) =>
    scoringCategories(
      input: input,
      format: format,
      result: applyBall(state, format, input, ctx),
    );

void main() {
  group('the vocabulary matches the spec', () {
    test('every category in vectors.json is declared here', () {
      // If the vectors grow a category this set does not know about, the
      // coverage report would silently under-count — it would report full
      // coverage while a whole rule area had never been exercised.
      final file = File('supabase/functions/_shared/scoring/vectors.json');
      final suite = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final inSpec = (suite['vectors'] as List)
          .map((v) => (v as Map<String, dynamic>)['category'] as String)
          .toSet();

      expect(
        inSpec.difference(vectorCategories),
        isEmpty,
        reason: 'vectors.json has categories scoring_categories.dart lacks',
      );
    });

    test('every declared category is reachable from the spec', () {
      // The other direction: a category nobody can ever observe would block
      // the soak forever.
      final file = File('supabase/functions/_shared/scoring/vectors.json');
      final suite = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final inSpec = (suite['vectors'] as List)
          .map((v) => (v as Map<String, dynamic>)['category'] as String)
          .toSet();

      expect(vectorCategories.difference(inSpec), isEmpty);
    });
  });

  group('classification', () {
    test('a dot ball is just legal', () {
      expect(_categorise(const EngineBallInput()), {'legal'});
    });

    test('each ball kind reports itself', () {
      expect(
        _categorise(const EngineBallInput(
          isLegalDelivery: false,
          ballKind: BallKind.wide,
          extras: 1,
        )),
        contains('wide'),
      );
      expect(
        _categorise(const EngineBallInput(ballKind: BallKind.bye, extras: 1)),
        contains('bye'),
      );
      expect(
        _categorise(
            const EngineBallInput(ballKind: BallKind.legBye, extras: 2)),
        contains('leg_bye'),
      );
    });

    test('a delivery can exercise several rules at once', () {
      // A wicket that completes the over AND ends the innings is all three.
      // Every one of them genuinely executed, so every one counts.
      final cats = _categorise(
        const EngineBallInput(isWicket: true, wicketType: WicketType.bowled),
        state: const EngineInningsState(
          strikerId: 'S',
          nonStrikerId: 'N',
          bowlerId: 'B',
          legalBallCount: 5,
          totalWickets: 9,
        ),
      );
      expect(cats, containsAll(<String>{'legal', 'wicket', 'over_end', 'termination'}));
    });

    test('a rejection is categorised by what rejected it', () {
      expect(
        _categorise(
          const EngineBallInput(isWicket: true, wicketType: WicketType.bowled),
          ctx: const EngineContext(prevNonWideKind: BallKind.noBall),
        ),
        contains('free_hit'),
      );
      expect(
        _categorise(
          const EngineBallInput(),
          ctx: const EngineContext(bowlerLegalBalls: 24),
        ),
        contains('bowler_cap'),
      );
      expect(
        _categorise(const EngineBallInput(isWicket: true)),
        contains('validation'),
      );
    });

    test('a free hit that is scored off still counts as free_hit', () {
      expect(
        _categorise(
          const EngineBallInput(runsScored: 4),
          ctx: const EngineContext(prevNonWideKind: BallKind.noBall),
        ),
        contains('free_hit'),
      );
    });

    test('the hundred is detected structurally, not by name', () {
      // What makes it "the hundred" is that ends change on a different
      // cadence to sets — not what the format is called.
      expect(_categorise(const EngineBallInput(), format: _hundred),
          contains('hundred'));
      expect(_categorise(const EngineBallInput()), isNot(contains('hundred')));
    });
  });
}
