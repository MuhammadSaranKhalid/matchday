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
import 'pv_v2_lanes.dart' show pvPhaseConf;

class _FooterAction {
  const _FooterAction(this.action, this.label,
      {this.primary = false, this.icon, this.danger = false});
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

    final (String headline, String subline) = live
        ? (m.scoreA ?? 'In play', '${m.when} · ${m.venue}')
        : done
            ? (m.sub, '${m.when} · ${m.venue}')
            : (m.when, m.venue);

    // Only actions with a real backend/route survive (message / reschedule /
    // cancel / share are dropped — no backend).
    final footer = <_FooterAction>[
      if (live)
        const _FooterAction('resume', 'Resume scoring',
            primary: true, icon: PvIcons.whistle, danger: true)
      else if (m.phase == PvPhase.startsSoon) ...[
        if (m.lineupSet == false)
          const _FooterAction('lineup', 'Set lineup', icon: PvIcons.users),
        const _FooterAction('start', 'Start match', primary: true, icon: PvIcons.play),
      ] else if (m.phase == PvPhase.scheduled)
        _FooterAction(
          m.lineupSet == false ? 'lineup' : 'viewlineup',
          m.lineupSet == false ? 'Set lineup' : 'View lineup',
          primary: true,
          icon: PvIcons.users,
        )
      else if (awaiting)
        const _FooterAction('withdraw', 'Withdraw challenge',
            primary: true, icon: PvIcons.close, danger: true)
      else if (done)
        const _FooterAction('scorecard', 'View scorecard',
            primary: true, icon: PvIcons.ticket),
    ];

    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  _hero(live: live, done: done, headline: headline, subline: subline),
                  if (done) _completedScore(),
                  const _DetailSectionH('Match spec'),
                  _KvCard(rows: [
                    ('Format', 'T20 · 11-a-side'),
                    ('Overs', '20 · 6-ball'),
                    ('Ball', 'Tape'),
                    ('Venue', m.venue),
                    ('When', m.when),
                  ]),
                  if (!done && !awaiting) ...[
                    _DetailSectionH('Squad & lineup',
                        side: m.lineupSet == false ? 'not set' : 'XI locked'),
                    _squad(),
                  ],
                  if (!awaiting) ...[
                    const _DetailSectionH('Head to head'),
                    _headToHead(),
                  ],
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

