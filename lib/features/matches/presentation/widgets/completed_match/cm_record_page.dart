import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/completed_match_view.dart';
import 'cm_atoms.dart';

/// What a walkover or an abandonment renders instead of a scorecard.
///
/// With no delivery there is nothing to tab through, so the caller does not
/// render the tab bar at all and this page takes the whole body. Four tabs of
/// em-dashes reads as a broken page and invites taps that go nowhere; the
/// absence IS the content, so it is stated once, in words, and the page ends.
class CmRecordPage extends StatelessWidget {
  const CmRecordPage({required this.view, super.key});

  final CompletedMatchView view;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            view.headline ?? 'No match was played.',
            style: CkType.display(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
              height: 1.25,
            ),
          ),
          if (view.absenceNote != null) ...[
            const SizedBox(height: 10),
            Text(
              view.absenceNote!,
              style: CkType.body(
                fontSize: 13.5,
                height: 1.6,
                color: CkColors.ink2,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (view.recordRows.isNotEmpty)
            CmPanel(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: const BoxDecoration(
                    color: CkColors.paper,
                    border:
                        Border(bottom: BorderSide(color: CkColors.hairline)),
                  ),
                  child: Text('THE FIXTURE AS AGREED',
                      style: CmText.label(size: 9)),
                ),
                for (final (i, r) in view.recordRows.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                      border: i == view.recordRows.length - 1
                          ? null
                          : const Border(
                              bottom: BorderSide(color: CkColors.hairline)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 82,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(r.label.toUpperCase(),
                                style: CmText.label(size: 9)),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r.value,
                            style: CmText.name(size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          // The statement that closes the page. Dashed, because it describes a
          // boundary rather than holding content.
          DecoratedBox(
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NO DELIVERIES RECORDED',
                        style: CmText.label(size: 10, color: CkColors.ink2)),
                    const SizedBox(height: 6),
                    Text(
                      'There is no scorecard, no over log and no statistics '
                      'for this match, because no ball was bowled. Nothing is '
                      'missing.',
                      style: CkType.body(
                        fontSize: 12,
                        height: 1.6,
                        color: CkColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

/// A 14px-radius dashed rounded rectangle. Flutter's Border has no dash
/// support, so the outline is stroked from the same rounded path the fill uses.
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = CkColors.soft;

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + 4).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + 3;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
