import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/ball.dart';

/// The coloured ball pill (the `ck-ball` variants from styles.css), shared by
/// the scoring console and the spectator view.
class BallPill extends StatelessWidget {
  const BallPill({
    super.key,
    required this.bg,
    required this.fg,
    required this.label,
    required this.size,
  });

  final Color bg;
  final Color fg;
  final String label;
  final double size;

  factory BallPill.fromBall(Ball b, {required double size}) {
    final (Color bg, Color fg, String label) = switch (b) {
      _ when b.isWicket => (CkColors.red, Colors.white, 'W'),
      _ when b.isSix => (CkColors.ink, CkColors.paper, '6'),
      _ when b.isFour => (CkColors.greenSoft, CkColors.green, '4'),
      _ when b.extraType == ExtraType.wide => (
          CkColors.cream,
          CkColors.ink2,
          b.totalRuns > 1 ? '${b.totalRuns}wd' : 'wd'
        ),
      _ when b.extraType == ExtraType.noBall => (
          CkColors.cream,
          CkColors.ink2,
          b.totalRuns > 1 ? '${b.totalRuns}nb' : 'nb'
        ),
      _ when b.runsScored == 0 => (CkColors.paper2, CkColors.muted, '•'),
      _ => (CkColors.surface, CkColors.ink, '${b.runsScored}'),
    };
    return BallPill(bg: bg, fg: fg, label: label, size: size);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(label,
          style: CkType.mono(
              fontSize: size * 0.42, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
