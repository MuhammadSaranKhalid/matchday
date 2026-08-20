// The input half of the scoring screen: everything the scorer taps. Its
// counterpart is scoring_board.dart.
//
// Purely presentational — the widgets report intent through callbacks and know
// nothing about the controller.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/ball.dart';

/// Rows of run buttons plus the wicket key.
class RunPad extends StatelessWidget {
  const RunPad({
    super.key,
    required this.busy,
    required this.onRun,
    required this.onWicket,
  });

  /// A write is in flight. Every key is disabled — this is the guard that
  /// stops a double-tap recording two deliveries.
  final bool busy;
  final ValueChanged<int> onRun;
  final VoidCallback onWicket;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
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
      ),
    );
  }
}

/// Wide / no-ball / bye / leg-bye.
class ExtrasRow extends StatelessWidget {
  const ExtrasRow({super.key, required this.onExtra, this.busy = false});

  final ValueChanged<BallKind> onExtra;

  /// A write is in flight. The run pad already locks on this; the extras row
  /// did not, so mid-write the four extra keys stayed live while every run key
  /// was dead — an inconsistency the scorer had no way to read.
  final bool busy;

  static const _kinds = <(BallKind, String)>[
    (BallKind.wide, 'Wide'),
    (BallKind.noBall, 'No-ball'),
    (BallKind.bye, 'Bye'),
    (BallKind.legBye, 'Leg-bye'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
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
      ),
    );
  }
}

class RunButton extends StatelessWidget {
  const RunButton({super.key, 
    required this.value,
    required this.big,
    required this.onTap,
  });
  final int value;
  final bool big;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFour = value == 4;
    final isSix = value == 6;
    final isDot = value == 0;

    final bg = isFour
        ? CkColors.greenSoft
        : isSix
            ? CkColors.ink
            : CkColors.surface;
    final fg = isSix
        ? CkColors.paper
        : isFour
            ? const Color(0xFF1F5828)
            : CkColors.ink;
    final label = isDot ? '•' : '$value';

    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      height: big ? 56 : 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: isSix
            ? null
            : Border.all(color: CkColors.hairline, width: 1),
        boxShadow: isSix
            ? const [
                BoxShadow(
                  color: Color(0x14281E0F),
                  blurRadius: 28,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: CkType.display(
          fontSize: big ? 24 : 22,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: -0.02,
        ),
      ),
    );

    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null ? null : () => _ack(onTap!),
          borderRadius: BorderRadius.circular(14),
          child: box,
        ),
      ),
    );
  }
}

class WicketButton extends StatelessWidget {
  const WicketButton({super.key, required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null ? null : () => _ack(onTap!),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: CkColors.redSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              'W',
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CkColors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExtraButton extends StatelessWidget {
  const ExtraButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => _ack(onTap!),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label.toUpperCase(),
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.04,
                color: CkColors.ink2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acknowledge a scoring key the instant it is pressed.
///
/// The write is a network round trip; the confirmation is not. Firing a
/// selection click synchronously — before the await — means the key always
/// answers immediately, which is most of what "fast" feels like on a pad
/// being tapped once a ball. Deliberately not a heavy impact: a scorer hits
/// this several hundred times a match.
void _ack(VoidCallback action) {
  HapticFeedback.selectionClick();
  action();
}
