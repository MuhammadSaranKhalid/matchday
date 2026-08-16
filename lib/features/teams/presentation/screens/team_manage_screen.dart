import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/modals/modals.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../posts/presentation/providers/posts_providers.dart';
import '../../../posts/presentation/screens/photo_viewer_screen.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../posts/presentation/widgets/post_card_skeleton.dart';
import '../../data/datasources/teams_datasource_providers.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../providers/teams_providers.dart';
import '../utils/team_display.dart';
import '../widgets/add_player_sheet.dart';
import '../widgets/edit_team_sheet.dart';
import '../widgets/team_avatar.dart';

/// Complete Manager console: Roster, Posts, Requests, Roles, and Settings.
class TeamManageScreen extends ConsumerStatefulWidget {
  const TeamManageScreen({super.key, required this.teamId, this.justCreated = false});

  final String teamId;
  final bool justCreated;

  @override
  ConsumerState<TeamManageScreen> createState() => _TeamManageScreenState();
}

class _TeamManageScreenState extends ConsumerState<TeamManageScreen> {
  int _activeTab = 0; // 0: Roster, 1: Posts, 2: Requests, 3: Settings

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider(widget.teamId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (teamAsync) {
          AsyncData(:final value?) => Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/teams');
                          }
                        },
                        icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
                      ),
                      TeamAvatar(
                        name: value.name,
                        primaryColor: value.primaryColor,
                        logoUrl: value.logoUrl,
                        monogram: value.logoMonogram,
                        size: 36,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value.name,
                                style: CkType.display(fontSize: 17, letterSpacing: -0.01)),
                            GestureDetector(
                              onTap: () => context.push('/teams/${value.id.value}'),
                              child: Text('Public team page →',
                                  style: CkType.body(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: CkColors.red)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                _TabHeader(
                  activeIndex: _activeTab,
                  onTabSelected: (i) => setState(() => _activeTab = i),
                ),

                if (widget.justCreated && _activeTab == 0) const _JustCreatedBanner(),

                // Tab Content
                Expanded(
                  child: switch (_activeTab) {
                    0 => _RosterTab(team: value),
                    1 => _TeamAnnouncementsManageTab(team: value),
                    2 => _RequestsTab(team: value),
                    _ => _SettingsTab(team: value),
                  },
                ),
              ],
            ),
          AsyncData() => const Center(child: Text('Team not found')),
          AsyncError() => const Center(child: Text('Could not load team')),
          _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.activeIndex, required this.onTabSelected});
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _TabItem(label: 'Roster', active: activeIndex == 0, onTap: () => onTabSelected(0)),
          _TabItem(label: 'Posts', active: activeIndex == 1, onTap: () => onTabSelected(1)),
          _TabItem(label: 'Requests', active: activeIndex == 2, onTap: () => onTabSelected(2)),
          _TabItem(label: 'Settings', active: activeIndex == 3, onTap: () => onTabSelected(3)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? CkColors.ink : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _JustCreatedBanner extends StatelessWidget {
  const _JustCreatedBanner();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.greenSoft,
          borderRadius: BorderRadius.circular(CkRadii.sm),
        ),
        child: Text('Team created. Add your first player below.',
            style: CkType.body(fontSize: 13, color: const Color(0xFF1E5A2C))),
      );
}

// ─── Tab 1: Roster ──────────────────────────────────────────────────────────

class _RosterTab extends ConsumerWidget {
  const _RosterTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(team.id.value));

    return switch (rosterAsync) {
      AsyncData(:final value) => Column(
          children: [
            Expanded(
              child: value.isEmpty
                  ? _EmptyRoster(onAdd: () => _addPlayer(context, ref, team))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: value.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: CkColors.hairline),
                      itemBuilder: (_, i) => _ManagedRow(
                        entry: value[i],
                        team: team,
                        onManage: () => _memberActions(context, ref, value[i]),
                      ),
                    ),
            ),
            if (value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: CkButton(
                  label: 'Add player to squad',
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: CkColors.paper),
                  onPressed: () => _addPlayer(context, ref, team),
                ),
              ),
          ],
        ),
      AsyncError() => const Center(child: Text('Could not load roster')),
      _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
    };
  }
}

// ─── Tab 2: Requests & Invitations ──────────────────────────────────────────

