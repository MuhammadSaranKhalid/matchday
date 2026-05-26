import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'crest_palette.dart';

/// Empty-state card — dashed border, faded crest trio (LL · MK · GG),
/// headline + body + two buttons (Create / Find). Shown when the user has
/// no teams and no following relationships.
class MyTeamsEmptyState extends StatelessWidget {
  const MyTeamsEmptyState({
    super.key,
    this.subtitle,
    this.onCreate,
    this.onFind,
  });

  /// Body copy override.
  final String? subtitle;
  final VoidCallback? onCreate;
  final VoidCallback? onFind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: CkColors.line,
          radius: 16,
          strokeWidth: 1.2,
          dashLength: 5,
          dashGap: 4,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _FadedCrestTrio(),
              const SizedBox(height: 12),
              Text(
                'No teams yet',
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  subtitle ??
                      'Start your mohalla side, claim your spot on a team, or follow the clubs you watch every Sunday.',
                  textAlign: TextAlign.center,
                  style: CkType.body(
                    fontSize: 13,
                    color: CkColors.ink2,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _EmptyBtn(
                      label: 'Create a team',
                      primary: true,
                      onTap: onCreate ?? () {},
                    ),
                  ),
                  // "Find teams near you" intentionally hidden — discovery
                  // backend isn't wired yet. Restore when ready.
                  // const SizedBox(width: 8),
                  // Expanded(
                  //   child: _EmptyBtn(
                  //     label: 'Find teams near you',
                  //     primary: false,
                  //     onTap: onFind ?? () {},
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadedCrestTrio extends StatelessWidget {
  const _FadedCrestTrio();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DimCrest(crest: MyTeamsCrests.ll),
        _DimCrest(crest: MyTeamsCrests.mk),
        _DimCrest(crest: MyTeamsCrests.gg),
      ],
    );
  }
}

class _DimCrest extends StatelessWidget {
  const _DimCrest({required this.crest});
  final CrestStyle crest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CkColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        crest.mono,
        style: CkType.display(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

class _EmptyBtn extends StatelessWidget {
  const _EmptyBtn({
    required this.label,
    required this.primary,
    required this.onTap,
  });
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CkType.body(
            fontSize: 13,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
            color: primary ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rect border. Used by [MyTeamsEmptyState] and
/// [CreateNudgeCard].
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var d = 0.0;
      final total = m.length;
      while (d < total) {
        final extract = m.extractPath(d, (d + dashLength).clamp(0, total));
        canvas.drawPath(extract, paint);
        d += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.dashGap != dashGap;
}
