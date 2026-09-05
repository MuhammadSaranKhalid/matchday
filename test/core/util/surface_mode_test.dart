import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/util/surface_mode.dart';

/// The twelve swatches a team owner can pick from (`kTeamCreatePalette`).
/// The hero's whole ink ramp hangs on which of these flip, so they are
/// pinned here rather than left to a visual check.
const _palette = <String, int>{
  'dark green': 0xFF1E5A2C,
  'deep red': 0xFF8C2218,
  'dark blue': 0xFF1F2D4F,
  'brown': 0xFF3F3527,
  'burnt orange': 0xFF7B4413,
  'purple': 0xFF5E2A6B,
  'teal': 0xFF1F6E6F,
  'brick red': 0xFFA22B1E,
  'ink': 0xFF161107,
  'bright red': 0xFFE24A3F,
  'amber': 0xFFE6AC3D,
  'cream': 0xFFF8EAC6,
};

void main() {
  group('surfaceModeFor', () {
    test('only amber and cream flip the hero to ink mode', () {
      final flipped = <String>[
        for (final e in _palette.entries)
          if (surfaceModeFor(Color(e.value)).isInk) e.key,
      ];
      expect(flipped, unorderedEquals(<String>['amber', 'cream']));
    });

    test('bright red stays in paper mode — it is close, but clears white', () {
      // L≈0.21 against the 0.25 threshold. The nearest swatch to the
      // crossover, so it is the one worth pinning.
      const brightRed = Color(0xFFE24A3F);
      expect(brightRed.computeLuminance(), lessThan(kInkModeLuminanceThreshold));
      expect(surfaceModeFor(brightRed).isPaper, isTrue);
    });

    test('the extremes resolve the obvious way', () {
      expect(surfaceModeFor(const Color(0xFF000000)).isPaper, isTrue);
      expect(surfaceModeFor(const Color(0xFFFFFFFF)).isInk, isTrue);
    });
  });

  group('darkenForPaper', () {
    test('leaves an already-dark primary untouched', () {
      const darkBlue = Color(0xFF1F2D4F);
      expect(darkenForPaper(darkBlue), equals(darkBlue));
    });

    test('darkens a pale primary enough to read on paper', () {
      // Cream monogram letters on a paper disc measure 1.05:1 raw — the
      // failure case the crest exists to avoid.
      const cream = Color(0xFFF8EAC6);
      final darkened = darkenForPaper(cream);
      expect(darkened, isNot(equals(cream)));

      const paper = Color(0xFFFBFAF6);
      expect(_contrast(darkened, paper), greaterThan(4.5));
    });

    test('amber lands on its status-ink partner', () {
      // The design pairs #E6AC3D with amberInk #8A6E2E; the HSL clamp is the
      // general rule that produces it, so check the neighbourhood, not the
      // exact byte.
      final darkened = darkenForPaper(const Color(0xFFE6AC3D));
      expect(_contrast(darkened, const Color(0xFFFBFAF6)), greaterThan(4.5));
    });
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
