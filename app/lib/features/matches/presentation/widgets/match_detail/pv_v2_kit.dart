import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'pv_v2_data.dart';

// ── Icons (exact path data from challenge-shared.jsx `PATHS`) ────────────────

abstract final class PvIcons {
  static const back = '<path d="M15 18l-6-6 6-6"/>';
  static const next = '<path d="M9 18l6-6-6-6"/>';
  static const check = '<polyline points="20 6 9 17 4 12"/>';
  static const close = '<path d="M6 6l12 12M18 6L6 18"/>';
  static const search =
      '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>';
  static const cal =
      '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const users =
      '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>';
  static const share =
      '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>';
  static const info =
      '<circle cx="12" cy="12" r="9"/><path d="M12 16v-4M12 8h.01"/>';
  static const flag = '<path d="M4 22V4M4 4h13l-2 4 2 4H4"/>';
  static const swords =
      '<path d="M14.5 17.5 22 10l-2-2-7.5 7.5M9.5 6.5 2 14l2 2 7.5-7.5"/>';
  static const pencil =
      '<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>';
  static const msg =
      '<path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>';
  static const bell =
      '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>';
  static const star =
      '<path d="M12 3l2.9 5.9 6.5.9-4.7 4.6 1.1 6.5L12 18l-5.8 3.4 1.1-6.5L2.6 9.8l6.5-.9z"/>';
  static const trophy =
      '<path d="M6 4h12v4a6 6 0 0 1-12 0z"/><path d="M6 6H3v2a3 3 0 0 0 3 3M18 6h3v2a3 3 0 0 1-3 3M9 20h6M12 14v6"/>';
  static const play = '<path d="M6 4l14 8-14 8z"/>';
  static const dots =
      '<circle cx="5" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="19" cy="12" r="1.4"/>';
  static const whistle =
      '<circle cx="9" cy="14" r="6"/><path d="M15 12l7-3-1 4-6 1M9 14h.01"/>';
  static const ticket =
      '<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 11a2 2 0 0 0 0 2M21 11a2 2 0 0 1 0 2"/>';

  /// Lookup by the string names used in the account/data layer.
  static const Map<String, String> byName = {
    'back': back,
    'next': next,
    'check': check,
    'close': close,
    'search': search,
    'cal': cal,
    'plus': plus,
    'users': users,
    'share': share,
    'info': info,
    'flag': flag,
    'swords': swords,
    'pencil': pencil,
    'msg': msg,
    'bell': bell,
    'star': star,
    'trophy': trophy,
    'play': play,
    'dots': dots,
    'whistle': whistle,
    'ticket': ticket,
  };
}

/// Renders a [PvIcons] glyph (by raw path or by `byName` key).
class PvIcon extends StatelessWidget {
  const PvIcon(
    this.path, {
    super.key,
    this.size = 18,
    this.color = CkColors.ink,
    this.sw = 2,
  });

  /// Resolve a glyph by its data-layer name (e.g. account item icons).
  factory PvIcon.named(
    String name, {
    Key? key,
    double size = 18,
    Color color = CkColors.ink,
    double sw = 2,
  }) => PvIcon(
    PvIcons.byName[name] ?? PvIcons.info,
    key: key,
    size: size,
    color: color,
    sw: sw,
  );

  final String path;
  final double size;
  final Color color;
  final double sw;

  @override
  Widget build(BuildContext context) =>
      V2Svg(path, size: size, color: color, strokeWidth: sw);
}

// ── Mono label helper ───────────────────────────────────────────────────────

/// JetBrains Mono, 700, 0.10em uppercase (the prototype's `mono` style).
TextStyle pvMono(
  double size, {
  Color color = CkColors.muted,
  FontWeight weight = FontWeight.w700,
}) => CkType.mono(
  fontSize: size,
  fontWeight: weight,
  letterSpacing: 0.10,
  color: color,
);

// ── Pill ────────────────────────────────────────────────────────────────────

enum PvTone { red, amber, green, neutral }

/// phase → (pill label, tone, live).
(String, PvTone, bool) pvPhaseConf(PvPhase p) => switch (p) {
  PvPhase.live => ('LIVE', PvTone.red, true),
  PvPhase.startsSoon => ('STARTS SOON', PvTone.amber, false),
  PvPhase.scheduled => ('SCHEDULED', PvTone.neutral, false),
  PvPhase.awaitingReply => ('AWAITING REPLY', PvTone.amber, false),
  PvPhase.completed => ('FINAL', PvTone.neutral, false),
};

/// Mono status pill with a leading colour dot (pulses when [live]).
class PvPill extends StatelessWidget {
  const PvPill(
    this.label, {
    super.key,
    this.tone = PvTone.neutral,
    this.live = false,
  });

  final String label;
  final PvTone tone;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color dot) = switch (tone) {
      PvTone.red => (CkColors.redSoft, CkInk.red, CkColors.red),
      PvTone.amber => (CkColors.cream, CkInk.amber, CkColors.amber),
      PvTone.green => (CkColors.greenSoft, CkInk.green, CkColors.green),
      PvTone.neutral => (CkColors.paper2, CkColors.muted, CkColors.soft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PvDot(color: dot, size: 5, pulse: live),
          const SizedBox(width: 5),
          Text(label, style: pvMono(9, color: fg)),
        ],
      ),
    );
  }
}

/// A small round dot. When [pulse] is set it fades 1 → 0.3 → 1 on a 1.4s loop
/// (the prototype's `ck-pulse` keyframe).
class PvDot extends StatefulWidget {
  const PvDot({
    super.key,
    required this.color,
    this.size = 6,
    this.pulse = false,
  });

  final Color color;
  final double size;
  final bool pulse;

  @override
  State<PvDot> createState() => _PvDotState();
}

class _PvDotState extends State<PvDot> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (_c == null) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_c!),
      child: dot,
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────────

/// Mono uppercase section label, gutter 18, optional right-aligned action.
class PvSecLabel extends StatelessWidget {
  const PvSecLabel(this.label, {super.key, this.action, this.onAction});

  final String label;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: pvMono(10, color: CkColors.muted)),
          if (action != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Text(action!, style: pvMono(9, color: CkColors.ink2)),
            ),
        ],
      ),
    );
  }
}
