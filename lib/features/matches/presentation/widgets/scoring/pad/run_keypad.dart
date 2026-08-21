import 'package:flutter/material.dart';

import 'pad_buttons.dart';

/// Grid of runs keys (0, 1, 2, 3, 4, 6) and the Wicket button.
class RunKeypad extends StatelessWidget {
  const RunKeypad({
    super.key,
    required this.onRun,
    required this.onWicket,
    this.busy = false,
  });

  final ValueChanged<int> onRun;
  final VoidCallback onWicket;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final r in const [0, 1, 2, 3]) ...[
              Expanded(
                child: RunButton(
                  value: r,
                  big: false,
                  onTap: enabled ? () => onRun(r) : null,
                ),
              ),
              if (r != 3) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: RunButton(
                value: 4,
                big: true,
                onTap: enabled ? () => onRun(4) : null,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: RunButton(
                value: 6,
                big: true,
                onTap: enabled ? () => onRun(6) : null,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: WicketButton(onTap: enabled ? onWicket : null),
            ),
          ],
        ),
      ],
    );
  }
}
