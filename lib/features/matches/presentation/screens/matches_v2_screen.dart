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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../providers/matches_feed_providers.dart';

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

String _teamShort(dynamic team) {
  if (team == null) return 'TM';
  if (team.logoMonogram != null && (team.logoMonogram as String).isNotEmpty) {
    return team.logoMonogram as String;
  }
  final name = team.name as String? ?? '';
  if (name.length >= 2) {
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
  return name.toUpperCase();
}

Color _teamColor(dynamic team) {
  if (team == null || team.primaryColor == null) return CkColors.red;
  final hex = (team.primaryColor as String).replaceAll('#', '');
  final val = int.tryParse(hex, radix: 16);
  if (val == null) return CkColors.red;
  return Color(0xFF000000 | val);
}

class MatchesV2Screen extends ConsumerStatefulWidget {
  const MatchesV2Screen({super.key, this.onBell});

  final VoidCallback? onBell;

  @override
  ConsumerState<MatchesV2Screen> createState() => _MatchesV2ScreenState();
}

enum _MatchTab { live, upcoming, recent, browse }

class _MatchesV2ScreenState extends ConsumerState<MatchesV2Screen> {
  _MatchTab _tab = _MatchTab.live;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(matchesFeedProvider);

    return ColoredBox(
      color: CkColors.paper,
      child: Column(
        children: [
          _MatchTabs(
            active: _tab,
            feedState: feedAsync.value,
            onChange: (t) => setState(() => _tab = t),
          ),
          Expanded(
            child: RefreshIndicator(
              color: CkColors.ink,
              backgroundColor: CkColors.paper,
              onRefresh: () async {
                ref.invalidate(matchesFeedProvider);
              },
              child: switch (feedAsync) {
                AsyncData(:final value) => _bodyFor(value),
                AsyncError() => ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Text(
                          'Failed to load matches feed',
                          style: CkType.body(fontSize: 13, color: CkColors.muted),
                        ),
                      ),
                    ],
                  ),
                _ => const Center(
                    child: CircularProgressIndicator(color: CkColors.ink),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyFor(MatchesFeedState state) {
    const pad = EdgeInsets.fromLTRB(0, 4, 0, 12);
    return switch (_tab) {
      _MatchTab.live => ListView(
          padding: pad,
          children: [_LiveBody(items: state.live)],
        ),
      _MatchTab.upcoming => ListView(
          padding: pad,
          children: [_UpcomingBody(items: state.upcoming)],
        ),
      _MatchTab.recent => ListView(
          padding: pad,
          children: [_RecentBody(items: state.recent)],
        ),
      _MatchTab.browse => ListView(
          padding: pad,
          children: [_BrowseBody(poolItems: state.openPool)],
        ),
    };
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Segmented sub-tab switcher
// ───────────────────────────────────────────────────────────────────────────

class _MatchTabs extends StatelessWidget {
  const _MatchTabs({
    required this.active,
    required this.onChange,
    this.feedState,
  });

  final _MatchTab active;
  final ValueChanged<_MatchTab> onChange;
  final MatchesFeedState? feedState;

  @override
  Widget build(BuildContext context) {
    final liveCount = feedState?.liveCount ?? 0;
    final upcomingCount = feedState?.upcomingCount ?? 0;
    final recentCount = feedState?.recentCount ?? 0;
    final poolCount = feedState?.poolCount ?? 0;

    final tabs = [
      (_MatchTab.live, 'Live', '$liveCount', true, false),
      (_MatchTab.upcoming, 'Upcoming', '$upcomingCount', false, false),
      (_MatchTab.recent, 'Recent', '$recentCount', false, false),
      (_MatchTab.browse, 'Browse', poolCount > 0 ? '$poolCount' : '∞', false, poolCount > 0),
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
  const _LiveBody({this.items = const []});

  final List<PublicLiveMatchItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NO LIVE MATCHES',
                style: _mono(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Matches currently in progress or toss will show here.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12.5, color: CkColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Subhead('In Progress'),
          for (final item in items)
            _LiveMatchCard(
              matchId: item.match.id.value,
              tournament: item.match.format.oversPerInnings > 0
                  ? '${item.match.format.oversPerInnings} OVERS · ${item.match.format.ballType.wire.toUpperCase()}'
                  : 'FRIENDLY MATCH',
              aShort: _teamShort(item.teamA),
              aColor: _teamColor(item.teamA),
              aName: item.teamA?.name ?? 'Team A',
              aScore: item.scoreA,
              bShort: _teamShort(item.teamB),
              bColor: _teamColor(item.teamB),
              bName: item.teamB?.name ?? 'Team B',
              bScore: item.scoreB,
              need: item.need,
              rate: item.rate,
              scorer: item.scorerName ?? 'Matchday Scorer',
            ),
        ],
      ),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  const _LiveMatchCard({
    required this.matchId,
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
    required this.scorer,
  });

  final String matchId;
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
  final String scorer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // JSX: '0 14px 12px'.
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GestureDetector(
        onTap: () {
          context.push('/matches/$matchId/scoring');
        },
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
                      'scoring · $scorer',
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
                    _WatchButton(matchId: matchId),
                  ],
                ),
              ),
            ],
          ),
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
  const _WatchButton({required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/matches/$matchId/scoring');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Score / Watch',
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
  const _UpcomingBody({this.items = const []});

  final List<PublicUpcomingMatchItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NO UPCOMING FIXTURES',
                style: _mono(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirmed upcoming matches will appear here.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12.5, color: CkColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    final today = items.where((i) => i.isToday).toList();
    final later = items.where((i) => !i.isToday).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (today.isNotEmpty) ...[
            const _Subhead('Today'),
            for (final item in today)
              _UpcomingRow(
                matchId: item.match.id.value,
                when: item.whenFormatted,
                aShort: _teamShort(item.teamA),
                aColor: _teamColor(item.teamA),
                bShort: _teamShort(item.teamB),
                bColor: _teamColor(item.teamB),
                ctx: item.contextLabel,
                venue: item.venue,
              ),
          ],
          if (later.isNotEmpty) ...[
            const _Subhead('Upcoming'),
            for (final item in later)
              _UpcomingRow(
                matchId: item.match.id.value,
                when: item.whenFormatted,
                aShort: _teamShort(item.teamA),
                aColor: _teamColor(item.teamA),
                bShort: _teamShort(item.teamB),
                bColor: _teamColor(item.teamB),
                ctx: item.contextLabel,
                venue: item.venue,
              ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.matchId,
    required this.when,
    required this.aShort,
    required this.aColor,
    required this.bShort,
    required this.bColor,
    required this.ctx,
    required this.venue,
  });

  final String matchId;
  final String when;
  final String aShort;
  final Color aColor;
  final String bShort;
  final Color bColor;
  final String ctx;
  final String venue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/matches/$matchId/start');
      },
      child: Container(
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
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// RECENT body
// ───────────────────────────────────────────────────────────────────────────

class _RecentBody extends StatelessWidget {
  const _RecentBody({this.items = const []});

  final List<PublicRecentMatchItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NO RECENT MATCHES',
                style: _mono(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Completed match scorecards will appear here.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12.5, color: CkColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Subhead('Completed Matches'),
          for (final item in items)
            _RecentRow(
              matchId: item.match.id.value,
              aShort: _teamShort(item.teamA),
              aColor: _teamColor(item.teamA),
              bShort: _teamShort(item.teamB),
              bColor: _teamColor(item.teamB),
              aScore: item.scoreA,
              bScore: item.scoreB,
              result: item.resultSummary,
              ctx: item.contextLabel,
            ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.matchId,
    required this.aShort,
    required this.aColor,
    required this.bShort,
    required this.bColor,
    required this.aScore,
    required this.bScore,
    required this.result,
    required this.ctx,
  });

  final String matchId;
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
    return GestureDetector(
      onTap: () {
        context.push('/matches/$matchId/scoring');
      },
      child: Container(
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
  const _BrowseBody({this.poolItems = const []});

  final List<OpenMatchPoolItem> poolItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Open Challenge Matchmaking banner & quick code entry
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Pill(label: 'OPEN POOL', tone: PillTone.green),
                    const SizedBox(width: 8),
                    Text('CHALLENGE MATCHMAKING', style: _mono(fontSize: 9.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Join an open match challenge or accept an opponent\'s 6-digit share code.',
                  style: CkType.body(fontSize: 12.5, color: CkColors.ink2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/matches/send-challenge');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: CkColors.ink,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '+ Post Open Challenge',
                            style: CkType.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CkColors.paper,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/matches/pool');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: CkColors.paper,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: CkColors.hairline),
                          ),
                          child: Text(
                            'Open Match Pool →',
                            style: CkType.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CkColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (poolItems.isNotEmpty) ...[
          const _Subhead('Open Challenges'),
          for (final item in poolItems)
            GestureDetector(
              onTap: () {
                context.push('/challenges/${item.request.id.value}');
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  border: Border.all(color: CkColors.hairline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Crest(
                      short: _teamShort(item.fromTeam),
                      color: _teamColor(item.fromTeam),
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.fromTeam?.name ?? 'Open Challenger',
                            style: CkType.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${item.formatLabel} · ${item.venue}',
                              style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: CkColors.paper2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      child: Text(
                        item.shareCode,
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.14,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],

        // Filter chips row (horizontally scrollable).
        Padding(
          // JSX: padding '4px 18px 12px'.
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, label) in const [
                  'Tournaments',
                  'Following',
                  'Playing',
                  'Organizing',
                  'Near you',
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
        const _Subhead('Tournaments · Active'),
        const _TourneyRow(
          short: 'SC',
          color: CkCrest.sc,
          name: "Spring Cup '26",
          meta: 'QF · 4 matches left',
          live: true,
        ),
        const _TourneyRow(
          short: 'SL',
          color: Color(0xFF2E3E63),
          name: "Sunday League '26",
          meta: 'R1 · 24 matches scheduled',
        ),
        const _TourneyRow(
          short: 'KT',
          color: Color(0xFF2F4C84),
          name: 'Karachi T20 Open',
          meta: '32 teams · prize ₨ 50k',
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
    this.live = false,
  });

  final String short;
  final Color color;
  final String name;
  final String meta;
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
          const SizedBox(width: 8),
          const V2Svg(V2Icons.chevronRight, size: 14, color: CkColors.muted),
        ],
      ),
    );
  }
}
