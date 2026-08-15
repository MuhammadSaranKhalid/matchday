import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../posts/domain/entities/post_media.dart';
import '../../../posts/presentation/screens/photo_viewer_screen.dart';
import '../../domain/entities/message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isTeam,
    this.showSender = true,
    this.onReply,
    this.onDelete,
  });

  final Message message;
  final bool isTeam;
  final bool showSender;
  final ValueChanged<Message>? onReply;
  final ValueChanged<Message>? onDelete;

  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final me = message.fromMe;
    final isDeleted = message.isDeleted;
    final senderName = message.senderDisplayName ?? 'Deleted user';
    final time = _timeFmt.format(message.createdAt.toLocal()).toLowerCase();

    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: isDeleted ? null : () => _showActionsSheet(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          margin: const EdgeInsets.symmetric(vertical: 2.5),
          decoration: BoxDecoration(
            color: me ? CkColors.ink : CkColors.paper2,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(me ? 18 : 4),
              bottomRight: Radius.circular(me ? 4 : 18),
            ),
            border: me
                ? null
                : Border.all(color: CkColors.hairline.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF281E0F).withValues(alpha: 0.04),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Team chat sender name
              if (isTeam && !me && showSender && !isDeleted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CkColors.red,
                    ),
                  ),
                ),

              // Quoted / Replied message preview
              if (message.replyToBody != null &&
                  message.replyToBody!.isNotEmpty &&
                  !isDeleted)
                _ReplyPreview(
                  author: message.replyToAuthor ?? 'Replied message',
                  body: message.replyToBody!,
                  fromMe: me,
                ),

              // Photo attachment if any
              if (message.isImage &&
                  message.mediaUrl != null &&
                  message.mediaUrl!.isNotEmpty &&
                  !isDeleted)
                _PhotoAttachment(
                  url: message.mediaUrl!,
                  fromMe: me,
                  caption: message.body != 'Photo' ? message.body : null,
                ),

              // Text Body & Time
              if (!message.isImage || (message.body != 'Photo' && !message.isImage))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Text(
                        isDeleted ? 'This message was deleted' : message.body,
                        style: isDeleted
                            ? TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: me
                                    ? CkColors.paper.withValues(alpha: 0.6)
                                    : CkColors.muted,
                              )
                            : TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: me ? CkColors.paper : CkColors.ink,
                              ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isEdited && !isDeleted)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Text(
                                'edited',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: me
                                      ? CkColors.paper.withValues(alpha: 0.6)
                                      : CkColors.muted,
                                ),
                              ),
                            ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 10,
                              color: me
                                  ? CkColors.paper.withValues(alpha: 0.65)
                                  : CkColors.muted,
                            ),
                          ),
                          if (me && !isDeleted) ...[
                            const SizedBox(width: 3),
                            Icon(
                              Icons.done_all_rounded,
                              size: 13,
                              color: CkColors.paper.withValues(alpha: 0.75),
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

  void _showActionsSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, size: 20, color: CkColors.ink),
                  title: const Text('Copy Text', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: message.body));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                if (onReply != null)
                  ListTile(
                    leading: const Icon(Icons.reply_rounded, size: 20, color: CkColors.ink),
                    title: const Text('Reply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onReply!(message);
                    },
                  ),
                if (message.fromMe && onDelete != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, size: 20, color: CkColors.red),
                    title: const Text('Delete for Everyone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CkColors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDelete!(message);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
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
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: fromMe
            ? Colors.white.withValues(alpha: 0.12)
            : CkColors.paper.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: fromMe ? CkColors.red : CkColors.ink,
            width: 3.5,
          ),
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fromMe ? CkColors.redSoft : CkColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: fromMe
                  ? CkColors.paper.withValues(alpha: 0.75)
                  : CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.all(4),
          constraints: const BoxConstraints(
            maxHeight: 240,
            minWidth: 160,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: fromMe ? Colors.white12 : CkColors.paper,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: fromMe ? Colors.white12 : CkColors.paper,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, size: 28, color: CkColors.muted),
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
