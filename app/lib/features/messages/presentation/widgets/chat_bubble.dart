import 'dart:io' as io;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../safety/presentation/providers/safety_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/messages_providers.dart';
import 'chat_avatar.dart';
import 'chat_theme.dart';

class ChatBubble extends ConsumerStatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMultiParticipant,
    this.showSender = true,
    this.isSelected = false,
    this.onReply,
    this.onDelete,
    this.onSelect,
    this.onRetry,
    this.onReactionSelected,
  });

  final ChatMessage message;
  final bool isMultiParticipant;
  final bool showSender;
  final bool isSelected;
  final ValueChanged<ChatMessage>? onReply;
  final ValueChanged<ChatMessage>? onDelete;
  final ValueChanged<ChatMessage>? onSelect;
  final ValueChanged<ChatMessage>? onRetry;
  final void Function(ChatMessage message, String emoji)? onReactionSelected;

  @override
  ConsumerState<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<ChatBubble> {
  static final DateFormat _time = DateFormat('h:mm a');
  static const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

  double _dragOffset = 0;
  bool _showReactions = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final blocked = ref.watch(blockedAccountsProvider).value?.any(
              (user) => user.id == message.senderId,
            ) ??
        false;
    if (blocked) return const SizedBox.shrink();

    final me = message.fromMe;
    final senderName = message.senderDisplayName ?? 'Deleted user';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            final delta = details.primaryDelta ?? 0;
            if (delta <= 0) return;
            setState(() {
              _dragOffset = (_dragOffset + delta).clamp(0.0, 72.0).toDouble();
            });
          },
          onHorizontalDragEnd: (_) {
            if (_dragOffset >= 48 && !message.isDeleted) {
              HapticFeedback.lightImpact();
              widget.onReply?.call(message);
            }
            setState(() => _dragOffset = 0);
          },
          onHorizontalDragCancel: () => setState(() => _dragOffset = 0),
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment:
                    me ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!me && widget.isMultiParticipant) ...[
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: widget.showSender
                          ? ChatAvatar(
                              label: senderName,
                              imageUrl: message.senderAvatarUrl,
                              size: 32,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment:
                          me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!me &&
                            widget.isMultiParticipant &&
                            widget.showSender &&
                            !message.isDeleted)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 3),
                            child: Text(
                              senderName,
                              style: ChatTheme.badge(
                                color: ChatTheme.charcoalInk,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onLongPress: message.isDeleted
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _showReactions = true);
                                  widget.onSelect?.call(message);
                                },
                          onTap: _showReactions
                              ? () => setState(() => _showReactions = false)
                              : null,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                            ),
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: me
                                  ? ChatTheme.charcoalInk
                                  : ChatTheme.pureSurface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(me ? 14 : 4),
                                bottomRight: Radius.circular(me ? 4 : 14),
                              ),
                              border: Border.all(
                                color: widget.isSelected
                                    ? ChatTheme.matchDayCoral
                                    : me
                                        ? ChatTheme.charcoalInk
                                        : ChatTheme.hairlineSand,
                                width: widget.isSelected ? 2 : 1,
                              ),
                              boxShadow: me ? null : ChatTheme.whisperShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.replyToBody?.isNotEmpty == true &&
                                    !message.isDeleted) ...[
                                  _ReplyPreview(
                                    author: message.replyToAuthor ?? 'Reply',
                                    body: message.replyToBody!,
                                    fromMe: me,
                                  ),
                                  const SizedBox(height: 7),
                                ],
                                if (message.isImage && !message.isDeleted) ...[
                                  _PhotoAttachment(
                                    localPath: message.localMediaPath,
                                    storagePath: message.storageMediaPath,
                                    fromMe: me,
                                  ),
                                  if ((message.body ?? '').trim().isNotEmpty)
                                    const SizedBox(height: 6),
                                ],
                                if (!message.isImage ||
                                    (message.body ?? '').trim().isNotEmpty ||
                                    message.isDeleted)
                                  Text(
                                    message.isDeleted
                                        ? 'This message was deleted'
                                        : (message.body ?? ''),
                                    style: ChatTheme.bodyMd(
                                      color: me
                                          ? ChatTheme.pureSurface
                                          : ChatTheme.charcoalInk,
                                    ).copyWith(
                                      fontStyle: message.isDeleted
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (message.isEdited && !message.isDeleted)
                                      Text(
                                        'edited  ',
                                        style: ChatTheme.timestamp(
                                          color: me
                                              ? Colors.white60
                                              : ChatTheme.mutedStone,
                                        ),
                                      ),
                                    Text(
                                      _time.format(message.createdAt.toLocal()),
                                      style: ChatTheme.timestamp(
                                        color: me
                                            ? Colors.white60
                                            : ChatTheme.mutedStone,
                                      ),
                                    ),
                                    if (me) ...[
                                      const SizedBox(width: 5),
                                      _DeliveryIcon(
                                        status: message.deliveryStatus,
                                        onRetry: message.isFailed
                                            ? () => widget.onRetry?.call(message)
                                            : null,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (message.reactions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Wrap(
                              spacing: 4,
                              children: _reactionCounts(message)
                                  .entries
                                  .map(
                                    (entry) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ChatTheme.softSandFill,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: ChatTheme.hairlineSand,
                                        ),
                                      ),
                                      child: Text(
                                        '${entry.key} ${entry.value}',
                                        style: ChatTheme.badge(),
                                      ),
                                    ),
                                  )
                                  .toList(),
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
        if (_showReactions)
          Positioned(
            top: -38,
            left: me ? null : (widget.isMultiParticipant ? 40 : 0),
            right: me ? 0 : null,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(999),
              color: ChatTheme.pureSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _quickReactions
                      .map(
                        (emoji) => InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            widget.onReactionSelected?.call(message, emoji);
                            setState(() => _showReactions = false);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(emoji, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Map<String, int> _reactionCounts(ChatMessage message) {
    final counts = <String, int>{};
    for (final reaction in message.reactions) {
      if (reaction.isRemoved) continue;
      counts.update(reaction.reaction, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: fromMe ? Colors.white10 : ChatTheme.softSandFill,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: fromMe ? ChatTheme.pureSurface : ChatTheme.matchDayCoral,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: ChatTheme.badge(
              color: fromMe ? ChatTheme.pureSurface : ChatTheme.matchDayCoral,
            ),
          ),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ChatTheme.bodySm(
              color: fromMe ? Colors.white70 : ChatTheme.mutedStone,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({required this.status, this.onRetry});

  final MessageDeliveryStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageDeliveryStatus.pending => const Icon(
          Icons.schedule_rounded,
          size: 14,
          color: Colors.white60,
        ),
      MessageDeliveryStatus.sending => const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white60,
          ),
        ),
      MessageDeliveryStatus.sent => const Icon(
          Icons.done_rounded,
          size: 14,
          color: Colors.white60,
        ),
      MessageDeliveryStatus.delivered => const Icon(
          Icons.done_all_rounded,
          size: 14,
          color: Colors.white60,
        ),
      MessageDeliveryStatus.read => const Icon(
          Icons.done_all_rounded,
          size: 14,
          color: ChatTheme.matchDayCoral,
        ),
      MessageDeliveryStatus.failed => InkWell(
          onTap: onRetry,
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(
              Icons.refresh_rounded,
              size: 15,
              color: ChatTheme.destructiveCoralText,
            ),
          ),
        ),
    };
  }
}

class _PhotoAttachment extends ConsumerWidget {
  const _PhotoAttachment({
    required this.fromMe,
    this.localPath,
    this.storagePath,
  });

  final bool fromMe;
  final String? localPath;
  final String? storagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget frame(Widget child) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 220,
            height: 180,
            child: child,
          ),
        );

    Widget broken() => frame(
          Container(
            color: fromMe ? Colors.white12 : ChatTheme.softSandFill,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: ChatTheme.mutedStone,
              ),
            ),
          ),
        );

    void showImage(Widget image) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(child: InteractiveViewer(child: image)),
              SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final local = localPath?.trim();
    if (local != null && local.isNotEmpty) {
      final file = io.File(local);
      if (file.existsSync()) {
        final image = Image.file(file, fit: BoxFit.cover);
        return GestureDetector(
          onTap: () => showImage(Image.file(file, fit: BoxFit.contain)),
          child: frame(image),
        );
      }
    }

    final storage = storagePath?.trim();
    if (storage == null || storage.isEmpty) return broken();

    Widget network(String url) {
      final image = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: fromMe ? Colors.white12 : ChatTheme.softSandFill,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ChatTheme.matchDayCoral,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => broken(),
      );
      return GestureDetector(
        onTap: () => showImage(
          CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
        child: frame(image),
      );
    }

    if (storage.startsWith('http://') || storage.startsWith('https://')) {
      return network(storage);
    }

    return ref.watch(chatMediaUrlProvider(storage)).when(
          data: network,
          loading: () => frame(
            Container(
              color: fromMe ? Colors.white12 : ChatTheme.softSandFill,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ChatTheme.matchDayCoral,
                ),
              ),
            ),
          ),
          error: (_, __) => broken(),
        );
  }
}
