import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/chat.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_theme.dart';

/// Screen displaying incoming message requests matching Stitch design
/// `44ba117202ca4197b3f92578f965aac3` (Message Requests & Detail).
class MessageRequestsScreen extends ConsumerWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      body: SafeArea(
        bottom: false,
        child: switch (chatsAsync) {
          AsyncData(:final value) => _RequestsBody(
              requests: value.where((c) => c.isRequest).toList(),
              onRefresh: () async {
                await ref.read(chatRepositoryProvider).refreshInbox();
              },
            ),
          AsyncError() => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: ChatTheme.destructiveCoralText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load message requests',
                      style: ChatTheme.headlineSm(),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => ref.read(chatRepositoryProvider).refreshInbox(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          _ => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ChatTheme.matchDayCoral,
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _RequestsBody extends StatelessWidget {
  const _RequestsBody({
    required this.requests,
    required this.onRefresh,
  });

  final List<Chat> requests;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top App Bar
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          decoration: const BoxDecoration(
            color: ChatTheme.clubhouseCanvas,
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Row(
            children: [
              // 40px Circular Back Button
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
              const SizedBox(width: 4),

              // Title and count badge
              Text(
                'Message Requests',
                style: ChatTheme.headlineMd(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ChatTheme.softSandFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ChatTheme.hairlineSand),
                ),
                child: Text(
                  '${requests.length} requests',
                  style: ChatTheme.timestamp(),
                ),
              ),
              const Spacer(),

              // Filter / Tune button
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Filter options: All requests shown'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Request filters',
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: ChatTheme.mutedStone,
                ),
              ),
            ],
          ),
        ),

        // Privacy Informative Note Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          decoration: BoxDecoration(
            color: ChatTheme.clubhouseCanvas,
            border: Border(
              bottom: BorderSide(
                color: ChatTheme.hairlineSand.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Text(
            'These people aren\'t in your contacts or team roster. They won\'t know you\'ve seen their message until you accept.',
            style: ChatTheme.bodySm(color: ChatTheme.mutedStone).copyWith(
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),

        // Hidden Requests Shortcut Row
        Container(
          color: ChatTheme.clubhouseCanvas,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No hidden requests at this time'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ChatTheme.softSandFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: ChatTheme.hairlineSand),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: ChatTheme.mutedStone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hidden Requests',
                          style: ChatTheme.rowTitle(color: ChatTheme.charcoalInk),
                        ),
                        Text(
                          'Filtered spam and muted inquiries',
                          style: ChatTheme.metadata(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: ChatTheme.softSandFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: ChatTheme.hairlineSand),
                    ),
                    child: Text(
                      '0',
                      style: ChatTheme.timestamp(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ChatTheme.mutedStone,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Request Tiles List
        Expanded(
          child: Container(
            color: ChatTheme.clubhouseCanvas,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: ChatTheme.matchDayCoral,
              backgroundColor: ChatTheme.clubhouseCanvas,
              child: requests.isEmpty
                  ? const _EmptyRequests()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: requests.length + 1,
                      separatorBuilder: (_, index) {
                        if (index >= requests.length) return const SizedBox.shrink();
                        return const Divider(
                          height: 1,
                          thickness: 1,
                          color: ChatTheme.hairlineSand,
                        );
                      },
                      itemBuilder: (context, index) {
                        if (index == requests.length) {
                          // Safety Footer
                          return const _SafetyFooter();
                        }
                        final chat = requests[index];
                        return _RequestTile(
                          chat: chat,
                          onTap: () => context.push('/messages/${chat.id.value}'),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.chat,
    required this.onTap,
  });

  final Chat chat;
  final VoidCallback onTap;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final name = chat.displayName;
    final mono = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final handle = chat.dmOtherUserUsername;
    final timeStr = _formatTime(chat.lastMessageAt);
    final preview = chat.lastMessagePreview ?? 'Sent a message';

    return Material(
      color: ChatTheme.clubhouseCanvas,
      child: InkWell(
        onTap: onTap,
        splashColor: ChatTheme.charcoalInk.withValues(alpha: 0.04),
        highlightColor: ChatTheme.charcoalInk.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 44px Avatar with cricket sport badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ChatTheme.softSandFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: ChatTheme.hairlineSand),
                    ),
                    child: Text(
                      mono,
                      style: ChatTheme.badge(
                        color: ChatTheme.charcoalInk,
                      ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ChatTheme.matchDayCoral,
                        shape: BoxShape.circle,
                        border: Border.all(color: ChatTheme.pureSurface, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.sports_cricket_rounded,
                        size: 9.5,
                        color: ChatTheme.pureSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Middle Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name + Category badge + Timestamp
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChatTheme.rowTitle(
                              color: ChatTheme.charcoalInk,
                            ),
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: ChatTheme.timestamp(color: ChatTheme.charcoalInk),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Row 2: Subtitle / context
                    Text(
                      handle != null && handle.isNotEmpty
                          ? '@$handle • Direct Message'
                          : 'Player Inquiry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChatTheme.metadata(color: ChatTheme.mutedStone),
                    ),
                    const SizedBox(height: 4),

                    // Row 3: Snippet Preview with Coral Unread Dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '"$preview"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChatTheme.bodySm(color: ChatTheme.charcoalInk),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: ChatTheme.matchDayCoral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyFooter extends StatelessWidget {
  const _SafetyFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ChatTheme.softSandFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_rounded,
              size: 16,
              color: ChatTheme.mutedStone,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can block unwanted contacts at any time. Blocked players won\'t be able to reach your team.',
            textAlign: TextAlign.center,
            style: ChatTheme.metadata(color: ChatTheme.mutedStone).copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ChatTheme.softSandFill,
                shape: BoxShape.circle,
                border: Border.all(color: ChatTheme.hairlineSand),
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 26,
                color: ChatTheme.charcoalInk,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No message requests',
              style: ChatTheme.headlineSm(),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages from players you do not follow will appear here.',
              textAlign: TextAlign.center,
              style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
            ),
          ],
        ),
      ),
    );
  }
}
