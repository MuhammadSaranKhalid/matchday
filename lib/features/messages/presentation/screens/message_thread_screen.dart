import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../safety/presentation/providers/safety_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../controllers/message_thread_controller.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_theme.dart';

class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _composerFocus = FocusNode();
  bool _sending = false;
  String? _composerError;
  Message? _replyingTo;

  // Selection mode (Screen 5e64f8b6161b4b75ab780b2923d64221)
  Message? _selectedMessage;

  Timer? _draftSaveDebounce;
  Timer? _typingDebounce;
  bool _isTypingPublished = false;

  bool _hasMoreOlder = true;
  bool _isLoadingOlder = false;
  bool _actingOnRequest = false;

  bool _isScrolledUp = false;
  int _newMessagesWhileScrolledUp = 0;
  int? _initialUnreadCount;

  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  int? _lastMarkedReadSeq;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScrollChanged);
    _restoreDraft();
    _textController.addListener(_onComposerChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _checkAndMarkVisibleRead();
    }
  }

  void _checkAndMarkVisibleRead([List<Message>? currentMessages]) {
    if (!mounted) return;
    if (_lifecycleState != AppLifecycleState.resumed) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    if (_isScrolledUp) return;

    final msgs = currentMessages ??
        ref.read(messageThreadProvider(widget.chatId)).value;
    if (msgs == null || msgs.isEmpty) return;

    int? highestVisibleSeq;
    for (final m in msgs) {
      if (m.messageSeq != null && m.messageSeq! > 0) {
        if (highestVisibleSeq == null || m.messageSeq! > highestVisibleSeq) {
          highestVisibleSeq = m.messageSeq;
        }
      }
    }

    if (highestVisibleSeq != null &&
        (_lastMarkedReadSeq == null || highestVisibleSeq > _lastMarkedReadSeq!)) {
      _lastMarkedReadSeq = highestVisibleSeq;
      ref
          .read(messageThreadProvider(widget.chatId).notifier)
          .markRead(throughSeq: highestVisibleSeq);
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final isScrolledUp = _scrollController.offset > 120;
    if (isScrolledUp != _isScrolledUp) {
      setState(() {
        _isScrolledUp = isScrolledUp;
        if (!_isScrolledUp && _newMessagesWhileScrolledUp > 0) {
          _newMessagesWhileScrolledUp = 0;
          _checkAndMarkVisibleRead();
        }
      });
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await ref
        .read(messagesRepositoryProvider)
        .readDraft(ChatId(widget.chatId));
    if (!mounted || draft == null || draft.isEmpty) return;
    if (_textController.text.isNotEmpty) return;
    _textController.text = draft;
    _textController.selection = TextSelection.collapsed(offset: draft.length);
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

    if (snapshot.trim().isNotEmpty) {
      if (!_isTypingPublished) {
        _isTypingPublished = true;
        ref
            .read(messagesRepositoryProvider)
            .setTyping(ChatId(widget.chatId), true);
      }
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (_isTypingPublished) {
          _isTypingPublished = false;
          ref
              .read(messagesRepositoryProvider)
              .setTyping(ChatId(widget.chatId), false);
        }
      });
    } else {
      if (_isTypingPublished) {
        _typingDebounce?.cancel();
        _isTypingPublished = false;
        ref
            .read(messagesRepositoryProvider)
            .setTyping(ChatId(widget.chatId), false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveDebounce?.cancel();
    _typingDebounce?.cancel();
    if (_isTypingPublished) {
      ref
          .read(messagesRepositoryProvider)
          .setTyping(ChatId(widget.chatId), false);
    }
    _textController.removeListener(_onComposerChanged);
    _textController.dispose();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  Chat? _findChat() {
    return ref.watch(
      myChatsProvider.select((async) {
        return switch (async) {
          AsyncData(:final value) =>
            value.where((c) => c.id.value == widget.chatId).firstOrNull,
          _ => null,
        };
      }),
    );
  }

  Future<void> _onLoadOlder() async {
    if (!_hasMoreOlder || _isLoadingOlder || !mounted) return;
    setState(() => _isLoadingOlder = true);
    final result =
        await ref
            .read(messageThreadProvider(widget.chatId).notifier)
            .loadOlder();
    if (!mounted) return;
    setState(() {
      _isLoadingOlder = false;
      result.fold((_) {}, (count) {
        if (count < 50) _hasMoreOlder = false;
      });
    });
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _sending) return;
    _typingDebounce?.cancel();
    if (_isTypingPublished) {
      _isTypingPublished = false;
      ref
          .read(messagesRepositoryProvider)
          .setTyping(ChatId(widget.chatId), false);
    }
    setState(() {
      _sending = true;
      _composerError = null;
    });

    final replyId = _replyingTo?.id.value;
    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .send(text, replyToId: replyId);
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
    _typingDebounce?.cancel();
    if (_isTypingPublished) {
      _isTypingPublished = false;
      ref
          .read(messagesRepositoryProvider)
          .setTyping(ChatId(widget.chatId), false);
    }
    setState(() {
      _sending = true;
      _composerError = null;
    });

    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.path.split('.').last;
    final replyId = _replyingTo?.id.value;

    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .sendImage(imageBytes: bytes, extension: ext, replyToId: replyId);
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
        SnackBar(
          content: Text('Failed to delete message: ${f.message}'),
          backgroundColor: ChatTheme.charcoalInk,
        ),
      ),
      (_) {
        setState(() => _selectedMessage = null);
      },
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

  Future<void> _acceptRequest() async {
    if (_actingOnRequest) return;
    setState(() => _actingOnRequest = true);
    final res =
        await ref
            .read(messageThreadProvider(widget.chatId).notifier)
            .acceptRequest();
    if (!mounted) return;
    setState(() => _actingOnRequest = false);
    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: ChatTheme.destructiveCoralText,
        ),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message request accepted'),
            backgroundColor: ChatTheme.successMintText,
          ),
        );
      },
    );
  }

  Future<void> _declineRequest() async {
    if (_actingOnRequest) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ChatTheme.pureSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: ChatTheme.hairlineSand),
            ),
            title: Text('Delete Request?', style: ChatTheme.headlineSm()),
            content: Text(
              'This message request will be removed from your inbox.',
              style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: ChatTheme.button(color: ChatTheme.charcoalInk),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Delete',
                  style: ChatTheme.button(
                    color: ChatTheme.destructiveCoralText,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _actingOnRequest = true);
    final res =
        await ref
            .read(messageThreadProvider(widget.chatId).notifier)
            .declineRequest();
    if (!mounted) return;
    setState(() => _actingOnRequest = false);
    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: ChatTheme.destructiveCoralText,
        ),
      ),
      (_) {
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _blockUser() async {
    final chat = _findChat();
    final otherUserId = chat?.dmOtherUserId;
    if (otherUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChatTheme.pureSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ChatTheme.hairlineSand),
        ),
        title: Text(
          'Block ${chat?.displayName ?? "User"}?',
          style: ChatTheme.headlineSm(),
        ),
        content: Text(
          'Blocked players cannot send you message requests or see your active status.',
          style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: ChatTheme.button(color: ChatTheme.charcoalInk),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Block',
              style: ChatTheme.button(
                color: ChatTheme.destructiveCoralText,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final res = await ref.read(safetyRepositoryProvider).block(otherUserId);
    if (!mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: ChatTheme.destructiveCoralText,
        ),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${chat?.displayName ?? "User"} has been blocked'),
            backgroundColor: ChatTheme.charcoalInk,
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = _findChat();
    if (_initialUnreadCount == null && chat != null && chat.unreadCount > 0) {
      _initialUnreadCount = chat.unreadCount;
    }

    ref.listen(messageThreadProvider(widget.chatId), (prev, next) {
      if (next is AsyncData<List<Message>>) {
        final messages = next.value;
        if (messages.isNotEmpty) {
          final prevList = prev?.value ?? const <Message>[];
          if (prevList.isNotEmpty && messages.length > prevList.length) {
            final newCount = messages.length - prevList.length;
            final latest = messages.last;
            if (!latest.fromMe) {
              if (_isScrolledUp) {
                setState(() {
                  _newMessagesWhileScrolledUp += newCount;
                });
              } else {
                _checkAndMarkVisibleRead(messages);
              }
            }
          } else if (prevList.isEmpty && !_isScrolledUp) {
            // Initial paint: advance read horizon after layout once message region is visible (Spec §23)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndMarkVisibleRead(messages);
            });
          }
        }
      }
    });

    final threadAsync = ref.watch(messageThreadProvider(widget.chatId));

    final isIncomingRequest = chat?.isRequest == true;
    final isPendingOutgoing = chat?.isPendingOutgoingRequest == true;

    final placeholder =
        chat?.isTeam == true
            ? 'Message team...'
            : 'Message ${chat?.displayName ?? 'user'}...';

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar (Normal or Selection Mode)
            if (_selectedMessage != null)
              _SelectionHeader(
                selectedMessage: _selectedMessage!,
                onClose: () => setState(() => _selectedMessage = null),
                onReply: (m) {
                  setState(() {
                    _replyingTo = m;
                    _selectedMessage = null;
                  });
                  _composerFocus.requestFocus();
                },
                onDelete: _deleteMessage,
              )
            else
              _ThreadHeader(
                chatId: widget.chatId,
                chat: chat,
                onBack: () => Navigator.of(context).pop(),
              ),

            if (isIncomingRequest)
              _RequestNoticeBanner(
                userName: chat?.displayName ?? 'This player',
              ),

            // Main Message Timeline
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  switch (threadAsync) {
                    AsyncData(:final value) =>
                      value.isEmpty
                          ? const _EmptyBody()
                          : _Conversation(
                            messages: value,
                            isTeam: chat?.isTeam ?? false,
                            scroll: _scrollController,
                            initialUnreadCount: _initialUnreadCount,
                            selectedMessage: _selectedMessage,
                            isLoadingOlder: _isLoadingOlder,
                            hasMoreOlder: _hasMoreOlder,
                            onLoadOlder: _onLoadOlder,
                            onReply: (m) {
                              setState(() => _replyingTo = m);
                              _composerFocus.requestFocus();
                            },
                            onSelect: (m) {
                              setState(() {
                                if (_selectedMessage?.id == m.id) {
                                  _selectedMessage = null;
                                } else {
                                  _selectedMessage = m;
                                }
                              });
                            },
                            onDelete: _deleteMessage,
                            onReaction: (m, emoji) {
                              ref.read(chatRepositoryProvider).setReaction(m.id.value, emoji, true);
                            },
                          ),
                    AsyncError(:final error) => _ErrorBody(
                      message:
                          error is FailureWrapper
                              ? error.failure.message
                              : error.toString(),
                      onRetry:
                          () =>
                              ref.invalidate(messageThreadProvider(widget.chatId)),
                    ),
                    _ => const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ChatTheme.matchDayCoral,
                        ),
                      ),
                    ),
                  },
                  if (_isScrolledUp && _newMessagesWhileScrolledUp > 0)
                    Positioned(
                      bottom: 12,
                      child: _ScrollToBottomPill(
                        count: _newMessagesWhileScrolledUp,
                        onTap: () {
                          _scrollToBottom();
                          setState(() {
                            _newMessagesWhileScrolledUp = 0;
                          });
                          _checkAndMarkVisibleRead();
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Requests or Outgoing notices or Active Composer
            if (isIncomingRequest)
              _RequestActionBar(
                onAccept: _acceptRequest,
                onDecline: _declineRequest,
                onBlock: _blockUser,
                userName: chat?.displayName,
                isLoading: _actingOnRequest,
              )
            else if (isPendingOutgoing)
              const _PendingOutgoingNotice()
            else ...[
              Consumer(
                builder: (context, ref, _) {
                  final isTyping =
                      ref.watch(chatTypingProvider(widget.chatId)).value ??
                      false;
                  return AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState:
                        isTyping
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                    firstChild: _TypingIndicator(
                      displayName: chat?.displayName ?? 'Someone',
                    ),
                    secondChild: const SizedBox.shrink(),
                  );
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
                placeholder: placeholder,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Header: Normal Mode ─────────────────────────────────────────────────────

class _ThreadHeader extends ConsumerWidget {
  const _ThreadHeader({
    required this.chatId,
    required this.chat,
    required this.onBack,
  });

  final String chatId;
  final Chat? chat;
  final VoidCallback onBack;

  void _openDetails(BuildContext context) {
    context.push('/messages/$chatId/details', extra: chat);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = chat?.displayName ?? '…';
    final mono = chat?.displayMonogram ?? '?';
    final isTeam = chat?.isTeam == true;
    final isDm = chat?.isDm == true;

    // Subtitle logic
    final Widget subtitleWidget;
    if (isTeam && chat?.teamId != null) {
      final rosterAsync = ref.watch(rosterProvider(chat!.teamId!.value));
      final count = rosterAsync.value?.length;
      subtitleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ChatTheme.successMintText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            count != null ? '$count Members • Active' : 'Team Chat',
            style: ChatTheme.metadata(color: ChatTheme.mutedStone),
          ),
        ],
      );
    } else if (isDm) {
      subtitleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ChatTheme.successMintText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Active • Online now',
            style: ChatTheme.metadata(color: ChatTheme.successMintText),
          ),
        ],
      );
    } else {
      subtitleWidget = Text(
        'Match Room',
        style: ChatTheme.metadata(color: ChatTheme.matchDayCoral),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: ChatTheme.clubhouseCanvas,
        border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: Row(
        children: [
          // 44px Circular Back Button
          GestureDetector(
            onTap: onBack,
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

          // Avatar & Title Tappable Group
          Expanded(
            child: GestureDetector(
              onTap: () => _openDetails(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isTeam
                                  ? ChatTheme.matchDayCoral
                                  : ChatTheme.softSandFill,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isTeam
                                    ? ChatTheme.matchDayCoral
                                    : ChatTheme.hairlineSand,
                          ),
                        ),
                        child: Text(
                          mono,
                          style: ChatTheme.badge(
                            color:
                                isTeam
                                    ? ChatTheme.pureSurface
                                    : ChatTheme.charcoalInk,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isDm)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: ChatTheme.successMintText,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ChatTheme.clubhouseCanvas,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChatTheme.headlineSm(),
                        ),
                        const SizedBox(height: 1),
                        subtitleWidget,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trailing Info / More trigger
          IconButton(
            onPressed: () => _openDetails(context),
            tooltip: 'Details',
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 22,
              color: ChatTheme.charcoalInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header: Selection Mode ──────────────────────────────────────────────────

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.selectedMessage,
    required this.onClose,
    required this.onReply,
    required this.onDelete,
  });

  final Message selectedMessage;
  final VoidCallback onClose;
  final ValueChanged<Message> onReply;
  final ValueChanged<Message> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: ChatTheme.clubhouseCanvas,
        border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: 'Deselect',
            icon: const Icon(Icons.close_rounded, color: ChatTheme.charcoalInk),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ChatTheme.matchDayCoral,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '1 SELECTED',
                style: ChatTheme.badge(
                  color: ChatTheme.charcoalInk,
                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ],
          ),
          const Spacer(),
          // Reply Action Pill
          GestureDetector(
            onTap: () => onReply(selectedMessage),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ChatTheme.softSandFill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ChatTheme.hairlineSand),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply_rounded,
                    size: 16,
                    color: ChatTheme.charcoalInk,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reply',
                    style: ChatTheme.button(color: ChatTheme.charcoalInk),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delete Action Pill (if own message)
          if (selectedMessage.fromMe)
            GestureDetector(
              onTap: () => onDelete(selectedMessage),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ChatTheme.destructiveCoralBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ChatTheme.destructiveCoralText.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: ChatTheme.destructiveCoralText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delete',
                      style: ChatTheme.button(
                        color: ChatTheme.destructiveCoralText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Conversation Timeline ───────────────────────────────────────────────────

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.messages,
    required this.isTeam,
    required this.scroll,
    required this.selectedMessage,
    required this.isLoadingOlder,
    required this.hasMoreOlder,
    required this.onLoadOlder,
    required this.onReply,
    required this.onSelect,
    required this.onDelete,
    required this.onReaction,
    this.initialUnreadCount,
  });

  final List<Message> messages;
  final bool isTeam;
  final ScrollController scroll;
  final Message? selectedMessage;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final VoidCallback onLoadOlder;
  final ValueChanged<Message> onReply;
  final ValueChanged<Message> onSelect;
  final ValueChanged<Message> onDelete;
  final void Function(Message m, String emoji) onReaction;
  final int? initialUnreadCount;

  static const _loadOlderThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(messages);
    final itemCount = items.length + (isLoadingOlder ? 1 : 0);

    return ListView.builder(
      controller: scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (isLoadingOlder && i == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ChatTheme.mutedStone,
                ),
              ),
            ),
          );
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

  List<Widget> _buildItems(List<Message> msgs) {
    final out = <Widget>[];
    DateTime? lastDay;
    String? lastSenderId;

    final unreadBoundaryIndex = (initialUnreadCount != null && initialUnreadCount! > 0)
        ? msgs.length - initialUnreadCount!
        : -1;

    for (int i = 0; i < msgs.length; i++) {
      if (i == unreadBoundaryIndex && unreadBoundaryIndex >= 0 && unreadBoundaryIndex < msgs.length) {
        out.add(const _UnreadDividerChip('NEW MESSAGES'));
      }

      final m = msgs[i];
      final day = DateTime(
        m.createdAt.year,
        m.createdAt.month,
        m.createdAt.day,
      );
      if (lastDay == null || day != lastDay) {
        out.add(_DayDividerChip(_formatDay(day)));
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
          isSelected: selectedMessage?.id == m.id,
          onReply: onReply,
          onSelect: onSelect,
          onDelete: onDelete,
          onReactionSelected: onReaction,
        ),
      );
    }
    return out;
  }

  String _formatDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'TODAY';
    if (day == yesterday) return 'YESTERDAY';
    return DateFormat('EEEE, d MMM').format(day).toUpperCase();
  }
}

