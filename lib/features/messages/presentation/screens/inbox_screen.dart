import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/chat.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_theme.dart';
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
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      body: SafeArea(
        top: false,
        bottom: false,
        child: switch (chatsAsync) {
          AsyncData(:final value) => _Loaded(
              chats: value,
              showBack: showBack,
              showHeader: showHeader,
              onRefresh: () async {
                ref.invalidate(myChatsProvider);
                try {
                  await ref.read(myChatsProvider.future);
                } catch (_) {}
              },
            ),
          AsyncError(:final error) => _ErrorView(
              message: _messageFor(error),
              onRetry: () {
                ref.invalidate(myChatsProvider);
              },
            ),
          _ => const _Skeleton(),
        },
      ),
    );
  }

  String _messageFor(Object e) {
    if (e is FailureWrapper) return e.failure.message;
    return 'Could not load your chats.';
  }
}

// ─── Loaded body ─────────────────────────────────────────────────────────────

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.chats,
    required this.onRefresh,
    this.showBack = false,
    this.showHeader = true,
  });

  final List<Chat> chats;
  final Future<void> Function() onRefresh;
  final bool showBack;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final requestChats = chats.where((c) => c.isRequest).toList();
    final visible = chats.where((c) => !c.isRequest).toList();

    return Column(
      children: [
        // Stitch Chats Header
        if (showHeader)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            decoration: const BoxDecoration(
              color: ChatTheme.clubhouseCanvas,
              border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
            ),
            child: Row(
              children: [
                if (showBack)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ChatTheme.softSandFill,
                        shape: BoxShape.circle,
                        border: Border.all(color: ChatTheme.hairlineSand),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: ChatTheme.charcoalInk,
                      ),
                    ),
                  ),
                Text(
                  'Chats',
                  style: ChatTheme.headlineLg(),
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
                    '${visible.length} active',
                    style: ChatTheme.timestamp(),
                  ),
                ),
                if (requestChats.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/messages/requests'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: ChatTheme.pureSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: ChatTheme.hairlineSand),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(36, 35, 31, 0.04),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mark_email_unread_outlined,
                            size: 14,
                            color: ChatTheme.mutedStone,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Requests',
                            style: ChatTheme.badge(color: ChatTheme.charcoalInk),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: ChatTheme.matchDayCoral,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${requestChats.length}',
                              style: ChatTheme.badge(color: ChatTheme.pureSurface)
                                  .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Compose button
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Start a new chat by browsing teams or players'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Compose Chat',
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 24,
                    color: ChatTheme.charcoalInk,
                  ),
                ),
                // Manage / Profile button
                IconButton(
                  onPressed: () {
                    context.push('/profile');
                  },
                  tooltip: 'Profile and Settings',
                  icon: const Icon(
                    Icons.manage_accounts_outlined,
                    size: 22,
                    color: ChatTheme.charcoalInk,
                  ),
                ),
              ],
            ),
          ),

        if (!showHeader && requestChats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GestureDetector(
              onTap: () => context.push('/messages/requests'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ChatTheme.softSandFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ChatTheme.hairlineSand),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: ChatTheme.pureSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 18,
                        color: ChatTheme.charcoalInk,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message Requests',
                            style: ChatTheme.rowTitle(),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${requestChats.length} pending ${requestChats.length == 1 ? 'request' : 'requests'}',
                            style: ChatTheme.bodySm(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ChatTheme.matchDayCoral,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${requestChats.length}',
                        style: ChatTheme.badge(color: ChatTheme.pureSurface)
                            .copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: ChatTheme.mutedStone,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Conversation List
        Expanded(
          child: Container(
            color: ChatTheme.pureSurface,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: ChatTheme.matchDayCoral,
              backgroundColor: ChatTheme.pureSurface,
              child: visible.isEmpty
                  ? const _EmptyList()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 72,
                        color: ChatTheme.hairlineSand,
                      ),
                      itemBuilder: (context, i) => _ChatRowItem(
                        chat: visible[i],
                        onOpen: () => context.push('/messages/${visible[i].id.value}'),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Chat Row Item (Stitch Design) ──────────────────────────────────────────

class _ChatRowItem extends StatelessWidget {
  const _ChatRowItem({required this.chat, required this.onOpen});

  final Chat chat;
  final VoidCallback onOpen;

  static final _timeFmt = DateFormat('h:mm a');
  static final _dayFmt = DateFormat('MMM d');

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);

    if (diff.inDays == 0 && now.day == local.day) {
      return _timeFmt.format(local);
    } else if (diff.inDays < 2 && now.day - local.day == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(local);
    } else {
      return _dayFmt.format(local);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount > 0;
    final timeStr = _formatTime(chat.lastMessageAt);
    final mono = chat.displayMonogram;

    return Material(
      color: ChatTheme.pureSurface,
      child: InkWell(
        onTap: onOpen,
        onLongPress: () => _showContextMenu(context),
        splashColor: ChatTheme.charcoalInk.withValues(alpha: 0.04),
        highlightColor: ChatTheme.clubhouseCanvas,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: chat.isTeam
                          ? ChatTheme.matchDayCoral
                          : ChatTheme.softSandFill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: chat.isTeam
                            ? ChatTheme.matchDayCoral
                            : ChatTheme.hairlineSand,
                      ),
                    ),
                    child: Text(
                      mono,
                      style: ChatTheme.badge(
                        color: chat.isTeam
                            ? ChatTheme.pureSurface
                            : ChatTheme.charcoalInk,
                      ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  // Online indicator pip for DMs
                  if (chat.isDm)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3BA653),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ChatTheme.pureSurface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Title and preview column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title & Timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            chat.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChatTheme.rowTitle(),
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: ChatTheme.timestamp(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Row 2: Preview & Unread badge
                    Row(
                      children: [
                        Expanded(
                          child: _buildPreview(),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ChatTheme.matchDayCoral,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                              style: ChatTheme.badge(
                                color: ChatTheme.pureSurface,
                              ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
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
    );
  }

  Widget _buildPreview() {
    final preview = chat.lastMessagePreview;
    final unread = chat.unreadCount > 0;

    if (preview == null || preview.isEmpty) {
      return Text(
        'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ChatTheme.bodySm(color: ChatTheme.mutedStone)
            .copyWith(fontStyle: FontStyle.italic),
      );
    }

    if (chat.lastMessageFromMe) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.done_all_rounded,
            size: 15,
            color: ChatTheme.mutedStone,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
                children: [
                  const TextSpan(
                    text: 'You: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: preview),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      preview,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ChatTheme.bodySm(
        color: unread ? ChatTheme.charcoalInk : ChatTheme.mutedStone,
        fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: ChatTheme.pureSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: ChatTheme.hairlineSand,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      chat.displayName,
                      style: ChatTheme.rowTitle(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: ChatTheme.hairlineSand),
              ListTile(
                leading: const Icon(
                  Icons.reply_rounded,
                  color: ChatTheme.matchDayCoral,
                ),
                title: Text(
                  'Open & Reply',
                  style: ChatTheme.bodyMd(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onOpen();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.mark_chat_read_outlined,
                  color: ChatTheme.charcoalInk,
                ),
                title: Text(
                  'Mark as Read',
                  style: ChatTheme.bodyMd(),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeletons & Empty States ────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
          decoration: const BoxDecoration(
            color: ChatTheme.clubhouseCanvas,
            border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
          ),
          child: Row(
            children: [
              Text('Chats', style: ChatTheme.headlineLg()),
            ],
          ),
        ),
        const Expanded(
          child: InboxShimmerSkeleton(),
        ),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

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
                Icons.forum_outlined,
                size: 26,
                color: ChatTheme.charcoalInk,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Inbox is quiet',
              style: ChatTheme.headlineSm(),
            ),
            const SizedBox(height: 6),
            Text(
              'Your team, match, and direct conversations will appear here.',
              textAlign: TextAlign.center,
              style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              message,
              textAlign: TextAlign.center,
              style: ChatTheme.bodyMd(),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ChatTheme.hairlineSand),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
