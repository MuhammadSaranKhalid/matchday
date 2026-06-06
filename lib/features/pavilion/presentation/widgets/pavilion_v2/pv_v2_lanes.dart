// Pavilion v2 — the three segment lanes + the Today overview hero.
//
// Faithful port of `pavilion-parts.jsx` (Overview / TeamsLane / ToursLane) and
// the v2 status-only matches list from `pavilion-matches-v2.jsx`.
import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'pv_v2_data.dart';
import 'pv_v2_kit.dart';

/// The three workspace segments.
enum PvSeg { matches, teams, tournaments }

extension PvSegX on PvSeg {
  String get label => switch (this) {
        PvSeg.matches => 'Matches',
        PvSeg.teams => 'Teams',
        PvSeg.tournaments => 'Tournaments',
      };
  String get createLabel => switch (this) {
        PvSeg.matches => 'Schedule match',
        PvSeg.teams => 'Create team',
        PvSeg.tournaments => 'Create tournament',
      };
}

/// phase → (pill label, tone, live).
(String, PvTone, bool) pvPhaseConf(PvPhase p) => switch (p) {
      PvPhase.live => ('LIVE', PvTone.red, true),
      PvPhase.startsSoon => ('STARTS SOON', PvTone.amber, false),
      PvPhase.scheduled => ('SCHEDULED', PvTone.neutral, false),
      PvPhase.awaitingReply => ('AWAITING REPLY', PvTone.amber, false),
      PvPhase.completed => ('FINAL', PvTone.neutral, false),
    };

// ═══════════════════════════════════════════════════════════════════════════
// Overview — the "Today" hero + actionable chips (Matches segment only)
// ═══════════════════════════════════════════════════════════════════════════

class PvOverview extends StatelessWidget {
  const PvOverview({
    super.key,
    required this.matches,
    required this.tournaments,
    required this.onAction,
    required this.onSegment,
    required this.onOpenMatch,
  });

  final List<PvMatch> matches;
  final List<PvTournament> tournaments;
  final void Function(String id, String action) onAction;
  final void Function(PvSeg seg) onSegment;
  final void Function(String id) onOpenMatch;

