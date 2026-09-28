import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/chat_channel.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/chat_theme.dart';

class MessageRequestsScreen extends ConsumerWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(myChatChannelsProvider);

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      body: SafeArea(
        bottom: false,
        child: channels.when(
          data: (value) => _RequestsBody(
            requests: value.where((channel) => channel.isRequest).toList(),
            onRefresh: () async {
              await ref.read(chatRepositoryProvider).refreshInbox();
            },
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ChatTheme.matchDayCoral,
            ),
          ),
          error: (_, __) => Center(
            child: OutlinedButton(
              onPressed: () => ref.invalidate(myChatChannelsProvider),
              child: const Text('Retry'),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestsBody extends StatelessWidget {
  const _RequestsBody({required this.requests, required this.onRefresh});

  final List<ChatChannel> requests;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text('Message Requests', style: ChatTheme.headlineMd()),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ChatTheme.softSandFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${requests.length}', style: ChatTheme.badge()),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Text(
            'Opening a request lets you preview it without sending a normal read receipt. Accept it to start a regular conversation.',
            style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: requests.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 44,
                        color: ChatTheme.mutedStone,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text('No message requests', style: ChatTheme.headlineSm()),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 72,
                      color: ChatTheme.hairlineSand,
                    ),
                    itemBuilder: (_, index) => _RequestRow(
                      channel: requests[index],
                      onTap: () => context.push('/messages/${requests[index].id}'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.channel, required this.onTap});

  final ChatChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ChatAvatar(
                label: channel.displayName,
                imageUrl: channel.displayAvatarUrl,
                size: 46,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChatTheme.rowTitle(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      channel.lastMessagePreview?.trim().isNotEmpty == true
                          ? channel.lastMessagePreview!
                          : 'Wants to message you',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
                    ),
                  ],
                ),
              ),
              if (channel.lastMessageAt != null)
                Text(
                  DateFormat('MMM d').format(channel.lastMessageAt!.toLocal()),
                  style: ChatTheme.timestamp(),
                ),
            ],
          ),
        ),
      );
}
