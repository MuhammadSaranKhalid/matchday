// Pavilion "Yours" drill-down bodies — faithful presentation-only ports of
// PvMyStats / PvAchievements / PvWallet from the design
// (design_bundle/matchday/project/app/screens/Pavilion.jsx).
//
// BODY-ONLY: the Pavilion shell supplies the back/title header, so these
// widgets return just the scrollable body content. All buttons are inert;
// no Riverpod, no backend, mock data.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import 'pv_kit.dart';

// ---------------------------------------------------------------------------
// PvMyStatsBody — segmented Career / Form / Wagon control with local state.
// ---------------------------------------------------------------------------
class PvMyStatsBody extends StatefulWidget {
  const PvMyStatsBody({super.key});

  @override
  State<PvMyStatsBody> createState() => _PvMyStatsBodyState();
}

class _PvMyStatsBodyState extends State<PvMyStatsBody> {
  static const _tabs = ['Career', 'Form', 'Wagon'];
  String _tab = 'Career';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented tab control.
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: _SegTab(
                    label: _tabs[i],
                    selected: _tab == _tabs[i],
                    onTap: () => setState(() => _tab = _tabs[i]),
                  )),
                ],
              ],
            ),
          ),
          switch (_tab) {
            'Career' => const _CareerGrid(),
            'Form' => const _FormList(),
            _ => const _WagonView(),
          },
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

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

// --- Career: 2-col stat grid ----------------------------------------------
class _CareerGrid extends StatelessWidget {
  const _CareerGrid();

  static const _stats = <(String, String)>[
    ('Runs', '4,217'),
    ('Average', '36.4'),
    ('Strike rate', '138.6'),
    ('Best', '112*'),
    ('Wickets', '21'),
    ('Economy', '8.4'),
    ('Catches', '38'),
    ('MOM', '14'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        children: [
          for (var i = 0; i < _stats.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StatCell(_stats[i])),
                const SizedBox(width: 8),
                Expanded(child: _StatCell(_stats[i + 1])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.stat);

  final (String, String) stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stat.$1, style: pvMonoLabel()),
          const SizedBox(height: 4),
          Text(stat.$2, style: pvDisplay(24)),
        ],
      ),
    );
  }
}

// --- Form: last-5-innings rows --------------------------------------------
class _FormList extends StatelessWidget {
  const _FormList();

  static const _innings = <_Inning>[
    _Inning(vs: 'Eagles', r: 67, b: 41, tag: 'NOT OUT', kind: PvPillKind.green),
    _Inning(vs: 'Kings', r: 12, b: 18),
    _Inning(vs: 'DHA', r: 88, b: 52, tag: '50+', kind: PvPillKind.amber),
    _Inning(vs: 'Old Boys', r: 4, b: 9),
    _Inning(vs: 'Eagles', r: 33, b: 24),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LAST 5 INNINGS', style: pvMonoLabel()),
          const SizedBox(height: 10),
          for (var i = 0; i < _innings.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _InningRow(_innings[i]),
          ],
        ],
      ),
    );
  }
}

class _Inning {
  const _Inning({required this.vs, required this.r, required this.b, this.tag, this.kind});

  final String vs;
  final int r;
  final int b;
  final String? tag;
  final PvPillKind? kind;
}

class _InningRow extends StatelessWidget {
  const _InningRow(this.inning);

  final _Inning inning;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('vs ${inning.vs}',
                    style: CkType.body(fontSize: 12, color: CkColors.muted)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${inning.r} ', style: pvDisplay(18)),
                      TextSpan(
                        text: '(${inning.b})',
                        style: CkType.body(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (inning.tag != null) ...[
            const SizedBox(width: 12),
            PvPill(inning.tag!, kind: inning.kind ?? PvPillKind.def),
          ],
        ],
      ),
    );
  }
}

// --- Wagon: 280×280 wagon-wheel via CustomPaint --------------------------
class _WagonView extends StatelessWidget {
  const _WagonView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: CkColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              child: const CustomPaint(painter: _WagonPainter()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Career wagon · 412 boundaries · leg-side dominant',
            textAlign: TextAlign.center,
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ],
      ),
    );
  }
}

class _WagonPainter extends CustomPainter {
  const _WagonPainter();

  // JSX shot lines: [x, y, weightCode]. weightCode 6 = ink, 4 = green, else muted.
  static const _shots = <(double, double, int)>[
    (80, -40, 6), (60, -75, 4), (-65, -55, 4), (-90, 30, 6),
    (50, 60, 4), (85, 45, 6), (-30, 85, 1), (-70, -20, 4),
    (40, -90, 6), (25, -60, 2), (-55, 70, 1), (70, 10, 4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox -110..110 over 280px → scale & centre at canvas middle.
    final scale = size.width / 220.0;
    final center = Offset(size.width / 2, size.height / 2);

    Offset map(double x, double y) =>
        center + Offset(x * scale, y * scale);

    final hair = Paint()
      ..color = CkColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // field circles r100 / r55
    canvas.drawCircle(center, 100 * scale, hair);
    canvas.drawCircle(center, 55 * scale, hair);
    // axes
    canvas.drawLine(map(0, -100), map(0, 100), hair);
    canvas.drawLine(map(-100, 0), map(100, 0), hair);

    // shot lines
    for (final (x, y, code) in _shots) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (code == 1 ? 0.8 : 1.4) * scale
        ..color = switch (code) {
          6 => CkColors.ink,
          4 => CkColors.green,
          _ => CkColors.muted,
        };
      canvas.drawLine(center, map(x, y), paint);
    }

    // red center dot r3
    canvas.drawCircle(center, 3 * scale, Paint()..color = CkColors.red);
  }

