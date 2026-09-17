import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../features/posts/domain/entities/comment.dart';
import '../../../features/safety/presentation/widgets/safety_menu.dart';
import '../../../features/safety/presentation/providers/safety_providers.dart';
import '../../../features/posts/domain/entities/post.dart';
import '../../../features/posts/presentation/controllers/comments_controller.dart';
import '../../../features/posts/presentation/controllers/feed_controller.dart';
import '../../../features/profile/presentation/providers/profile_providers.dart';
import '../../theme/circk_theme.dart';
import '../v2/v2_kit.dart';

/// Opens the Comments bottom sheet over the current screen matching Instagram/Threads UX.
Future<void> showCommentsSheet(
  BuildContext context, {
  String? postId,
  String? postAuthorHandle,
  ValueChanged<String>? onOpenProfile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8A000000), // smooth dark backdrop
    builder: (_) => CommentsSheet(
      postId: postId,
      postAuthorHandle: postAuthorHandle,
      onOpenProfile: onOpenProfile,
    ),
  );
}

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({
    super.key,
    this.postId,
    this.postAuthorHandle,
    this.onOpenProfile,
  });

  final String? postId;
  final String? postAuthorHandle;
  final ValueChanged<String>? onOpenProfile;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final Set<String> _expandedParentIds = {};
  String? _replyingToName;
  String? _replyingParentId;

  static const List<String> _kQuickEmojis = ['❤️', '🔥', '🏏', '👏', '🙌', '😍', '😂', '💪'];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _extractMonogram(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return 'ME';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.postId != null) {
      final pid = widget.postId!;
      final parentId = _replyingParentId;
      ref
          .read(commentsControllerProvider(pid).notifier)
          .addComment(text, parentCommentId: parentId);

      // Auto expand thread if replying
      if (parentId != null) {
        _expandedParentIds.add(parentId);
      }

      // Increment feed post count optimistically
      ref
          .read(feedControllerProvider.notifier)
          .incrementCommentsCount(PostId(pid));
    }

    setState(() {
      _replyingToName = null;
      _replyingParentId = null;
      _controller.clear();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onReply({required Comment comment, required String parentId}) {
    final handle = (comment.authorUsername != null && comment.authorUsername!.trim().isNotEmpty)
        ? comment.authorUsername!.trim().replaceAll('@', '')
        : (comment.authorName ?? 'user').trim().split(' ').first.toLowerCase();

    setState(() {
      _replyingToName = comment.authorName ?? 'user';
      _replyingParentId = parentId;
      _expandedParentIds.add(parentId);
    });
    _controller.text = '@$handle ';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _focusNode.requestFocus();
  }

  void _onEmojiTap(String emoji) {
    final current = _controller.text;
    final pos = _controller.selection.baseOffset;
    if (pos >= 0 && pos <= current.length) {
      final newText = current.substring(0, pos) + emoji + current.substring(pos);
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: pos + emoji.length),
      );
    } else {
      _controller.text = current + emoji;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _toggleReplies(String parentId) {
    setState(() {
      if (_expandedParentIds.contains(parentId)) {
        _expandedParentIds.remove(parentId);
      } else {
        _expandedParentIds.add(parentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final sheetH = screenH * 0.70;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final commentsAsync = widget.postId != null
        ? ref.watch(commentsControllerProvider(widget.postId!))
        : null;

    final commentsList = commentsAsync?.value ?? const <Comment>[];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: sheetH,
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Grabber handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: CkColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    'Comments',
                    style: CkType.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: CkColors.hairline),

              // Comments Body
              Expanded(
                child: commentsAsync == null
                    ? const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: CkColors.muted),
                        ),
                      )
                    : commentsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CkColors.ink,
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Text(
                            'Error loading comments: $err',
                            style: const TextStyle(color: CkColors.red),
                          ),
                        ),
                        data: (_) {
                          if (commentsList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 40,
                                    color: CkColors.muted,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No comments yet',
                                    style: CkType.display(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CkColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Start the conversation.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CkColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: commentsList.length,
                            itemBuilder: (context, index) {
                              final parent = commentsList[index];
                              final myUid = ref.read(myProfileProvider).value?.userId.value;
                              final isExpanded = _expandedParentIds.contains(parent.id);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _InstagramCommentRow(
                                    comment: parent,
                                    isMe: parent.authorId == myUid,
                                    isReply: false,
                                    onOpenProfile: widget.onOpenProfile,
                                    onReply: () => _onReply(
                                      comment: parent,
                                      parentId: parent.id,
                                    ),
                                    onLikeToggle: () {
                                      if (widget.postId != null) {
                                        ref
                                            .read(commentsControllerProvider(widget.postId!).notifier)
                                            .toggleCommentLike(parent.id);
                                      }
                                    },
                                  ),

                                  // Replies Accordion
                                  if (parent.replies.isNotEmpty) ...[
                                    if (!isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(58, 2, 16, 10),
                                        child: GestureDetector(
                                          onTap: () => _toggleReplies(parent.id),
                                          behavior: HitTestBehavior.opaque,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 1,
                                                color: CkColors.soft,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'View ${parent.replies.length} more ${parent.replies.length == 1 ? 'reply' : 'replies'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: CkColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else ...[
                                      for (final reply in parent.replies)
                                        _InstagramCommentRow(
                                          comment: reply,
                                          isMe: reply.authorId == myUid,
                                          isReply: true,
                                          onOpenProfile: widget.onOpenProfile,
                                          onReply: () => _onReply(
                                            comment: reply,
                                            parentId: parent.id,
                                          ),
                                          onLikeToggle: () {
                                            if (widget.postId != null) {
                                              ref
                                                  .read(commentsControllerProvider(widget.postId!).notifier)
                                                  .toggleCommentLike(reply.id);
                                            }
                                          },
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(58, 4, 16, 10),
                                        child: GestureDetector(
                                          onTap: () => _toggleReplies(parent.id),
                                          behavior: HitTestBehavior.opaque,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 1,
                                                color: CkColors.soft,
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'Hide replies',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: CkColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),

              // Replying banner
              if (_replyingToName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: CkColors.paper2,
                  child: Row(
                    children: [
                      Text(
                        'Replying to ',
                        style: CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                      Text(
                        _replyingToName!,
                        style: CkType.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _replyingToName = null;
                          _replyingParentId = null;
                        }),
                        child: const V2Svg(
                          V2Icons.close,
                          size: 14,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick Emoji Row
              Container(
                decoration: const BoxDecoration(
                  color: CkColors.paper,
                  border: Border(
                    top: BorderSide(
                      color: Color(0x33C8C4B7),
                      width: 0.8,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _kQuickEmojis
                      .map(
                        (emoji) => GestureDetector(
                          onTap: () => _onEmojiTap(emoji),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 21),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              // Bottom Input Composer
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final profile = ref.watch(myProfileProvider).value;
    final name = (profile?.displayName?.trim().isNotEmpty ?? false)
        ? profile!.displayName!.trim()
        : 'You';
    final mono = _extractMonogram(name);

    final placeholder = _replyingToName != null
        ? 'Reply to $_replyingToName…'
        : (widget.postAuthorHandle != null
            ? 'Add a comment for ${widget.postAuthorHandle}…'
            : 'Add a comment…');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      color: CkColors.paper,
      child: Row(
        children: [
          Avatar(mono: mono, size: 34, tone: AvatarTone.ink),
          const SizedBox(width: 10),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  style: CkType.body(fontSize: 13.5, color: CkColors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: CkColors.paper2,
                    hintText: placeholder,
                    hintStyle: const TextStyle(fontSize: 13, color: CkColors.soft),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: CkColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: CkColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: CkColors.line),
                    ),
                    suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 32),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: hasText ? _submitComment : null,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: hasText ? CkColors.ink : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: V2Svg(
                            V2Icons.share,
                            size: 13,
                            color: hasText ? CkColors.paper : CkColors.soft,
                            strokeWidth: 2.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InstagramCommentRow extends ConsumerWidget {
  const _InstagramCommentRow({
    required this.comment,
    required this.isMe,
    required this.isReply,
    required this.onReply,
    required this.onLikeToggle,
    this.onOpenProfile,
  });

  final Comment comment;
  final bool isMe;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback onLikeToggle;
  final ValueChanged<String>? onOpenProfile;

  void _navigateToProfile(BuildContext context, String rawHandle) {
    final clean = rawHandle.replaceAll('@', '').trim();
    if (clean.isEmpty) return;
    if (onOpenProfile != null) {
      onOpenProfile!(clean);
    } else {
      context.push('/u/$clean');
    }
  }

  List<InlineSpan> _buildBodySpans(BuildContext context, String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(@[a-zA-Z0-9_\.]+)');
    final matches = regex.allMatches(text);

    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: const TextStyle(color: CkColors.ink),
          ),
        );
      }
      final handle = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _navigateToProfile(context, handle),
            behavior: HitTestBehavior.opaque,
            child: Text(
              handle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E5BB2),
              ),
            ),
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: const TextStyle(color: CkColors.ink),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(blockedAccountsProvider).value?.any((u) => u.id == comment.authorId) ?? false) return const SizedBox.shrink();
    final timeStr = timeago.format(comment.createdAt, locale: 'en_short');
    final authorHandle = (comment.authorUsername != null && comment.authorUsername!.trim().isNotEmpty)
        ? comment.authorUsername!.trim().replaceAll('@', '')
        : (comment.authorName ?? 'user').trim().toLowerCase().replaceAll(' ', '_');

    return Container(
      padding: EdgeInsets.fromLTRB(isReply ? 58 : 16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context, authorHandle),
            behavior: HitTestBehavior.opaque,
            child: Avatar(
              mono: comment.authorMonogram,
              imageUrl: comment.authorPhotoUrl,
              size: isReply ? 26 : 34,
              tone: isMe ? AvatarTone.ink : AvatarTone.paper,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row: handle + time + YOU badge
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(context, authorHandle),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        authorHandle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CkColors.muted,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: CkColors.paper2,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: CkColors.hairline),
                        ),
                        child: Text(
                          'YOU',
                          style: CkType.mono(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: CkColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                if (!isMe) Align(alignment: Alignment.centerRight, child: SafetyMenu(userId: comment.authorId, kind: 'comment', targetId: comment.id)),
                // Comment body text
                RichText(
                  text: TextSpan(
                    style: CkType.body(
                      fontSize: 13,
                      height: 1.35,
                      color: CkColors.ink,
                    ),
                    children: _buildBodySpans(context, comment.text),
                  ),
                ),
                const SizedBox(height: 5),

                // Action row: Reply
                GestureDetector(
                  onTap: onReply,
                  behavior: HitTestBehavior.opaque,
                  child: const Text(
                    'Reply',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: CkColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right vertical stack: Heart icon + like count
          GestureDetector(
            onTap: onLikeToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 15,
                    color: comment.isLiked ? CkColors.red : CkColors.muted,
                  ),
                  if (comment.likesCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${comment.likesCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: comment.isLiked ? CkColors.red : CkColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