  @override
  Widget build(BuildContext context) {
    final liveList = matches.where((m) => m.phase == PvPhase.live);
    final soonList = matches.where((m) => m.phase == PvPhase.startsSoon);
    final live = liveList.isEmpty ? null : liveList.first;
    final soon = soonList.isEmpty ? null : soonList.first;
    final hero = live ?? soon;
    final isLive = live != null;

    // Squad-invite / lineup-gap chips have no backend yet; the actionable
    // chips wired here are awaiting-challenges (real) + tournament fixture gaps.
    final awaiting = matches.where((m) => m.phase == PvPhase.awaitingReply).length;
    final tourGaps = tournaments.fold<int>(0, (s, t) => s + t.needs);

    final chips = <(String, PvSeg)>[
      if (awaiting > 0) ('$awaiting challenge${awaiting > 1 ? 's' : ''} awaiting', PvSeg.matches),
      if (tourGaps > 0) ('$tourGaps fixtures to schedule', PvSeg.tournaments),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PvSecLabel('TODAY'),
          if (hero != null)
            _Hero(
                m: hero, isLive: isLive, onAction: onAction, onOpen: onOpenMatch)
          else
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CkColors.line),
              ),
              child: Text(
                'Nothing live today. Schedule a friendly or check your fixtures below.',
                style: CkType.body(fontSize: 12.5, height: 1.5, color: CkColors.ink2),
              ),
            ),
          if (chips.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _Chip(label: chips[i].$1, onTap: () => onSegment(chips[i].$2)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.m,
    required this.isLive,
    required this.onAction,
    required this.onOpen,
  });

  final PvMatch m;
  final bool isLive;
  final void Function(String id, String action) onAction;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    // Tapping the card body opens the Match Detail page (the hero match is
    // hidden from the list below, so this is its only path to detail). The CTA
    // button stays the one-tap shortcut to the urgent action (start / resume) —
    // a nested GestureDetector, so it wins taps on itself.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpen(m.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              PvDot(color: CkColors.red, size: 6, pulse: isLive),
              const SizedBox(width: 8),
              Text(isLive ? 'LIVE NOW' : 'STARTS SOON',
                  style: pvMono(9, color: Colors.white).copyWith(
                      color: Colors.white.withValues(alpha: 0.85))),
              const Spacer(),
              Text(m.when,
                  style: pvMono(9).copyWith(color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Crest(
                  short: m.them.short,
                  color: m.them.color,
                  logoUrl: m.them.logoUrl,
                  size: 42,
                  radius: 11),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${m.me.short} vs ${m.them.short}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('${m.sub} · ${m.venue}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.body(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7))),
                    ),
                  ],
                ),
              ),
              if (m.scoreA != null) ...[
                const SizedBox(width: 8),
                Text(m.scoreA!,
                    style: CkType.mono(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _HeroCta(isLive: isLive, onTap: () => onAction(m.id, isLive ? 'resume' : 'start')),
        ],
      ),
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta({required this.isLive, required this.onTap});
  final bool isLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isLive ? CkColors.red : CkColors.paper;
    final fg = isLive ? CkColors.paper : CkColors.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PvIcon(isLive ? PvIcons.whistle : PvIcons.play, size: 16, color: fg, sw: 2),
            const SizedBox(width: 7),
            Text(isLive ? 'Resume scoring' : 'Start match',
                style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PvDot(color: CkColors.amber, size: 6),
            const SizedBox(width: 7),
            Text(label,
                style: CkType.body(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 7),
            const PvIcon(PvIcons.next, size: 13, color: CkColors.muted, sw: 2),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Matches lane — status-only cards, grouped UPCOMING / PLAYED
// ═══════════════════════════════════════════════════════════════════════════

class PvMatchesLane extends StatelessWidget {
  const PvMatchesLane({
    super.key,
    required this.matches,
    required this.onOpen,
    this.hideIds = const {},
  });

  final List<PvMatch> matches;
  final void Function(PvMatch) onOpen;
  final Set<String> hideIds;

  @override
  Widget build(BuildContext context) {
    const up = {PvPhase.live, PvPhase.startsSoon, PvPhase.scheduled, PvPhase.awaitingReply};
    final upcoming =
        matches.where((m) => up.contains(m.phase) && !hideIds.contains(m.id)).toList();
    final past = matches.where((m) => m.phase == PvPhase.completed).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PvSecLabel(upcoming.isNotEmpty ? 'UPCOMING · ${upcoming.length}' : 'UPCOMING'),
          if (upcoming.isEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Everything upcoming is up top. Schedule another with ＋.',
                  style: CkType.body(fontSize: 12.5, color: CkColors.ink2)),
            ),
          for (final m in upcoming) PvMatchCard(m: m, onOpen: onOpen),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 6),
            PvSecLabel('PLAYED · ${past.length}'),
            for (final m in past) PvMatchCard(m: m, onOpen: onOpen),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Status-only match card — no buttons, clear chevron + press state.
class PvMatchCard extends StatefulWidget {
  const PvMatchCard({super.key, required this.m, required this.onOpen});
  final PvMatch m;
  final void Function(PvMatch) onOpen;

  @override
  State<PvMatchCard> createState() => _PvMatchCardState();
}

class _PvMatchCardState extends State<PvMatchCard> {
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final (label, tone, live) = pvPhaseConf(m.phase);
    final showScore = m.phase == PvPhase.live || m.phase == PvPhase.completed;
    final lineupGap = m.lineupSet == false &&
        (m.phase == PvPhase.scheduled || m.phase == PvPhase.startsSoon);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _press = true),
      onTapUp: (_) => setState(() => _press = false),
      onTapCancel: () => setState(() => _press = false),
      onTap: () => widget.onOpen(m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        decoration: BoxDecoration(
          color: _press ? CkColors.paper2 : CkColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                PvPill(label, tone: tone, live: live),
                if (lineupGap) ...[
                  const SizedBox(width: 8),
                  Text('LINEUP NOT SET', style: pvMono(9, color: CkInk.amber)),
                ],
                const Spacer(),
                Text(m.when, style: pvMono(9, color: CkColors.muted)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Crest(
                    short: m.them.short,
                    color: m.them.color,
                    logoUrl: m.them.logoUrl,
                    size: 40,
                    radius: 11),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text('${m.me.short} vs ${m.them.short}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CkType.display(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                          if (m.result != null) ...[
                            const SizedBox(width: 6),
                            _ResultTag(won: m.result == 'W'),
                          ],
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                            [m.sub, m.venue].where((s) => s.isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.body(fontSize: 11.5, color: CkColors.muted)),
                      ),
                    ],
                  ),
                ),
                if (showScore) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.scoreA ?? '',
                          style: CkType.mono(
                              fontSize: 14, fontWeight: FontWeight.w700, color: CkColors.ink)),
                      if (m.scoreB != null && m.scoreB != '—')
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(m.scoreB!,
                              style: CkType.mono(fontSize: 11, color: CkColors.muted)),
                        ),
                    ],
                  ),
                ],
                SizedBox(width: showScore ? 4 : 0),
                const PvIcon(PvIcons.next, size: 16, color: CkColors.soft, sw: 2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTag extends StatelessWidget {
  const _ResultTag({required this.won});
  final bool won;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: won ? CkColors.greenSoft : CkColors.paper2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(won ? 'WON' : 'LOST',
          style: pvMono(9, color: won ? CkInk.green : CkColors.muted)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Teams lane
// ═══════════════════════════════════════════════════════════════════════════

class PvTeamsLane extends StatelessWidget {
  const PvTeamsLane({
    super.key,
    required this.teams,
    required this.onOpen,
    required this.onResolve,
  });

  final List<PvTeam> teams;
  final void Function(PvTeam) onOpen;
  final void Function(PvTeam, String need) onResolve;

  static (String, PvTone) _role(String role) => switch (role) {
        'captain' => ('CAPTAIN', PvTone.amber),
        'owner' => ('OWNER', PvTone.green),
        _ => ('PLAYER', PvTone.neutral),
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PvSecLabel('YOUR TEAMS · ${teams.length}'),
          for (final t in teams) _teamCard(t),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _teamCard(PvTeam t) {
    final c = t.crest;
    final (roleLabel, roleTone) = _role(t.role);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Crest(
                      short: c.short,
                      color: c.color,
                      logoUrl: c.logoUrl,
                      size: 44,
                      radius: 11),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CkType.display(
                                      fontSize: 15.5, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                            PvPill(roleLabel, tone: roleTone),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(t.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CkType.body(fontSize: 11.5, color: CkColors.muted)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const PvIcon(PvIcons.next, size: 16, color: CkColors.muted, sw: 2),
                ],
              ),
            ),
          ),
          if (t.needs.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: CkColors.paper2,
                border: Border(top: BorderSide(color: CkColors.hairline)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < t.needs.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    _needRow(t.needs[i], () => onResolve(t, t.needs[i]), fix: true),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A need/gap row inside a team or tournament card footer.
Widget _needRow(String text, VoidCallback onTap, {required bool fix}) {
  return Row(
    children: [
      const PvDot(color: CkColors.amber, size: 5),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: CkType.body(fontSize: 12, color: CkColors.ink2)),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: fix ? 8 : 9, vertical: fix ? 4 : 5),
          decoration: BoxDecoration(
            color: fix ? CkColors.paper : CkColors.ink,
            borderRadius: BorderRadius.circular(7),
            border: fix ? Border.all(color: CkColors.hairline) : null,
          ),
          child: Text(fix ? 'FIX' : 'SCHEDULE',
              style: pvMono(9, color: fix ? CkColors.ink : CkColors.paper)),
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Tournaments lane
// ═══════════════════════════════════════════════════════════════════════════

class PvToursLane extends StatelessWidget {
  const PvToursLane({
    super.key,
    required this.tournaments,
    required this.onOpen,
    required this.onSchedule,
  });

  final List<PvTournament> tournaments;
  final void Function(PvTournament) onOpen;
  final void Function(PvTournament) onSchedule;

  @override
  Widget build(BuildContext context) {
    final org = tournaments.where((t) => t.kind == PvTourKind.organizing).toList();
    final play = tournaments.where((t) => t.kind == PvTourKind.playing).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PvSecLabel('ORGANIZING · ${org.length}'),
          for (final t in org) _tourCard(t),
          if (play.isNotEmpty) ...[
            const SizedBox(height: 6),
            PvSecLabel('PLAYING · ${play.length}'),
            for (final t in play) _tourCard(t),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _tourCard(PvTournament t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const PvIcon(PvIcons.trophy, size: 20, color: CkColors.paper, sw: 1.8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.display(fontSize: 15.5, fontWeight: FontWeight.w700)),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('${t.format} · ${t.stage}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CkType.body(fontSize: 11.5, color: CkColors.muted)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: t.progress,
                              minHeight: 4,
                              backgroundColor: CkColors.paper2,
                              valueColor: AlwaysStoppedAnimation(t.color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const PvIcon(PvIcons.next, size: 16, color: CkColors.muted, sw: 2),
                ],
              ),
            ),
          ),
          if (t.needs > 0)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: CkColors.paper2,
                border: Border(top: BorderSide(color: CkColors.hairline)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: _needRow(t.sub, () => onSchedule(t), fix: false),
            ),
        ],
      ),
    );
  }
}