  @override
  bool shouldRepaint(covariant _WagonPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// PvAchievementsBody — 2-col grid of achievement tiles.
// ---------------------------------------------------------------------------
enum _AchKind { unlocked, progress, locked }

class _Achievement {
  const _Achievement(this.title, this.kind, [this.date]);

  final String title;
  final _AchKind kind;
  final String? date;
}

class PvAchievementsBody extends StatelessWidget {
  const PvAchievementsBody({super.key});

  static const _items = <_Achievement>[
    _Achievement('First fifty', _AchKind.unlocked, 'May 2019 · vs Eagles'),
    _Achievement('Hat-trick hero', _AchKind.unlocked, 'Dec 2022 · vs DHA'),
    _Achievement('Century maker', _AchKind.unlocked, '4× · best 112*'),
    _Achievement('1000 career runs', _AchKind.unlocked, 'Jan 2021'),
    _Achievement('5-fer', _AchKind.progress, '4 wkts · 1 to go'),
    _Achievement('MOM ×25', _AchKind.progress, '14 / 25'),
    _Achievement('Captain a tournament', _AchKind.progress, 'in progress · Spring Cup'),
    _Achievement('Score 100 matches', _AchKind.locked),
    _Achievement('Tournament winner', _AchKind.locked),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _AchTile(_items[i])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < _items.length
                        ? _AchTile(_items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchTile extends StatelessWidget {
  const _AchTile(this.ach);

  final _Achievement ach;

  @override
  Widget build(BuildContext context) {
    final unlocked = ach.kind == _AchKind.unlocked;
    final locked = ach.kind == _AchKind.locked;

    final tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? CkColors.cream : CkColors.paper,
        borderRadius: BorderRadius.circular(10),
        // creamBorder = oklch(0.86 0.05 90) — the JSX unlocked tile border.
        border: Border.all(color: unlocked ? CkColors.creamBorder : CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked ? CkColors.amber : CkColors.paper2,
              shape: BoxShape.circle,
            ),
            child: Text(
              switch (ach.kind) {
                _AchKind.unlocked => '✦',
                _AchKind.progress => '◴',
                _AchKind.locked => '🔒',
              },
              style: TextStyle(
                fontSize: 18,
                color: unlocked ? CkColors.paper : CkColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ach.title,
            style: const TextStyle(
              fontFamily: 'Inter Tight',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
            ),
          ),
          if (ach.date != null) ...[
            const SizedBox(height: 3),
            Text(
              ach.date!,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                color: CkColors.muted,
              ),
            ),
          ],
        ],
      ),
    );

    return locked ? Opacity(opacity: 0.5, child: tile) : tile;
  }
}

// ---------------------------------------------------------------------------
// PvWalletBody — balance card + recent activity rows.
// ---------------------------------------------------------------------------
class _Activity {
  const _Activity(this.title, this.amount, this.date, {required this.incoming});

  final String title;
  final String amount;
  final String date;
  final bool incoming;
}

class PvWalletBody extends StatelessWidget {
  const PvWalletBody({super.key});

  static const _activity = <_Activity>[
    _Activity('Spring Cup ‘26 · entry fee', '−₨ 5,000', 'Mar 4', incoming: false),
    _Activity('Best Bowler · Spring ‘25', '+₨ 12,500', 'Feb 14', incoming: true),
    _Activity('Friday League · entry fee', '−₨ 2,000', 'Jan 22', incoming: false),
    _Activity('MOM bonus · vs DHA', '+₨ 500', 'Jan 14', incoming: true),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance card.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: PvCard(
              accent: CkColors.green,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('AVAILABLE BALANCE', style: pvMonoLabel()),
                  const SizedBox(height: 6),
                  Text('₨ 12,500', style: pvDisplay(38)),
                  const SizedBox(height: 6),
                  Text(
                    "From Spring Cup '25 · Best Bowler payout",
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(child: _WalletButton('Withdraw', filled: true)),
                      SizedBox(width: 8),
                      Expanded(child: _WalletButton('Add method', filled: false)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const PvSectionH('Recent activity'),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Column(
              children: [
                for (var i = 0; i < _activity.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _ActivityRow(_activity[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton(this.label, {required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: filled ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        label,
        style: CkType.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: filled ? CkColors.paper : CkColors.ink,
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.item);

  final _Activity item;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title,
                    style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  item.date,
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.amount,
            style: TextStyle(
              fontFamily: 'Inter Tight',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: item.incoming ? CkColors.green : CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