// ─── Day Divider Chip ────────────────────────────────────────────────────────

class _DayDividerChip extends StatelessWidget {
  const _DayDividerChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: ChatTheme.softSandFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ChatTheme.hairlineSand),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(36, 35, 31, 0.02),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(
          label,
          style: ChatTheme.badge(
            color: ChatTheme.mutedStone,
          ).copyWith(fontSize: 10, letterSpacing: 0.6),
        ),
      ),
    );
  }
}

// ─── Unread Divider Chip ─────────────────────────────────────────────────────

class _UnreadDividerChip extends StatelessWidget {
  const _UnreadDividerChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: ChatTheme.hairlineSand, height: 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: ChatTheme.destructiveCoralBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ChatTheme.hairlineSand),
            ),
            child: Text(
              label,
              style: ChatTheme.badge(color: ChatTheme.destructiveCoralText)
                  .copyWith(fontSize: 10, letterSpacing: 0.8),
            ),
          ),
          const Expanded(
            child: Divider(color: ChatTheme.hairlineSand, height: 1),
          ),
        ],
      ),
    );
  }
}

// ─── Scroll To Bottom Pill ───────────────────────────────────────────────────

class _ScrollToBottomPill extends StatelessWidget {
  const _ScrollToBottomPill({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ChatTheme.matchDayCoral,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              count > 1 ? '$count new messages' : 'New message',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Typing Indicator ────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.displayName});

