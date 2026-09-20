import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../safety/presentation/widgets/safety_menu.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/entities/chat_participant.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/chat_theme.dart';

class ChatDetailsScreen extends ConsumerWidget {
  const ChatDetailsScreen({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref
        .watch(myChatChannelsProvider)
        .value
        ?.where((item) => item.id == chatId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      appBar: AppBar(
        backgroundColor: ChatTheme.clubhouseCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Chat Info', style: ChatTheme.headlineSm()),
        centerTitle: true,
        actions: [
          if (channel?.isDm == true && channel?.dmOtherUserId != null)
            SafetyMenu(
              userId: channel!.dmOtherUserId!,
              kind: 'user',
              targetId: channel.dmOtherUserId!,
            ),
        ],
      ),
      body: channel == null
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ChatTheme.matchDayCoral,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: channel.isDm
                  ? _DirectInfo(channel: channel)
                  : channel.isTeam
                      ? _TeamInfo(channel: channel)
                      : _MultiParticipantInfo(channel: channel),
            ),
    );
  }
}

class _DirectInfo extends StatelessWidget {
  const _DirectInfo({required this.channel});

  final ChatChannel channel;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ChatAvatar(
            label: channel.displayName,
            imageUrl: channel.displayAvatarUrl,
            size: 76,
          ),
          const SizedBox(height: 12),
          Text(
            channel.displayName,
            textAlign: TextAlign.center,
            style: ChatTheme.headlineLg(),
          ),
          if (channel.dmOtherUserUsername?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text(
              '@${channel.dmOtherUserUsername}',
              style: ChatTheme.metadata(),
            ),
          ],
          const SizedBox(height: 28),
          _InfoCard(
            children: [
              const _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Conversation',
                value: 'Direct message',
              ),
              if (channel.isPendingOutgoingRequest)
                const _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Request',
                  value: 'Waiting for acceptance',
                ),
              if (channel.isRequest)
                const _InfoRow(
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Request',
                  value: 'Waiting for your decision',
                ),
            ],
          ),
        ],
      );
}

class _TeamInfo extends ConsumerWidget {
  const _TeamInfo({required this.channel});

  final ChatChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = channel.teamId;
    final team = teamId == null ? null : ref.watch(teamProvider(teamId)).value;
    final roster = teamId == null ? null : ref.watch(rosterProvider(teamId));

    return Column(
      children: [
        ChatAvatar(
          label: channel.displayName,
          imageUrl: team?.logoUrl ?? channel.displayAvatarUrl,
          size: 76,
          backgroundColor: ChatTheme.matchDayCoral,
          foregroundColor: ChatTheme.pureSurface,
        ),
        const SizedBox(height: 12),
        Text(
          team?.name ?? channel.displayName,
          textAlign: TextAlign.center,
          style: ChatTheme.headlineLg(),
        ),
        const SizedBox(height: 4),
        Text(
          [
            'Team chat',
            if (team?.foundedYear != null) 'Est. ${team!.foundedYear}',
          ].join(' • '),
          style: ChatTheme.metadata(),
        ),
        const SizedBox(height: 22),
        _InfoCard(
          children: [
            if (team?.description?.trim().isNotEmpty == true)
              _InfoRow(
                icon: Icons.notes_rounded,
                label: 'About',
                value: team!.description!,
              ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Home ground',
              value: team?.homeGround?.trim().isNotEmpty == true
                  ? team!.homeGround!
                  : 'Not provided',
            ),
            _InfoRow(
              icon: Icons.place_outlined,
              label: 'Location',
              value: team?.city?.trim().isNotEmpty == true
                  ? team!.city!
                  : 'Not provided',
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: roster?.value == null
              ? 'Squad'
              : '${roster!.value!.length} Squad Members',
        ),
        const SizedBox(height: 6),
        if (roster == null)
          const Text('Roster unavailable')
        else
          roster.when(
            data: (members) => _MemberList(members: members),
            loading: () => const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              'Could not load the team roster.',
              style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
            ),
          ),
      ],
    );
  }
}

class _MultiParticipantInfo extends ConsumerWidget {
  const _MultiParticipantInfo({required this.channel});

  final ChatChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participants = ref.watch(chatParticipantsProvider(channel.id));
    final type = switch (channel.contextType) {
      ChatChannelContext.match => 'Match room',
      ChatChannelContext.tournament => 'Tournament chat',
      ChatChannelContext.club => 'Club chat',
      ChatChannelContext.team => 'Team chat',
      ChatChannelContext.none => 'Group chat',
    };

    return Column(
      children: [
        ChatAvatar(
          label: channel.displayName,
          imageUrl: channel.displayAvatarUrl,
          size: 76,
        ),
        const SizedBox(height: 12),
        Text(
          channel.displayName,
          textAlign: TextAlign.center,
          style: ChatTheme.headlineLg(),
        ),
        const SizedBox(height: 4),
        Text(type, style: ChatTheme.metadata()),
        if (channel.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 18),
          Text(
            channel.description!,
            textAlign: TextAlign.center,
            style: ChatTheme.bodyMd(color: ChatTheme.mutedStone),
          ),
        ],
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Participants'),
        const SizedBox(height: 6),
        participants.when(
          data: (people) => _ParticipantList(
            participants: people.where((person) => person.isActive).toList(),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(18),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => Text(
            'Could not load participants.',
            style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
          ),
        ),
      ],
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members});
  final List<RosterMember> members;

  @override
  Widget build(BuildContext context) => Column(
        children: members
            .map(
              (member) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ChatAvatar(
                  label: member.displayName,
                  imageUrl: member.profilePhotoUrl,
                  size: 40,
                ),
                title: Text(member.displayName, style: ChatTheme.rowTitle()),
                subtitle: Text(
                  member.username?.trim().isNotEmpty == true
                      ? '@${member.username}'
                      : member.member.topRole.label,
                  style: ChatTheme.metadata(),
                ),
                trailing: member.member.jerseyNumber == null
                    ? null
                    : Text(
                        '#${member.member.jerseyNumber}',
                        style: ChatTheme.timestamp(),
                      ),
              ),
            )
            .toList(),
      );
}

class _ParticipantList extends StatelessWidget {
  const _ParticipantList({required this.participants});
  final List<ChatParticipant> participants;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Text(
        'No active participants are cached yet.',
        style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
      );
    }

    return Column(
      children: participants
          .map(
            (person) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ChatAvatar(
                label: person.displayName,
                imageUrl: person.avatarUrl,
                size: 40,
              ),
              title: Text(person.displayName, style: ChatTheme.rowTitle()),
              subtitle: Text(
                person.username?.trim().isNotEmpty == true
                    ? '@${person.username}'
                    : person.channelRole,
                style: ChatTheme.metadata(),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: ChatTheme.pureSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ChatTheme.hairlineSand),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, color: ChatTheme.hairlineSand),
            ],
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: ChatTheme.mutedStone),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ChatTheme.badge()),
                  const SizedBox(height: 2),
                  Text(value, style: ChatTheme.bodyMd()),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: ChatTheme.sectionHeader()),
      );
}
