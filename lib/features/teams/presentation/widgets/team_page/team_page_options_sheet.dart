import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_confirm_dialog.dart';
import '../../../../../core/widgets/ck_toast.dart';
import '../../../../follows/domain/entities/follow.dart';
import '../../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../../../follows/presentation/providers/follows_providers.dart';
import '../../../domain/entities/team.dart';
import '../../../domain/entities/team_relationship.dart';
import '../../controllers/team_page_controller.dart';
import '../../state/team_page_state.dart';
import '../../utils/team_share.dart';
import '../team_crest.dart';
import 'team_page_join_request_sheet.dart';

Future<void> showTeamPageOptionsSheet(
  BuildContext context, {
  required String teamId,
  required TeamPageState page,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CkColors.paper,
    barrierColor: CkColors.ink.withValues(alpha: 0.42),
    isScrollControlled: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CkRadii.lg)),
    ),
    builder: (_) => _TeamOptionsSheet(teamId: teamId, page: page),
  );
}

class _TeamOptionsSheet extends ConsumerStatefulWidget {
  const _TeamOptionsSheet({required this.teamId, required this.page});
  final String teamId;
  final TeamPageState page;

  @override
  ConsumerState<_TeamOptionsSheet> createState() => _TeamOptionsSheetState();
}

class _TeamOptionsSheetState extends ConsumerState<_TeamOptionsSheet> {
  Team get team => widget.page.team;
  TeamRelationship get relationship => widget.page.relationship;

  void _dismissThen(void Function(BuildContext pageContext) action) {
    final pageContext = Navigator.of(context).context;
    Navigator.of(context).pop();
    action(pageContext);
  }

  Future<void> _setStatus(
    BuildContext pageContext,
    TeamStatus status,
  ) async {
    if (status == TeamStatus.archived) {
      final confirmed = await showCkConfirmDialog(
        pageContext,
        icon: Icons.archive_outlined,
        title: 'Archive ${team.name}?',
        body: 'The team page becomes read-only. Posts, squad and match history '
            'stay visible as a record. ',
        emphasis: 'You can restore it any time',
        bodyTail: ' from the ⋯ menu.',
        confirmLabel: 'Archive team',
        cancelLabel: 'Keep it active',
      );
      if (!confirmed) return;
    }

    final error = await ref
        .read(teamPageControllerProvider(widget.teamId).notifier)
        .setStatus(status);
    if (!pageContext.mounted) return;
    CkToast.show(
      pageContext,
      message: error ??
          (status == TeamStatus.archived ? 'Team archived' : 'Team restored'),
      isError: error != null,
      icon: error == null
          ? (status == TeamStatus.archived
              ? Icons.archive_outlined
              : Icons.unarchive_outlined)
          : null,
    );
  }

  Future<void> _leave(BuildContext pageContext) async {
    final membership = widget.page.membership;
    if (membership == null) return;
    final confirmed = await showCkConfirmDialog(
      pageContext,
      icon: Icons.logout,
      title: 'Leave ${team.name}?',
      body: 'You’ll be removed from the active squad. Historical scorecards '
          'remain part of the team record. ',
      emphasis: 'This can’t be undone',
      bodyTail: ' — a manager would have to invite you back.',
      confirmLabel: 'Leave team',
      cancelLabel: 'Stay in the squad',
      destructive: true,
    );
    if (!confirmed) return;

    final error = await ref
        .read(teamPageControllerProvider(widget.teamId).notifier)
        .leaveTeam(membership.member.id);
    if (!pageContext.mounted) return;
    CkToast.show(
      pageContext,
      message: error ?? 'You left ${team.name}',
      isError: error != null,
      icon: error == null ? Icons.logout : null,
    );
  }

  Future<void> _setNotifications(bool enabled) async {
    final result = await ref.read(followsRepositoryProvider).setNotificationsEnabled(
          TeamFollowTarget(TeamId(widget.teamId)),
          enabled: enabled,
        );
    if (!mounted) return;
    result.fold(
      (failure) => CkToast.show(context, message: failure.message, isError: true),
      (_) {
        ref.invalidate(teamNotificationsEnabledProvider(widget.teamId));
        CkToast.show(
          context,
          message: enabled ? 'Notifications on for ${team.name}' : 'Notifications off',
          icon: enabled ? Icons.notifications : Icons.notifications_off_outlined,
        );
      },
    );
  }

  Future<void> _unfollow(BuildContext pageContext) async {
    await ref
        .read(followToggleProvider('team', widget.teamId).notifier)
        .toggle();
    if (!pageContext.mounted) return;
    CkToast.show(
      pageContext,
      message: 'Unfollowed ${team.name}',
      icon: Icons.person_remove_outlined,
    );
  }

