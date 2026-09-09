import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/scoring/scorecard.dart';
import '../../state/completed_match_view.dart';
import 'cm_atoms.dart';

/// The Stats tab — the shape of the two innings against each other.
///
/// The innings are told apart by FILL versus OUTLINE, never by hue: filled
/// bars and a solid worm for the first innings, hairline-outlined bars and a
/// dashed worm for the second. Two team colours on one chart would compete
/// with the result band, and colour-blind readers lose the distinction
/// entirely; fill versus outline survives both.
class CmStatsTab extends StatelessWidget {
  const CmStatsTab({required this.view, super.key});

  final CompletedMatchView view;

  @override
  Widget build(BuildContext context) {
    final innings = view.innings;
    if (innings.isEmpty) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 32),
      children: [
        _Legend(view: view),
        const SizedBox(height: 13),
        const CmSectionHeading('Manhattan · runs per over'),
        const SizedBox(height: 11),
        CmPanel(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 14, 13, 10),
            child: _Manhattan(innings: innings),
          ),
        ]),
        const SizedBox(height: 13),
        const CmSectionHeading('Worm · cumulative runs'),
        const SizedBox(height: 11),
        CmPanel(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 14, 13, 10),
            child: _Worm(innings: innings),
          ),
        ]),
        const SizedBox(height: 13),
        const CmSectionHeading('Where the runs came from'),
        const SizedBox(height: 11),
        _RunSources(view: view),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.view});

  final CompletedMatchView view;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final (i, inn) in view.innings.indexed) ...[
            Container(
              width: 16,
              height: 10,
              decoration: BoxDecoration(
                color: i == 0 ? CkColors.ink : Colors.transparent,
                border: i == 0 ? null : Border.all(color: CkColors.ink2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _teamName(view, inn.battingTeamSide),
              style: CmText.label(size: 9.5, color: CkColors.ink2),
            ),
            if (i == 0) const SizedBox(width: 16),
          ],
        ],
      );
}

String _teamName(CompletedMatchView v, String side) =>
    v.sides.where((s) => s.sideLetter == side).map((s) => s.name).firstOrNull ??
    'Team';

/// Runs per over, both innings interleaved. Every over occupies a bar, so a
/// maiden reads as a gap in the skyline rather than vanishing.
class _Manhattan extends StatelessWidget {
  const _Manhattan({required this.innings});

  final List<InningsCard> innings;

  @override
  Widget build(BuildContext context) {
    final series = innings.map((i) => i.runsPerOver).toList();
    final overs = series.fold<int>(0, (a, b) => a > b.length ? a : b.length);
    final max = series
        .expand((s) => s)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MAX $max', style: CmText.label(size: 9)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var o = 0; o < overs; o++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final (i, s) in series.indexed)
                          Expanded(
                            child: Container(
                              height: (o < s.length ? s[o] : 0) / max * 100,
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              decoration: BoxDecoration(
                                color: i == 0 ? CkColors.ink : null,
                                border: i == 0
                                    ? null
                                    : Border.all(
                                        color: CkColors.ink2, width: 1),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1', style: CmText.label(size: 9)),
            Text('$overs', style: CmText.label(size: 9)),
          ],
        ),
      ],
    );
  }
}

/// Cumulative runs. Solid for the first innings, dashed for the second — the
/// chase is the line you follow, so it is the one that reads as provisional
/// until it crosses.
class _Worm extends StatelessWidget {
  const _Worm({required this.innings});

  final List<InningsCard> innings;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _WormPainter(
                series: innings.map((i) => i.cumulativeRuns).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: CmText.label(size: 9)),
              Text(
                '${innings.map((i) => i.runsPerOver.length).fold<int>(0, (a, b) => a > b ? a : b)} OV',
                style: CmText.label(size: 9),
              ),
            ],
          ),
        ],
      );
}

class _WormPainter extends CustomPainter {
  _WormPainter({required this.series});

  final List<List<int>> series;

  @override
  void paint(Canvas canvas, Size size) {
    final maxRuns = series
        .expand((s) => s)
        .fold<int>(1, (a, b) => a > b ? a : b);
    final maxOvers = series.fold<int>(1, (a, b) => a > b.length ? a : b.length);

    for (final (i, s) in series.indexed) {
      if (s.isEmpty) continue;
      final path = Path()..moveTo(0, size.height);
      for (final (o, runs) in s.indexed) {
        path.lineTo(
          (o + 1) / maxOvers * size.width,
          size.height - runs / maxRuns * size.height,
        );
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 2 : 1.5
        ..strokeCap = StrokeCap.round
        ..color = i == 0 ? CkColors.ink : CkColors.ink2;

      if (i == 0) {
        canvas.drawPath(path, paint);
      } else {
        _drawDashed(canvas, path, paint);
      }
    }
  }

  static void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + 5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WormPainter old) => old.series != series;
}

/// Fours, sixes, ones-and-twos and dots — the texture behind the total.
class _RunSources extends StatelessWidget {
  const _RunSources({required this.view});

  final CompletedMatchView view;

  @override
  Widget build(BuildContext context) => CmPanel(
        children: [
          for (final (i, inn) in view.innings.indexed)
            Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
              decoration: BoxDecoration(
                border: i == view.innings.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: CkColors.hairline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _teamName(view, inn.battingTeamSide),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CmText.name(size: 13),
                        ),
                      ),
                      Text('${inn.dots} DOTS', style: CmText.label(size: 9)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SourceBar(card: inn),
                  const SizedBox(height: 6),
                  Text(
                    '${inn.fours} fours · ${inn.sixes} sixes · '
                    '${inn.runsInOnesAndTwos} in ones & twos · '
                    '${inn.extras.total} extras',
                    style: CmText.figure(
                        size: 9.5,
                        weight: FontWeight.w600,
                        color: CkColors.muted),
                  ),
                ],
              ),
            ),
        ],
      );
}

class _SourceBar extends StatelessWidget {
  const _SourceBar({required this.card});

  final InningsCard card;

  @override
  Widget build(BuildContext context) {
    final parts = <(int, Color)>[
      (card.fours * 4, CkColors.ink),
      (card.sixes * 6, CkColors.ink2),
      (card.runsInOnesAndTwos, CkColors.soft),
      (card.extras.total, CkColors.line),
    ].where((p) => p.$1 > 0).toList();

    if (parts.isEmpty) return const SizedBox(height: 10);

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final p in parts)
              Expanded(flex: p.$1, child: ColoredBox(color: p.$2)),
          ],
        ),
      ),
    );
  }
}
