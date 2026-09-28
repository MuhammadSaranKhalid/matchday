import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_channel.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/chat_theme.dart';
import '../widgets/inbox_search_bar.dart';
import '../widgets/inbox_shimmer_skeleton.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({
    super.key,
    this.onBell,
    this.showBack = false,
    this.showHeader = true,
  });

  final VoidCallback? onBell;
  final bool showBack;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(myChatChannelsProvider);

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      body: SafeArea(
        top: false,
        bottom: false,
        child: channels.when(
          data: (value) => _LoadedInbox(
            channels: value,
            showBack: showBack,
            showHeader: showHeader,
            onBell: onBell,
          ),
          loading: () => _InboxLoading(showHeader: showHeader),
          error: (error, _) => _InboxError(
            message: error is FailureWrapper
                ? error.failure.message
                : 'Could not load your chats.',
            onRetry: () => ref.invalidate(myChatChannelsProvider),
          ),
        ),
      ),
    );
  }
}

class _LoadedInbox extends ConsumerStatefulWidget {
  const _LoadedInbox({
    required this.channels,
    required this.showBack,
    required this.showHeader,
    this.onBell,
  });

  final List<ChatChannel> channels;
  final bool showBack;
  final bool showHeader;
  final VoidCallback? onBell;

  @override
  ConsumerState<_LoadedInbox> createState() => _LoadedInboxState();
}

class _LoadedInboxState extends ConsumerState<_LoadedInbox> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final result = await ref.read(chatRepositoryProvider).refreshInbox();
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = widget.channels.where((channel) => channel.isRequest).toList();
    var visible = widget.channels.where((channel) => !channel.isRequest).toList();

    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      visible = visible.where((channel) {
        return channel.displayName.toLowerCase().contains(query) ||
            (channel.dmOtherUserUsername?.toLowerCase().contains(query) ?? false) ||
            (channel.lastMessagePreview?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return Column(
      children: [
        if (widget.showHeader)
          _InboxHeader(
            showBack: widget.showBack,
            onBell: widget.onBell,
            activeCount: widget.channels.where((c) => !c.isRequest).length,
            requestCount: requests.length,
          ),
        InboxSearchBar(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
        ),
        Expanded(
          child: visible.isEmpty
              ? RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        query.isEmpty
                            ? Icons.chat_bubble_outline_rounded
                            : Icons.search_off_rounded,
                        size: 42,
                        color: ChatTheme.mutedStone,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          query.isEmpty ? 'No chats yet' : 'No chats match “$_query”',
                          style: ChatTheme.headlineSm(),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 28),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 72,
                      color: ChatTheme.hairlineSand,
                    ),
                    itemBuilder: (context, index) => _ChatRow(
                      channel: visible[index],
                      onOpen: () => context.push('/messages/${visible[index].id}'),
                      onMarkRead: visible[index].unreadCount > 0 &&
                              visible[index].lastMessageSeq != null
                          ? () async {
                              await ref.read(chatRepositoryProvider).markRead(
                                    visible[index].id,
                                    visible[index].lastMessageSeq,
                                  );
                            }
                          : null,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({
    required this.showBack,
    required this.activeCount,
    required this.requestCount,
    this.onBell,
  });

  final bool showBack;
  final int activeCount;
  final int requestCount;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
        ),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            Text('Chats', style: ChatTheme.headlineLg()),
            const SizedBox(width: 8),
            _CountChip(label: '$activeCount active'),
            if (requestCount > 0) ...[
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.push('/messages/requests'),
                child: _CountChip(
                  label: '$requestCount request${requestCount == 1 ? '' : 's'}',
                  emphasized: true,
                ),
              ),
            ],
            const Spacer(),
            if (onBell != null)
              IconButton(
                onPressed: onBell,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
          ],
        ),
      );
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, this.emphasized = false});
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: emphasized ? ChatTheme.destructiveCoralBg : ChatTheme.softSandFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ChatTheme.hairlineSand),
        ),
        child: Text(
          label,
          style: ChatTheme.badge(
            color: emphasized ? ChatTheme.destructiveCoralText : ChatTheme.mutedStone,
          ),
        ),
      );
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.channel,
    required this.onOpen,
    this.onMarkRead,
  });

  final ChatChannel channel;
  final VoidCallback onOpen;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final preview = channel.lastMessagePreview?.trim();
    final prefix = channel.lastMessageFromMe && preview?.isNotEmpty == true ? 'You: ' : '';

    return InkWell(
      onTap: onOpen,
      onLongPress: onMarkRead,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            ChatAvatar(
              label: channel.displayName,
              imageUrl: channel.displayAvatarUrl,
              size: 46,
              backgroundColor:
                  channel.isTeam ? ChatTheme.matchDayCoral : ChatTheme.softSandFill,
              foregroundColor:
                  channel.isTeam ? ChatTheme.pureSurface : ChatTheme.charcoalInk,
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
                    style: ChatTheme.rowTitle().copyWith(
                      fontWeight:
                          channel.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview?.isNotEmpty == true
                        ? '$prefix$preview'
                        : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (channel.lastMessageAt != null)
                  Text(
                    _inboxTime(channel.lastMessageAt!),
                    style: ChatTheme.timestamp(),
                  ),
                const SizedBox(height: 5),
                if (channel.unreadCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: ChatTheme.matchDayCoral,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      channel.unreadCount > 99 ? '99+' : '${channel.unreadCount}',
                      style: ChatTheme.badge(color: ChatTheme.pureSurface),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _inboxTime(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return DateFormat('h:mm a').format(local);
    }
    return DateFormat('MMM d').format(local);
  }
}

class _InboxLoading extends StatelessWidget {
  const _InboxLoading({required this.showHeader});
  final bool showHeader;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (showHeader)
            const SizedBox(
              height: 62,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Chats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          const Expanded(child: InboxShimmerSkeleton()),
        ],
      );
}

class _InboxError extends StatelessWidget {
  const _InboxError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
