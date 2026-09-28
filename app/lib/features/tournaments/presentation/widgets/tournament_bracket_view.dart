import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../providers/tournaments_providers.dart';
import 'ck_bracket_node.dart';

/// How a node is fed. The canvas states this grammar outright, and it is the
/// whole reason the bracket reads rather than merely renders.
enum FeederStyle {
  /// 1px solid ink — a resolved route. Only drawn once the feeding match has
  /// a winner.
  resolved,

  /// 1px hairline — unresolved. Orthogonal only: out, across the gutter, in.
  /// No diagonals, no curves.
  unresolved,

  /// 1px dashed ink — a bye. The node keeps its seed chip and states the
  /// reason in mono, so the empty half of the round never looks like a
  /// loading state.
  bye,
}

/// Artboards 13 and 13c — the Bracket / Playoffs tab.
///
/// The tree pans horizontally under a pinned round strip; tapping a round
/// anchor **animates the pan to that column rather than jumping**. The 3rd
/// place playoff is pinned below the Final rather than drawn into the tree —
/// it is a fixture, not a route.
class TournamentBracketView extends ConsumerStatefulWidget {
  const TournamentBracketView({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentBracketView> createState() =>
      _TournamentBracketViewState();
}

class _TournamentBracketViewState extends ConsumerState<TournamentBracketView> {
  final _pan = ScrollController();

  static const _columnWidth = 216.0;
  static const _gutter = 30.0;
  static const _nodeHeight = 74.0;
  static const _nodeGap = 18.0;

  @override
  void dispose() {
    _pan.dispose();
    super.dispose();
  }

  void _panTo(int column) {
    if (!_pan.hasClients) return;
    final target = (column * (_columnWidth + _gutter))
        .clamp(0.0, _pan.position.maxScrollExtent);
    _pan.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(tournamentLiveBoardProvider(widget.tournament.id));

    return switch (board) {
      AsyncLoading() =>
        const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
          ),
        ),
      AsyncData(value: final fixtures) => _body(fixtures),
    };
  }

