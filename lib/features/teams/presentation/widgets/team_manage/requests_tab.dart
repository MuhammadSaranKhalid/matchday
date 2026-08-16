import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../domain/entities/team.dart';
import '../../../domain/entities/team_claim_request.dart';
import '../../../domain/entities/team_invite.dart';
import '../../../domain/entities/team_join_request.dart';
import '../../../domain/entities/team_member.dart';
import '../../controllers/team_manage_controller.dart';
import '../../providers/teams_providers.dart';

/// Requests and invitations tab for handling player join requests, claim requests, and sent invites.
class RequestsTab extends ConsumerWidget {
  const RequestsTab({super.key, required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinReqsAsync = ref.watch(teamPendingJoinRequestsProvider(team.id.value));
    final claimsAsync = ref.watch(teamPendingClaimRequestsProvider(team.id.value));
    final invitesAsync = ref.watch(teamPendingInvitesProvider(team.id.value));

    final hasJoin = (joinReqsAsync.value?.isNotEmpty ?? false);
    final hasClaims = (claimsAsync.value?.isNotEmpty ?? false);
    final hasInvites = (invitesAsync.value?.isNotEmpty ?? false);
    final isAllLoaded = joinReqsAsync.hasValue && claimsAsync.hasValue && invitesAsync.hasValue;
    final isEmpty = isAllLoaded && !hasJoin && !hasClaims && !hasInvites;

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async {
        ref.invalidate(teamPendingJoinRequestsProvider(team.id.value));
        ref.invalidate(teamPendingClaimRequestsProvider(team.id.value));
        ref.invalidate(teamPendingInvitesProvider(team.id.value));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Invite share card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: CkColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: const Icon(Icons.link_rounded, color: CkColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Team Invite',
                        style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invite players via link or QR',
                        style: CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                      text: 'https://matchday.app/teams/${team.id.value}/join',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied to clipboard!')),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: CkColors.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Copy Link',
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Section 1: Player Join Requests ───
          if (hasJoin) ...[
            Text(
              'PLAYER JOIN REQUESTS (${joinReqsAsync.value!.length})',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final req in joinReqsAsync.value!) ...[
              PlayerJoinRequestCard(
                request: req,
                teamId: team.id.value,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
          ],

          // ─── Section 2: Roster Claim Requests ───
          if (hasClaims) ...[
            Text(
              'ROSTER CLAIM REQUESTS (${claimsAsync.value!.length})',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final req in claimsAsync.value!) ...[
              ClaimRequestCard(
                request: req,
                teamId: team.id.value,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
          ],

          // ─── Section 3: Sent Team Invitations ───
          if (hasInvites) ...[
            Text(
              'SENT INVITATIONS (${invitesAsync.value!.length})',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final inv in invitesAsync.value!) ...[
              SentInviteCard(
                invite: inv,
                teamId: team.id.value,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
          ],

          // ─── Empty state if all are empty ───
          if (isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, size: 36, color: CkColors.muted),
                  const SizedBox(height: 8),
                  Text(
                    'No pending requests',
                    style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When players ask to join your squad, claim historical scorecards, or when you invite players, their status will appear here.',
                    textAlign: TextAlign.center,
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PlayerJoinRequestCard extends ConsumerWidget {
  const PlayerJoinRequestCard({super.key, required this.request, required this.teamId});
  final TeamJoinRequest request;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqId = request.requestId;
    final playerName = request.applicantName ?? 'Player';
    final playerHandle = request.applicantUsername;
    final photoUrl = request.applicantPhotoUrl;
    final message = request.message;
    final ctrl = ref.read(teamManageControllerProvider.notifier);

    final roleLabel = switch (request.role) {
      MemberRole.captain => 'Captain',
      MemberRole.viceCaptain => 'Vice Captain',
      MemberRole.wicketKeeper => 'Wicket-keeper',
      MemberRole.player => 'Squad Player',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (playerHandle != null && playerHandle.isNotEmpty) {
                context.push('/u/$playerHandle');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Avatar(
                  mono: playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                  imageUrl: photoUrl,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerName,
                        style: CkType.display(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${playerHandle != null ? '@$playerHandle · ' : ''}Applying as $roleLabel',
                        style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: CkColors.muted),
              ],
            ),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$message"',
                style: CkType.body(fontSize: 12, color: CkColors.ink).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () async {
                  final error = await ctrl.declineJoinRequest(
                    requestId: reqId,
                    teamId: teamId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Join request declined')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: CkColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Text(
                    'Decline',
                    style: CkType.body(fontSize: 12, fontWeight: FontWeight.w600, color: CkColors.red),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final error = await ctrl.acceptJoinRequest(
                    requestId: reqId,
                    teamId: teamId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Accepted! $playerName added to squad roster.')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CkColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Accept Request',
                    style: CkType.body(fontSize: 12, fontWeight: FontWeight.w700, color: CkColors.paper),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ClaimRequestCard extends ConsumerWidget {
  const ClaimRequestCard({super.key, required this.request, required this.teamId});
  final TeamClaimRequest request;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqId = request.requestId;
    final requesterName = request.requesterName ?? 'Player';
    final requesterHandle = request.requesterUsername;
    final photoUrl = request.requesterPhotoUrl;
    final unclaimedName = request.unclaimedPlayerName ?? 'Roster spot';
    final message = request.message;
    final ctrl = ref.read(teamManageControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (requesterHandle != null && requesterHandle.isNotEmpty) {
                context.push('/u/$requesterHandle');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Avatar(
                  mono: requesterName.isNotEmpty ? requesterName[0].toUpperCase() : '?',
                  imageUrl: photoUrl,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterName,
                        style: CkType.display(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${requesterHandle != null ? '@$requesterHandle · ' : ''}wants to claim: $unclaimedName',
                        style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: CkColors.muted),
              ],
            ),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$message"',
                style: CkType.body(fontSize: 12, color: CkColors.ink).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () async {
                  final error = await ctrl.declineClaimRequest(
                    requestId: reqId,
                    teamId: teamId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Claim request rejected')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: CkColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Text(
                    'Reject',
                    style: CkType.body(fontSize: 12, fontWeight: FontWeight.w600, color: CkColors.red),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final error = await ctrl.acceptClaimRequest(
                    requestId: reqId,
                    teamId: teamId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Claim approved! $requesterName added to roster.')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CkColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Approve Claim',
                    style: CkType.body(fontSize: 12, fontWeight: FontWeight.w700, color: CkColors.paper),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SentInviteCard extends ConsumerWidget {
  const SentInviteCard({super.key, required this.invite, required this.teamId});
  final TeamInvite invite;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteId = invite.inviteId;
    final inviteeName = invite.inviteeName ?? 'Player';
    final inviteeHandle = invite.inviteeUsername;
    final photoUrl = invite.inviteePhotoUrl;
    final jersey = invite.jerseyNumber;
    final message = invite.message;
    final ctrl = ref.read(teamManageControllerProvider.notifier);

    final roleLabel = switch (invite.role) {
      MemberRole.captain => 'Captain',
      MemberRole.viceCaptain => 'Vice Captain',
      MemberRole.wicketKeeper => 'Wicket-keeper',
      MemberRole.player => 'Squad Player',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (inviteeHandle != null && inviteeHandle.isNotEmpty) {
                context.push('/u/$inviteeHandle');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Avatar(
                  mono: inviteeName.isNotEmpty ? inviteeName[0].toUpperCase() : '?',
                  imageUrl: photoUrl,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inviteeName,
                        style: CkType.display(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${inviteeHandle != null ? '@$inviteeHandle · ' : ''}Invited as $roleLabel${jersey != null ? ' (#$jersey)' : ''}',
                        style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CkColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pending',
                    style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w700, color: CkColors.amber),
                  ),
                ),
              ],
            ),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$message"',
                style: CkType.body(fontSize: 12, color: CkColors.ink).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final error = await ctrl.cancelTeamInvite(
                  inviteId: inviteId,
                  teamId: teamId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Invitation cancelled')),
                  );
                }
              },
              icon: const Icon(Icons.close_rounded, size: 14, color: CkColors.red),
              label: Text(
                'Cancel Invite',
                style: CkType.body(fontSize: 12, fontWeight: FontWeight.w600, color: CkColors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
