import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/util/surface_mode.dart';
import '../../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../utils/team_display.dart';
import '../team_crest.dart';
import 'tp_atoms.dart';
import 'tp_join_request_sheet.dart';
import 'tp_view.dart';

/// Hero header — the team's own colour, a circular crest, and the chrome that
/// sits on top of it.
///
/// The ground here is **data, not brand**: `teams.team_colors.primary` is one
/// of twelve owner-chosen swatches spanning near-black to pale cream. White
/// chrome fails on the pale two, so the whole hero carries an ink ramp that
/// flips on the ground's WCAG luminance ([surfaceModeFor]) rather than
class TpHero extends StatelessWidget {
  const TpHero({
    super.key,
    required this.teamId,
    required this.team,
    required this.viewer,
    required this.badges,
    this.hasPendingInvite = false,
    this.onBack,
    this.onShare,
    this.onOptions,
  });

  final String teamId;
  final TpTeam team;
  final TeamPageViewer viewer;
  final List<TpHeroBadge> badges;
  final bool hasPendingInvite;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onOptions;

  bool get _archived => team.archived != null;

  @override
  Widget build(BuildContext context) {
    final color = team.primary;
    final mode = surfaceModeFor(color);
    final ink = mode.isInk;

    // The whole ramp derives from the two lines below; nothing downstream
    // hard-codes white.
    final primaryInk = ink ? CkColors.ink : Colors.white;
    final secondaryInk =
        ink ? CkColors.ink2 : Colors.white.withValues(alpha: 0.85);

    return ColoredBox(
      color: color,
      child: Stack(
        children: [
          Positioned(
            top: -96,
            right: -118,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(340, 250),
                painter: TpCricketGroundPainter(
                  color: ink
                      ? CkColors.ink.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Button row: laid out at 10px so the 44pt hit boxes inset
                  // 4px inside themselves and the discs still land on the
                  // hero's 14px optical margin.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TpIconBtn(
                            icon: Icons.arrow_back,
                            onColor: true,
                            mode: mode,
                            onTap: onBack,
                            tooltip: 'Back',
                          ),
                          Row(
                            children: [
                              TpIconBtn(
                                icon: Icons.ios_share,
                                onColor: true,
                                mode: mode,
                                onTap: onShare,
                                tooltip: 'Share team',
                              ),
                              TpIconBtn(
                                icon: Icons.more_horiz,
                                onColor: true,
                                mode: mode,
                                onTap: onOptions,
                                tooltip: 'More',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _Identity(
                      team: team,
                      mode: mode,
                      primaryInk: primaryInk,
                      secondaryInk: secondaryInk,
                    ),
                  ),

                  // An archived team is a record: the rows that invite action
                  // are removed, not disabled, and the way back is named.
                  if (_archived)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: _ArchivedStrip(
                        archived: team.archived!,
                        mode: mode,
                        canRestore: viewer == TeamPageViewer.owner,
                      ),
                    )
                  else ...[
                    if (badges.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: _BadgesRow(badges: badges, mode: mode),
                      ),
                    if (team.record != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: _RecordStrip(record: team.record!, mode: mode),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: TpActionRow(
                        teamId: teamId,
                        viewer: viewer,
                        team: team,
                        mode: mode,
                        hasPendingInvite: hasPendingInvite,
                      ),
                    ),
                  ],
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
    required this.mode,
    required this.primaryInk,
    required this.secondaryInk,
  });

  final TpTeam team;
  final CkSurfaceMode mode;
  final Color primaryInk;
  final Color secondaryInk;

  /// The name never wraps — a second line pushes the tagline into the badges.
  /// It steps down twice, then ellipsises.
  double _nameSize(String name) {
    if (name.length <= 16) return 28;
    if (name.length <= 20) return 24;
    return 21;
  }

  @override
  Widget build(BuildContext context) {
    final hasTagline = team.tagline != null && team.tagline!.trim().isNotEmpty;
    final eyebrow = [
      team.type.toUpperCase(),
      if (team.area.trim().isNotEmpty) team.area.toUpperCase(),
      if (team.city.trim().isNotEmpty) team.city.toUpperCase(),
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TeamCrest(
          name: team.name,
          primaryColor: hexOf(team.primary),
          logoUrl: team.logoUrl,
          crestKind: team.crestKind,
          monogram: team.mono,
          size: 72,
          onLightSurface: mode.isInk,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.14,
                        color: secondaryInk,
                      ),
                    ),
                  ),
                  if (team.verified) ...[
                    const SizedBox(width: 6),
                    TpVerifiedTick(color: primaryInk),
                  ],
                ],
              ),
              // With no tagline the stack loses its counterweight, so the
              // eyebrow tucks closer to the name.
              SizedBox(height: hasTagline ? 3 : 4),
              Text(
                team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.display(
                  fontSize: _nameSize(team.name),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.03,
                  height: 1.05,
                  color: primaryInk,
                ),
              ),
              if (hasTagline) ...[
                const SizedBox(height: 3),
                Text(
                  '“${team.tagline}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 13,
                    height: 1.35,
                    color: secondaryInk,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ArchivedStrip extends StatelessWidget {
  const _ArchivedStrip({
    required this.archived,
    required this.mode,
    required this.canRestore,
  });

  final String archived;
  final CkSurfaceMode mode;
  final bool canRestore;

  @override
  Widget build(BuildContext context) {
    final ink = mode.isInk;
    final label = ink ? CkColors.ink : Colors.white;
    final sub = ink ? CkColors.ink2 : Colors.white.withValues(alpha: 0.82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 9, 5),
          decoration: BoxDecoration(
            color: ink
                ? CkColors.ink.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
            border: ink
                ? Border.all(color: CkColors.ink.withValues(alpha: 0.14))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.archive_outlined, size: 12, color: label),
              const SizedBox(width: 5),
              Text(
                'ARCHIVED · READ-ONLY',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: label,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          canRestore
              ? 'Archived $archived · you can restore it from ⋯'
              : 'Archived $archived · this page is kept as a record',
          style: CkType.body(fontSize: 12.5, color: sub),
        ),
      ],
    );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.badges, required this.mode});

  final List<TpHeroBadge> badges;
  final CkSurfaceMode mode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final b in badges) _Badge(badge: b, mode: mode)],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge, required this.mode});

  final TpHeroBadge badge;
  final CkSurfaceMode mode;

  @override
  Widget build(BuildContext context) {
    final ink = mode.isInk;
    final isRed = badge.tone == TpHeroBadgeTone.red;
    // The red pill keeps its own ground in both modes — it is a status, not
    // chrome, and white on Cricket Red holds either way.
    final label = isRed
        ? Colors.white
        : ink
            ? CkColors.ink2
            : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: isRed
            ? CkColors.red
            : ink
                ? CkColors.ink.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: (ink && !isRed)
            ? Border.all(color: CkColors.ink.withValues(alpha: 0.14))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.pulse) ...[
            TpLivePulse(color: label),
            const SizedBox(width: 5),
          ],
          Text(
            badge.label.toUpperCase(),
            style: tpMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: label,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordStrip extends StatelessWidget {
  const _RecordStrip({required this.record, required this.mode});

  final TpRecord record;
  final CkSurfaceMode mode;

  @override
  Widget build(BuildContext context) {
    final ink = mode.isInk;
    final figures = ink ? CkColors.ink : Colors.white;
    final labels =
        ink ? CkColors.ink2 : Colors.white.withValues(alpha: 0.72);
    final divider = ink
        ? CkColors.ink.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.14);

    final cells = <(String, String)>[
      ('PLAYED', '${record.played}'),
      ('WON', '${record.won}'),
      ('LOST', '${record.lost}'),
      ('WIN %', '${record.winPct}'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: ink
            ? CkColors.ink.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: ink ? Border.all(color: divider) : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(left: BorderSide(color: divider)),
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
                          color: labels,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cells[i].$2,
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: figures,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    required this.mode,
    this.hasPendingInvite = false,
  });

  final String teamId;
  final TeamPageViewer viewer;
  final TpTeam team;
  final CkSurfaceMode mode;
  final bool hasPendingInvite;

  List<_Action> _actionsFor(BuildContext context, WidgetRef ref) {
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
        return hasPendingInvite
            ? const []
            : [_joinAction(context, primary: true)];
      case TeamPageViewer.stranger:
        return [
          _followAction(ref),
          if (!hasPendingInvite) _joinAction(context, primary: false),
        ];
    }
  }

  _Action _joinAction(BuildContext context, {bool primary = false}) {
    return _Action(
      label: 'Request to join',
      icon: Icons.add_rounded,
      primary: primary,
      onTap: () => showTeamJoinRequestSheet(
        context,
        teamId: teamId,
        teamName: team.name,
      ),
    );
  }

  _Action _followAction(WidgetRef ref) {
    final following = ref.watch(followToggleProvider('team', teamId));
    final isFollowing = following.value ?? false;
    return _Action(
      label: isFollowing ? 'Following' : 'Follow',
      icon: isFollowing ? Icons.check : Icons.add,
      primary: true,
      onTap: () =>
          ref.read(followToggleProvider('team', teamId).notifier).toggle(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = _actionsFor(context, ref);
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _ActionButton(
            action: actions[i],
            heroColor: team.primary,
            mode: mode,
          ),
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
    this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool primary;
  final VoidCallback? onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.heroColor,
    required this.mode,
  });

  final _Action action;
  final Color heroColor;
  final CkSurfaceMode mode;

  @override
  Widget build(BuildContext context) {
    final ink = mode.isInk;
    final primary = action.primary;

    // On a pale hero a white button is invisible, so the fill inverts to ink
    // and the outline thickens to hold its edge.
    final Color fill = primary
        ? (ink ? CkColors.ink : Colors.white)
        : Colors.transparent;
    final Color foreground = primary
        ? (ink ? CkColors.paper : heroColor)
        : (ink ? CkColors.ink : Colors.white);
    final Border? border = primary
        ? null
        : Border.all(
            color: ink
                ? CkColors.ink.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.42),
            width: ink ? 1.5 : 1,
          );

    final body = Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: primary ? 0 : 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (action.icon != null)
            Icon(action.icon, size: 14, color: foreground),
          if (action.icon != null && action.label != null)
            const SizedBox(width: 6),
          if (action.label != null)
            Flexible(
              child: Text(
                action.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.body(
                  fontSize: 13,
                  fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                ),
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

    return Expanded(child: tapped);
  }
}

/// The cricket-ground motif that bleeds off the hero's top-right corner.
class TpCricketGroundPainter extends CustomPainter {
  const TpCricketGroundPainter({this.color = Colors.white});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // Outer ring is a broad band, not a hairline — at 10% opacity a thin
    // stroke disappears against a mid-tone primary.
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 340 - 22, height: 250 - 22),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22,
    );

    final thin = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCenter(center: c, width: 224, height: 158),
      thin,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 26, height: 96),
        const Radius.circular(3),
      ),
      thin,
    );
  }

  @override
  bool shouldRepaint(TpCricketGroundPainter old) => old.color != color;
}
