import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:matchday/core/error/failures.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/core/widgets/v2/v2_kit.dart';
import 'package:matchday/features/messages/domain/entities/chat.dart';
import 'package:matchday/features/messages/domain/entities/message.dart';
import 'package:matchday/features/messages/presentation/controllers/message_thread_controller.dart';
import 'package:matchday/features/messages/presentation/providers/messages_providers.dart';
import 'package:matchday/features/messages/presentation/widgets/chat_bubble.dart';
import 'package:matchday/features/messages/presentation/widgets/chat_composer.dart';
import 'package:matchday/features/messages/presentation/widgets/color_utils.dart';

class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _composerFocus = FocusNode();
  bool _sending = false;
  String? _composerError;
  Message? _replyingTo;

  /// Trailing debounce for draft autosave — fired 250ms after the last
  /// keystroke.
  Timer? _draftSaveDebounce;

  // ─── Pagination state (ticket #35) ──────────────────────────────────────
  bool _hasMoreOlder = true;
  bool _isLoadingOlder = false;

  @override
  void initState() {
    super.initState();
    // Stamp last_read_at once the controller is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(messageThreadProvider(widget.chatId).notifier).markRead();
    });
    // Restore composer text from a persisted draft, if any.
    _restoreDraft();
    // Autosave the composer text as the user types (debounced).
    _textController.addListener(_onComposerChanged);
  }

  Future<void> _restoreDraft() async {
    final draft = await ref
        .read(messagesRepositoryProvider)
        .readDraft(ChatId(widget.chatId));
    if (!mounted || draft == null || draft.isEmpty) return;
    if (_textController.text.isNotEmpty) return;
    _textController.text = draft;
    _textController.selection =
        TextSelection.collapsed(offset: draft.length);
  }

  void _onComposerChanged() {
    _draftSaveDebounce?.cancel();
    final snapshot = _textController.text;
    _draftSaveDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      final repo = ref.read(messagesRepositoryProvider);
      if (snapshot.trim().isEmpty) {
        await repo.deleteDraft(ChatId(widget.chatId));
      } else {
        await repo.saveDraft(ChatId(widget.chatId), snapshot);
      }
    });
  }

  @override
  void dispose() {
    _draftSaveDebounce?.cancel();
    _textController.removeListener(_onComposerChanged);
    _textController.dispose();
    _scrollController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  /// Find this chat in the inbox so the header has a name + crest.
  Chat? _findChat() {
    return ref.watch(myChatsProvider.select((async) {
      return switch (async) {
        AsyncData(:final value) =>
          value.where((c) => c.id.value == widget.chatId).firstOrNull,
        _ => null,
      };
    }));
  }

  Future<void> _onLoadOlder() async {
    if (!_hasMoreOlder || _isLoadingOlder || !mounted) return;
    setState(() => _isLoadingOlder = true);
    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .loadOlder();
    if (!mounted) return;
    setState(() {
      _isLoadingOlder = false;
      result.fold(
        (_) {},
        (count) {
          if (count < 50) _hasMoreOlder = false;
        },
      );
    });
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _composerError = null;
    });

    final replyId = _replyingTo?.id.value;
    final result = await ref.read(messageThreadProvider(widget.chatId).notifier).send(
          text,
          replyToId: replyId,
        );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _sending = false;
        _composerError = failure.message;
      }),
      (_) {
        _textController.clear();
        setState(() {
          _sending = false;
          _composerError = null;
          _replyingTo = null;
        });
        _composerFocus.requestFocus();
        _scrollToBottom();
      },
    );
  }

  Future<void> _sendImage(File imageFile) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _composerError = null;
    });

    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.path.split('.').last;
    final replyId = _replyingTo?.id.value;

    final result = await ref.read(messageThreadProvider(widget.chatId).notifier).sendImage(
          imageBytes: bytes,
          extension: ext,
          replyToId: replyId,
        );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _sending = false;
        _composerError = failure.message;
      }),
      (_) {
        setState(() {
          _sending = false;
          _composerError = null;
          _replyingTo = null;
        });
        _scrollToBottom();
      },
    );
  }

  void _deleteMessage(Message message) async {
    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .deleteMessage(message.id.value);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message: ${f.message}')),
      ),
      (_) {},
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = _findChat();
    final threadAsync = ref.watch(messageThreadProvider(widget.chatId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _ThreadHeader(
              chat: chat,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: switch (threadAsync) {
                AsyncData(:final value) => value.isEmpty
                    ? const _EmptyBody()
                    : _Conversation(
                        messages: value,
                        isTeam: chat?.isTeam ?? false,
                        scroll: _scrollController,
                        isLoadingOlder: _isLoadingOlder,
                        hasMoreOlder: _hasMoreOlder,
                        onLoadOlder: _onLoadOlder,
                        onReply: (m) => setState(() => _replyingTo = m),
                        onDelete: _deleteMessage,
                      ),
                AsyncError(:final error) => _ErrorBody(
                    message: error is FailureWrapper
                        ? error.failure.message
                        : error.toString(),
                    onRetry: () =>
                        ref.invalidate(messageThreadProvider(widget.chatId)),
                  ),
                _ => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CkColors.ink,
                      ),
                    ),
                  ),
              },
            ),
            ChatComposer(
              textController: _textController,
              focusNode: _composerFocus,
              onSendText: _send,
              onSendImage: _sendImage,
              sending: _sending,
              replyingTo: _replyingTo,
              onCancelReply: () => setState(() => _replyingTo = null),
              error: _composerError,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({required this.chat, required this.onBack});

  final Chat? chat;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final name = chat?.displayName ?? '…';
    final mono = chat?.displayMonogram ?? '?';
    final color = parseHexColor(chat?.teamPrimaryColorHex, CkColors.ink);
    final isTeam = chat?.isTeam == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              child: const V2Svg(
                V2Icons.chevronLeft,
                size: 18,
                color: CkColors.ink,
              ),
            ),
          ),
          if (isTeam)
            Crest(short: mono, color: color, size: 36, radius: 10)
          else if (chat?.displayAvatarUrl.isNotEmpty == true)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: chat!.displayAvatarUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Avatar(mono: mono, size: 36, tone: AvatarTone.ink),
                errorWidget: (_, __, ___) =>
                    Avatar(mono: mono, size: 36, tone: AvatarTone.ink),
              ),
            )
          else
            Avatar(mono: mono, size: 36, tone: AvatarTone.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isTeam ? 'Team Chat' : 'Direct Message',
                  style: CkType.body(
                    fontSize: 11,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Conversation list ───────────────────────────────────────────────────────

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.messages,
    required this.isTeam,
    required this.scroll,
    required this.isLoadingOlder,
    required this.hasMoreOlder,
    required this.onLoadOlder,
    required this.onReply,
    required this.onDelete,
  });

  final List<Message> messages;
  final bool isTeam;
  final ScrollController scroll;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final VoidCallback onLoadOlder;
  final ValueChanged<Message> onReply;
  final ValueChanged<Message> onDelete;

  static const _loadOlderThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(messages);
    final itemCount = items.length + (isLoadingOlder ? 1 : 0);

    return ListView.builder(
      controller: scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (isLoadingOlder && i == items.length) {
          return const _LoadOlderSpinner();
        }
        if (hasMoreOlder &&
            !isLoadingOlder &&
            i >= items.length - _loadOlderThreshold) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadOlder());
        }
        return items[items.length - 1 - i];
      },
    );
  }

  /// Group messages by date and check consecutive senders.
  List<Widget> _buildItems(List<Message> msgs) {
    final out = <Widget>[];
    DateTime? lastDay;
    String? lastSenderId;

    for (int i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (lastDay == null || day != lastDay) {
        out.add(_DayDivider(_formatDay(day)));
        out.add(const SizedBox(height: 8));
        lastDay = day;
        lastSenderId = null;
      }

      final showSender = lastSenderId != m.senderId;
      lastSenderId = m.senderId;

      out.add(
        ChatBubble(
          message: m,
          isTeam: isTeam,
          showSender: showSender,
          onReply: onReply,
          onDelete: onDelete,
        ),
      );
    }
    return out;
  }

  String _formatDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(day);
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CkColors.hairline.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: CkType.mono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
            color: CkColors.muted,
          ),
        ),
      ),
    );
  }
}

class _LoadOlderSpinner extends StatelessWidget {
  const _LoadOlderSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: CkColors.muted,
          ),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 24,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Say hello to start the conversation.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 13, color: CkColors.ink, height: 1.5),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
