import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which ink a surface painted in an arbitrary colour has to draw with.
///
/// A team's `primary_color` is **data, not brand** — the owner picks it from a
/// 12-swatch palette that spans `#161107` (near-black) to `#F8EAC6` (pale
/// cream). White chrome on the pale two measures under 2:1, so the hero has to
/// flip its whole ink ramp rather than trust a single foreground colour.
enum CkSurfaceMode {
  /// Dark ground → white text, white-alpha fills. The common case.
  paper,

  /// Light ground → ink text, ink-alpha fills + hairlines.
  ink,
}

/// The crossover point on WCAG relative luminance.
///
/// White clears 3:1 against a ground up to L ≈ 0.30; ink `#29251E` clears it
/// from L ≈ 0.17 up. The overlap means 0.25 has margin on both sides, and it
/// is computed from the stored hex — no per-team configuration, and it holds
/// for any swatch added later. Of the 12 shipped swatches only amber
/// (`#E6AC3D`, L≈0.47) and cream (`#F8EAC6`, L≈0.83) flip.
const double kInkModeLuminanceThreshold = 0.25;

/// Picks the ink ramp for a surface painted [background].
CkSurfaceMode surfaceModeFor(Color background) =>
    background.computeLuminance() >= kInkModeLuminanceThreshold
        ? CkSurfaceMode.ink
        : CkSurfaceMode.paper;

extension CkSurfaceModeX on CkSurfaceMode {
  bool get isInk => this == CkSurfaceMode.ink;
  bool get isPaper => this == CkSurfaceMode.paper;
}

/// Darkens [color] until it can carry 13px text on paper.
///
/// Used for the monogram crest: the letters are drawn in the team's own
/// primary, but `#F8EAC6` on `#FBFAF6` is 1.05:1 — invisible. Clamping HSL
/// lightness to 0.32 turns each pale swatch into its status-ink partner
/// (`#E6AC3D` → ≈`#8A6E2E`) and leaves the ten dark swatches untouched.
Color darkenForPaper(Color color) {
  if (color.computeLuminance() < kInkModeLuminanceThreshold) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness(math.min(hsl.lightness, 0.32)).toColor();
}
