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
import '../../../domain/entities/team_member.dart';
import '../../providers/teams_providers.dart';
import '../../utils/team_display.dart';
import '../../utils/team_share.dart';
import '../team_crest.dart';
import 'tp_join_request_sheet.dart';
import 'tp_view.dart';

/// The ⋯ menu.
///
/// A bottom sheet rather than a floating popup — it's the app's established
/// pattern, and it has room for the sublines that make an infrequent,
/// consequential action legible ("Makes the page read-only. You can restore
/// it later.").
///
/// The list swaps per viewer role; the header row and row anatomy never do.
Future<void> showTeamOptionsSheet(
  BuildContext context, {
  required String teamId,
  required TpTeam team,
  required TeamPageViewer viewer,
  required String? viewerMembershipId,
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
    builder: (_) => _TeamOptionsSheet(
      teamId: teamId,
      team: team,
      viewer: viewer,
      viewerMembershipId: viewerMembershipId,
    ),
  );
}

class _TeamOptionsSheet extends ConsumerStatefulWidget {
  const _TeamOptionsSheet({
    required this.teamId,
    required this.team,
    required this.viewer,
    required this.viewerMembershipId,
  });

  final String teamId;
  final TpTeam team;
  final TeamPageViewer viewer;
  final String? viewerMembershipId;

  @override
  ConsumerState<_TeamOptionsSheet> createState() => _TeamOptionsSheetState();
}

class _TeamOptionsSheetState extends ConsumerState<_TeamOptionsSheet> {
  bool get _archived => widget.team.archived != null;
  bool get _isOwner => widget.viewer == TeamPageViewer.owner;

  /// Closes the sheet, then runs [action] against the *page's* context — the
  /// sheet's own context is gone by the time a toast or dialog needs one.
  void _dismissThen(void Function(BuildContext pageContext) action) {
    final pageContext = Navigator.of(context).context;
    Navigator.of(context).pop();
    action(pageContext);
  }

  Future<void> _archive(BuildContext pageContext) async {
    final confirmed = await showCkConfirmDialog(
      pageContext,
      icon: Icons.archive_outlined,
      title: 'Archive ${widget.team.name}?',
      body: 'The team page becomes read-only. Posts, squad and stats stay '
          'visible as a record, but nobody can post, join or follow. ',
      emphasis: 'You can restore it any time',
      bodyTail: ' from the ⋯ menu.',
      confirmLabel: 'Archive team',
      cancelLabel: 'Keep it active',
    );
    if (!confirmed) return;
    final result = await ref.read(teamsRepositoryProvider).setTeamStatus(
          teamId: TeamId(widget.teamId),
          status: TeamStatus.archived,
        );
    if (!pageContext.mounted) return;
    result.fold(
      (f) => CkToast.show(
        pageContext,
        message: f.message,
        isError: true,
      ),
      (_) => CkToast.show(
        pageContext,
        message: 'Team archived',
        icon: Icons.archive_outlined,
        actionLabel: 'Undo',
        onAction: () => _restore(pageContext, silent: true),
      ),
    );
  }

  Future<void> _restore(BuildContext pageContext, {bool silent = false}) async {
    final result = await ref.read(teamsRepositoryProvider).setTeamStatus(
          teamId: TeamId(widget.teamId),
          status: TeamStatus.active,
        );
    if (!pageContext.mounted) return;
    result.fold(
      (f) => CkToast.show(pageContext, message: f.message, isError: true),
      (_) => CkToast.show(
        pageContext,
        message: silent ? 'Team restored' : '${widget.team.name} is back',
        icon: Icons.unarchive_outlined,
      ),
    );
  }

