// Pavilion drill-down BODY screens — faithful presentation-only ports of the
// Pv* drill-down functions in design_bundle/matchday/project/app/screens/
// Pavilion.jsx (PvStatusInvites / PvStatusClaims / PvStatusDrafts /
// PvStatusToday / PvCaptainDuties / PvOrganizerDuties).
//
// BODY-ONLY: the Pavilion shell renders the title/back header above these.
// Each widget returns just the scrollable body content. Mock data, inert
// buttons. No Riverpod / no backend.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import 'pv_kit.dart';

// ─────────────────────────────────────────────────────────
// Shared local atoms (private to this file)
// ─────────────────────────────────────────────────────────

/// A small pill-shaped action button used inside the drill-down cards.
/// primary = ink bg / paper text; secondary = paper bg + hairline border.
/// Inter 11/12 · 600. Inert by default.
class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
    this.label, {
    this.primary = false,
    this.expanded = false,
    this.fullWidth = false,
    this.fontSize = 12,
    this.verticalPadding = 8,
  });

  final String label;
  final bool primary;

  /// Wrap in [Expanded] for use inside a [Row] of equal-width buttons.
  final bool expanded;

  /// Stretch to fill the parent width (single full-width button).
  final bool fullWidth;
  final double fontSize;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? CkColors.paper : CkColors.ink;
    Widget btn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: fullWidth ? double.infinity : null,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
    if (expanded) btn = Expanded(child: btn);
    return btn;
  }
}

/// A large, rounded full-width CTA used on the Today's fixture screen.
class _BigBtn extends StatelessWidget {
  const _BigBtn(
    this.label, {
    this.primary = false,
    this.textColor,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.verticalPadding = 12,
  });

  final String label;
  final bool primary;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor ?? (primary ? CkColors.paper : CkColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Mono meta timestamp ("2h", "3 days ago", …) — JetBrains Mono 10, muted.
Widget _ageMeta(String text) => Text(
      text,
      style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: CkColors.muted),
    );

/// Card title — Inter 14 / 600.
Text _cardTitle(String text) => Text(
      text,
      style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
    );

/// Card sub line — Inter 12, muted.
Text _cardSub(String text, {double height = 1.0}) => Text(
      text,
      style: CkType.body(fontSize: 12, height: height, color: CkColors.muted),
    );

// ─────────────────────────────────────────────────────────
// PvStatusInvites — filter chips + invite cards
// ─────────────────────────────────────────────────────────

enum _InviteKind { team, tour, role }

class _Invite {
  const _Invite(this.kind, this.title, this.by, this.age, {this.done = false});
  final _InviteKind kind;
  final String title;
  final String by;
  final String age;
  final bool done;
}

class PvStatusInvitesBody extends StatefulWidget {
  const PvStatusInvitesBody({super.key});

  @override
  State<PvStatusInvitesBody> createState() => _PvStatusInvitesBodyState();
}

class _PvStatusInvitesBodyState extends State<PvStatusInvitesBody> {
  // 'all' | 'team' | 'tour' | 'role'
  String _tab = 'all';

  static const _items = <_Invite>[
    _Invite(_InviteKind.team, 'DHA United · squad invite', 'Asad Q. · captain', '2h'),
    _Invite(_InviteKind.tour, 'Spring Cup ‘26 · tournament invite',
        'Sara A. · organizer', '5h'),
    _Invite(_InviteKind.role, 'Become scorer · QF Lions vs Eagles',
        'Tournament', '1d'),
    _Invite(_InviteKind.role, 'Co-manager · Lahore Lions', 'Imran Q.', '2d'),
    _Invite(_InviteKind.team, 'Mohalla Kings · join request reply', 'Approved',
        '3d',
        done: true),
  ];

  static const _chips = <(String, String)>[
    ('all', 'All'),
    ('team', 'Teams'),
    ('tour', 'Tournaments'),
    ('role', 'Roles'),
  ];

  String _kindKey(_InviteKind k) => switch (k) {
        _InviteKind.team => 'team',
        _InviteKind.tour => 'tour',
        _InviteKind.role => 'role',
      };

  String _kindLabel(_InviteKind k) => switch (k) {
        _InviteKind.team => 'Team',
        _InviteKind.tour => 'Tournament',
        _InviteKind.role => 'Role',
      };

