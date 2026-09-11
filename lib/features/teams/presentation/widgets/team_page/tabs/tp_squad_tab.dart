import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/theme/circk_theme.dart';
import '../tp_atoms.dart';
import '../tp_view.dart';

/// Squad tab — three modes:
///   1. Owner with ≤1 member → onboarding panel ("It's just you so far" + 3 CTAs).
///   2. Private team viewed by stranger → lock gate + Request-to-join CTA.
///   3. Normal grouped roster (Captaincy & keeper / Players) with filter chips.
class TeamSquadTab extends StatelessWidget {
  const TeamSquadTab({
    super.key,
    required this.teamId,
    required this.team,
    required this.viewer,
    this.viewerPlayerId,
  });

  final String teamId;
  final TpTeam team;
  final TeamPageViewer viewer;
  final String? viewerPlayerId;

  /// True when the viewer is the owner and the squad has no players besides
  /// the viewer themselves.
  bool get _isOwnerEmpty {
    if (viewer != TeamPageViewer.owner) return false;
    return team.squad.every((p) => p.id == viewerPlayerId);
  }

  bool get _privateGated =>
      team.privacy.toLowerCase().startsWith('private') &&
      (viewer == TeamPageViewer.stranger ||
          viewer == TeamPageViewer.strangerPrivate);

  @override
  Widget build(BuildContext context) {
    if (team.squad.isEmpty && !_isOwnerEmpty && !_privateGated) {
      return const TpEmptyTile(
        icon: Icons.groups_2_outlined,
        title: 'Squad still being built.',
        body: "Players will appear here once they're added.",
      );
    }
    if (_privateGated) return _PrivateGate(team: team);
    if (_isOwnerEmpty) {
      return _OwnerOnboarding(
        teamId: teamId,
        team: team,
        viewerPlayerId: viewerPlayerId,
      );
    }

    final lead =
        team.squad
            .where(
              (p) =>
                  p.role == TpPlayerRole.manager ||
                  p.role == TpPlayerRole.captain,
            )
            .toList();
    final players =
        team.squad.where((p) => p.role == TpPlayerRole.player).toList();

    final builders = <WidgetBuilder>[];
    builders.add((_) => const _FilterChips());
    if (lead.isNotEmpty) {
      builders.add(
        (_) => TpSectionHeader(label: 'Captaincy & keeper', count: lead.length),
      );
      for (var i = 0; i < lead.length; i++) {
        final player = lead[i];
        final isFirst = i == 0;
        builders.add(
          (_) => TpPlayerRowWidget(
            player: player,
            primary: team.primary,
            isFirst: isFirst,
            viewerPlayerId: viewerPlayerId,
          ),
        );
      }
    }
    if (players.isNotEmpty) {
      builders.add(
        (_) => TpSectionHeader(label: 'Players', count: players.length),
      );
      for (var i = 0; i < players.length; i++) {
        final player = players[i];
        final isFirst = i == 0;
        builders.add(
          (_) => TpPlayerRowWidget(
            player: player,
            primary: team.primary,
            isFirst: isFirst,
            viewerPlayerId: viewerPlayerId,
          ),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 14),
      itemCount: builders.length,
      itemBuilder: (ctx, i) => builders[i](ctx),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  static const _labels = [
    'All',
    'Batters',
    'Bowlers',
    'All-rounders',
    'Keeper',
  ];

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? CkColors.ink : CkColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: active ? null : Border.all(color: CkColors.hairline),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _DashedPanel(
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 28, color: CkColors.ink),
            const SizedBox(height: 12),
            Text(
              'Private squad',
              style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                'Only accepted team members can view the full squad.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12, color: CkColors.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerOnboarding extends StatelessWidget {
  const _OwnerOnboarding({
    required this.teamId,
    required this.team,
    this.viewerPlayerId,
  });

  final String teamId;
  final TpTeam team;
  final String? viewerPlayerId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DashedPanel(
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: CkColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_2_outlined, color: CkColors.ink),
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
                  'Manage your squad, add players, and assign roles in Team Management.',
                  textAlign: TextAlign.center,
                  style: CkType.body(
                    fontSize: 12,
                    color: CkColors.ink2,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/teams/$teamId/manage'),
                icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                label: const Text('Manage Team & Squad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CkColors.ink,
                  foregroundColor: CkColors.paper,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final paint =
        Paint()
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
