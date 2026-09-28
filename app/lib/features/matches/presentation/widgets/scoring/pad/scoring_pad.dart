import 'package:flutter/material.dart';

import '../../../../domain/entities/ball.dart';
import 'extras_keypad.dart';
import 'run_keypad.dart';

/// The complete, self-contained scoring keypad surface.
///
/// Combines [RunKeypad] (runs & wicket) and [ExtrasKeypad] (wide, no-ball, bye, leg-bye).
/// Purely presentational: reports user input through callbacks.
class ScoringPad extends StatelessWidget {
  const ScoringPad({
    super.key,
    required this.onRun,
    required this.onWicket,
    required this.onExtra,
    this.busy = false,
  });

  final ValueChanged<int> onRun;
  final VoidCallback onWicket;
  final ValueChanged<BallKind> onExtra;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RunKeypad(onRun: onRun, onWicket: onWicket, busy: busy),
          const SizedBox(height: 6),
          ExtrasKeypad(onExtra: onExtra, busy: busy),
        ],
      ),
    );
  }
}
