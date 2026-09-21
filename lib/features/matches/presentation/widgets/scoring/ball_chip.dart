// Ball chips — the small coloured pill that represents one delivery.
// Extracted from scoring_screen.dart, which had grown past 3,200
// lines. Purely presentational — no Riverpod, no repository access.

import 'package:flutter/material.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/ball.dart';

enum BallChipKind { dot, run, four, six, wkt, extra }

class BallChipData {
  const BallChipData({required this.label, required this.kind});
  final String label;
  final BallChipKind kind;
}

class BallChip extends StatelessWidget {
  const BallChip({super.key, required this.chip, required this.size});
  final BallChipData chip;
  final double size;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    bool border = false;
    switch (chip.kind) {
      case BallChipKind.four:
        bg = CkColors.greenSoft;
        fg = const Color(0xFF1F5828);
        break;
      case BallChipKind.six:
        bg = CkColors.ink;
        fg = CkColors.paper;
        break;
      case BallChipKind.wkt:
        bg = CkColors.red;
        fg = Colors.white;
        break;
      case BallChipKind.extra:
        bg = CkColors.cream;
        fg = CkColors.ink2;
        break;
      case BallChipKind.dot:
        bg = CkColors.paper2;
        fg = CkColors.muted;
        border = true;
        break;
      case BallChipKind.run:
        bg = CkColors.paper2;
        fg = CkColors.ink;
        border = true;
        break;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border ? Border.all(color: CkColors.hairline, width: 1) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        chip.label,
        style: CkType.display(
          fontSize: size <= 22 ? 11 : 13,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: -0.02,
        ),
      ),
    );
  }
}

String ballChipLabel(Ball b) {
  if (b.isWicket) return 'W';
  if (b.ballKind == BallKind.wide) {
    return b.extras > 1 ? '${b.extras}wd' : 'wd';
  }
  if (b.ballKind == BallKind.noBall) {
    final t = 1 + b.runsScored;
    return t > 1 ? '${t}nb' : 'nb';
  }
  if (b.ballKind == BallKind.bye) return '${b.extras}b';
  if (b.ballKind == BallKind.legBye) return '${b.extras}lb';
  if (b.runsScored == 0) return '•';
  return '${b.runsScored}';
}

BallChipKind ballChipKind(Ball b) {
  if (b.isWicket) return BallChipKind.wkt;
  if (b.ballKind == BallKind.wide ||
      b.ballKind == BallKind.noBall ||
      b.ballKind == BallKind.bye ||
      b.ballKind == BallKind.legBye) {
    return BallChipKind.extra;
  }
  if (b.runsScored == 4) return BallChipKind.four;
  if (b.runsScored == 6) return BallChipKind.six;
  if (b.runsScored == 0) return BallChipKind.dot;
  return BallChipKind.run;
}

/// How a delivery is numbered in the log.
///
/// The engine stores `ball_in_over = 0` for every illegal delivery — a
/// sentinel meaning "this one did not count", not a ball number. Printing it
/// raw produced "1.0" for a no-ball bowled *after* 1.1, which read as though
/// it came first, and made two wides in an over indistinguishable. Wides and
/// no-balls genuinely have no ball number, so say so.
String ballNumberLabel(Ball b) =>
    b.isLegalDelivery ? '${b.overNumber}.${b.ballInOver}' : '${b.overNumber}.–';

/// Human label for a dismissal. [WicketType.wire] is the database spelling
/// (`run_out`, `hit_wicket`) and used to reach the UI verbatim.
String wicketLabel(WicketType? t) => switch (t) {
  WicketType.bowled => 'bowled',
  WicketType.caught => 'caught',
  WicketType.lbw => 'LBW',
  WicketType.runOut => 'run out',
  WicketType.stumped => 'stumped',
  WicketType.hitWicket => 'hit wicket',
  WicketType.retiredHurt => 'retired hurt',
  WicketType.obstructing => 'obstructing the field',
  WicketType.timedOut => 'timed out',
  WicketType.handledBall => 'handled the ball',
  null => 'out',
};

/// One-line description of a delivery.
///
/// [batterName] and [fielderName] are optional because not every caller can
/// resolve them. When they are available a wicket reads "Shaheen c Haris"
/// instead of the previous "WICKET · caught", which named nobody — the scorer
/// could not tell from the log who had actually been dismissed.
String describeBall(Ball b, {String? batterName, String? fielderName}) {
  if (b.isWicket) {
    final how = wicketLabel(b.wicketType);
    final by =
        (fielderName != null && fielderName.trim().isNotEmpty)
            ? switch (b.wicketType) {
              WicketType.caught => 'c $fielderName',
              WicketType.stumped => 'st $fielderName',
              WicketType.runOut => 'run out ($fielderName)',
              _ => how,
            }
            : how;
    return (batterName != null && batterName.trim().isNotEmpty)
        ? '$batterName · $by'
        : 'WICKET · $by';
  }
  switch (b.ballKind) {
    case BallKind.wide:
      return 'Wide${b.extras > 1 ? ' + ${b.extras - 1}' : ''}';
    case BallKind.noBall:
      return 'No-ball${b.runsScored > 0 ? ' · ${b.runsScored} off bat' : ''}';
    case BallKind.bye:
      return '${b.extras} bye${b.extras == 1 ? '' : 's'}';
    case BallKind.legBye:
      return '${b.extras} leg-bye${b.extras == 1 ? '' : 's'}';
    case BallKind.legal:
      if (b.runsScored == 0) return 'Dot ball';
      if (b.runsScored == 4) return 'Four!';
      if (b.runsScored == 6) return 'SIX!';
      return '${b.runsScored} run${b.runsScored == 1 ? '' : 's'}';
  }
}
