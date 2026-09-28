import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../providers/matches_board_providers.dart';
import '../pool/pool_challenge_card.dart';
import 'match_score_row.dart';

/// The four status tabs — `Matches.dc.html` artboard 02.
///
/// Selected is ink text on a 2px ink rule; unselected is muted mono with no
/// rule. **The selected tab is never red.** The live count rides as a bare
/// tabular figure after the word, with the pulsing dot as its only ornament;
/// at zero, both dot and figure disappear.
class BoardTabs extends StatelessWidget {
  const BoardTabs({
    super.key,
    required this.selected,
    required this.liveCount,
    required this.onSelect,
  });

  final MatchesBoardTab selected;
  final int liveCount;
  final ValueChanged<MatchesBoardTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      // The design insets the tabs 18 and spaces them 22, which fits its own
      // 390 artboard. Here they share the 16 gutter the cards below use, so
      // the first tab lines up with the group crests rather than sitting
      // proud of them, and the gap flexes so all four always fit — a
      // part-scrolled tab row reads as a layout fault, not as a scroll.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabs = MatchesBoardTab.values;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final tab in tabs)
                  Flexible(
                    child: _Tab(
                      tab: tab,
                      selected: tab == selected,
                      // The tab is not a metric: past nine it stops counting.
                      count: tab == MatchesBoardTab.live ? liveCount : 0,
                      onTap: () => onSelect(tab),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final MatchesBoardTab tab;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCount = count > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? CkColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCount) ...[const _Dot(), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                showCount
                    ? '${tab.label} ${count > 9 ? '9+' : count}'.toUpperCase()
                    : tab.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.07,
                  color: selected ? CkColors.ink : CkColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      color: CkColors.red,
      shape: BoxShape.circle,
    ),
  );
}

/// A competition's header — `Matches.dc.html` artboard 09.
///
/// Crest, name, and a mono sub-line carrying stage · fixture count. Collapsed
/// keeps the sub-line and gains a live tally, so a folded group still tells
/// you whether to open it.
class BoardGroupHeader extends StatelessWidget {
  const BoardGroupHeader({
    super.key,
    required this.group,
    required this.collapsed,
    required this.onToggle,
    this.onOpen,
  });

  final BoardGroup group;
  final bool collapsed;
  final VoidCallback onToggle;

  /// Tapping the header opens the tournament; the chevron only folds it.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = group.tournament;
    final live = group.liveCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: group.isFriendlies ? onToggle : (onOpen ?? onToggle),
      child: Row(
        children: [
          if (group.isFriendlies)
            // No crest to show, so a hairline paper square holds the slot.
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CkColors.line),
              ),
            )
          else
            Crest(
              short: _monogram(t?.name),
              color: CkColors.ink,
              size: 28,
              radius: 8,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.isFriendlies ? 'Friendlies' : (t?.name ?? 'Tournament'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _subLine().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.07,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                    if (collapsed && live > 0) ...[
                      const SizedBox(width: 8),
                      LivePip(label: '$live live'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: const Duration(milliseconds: 140),
                child: const V2Svg(
                  V2Icons.chevronDown,
                  size: 16,
                  color: CkColors.muted,
                  strokeWidth: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subLine() {
    final n = group.matches.length;
    final fixtures = '$n ${n == 1 ? 'fixture' : 'fixtures'}';
    if (group.isFriendlies) return 'Challenges and pool · $fixtures';
    final stage = group.matches.first.match.round;
    return [if (stage != null && stage.isNotEmpty) stage, fixtures].join(' · ');
  }

  static String _monogram(String? name) {
    if (name == null || name.trim().isEmpty) return 'T';
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return words.first.substring(0, 1).toUpperCase();
  }
}

/// "Today · Tue 2 Sep" — the day rule that groups the week on Upcoming and
/// Finished.
class BoardDayHeader extends StatelessWidget {
  const BoardDayHeader(this.day, {super.key});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _label(day).toUpperCase(),
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.ink,
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(child: Divider(height: 1, color: CkColors.line)),
      ],
    );
  }

  static String _label(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final date = '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';

    final now = DateTime.now();
    final delta =
        DateTime(
          d.year,
          d.month,
          d.day,
        ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return switch (delta) {
      0 => 'Today · $date',
      1 => 'Tomorrow · $date',
      -1 => 'Yesterday · $date',
      _ => date,
    };
  }
}

/// An upcoming fixture — `Matches.dc.html` artboard 03.
///
/// No score yet, so **the time is the figure**: display 20 on a left rail,
/// occupying the column where the score would sit.
class UpcomingMatchRow extends StatelessWidget {
  const UpcomingMatchRow({super.key, required this.item, this.onTap});

  final BoardMatch item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final start = item.match.scheduledStartTime;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: CkColors.paper,
                  border: Border(right: BorderSide(color: CkColors.hairline)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      start == null ? '—' : _clock(start),
                      style: CkType.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                        letterSpacing: -0.02,
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (start != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        start.hour >= 12 ? 'PM' : 'AM',
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.08,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _side(item.teamA, item.match.teamAId),
                      const SizedBox(height: 7),
                      _side(item.teamB, item.match.teamBId),
                      const SizedBox(height: 8),
                      Text(
                        _context().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.07,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _side(Team? team, TeamId teamId) {
    final mine = item.viewerTeamId == teamId;
    return Row(
      children: [
        Crest(
          short: teamMonogram(team),
          color: teamCrestColor(team),
          logoUrl: team?.logoUrl,
          size: 20,
          radius: 6,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: CkType.display(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
                letterSpacing: -0.01,
              ),
              children: [
                TextSpan(text: team?.name ?? 'Team'),
                if (mine) ...[
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: 'YOU',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.soft,
                    ),
                  ),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _context() {
    final m = item.match;
    final overs = m.format.oversPerInnings;
    return [
      if (m.round case final r? when r.isNotEmpty) r,
      if (m.venue?.ground case final g? when g.trim().isNotEmpty) g.trim(),
      if (overs > 0) '$overs ov',
      if (m.format.playersPerTeam != 11) '${m.format.playersPerTeam}-a-side',
    ].join(' · ');
  }

  static String _clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')}';
  }
}
