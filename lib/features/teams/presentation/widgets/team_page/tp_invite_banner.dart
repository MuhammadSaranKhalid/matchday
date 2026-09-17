import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_toast.dart';
import '../../../domain/entities/team_invite.dart';
import '../../controllers/teams_list_controller.dart';
import '../../providers/teams_providers.dart';
import 'tp_atoms.dart';

/// Card displayed on the Team Page when the current user has a pending invitation to join.
class TpInviteBanner extends ConsumerStatefulWidget {
  const TpInviteBanner({
    super.key,
    required this.invite,
    required this.teamId,
    required this.teamName,
  });

  final TeamInvite invite;
  final String teamId;
  final String teamName;

  @override
  ConsumerState<TpInviteBanner> createState() => _TpInviteBannerState();
}

class _TpInviteBannerState extends ConsumerState<TpInviteBanner> {
  bool _accepting = false;
  bool _declining = false;

  bool get _busy => _accepting || _declining;

  Future<void> _handleAccept() async {
    if (_busy) return;
    setState(() => _accepting = true);
    final result = await ref
        .read(teamsRepositoryProvider)
        .acceptTeamInvite(widget.invite.inviteId);
    if (!mounted) return;
    setState(() => _accepting = false);

    result.fold(
      (failure) =>
          CkToast.show(context, message: failure.message, isError: true),
      (_) {
        CkToast.show(
          context,
          message: 'Welcome to ${widget.teamName}!',
          icon: Icons.check_circle_outline,
        );
        ref.invalidate(myPendingInviteForTeamProvider(widget.teamId));
        ref.invalidate(teamProvider(widget.teamId));
        ref.invalidate(rosterProvider(widget.teamId));
        ref.invalidate(myTeamsProvider);
        ref.invalidate(myTeamRolesProvider);
        ref.invalidate(teamsListControllerProvider);
      },
    );
  }

  Future<void> _handleDecline() async {
    if (_busy) return;
    setState(() => _declining = true);
    final result = await ref
        .read(teamsRepositoryProvider)
        .declineTeamInvite(widget.invite.inviteId);
    if (!mounted) return;
    setState(() => _declining = false);

    result.fold(
      (failure) =>
          CkToast.show(context, message: failure.message, isError: true),
      (_) {
        CkToast.show(
          context,
          message: 'Invitation declined',
          icon: Icons.close,
        );
        ref.invalidate(myPendingInviteForTeamProvider(widget.teamId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviter = widget.invite.inviterName ?? 'Team Management';
    final roleStr = widget.invite.role.name.toUpperCase();
    final jersey = widget.invite.jerseyNumber;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CkColors.cream,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'INVITED TO SQUAD',
                    style: tpMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: CkColors.amberInk,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  jersey != null ? '$roleStr · #$jersey' : roleStr,
                  style: tpMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$inviter invited you to join ${widget.teamName}',
              style: CkType.display(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
                color: CkColors.ink,
              ),
            ),
            if (widget.invite.message != null &&
                widget.invite.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '“${widget.invite.message!.trim()}”',
                style: CkType.body(
                  fontSize: 12.5,
                  // fontStyle: FontStyle.italic,
                  color: CkColors.ink2,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _busy ? null : _handleAccept,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CkColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          _accepting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Accept Invite',
                                    style: CkType.body(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _busy ? null : _handleDecline,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CkColors.paper2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      child:
                          _declining
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CkColors.ink,
                                ),
                              )
                              : Text(
                                'Decline',
                                style: CkType.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CkColors.ink2,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