  Widget _body(List<TournamentLiveMatch> fixtures) {
    final knockout = fixtures.where((f) => !_isThirdPlace(f)).toList();
    final thirdPlace =
        fixtures.where(_isThirdPlace).cast<TournamentLiveMatch?>().firstOrNull;

    if (knockout.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_tree_outlined,
                size: 30,
                color: CkColors.soft,
              ),
              const SizedBox(height: 12),
              Text(
                'The bracket is not drawn yet',
                textAlign: TextAlign.center,
                style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'It appears the moment the organiser locks the draw.',
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 12.5,
                  height: 1.55,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final columns = _columnsOf(knockout);
    final tallest = columns.fold<int>(
      0,
      (m, c) => c.fixtures.length > m ? c.fixtures.length : m,
    );
    final treeHeight = tallest * _nodeHeight + (tallest - 1) * _nodeGap + 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoundStrip(
          labels: [for (final c in columns) c.shortLabel],
          onTap: _panTo,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: treeHeight,
                  child: SingleChildScrollView(
                    controller: _pan,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _Tree(
                      columns: columns,
                      columnWidth: _columnWidth,
                      gutter: _gutter,
                      nodeHeight: _nodeHeight,
                      nodeGap: _nodeGap,
                      onTapMatch: (m) => context.push('/matches/${m.matchId}'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swipe_outlined,
                        size: 14,
                        color: CkColors.soft,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe to pan',
                        style:
                            CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
                // Pinned under the Final, never drawn into the tree — it has
                // no onward feeder.
                if (thirdPlace != null) _ThirdPlace(match: thirdPlace),
                const _FeederLegend(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static bool _isThirdPlace(TournamentLiveMatch m) {
    final r = m.round?.toLowerCase() ?? '';
    return r.contains('3rd') || r.contains('third place');
  }

  /// Groups fixtures into bracket columns, ordered smallest round first.
  List<_Column> _columnsOf(List<TournamentLiveMatch> fixtures) {
    final map = <String, List<TournamentLiveMatch>>{};
    for (final f in fixtures) {
      map.putIfAbsent(_roundKeyOf(f), () => []).add(f);
    }
    final keys = map.keys.toList()
      // Most fixtures first: the widest round is the earliest.
      ..sort((a, b) => map[b]!.length.compareTo(map[a]!.length));
    return [
      for (final k in keys)
        _Column(
          label: k,
          shortLabel: _short(k),
          fixtures: map[k]!
            ..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime)),
        ),
    ];
  }

  static String _roundKeyOf(TournamentLiveMatch m) {
    final r = m.round ?? 'Round';
    // "Quarter-Final 1" and "Quarter-Final 2" are one column.
    return r.replaceAll(RegExp(r'\s*\d+$'), '').trim();
  }

  static String _short(String label) {
    final l = label.toLowerCase();
    if (l.contains('quarter')) return 'QF';
    if (l.contains('semi')) return 'SF';
    if (l.contains('final')) return 'Final';
    if (l.contains('round of')) return label.replaceAll('Round of ', 'R');
    return label.length <= 6 ? label : label.substring(0, 6);
  }
}

class _Column {
  const _Column({
    required this.label,
    required this.shortLabel,
    required this.fixtures,
  });

  final String label;
  final String shortLabel;
  final List<TournamentLiveMatch> fixtures;
}

/// The pinned round strip. Tapping an anchor pans; it never jumps.
class _RoundStrip extends StatelessWidget {
  const _RoundStrip({required this.labels, required this.onTap});

  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        color: CkColors.paper2,
        border: Border(bottom: BorderSide(color: CkColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: CkColors.line),
                ),
                child: Text(
                  labels[i],
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.ink2,
                  ),
                ),
              ),
            ),
            if (i != labels.length - 1) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

/// The tree itself: columns of nodes with the feeder paths painted behind
/// them. Positions are computed once here so the painter and the nodes cannot
/// disagree about where a line should land.
class _Tree extends StatelessWidget {
  const _Tree({
    required this.columns,
    required this.columnWidth,
    required this.gutter,
    required this.nodeHeight,
    required this.nodeGap,
    required this.onTapMatch,
  });

  final List<_Column> columns;
  final double columnWidth;
  final double gutter;
  final double nodeHeight;
  final double nodeGap;
  final ValueChanged<TournamentLiveMatch> onTapMatch;

  /// Vertical centre of node [i] in a column of [count], within a tree whose
  /// tallest column has [tallest] nodes. Later rounds sit midway between the
  /// two nodes that feed them, which is what makes the paths orthogonal.
  double _centreOf(int i, int count, int tallest) {
    final span = tallest * nodeHeight + (tallest - 1) * nodeGap;
    final slot = span / count;
    return slot * i + slot / 2;
  }

  @override
  Widget build(BuildContext context) {
    final tallest = columns.fold<int>(
      0,
      (m, c) => c.fixtures.length > m ? c.fixtures.length : m,
    );
    final span = tallest * nodeHeight + (tallest - 1) * nodeGap;
    final width =
        columns.length * columnWidth + (columns.length - 1) * gutter;

    final positioned = <_Placed>[];
    for (var c = 0; c < columns.length; c++) {
      final col = columns[c];
      for (var i = 0; i < col.fixtures.length; i++) {
        positioned.add(
          _Placed(
            match: col.fixtures[i],
            column: c,
            indexInColumn: i,
            left: c * (columnWidth + gutter),
            centreY: _centreOf(i, col.fixtures.length, tallest),
          ),
        );
      }
    }

    return SizedBox(
      width: width,
      height: span,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FeederPainter(
                placed: positioned,
                columnWidth: columnWidth,
                gutter: gutter,
              ),
            ),
          ),
          for (final p in positioned)
            Positioned(
              left: p.left,
              top: p.centreY - nodeHeight / 2,
              width: columnWidth,
              height: nodeHeight,
              child: _Node(match: p.match, onTap: () => onTapMatch(p.match)),
            ),
        ],
      ),
    );
  }
}

class _Placed {
  const _Placed({
    required this.match,
    required this.column,
    required this.indexInColumn,
    required this.left,
    required this.centreY,
  });

  final TournamentLiveMatch match;
  final int column;
  final int indexInColumn;
  final double left;
  final double centreY;
}

/// Orthogonal only: out of the parent, across the gutter, into the child.
/// **No diagonals, no curves** — the canvas is explicit, and a curve would
/// imply a relationship the bracket does not have.
class _FeederPainter extends CustomPainter {
  const _FeederPainter({
    required this.placed,
    required this.columnWidth,
    required this.gutter,
  });

  final List<_Placed> placed;
  final double columnWidth;
  final double gutter;

  @override
  void paint(Canvas canvas, Size size) {
    for (final child in placed) {
      if (child.column == 0) continue;

      final parents = placed
          .where((p) => p.column == child.column - 1)
          .toList()
        ..sort((a, b) => a.indexInColumn.compareTo(b.indexInColumn));
      if (parents.isEmpty) continue;

      // Two parents feed each child, in order.
      final first = child.indexInColumn * 2;
      for (final offset in [0, 1]) {
        final idx = first + offset;
        if (idx >= parents.length) continue;
        final parent = parents[idx];
        _drawFeeder(canvas, parent, child, _styleFor(parent, child));
      }
    }
  }

