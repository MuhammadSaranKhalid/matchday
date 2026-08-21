import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matchday/core/theme/circk_theme.dart';

/// Single run button (0, 1, 2, 3, 4, 6).
class RunButton extends StatelessWidget {
  const RunButton({
    super.key,
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
        border: isSix ? null : Border.all(color: CkColors.hairline, width: 1),
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
          onTap: onTap == null ? null : () => ackHaptic(onTap!),
          borderRadius: BorderRadius.circular(14),
          child: box,
        ),
      ),
    );
  }
}

/// Danger-toned wicket action key ('W').
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
          onTap: onTap == null ? null : () => ackHaptic(onTap!),
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

/// Single extra type button (Wide, No-ball, Bye, Leg-bye).
class ExtraButton extends StatelessWidget {
  const ExtraButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => ackHaptic(onTap!),
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

/// Fast haptic feedback on keypad tap.
void ackHaptic(VoidCallback action) {
  HapticFeedback.selectionClick();
  action();
}
