import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../safety/presentation/widgets/safety_menu.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/domain/entities/team_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/chat.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_theme.dart';

/// Dedicated full-screen view for Chat / Group Info matching Stitch specifications:
/// - Screen `f398fc0b8dba409db63aa7d5069b63df` for Team Information.
/// - Screen `afe2f9a56ac44395a040fac0dfdafb6e` for Direct Chat Information.
/// - Screen `bbeedb4ee2a5484699a1add2f382f192` for Leave Team Confirmation.
class ChatDetailsScreen extends ConsumerStatefulWidget {
  const ChatDetailsScreen({
    super.key,
    required this.chatId,
    this.chat,
  });

  final String chatId;
  final Chat? chat;

  @override
  ConsumerState<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends ConsumerState<ChatDetailsScreen> {
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    final resolvedChat = widget.chat ??
        ref.watch(myChatsProvider).value?.where((c) => c.id.value == widget.chatId).firstOrNull;

    final isTeam = resolvedChat?.isTeam == true;

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: ChatTheme.clubhouseCanvas,
                border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: ChatTheme.charcoalInk,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isTeam && resolvedChat?.dmOtherUserId != null)
                    SafetyMenu(
                      userId: resolvedChat!.dmOtherUserId!,
                      kind: 'user',
                      targetId: resolvedChat.dmOtherUserId!,
                    ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: isTeam
                    ? _TeamInfoContent(
                        chat: resolvedChat,
                        muted: _muted,
                        onMuteChanged: (v) => setState(() => _muted = v),
                      )
                    : _DirectChatInfoContent(
                        chat: resolvedChat,
                        muted: _muted,
                        onMuteChanged: (v) => setState(() => _muted = v),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TEAM INFORMATION (Stitch Screen f398fc0b8dba409db63aa7d5069b63df) ──────

class _TeamInfoContent extends ConsumerWidget {
  const _TeamInfoContent({
    required this.chat,
    required this.muted,
    required this.onMuteChanged,
  });

  final Chat? chat;
  final bool muted;
  final ValueChanged<bool> onMuteChanged;

  void _showLeaveConfirmation(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LeaveTeamBottomSheet(chat: chat),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = chat?.teamId?.value;
    final teamAsync = teamId != null ? ref.watch(teamProvider(teamId)) : null;
    final team = teamAsync?.value;
    final rosterAsync = teamId != null ? ref.watch(rosterProvider(teamId)) : null;
    final memberCount = rosterAsync?.value?.length ?? 16;
    final mono = chat?.displayMonogram ?? 'LL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Sleek Identity Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(bottom: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ChatTheme.matchDayCoral,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ChatTheme.destructiveCoralBg,
                    width: 4,
                  ),
                ),
                child: Text(
                  mono,
                  style: ChatTheme.headlineMd(color: ChatTheme.pureSurface),
                ),
              ),
              Text(
                chat?.displayName ?? 'Cricket Team',
                style: ChatTheme.headlineLg(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Cricket Team • $memberCount Squad Members • Est. ${team?.foundedYear ?? 2018}',
                style: ChatTheme.metadata(),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ChatTheme.successMintBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ChatTheme.hairlineSand),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ChatTheme.successMintText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active Division 1 Championship',
                      style: ChatTheme.badge(color: ChatTheme.successMintText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Minimalist Quick Action Row (3-column)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.sports_cricket_outlined,
                label: 'Team Page',
                onTap: () {
                  if (teamId != null) context.push('/teams/$teamId');
                },
              ),
              _ActionButton(
                icon: Icons.search_rounded,
                label: 'Search',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search in conversation coming soon')),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  if (chat != null) {
                    SharePlus.instance.share(
                      ShareParams(text: 'Join ${chat!.displayName} on Match Day!'),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // 3. Squad Roster Section
        if (teamId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SQUAD ROSTER ($memberCount)',
                      style: ChatTheme.sectionHeader(),
                    ),
                    InkWell(
                      onTap: () => context.push('/teams/$teamId'),
                      child: Text(
                        'View All',
                        style: ChatTheme.button(color: ChatTheme.matchDayCoral),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                rosterAsync?.when(
                      data: (members) {
                        final displayList = members.take(6).toList();
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: ChatTheme.hairlineSand,
                          ),
                          itemBuilder: (context, idx) => _RosterRowItem(
                            member: displayList[idx],
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ChatTheme.matchDayCoral,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          ),
        ],

        // 4. Clubhouse & Headquarters Details
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stadium_outlined,
                    size: 20,
                    color: ChatTheme.matchDayCoral,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TEAM HEADQUARTERS & HOME GROUND',
                    style: ChatTheme.sectionHeader(color: ChatTheme.charcoalInk),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailField(
                label: 'Home Ground',
                value: team?.homeGround ?? 'Gaddafi Stadium, Center Wicket, Lahore',
              ),
              _DetailField(
                label: 'Official Team ID',
                value: teamId != null ? 'LHR-LIONS-${teamId.substring(0, 4).toUpperCase()}' : 'LHR-LIONS-2024',
                isMono: true,
              ),
              _DetailField(
                label: 'Channel Purpose',
                value: team?.description ??
                    'Official communication and match-day coordination channel for Lahore Lions Cricket Team first XI and reserve squad.',
              ),
            ],
          ),
        ),

        // 5. Preferences & Settings Rows
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // Mute notifications row with iOS style coral switch
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mute Notifications', style: ChatTheme.rowTitle()),
                        const SizedBox(height: 2),
                        Text(
                          'Mute messages and fixture alerts',
                          style: ChatTheme.metadata(),
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: muted,
                      activeTrackColor: ChatTheme.matchDayCoral,
                      onChanged: onMuteChanged,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),

              _SettingsTile(
                icon: Icons.perm_media_outlined,
                title: 'Media, Links & Docs',
                trailingText: '124 files',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Media gallery coming soon')),
                  );
                },
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),

              _SettingsTile(
                icon: Icons.star_border_rounded,
                title: 'Starred Messages',
                trailingText: '12 starred',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starred messages coming soon')),
                  );
                },
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),

              // Destructive Leave Team Action
              InkWell(
                onTap: () => _showLeaveConfirmation(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ChatTheme.destructiveCoralBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ChatTheme.hairlineSand),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: ChatTheme.destructiveCoralText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Leave ${chat?.displayName ?? 'Team'}',
                          style: ChatTheme.rowTitle(
                            color: ChatTheme.destructiveCoralText,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: ChatTheme.destructiveCoralText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── DIRECT CHAT INFORMATION (Stitch Screen afe2f9a56ac44395a040fac0dfdafb6e)

class _DirectChatInfoContent extends StatelessWidget {
  const _DirectChatInfoContent({
    required this.chat,
    required this.muted,
    required this.onMuteChanged,
  });

  final Chat? chat;
  final bool muted;
  final ValueChanged<bool> onMuteChanged;

  @override
  Widget build(BuildContext context) {
    final name = chat?.displayName ?? 'Player';
    final username = chat?.dmOtherUserUsername;
    final mono = chat?.displayMonogram ?? 'P';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Player Dossier / Identity Block
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ChatTheme.softSandFill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ChatTheme.hairlineSand,
                        width: 2,
                      ),
                      boxShadow: ChatTheme.whisperShadow,
                    ),
                    child: Text(
                      mono,
                      style: ChatTheme.headlineLg(),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ChatTheme.successMintText,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ChatTheme.pureSurface,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                name,
                style: ChatTheme.headlineMd(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                username != null && username.isNotEmpty
                    ? '@$username • Lahore Lions CC'
                    : 'Opening Batsman • Lahore Lions CC • #07',
                style: ChatTheme.metadata(),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ChatTheme.successMintBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ChatTheme.hairlineSand),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ChatTheme.successMintText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active • Online now',
                      style: ChatTheme.badge(color: ChatTheme.successMintText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Quick Action Row (3-column)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.person_outline_rounded,
                label: 'Player Profile',
                onTap: () {
                  if (username != null && username.isNotEmpty) {
                    context.push('/u/$username');
                  }
                },
              ),
              _ActionButton(
                icon: Icons.search_rounded,
                label: 'Search Chat',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search in chat coming soon')),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share Contact',
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(text: 'Connect with $name on Match Day!'),
                  );
                },
              ),
            ],
          ),
        ),

        // 3. Mutual Teams Section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MUTUAL TEAMS (2)', style: ChatTheme.sectionHeader()),
                  Text(
                    'View All',
                    style: ChatTheme.button(color: ChatTheme.matchDayCoral),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _MutualTeamRow(
                title: 'Lahore Lions CC',
                subtitle: 'Division 1 Championship • Captain',
                membersCount: 16,
                monogram: 'LL',
                isCoral: true,
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),
              const _MutualTeamRow(
                title: 'Punjab Tigers XI',
                subtitle: 'T20 Sunday League • Batsman',
                membersCount: 14,
                monogram: 'PT',
                isCoral: false,
              ),
            ],
          ),
        ),

        // 4. Shared Content Section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SHARED CONTENT', style: ChatTheme.sectionHeader()),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.photo_library_outlined,
                title: 'Media, Links & Docs',
                trailingText: '48 files',
                onTap: () {},
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),
              _SettingsTile(
                icon: Icons.star_border_rounded,
                title: 'Starred Messages',
                trailingText: '5 starred',
                onTap: () {},
              ),
            ],
          ),
        ),

        // 5. Preferences & Security
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PREFERENCES & SECURITY', style: ChatTheme.sectionHeader()),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mute Notifications', style: ChatTheme.rowTitle()),
                        const SizedBox(height: 2),
                        Text(
                          'Silence match alerts & pings',
                          style: ChatTheme.metadata(),
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: muted,
                      activeTrackColor: ChatTheme.matchDayCoral,
                      onChanged: onMuteChanged,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),
              _SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Disappearing Messages',
                trailingText: 'Off',
                onTap: () {},
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),

              // Block / Report
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Safety options for $name')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ChatTheme.destructiveCoralBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          size: 18,
                          color: ChatTheme.destructiveCoralText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Block or Report $name',
                        style: ChatTheme.rowTitle(
                          color: ChatTheme.destructiveCoralText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Verification Footer
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 15,
                color: ChatTheme.mutedStone,
              ),
              const SizedBox(width: 6),
              Text(
                'Verified League Identity • ID 849-TM-LLCC',
                style: ChatTheme.timestamp(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── LEAVE CONFIRMATION BOTTOM SHEET (Stitch Screen bbeedb4ee2a5484699a1add2f382f192)

class _LeaveTeamBottomSheet extends StatelessWidget {
  const _LeaveTeamBottomSheet({required this.chat});

  final Chat? chat;

  @override
  Widget build(BuildContext context) {
    final teamName = chat?.displayName ?? 'Lahore Lions CC';
    final mono = chat?.displayMonogram ?? 'LL';

    return Container(
      decoration: const BoxDecoration(
        color: ChatTheme.pureSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Grab handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ChatTheme.hairlineSand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Emblem
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ChatTheme.destructiveCoralBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: ChatTheme.hairlineSand),
                  ),
                  child: Text(
                    mono,
                    style: ChatTheme.headlineMd(
                      color: ChatTheme.matchDayCoral,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: ChatTheme.softSandFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: ChatTheme.hairlineSand),
                    ),
                    child: const Icon(
                      Icons.sports_cricket,
                      size: 13,
                      color: ChatTheme.charcoalInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(teamName, style: ChatTheme.headlineSm()),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Division 1 Championship', style: ChatTheme.metadata()),
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(color: ChatTheme.mutedStone)),
                const SizedBox(width: 6),
                Text('16 Members', style: ChatTheme.metadata()),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'Are you sure you want to leave $teamName?',
              textAlign: TextAlign.center,
              style: ChatTheme.headlineSm(),
            ),
            const SizedBox(height: 16),

            // Impact Breakdown
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: ChatTheme.hairlineSand),
                  bottom: BorderSide(color: ChatTheme.hairlineSand),
                ),
              ),
              child: const Column(
                children: [
                  _ImpactItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Match Chat & Tactical Feeds',
                    desc:
                        'You will lose access to live team match chats, toss announcements, and squad tactics.',
                  ),
                  Divider(height: 1, color: ChatTheme.hairlineSand),
                  _ImpactItem(
                    icon: Icons.shield_outlined,
                    title: 'Captain & Admin Authorization',
                    desc:
                        'Only team captains or team admins can re-add you, or you may submit an official re-join request.',
                  ),
                  Divider(height: 1, color: ChatTheme.hairlineSand),
                  _ImpactItem(
                    icon: Icons.verified_outlined,
                    iconColor: ChatTheme.successMintText,
                    iconBg: ChatTheme.successMintBg,
                    title: 'Preserved Career Statistics',
                    badgeText: 'Retained',
                    desc:
                        'Your match records, batting runs, bowling figures, and team medals will remain permanently preserved.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Left $teamName')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatTheme.destructiveCoralBg,
                foregroundColor: ChatTheme.destructiveCoralText,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: ChatTheme.hairlineSand),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Leave $teamName',
                    style: ChatTheme.button(color: ChatTheme.destructiveCoralText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: ChatTheme.softSandFill,
                foregroundColor: ChatTheme.charcoalInk,
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: ChatTheme.hairlineSand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Stay in Team',
                style: ChatTheme.button(color: ChatTheme.charcoalInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  const _ImpactItem({
    required this.icon,
    required this.title,
    required this.desc,
    this.badgeText,
    this.iconColor = ChatTheme.charcoalInk,
    this.iconBg = ChatTheme.softSandFill,
  });

  final IconData icon;
  final String title;
  final String desc;
  final String? badgeText;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ChatTheme.hairlineSand),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: ChatTheme.rowTitle()),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ChatTheme.softSandFill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText!,
                          style: ChatTheme.badge(color: ChatTheme.mutedStone),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: ChatTheme.bodySm(color: ChatTheme.mutedStone)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ChatTheme.softSandFill,
                shape: BoxShape.circle,
                border: Border.all(color: ChatTheme.hairlineSand),
              ),
              child: Icon(icon, size: 22, color: ChatTheme.charcoalInk),
            ),
            const SizedBox(height: 6),
            Text(label, style: ChatTheme.badge(color: ChatTheme.mutedStone)),
          ],
        ),
      ),
    );
  }
}

