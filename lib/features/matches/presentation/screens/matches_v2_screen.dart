// Faithful Flutter port of the `V2Matches` screen from the matchday v2 design
// prototype (`design/app/screens/v2-IA.jsx`).
//
// PRESENTATION-ONLY, MOCK DATA. No Riverpod / backend / repositories — this is
// a 1:1 visual rebuild with inert affordances, mirroring the prototype. The
// only live interaction is the header bell (→ [onBell]) and the segmented
// sub-tab switcher.
//
// Colours / radii / type come from [CkColors] / [CkRadii] / [CkType]; shared
// atoms (Crest, Pill, V2Header, V2Svg, CkCrest, CkInk) come from the v2 kit.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// The base mono eyebrow style used across the prototype: JetBrains Mono
/// 0.10em uppercase muted. (`mono` in the JSX; `CkType.mono` defaults to the
/// looser 0.14em, so we pass 0.10 explicitly.)
TextStyle _mono({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = CkColors.muted,
}) => CkType.mono(
  fontSize: fontSize,
  fontWeight: fontWeight,
  letterSpacing: 0.10,
  color: color,
);

/// A mono caption that is NOT uppercased and has no tracking — used for the
/// "scoring · Imran S." / venue secondary lines (JSX overrides
/// `textTransform:none, letterSpacing:0, fontWeight:500`).
TextStyle _monoPlain({required double fontSize, Color color = CkColors.muted}) =>
    TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: color,
    );

class MatchesV2Screen extends StatefulWidget {
  const MatchesV2Screen({super.key, this.onBell});

  final VoidCallback? onBell;

  @override
  State<MatchesV2Screen> createState() => _MatchesV2ScreenState();
}

enum _MatchTab { live, upcoming, recent, browse }

class _MatchesV2ScreenState extends State<MatchesV2Screen> {
  _MatchTab _tab = _MatchTab.live;

