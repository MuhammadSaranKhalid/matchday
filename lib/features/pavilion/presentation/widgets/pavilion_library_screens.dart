// Pavilion library drill-down BODIES — faithful presentation-only ports of
// PvLibrarySaved / PvLibraryFollowed / PvLibraryScorer from the design
// (design_bundle/matchday/project/app/screens/Pavilion.jsx).
//
// Body-only: the Pavilion shell supplies the back/title header. Each body is a
// scrollable widget. Mock data; buttons inert except the Followed tab control
// and per-follow bell toggles, which flip local state.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import 'pv_kit.dart';

// ─────────────────────────────────────────────────────────────────────────
// PvLibrarySaved
// ─────────────────────────────────────────────────────────────────────────

/// Saved items: filter chips (All/Posts/Matches/Tours) + cards, each with a
/// kind pill (match→red, tour→amber), a mono source line, and a saved excerpt.
class PvLibrarySavedBody extends StatefulWidget {
  const PvLibrarySavedBody({super.key});

  @override
  State<PvLibrarySavedBody> createState() => _PvLibrarySavedBodyState();
}

class _PvLibrarySavedBodyState extends State<PvLibrarySavedBody> {
  static const _filters = ['All', 'Posts', 'Matches', 'Tours'];
  int _active = 0;

  // (title, source, kind) — kind one of: post / match / tour
  static const _items = [
    ('"That cover drive was clean."', 'Bilal Khan · 3d ago', 'post'),
    ('Lions vs Eagles · QF', 'Match · Mar 14', 'match'),
    ('Spring Cup ‘26', 'Tournament', 'tour'),
    ('"Looking for a fast bowler"', 'Old Boys · 5d ago', 'post'),
    ('"Hat-trick — never gets old"', 'Imran Q. · 1w ago', 'post'),
  ];