  Future<void> _leave(BuildContext pageContext) async {
    final membershipId = widget.viewerMembershipId;
    if (membershipId == null) return;
    final confirmed = await showCkConfirmDialog(
      pageContext,
      icon: Icons.logout,
      title: 'Leave ${widget.team.name}?',
      body: 'You’ll be removed from the squad and your batting and bowling '
          'records for this team stop counting toward it. ',
      emphasis: 'This can’t be undone',
      bodyTail: ' — the owner would have to invite you back.',
      confirmLabel: 'Leave team',
      cancelLabel: 'Stay in the squad',
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref
        .read(teamsRepositoryProvider)
        .leaveTeam(MembershipId(membershipId));
    if (!pageContext.mounted) return;
    result.fold(
      (f) => CkToast.show(pageContext, message: f.message, isError: true),
      (_) => CkToast.show(
        pageContext,
        message: 'You left ${widget.team.name}',
        icon: Icons.logout,
      ),
    );
  }

  Future<void> _setNotifications(bool enabled) async {
    final result =
        await ref.read(followsRepositoryProvider).setNotificationsEnabled(
              TeamFollowTarget(TeamId(widget.teamId)),
              enabled: enabled,
            );
    if (!mounted) return;
    result.fold(
      (f) => CkToast.show(context, message: f.message, isError: true),
      (_) {
        ref.invalidate(teamNotificationsEnabledProvider(widget.teamId));
        CkToast.show(
          context,
          message: enabled
              ? 'Notifications on for ${widget.team.name}'
              : 'Notifications off',
          icon: enabled
              ? Icons.notifications
              : Icons.notifications_off_outlined,
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
      message: 'Unfollowed ${widget.team.name}',
      icon: Icons.person_remove_outlined,
    );
  }

  // ── The lists ──────────────────────────────────────────────────────────

  List<Widget> _rows() {
    final share = _OptionRow(
      icon: Icons.ios_share,
      label: 'Share team',
      onTap: () => _dismissThen(
        (ctx) => shareTeam(
          ctx,
          teamId: widget.teamId,
          teamName: widget.team.name,
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

    // An archived team is a record. Everything but sharing is suppressed —
    // hidden, not disabled — except the owner's way back out.
    if (_archived) {
      return [
        share,
        copy,
        if (_isOwner) ...[
          const _RowDivider(),
          _OptionRow(
            icon: Icons.unarchive_outlined,
            label: 'Restore team',
            subline: 'Brings the page back to life',
            onTap: () => _dismissThen(_restore),
          ),
        ],
      ];
    }

    switch (widget.viewer) {
      case TeamPageViewer.owner:
      case TeamPageViewer.captain:
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
          // Settings and archive are the owner's alone: a captain edits the
          // team, only the owner can end it.
          if (_isOwner) ...[
            _OptionRow(
              icon: Icons.settings_outlined,
              label: 'Team settings',
              subline: 'Privacy, roles, squad size',
              chevron: true,
              onTap: () => _dismissThen(
                (ctx) =>
                    ctx.push('/teams/${widget.teamId}/manage?tab=settings'),
              ),
            ),
            const _RowDivider(),
            _OptionRow(
              icon: Icons.archive_outlined,
              label: 'Archive team',
              subline: 'Makes the page read-only. You can restore it later.',
              destructive: true,
              onTap: () => _dismissThen(_archive),
            ),
          ],
        ];

      case TeamPageViewer.player:
        return [
          share,
          copy,
          if (widget.viewerMembershipId != null) ...[
            const _RowDivider(),
            _OptionRow(
              icon: Icons.logout,
              label: 'Leave team',
              subline: 'You’ll lose your squad stats history',
              destructive: true,
              onTap: () => _dismissThen(_leave),
            ),
          ],
        ];

      case TeamPageViewer.following:
        return [
          share,
          copy,
          _NotificationsRow(
            teamId: widget.teamId,
            onChanged: _setNotifications,
          ),
          _OptionRow(
            icon: Icons.person_remove_outlined,
            label: 'Unfollow',
            onTap: () => _dismissThen(_unfollow),
          ),
        ];

      case TeamPageViewer.stranger:
      case TeamPageViewer.strangerPrivate:
        return [
          share,
          copy,
          _OptionRow(
            icon: Icons.person_add_alt,
            label: 'Request to join',
            subline: widget.viewer == TeamPageViewer.strangerPrivate
                ? 'Squad and stats stay hidden until you’re in'
                : 'The owner approves requests',
            onTap: () => _dismissThen(
              (ctx) => showTeamJoinRequestSheet(
                ctx,
                teamId: widget.teamId,
                teamName: widget.team.name,
              ),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            // Header — says what the sheet acts on. Without it a list of
            // verbs floats free of its object.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _SheetHeader(
                team: widget.team,
                viewer: widget.viewer,
                archived: _archived,
              ),
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
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.team,
    required this.viewer,
    required this.archived,
  });

  final TpTeam team;
  final TeamPageViewer viewer;
  final bool archived;

  (String, IconData?) get _chip {
    if (archived) return ('ARCHIVED', Icons.archive_outlined);
    return switch (viewer) {
      TeamPageViewer.owner => ('OWNER', null),
      TeamPageViewer.captain => ('CAPTAIN', null),
      TeamPageViewer.player => ('PLAYER', null),
      TeamPageViewer.following => ('FOLLOWING', null),
      TeamPageViewer.stranger => ('PUBLIC', null),
      TeamPageViewer.strangerPrivate => ('PRIVATE', Icons.lock_outline),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _chip;
    final where = [
      team.type.toUpperCase(),
      if (team.city.trim().isNotEmpty) team.city.toUpperCase(),
    ].join(' · ');

    return Row(
      children: [
        TeamCrest(
          name: team.name,
          primaryColor: hexOf(team.primary),
          logoUrl: team.logoUrl,
          crestKind: team.crestKind,
          monogram: team.mono,
          size: 44,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.display(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                where,
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CkColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: CkColors.ink2),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One row of the menu.
///
/// The icon column is fixed at 20px with a 14px gap, so every label in every
/// role variant starts at the same x — the lists differ, the rhythm doesn't.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    this.subline,
    this.onTap,
    this.chevron = false,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? subline;
  final VoidCallback? onTap;
  final bool chevron;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? CkColors.red : CkColors.ink;
    final row = Container(
      height: subline == null ? 52 : 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CkType.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tint,
                  ),
                ),
                if (subline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subline!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (chevron)
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: CkColors.soft,
            ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Flat app: a tint, not a ripple.
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: CkColors.paper2,
        child: row,
      ),
    );
  }
}

/// Hairline before a destructive row — never at the top of a list, never one
/// thumb-slip from a routine action.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1, thickness: 1, color: CkColors.hairline),
      );
}

class _NotificationsRow extends ConsumerWidget {
  const _NotificationsRow({required this.teamId, required this.onChanged});

  final String teamId;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(teamNotificationsEnabledProvider(teamId)).value ?? false;
    return _OptionRow(
      icon: enabled ? Icons.notifications : Icons.notifications_none,
      label: 'Notifications',
      subline: 'Match results and posts',
      onTap: () => onChanged(!enabled),
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: onChanged,
        activeTrackColor: CkColors.ink,
        inactiveTrackColor: CkColors.paper2,
      ),
    );
  }
}