  String get _sub => switch (_tab) {
    _MatchTab.live => '2 live · 5 today · across 1 tournament',
    _MatchTab.upcoming => 'Next 14 days · 5 fixtures',
    _MatchTab.recent => 'Last 30 days · 7 results',
    _MatchTab.browse => 'Tournaments you can follow, play, or organize',
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            V2Header(
              title: 'Matches',
              sub: _sub,
              notifCount: 3,
              onBell: widget.onBell,
            ),
            _MatchTabs(
              active: _tab,
              onChange: (t) => setState(() => _tab = t),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    // JSX scroll container padding: '4px 0 12px'.
    const pad = EdgeInsets.fromLTRB(0, 4, 0, 12);
    return switch (_tab) {
      _MatchTab.live => ListView(padding: pad, children: const [_LiveBody()]),
      _MatchTab.upcoming =>
        ListView(padding: pad, children: const [_UpcomingBody()]),
      _MatchTab.recent =>
        ListView(padding: pad, children: const [_RecentBody()]),
      _MatchTab.browse =>
        ListView(padding: pad, children: const [_BrowseBody()]),
    };
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Segmented sub-tab switcher
// ───────────────────────────────────────────────────────────────────────────

class _MatchTabs extends StatelessWidget {
  const _MatchTabs({required this.active, required this.onChange});

  final _MatchTab active;
  final ValueChanged<_MatchTab> onChange;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (_MatchTab.live, 'Live', '2', true, false),
      (_MatchTab.upcoming, 'Upcoming', '5', false, false),
      (_MatchTab.recent, 'Recent', '7', false, false),
      (_MatchTab.browse, 'Browse', '∞', false, true),
    ];
    return Padding(
      // JSX: padding '0 14px 10px'.
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          border: Border.all(color: CkColors.hairline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, t) in tabs.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                _TabItem(
                  label: t.$2,
                  count: t.$3,
                  isRed: t.$4,
                  hasNewDot: t.$5,
                  isActive: t.$1 == active,
                  onTap: () => onChange(t.$1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.count,
    required this.isRed,
    required this.hasNewDot,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String count;
  final bool isRed;
  final bool hasNewDot;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isRed && isActive ? CkColors.red : CkColors.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? CkColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    blurRadius: 3,
                    offset: Offset(0, 1),
                    // rgba(40,30,15,0.06)
                    color: Color(0x0F281E0F),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Content-sized (the tab bar is horizontally scrollable).
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: CkType.body(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? CkColors.ink : CkColors.muted,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive ? CkColors.paper2 : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                count,
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: badgeColor,
                ),
              ),
            ),
            if (hasNewDot && !isActive) ...[
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: CkColors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Shared subhead
// ───────────────────────────────────────────────────────────────────────────

class _Subhead extends StatelessWidget {
  const _Subhead(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // JSX: padding '14px 18px 8px'.
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Text(text.toUpperCase(), style: _mono(fontSize: 9.5)),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// LIVE body
// ───────────────────────────────────────────────────────────────────────────

class _LiveBody extends StatelessWidget {
  const _LiveBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Subhead("Spring Cup '26 · QF"),
          _LiveMatchCard(
            tournament: 'QF · MATCH 2',
            aShort: 'LL',
            aColor: CkCrest.ll,
            aName: 'Lahore Lions',
            aScore: '142/6 (20)',
            bShort: 'KC',
            bColor: CkCrest.kc,
            bName: 'Karachi Cobras',
            bScore: '119/9 (19.2)',
            need: 'L need 24 from 12 balls',
            rate: 'CRR 5.97  RRR 12.00',
          ),
          _Subhead('Sunday League'),
          _LiveMatchCard(
            tournament: 'GROUP A · R1',
            aShort: 'MT',
            aColor: CkCrest.mt,
            aName: 'Multan Tigers',
            aScore: '98/2 (12.4)',
            bShort: 'OB',
            bColor: CkCrest.ob,
            bName: 'Old Boys',
            bScore: '—',
            need: 'MT building a base',
            rate: 'CRR 7.74  Target —',
          ),
        ],
      ),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  const _LiveMatchCard({
    required this.tournament,
    required this.aShort,
    required this.aColor,
    required this.aName,
    required this.aScore,
    required this.bShort,
    required this.bColor,
    required this.bName,
    required this.bScore,
    required this.need,
    required this.rate,
  });

  final String tournament;
  final String aShort;
  final Color aColor;
  final String aName;
  final String aScore;
  final String bShort;
  final Color bColor;
  final String bName;
  final String bScore;
  final String need;
  final String rate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // JSX: '0 14px 12px'.
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CkColors.paper,
          border: Border.all(color: CkColors.hairline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row.
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Pill(label: 'LIVE', tone: PillTone.red),
                  const SizedBox(width: 8),
                  Text(tournament, style: _mono(fontSize: 9)),
                  const Spacer(),
                  Text(
                    'scoring · Imran S.',
                    style: _monoPlain(fontSize: 9),
                  ),
                ],
              ),
            ),
            // Team A.
            _TeamRow(
              short: aShort,
              color: aColor,
              name: aName,
              score: aScore,
              topHairline: false,
            ),
            // Team B (chasing — score in red).
            _TeamRow(
              short: bShort,
              color: bColor,
              name: bName,
              score: bScore,
              scoreColor: CkColors.red,
              topHairline: true,
            ),
            // Footer.
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CkColors.hairline)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          need,
                          style: CkType.body(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: CkColors.ink,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            rate,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: CkColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _WatchButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.short,
    required this.color,
    required this.name,
    required this.score,
    required this.topHairline,
    this.scoreColor = CkColors.ink,
  });

  final String short;
  final Color color;
  final String name;
  final String score;
  final bool topHairline;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    // First row: paddingBottom 8. Second row: paddingTop 4, paddingBottom 8.
    return Container(
      padding: EdgeInsets.only(top: topHairline ? 4 : 0, bottom: 8),
      decoration: topHairline
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: CkColors.hairline)),
            )
          : null,
      child: Row(
        children: [
          Crest(short: short, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  score,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
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

class _WatchButton extends StatelessWidget {
  const _WatchButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Watch',
          style: CkType.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: CkColors.paper,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// UPCOMING body
// ───────────────────────────────────────────────────────────────────────────

class _UpcomingBody extends StatelessWidget {
  const _UpcomingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Subhead('Today'),
          _UpcomingRow(
            when: '4:00 PM',
            aShort: 'LL',
            aColor: CkCrest.ll,
            bShort: 'KC',
            bColor: CkCrest.kc,
            ctx: 'Spring Cup · SF 1',
            venue: 'Gaddafi B',
          ),
          _UpcomingRow(
            when: '6:30 PM',
            aShort: 'MT',
            aColor: CkCrest.mt,
            bShort: 'OB',
            bColor: CkCrest.ob,
            ctx: 'Sunday League · R2',
            venue: 'Iqbal Park',
          ),
          _Subhead('This week'),
          _UpcomingRow(
            when: 'Sat 25 · 4 PM',
            aShort: 'LL',
            aColor: CkCrest.ll,
            bShort: 'MK',
            bColor: CkCrest.mk,
            ctx: 'Friendly',
            venue: 'Model Town',
          ),
          _UpcomingRow(
            when: 'Sun 26 · 7 AM',
            aShort: 'KE',
            aColor: CkCrest.ke,
            bShort: 'OB',
            bColor: CkCrest.ob,
            ctx: 'Friendly · T10',
            venue: 'Iqbal Park',
          ),
          _UpcomingRow(
            when: 'Wed 29 · 4 PM',
            aShort: 'SC',
            aColor: CkCrest.sc,
            bShort: 'SC',
            bColor: CkCrest.sc,
            ctx: 'Spring Cup · F',
            venue: 'Gaddafi B',
            isFinal: true,
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.when,
    required this.aShort,
    required this.aColor,
    required this.bShort,
    required this.bColor,
    required this.ctx,
    required this.venue,
    this.isFinal = false,
  });

  final String when;
  final String aShort;
  final Color aColor;
  final String bShort;
  final Color bColor;
  final String ctx;
  final String venue;
  final bool isFinal;

  @override
  Widget build(BuildContext context) {
    return Container(
      // JSX: margin '0 14px 8px'.
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left column.
            SizedBox(
              width: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    when,
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(venue, style: _monoPlain(fontSize: 9)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Vertical divider.
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: CkColors.hairline,
            ),
            const SizedBox(width: 10),
            // Middle: crests + vs + optional FINAL pill.
            Expanded(
              child: Row(
                children: [
                  Crest(short: aShort, color: aColor, size: 26, radius: 6),
                  const SizedBox(width: 6),
                  Text(
                    'vs',
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Crest(short: bShort, color: bColor, size: 26, radius: 6),
                  const Spacer(),
                  if (isFinal)
                    const Pill(label: 'FINAL', tone: PillTone.amber),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right: context.
            SizedBox(
              width: 70,
              child: Text(
                ctx.toUpperCase(),
                textAlign: TextAlign.right,
                style: _mono(fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// RECENT body
// ───────────────────────────────────────────────────────────────────────────

class _RecentBody extends StatelessWidget {
  const _RecentBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Subhead('Yesterday'),
          _RecentRow(
            aShort: 'LL',
            aColor: CkCrest.ll,
            bShort: 'MT',
            bColor: CkCrest.mt,
            aScore: '142/6',
            bScore: '119/9',
            result: 'Lions won by 23 runs',
            ctx: 'Spring Cup · R1',
          ),
          _Subhead('This week'),
          _RecentRow(
            aShort: 'KE',
            aColor: CkCrest.ke,
            bShort: 'MK',
            bColor: CkCrest.mk,
            aScore: '178/4',
            bScore: '142/9',
            result: 'Eagles won by 36 runs',
            ctx: 'Friendly · 20 ov',
          ),
          _RecentRow(
            aShort: 'OB',
            aColor: CkCrest.ob,
            bShort: 'KC',
            bColor: CkCrest.kc,
            aScore: '108',
            bScore: '111/4',
            result: 'Cobras won by 6 wkts',
            ctx: 'Sunday League',
          ),
          _Subhead('Earlier'),
          _RecentRow(
            aShort: 'MT',
            aColor: CkCrest.mt,
            bShort: 'LL',
            bColor: CkCrest.ll,
            aScore: '156/8',
            bScore: '159/6',
            result: 'Lions won by 4 wkts',
            ctx: 'Friendly',
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.aShort,
    required this.aColor,
    required this.bShort,
    required this.bColor,
    required this.aScore,
    required this.bScore,
    required this.result,
    required this.ctx,
  });

  final String aShort;
  final Color aColor;
  final String bShort;
  final Color bColor;
  final String aScore;
  final String bScore;
  final String result;
  final String ctx;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score row.
          Row(
            children: [
              Crest(short: aShort, color: aColor, size: 26, radius: 6),
              const SizedBox(width: 10),
              Text(aScore, style: _score(CkColors.ink)),
              const Spacer(),
              Text(bScore, style: _score(CkColors.muted)),
              const SizedBox(width: 10),
              Crest(short: bShort, color: bColor, size: 26, radius: 6),
            ],
          ),
          const SizedBox(height: 8),
          // Result row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result,
                style: CkType.body(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
              const Spacer(),
              Text(ctx.toUpperCase(), style: _mono(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _score(Color color) => TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: color,
  );
}

// ───────────────────────────────────────────────────────────────────────────
// BROWSE body
// ───────────────────────────────────────────────────────────────────────────

class _BrowseBody extends StatelessWidget {
  const _BrowseBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter chips row (horizontally scrollable).
        Padding(
          // JSX: padding '4px 18px 12px'.
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, label) in const [
                  'Following',
                  'Playing',
                  'Organizing',
                  'Near you',
                  'Featured',
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _FilterChip(label: label, active: i == 0),
                ],
              ],
            ),
          ),
        ),
        // Featured hero.
        const _FeaturedHero(),
        const _Subhead('Following · 2'),
        const _TourneyRow(
          short: 'SC',
          color: CkCrest.sc,
          name: "Spring Cup '26",
          meta: 'QF · 4 matches left',
          live: true,
        ),
        const _TourneyRow(
          short: 'SL',
          // oklch(0.42 0.10 260) — deep indigo (same family as KC).
          color: Color(0xFF2E3E63),
          name: "Sunday League '26",
          meta: 'R1 · 24 matches scheduled',
        ),
        const _Subhead('Playing · 1'),
        const _TourneyRow(
          short: 'SC',
          color: CkCrest.sc,
          name: "Spring Cup '26",
          meta: 'You · Lahore Lions · seeded #3',
          role: 'PLAYING',
        ),
        const _Subhead('Organizing · 1'),
        const _TourneyRow(
          short: 'IF',
          // oklch(0.55 0.13 80) — warm olive/amber-brown.
          color: Color(0xFF8A6A1E),
          name: 'Iqbal Park Festival',
          meta: 'Registration opens Mon',
          role: 'DRAFT',
        ),
        const _Subhead('Near you · Karachi'),
        const _TourneyRow(
          short: 'KT',
          // oklch(0.45 0.12 250) — blue.
          color: Color(0xFF2F4C84),
          name: 'Karachi T20 Open',
          meta: '32 teams · prize ₨ 50k',
        ),
        const _TourneyRow(
          short: 'KC',
          // oklch(0.42 0.10 260) — deep indigo.
          color: Color(0xFF2E3E63),
          name: 'Korangi Cup',
          meta: '16 teams · tape ball',
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: active ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.10,
          color: active ? CkColors.paper : CkColors.ink2,
        ),
      ),
    );
  }
}

class _FeaturedHero extends StatelessWidget {
  const _FeaturedHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // JSX: padding '0 18px 14px'.
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          color: CkColors.ink,
          child: Stack(
            children: [
              // Decorative pitch ellipses, top-right, very faint.
              Positioned(
                right: -110,
                top: -90,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.08,
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: _EllipsePainter(),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Pill(label: 'FEATURED · LIVE', tone: PillTone.red),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "Spring Cup '26",
                      style: CkType.display(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '8 teams · Karachi · 14–25 May · QF in progress',
                      style: CkType.body(
                        fontSize: 12,
                        // rgba(255,255,255,0.7)
                        color: const Color(0xB3FFFFFF),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _HeroButton(
                            label: 'See bracket',
                            background: CkColors.paper,
                            foreground: CkColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _HeroButton(
                            label: 'Follow',
                            background: Colors.transparent,
                            foreground: CkColors.paper,
                            fontWeight: FontWeight.w600,
                            // rgba(255,255,255,0.3)
                            border: Color(0x4DFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EllipsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0 0 200 200 scaled to 260; stroke-width 0.8 in viewBox units.
    final scale = size.width / 200;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 0.8 * scale;
    final c = Offset(100 * scale, 100 * scale);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 184 * scale, height: 120 * scale),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 110 * scale, height: 70 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.fontWeight,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final FontWeight fontWeight;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border != null ? Border.all(color: border!) : null,
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 12.5,
            fontWeight: fontWeight,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _TourneyRow extends StatelessWidget {
  const _TourneyRow({
    required this.short,
    required this.color,
    required this.name,
    required this.meta,
    this.role,
    this.live = false,
  });

  final String short;
  final Color color;
  final String name;
  final String meta;
  final String? role;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Crest(short: short, color: color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (live) ...[
                      const SizedBox(width: 6),
                      const Pill(label: 'LIVE', tone: PillTone.red),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    meta,
                    style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                  ),
                ),
              ],
            ),
          ),
          if (role != null) ...[
            const SizedBox(width: 8),
            Pill(label: role!, tone: PillTone.neutral),
          ],
          const SizedBox(width: 8),
          const V2Svg(V2Icons.chevronRight, size: 14, color: CkColors.muted),
        ],
      ),
    );
  }
}
