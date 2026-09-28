import 'package:flutter/material.dart';

import '../../../../domain/entities/ball.dart';
import 'pad_buttons.dart';

/// Row of extra delivery triggers (Wide, No-ball, Bye, Leg-bye).
class ExtrasKeypad extends StatelessWidget {
  const ExtrasKeypad({super.key, required this.onExtra, this.busy = false});

  final ValueChanged<BallKind> onExtra;
  final bool busy;

  static const _kinds = <(BallKind, String)>[
    (BallKind.wide, 'Wide'),
    (BallKind.noBall, 'No-ball'),
    (BallKind.bye, 'Bye'),
    (BallKind.legBye, 'Leg-bye'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (kind, label) in _kinds) ...[
          Expanded(
            child: ExtraButton(
              label: label,
              onTap: busy ? null : () => onExtra(kind),
            ),
          ),
          if (kind != BallKind.legBye) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