  // ── top bar ──
  Widget _topBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PvIcon(PvIcons.back, size: 18, color: CkColors.ink, sw: 2),
                    const SizedBox(width: 4),
                    Text('Pavilion',
                        style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Text('MATCH', style: pvMono(9, color: CkColors.muted)),
            const Padding(
              padding: EdgeInsets.all(6),
              child: PvIcon(PvIcons.dots, size: 18, color: CkColors.ink2, sw: 2),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: live ? CkColors.ink : CkColors.paper2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Center(child: PvPill(label, tone: tone, live: isLive)),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroSide(m.me, 'you · ${m.role}', live: live, fg: fg, mutedFg: mutedFg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: PvIcon(PvIcons.swords,
                    size: 20,
                    color: live ? Colors.white.withValues(alpha: 0.5) : CkColors.muted,
                    sw: 2),
              ),
              _heroSide(m.them, 'opponent', live: live, fg: fg, mutedFg: mutedFg),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: live ? Colors.white.withValues(alpha: 0.14) : CkColors.hairline),
              ),
            ),
            child: Column(
              children: [
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: (live || done)
                      ? CkType.mono(
                          fontSize: live ? 26 : 18,
                          fontWeight: FontWeight.w700,
                          color: fg)
                      : CkType.display(
                          fontSize: 18, fontWeight: FontWeight.w700, color: fg),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(subline,
                      textAlign: TextAlign.center,
                      style: CkType.body(
                          fontSize: 12,
                          color: live ? Colors.white.withValues(alpha: 0.7) : CkColors.muted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSide(PvCrest c, String role,
      {required bool live, required Color fg, required Color mutedFg}) {
    return Expanded(
      child: Column(
        children: [
          Crest(
              short: c.short,
              color: c.color,
              logoUrl: c.logoUrl,
              size: 52,
              radius: 14),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.display(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(role, style: CkType.body(fontSize: 10.5, color: mutedFg)),
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
                Text('$short${win ? ' · WON' : ''}', style: pvMono(9, color: CkColors.muted)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(score ?? '',
                      style: CkType.mono(
                          fontSize: 18, fontWeight: FontWeight.w700, color: CkColors.ink)),
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

  // ── squad & lineup ──
  Widget _squad() {
    final rsvpYes = m.phase == PvPhase.startsSoon ? 11 : 9;
    const stack = [
      ('BA', null),
      ('AS', Color(0xFF8A8F98)),
      ('FK', Color(0xFFB0784A)),
      ('HT', Color(0xFF5A7D52)),
    ];
    Widget chip(String mono, Color bg, Color fg, bool monoFont) => Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: CkColors.paper, width: 2),
          ),
          child: Text(mono,
              style: (monoFont
                      ? CkType.mono(fontSize: 9, fontWeight: FontWeight.w700, color: fg)
                      : CkType.display(fontSize: 9, fontWeight: FontWeight.w700, color: fg))),
        );
    // Overlapping avatar cluster. Flutter forbids negative margins, so the
    // design's -10px overlap is rebuilt with a Stack: 28px chips on an 18px
    // step. Later children paint on top, matching the design's z-order.
    const step = 18.0;
    final count = stack.length + 1; // avatars + the "+N" chip
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: (count - 1) * step + 28,
            height: 28,
            child: Stack(
              children: [
                for (var i = 0; i < stack.length; i++)
                  Positioned(
                    left: i * step,
                    child: chip(stack[i].$1, stack[i].$2 ?? m.me.color, CkColors.paper, false),
                  ),
                Positioned(
                  left: stack.length * step,
                  child: chip('+${rsvpYes - 4}', CkColors.paper2, CkColors.ink2, true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$rsvpYes of 11 confirmed',
                    style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(m.lineupSet == false ? 'Lineup not set yet' : 'Your XI is locked',
                      style: CkType.body(fontSize: 11, color: CkColors.muted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── head to head ──
  Widget _headToHead() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: '3',
                  style: CkType.display(fontSize: 22, fontWeight: FontWeight.w700)),
              TextSpan(text: ' – ', style: CkType.body(fontSize: 13, color: CkColors.muted)),
              TextSpan(
                  text: '2',
                  style: CkType.display(fontSize: 22, fontWeight: FontWeight.w700)),
            ])),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: CkType.body(fontSize: 11.5, height: 1.5, color: CkColors.muted),
                  children: [
                    const TextSpan(text: '5 meetings · last: '),
                    TextSpan(
                        text: '${m.me.short} won by 12',
                        style: CkType.body(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: CkColors.ink2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

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

  Widget _footerButton(_FooterAction f) {
    final fg = f.primary ? CkColors.paper : (f.danger ? CkColors.red : CkColors.ink);
    final bg = f.primary ? (f.danger ? CkColors.red : CkColors.ink) : CkColors.paper;
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
            Text(f.label,
                style: CkType.body(
                    fontSize: 13.5,
                    fontWeight: f.primary ? FontWeight.w700 : FontWeight.w600,
                    color: fg)),
          ],
        ),
      ),
    );
  }
}

// ── shared detail bits ──

class _DetailSectionH extends StatelessWidget {
  const _DetailSectionH(this.label, {this.side});
  final String label;
  final String? side;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: pvMono(10, color: CkColors.muted)),
          if (side != null)
            Text(side!, style: CkType.body(fontSize: 11, color: CkColors.muted)),
        ],
      ),
    );
  }
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
                  top: i == 0 ? BorderSide.none : const BorderSide(color: CkColors.hairline),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(rows[i].$1.toUpperCase(), style: pvMono(9.5, color: CkColors.muted)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(rows[i].$2,
                        textAlign: TextAlign.right,
                        style: CkType.body(
                            fontSize: 13, fontWeight: FontWeight.w500, color: CkColors.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
