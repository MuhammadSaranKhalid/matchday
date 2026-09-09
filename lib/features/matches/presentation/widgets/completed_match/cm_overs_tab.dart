import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/ball.dart';
import '../../../domain/scoring/scorecard.dart';
import 'cm_atoms.dart';

/// The Overs tab — the ball-by-ball log, newest over first.
///
/// It opens on the LAST over rather than the first: the thing a person opens
/// this tab to relive is how it finished. "↑ First over" jumps to the start
/// for anyone reading it as a story instead.
///
/// There is no commentary text. The ledger records what each delivery WAS, not
/// what it looked like — `match_deliveries` has no commentary column and
/// nothing writes one — so each ball prints its outcome and stops. Rows with
/// nothing more to say print nothing more.
class CmOversTab extends StatefulWidget {
  const CmOversTab({required this.card, super.key});

  final InningsCard card;

  @override
  State<CmOversTab> createState() => _CmOversTabState();
}

class _CmOversTabState extends State<CmOversTab> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overs = _groupIntoOvers(widget.card.balls);
    if (overs.isEmpty) {
      return Center(
        child: Text('No deliveries in this innings.',
            style: CkType.body(fontSize: 13, color: CkColors.muted)),
      );
    }

    // Newest first — the last over is the first thing on screen.
    final ordered = overs.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () => _controller.animateTo(
                  _controller.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                ),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('↑ FIRST OVER',
                      style: CmText.label(size: 9.5, color: CkColors.ink2)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _controller,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 11),
            itemBuilder: (context, i) => _OverBlock(over: ordered[i]),
          ),
        ),
      ],
    );
  }
}

class _Over {
  _Over(this.number);
  final int number;
  final List<Ball> balls = [];

  int get runs =>
      balls.fold(0, (a, b) => a + b.runsScored + b.extras);
  int get wickets => balls.where((b) => b.isWicket).length;
}

List<_Over> _groupIntoOvers(List<Ball> balls) {
  final out = <int, _Over>{};
  for (final b in balls) {
    (out[b.overNumber] ??= _Over(b.overNumber)).balls.add(b);
  }
  final keys = out.keys.toList()..sort();
  return [for (final k in keys) out[k]!];
}

class _OverBlock extends StatelessWidget {
  const _OverBlock({required this.over});

  final _Over over;

  @override
  Widget build(BuildContext context) => CmPanel(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: const BoxDecoration(
              color: CkColors.paper,
              border: Border(bottom: BorderSide(color: CkColors.hairline)),
            ),
            child: Row(
              children: [
                Text('OVER ${over.number + 1}',
                    style: CmText.label(size: 9.5, color: CkColors.ink)),
                const Spacer(),
                Text(
                  '${over.runs} run${over.runs == 1 ? '' : 's'}'
                  '${over.wickets > 0 ? ' · ${over.wickets} w' : ''}',
                  style: CmText.figure(
                      size: 10,
                      weight: FontWeight.w600,
                      color: CkColors.muted),
                ),
              ],
            ),
          ),
          for (final (i, b) in over.balls.indexed)
            _BallRow(ball: b, last: i == over.balls.length - 1),
        ],
      );
}

class _BallRow extends StatelessWidget {
  const _BallRow({required this.ball, required this.last});

  final Ball ball;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (token, tone) = _token(ball);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              // An illegal delivery repeats its ball number, so an over with
              // extras runs longer than six entries.
              '${ball.overNumber}.${ball.ballInOver}',
              style: CmText.figure(
                  size: 10, weight: FontWeight.w600, color: CkColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          _Token(text: token, tone: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _outcome(ball),
              maxLines: 2,
              style: CkType.body(fontSize: 12, height: 1.4, color: CkColors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tone { plain, wicket, extra }

(String, _Tone) _token(Ball b) {
  if (b.isWicket) return ('W', _Tone.wicket);
  return switch (b.ballKind) {
    BallKind.wide => ('wd', _Tone.extra),
    BallKind.noBall => ('nb', _Tone.extra),
    BallKind.bye => ('b', _Tone.extra),
    BallKind.legBye => ('lb', _Tone.extra),
    BallKind.legal =>
      (b.runsScored == 0 ? '•' : '${b.runsScored}', _Tone.plain),
  };
}

String _outcome(Ball b) {
  final runs = b.runsScored + b.extras;
  if (b.isWicket) return 'Wicket';
  return switch (b.ballKind) {
    BallKind.wide => 'Wide${runs > 1 ? ' · $runs runs' : ''}',
    BallKind.noBall => 'No ball · $runs run${runs == 1 ? '' : 's'}',
    BallKind.bye => 'Bye · $runs run${runs == 1 ? '' : 's'}',
    BallKind.legBye => 'Leg bye · $runs run${runs == 1 ? '' : 's'}',
    BallKind.legal => switch (b.runsScored) {
        0 => 'Dot ball',
        4 => 'Four',
        6 => 'Six',
        1 => 'Single',
        _ => '${b.runsScored} runs',
      },
  };
}

class _Token extends StatelessWidget {
  const _Token({required this.text, required this.tone});

  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _Tone.wicket => (CkColors.redSurface, CkColors.redInk),
      _Tone.extra => (CkColors.cream, CkColors.amberInk),
      _Tone.plain => (CkColors.paper2, CkColors.ink),
    };
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(text,
          style: CmText.figure(size: 10.5, color: fg)),
    );
  }
}
