// Shared Pavilion atoms — public ports of the `Pv*` helpers from the design
// (design_bundle/matchday/project/app/screens/Pavilion.jsx), used by the
// Pavilion drill-down screens. Presentation-only, mock-data chrome.
//
// Drill-down BODIES use these; the Pavilion shell (pavilion_v2_screen.dart)
// supplies the back/title header, so there's no PvHeader here.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// monoLabel: JetBrains Mono 10 / 700 / 0.10em uppercase, default muted.
TextStyle pvMonoLabel({Color color = CkColors.muted}) => CkType.mono(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.10,
      color: color,
    );

/// display(size): Inter Tight 700 / -0.025em / line-height 1.05.
TextStyle pvDisplay(double size, {Color color = CkColors.ink}) =>
    CkType.display(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.025,
      height: 1.05,
      color: color,
    );

/// PvSectionH — mono label (+ optional count badge) and optional "ACTION →".
class PvSectionH extends StatelessWidget {
  const PvSectionH(this.label, {super.key, this.count, this.action, this.onAction, this.accent});

  final String label;
  final int? count;
  final String? action;
  final VoidCallback? onAction;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label.toUpperCase(),
                  style: pvMonoLabel(color: accent ?? CkColors.muted)),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                  decoration: BoxDecoration(
                    color: CkColors.ink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$count',
                      style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: CkColors.paper)),
                ),
              ],
            ],
          ),
          if (action != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Text('${action!.toUpperCase()} →',
                  style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.ink)),
            ),
        ],
      ),
    );
  }
}

/// PvCard — paper card, hairline border, optional 3px coloured left accent.
class PvCard extends StatelessWidget {
  const PvCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final Widget child;
  final Color? accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: const BorderSide(color: CkColors.hairline),
          right: const BorderSide(color: CkColors.hairline),
          bottom: const BorderSide(color: CkColors.hairline),
          left: BorderSide(
            color: accent ?? CkColors.hairline,
            width: accent != null ? 3 : 1,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// PvRow — full-width button row: 36×36 glyph tile + title/sub + meta + chevron.
class PvRow extends StatelessWidget {
  const PvRow({
    super.key,
    required this.glyph,
    required this.title,
    this.sub,
    this.meta,
    this.onTap,
    this.accent,
  });

  final String glyph;
  final String title;
  final String? sub;
  final String? meta;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent ?? CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(glyph,
                  style: TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accent != null ? CkColors.paper : CkColors.ink,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: CkType.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25)),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(sub!,
                          style:
                              CkType.body(fontSize: 12, color: CkColors.muted)),
                    ),
                ],
              ),
            ),
            if (meta != null) ...[
              const SizedBox(width: 8),
              Text(meta!,
                  style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: CkColors.muted)),
            ],
            const SizedBox(width: 8),
            const V2Svg(V2Icons.chevronRight,
                size: 14, color: CkColors.muted, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

enum PvPillKind { def, red, amber, green, soft, ink }

/// PvPill — mono uppercase chip in one of six tones.
class PvPill extends StatelessWidget {
  const PvPill(this.label, {super.key, this.kind = PvPillKind.def});

  final String label;
  final PvPillKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      PvPillKind.def => (CkColors.paper2, CkColors.ink2, CkColors.hairline),
      PvPillKind.red => (CkColors.red, Colors.white, null),
      PvPillKind.amber => (CkColors.amber, CkInk.amber, null),
      PvPillKind.green => (CkColors.green, Colors.white, null),
      PvPillKind.soft => (CkColors.cream, CkInk.amber, null),
      PvPillKind.ink => (CkColors.ink, CkColors.paper, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(label.toUpperCase(),
          style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: fg)),
    );
  }
}

/// PvSwitch — 38×22 toggle (ink on / grey off, paper knob).
class PvSwitch extends StatelessWidget {
  const PvSwitch({super.key, required this.on, this.onChange});

  final bool on;
  final ValueChanged<bool>? onChange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange == null ? null : () => onChange!(!on),
      child: Container(
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(2),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? CkColors.ink : const Color(0xFFD6D4CF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: CkColors.paper,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x26000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard scroll padding for a Pavilion drill-down body.
const pvBodyPadding = EdgeInsets.fromLTRB(18, 8, 18, 24);
