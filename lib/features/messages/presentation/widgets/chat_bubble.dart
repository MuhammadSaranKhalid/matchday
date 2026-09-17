import 'dart:io' as io;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'chat_theme.dart';
import '../../../posts/domain/entities/post_media.dart';
import '../../../posts/presentation/screens/photo_viewer_screen.dart';
import '../../../safety/presentation/providers/safety_providers.dart';
import '../../domain/entities/chat_message.dart' show MessageDeliveryStatus;
import '../../domain/entities/message.dart';

class ChatBubble extends ConsumerStatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isTeam,
    this.showSender = true,
    this.isSelected = false,
    this.onReply,
    this.onDelete,
    this.onSelect,
    this.onReactionSelected,
  });

  final Message message;
  final bool isTeam;
  final bool showSender;
  final bool isSelected;
  final ValueChanged<Message>? onReply;
  final ValueChanged<Message>? onDelete;
  final ValueChanged<Message>? onSelect;
  final void Function(Message message, String emoji)? onReactionSelected;

  @override
  ConsumerState<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<ChatBubble> {
  static final _timeFmt = DateFormat('h:mm a');
  double _dragOffset = 0.0;
  bool _showingReactions = false;

  @override
  Widget build(BuildContext context) {
    if (ref.watch(blockedAccountsProvider).value?.any((u) => u.id == widget.message.senderId) ?? false) {
      return const SizedBox.shrink();
    }

    final m = widget.message;
    final me = m.fromMe;
    final isDeleted = m.isDeleted;
    final senderName = m.senderDisplayName ?? 'Teammate';
    final time = _timeFmt.format(m.createdAt.toLocal());
    final isSelected = widget.isSelected;

    // Sender initials monogram for team chat
    final mono = senderName.isNotEmpty
        ? senderName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Swipe-to-reply wrapper
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! > 0) {
              setState(() {
                _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, 72.0);
              });
            } else if (details.primaryDelta != null && details.primaryDelta! < 0) {
              setState(() {
                _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, 72.0);
              });
            }
          },
          onHorizontalDragEnd: (details) {
            if (_dragOffset >= 48) {
              HapticFeedback.lightImpact();
              widget.onReply?.call(m);
            }
            setState(() => _dragOffset = 0.0);
          },
          onHorizontalDragCancel: () => setState(() => _dragOffset = 0.0),
          behavior: HitTestBehavior.opaque,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left avatar for team incoming messages
                  if (!me && widget.isTeam) ...[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ChatTheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: ChatTheme.hairlineSand),
                      ),
                      child: Text(
                        mono,
                        style: ChatTheme.badge(
                          color: ChatTheme.charcoalInk,
                        ),
                      ),
                    ),
                  ],

                  // Bubble body & sender name
                  Flexible(
                    child: Column(
                      crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Team chat sender name above incoming message
                        if (!me && widget.isTeam && widget.showSender && !isDeleted)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 3),
                            child: Text(
                              senderName,
                              style: ChatTheme.rowTitle(
                                color: ChatTheme.charcoalInk,
                              ),
                            ),
                          ),

                        // Bubble container
                        GestureDetector(
                          onLongPress: isDeleted ? null : () => _handleLongPress(context),
                          onTap: () {
                            if (_showingReactions) {
                              setState(() => _showingReactions = false);
                            }
                            if (widget.onSelect != null && isSelected) {
                              widget.onSelect!(m);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * (me ? 0.82 : 0.85),
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: me ? ChatTheme.charcoalInk : ChatTheme.pureSurface,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(14),
                                    topRight: const Radius.circular(14),
                                    bottomLeft: Radius.circular(me ? 14 : 4),
                                    bottomRight: Radius.circular(me ? 4 : 14),
                                  ),
                                  border: isSelected
                                      ? Border.all(color: ChatTheme.matchDayCoral, width: 2)
                                      : (me
                                          ? null
                                          : Border.all(color: ChatTheme.hairlineSand)),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: ChatTheme.matchDayCoral.withValues(alpha: 0.15),
                                            offset: const Offset(0, 2),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : (me ? null : ChatTheme.whisperShadow),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Nested Quoted Reply Card
                                    if (m.replyToBody != null &&
                                        m.replyToBody!.isNotEmpty &&
                                        !isDeleted)
                                      _NestedReplyCard(
                                        author: m.replyToAuthor ?? 'Replying',
                                        body: m.replyToBody!,
                                        fromMe: me,
                                      ),

                                    // Photo Attachment
                                    if (m.isImage &&
                                        m.mediaUrl != null &&
                                        m.mediaUrl!.isNotEmpty &&
                                        !isDeleted)
                                      _PhotoAttachment(
                                        url: m.mediaUrl!,
                                        fromMe: me,
                                        caption: m.body != 'Photo' ? m.body : null,
                                      ),

                                    // Text Content
                                    if (!m.isImage || (m.body != 'Photo' && !m.isImage))
                                      Text(
                                        isDeleted ? 'This message was deleted' : m.body,
                                        style: isDeleted
                                            ? ChatTheme.bodyMd(
                                                color: me
                                                    ? ChatTheme.pureSurface.withValues(alpha: 0.6)
                                                    : ChatTheme.mutedStone,
                                              ).copyWith(fontStyle: FontStyle.italic)
                                            : ChatTheme.bodyMd(
                                                color: me ? ChatTheme.pureSurface : ChatTheme.charcoalInk,
                                              ),
                                      ),
                                  ],
                                ),
                              ),

                              // Selected Checkmark Badge Indicator
                              if (isSelected)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: ChatTheme.matchDayCoral,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 13,
                                      color: ChatTheme.pureSurface,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Timestamp & Read Receipts Row
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                time,
                                style: ChatTheme.timestamp(),
                              ),
                              if (m.isEdited && !isDeleted) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '• edited',
                                  style: ChatTheme.timestamp(),
                                ),
                              ],
                              if (me && !isDeleted) ...[
                                const SizedBox(width: 4),
                                switch (m.deliveryStatus) {
                                  MessageDeliveryStatus.pending ||
                                  MessageDeliveryStatus.sending =>
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: ChatTheme.mutedStone,
                                    ),
                                  MessageDeliveryStatus.sent =>
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: ChatTheme.mutedStone,
                                    ),
                                  MessageDeliveryStatus.delivered =>
                                    const Icon(
                                      Icons.done_all_rounded,
                                      size: 14,
                                      color: ChatTheme.mutedStone,
                                    ),
                                  MessageDeliveryStatus.read =>
                                    const Icon(
                                      Icons.done_all_rounded,
                                      size: 14,
                                      color: ChatTheme.matchDayCoral,
                                    ),
                                  MessageDeliveryStatus.failed =>
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 14,
                                      color: ChatTheme.destructiveCoralText,
                                    ),
                                },
                              ],
                            ],
                          ),
                        ),

                        // Reaction badges
                        if (m.reactions.isNotEmpty && !isDeleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: () {
                                final counts = <String, int>{};
                                for (final r in m.reactions) {
                                  counts[r.reaction] = (counts[r.reaction] ?? 0) + 1;
                                }
                                return counts.entries.map((entry) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ChatTheme.softSandFill,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: ChatTheme.hairlineSand),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(entry.key, style: const TextStyle(fontSize: 12)),
                                        if (entry.value > 1) ...[
                                          const SizedBox(width: 3),
                                          Text(
                                            '${entry.value}',
                                            style: ChatTheme.metadata(
                                              color: ChatTheme.charcoalInk,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList();
                              }(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating Reaction Pill Bar on Long-Press
        if (_showingReactions)
          Positioned(
            top: -42,
            left: me ? null : 40,
            right: me ? 16 : null,
            child: _FloatingReactionBar(
              onSelectEmoji: (emoji) {
                setState(() => _showingReactions = false);
                widget.onReactionSelected?.call(m, emoji);
              },
              onClose: () => setState(() => _showingReactions = false),
            ),
          ),
      ],
    );
  }

  void _handleLongPress(BuildContext context) {
    HapticFeedback.mediumImpact();
    setState(() => _showingReactions = !_showingReactions);
    widget.onSelect?.call(widget.message);
  }
}

// ─── Nested Quoted Reply Card ────────────────────────────────────────────────
class _NestedReplyCard extends StatelessWidget {
  const _NestedReplyCard({
    required this.author,
    required this.body,
    required this.fromMe,
  });

  final String author;
  final String body;
  final bool fromMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fromMe
            ? Colors.white.withValues(alpha: 0.12)
            : ChatTheme.softSandFill,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: ChatTheme.matchDayCoral, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ChatTheme.metadata(
              color: ChatTheme.matchDayCoral,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ChatTheme.bodySm(
              color: fromMe
                  ? ChatTheme.pureSurface.withValues(alpha: 0.8)
                  : ChatTheme.mutedStone,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating Reaction Bar ───────────────────────────────────────────────────
class _FloatingReactionBar extends StatelessWidget {
  const _FloatingReactionBar({
    required this.onSelectEmoji,
    required this.onClose,
  });

  final ValueChanged<String> onSelectEmoji;
  final VoidCallback onClose;

  static const _emojis = ['🏏', '🔥', '👍', '❤️', '👏', '😂'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ChatTheme.pureSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ChatTheme.hairlineSand),
          boxShadow: ChatTheme.floatingCardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._emojis.map((emoji) => GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelectEmoji(emoji);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                )),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ChatTheme.softSandFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: ChatTheme.hairlineSand),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: ChatTheme.mutedStone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Attachment ────────────────────────────────────────────────────────
class _PhotoAttachment extends StatelessWidget {
  const _PhotoAttachment({
    required this.url,
    required this.fromMe,
    this.caption,
  });

  final String url;
  final bool fromMe;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => PhotoViewerScreen(
              media: [
                PostMedia(
                  url: url,
                  blurhash: '',
                  width: 800,
                  height: 800,
                ),
              ],
              initialIndex: 0,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(
            maxHeight: 220,
            minWidth: 160,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (url.startsWith('/') || url.startsWith('file://'))
                Image.file(
                  io.File(url.replaceFirst('file://', '')),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: fromMe ? Colors.white12 : ChatTheme.softSandFill,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 28,
                        color: ChatTheme.mutedStone,
                      ),
                    ),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: fromMe ? Colors.white12 : ChatTheme.softSandFill,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ChatTheme.matchDayCoral,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 120,
                    color: fromMe ? Colors.white12 : ChatTheme.softSandFill,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 28,
                        color: ChatTheme.mutedStone,
                      ),
                    ),
                  ),
                ),
              if (caption != null && caption!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      caption!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