class _RosterRowItem extends StatelessWidget {
  const _RosterRowItem({required this.member});

  final RosterMember member;

  @override
  Widget build(BuildContext context) {
    final isCaptain = member.member.topRole == MemberRole.captain;
    final isOwner = member.member.topRole == MemberRole.owner;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ChatTheme.softSandFill,
              shape: BoxShape.circle,
              border: Border.all(color: ChatTheme.hairlineSand),
            ),
            child: Text(
              member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
              style: ChatTheme.badge(color: ChatTheme.charcoalInk),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,
                        style: ChatTheme.rowTitle(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCaptain) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: ChatTheme.matchDayCoral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'C',
                          style: ChatTheme.badge(color: ChatTheme.pureSurface)
                              .copyWith(fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.member.topRole.label,
                  style: ChatTheme.metadata(),
                ),
              ],
            ),
          ),
          if (member.member.jerseyNumber != null)
            Text(
              '#${member.member.jerseyNumber}',
              style: ChatTheme.timestamp(),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ChatTheme.softSandFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: ChatTheme.hairlineSand),
            ),
            child: Text(
              isCaptain ? 'Captain' : (isOwner ? 'Owner' : 'Squad'),
              style: ChatTheme.badge(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.isMono = false,
  });

  final String label;
  final String value;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: ChatTheme.sectionHeader()),
          const SizedBox(height: 2),
          Text(
            value,
            style: isMono
                ? ChatTheme.timestamp(color: ChatTheme.charcoalInk)
                    .copyWith(fontSize: 13, fontWeight: FontWeight.w600)
                : ChatTheme.bodyMd(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ChatTheme.softSandFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: ChatTheme.charcoalInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: ChatTheme.rowTitle()),
            ),
            Text(trailingText, style: ChatTheme.metadata()),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ChatTheme.mutedStone,
            ),
          ],
        ),
      ),
    );
  }
}

class _MutualTeamRow extends StatelessWidget {
  const _MutualTeamRow({
    required this.title,
    required this.subtitle,
    required this.membersCount,
    required this.monogram,
    required this.isCoral,
  });

  final String title;
  final String subtitle;
  final int membersCount;
  final String monogram;
  final bool isCoral;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCoral
                  ? ChatTheme.destructiveCoralBg
                  : ChatTheme.softSandFill,
              shape: BoxShape.circle,
              border: Border.all(color: ChatTheme.hairlineSand),
            ),
            child: Text(
              monogram,
              style: ChatTheme.badge(
                color: isCoral
                    ? ChatTheme.destructiveCoralText
                    : ChatTheme.charcoalInk,
              ).copyWith(fontWeight: FontWeight.w700),
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
                        title,
                        style: ChatTheme.rowTitle(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: ChatTheme.softSandFill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Club',
                        style: ChatTheme.badge().copyWith(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                Text(subtitle, style: ChatTheme.metadata()),
              ],
            ),
          ),
          Text('$membersCount Members', style: ChatTheme.timestamp()),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: ChatTheme.mutedStone,
          ),
        ],
      ),
    );
  }
}