Map<String, dynamic> _asMap(dynamic val) {
  if (val == null) return const <String, dynamic>{};
  if (val is Map<String, dynamic>) return val;
  if (val is Map) {
    return val.map((k, v) => MapEntry(k.toString(), v));
  }
  return const <String, dynamic>{};
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.team});
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
                      Text('Share Team Invite',
                          style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Invite players via link or QR',
                          style: CkType.body(fontSize: 11, color: CkColors.muted)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: 'https://matchday.app/teams/${team.id.value}/join'));
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
                      style: CkType.body(fontSize: 12, fontWeight: FontWeight.w700, color: CkColors.paper),
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
              _PlayerJoinRequestCard(
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
              _ClaimRequestCard(
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
              _SentInviteCard(
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

class _PlayerJoinRequestCard extends ConsumerWidget {
  const _PlayerJoinRequestCard({required this.request, required this.teamId});
  final Map<String, dynamic> request;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqId = request['request_id']?.toString() ?? '';
    final player = _asMap(request['player']);
    final playerName = player['display_name']?.toString() ?? 'Player';
    final playerHandle = player['username']?.toString();
    final photoUrl = player['profile_photo_url']?.toString();
    final role = request['role']?.toString() ?? 'player';
    final message = request['message']?.toString();

    final roleLabel = switch (role) {
      'captain' => 'Captain',
      'vice_captain' => 'Vice Captain',
      'wicket_keeper' => 'Wicket-keeper',
      _ => 'Squad Player',
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
                  await ref.read(teamsRemoteDataSourceProvider).declineTeamJoinRequest(reqId);
                  ref.invalidate(teamPendingJoinRequestsProvider(teamId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Join request declined')),
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
                  await ref.read(teamsRemoteDataSourceProvider).acceptTeamJoinRequest(reqId);
                  ref.invalidate(teamPendingJoinRequestsProvider(teamId));
                  ref.invalidate(rosterProvider(teamId));
                  ref.invalidate(teamProvider(teamId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Accepted! $playerName added to squad roster.')),
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

class _ClaimRequestCard extends ConsumerWidget {
  const _ClaimRequestCard({required this.request, required this.teamId});
  final Map<String, dynamic> request;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqId = request['request_id']?.toString() ?? '';
    final requester = _asMap(request['requester']);
    final unclaimed = _asMap(request['unclaimed']);
    final requesterName = requester['display_name']?.toString() ?? 'Player';
    final requesterHandle = requester['username']?.toString();
    final photoUrl = requester['profile_photo_url']?.toString();
    final unclaimedName = unclaimed['display_name']?.toString() ?? 'Roster spot';
    final message = request['message']?.toString();

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
                  await ref.read(teamsRemoteDataSourceProvider).rejectClaimRequest(reqId);
                  ref.invalidate(teamPendingClaimRequestsProvider(teamId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Claim request rejected')),
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
                  await ref.read(teamsRemoteDataSourceProvider).approveClaimRequest(reqId);
                  ref.invalidate(teamPendingClaimRequestsProvider(teamId));
                  ref.invalidate(rosterProvider(teamId));
                  ref.invalidate(teamProvider(teamId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Claim approved! $requesterName added to roster.')),
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

class _SentInviteCard extends ConsumerWidget {
  const _SentInviteCard({required this.invite, required this.teamId});
  final Map<String, dynamic> invite;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteId = invite['invite_id']?.toString() ?? '';
    final invitee = _asMap(invite['invitee']);
    final inviteeName = invitee['display_name']?.toString() ?? 'Player';
    final inviteeHandle = invitee['username']?.toString();
    final photoUrl = invitee['profile_photo_url']?.toString();
    final role = invite['role']?.toString() ?? 'player';
    final jersey = invite['jersey_number'] as int?;
    final message = invite['message']?.toString();

    final roleLabel = switch (role) {
      'captain' => 'Captain',
      'vice_captain' => 'Vice Captain',
      'wicket_keeper' => 'Wicket-keeper',
      _ => 'Squad Player',
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
                await ref.read(teamsRemoteDataSourceProvider).cancelTeamInvite(inviteId);
                ref.invalidate(teamPendingInvitesProvider(teamId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation cancelled')),
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

// ─── Tab 3: Settings ────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Primary Edit Action Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TeamAvatar(
                    name: team.name,
                    primaryColor: team.primaryColor,
                    logoUrl: team.logoUrl,
                    monogram: team.logoMonogram,
                    size: 44,
                    radius: 12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: CkType.display(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.01,
                          ),
                        ),
                        if (team.tagline != null && team.tagline!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            team.tagline!,
                            style: CkType.body(
                              fontSize: 12,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showEditTeamSheet(context, team),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Team Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CkColors.ink,
                    foregroundColor: CkColors.paper,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Text(
          'TEAM CONFIGURATION',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),

        _settingTile(
          title: 'Team Logo & Brand Colors',
          value: team.logoUrl != null && team.logoUrl!.isNotEmpty ? 'Custom Logo Uploaded' : (team.logoMonogram != null ? 'Monogram (${team.logoMonogram})' : 'Preset Colors'),
          icon: Icons.palette_outlined,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          title: 'Team Name',
          value: team.name,
          icon: Icons.shield_outlined,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          title: 'Tagline & Description',
          value: team.tagline ?? (team.description != null && team.description!.isNotEmpty ? team.description! : 'Not set'),
          icon: Icons.notes_rounded,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          title: 'Location & Home Ground',
          value: '${team.city ?? "No city"} · ${team.homeGround ?? "No ground specified"}',
          icon: Icons.location_on_outlined,
          onTap: () => showEditTeamSheet(context, team),
        ),
        _settingTile(
          title: 'Squad Capacity',
          value: '25 Players Max',
          icon: Icons.groups_outlined,
          onTap: () => _snack(context, 'Squad capacity is fixed at 25 players.'),
        ),
        _settingTile(
          title: 'Team Privacy',
          value: team.privacy == TeamPrivacy.private ? 'Private Team (Invite-only)' : 'Public Team (Discoverable)',
          icon: Icons.lock_outline_rounded,
          onTap: () => showEditTeamSheet(context, team),
        ),
      ],
    );
  }

  Widget _settingTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: CkColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CkType.body(fontSize: 11, color: CkColors.muted)),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: CkType.display(fontSize: 13.5, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: CkColors.muted),
          ],
        ),
      ),
    );
  }
}

// ─── Actions & Sub-widgets ──────────────────────────────────────────────────

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

void _showFailure(BuildContext context, Either<Failure, Object?> result) {
  result.fold((f) => _snack(context, f.message), (_) {});
}

Future<void> _addPlayer(BuildContext context, WidgetRef ref, Team team) async {
  await AddPlayerSheet.show(context, team);
}

Future<void> _memberActions(
    BuildContext context, WidgetRef ref, RosterMember entry) async {
  final action = await showModalBottomSheet<_MemberAction>(
    context: context,
    backgroundColor: CkColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MemberActionsSheet(entry: entry),
  );
  if (action == null || !context.mounted) return;
  final m = entry.member;

  switch (action) {
    case _MemberAction.jersey:
      final picked = await showModalBottomSheet<({int? value})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: CkColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _JerseySheet(initial: m.jerseyNumber),
      );
      if (picked == null || !context.mounted) return;
      JerseyNumber? jersey;
      if (picked.value != null) {
        final jerseyRes = JerseyNumber.create(picked.value!);
        if (jerseyRes.isLeft()) {
          _snack(context, jerseyRes.getLeft().toNullable()!.message);
          return;
        }
        jersey = jerseyRes.getRight().toNullable();
      }
      final result =
          await ref.read(teamsRepositoryProvider).setJerseyNumber(m.id, jersey);
      if (context.mounted) {
        _showFailure(context, result);
        ref.invalidate(rosterProvider(m.teamId.value));
        ref.invalidate(teamProvider(m.teamId.value));
      }
    case _MemberAction.captain:
    case _MemberAction.viceCaptain:
    case _MemberAction.keeper:
    case _MemberAction.player:
      final result = await ref
          .read(teamsRepositoryProvider)
          .setMemberRole(m.id, action.role!);
      if (context.mounted) {
        _showFailure(context, result);
        ref.invalidate(rosterProvider(m.teamId.value));
        ref.invalidate(teamProvider(m.teamId.value));
      }
    case _MemberAction.remove:
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Remove from squad?', style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Text(
            'Remove ${entry.displayName} from the active team roster? Historical match scorecards will remain intact.',
            style: CkType.body(fontSize: 13, color: CkColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: CkColors.ink)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove',
                  style: TextStyle(color: CkColors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
      final result =
          await ref.read(teamsRepositoryProvider).removeMember(m.id);
      if (context.mounted) {
        _showFailure(context, result);
        ref.invalidate(rosterProvider(m.teamId.value));
        ref.invalidate(teamProvider(m.teamId.value));
      }
  }
}

enum _MemberAction {
  jersey,
  captain,
  viceCaptain,
  keeper,
  player,
  remove;

  MemberRole? get role => switch (this) {
        _MemberAction.captain => MemberRole.captain,
        _MemberAction.viceCaptain => MemberRole.viceCaptain,
        _MemberAction.keeper => MemberRole.wicketKeeper,
        _MemberAction.player => MemberRole.player,
        _ => null,
      };
}

class _ManagedRow extends StatelessWidget {
  const _ManagedRow({
    required this.entry,
    required this.team,
    required this.onManage,
  });
  final RosterMember entry;
  final Team team;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final m = entry.member;
    final primary = parseHexColor(team.primaryColor, fallback: CkColors.ink);
    final isUnclaimed = m.playerType == PlayerType.unclaimed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Left + Center: Clickable player profile / info area
          Expanded(
            child: InkWell(
              onTap: () {
                if (!isUnclaimed && entry.username != null && entry.username!.isNotEmpty) {
                  context.push('/u/${entry.username}');
                } else if (isUnclaimed) {
                  _showOfflinePlayerSheet(context, team, entry, onManage);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    if (!isUnclaimed && (entry.profilePhotoUrl != null && entry.profilePhotoUrl!.isNotEmpty))
                      Avatar(
                        mono: entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                        imageUrl: entry.profilePhotoUrl,
                        size: 38,
                      )
                    else
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: m.jerseyNumber == null ? CkColors.paper2 : primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: m.jerseyNumber == null ? CkColors.hairline : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          m.jerseyNumber == null ? '—' : '#${m.jerseyNumber}',
                          style: CkType.display(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: m.jerseyNumber == null ? CkColors.muted : Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.displayName,
                                  style: CkType.display(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.01,
                                  ),
                                ),
                              ),
                              if (m.role != MemberRole.player) ...[
                                const SizedBox(width: 6),
                                _roleChip(m.role),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (isUnclaimed) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: CkColors.paper2,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Offline Player',
                                    style: CkType.mono(fontSize: 9, color: CkColors.muted),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  entry.username != null ? '@${entry.username}' : 'Verified Member',
                                  style: CkType.body(fontSize: 11, color: const Color(0xFF1E5A2C)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right: 3-dots actions button
          IconButton(
            onPressed: onManage,
            icon: const Icon(Icons.more_horiz_rounded, color: CkColors.ink),
            tooltip: 'Member actions',
          ),
        ],
      ),
    );
  }

  Widget _roleChip(MemberRole role) {
    final label = switch (role) {
      MemberRole.captain => 'C',
      MemberRole.viceCaptain => 'VC',
      MemberRole.wicketKeeper => 'WK',
      MemberRole.player => '',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: CkType.mono(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF6B5414)),
      ),
    );
  }
}

void _showOfflinePlayerSheet(
  BuildContext context,
  Team team,
  RosterMember entry,
  VoidCallback onManage,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: CkColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Text(
                    entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                    style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Offline Squad Placeholder',
                        style: CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.phoneNumber != null && entry.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: CkColors.muted),
                    const SizedBox(width: 8),
                    Text(
                      entry.phoneNumber!,
                      style: CkType.mono(fontSize: 13, fontWeight: FontWeight.w600, color: CkColors.ink),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: CkColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This player does not have a linked Matchday account yet. You can share the claim link so they can register and claim their stats.',
                      style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: 'https://matchday.app/teams/${team.id.value}/claim',
                      ));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Claim link copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Claim Link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CkColors.ink,
                      side: const BorderSide(color: CkColors.hairline),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onManage();
                    },
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Manage Role'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_alt_1_outlined,
                size: 52, color: CkColors.soft),
            const SizedBox(height: 14),
            Text('Your roster is empty', style: CkType.display(fontSize: 20)),
            const SizedBox(height: 6),
            Text('Add your first player to build the squad.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 14, color: CkColors.muted)),
            const SizedBox(height: 18),
            CkButton(
              label: 'Add player',
              expand: false,
              icon: const Icon(Icons.add_rounded, size: 20, color: CkColors.paper),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberActionsSheet extends StatelessWidget {
  const _MemberActionsSheet({required this.entry});
  final RosterMember entry;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, _MemberAction action,
            {Color color = CkColors.ink}) =>
        ListTile(
          leading: Icon(icon, color: color, size: 20),
          title: Text(label,
              style: CkType.body(
                  fontSize: 14.5, fontWeight: FontWeight.w500, color: color)),
          onTap: () => Navigator.of(context).pop(action),
        );

    final m = entry.member;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: CkColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CkColors.paper2,
                  child: Text(
                    entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                    style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.displayName,
                          style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(
                        m.role == MemberRole.captain
                            ? 'Captain'
                            : m.role == MemberRole.viceCaptain
                                ? 'Vice Captain'
                                : m.role == MemberRole.wicketKeeper
                                    ? 'Wicket-keeper'
                                    : 'Squad Player',
                        style: CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CkColors.hairline),
          item(Icons.tag_rounded, 'Set jersey number', _MemberAction.jersey),
          if (m.role != MemberRole.captain)
            item(Icons.star_rounded, 'Promote to Captain', _MemberAction.captain,
                color: const Color(0xFFB45309)),
          if (m.role != MemberRole.viceCaptain)
            item(Icons.star_half_rounded, 'Make Vice-Captain', _MemberAction.viceCaptain),
          if (m.role != MemberRole.wicketKeeper)
            item(Icons.sports_baseball_outlined, 'Make Wicket-keeper', _MemberAction.keeper),
          if (m.role != MemberRole.player)
            item(Icons.person_outline_rounded, 'Set as regular player', _MemberAction.player),
          item(Icons.delete_outline_rounded, 'Remove from squad',
              _MemberAction.remove,
              color: CkColors.red),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _JerseySheet extends StatefulWidget {
  const _JerseySheet({this.initial});
  final int? initial;
  @override
  State<_JerseySheet> createState() => _JerseySheetState();
}

class _JerseySheetState extends State<_JerseySheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jersey number', style: CkType.display(fontSize: 20)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: CkType.body(fontSize: 16),
            decoration: const InputDecoration(hintText: 'e.g. 7'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CkButton.secondary(
                  label: 'Clear',
                  onPressed: () =>
                      Navigator.of(context).pop((value: null)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: CkButton(label: 'Save', onPressed: _submit)),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final n = int.tryParse(_controller.text.trim());
    Navigator.of(context).pop((value: n));
  }
}

// ---------------------------------------------------------------------------
// Team Announcements & Posts Management Tab
// ---------------------------------------------------------------------------

class _TeamAnnouncementsManageTab extends ConsumerWidget {
  const _TeamAnnouncementsManageTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(teamPostsProvider(team.id.value));

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async =>
          ref.refresh(teamPostsProvider(team.id.value).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          // Announcement Creation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CkColors.ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.campaign_outlined,
                        size: 18,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Post Announcement',
                            style: CkType.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Share trials, match updates & squad selections',
                            style: CkType.body(
                              fontSize: 11.5,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final uri = Uri(
                        path: '/composer',
                        queryParameters: {
                          'teamId': team.id.value,
                          'teamName': team.name,
                          if (team.logoMonogram != null && team.logoMonogram!.isNotEmpty)
                            'teamMono': team.logoMonogram!,
                        },
                      );
                      context.push(uri.toString());
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text('Post as ${team.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PUBLISHED POSTS',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          switch (postsAsync) {
            AsyncData(:final value) when value.isEmpty => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 32,
                    color: CkColors.muted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No posts published yet',
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Posts you publish as ${team.name} will appear here and on the team\'s public page.',
                    textAlign: TextAlign.center,
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final post in value)
                  FeedPostCard(
                    post: post,
                    onComment: () => showCommentsSheet(
                      context,
                      postId: post.id.value,
                      postAuthorHandle: post.authorUsername != null &&
                              post.authorUsername!.isNotEmpty
                          ? '@${post.authorUsername}'
                          : post.authorName,
                      onOpenProfile: (String u) => context.push('/u/$u'),
                    ),
                    onLike: () => ref
                        .read(postsRepositoryProvider)
                        .togglePostLike(post.id),
                    onBookmark: () => ref
                        .read(postsRepositoryProvider)
                        .toggleBookmark(post.id),
                    onAuthorTap: (String u) => context.push('/u/$u'),
                    onOpenPhoto: (int idx) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PhotoViewerScreen(
                            media: post.media,
                            initialIndex: idx,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            AsyncError() => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Could not load posts.',
                  style: TextStyle(fontSize: 13, color: CkColors.muted),
                ),
              ),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(16),
              child: PostCardSkeleton(),
            ),
          },
        ],
      ),
    );
  }
}
