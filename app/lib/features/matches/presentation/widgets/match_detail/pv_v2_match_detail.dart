// Pavilion v2 — Match Detail page.
//
// Faithful port of `MatchDetail` in `pavilion-matches-v2.jsx`. This is where
// every per-match action lives (the cards are status-only). Full-screen column:
// top bar · scrolling body (hero, completed score, match spec, squad/lineup,
// head-to-head, manage) · phase-aware sticky footer.
import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'pv_v2_data.dart';
import 'pv_v2_kit.dart';

class _FooterAction {
  const _FooterAction(
    this.action,
    this.label, {
    this.primary = false,
    this.icon,
    this.danger = false,
  });
  final String action;
  final String label;
  final bool primary;
  final String? icon;
  final bool danger;
}

class PvMatchDetail extends StatelessWidget {
  const PvMatchDetail({
    super.key,
    required this.m,
    required this.onBack,
    required this.onAction,
  });

  final PvMatch m;
  final void Function(String id, String action) onAction;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final live = m.phase == PvPhase.live;
    final done = m.phase == PvPhase.completed;
    final awaiting = m.phase == PvPhase.awaitingReply;

    final (String headline, String subline) =
        live
            ? (m.scoreA ?? 'In play', '${m.when} · ${m.venue}')
            : done
            ? (m.sub, '${m.when} · ${m.venue}')
            : (m.when, m.venue);

    // Sticky footer — capability- and phase-aware.
    // Start Match is strictly capability-gated by `canStartMatch`.
    final footer = <_FooterAction>[
      if (live)
        const _FooterAction(
          'resume',
          'Resume scoring',
          primary: true,
          icon: PvIcons.whistle,
          danger: true,
        )
      else if ((m.phase == PvPhase.startsSoon ||
              m.phase == PvPhase.scheduled) &&
          m.canStartMatch)
        const _FooterAction(
          'start',
          'Start match',
          primary: true,
          icon: PvIcons.play,
        )
      else if (awaiting)
        const _FooterAction(
          'withdraw',
          'Withdraw challenge',
          primary: true,
          icon: PvIcons.close,
          danger: true,
        )
      else if (done) ...[
        const _FooterAction('share', 'Share', icon: PvIcons.share),
        const _FooterAction(
          'scorecard',
          'View scorecard',
          primary: true,
          icon: PvIcons.ticket,
        ),
      ],
    ];