  final String displayName;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: ChatTheme.clubhouseCanvas,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay) % 1.0;
                  final opacity = (value < 0.5 ? value * 2 : (1.0 - value) * 2)
                      .clamp(0.25, 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ChatTheme.charcoalInk.withValues(alpha: opacity),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${widget.displayName} is typing...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChatTheme.bodySm(
                color: ChatTheme.mutedStone,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notices and Empty State ─────────────────────────────────────────────────

class _RequestNoticeBanner extends StatelessWidget {
  const _RequestNoticeBanner({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: ChatTheme.clubhouseCanvas,
        border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ChatTheme.softSandFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ChatTheme.hairlineSand),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.visibility_off_outlined,
              size: 14,
              color: ChatTheme.mutedStone,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$userName won\'t know you\'ve seen this until you accept.',
                overflow: TextOverflow.ellipsis,
                style: ChatTheme.metadata(color: ChatTheme.mutedStone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestActionBar extends StatelessWidget {
  const _RequestActionBar({
    required this.onAccept,
    required this.onDecline,
    required this.onBlock,
    this.userName,
    this.isLoading = false,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onBlock;
  final String? userName;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: ChatTheme.pureSurface,
        border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Accepting allows ${userName ?? "them"} to message you directly.',
            textAlign: TextAlign.center,
            style: ChatTheme.metadata(color: ChatTheme.mutedStone),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Block Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onBlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatTheme.destructiveCoralBg,
                      foregroundColor: ChatTheme.destructiveCoralText,
                      elevation: 0,
                      side: BorderSide(
                        color: ChatTheme.destructiveCoralText.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.block_rounded, size: 17),
                        const SizedBox(width: 4),
                        Text(
                          'Block',
                          style: ChatTheme.button(
                            color: ChatTheme.destructiveCoralText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onDecline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatTheme.softSandFill,
                      foregroundColor: ChatTheme.charcoalInk,
                      elevation: 0,
                      side: const BorderSide(color: ChatTheme.hairlineSand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 17, color: ChatTheme.mutedStone),
                        const SizedBox(width: 4),
                        Text(
                          'Delete',
                          style: ChatTheme.button(color: ChatTheme.charcoalInk),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Accept Button (Expanded slightly more for emphasis)
              Expanded(
                flex: 125,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatTheme.matchDayCoral,
                      foregroundColor: ChatTheme.pureSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ChatTheme.pureSurface,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 18, color: ChatTheme.pureSurface),
                              const SizedBox(width: 4),
                              Text(
                                'Accept',
                                style: ChatTheme.button(color: ChatTheme.pureSurface)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingOutgoingNotice extends StatelessWidget {
  const _PendingOutgoingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        color: ChatTheme.softSandFill,
        border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 18,
            color: ChatTheme.mutedStone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Message request sent. You can send more messages once they accept.',
              style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
            ),
          ),
        ],
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ChatTheme.softSandFill,
                shape: BoxShape.circle,
                border: Border.all(color: ChatTheme.hairlineSand),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 24,
                color: ChatTheme.mutedStone,
              ),
            ),
            const SizedBox(height: 14),
            Text('No messages yet', style: ChatTheme.headlineSm()),
            const SizedBox(height: 4),
            Text(
              'Say hello to start the conversation.',
              textAlign: TextAlign.center,
              style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
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
              style: ChatTheme.bodyMd(),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