  /// A route is resolved only once the feeding match has produced a winner.
  /// A child with one named side and no second parent is a bye.
  FeederStyle _styleFor(_Placed parent, _Placed child) {
    if (parent.match.winnerId != null) return FeederStyle.resolved;
    if (parent.match.status == 'walkover') return FeederStyle.bye;
    return FeederStyle.unresolved;
  }

  void _drawFeeder(
    Canvas canvas,
    _Placed parent,
    _Placed child,
    FeederStyle style,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = style == FeederStyle.unresolved ? CkColors.line : CkColors.ink;

    final startX = parent.left + columnWidth;
    final endX = child.left;
    final midX = startX + gutter / 2;

    final path = Path()
      ..moveTo(startX, parent.centreY)
      ..lineTo(midX, parent.centreY)
      ..lineTo(midX, child.centreY)
      ..lineTo(endX, child.centreY);

    if (style == FeederStyle.bye) {
      _drawDashed(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  static void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FeederPainter old) =>
      old.placed.length != placed.length;
}

class _Node extends StatelessWidget {
  const _Node({required this.match, required this.onTap});

  final TournamentLiveMatch match;
  final VoidCallback onTap;

  /// Where a bye sends the seed — "advances to SF" beats a bare "Bye".
  static String _nextRoundOf(String? round) {
    final r = round?.toLowerCase() ?? '';
    if (r.contains('quarter')) return 'SF';
    if (r.contains('semi')) return 'the Final';
    if (r.contains('round of')) return 'the next round';
    return 'the next round';
  }

  @override
  Widget build(BuildContext context) {
    return CkBracketNode(
      teamAId: match.teamAId,
      teamBId: match.teamBId,
      teamAName: match.displayNameFor(match.teamAId),
      teamBName: match.displayNameFor(match.teamBId),
      scoreA: match.lineFor(match.teamAId)?.scoreText,
      scoreB: match.lineFor(match.teamBId)?.scoreText,
      winnerTeamId: match.winnerId,
      roundLabel: match.round,
      isLive: match.status == 'live' || match.status == 'super_over',
      // A bye keeps its seed chip and states the reason in mono, so the empty
      // half of the round never looks like a loading state.
      isBye: match.teamBId == null && match.teamAId != null,
      byeReason: match.teamBId == null && match.teamAId != null
          ? 'Bye · advances to ${_nextRoundOf(match.round)}'
          : null,
      onTap: onTap,
    );
  }
}

/// The 3rd place playoff — a fixture, not a route, so it is pinned below the
/// Final rather than drawn into the tree.
class _ThirdPlace extends StatelessWidget {
  const _ThirdPlace({required this.match});

  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3RD PLACE PLAYOFF · '
              '${DateFormat('EEE d MMM · HH:mm').format(match.scheduledStartTime)}'
                  .toUpperCase(),
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            _PlayoffSide(
              name: match.teamAId == null
                  ? 'Loser SF1'
                  : match.displayNameFor(match.teamAId),
              resolved: match.teamAId != null,
            ),
            const SizedBox(height: 5),
            _PlayoffSide(
              name: match.teamBId == null
                  ? 'Loser SF2'
                  : match.displayNameFor(match.teamBId),
              resolved: match.teamBId != null,
            ),
            const SizedBox(height: 8),
            Text(
              match.venue,
              style: CkType.body(fontSize: 11, color: CkColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayoffSide extends StatelessWidget {
  const _PlayoffSide({required this.name, required this.resolved});

  final String name;
  final bool resolved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: resolved ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
        if (!resolved)
          Text(
            'To be decided',
            style: CkType.body(fontSize: 11, color: CkColors.soft),
          ),
      ],
    );
  }
}

/// The grammar, stated on the screen that uses it — a reader should not have
/// to guess why one line is dashed and another solid.
class _FeederLegend extends StatelessWidget {
  const _FeederLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FEEDER LINES',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 7),
          const _LegendRow(
            style: FeederStyle.resolved,
            text: 'Resolved route — drawn once the feeding match has a winner.',
          ),
          const _LegendRow(
            style: FeederStyle.unresolved,
            text: 'Unresolved route — orthogonal only, no diagonals.',
          ),
          const _LegendRow(
            style: FeederStyle.bye,
            text: 'A bye — the node keeps its seed and states the reason.',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.style, required this.text});

  final FeederStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: SizedBox(
              width: 22,
              height: 1,
              child: CustomPaint(painter: _LegendLinePainter(style: style)),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: CkType.body(
                fontSize: 11,
                height: 1.45,
                color: CkColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.style});

  final FeederStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..color = style == FeederStyle.unresolved ? CkColors.line : CkColors.ink;

    if (style == FeederStyle.bye) {
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
        x += 7;
      }
      return;
    }
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter old) => old.style != style;
}