  List<Widget> _rows() {
    final share = _OptionRow(
      icon: Icons.ios_share,
      label: 'Share team',
      onTap: () => _dismissThen(
        (ctx) => shareTeam(
          ctx,
          teamId: widget.teamId,
          teamName: team.name,
        ),
      ),
    );
    final copy = _OptionRow(
      icon: Icons.content_copy,
      label: 'Copy link',
      subline: teamShareLink(widget.teamId).replaceFirst('https://', ''),
      onTap: () => _dismissThen(
        (ctx) => copyTeamLink(ctx, teamId: widget.teamId),
      ),
    );

    if (team.isArchived) {
      return [
        share,
        copy,
        if (relationship == TeamRelationship.owner) ...[
          const _RowDivider(),
          _OptionRow(
            icon: Icons.unarchive_outlined,
            label: 'Restore team',
            subline: 'Brings the page back to life',
            onTap: () => _dismissThen(
              (ctx) => _setStatus(ctx, TeamStatus.active),
            ),
          ),
        ],
      ];
    }

    if (relationship.isStaff) {
      return [
        share,
        copy,
        _OptionRow(
          icon: Icons.edit_outlined,
          label: 'Edit team',
          subline: 'Name, logo, colour, tagline',
          chevron: true,
          onTap: () => _dismissThen(
            (ctx) => ctx.push('/teams/${widget.teamId}/manage?tab=settings'),
          ),
        ),
        _OptionRow(
          icon: Icons.person_add_alt,
          label: 'Invite players',
          subline: 'Add to the squad or invite by link',
          chevron: true,
          onTap: () => _dismissThen(
            (ctx) => ctx.push('/teams/${widget.teamId}/manage?tab=roster'),
          ),
        ),
        _OptionRow(
          icon: Icons.settings_outlined,
          label: 'Team settings',
          subline: 'Privacy, roles, squad size',
          chevron: true,
          onTap: () => _dismissThen(
            (ctx) => ctx.push('/teams/${widget.teamId}/manage?tab=settings'),
          ),
        ),
        if (relationship == TeamRelationship.owner) ...[
          const _RowDivider(),
          _OptionRow(
            icon: Icons.archive_outlined,
            label: 'Archive team',
            subline: 'Makes the page read-only. You can restore it later.',
            destructive: true,
            onTap: () => _dismissThen(
              (ctx) => _setStatus(ctx, TeamStatus.archived),
            ),
          ),
        ] else ...[
          const _RowDivider(),
          _OptionRow(
            icon: Icons.logout,
            label: 'Leave team',
            destructive: true,
            onTap: () => _dismissThen(_leave),
          ),
        ],
      ];
    }

    if (relationship.isMember) {
      return [
        share,
        copy,
        const _RowDivider(),
        _OptionRow(
          icon: Icons.logout,
          label: 'Leave team',
          subline: 'Historical match records remain intact',
          destructive: true,
          onTap: () => _dismissThen(_leave),
        ),
      ];
    }

    final following = ref.watch(followToggleProvider('team', widget.teamId)).value ?? false;
    if (following) {
      return [
        share,
        copy,
        _NotificationsRow(teamId: widget.teamId, onChanged: _setNotifications),
        _OptionRow(
          icon: Icons.person_remove_outlined,
          label: 'Unfollow',
          onTap: () => _dismissThen(_unfollow),
        ),
      ];
    }

    return [
      share,
      copy,
      if (widget.page.canRequestJoin)
        _OptionRow(
          icon: Icons.person_add_alt,
          label: 'Request to join',
          subline: 'The owner or a manager approves requests',
          onTap: () => _dismissThen(
            (ctx) => showTeamJoinRequestSheet(
              ctx,
              teamId: widget.teamId,
              teamName: team.name,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom + 34,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: CkColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: _SheetHeader(page: widget.page),
              ),
              const Divider(height: 1, thickness: 1, color: CkColors.hairline),
              const SizedBox(height: 6),
              ..._rows(),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.page});
  final TeamPageState page;

  @override
  Widget build(BuildContext context) {
    final team = page.team;
    final chip = team.isArchived
        ? 'ARCHIVED'
        : switch (page.relationship) {
            TeamRelationship.owner => 'OWNER',
            TeamRelationship.manager => 'MANAGER',
            TeamRelationship.captain => 'CAPTAIN',
            TeamRelationship.player => 'PLAYER',
            TeamRelationship.none => team.privacy == TeamPrivacy.private
                ? 'PRIVATE'
                : 'PUBLIC',
          };
    final where = [
      team.type.wire.toUpperCase(),
      if (team.homeGround?.trim().isNotEmpty ?? false)
        team.homeGround!.toUpperCase(),
    ].join(' · ');

    return Row(
      children: [
        TeamCrest(
          name: team.name,
          primaryColor: team.primaryColor,
          logoUrl: team.logoUrl,
          crestKind: team.crestKind,
          monogram: team.logoMonogram,
          size: 44,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.display(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(where, style: CkType.mono(fontSize: 9, color: CkColors.muted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Text(
            chip,
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: CkColors.ink2,
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    this.subline,
    this.chevron = false,
    this.destructive = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? subline;
  final bool chevron;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 20, color: destructive ? CkColors.red : CkColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: CkType.body(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: destructive ? CkColors.red : CkColors.ink,
                      ),
                    ),
                    if (subline != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subline!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (chevron)
                const Icon(Icons.chevron_right_rounded, size: 18, color: CkColors.muted),
            ],
          ),
        ),
      );
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, color: CkColors.hairline),
      );
}

class _NotificationsRow extends ConsumerWidget {
  const _NotificationsRow({required this.teamId, required this.onChanged});
  final String teamId;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(teamNotificationsEnabledProvider(teamId)).value ?? false;
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      secondary: const Icon(Icons.notifications_none, color: CkColors.ink),
      title: Text(
        'Notifications',
        style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      value: enabled,
      onChanged: (value) => onChanged(value),
    );
  }
}
