// Wide / no-ball / bye / leg-bye entry.
// Extracted from scoring_screen.dart, which had grown past 3,200
// lines. Purely presentational — no Riverpod, no repository access.

import 'package:flutter/material.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/ball.dart';
import 'sheet_kit.dart';
import 'scoring_board.dart';

class ExtraResult {
  const ExtraResult({
    required this.kind,
    required this.runs,
    required this.freeHit,
  });
  final BallKind kind;
  final int runs;
  final bool freeHit;
}

class ExtrasSheet extends StatefulWidget {
  const ExtrasSheet({super.key, required this.kind, required this.overs});
  final BallKind kind;
  final String overs;
  @override
  State<ExtrasSheet> createState() => _ExtrasSheetState();
}

class _ExtrasSheetState extends State<ExtrasSheet> {
  int _runs = 0;
  bool _freeHit = false;

  @override
  void initState() {
    super.initState();
    _runs = widget.kind == BallKind.noBall
        ? 0
        : widget.kind == BallKind.wide
            ? 0
            : 1;
    _freeHit = widget.kind == BallKind.noBall;
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final title = switch (kind) {
      BallKind.wide => 'Wide',
      BallKind.noBall => 'No-ball',
      BallKind.bye => 'Bye',
      BallKind.legBye => 'Leg-bye',
      BallKind.legal => 'Run',
    };
    final kicker = switch (kind) {
      BallKind.wide => 'WIDE BALL · ${widget.overs}',
      BallKind.noBall => 'NO-BALL · ${widget.overs}',
      BallKind.bye => 'BYE · ${widget.overs}',
      BallKind.legBye => 'LEG-BYE · ${widget.overs}',
      BallKind.legal => 'EXTRA · ${widget.overs}',
    };
    final sub = switch (kind) {
      BallKind.wide =>
        'One penalty run plus any runs taken. The ball is re-bowled; the '
            'batters change ends only if they run an odd number.',
      BallKind.noBall =>
        'One penalty plus runs off the bat. The next ball is a free hit.',
      BallKind.bye =>
        'Runs taken with no contact off the bat. Counts as a legal ball.',
      BallKind.legBye =>
        'Runs off the body, not the bat. Counts as a legal ball.',
      BallKind.legal => '',
    };
    final batRuns = kind == BallKind.noBall;
    final runLabel = batRuns
        ? 'RUNS OFF THE BAT'
        : kind == BallKind.wide
            ? 'EXTRA RUNS RUN'
            : 'RUNS TAKEN';
    // 3 belongs on the wide and no-ball rows: running three off either is
    // legal and not rare, and without the option the scorer had no way to
    // record it. The chip grid is six wide, so both still fit on one row.
    final opts = switch (kind) {
      BallKind.wide => const [0, 1, 2, 3, 4],
      BallKind.noBall => const [0, 1, 2, 3, 4, 6],
      BallKind.bye || BallKind.legBye => const [1, 2, 3, 4],
      BallKind.legal => const [0, 1, 2, 3, 4, 6],
    };
    final penalty = (kind == BallKind.wide || kind == BallKind.noBall) ? 1 : 0;
    final total = penalty + _runs;

    return SheetScrim(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHead(kicker: kicker, title: title, subtitle: sub),
            Text(
              runLabel,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 7),
            SheetRunChips(
              value: _runs,
              options: opts,
              onPick: (r) => setState(() => _runs = r),
            ),
            const SizedBox(height: 14),
            if (kind == BallKind.noBall)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _freeHit = !_freeHit),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _freeHit
                            ? CkColors.cream
                            : CkColors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _freeHit
                              ? kFreeHitBorder
                              : CkColors.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: 40,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _freeHit
                                  ? CkColors.amber
                                  : CkColors.line,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  top: 2,
                                  left: _freeHit ? 18 : 2,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: CkColors.paper,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next ball is a free hit',
                                  style: CkType.display(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Only a run-out or hit wicket can dismiss on a free hit.',
                                  style: CkType.body(
                                    fontSize: 11,
                                    color: CkColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '${title.toUpperCase()}${_runs > 0 ? ' + $_runs' : ''}',
                    style: CkType.mono(
                      fontSize: 12,
                      letterSpacing: 0.06,
                      color: const Color(0xB3FDFAF4),
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '+$total ',
                          style: CkType.display(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: CkColors.paper,
                            letterSpacing: -0.03,
                          ),
                        ),
                        TextSpan(
                          text: total == 1 ? 'run' : 'runs',
                          style: CkType.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0x99FDFAF4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SheetGhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SheetPrimaryButton(
                    label: 'Add ${title.toLowerCase()}',
                    onTap: () => Navigator.of(context).pop(
                      ExtraResult(
                        kind: kind,
                        runs: _runs,
                        freeHit: kind == BallKind.noBall ? _freeHit : false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