  PvPillKind _pillKind(String k) => switch (k) {
        'match' => PvPillKind.red,
        'tour' => PvPillKind.amber,
        _ => PvPillKind.def,
      };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Row(
            children: [
              for (var i = 0; i < _filters.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _Chip(
                  label: _filters[i],
                  selected: i == _active,
                  onTap: () => setState(() => _active = i),
                ),
              ],
            ],
          ),
        ),
        // Cards
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                PvCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          PvPill(_items[i].$3, kind: _pillKind(_items[i].$3)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _items[i].$2,
                              style: CkType.mono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                  color: CkColors.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _items[i].$1,
                        style: CkType.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped filter chip (selected → ink fill / paper text).
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? CkColors.ink : CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PvLibraryFollowed
// ─────────────────────────────────────────────────────────────────────────

class _Follow {
  const _Follow(this.name, this.sub, {this.notif = false});
  final String name;
  final String sub;
  final bool notif;
}

/// Followed entities, segmented by Players / Teams / Tournaments (local tab
/// state). Each row: ink initials avatar + name/sub + bell toggle (🔔 red on /
/// 🔕 muted off, local state) + inert "Following ✓" button.
class PvLibraryFollowedBody extends StatefulWidget {
  const PvLibraryFollowedBody({super.key});

  @override
  State<PvLibraryFollowedBody> createState() => _PvLibraryFollowedBodyState();
}

class _PvLibraryFollowedBodyState extends State<PvLibraryFollowedBody> {
  static const _tabs = ['Players', 'Teams', 'Tournaments'];
  int _active = 0;

  static const Map<String, List<_Follow>> _groups = {
    'Players': [
      _Follow('Babar Azam', 'PAK · top order', notif: true),
      _Follow('Imran Q.', '@imranq · captain · friend'),
      _Follow('Hassan Ali', 'PAK · pace'),
    ],
    'Teams': [
      _Follow('Lahore Lions', '14 squad · home', notif: true),
      _Follow('City Eagles', 'rivals · 8 squad'),
      _Follow('DHA United', '11 squad'),
    ],
    'Tournaments': [
      _Follow("Spring Cup '26", '8 teams · live', notif: true),
      _Follow('Friday League', '6 teams · weekly'),
    ],
  };

  // Per-row bell state keyed by "tabIndex:rowIndex".
  final Map<String, bool> _bells = {};

  bool _bellOn(int tab, int row, bool initial) =>
      _bells['$tab:$row'] ?? initial;

  String _initials(String name) {
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    final letters = parts.map((s) => s[0]).join();
    return letters.length > 2 ? letters.substring(0, 2) : letters;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _groups[_tabs[_active]]!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Segmented tab control
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _SegTab(
                    label: _tabs[i],
                    selected: i == _active,
                    onTap: () => setState(() => _active = i),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Rows
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _FollowRow(
                  initials: _initials(rows[i].name),
                  name: rows[i].name,
                  sub: rows[i].sub,
                  bellOn: _bellOn(_active, i, rows[i].notif),
                  onToggleBell: () => setState(() {
                    _bells['$_active:$i'] =
                        !_bellOn(_active, i, rows[i].notif);
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Segmented tab button (selected → ink fill / paper text), 8px radius.
class _SegTab extends StatelessWidget {
  const _SegTab({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? CkColors.ink : CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.initials,
    required this.name,
    required this.sub,
    required this.bellOn,
    this.onToggleBell,
  });

  final String initials;
  final String name;
  final String sub;
  final bool bellOn;
  final VoidCallback? onToggleBell;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Avatar(mono: initials, size: 36, tone: AvatarTone.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: CkType.body(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sub,
                    style:
                        CkType.body(fontSize: 11, color: CkColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Per-follow notification bell (local toggle).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleBell,
            child: Text(
              bellOn ? '\u{1F514}' : '\u{1F515}',
              style: TextStyle(
                fontSize: 14,
                color: bellOn ? CkColors.red : CkColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Inert "Following ✓" button.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Text('Following ✓',
                style: CkType.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PvLibraryScorer
// ─────────────────────────────────────────────────────────────────────────

/// Scorer history: 3 stat tiles (Total / This month / Avg accy) + recent
/// matches rows (date · divider · name · "venue · result" + optional Today pill).
class PvLibraryScorerBody extends StatelessWidget {
  const PvLibraryScorerBody({super.key});

  // (date, title, venue, result, isToday)
  static const _matches = [
    ('Mar 09', 'Lions vs Eagles', 'Model Town', 'Lions won by 4 wkts', true),
    ('Mar 02', 'Lions vs Mohalla K.', 'Gulberg', 'M. Kings won by 12', false),
    ('Feb 22', 'DHA vs Old Boys', 'DHA grounds', 'DHA won by 3 wkts', false),
    ('Feb 14', 'Eagles vs DHA', 'Model Town', 'Eagles won by 22', false),
  ];

  static const _stats = [
    ('Total', '38'),
    ('This month', '4'),
    ('Avg accy', '99.2%'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Stat tiles
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            children: [
              for (var i = 0; i < _stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(label: _stats[i].$1, value: _stats[i].$2),
                ),
              ],
            ],
          ),
        ),
        const PvSectionH('Recent matches'),
        // Recent match rows
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
            children: [
              for (var i = 0; i < _matches.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _MatchRow(
                  date: _matches[i].$1,
                  title: _matches[i].$2,
                  venue: _matches[i].$3,
                  result: _matches[i].$4,
                  isToday: _matches[i].$5,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              textAlign: TextAlign.center,
              style: pvMonoLabel().copyWith(fontSize: 9)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, style: pvDisplay(20)),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.date,
    required this.title,
    required this.venue,
    required this.result,
    required this.isToday,
  });

  final String date;
  final String title;
  final String venue;
  final String result;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(date.toUpperCase(),
                style: pvMonoLabel(color: CkColors.ink)),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 28, color: CkColors.hairline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: CkType.body(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$venue · $result',
                    style:
                        CkType.body(fontSize: 11, color: CkColors.muted)),
              ],
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            const PvPill('Today', kind: PvPillKind.red),
          ],
        ],
      ),
    );
  }
}
