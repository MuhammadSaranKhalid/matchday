import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Squad tab — three modes:
///   1. Owner with ≤1 member → onboarding panel ("It's just you so far" + 3 CTAs).
///   2. Private team viewed by stranger → lock gate + Request-to-join CTA.
///   3. Normal grouped roster (Captaincy & keeper / Players) with filter chips.
class TpSquadTab extends StatelessWidget {
  const TpSquadTab({
    super.key,
    required this.team,
    required this.viewer,
    this.viewerPlayerId,
  });

  final TpTeam team;
  final TeamPageViewer viewer;
  final String? viewerPlayerId;

  bool get _isOwnerEmpty =>
      viewer == TeamPageViewer.owner && team.squad.length <= 1;
  bool get _privateGated => team.privacy.toLowerCase().startsWith('private') &&
      (viewer == TeamPageViewer.stranger ||
          viewer == TeamPageViewer.strangerPrivate);

  @override
  Widget build(BuildContext context) {
    if (team.squad.isEmpty && !_isOwnerEmpty && !_privateGated) {
      return const TpEmptyTile(
        icon: Icons.groups_2_outlined,
        title: 'Squad still being built.',
        body: 'Players will appear here once they\'re added.',
      );
    }
    if (_privateGated) return _PrivateGate(team: team);
    if (_isOwnerEmpty) {
      return _OwnerOnboarding(
          team: team, viewerPlayerId: viewerPlayerId);
    }

    final lead = team.squad
        .where((p) =>
            p.role == TpPlayerRole.captain ||
            p.role == TpPlayerRole.viceCaptain ||
            p.role == TpPlayerRole.wicketKeeper)
        .toList();
    final players =
        team.squad.where((p) => p.role == TpPlayerRole.player).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      children: [
        _FilterChips(),
        if (lead.isNotEmpty) ...[
          TpSectionHeader(label: 'Captaincy & keeper', count: lead.length),
          for (var i = 0; i < lead.length; i++)
            TpPlayerRowWidget(
              player: lead[i],
              primary: team.primary,
              isFirst: i == 0,
              viewerPlayerId: viewerPlayerId,
            ),
        ],
        if (players.isNotEmpty) ...[
          TpSectionHeader(label: 'Players', count: players.length),
          for (var i = 0; i < players.length; i++)
            TpPlayerRowWidget(
              player: players[i],
              primary: team.primary,
              isFirst: i == 0,
              viewerPlayerId: viewerPlayerId,
            ),
        ],
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  static const _labels = ['All', 'Batters', 'Bowlers', 'All-rounders', 'Keeper'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == 0;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? CkColors.ink : CkColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: active
                  ? null
                  : Border.all(color: CkColors.hairline),
            ),
            alignment: Alignment.center,
            child: Text(
              _labels[i],
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? CkColors.paper : CkColors.ink2,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrivateGate extends StatelessWidget {
  const _PrivateGate({required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    return TpEmptyTile(
      icon: Icons.lock_outline,
      title: 'Private squad',
      body:
          'Only members can see the roster. Request to join — the captain will review.',
      cta: 'Request to join',
      onCtaTap: () {},
    );
  }
}

class _OwnerOnboarding extends StatelessWidget {
  const _OwnerOnboarding(
      {required this.team, required this.viewerPlayerId});
  final TpTeam team;
  final String? viewerPlayerId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        _DashedPanel(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CkColors.hairline),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_add_alt_1,
                  size: 28,
                  color: CkColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "It's just you so far.",
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  "Build ${team.name}'s squad — search registered "
                  'players, send SMS invites, or add unclaimed placeholders.',
                  textAlign: TextAlign.center,
                  style: CkType.body(
                    fontSize: 12,
                    color: CkColors.ink2,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _AddOption(
          primary: true,
          icon: Icons.search,
          title: 'Search registered players',
          sub: 'Pick from people already on MatchDay',
        ),
        const SizedBox(height: 8),
        const _AddOption(
          icon: Icons.mail_outline,
          title: 'Send SMS invite',
          sub: 'Phone number → download link',
        ),
        const SizedBox(height: 8),
        const _AddOption(
          icon: Icons.person_outline,
          title: 'Add as unclaimed',
          sub: 'Just a name — they can claim later',
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('YOU', style: tpMono()),
        ),
        const SizedBox(height: 8),
        if (team.squad.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: TpPlayerRowWidget(
              player: team.squad.first,
              primary: team.primary,
              isFirst: true,
              viewerPlayerId: viewerPlayerId,
            ),
          ),
      ],
    );
  }
}

class _DashedPanel extends StatelessWidget {
  const _DashedPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: CkColors.paper2,
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CkColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.sub,
    this.primary = false,
  });
  final IconData icon;
  final String title;
  final String sub;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primary ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary ? CkColors.ink : CkColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary
                  ? Colors.white.withValues(alpha: 0.14)
                  : CkColors.paper2,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 14,
              color: primary ? CkColors.paper : CkColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                    color: primary ? CkColors.paper : CkColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: CkType.body(
                    fontSize: 11,
                    color: primary
                        ? CkColors.paper.withValues(alpha: 0.72)
                        : CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: primary
                ? CkColors.paper.withValues(alpha: 0.6)
                : CkColors.muted,
          ),
        ],
      ),
    );
  }
}