  @override
  Widget build(BuildContext context) {
    final visible =
        _items.where((i) => _tab == 'all' || _kindKey(i.kind) == _tab).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Row(
            children: [
              for (var idx = 0; idx < _chips.length; idx++) ...[
                if (idx > 0) const SizedBox(width: 6),
                _ChipBtn(
                  label: _chips[idx].$2,
                  selected: _tab == _chips[idx].$1,
                  onTap: () => setState(() => _tab = _chips[idx].$1),
                ),
              ],
            ],
          ),
        ),
        // Invite cards
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _inviteCard(visible[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _inviteCard(_Invite it) {
    return PvCard(
      accent: it.done ? null : CkColors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PvPill(_kindLabel(it.kind),
                  kind: it.done ? PvPillKind.def : PvPillKind.amber),
              _ageMeta(it.age),
            ],
          ),
          const SizedBox(height: 4),
          _cardTitle(it.title),
          const SizedBox(height: 3),
          _cardSub(it.by),
          if (!it.done) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                _ActionBtn('Accept', primary: true, expanded: true),
                SizedBox(width: 8),
                _ActionBtn('Decline', expanded: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({required this.label, required this.selected, this.onTap});

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
          border:
              Border.all(color: selected ? CkColors.ink : CkColors.hairline),
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

// ─────────────────────────────────────────────────────────
// PvStatusClaims — claim status cards + dashed "find another"
// ─────────────────────────────────────────────────────────

class PvStatusClaimsBody extends StatelessWidget {
  const PvStatusClaimsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        // Pending
        PvCard(
          accent: CkColors.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PvPill('Pending', kind: PvPillKind.amber),
                  _ageMeta('3 days ago'),
                ],
              ),
              const SizedBox(height: 6),
              _cardTitle('"B. Khan" · Mohalla Kings ’21'),
              const SizedBox(height: 4),
              _cardSub('Manager: Faisal A. · 38 matches · 14 innings'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'On approval, all balls / innings / career stats migrate to '
                  'your profile atomically.',
                  style: CkType.body(
                      fontSize: 11, height: 1.4, color: CkColors.ink2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Approved
        PvCard(
          accent: CkColors.green,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PvPill('Approved', kind: PvPillKind.green),
                  _ageMeta('last week'),
                ],
              ),
              const SizedBox(height: 6),
              _cardTitle('"Bilal K." · City Eagles ’22'),
              const SizedBox(height: 4),
              _cardSub('Stats migrated · 24 mat · 612 runs'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Rejected
        PvCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PvPill('Rejected'),
                  _ageMeta('2 weeks ago'),
                ],
              ),
              const SizedBox(height: 6),
              _cardTitle('"B Khan" · Old Boys 2019'),
              const SizedBox(height: 4),
              _cardSub('Manager confirmed different player.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Dashed "find another"
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: _DashedBox(
            child: Text(
              '+ Find another profile to claim',
              style: CkType.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

/// A dashed-border, paper2-filled box (CustomPaint border for dashes).
class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CkColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(10));
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, dist + dash),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────
// PvStatusDrafts — draft cards with progress bar
// ─────────────────────────────────────────────────────────

class _Draft {
  const _Draft(this.kind, this.title, this.pct, this.step, this.last);
  final String kind; // 'tour' | 'team'
  final String title;
  final int pct;
  final String step;
  final String last;
}

class PvStatusDraftsBody extends StatelessWidget {
  const PvStatusDraftsBody({super.key});

  static const _drafts = <_Draft>[
    _Draft('tour', 'Spring Cup ‘26', 87, 'Review', 'today'),
    _Draft('team', 'Lions roster — invite', 50, 'Add players', 'yesterday'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        for (var i = 0; i < _drafts.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _draftCard(_drafts[i]),
        ],
      ],
    );
  }

  Widget _draftCard(_Draft d) {
    return PvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PvPill(d.kind == 'tour' ? 'Tournament' : 'Team'),
              _ageMeta('edited ${d.last}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(d.title, style: pvDisplay(16)),
          const SizedBox(height: 4),
          // "Stuck at <b>Step</b>"
          Text.rich(
            TextSpan(
              style: CkType.body(fontSize: 12, color: CkColors.muted),
              children: [
                const TextSpan(text: 'Stuck at '),
                TextSpan(
                  text: d.step,
                  style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // progress bar — height 4, ink fill at pct%
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4,
              color: CkColors.paper2,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: d.pct / 100,
                child: Container(color: CkColors.ink),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${d.pct}%',
                style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    color: CkColors.muted),
              ),
              const Row(
                children: [
                  _ActionBtn('Discard', fontSize: 11, verticalPadding: 6),
                  SizedBox(width: 6),
                  _ActionBtn('Resume →',
                      primary: true, fontSize: 11, verticalPadding: 6),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PvStatusToday — today's fixture card + CTAs
// ─────────────────────────────────────────────────────────

class PvStatusTodayBody extends StatelessWidget {
  const PvStatusTodayBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        PvCard(
          accent: CkColors.red,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('In 4h 12m', kind: PvPillKind.red),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _teamCrest('L', CkColors.red, 'Lions')),
                  const SizedBox(width: 14),
                  Text('vs', style: pvDisplay(20, color: CkColors.muted)),
                  const SizedBox(width: 14),
                  Expanded(child: _teamCrest('E', CkColors.green, 'Eagles')),
                ],
              ),
              const SizedBox(height: 14),
              _insetBox(
                label: 'Venue',
                title: 'Model Town · Pitch 2',
                sub: '1.4 km · 8 min drive',
              ),
              const SizedBox(height: 10),
              _insetBox(
                label: 'Your role',
                title: 'On the XI · Batting #3',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _BigBtn('Open match sheet →',
            primary: true, fontSize: 14, fontWeight: FontWeight.w700,
            verticalPadding: 14),
        const SizedBox(height: 8),
        const _BigBtn('Get directions'),
        const SizedBox(height: 8),
        const _BigBtn('Mark unavailable', textColor: CkColors.red),
      ],
    );
  }

  Widget _teamCrest(String letter, Color color, String name) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text(
            letter,
            style: const TextStyle(
              fontFamily: 'Inter Tight',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: CkColors.paper,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(name, style: pvDisplay(15), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _insetBox({required String label, required String title, String? sub}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: pvMonoLabel()),
          const SizedBox(height: 2),
          Text(title,
              style:
                  CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            _cardSub(sub).copyWithSize11(),
          ],
        ],
      ),
    );
  }
}

// Tiny helper so the venue sub line is 11px (the JSX uses fontSize:11 there).
extension on Text {
  Text copyWithSize11() => Text(
        data ?? '',
        style: CkType.body(fontSize: 11, color: CkColors.muted),
      );
}

// ─────────────────────────────────────────────────────────
// PvCaptainDuties — Pick XI / Join request / Claim approvals
// ─────────────────────────────────────────────────────────

class PvCaptainDutiesBody extends StatelessWidget {
  const PvCaptainDutiesBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        // Pick XI (red)
        PvCard(
          accent: CkColors.red,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('Pick XI · today', kind: PvPillKind.red),
              ),
              const SizedBox(height: 6),
              _cardTitle('QF · Lions vs Eagles · 18:30'),
              const SizedBox(height: 3),
              _cardSub('14 squad available · 11 needed · auto-pick from last match'),
              const SizedBox(height: 10),
              const _ActionBtn('Pick XI →',
                  primary: true, fullWidth: true, fontSize: 13,
                  verticalPadding: 10),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Join request (amber)
        PvCard(
          accent: CkColors.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('Join request', kind: PvPillKind.amber),
              ),
              const SizedBox(height: 6),
              _cardTitle('Hassan Ali wants to join Lions'),
              const SizedBox(height: 3),
              _cardSub('Off-spinner · 23 yrs · 18 matches · @hassana'),
              const SizedBox(height: 10),
              const Row(
                children: [
                  _ActionBtn('Approve', primary: true, expanded: true),
                  SizedBox(width: 8),
                  _ActionBtn('Reject', expanded: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Claim approvals (amber)
        PvCard(
          accent: CkColors.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('Claim approvals · 2', kind: PvPillKind.amber),
              ),
              const SizedBox(height: 6),
              _cardTitle('Two players claim profiles in your roster'),
              const SizedBox(height: 3),
              _cardSub(
                '"Bilal K. · Spring ’23"  →  Bilal Khan @bilalk\n'
                '"A. Asad · Winter ’22"  →  Asad A. @asad',
                height: 1.5,
              ),
              const SizedBox(height: 10),
              const _ActionBtn('Review claims →',
                  fullWidth: true, fontSize: 13, verticalPadding: 10),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// PvOrganizerDuties — registrations / scorers / payment / awards
// ─────────────────────────────────────────────────────────

class PvOrganizerDutiesBody extends StatelessWidget {
  const PvOrganizerDutiesBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        // Team registrations (green)
        PvCard(
          accent: CkColors.green,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('Team registrations · 2', kind: PvPillKind.green),
              ),
              const SizedBox(height: 6),
              _cardTitle('DHA United · Old Boys'),
              const SizedBox(height: 3),
              _cardSub('Both squads locked · paid · awaiting your approval'),
              const SizedBox(height: 10),
              const _ActionBtn('Approve both →',
                  primary: true, fullWidth: true, fontSize: 13,
                  verticalPadding: 10),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Scorer pool low (amber)
        PvCard(
          accent: CkColors.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('Scorer pool low', kind: PvPillKind.amber),
              ),
              const SizedBox(height: 6),
              _cardTitle('3 scorers · 8 matches this weekend'),
              const SizedBox(height: 3),
              _cardSub('Recommend 5+ · invite from search'),
              const SizedBox(height: 10),
              const _ActionBtn('Invite scorers →',
                  fullWidth: true, fontSize: 13, verticalPadding: 10),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Payment overdue (red)
        PvCard(
          accent: CkColors.red,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('Payment overdue', kind: PvPillKind.red),
              ),
              const SizedBox(height: 6),
              _cardTitle('Mohalla Kings · ₨ 5,000 entry fee'),
              const SizedBox(height: 3),
              _cardSub('Due 4 days ago · waiver available'),
              const SizedBox(height: 10),
              const Row(
                children: [
                  _ActionBtn('Send reminder', primary: true, expanded: true),
                  SizedBox(width: 8),
                  _ActionBtn('Waive fee', expanded: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Awards open (default)
        PvCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: PvPill('Awards open'),
              ),
              const SizedBox(height: 6),
              _cardTitle('Tournament ends Sunday — finalize awards'),
              const SizedBox(height: 3),
              _cardSub('5 auto-suggested · pick winners or override'),
              const SizedBox(height: 10),
              const _ActionBtn('Open awards →',
                  fullWidth: true, fontSize: 13, verticalPadding: 10),
            ],
          ),
        ),
      ],
    );
  }
}
