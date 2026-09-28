import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_toast.dart';
import '../../../domain/entities/team_invite.dart';
import '../../controllers/team_page_controller.dart';

class TeamPageInviteBanner extends ConsumerStatefulWidget {
  const TeamPageInviteBanner({
    super.key,
    required this.invite,
    required this.teamId,
    required this.teamName,
  });

  final TeamInvite invite;
  final String teamId;
  final String teamName;

  @override
  ConsumerState<TeamPageInviteBanner> createState() =>
      _TeamPageInviteBannerState();
}

class _TeamPageInviteBannerState extends ConsumerState<TeamPageInviteBanner> {
  bool _accepting = false;
  bool _declining = false;
  bool get _busy => _accepting || _declining;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    final error = await ref
        .read(teamPageControllerProvider(widget.teamId).notifier)
        .acceptInvite(widget.invite.inviteId);
    if (!mounted) return;
    setState(() => _accepting = false);
    CkToast.show(
      context,
      message: error ?? 'You joined ${widget.teamName}',
      isError: error != null,
      icon: error == null ? Icons.check_rounded : null,
    );
  }

  Future<void> _decline() async {
    setState(() => _declining = true);
    final error = await ref
        .read(teamPageControllerProvider(widget.teamId).notifier)
        .declineInvite(widget.invite.inviteId);
    if (!mounted) return;
    setState(() => _declining = false);
    if (error != null) {
      CkToast.show(context, message: error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.greenSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.green.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: CkColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You’re invited to join ${widget.teamName}',
                      style: CkType.display(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: CkColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.invite.message?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  widget.invite.message!,
                  style: CkType.body(fontSize: 12, color: CkColors.ink2),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: _busy ? null : _accept,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CkColors.ink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _accepting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Accept Invite',
                                style: CkType.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _decline,
                      child: _declining
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
