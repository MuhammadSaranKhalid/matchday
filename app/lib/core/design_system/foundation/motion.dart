import 'package:flutter/animation.dart';

/// Standardized motion and animation curves and durations.
abstract final class Motion {
  static const durationFast = Duration(milliseconds: 150);
  static const durationStandard = Duration(milliseconds: 250);
  static const durationSlow = Duration(milliseconds: 350);

  static const curveFast = Curves.easeOutCubic;
  static const curveStandard = Curves.easeInOutCubic;
  static const curveEmphasized = Curves.easeInOutCubicEmphasized;
}