    return Material(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  _closeButtonRow(),
                  _hero(
                    live: live,
                    done: done,
                    headline: headline,
                    subline: subline,
                  ),
                  if (done) _completedScore(),
                  const _DetailSectionH('Match spec'),
                  _KvCard(
                    rows: [
                      ('Format', m.formatDisplay),
                      ('Overs', m.oversDisplay),
                      ('Ball', m.ballDisplay),
                      ('Venue', m.venue),
                      ('When', m.when),
                    ],
                  ),
                  // Manage rows — design `pavilion-matches-v2.jsx:184-190`.
                  // Hidden for completed / awaiting-reply.
                  if (!done && !awaiting) ..._manageSection(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (footer.isNotEmpty) _footerBar(footer),
          ],
        ),
      ),
    );
  }

  // ── top close row on main page ──
  Widget _closeButtonRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('MATCH', style: pvMono(10, color: CkColors.muted)),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onBack,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.paper2,
            shape: BoxShape.circle,
            border: Border.all(color: CkColors.hairline),
          ),
          child: const PvIcon(
            PvIcons.close,
            size: 14,
            color: CkColors.ink,
            sw: 2.2,
          ),
        ),
      ),
    ],
  );

  // ── hero ──
  Widget _hero({
    required bool live,
    required bool done,
    required String headline,
    required String subline,
  }) {
    final fg = live ? CkColors.paper : CkColors.ink;
    final mutedFg = live ? Colors.white.withValues(alpha: 0.6) : CkColors.muted;
    final (label, tone, isLive) = pvPhaseConf(m.phase);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: live ? CkColors.ink : CkColors.paper2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Decorative cricket-ground ellipses, live state only.
          // Design `pavilion-matches-v2.jsx:208`.
          if (live)
            const Positioned(
              right: -80,
              top: -70,
              width: 200,
              height: 200,
              child: IgnorePointer(
                child: CustomPaint(painter: _HeroEllipsePainter()),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              children: [
                Center(child: PvPill(label, tone: tone, live: isLive)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _heroSide(
                      m.me,
                      m.meSubtitleDisplay,
                      live: live,
                      fg: fg,
                      mutedFg: mutedFg,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: PvIcon(
                        PvIcons.swords,
                        size: 20,
                        color:
                            live
                                ? Colors.white.withValues(alpha: 0.5)
                                : CkColors.muted,
                        sw: 2,
                      ),
                    ),
                    _heroSide(
                      m.them,
                      m.themSubtitleDisplay,
                      live: live,
                      fg: fg,
                      mutedFg: mutedFg,
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color:
                            live
                                ? Colors.white.withValues(alpha: 0.14)
                                : CkColors.hairline,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style:
                            (live || done)
                                ? CkType.mono(
                                  fontSize: live ? 26 : 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.01,
                                  color: fg,
                                )
                                : CkType.display(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          subline,
                          textAlign: TextAlign.center,
                          style: CkType.body(
                            fontSize: 12,
                            color:
                                live
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : CkColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSide(
    PvCrest c,
    String role, {
    required bool live,
    required Color fg,
    required Color mutedFg,
  }) {
    return Expanded(
      child: Column(
        children: [
          Crest(
            short: c.short,
            color: c.color,
            logoUrl: c.logoUrl,
            size: 52,
            radius: 14,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              role,
              style: CkType.body(fontSize: 10.5, color: mutedFg),
            ),
          ),
        ],
      ),
    );
  }

  // ── completed score line ──
  Widget _completedScore() {
    Widget box(String short, String? score, bool win) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: win ? CkColors.greenSoft : CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$short${win ? ' · WON' : ''}',
              style: pvMono(9, color: CkColors.muted),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                score ?? '',
                style: CkType.mono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final meWon = m.result == 'W';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          box(m.me.short, m.scoreA, meWon),
          const SizedBox(width: 8),
          box(m.them.short, m.scoreB, !meWon),
        ],
      ),
    );
  }

  // ── sticky footer ──
  Widget _footerBar(List<_FooterAction> footer) => Container(
    decoration: const BoxDecoration(
      color: CkColors.paper,
      border: Border(top: BorderSide(color: CkColors.hairline)),
    ),
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          for (var i = 0; i < footer.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              flex: footer[i].primary ? 14 : 10,
              child: _footerButton(footer[i]),
            ),
          ],
        ],
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Management actions
  // ---------------------------------------------------------------------------
  //
  // Cancellation is intentionally the only management action currently exposed
  // here.
  //
  // There is:
  //
  // - no reschedule
  // - no lineup management
  // - no role-name authorization
  // - no fake "Coming soon" cancel button
  //
  // The row exists only when effective `match.cancel` evaluates to true.
  List<Widget> _manageSection() {
    if (!m.canCancelMatch) {
      return const [];
    }

    return [
      const _DetailSectionH('Manage'),
      Container(
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onAction(m.id, 'cancel'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                const PvIcon(
                  PvIcons.close,
                  size: 16,
                  color: CkColors.red,
                  sw: 1.8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancel match',
                    style: CkType.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: CkColors.red,
                    ),
                  ),
                ),
                const PvIcon(
                  PvIcons.next,
                  size: 14,
                  color: CkColors.soft,
                  sw: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _footerButton(_FooterAction f) {
    final fg =
        f.primary ? CkColors.paper : (f.danger ? CkColors.red : CkColors.ink);
    final bg =
        f.primary ? (f.danger ? CkColors.red : CkColors.ink) : CkColors.paper;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onAction(m.id, f.action),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: f.primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (f.icon != null) ...[
              PvIcon(f.icon!, size: 15, color: fg, sw: 2),
              const SizedBox(width: 7),
            ],
            Text(
              f.label,
              style: CkType.body(
                fontSize: 13.5,
                fontWeight: f.primary ? FontWeight.w700 : FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── shared detail bits ──

class _DetailSectionH extends StatelessWidget {
  const _DetailSectionH(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 9),
      child: Text(label, style: pvMono(10, color: CkColors.muted)),
    );
  }
}

/// Decorative cricket-ground motif drawn behind the live-match hero. Two
/// concentric ellipses (boundary + inner ring) in white at 8% opacity.
/// Design `pavilion-matches-v2.jsx:208` — an inline SVG, ported here as
/// CustomPaint so it costs nothing at runtime.
class _HeroEllipsePainter extends CustomPainter {
  const _HeroEllipsePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 180, height: 112),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 100, height: 60),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _KvCard extends StatelessWidget {
  const _KvCard({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top:
                      i == 0
                          ? BorderSide.none
                          : const BorderSide(color: CkColors.hairline),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      rows[i].$1.toUpperCase(),
                      style: pvMono(9.5, color: CkColors.muted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: CkType.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CkColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
