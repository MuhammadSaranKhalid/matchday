import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/util/surface_mode.dart';
import '../../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../../domain/entities/team.dart';
import '../../../domain/entities/team_relationship.dart';
import '../../state/team_page_state.dart';
import '../../utils/team_display.dart';
import '../team_crest.dart';
import 'team_page_join_request_sheet.dart';
import 'team_page_visuals.dart';

class TeamPageHeader extends ConsumerWidget {
  const TeamPageHeader({
    super.key,
    required this.teamId,
    required this.page,
    this.onBack,
    this.onShare,
    this.onOptions,
  });

  final String teamId;
  final TeamPageState page;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = page.team;
    final color = parseHexColor(team.primaryColor, fallback: CkColors.ink);
    final mode = surfaceModeFor(color);
    final primaryInk = mode.isInk ? CkColors.ink : Colors.white;
    final secondaryInk =
        mode.isInk ? CkColors.ink2 : Colors.white.withValues(alpha: 0.85);
    final hasLive = page.matches.any((match) => match.status.isLive);

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
                painter: TeamPageGroundPainter(
                  color: mode.isInk
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TeamPageIconButton(
                            icon: Icons.arrow_back,
                            mode: mode,
                            onTap: onBack,
                            tooltip: 'Back',
                          ),
                          Row(
                            children: [
                              TeamPageIconButton(
                                icon: Icons.ios_share,
                                mode: mode,
                                onTap: onShare,
                                tooltip: 'Share team',
                              ),
                              TeamPageIconButton(
                                icon: Icons.more_horiz,
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
                  if (team.isArchived)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: _ArchivedStrip(
                        archived: DateFormat('d MMM yyyy')
                            .format(team.updatedAt.toLocal()),
                        mode: mode,
                        canRestore: page.relationship == TeamRelationship.owner,
                      ),
                    )
                  else ...[
                    if (hasLive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: _LiveBadge(mode: mode),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: _ActionRow(
                        teamId: teamId,
                        page: page,
                        mode: mode,
                        heroColor: color,
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

  final Team team;
  final CkSurfaceMode mode;
  final Color primaryInk;
  final Color secondaryInk;

  @override
  Widget build(BuildContext context) {
    final hasTagline = team.tagline?.trim().isNotEmpty ?? false;
    final eyebrow = [
      team.type.wire.toUpperCase(),
      if (team.city?.trim().isNotEmpty ?? false) team.city!.toUpperCase(),
    ].join(' · ');
    final nameSize = team.name.length <= 16
        ? 28.0
        : team.name.length <= 20
            ? 24.0
            : 21.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TeamCrest(
          name: team.name,
          primaryColor: team.primaryColor,
          logoUrl: team.logoUrl,
          crestKind: team.crestKind,
          monogram: team.logoMonogram,
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
                  if (team.isVerified) ...[
                    const SizedBox(width: 6),
                    TeamPageVerifiedTick(color: primaryInk),
                  ],
                ],
              ),
              SizedBox(height: hasTagline ? 3 : 4),
              Text(
                team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.display(
                  fontSize: nameSize,
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

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.mode});
  final CkSurfaceMode mode;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: CkColors.red,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TeamPageLivePulse(),
            const SizedBox(width: 5),
            Text(
              'PLAYING NOW',
              style: teamPageMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
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
    final label = mode.isInk ? CkColors.ink : Colors.white;
    final sub = mode.isInk ? CkColors.ink2 : Colors.white.withValues(alpha: 0.82);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 9, 5),
          decoration: BoxDecoration(
            color: mode.isInk
                ? CkColors.ink.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
            border: mode.isInk
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
                style: teamPageMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: label,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Archived $archived${canRestore ? ' · Restore from the ⋯ menu' : ''}',
          style: CkType.body(fontSize: 11.5, color: sub),
        ),
      ],
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({
    required this.teamId,
    required this.page,
    required this.mode,
    required this.heroColor,
  });

  final String teamId;
  final TeamPageState page;
  final CkSurfaceMode mode;
  final Color heroColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <_Action>[];
    final relationship = page.relationship;

    if (relationship.isStaff) {
      actions.addAll([
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
                'teamName': page.team.name,
                if (page.team.logoMonogram?.isNotEmpty ?? false)
                  'teamMono': page.team.logoMonogram!,
              },
            );
            context.push(uri.toString());
          },
        ),
      ]);
    } else if (relationship.isMember) {
      actions.addAll(const [
        _Action(
          label: 'Team chat',
          icon: Icons.chat_bubble_outline,
          primary: true,
        ),
        _Action(label: 'My stats', icon: Icons.bar_chart),
      ]);
    } else {
      final following = ref.watch(followToggleProvider('team', teamId)).value ?? false;
      actions.add(
        _Action(
          label: following ? 'Following' : 'Follow',
          icon: following ? Icons.check : Icons.add,
          primary: true,
          onTap: () =>
              ref.read(followToggleProvider('team', teamId).notifier).toggle(),
        ),
      );
      if (page.canRequestJoin) {
        actions.add(
          _Action(
            label: 'Request to join',
            icon: Icons.add_rounded,
            onTap: () => showTeamJoinRequestSheet(
              context,
              teamId: teamId,
              teamName: page.team.name,
            ),
          ),
        );
      }
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              action: actions[i],
              mode: mode,
              heroColor: heroColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _Action {
  const _Action({
    required this.label,
    required this.icon,
    this.primary = false,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.mode,
    required this.heroColor,
  });
  final _Action action;
  final CkSurfaceMode mode;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    final fill = action.primary
        ? (mode.isInk ? CkColors.ink : Colors.white)
        : Colors.transparent;
    final foreground = action.primary
        ? (mode.isInk ? CkColors.paper : heroColor)
        : (mode.isInk ? CkColors.ink : Colors.white);
    final border = action.primary
        ? null
        : Border.all(
            color: mode.isInk
                ? CkColors.ink.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.42),
            width: mode.isInk ? 1.5 : 1,
          );

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(CkRadii.md),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: border,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.body(
                  fontSize: 13,
                  fontWeight: action.primary ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
