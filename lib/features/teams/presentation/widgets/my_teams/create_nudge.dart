import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// Soft "Play, don't just watch." nudge shown at the bottom of the
/// following-only case. Dashed-border card with a mini plus icon, a short
/// headline + sub, and a Start button. Less aggressive than the FAB so the
/// spectator isn't pressured.
class CreateNudgeCard extends StatelessWidget {
  const CreateNudgeCard({super.key, this.onStart});
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, size: 18, color: CkColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Play, don't just watch.",
                      style: CkType.display(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Create your own side or join one near Karachi.',
                      style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onStart ?? () {},
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: CkColors.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Start',
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CkColors.paper,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CkColors.line
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        final extract = m.extractPath(d, (d + 5).clamp(0, m.length));
        canvas.drawPath(extract, paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
