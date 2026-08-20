// The Dart half of the engine parity contract.
//
// This suite loads the SAME file the Deno suite loads —
// `supabase/functions/_shared/scoring/vectors.json` — and asserts the same
// expectations. That file is the specification; these two runners are the only
// things keeping the client engine and the server engine from drifting apart.
//
// If you are changing a scoring rule: change the vectors first, watch this fail
// alongside `deno test`, then make both pass.
//
// Run the other half with:
//   docker run --rm -v "$PWD":/app -w /app denoland/deno:latest \
//     test --allow-read --allow-net supabase/functions/_shared/scoring/engine.test.ts
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_engine.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_types.dart';

const _vectorPath = 'supabase/functions/_shared/scoring/vectors.json';

Map<String, dynamic> _merge(Map<String, dynamic> base, Object? override) => {
      ...base,
      ...?(override as Map<String, dynamic>?),
    };

EngineInningsState _state(Map<String, dynamic> j) => EngineInningsState(
      strikerId: j['strikerId'] as String?,
      nonStrikerId: j['nonStrikerId'] as String?,
      bowlerId: j['bowlerId'] as String?,
      legalBallCount: j['legalBallCount'] as int,
      totalRuns: j['totalRuns'] as int,
      totalWickets: j['totalWickets'] as int,
      totalExtras: j['totalExtras'] as int,
      isAllOut: j['isAllOut'] as bool,
      isDeclared: j['isDeclared'] as bool,
      target: j['target'] as int?,
      version: j['version'] as int,
    );

EngineFormat _format(Map<String, dynamic> j) => EngineFormat(
      oversPerInnings: j['oversPerInnings'] as int,
      playersPerTeam: j['playersPerTeam'] as int,
      ballsPerOver: j['ballsPerOver'] as int,
      endChangeBalls: j['endChangeBalls'] as int?,
      maxOversPerBowler: j['maxOversPerBowler'] as int,
      inningsPerSide: j['inningsPerSide'] as int,
      ballType: j['ballType'] as String,
      wicketsToAllOut: j['wicketsToAllOut'] as int?,
    );

EngineBallInput _input(Map<String, dynamic> j) => EngineBallInput(
      isLegalDelivery: j['isLegalDelivery'] as bool,
      ballKind: BallKind.fromWire(j['ballKind'] as String?),
      runsScored: j['runsScored'] as int,
      extras: j['extras'] as int,
      isWicket: j['isWicket'] as bool,
      wicketType: WicketType.fromWire(j['wicketType'] as String?),
      batsmanId: j['batsmanId'] as String?,
      nonStrikerId: j['nonStrikerId'] as String?,
      bowlerId: j['bowlerId'] as String?,
      fielderId: j['fielderId'] as String?,
      commentary: j['commentary'] as String?,
    );

EngineContext _ctx(Map<String, dynamic> j) => EngineContext(
      prevNonWideKind: j['prevNonWideKind'] == null
          ? null
          : BallKind.fromWire(j['prevNonWideKind'] as String),
      bowlerLegalBalls: (j['bowlerLegalBalls'] as int?) ?? 0,
    );

/// Flatten the engine's output to the same key names the vectors use, so the
/// comparison is against the spec's vocabulary rather than Dart's field names.
Map<String, Object?> _ballMap(ComputedBall b) => {
      'overNumber': b.overNumber,
      'ballInOver': b.ballInOver,
      'isFreeHit': b.isFreeHit,
      'isLegalDelivery': b.isLegalDelivery,
      'ballKind': b.ballKind.wire,
      'runsScored': b.runsScored,
      'extras': b.extras,
      'isWicket': b.isWicket,
      'wicketType': b.wicketType?.wire,
      'batsmanId': b.batsmanId,
      'nonStrikerId': b.nonStrikerId,
      'bowlerId': b.bowlerId,
      'fielderId': b.fielderId,
      'commentary': b.commentary,
    };

Map<String, Object?> _stateMap(NewInningsState s) => {
      'legalBallCount': s.legalBallCount,
      'totalRuns': s.totalRuns,
      'totalWickets': s.totalWickets,
      'totalExtras': s.totalExtras,
      'strikerId': s.strikerId,
      'nonStrikerId': s.nonStrikerId,
      'bowlerId': s.bowlerId,
    };

Map<String, Object?> _eventsMap(InningsEvents e) => {
      'overEnded': e.overEnded,
      'allOut': e.allOut,
      'oversComplete': e.oversComplete,
      'targetReached': e.targetReached,
      'inningsEnded': e.inningsEnded,
      'inningsEndReason': e.inningsEndReason?.wire,
    };

/// `expect` is a PARTIAL match — assert only the keys a vector names.
///
/// This mirrors the Deno runner exactly. If the two runners disagree about
/// what "expected" means, the two suites are not running the same spec even
/// though they read the same file.
void _assertSubset(
  Map<String, Object?> actual,
  Map<String, dynamic> expected,
  String where,
) {
  for (final entry in expected.entries) {
    expect(
      actual[entry.key],
      entry.value,
      reason: '$where.${entry.key}',
    );
  }
}

void main() {
  final file = File(_vectorPath);
  if (!file.existsSync()) {
    // A missing fixture must fail loudly. Silently skipping would leave the
    // parity contract unenforced while the suite reported green.
    test('vector file exists', () {
      fail('$_vectorPath not found — run from the package root');
    });
    return;
  }

  final suite = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final defaults = suite['defaults'] as Map<String, dynamic>;
  final vectors = (suite['vectors'] as List).cast<Map<String, dynamic>>();

  group('golden vectors', () {
    for (final v in vectors) {
      final name = v['name'] as String;
      final category = v['category'] as String;

      test('[$category] $name', () {
        final result = applyBall(
          _state(_merge(defaults['state'] as Map<String, dynamic>, v['state'])),
          _format(
              _merge(defaults['format'] as Map<String, dynamic>, v['format'])),
          _input(_merge(defaults['input'] as Map<String, dynamic>, v['input'])),
          _ctx(_merge(defaults['ctx'] as Map<String, dynamic>, v['ctx'])),
        );

        final expected = v['expect'] as Map<String, dynamic>;
        expect(
          result.ok,
          expected['ok'],
          reason: 'ok — ${result.error?.code ?? ''} ${result.error?.message ?? ''}',
        );

        if (expected['ok'] != true) {
          expect(result.error?.code, expected['error'], reason: 'error.code');
          return;
        }

        final ball = expected['ball'] as Map<String, dynamic>?;
        if (ball != null) _assertSubset(_ballMap(result.ball!), ball, 'ball');

        final newState = expected['newState'] as Map<String, dynamic>?;
        if (newState != null) {
          _assertSubset(_stateMap(result.newState!), newState, 'newState');
        }

        final events = expected['events'] as Map<String, dynamic>?;
        if (events != null) {
          _assertSubset(_eventsMap(result.events!), events, 'events');
        }
      });
    }
  });

  group('meta', () {
    test('the vector file is populated', () {
      // A fixture that lost its contents would turn this whole suite green
      // while asserting nothing at all.
      expect(vectors.length, greaterThanOrEqualTo(30));
    });

    test('vector names are unique', () {
      final names = vectors.map((v) => v['name'] as String).toList();
      expect(names.toSet().length, names.length, reason: 'duplicate name');
    });
  });
}
