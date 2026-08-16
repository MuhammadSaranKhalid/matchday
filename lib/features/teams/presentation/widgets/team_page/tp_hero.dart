import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../../data/datasources/teams_datasource_providers.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Hero header — primary-color background with cricket-ground motif, status bar
/// overlay, back/share/dots icons, crest tile + name + tagline, optional
/// badges row, optional W/L strip, action row.
class TpHero extends StatelessWidget {
  const TpHero({
    super.key,
    required this.teamId,
    required this.team,
    required this.viewer,
    required this.badges,
    this.onBack,
    this.onShare,
    this.onOptions,
  });

  final String teamId;
  final TpTeam team;
  final TeamPageViewer viewer;
  final List<TpHeroBadge> badges;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onOptions;

  Color get _heroColor =>
      team.archived != null ? const Color(0xFF6A6356) : team.primary;

  @override
  Widget build(BuildContext context) {
    final dim = team.archived != null;
    final color = _heroColor;
    return ColoredBox(
      color: color,
      child: Stack(
        children: [
          // Cricket-ground motif painted at the top-right corner.
          const Positioned(
            right: -30,
            top: -10,
            child: Opacity(
              opacity: 0.10,
              child: CustomPaint(
                size: Size(320, 200),
                painter: TpCricketGroundPainter(),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TpIconBtn(
                          icon: Icons.arrow_back,
                          onColor: true,
                          onTap: onBack,
                        ),
                        Row(
                          children: [
                            TpIconBtn(
                              icon: Icons.ios_share,
                              onColor: true,
                              onTap: onShare,
                            ),
                            const SizedBox(width: 6),
                            TpIconBtn(
                              icon: Icons.more_horiz,
                              onColor: true,
                              onTap: onOptions,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _Identity(team: team, heroColor: color, dim: dim),
                  ),
                  if (badges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: _BadgesRow(badges: badges),
                    ),
                  if (team.record != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: _RecordStrip(record: team.record!),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: TpActionRow(
                      teamId: teamId,
                      viewer: viewer,
                      team: team,
                      heroColor: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.team,
    required this.heroColor,
    required this.dim,
  });
  final TpTeam team;
  final Color heroColor;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _HeroCrest(team: team, heroColor: heroColor),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${team.type.toUpperCase()} · '
                      '${team.area.toUpperCase()}${team.area.isNotEmpty ? ', ' : ''}${team.city.toUpperCase()}',
                      style: tpMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    if (team.verified && !dim) const TpVerifiedTick(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  team.name,
                  style: CkType.display(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                if (team.tagline != null &&
                    team.tagline!.trim().isNotEmpty &&
                    !dim) ...[
                  const SizedBox(height: 6),
                  Text(
                    '“${team.tagline}”',
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.01,
                      color: Colors.white.withValues(alpha: 0.85),
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCrest extends StatelessWidget {
  const _HeroCrest({required this.team, required this.heroColor});
  final TpTeam team;
  final Color heroColor;

  Widget _mono() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      team.mono,
      style: CkType.display(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        color: heroColor,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final url = team.logoUrl;
    if (url == null || url.isEmpty) return _mono();
    final memW = (72 * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 72,
        height: 72,
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          memCacheWidth: memW,
          errorWidget: (_, __, ___) => _mono(),
          placeholder: (_, __) => _mono(),
        ),
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.badges});
  final List<TpHeroBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final b in badges) _Badge(badge: b)],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});
  final TpHeroBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color:
            badge.tone == TpHeroBadgeTone.red
                ? CkColors.red
                : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.pulse) ...[const TpLivePulse(), const SizedBox(width: 5)],
          Text(
            badge.label.toUpperCase(),
            style: tpMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordStrip extends StatelessWidget {
  const _RecordStrip({required this.record});
  final TpRecord record;

  @override
  Widget build(BuildContext context) {
    final cells = <(String, String)>[
      ('PLAYED', '${record.played}'),
      ('WON', '${record.won}'),
      ('LOST', '${record.lost}'),
      ('WIN %', '${record.winPct}'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border:
                        i == 0
                            ? null
                            : Border(
                              left: BorderSide(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cells[i].$1,
                        style: tpMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cells[i].$2,
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TpActionRow extends ConsumerWidget {
  const TpActionRow({
    super.key,
    required this.teamId,
    required this.viewer,
    required this.team,
    required this.heroColor,
  });

  final String teamId;
  final TeamPageViewer viewer;
  final TpTeam team;
  final Color heroColor;

  List<_Action> _actionsFor(BuildContext context, WidgetRef ref) {
    if (team.archived != null) {
      return const [
        _Action(label: 'Read-only archive', icon: Icons.access_time),
        _Action(icon: Icons.ios_share, iconOnly: true),
      ];
    }
    switch (viewer) {
      case TeamPageViewer.owner:
      case TeamPageViewer.captain:
        return [
          _Action(
            label: 'Manage',
            icon: Icons.dashboard_outlined,
            primary: true,
            onTap: () => context.push('/teams/$teamId/manage'),
          ),
          _Action(
            label: 'Post update',
            icon: Icons.edit_note_rounded,
            onTap: () {
              final uri = Uri(
                path: '/composer',
                queryParameters: {
                  'teamId': teamId,
                  'teamName': team.name,
                  if (team.mono.isNotEmpty) 'teamMono': team.mono,
                },
              );
              context.push(uri.toString());
            },
          ),
        ];
      case TeamPageViewer.player:
        return const [
          _Action(
            label: 'Team chat',
            icon: Icons.chat_bubble_outline,
            primary: true,
          ),
          _Action(label: 'My stats', icon: Icons.bar_chart),
        ];
      case TeamPageViewer.following:
        return [
          _followAction(ref),
          const _Action(label: 'Notify', icon: Icons.notifications_none),
        ];
      case TeamPageViewer.strangerPrivate:
        return [
          _joinAction(context, ref, primary: true),
        ];
      case TeamPageViewer.stranger:
        return [
          _followAction(ref),
          _joinAction(context, ref, primary: false),
        ];
    }
  }

  _Action _joinAction(BuildContext context, WidgetRef ref, {bool primary = false}) {
    return _Action(
      label: 'Request to join',
      icon: Icons.add_rounded,
      primary: primary,
      onTap: () => _showJoinRequestModal(context, ref),
    );
  }

  void _showJoinRequestModal(BuildContext context, WidgetRef ref) {
    final msgController = TextEditingController();
    String selectedRole = 'player';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Join ${team.name}',
                style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Send a join request to the team managers.',
                style: CkType.body(fontSize: 12.5, color: CkColors.muted),
              ),
              const SizedBox(height: 16),
              Text(
                'PLAYING ROLE',
                style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w700, color: CkColors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in [
                    (id: 'player', label: 'Squad Player'),
                    (id: 'wicket_keeper', label: 'Wicket-keeper'),
                  ])
                    ChoiceChip(
                      label: Text(r.label),
                      selected: selectedRole == r.id,
                      onSelected: (_) => setState(() => selectedRole = r.id),
                      selectedColor: CkColors.ink,
                      backgroundColor: CkColors.paper2,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedRole == r.id ? CkColors.paper : CkColors.ink,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'NOTE / MESSAGE (OPTIONAL)',
                style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w700, color: CkColors.muted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: msgController,
                maxLines: 3,
                style: CkType.body(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Right-arm fast bowler, available on weekends...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: CkColors.muted),
                  filled: true,
                  fillColor: CkColors.paper2,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: CkColors.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await ref.read(teamsRemoteDataSourceProvider).requestToJoinTeam(
                            teamId,
                            role: selectedRole,
                            message: msgController.text.trim(),
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Join request sent to team managers!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send request: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CkColors.ink,
                    foregroundColor: CkColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Send Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Action _followAction(WidgetRef ref) {
    final following = ref.watch(
      followToggleProvider('team', teamId),
    );
    final isFollowing = following.value ?? false;
    return _Action(
      label: isFollowing ? 'Following' : 'Follow',
      icon: isFollowing ? Icons.check : Icons.add,
      primary: true,
      onTap: () => ref
          .read(followToggleProvider('team', teamId).notifier)
          .toggle(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = _actionsFor(context, ref);
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _ActionButton(action: actions[i], heroColor: heroColor),
        ],
      ],
    );
  }
}

class _Action {
  const _Action({
    this.label,
    this.icon,
    this.primary = false,
    this.iconOnly = false,
    this.onTap,
  });
  final String? label;
  final IconData? icon;
  final bool primary;
  final bool iconOnly;
  final VoidCallback? onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.heroColor});
  final _Action action;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    final primary = action.primary;
    final body = Container(
      height: 44,
      padding: EdgeInsets.symmetric(
        horizontal: action.iconOnly ? 14 : (primary ? 0 : 14),
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border:
            primary
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (action.icon != null)
            Icon(
              action.icon,
              size: 14,
              color: primary ? heroColor : Colors.white,
            ),
          if (action.icon != null && action.label != null)
            const SizedBox(width: 6),
          if (action.label != null)
            Text(
              action.label!,
              style: CkType.body(
                fontSize: 13,
                fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                color: primary ? heroColor : Colors.white,
              ),
            ),
        ],
      ),
    );
    final tapped = action.onTap == null
        ? body
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: action.onTap,
            child: body,
          );
    if (primary || (!action.iconOnly && action.label != null)) {
      return Expanded(child: tapped);
    }
    return tapped;
  }
}

class TpCricketGroundPainter extends CustomPainter {
  const TpCricketGroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: size.width * 0.95,
        height: size.height * 0.85,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: size.width * 0.55,
        height: size.height * 0.5,
      ),
      paint,
    );
    canvas.drawRect(Rect.fromCenter(center: c, width: 16, height: 60), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
