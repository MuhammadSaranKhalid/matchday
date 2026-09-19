import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/push/push_messaging_service.dart';
import '../../../../core/push/push_provider.dart';
import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/entities/chat_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/repositories/chat_repository.dart';
import '../controllers/message_thread_controller.dart';
import '../providers/messages_providers.dart';
import '../utils/chat_timeline_utils.dart';
import '../widgets/chat_avatar.dart';
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
  final _imagePicker = ImagePicker();

  late final ChatRepository _chatRepository;
  late final PushMessagingService _pushMessagingService;

  ChatMessage? _replyingTo;
  ChatMessage? _selectedMessage;
  String? _draftReplyToId;

  Timer? _draftDebounce;
  Timer? _typingDebounce;
  bool _typingPublished = false;
  bool _sending = false;
  String? _composerError;

  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  bool _isScrolledUp = false;
  int _newMessagesWhileScrolledUp = 0;

  bool _capturedInitialReadHorizon = false;
  int? _initialLastReadSeq;
  int? _lastMarkedReadSeq;
  bool _requestPreviewMode = false;

  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _chatRepository = ref.read(chatRepositoryProvider);
    _pushMessagingService = ref.read(pushMessagingServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    _pushMessagingService.setActiveChat(widget.chatId);
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onComposerChanged);
    unawaited(_restoreDraft());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      _pushMessagingService.setActiveChat(widget.chatId);
      _checkAndMarkVisibleRead();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pushMessagingService.setActiveChat(null);
    }
  }

  ChatChannel? _channelFrom(List<ChatChannel>? channels) =>
      channels?.where((channel) => channel.id == widget.chatId).firstOrNull;

  Future<void> _restoreDraft() async {
    final draft = await _chatRepository.readDraftState(widget.chatId);
    if (!mounted || draft == null) return;

    if (_textController.text.isEmpty && draft.body.isNotEmpty) {
      _textController.text = draft.body;
      _textController.selection = TextSelection.collapsed(
        offset: draft.body.length,
      );
    }
    _draftReplyToId = draft.replyToMessageId;
  }

  void _onComposerChanged() {
    _scheduleDraftSave();

    if (_requestPreviewMode) return;
    final hasText = _textController.text.trim().isNotEmpty;

    if (hasText && !_typingPublished) {
      _typingPublished = true;
      unawaited(_chatRepository.setTyping(widget.chatId, true));
    }

    _typingDebounce?.cancel();
    if (hasText) {
      _typingDebounce = Timer(const Duration(seconds: 3), _stopTyping);
    } else {
      _stopTyping();
    }
  }

  void _stopTyping({bool publish = true}) {
    _typingDebounce?.cancel();
    if (!_typingPublished) return;
    _typingPublished = false;

    if (publish) {
      unawaited(_chatRepository.setTyping(widget.chatId, false));
    }
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    final body = _textController.text;
    final replyId = _replyingTo?.id ?? _draftReplyToId;

    _draftDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      if (body.trim().isEmpty && replyId == null) {
        await _chatRepository.deleteDraft(widget.chatId);
      } else {
        await _chatRepository.saveDraftState(
          widget.chatId,
          ChatDraft(body: body, replyToMessageId: replyId),
        );
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final scrolledUp = _scrollController.offset > 120;
    if (scrolledUp != _isScrolledUp) {
      setState(() {
        _isScrolledUp = scrolledUp;
        if (!scrolledUp) _newMessagesWhileScrolledUp = 0;
      });
      if (!scrolledUp) _checkAndMarkVisibleRead();
    }

    // List is reverse:true, so maxScrollExtent is the oldest edge.
    if (_hasMoreOlder &&
        !_isLoadingOlder &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 180) {
      unawaited(_loadOlder());
    }
  }

  Future<void> _loadOlder() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;
    setState(() => _isLoadingOlder = true);

    final result =
        await ref
            .read(messageThreadProvider(widget.chatId).notifier)
            .loadOlder();

    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (count) {
        if (count < 50) _hasMoreOlder = false;
      },
    );
    setState(() => _isLoadingOlder = false);
  }

  void _checkAndMarkVisibleRead([List<ChatMessage>? current]) {
    if (!mounted || _requestPreviewMode) return;
    if (_lifecycle != AppLifecycleState.resumed) return;
    if (_route == null || !_route!.isCurrent || _isScrolledUp) return;

    final messages =
        current ?? ref.read(messageThreadProvider(widget.chatId)).value;
    if (messages == null || messages.isEmpty) return;

    int? highest;
    for (final message in messages) {
      final seq = message.messageSeq;
      if (seq != null && seq > 0 && (highest == null || seq > highest)) {
        highest = seq;
      }
    }

    if (highest != null &&
        (_lastMarkedReadSeq == null || highest > _lastMarkedReadSeq!)) {
      _lastMarkedReadSeq = highest;
      unawaited(
        ref
            .read(messageThreadProvider(widget.chatId).notifier)
            .markRead(throughSeq: highest),
      );
    }
  }

  Future<void> _sendText() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _composerError = null;
    });
    _stopTyping();

    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .send(body, replyToId: _replyingTo?.id);

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _composerError = failure.message;
        _sending = false;
      }),
      (_) {
        // Explicit deletion prevents a delayed TextEditingController clear()
        // debounce from resurrecting a stale draft.
        unawaited(_chatRepository.deleteDraft(widget.chatId));
        _draftDebounce?.cancel();
        _textController.clear();
        setState(() {
          _sending = false;
          _replyingTo = null;
          _draftReplyToId = null;
        });
        _scrollToBottom();
      },
    );
  }

  Future<void> _sendImage() async {
    if (_sending) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _sending = true;
      _composerError = null;
    });

    final extension =
        picked.name.contains('.')
            ? picked.name.split('.').last.toLowerCase()
            : 'jpg';
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .sendImage(
          imageBytes: bytes,
          extension: extension,
          caption:
              _textController.text.trim().isEmpty
                  ? null
                  : _textController.text.trim(),
          replyToId: _replyingTo?.id,
        );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _sending = false;
        _composerError = failure.message;
      }),
      (_) {
        unawaited(_chatRepository.deleteDraft(widget.chatId));
        _draftDebounce?.cancel();
        _textController.clear();
        setState(() {
          _sending = false;
          _replyingTo = null;
          _draftReplyToId = null;
        });
        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _delete(ChatMessage message) async {
    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .deleteMessage(message.id);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => setState(() => _selectedMessage = null),
    );
  }

  Future<void> _retry(ChatMessage message) async {
    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .retryMessage(message.id);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {},
    );
  }

  Future<void> _edit(ChatMessage message) async {
    final controller = TextEditingController(text: message.body ?? '');
    final value = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Edit message'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();

    if (!mounted) return;
    if (value == null || value.trim() == (message.body ?? '').trim()) return;
    final result = await ref
        .read(messageThreadProvider(widget.chatId).notifier)
        .editMessage(message, value);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => setState(() => _selectedMessage = null),
    );
  }

  Future<void> _toggleReaction(ChatMessage message, String emoji) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final selected = message.reactions.any(
      (reaction) =>
          reaction.userId == currentUserId &&
          reaction.reaction == emoji &&
          !reaction.isRemoved,
    );
    await _chatRepository.setReaction(message.id, emoji, !selected);
  }

  Future<void> _acceptRequest() async {
    final result =
        await ref
            .read(messageThreadProvider(widget.chatId).notifier)
            .acceptRequest();
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        // LocalChannelMembers is already updated optimistically and the
        // repository upgrades Presence on the existing Ably attachment.
        // Do NOT invalidate messageThreadProvider here: invalidation disposes
        // the thread controller, closes the channel, and recreates it.
      },
    );
  }

  Future<void> _declineRequest() async {
    final result =
        await ref
            .read(messageThreadProvider(widget.chatId).notifier)
            .declineRequest();
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(myChatChannelsProvider).value;
    final channel = _channelFrom(channels);
    final messagesAsync = ref.watch(messageThreadProvider(widget.chatId));
    final syncState = ref.watch(chatSyncStateProvider(widget.chatId)).value;
    final participants =
        ref.watch(chatParticipantsProvider(widget.chatId)).value ?? const [];
    final typingUsers =
        ref.watch(chatTypingUsersProvider(widget.chatId)).value ?? const {};

    final incomingRequest = channel?.isRequest == true;
    final outgoingRequest = channel?.isPendingOutgoingRequest == true;
    _requestPreviewMode = incomingRequest;

    if (!_capturedInitialReadHorizon && channel != null) {
      _capturedInitialReadHorizon = true;
      _initialLastReadSeq = channel.lastReadMessageSeq;
    }

    ref.listen<AsyncValue<List<ChatMessage>>>(
      messageThreadProvider(widget.chatId),
      (previous, next) {
        final current = next.value;
        if (current == null) return;

        if (_replyingTo == null && _draftReplyToId != null) {
          final target =
              current
                  .where((message) => message.id == _draftReplyToId)
                  .firstOrNull;
          if (target != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _replyingTo = target;
                _draftReplyToId = null;
              });
            });
          }
        }

        final old = previous?.value ?? const <ChatMessage>[];
        if (old.isNotEmpty) {
          final count = countNewIncomingMessages(
            previous: old,
            current: current,
          );
          if (count > 0) {
            if (_isScrolledUp) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _newMessagesWhileScrolledUp += count);
                }
              });
            } else {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _checkAndMarkVisibleRead(current),
              );
            }
          }
        } else if (!_isScrolledUp) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _checkAndMarkVisibleRead(current),
          );
        }
      },
    );

    final typingLabel = _typingLabel(typingUsers, participants);

    return Scaffold(
      backgroundColor: ChatTheme.clubhouseCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ThreadHeader(
              channel: channel,
              chatId: widget.chatId,
              typingLabel: typingLabel,
              onBack: () => context.pop(),
              onDetails:
                  () => context.push('/messages/${widget.chatId}/details'),
            ),
            if (incomingRequest)
              _RequestBanner(
                onAccept: _acceptRequest,
                onDecline: _declineRequest,
              ),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty &&
                      (syncState == null || syncState.isInitialLoading)) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ChatTheme.matchDayCoral,
                      ),
                    );
                  }
                  if (messages.isEmpty) {
                    return const _EmptyThread();
                  }

                  return Stack(
                    children: [
                      _Timeline(
                        messages: messages,
                        initialLastReadSeq: _initialLastReadSeq,
                        isMultiParticipant:
                            channel?.isMultiParticipant ?? false,
                        selectedMessage: _selectedMessage,
                        scrollController: _scrollController,
                        loadingOlder: _isLoadingOlder,
                        onReply: (message) {
                          setState(() {
                            _replyingTo = message;
                            _draftReplyToId = null;
                            _selectedMessage = null;
                          });
                          _scheduleDraftSave();
                          _composerFocus.requestFocus();
                        },
                        onSelect:
                            (message) => setState(() {
                              _selectedMessage =
                                  _selectedMessage?.id == message.id
                                      ? null
                                      : message;
                            }),
                        onDelete: _delete,
                        onRetry: _retry,
                        onReaction: _toggleReaction,
                      ),
                      if (_newMessagesWhileScrolledUp > 0)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              setState(() => _newMessagesWhileScrolledUp = 0);
                              _scrollToBottom();
                            },
                            icon: const Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                            ),
                            label: Text('$_newMessagesWhileScrolledUp new'),
                          ),
                        ),
                    ],
                  );
                },
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ChatTheme.matchDayCoral,
                      ),
                    ),
                error:
                    (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load this chat.\n$error',
                          textAlign: TextAlign.center,
                          style: ChatTheme.bodyMd(color: ChatTheme.mutedStone),
                        ),
                      ),
                    ),
              ),
            ),
            if (_selectedMessage != null)
              _SelectionBar(
                message: _selectedMessage!,
                onClose: () => setState(() => _selectedMessage = null),
                onReply: () {
                  final message = _selectedMessage!;
                  setState(() {
                    _replyingTo = message;
                    _selectedMessage = null;
                  });
                  _scheduleDraftSave();
                  _composerFocus.requestFocus();
                },
                onEdit:
                    _selectedMessage!.fromMe &&
                            !_selectedMessage!.isDeleted &&
                            !_selectedMessage!.isImage
                        ? () => _edit(_selectedMessage!)
                        : null,
                onDelete:
                    _selectedMessage!.fromMe
                        ? () => _delete(_selectedMessage!)
                        : null,
              )
            else
              ChatComposer(
                controller: _textController,
                focusNode: _composerFocus,
                replyingTo: _replyingTo,
                enabled: !incomingRequest && !outgoingRequest,
                sending: _sending,
                placeholder:
                    outgoingRequest
                        ? 'Waiting for them to accept…'
                        : incomingRequest
                        ? 'Accept the request to reply'
                        : channel?.isMultiParticipant == true
                        ? 'Message group...'
                        : 'Message ${channel?.displayName ?? 'user'}...',
                errorText: _composerError,
                onSend: _sendText,
                onImagePressed: _sendImage,
                onCancelReply: () {
                  setState(() {
                    _replyingTo = null;
                    _draftReplyToId = null;
                  });
                  _scheduleDraftSave();
                },
              ),
          ],
        ),
      ),
    );
  }

  String? _typingLabel(
    Set<String> typingUsers,
    List<ChatParticipant> participants,
  ) {
    if (typingUsers.isEmpty) return null;
    final byId = {for (final person in participants) person.userId: person};
    final names =
        typingUsers.map((id) => byId[id]?.displayName ?? 'Someone').toList();
    if (names.length == 1) return '${names.first} is typing…';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing…';
    return '${names.length} people are typing…';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushMessagingService.setActiveChat(null);
    _stopTyping(publish: false);

    _draftDebounce?.cancel();
    final body = _textController.text;
    final replyId = _replyingTo?.id ?? _draftReplyToId;
    if (body.trim().isNotEmpty || replyId != null) {
      unawaited(
        _chatRepository.saveDraftState(
          widget.chatId,
          ChatDraft(body: body, replyToMessageId: replyId),
        ),
      );
    }

    _typingDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }
}

class _ThreadHeader extends ConsumerWidget {
  const _ThreadHeader({
    required this.channel,
    required this.chatId,
    required this.typingLabel,
    required this.onBack,
    required this.onDetails,
  });

  final ChatChannel? channel;
  final String chatId;
  final String? typingLabel;
  final VoidCallback onBack;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var online = false;
    if (channel?.isDm == true && channel?.dmOtherUserId != null) {
      online =
          ref
              .watch(
                isUserOnlineInChatProvider(
                  chatId: chatId,
                  userId: channel!.dmOtherUserId!,
                ),
              )
              .value ??
          false;
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          ChatAvatar(
            label: channel?.displayName ?? 'Chat',
            imageUrl: channel?.displayAvatarUrl,
            size: 38,
            online: channel?.isDm == true && online,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel?.displayName ?? 'Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChatTheme.rowTitle(),
                ),
                if (typingLabel != null)
                  Text(
                    typingLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatTheme.metadata(color: ChatTheme.matchDayCoral),
                  )
                else if (channel?.isDm == true)
                  Text(
                    online ? 'Online' : 'Offline',
                    style: ChatTheme.metadata(),
                  )
                else
                  Text(switch (channel?.contextType) {
                    ChatChannelContext.team => 'Team chat',
                    ChatChannelContext.match => 'Match room',
                    ChatChannelContext.tournament => 'Tournament chat',
                    ChatChannelContext.club => 'Club chat',
                    _ => 'Group chat',
                  }, style: ChatTheme.metadata()),
              ],
            ),
          ),
          IconButton(
            onPressed: onDetails,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.messages,
    required this.initialLastReadSeq,
    required this.isMultiParticipant,
    required this.selectedMessage,
    required this.scrollController,
    required this.loadingOlder,
    required this.onReply,
    required this.onSelect,
    required this.onDelete,
    required this.onRetry,
    required this.onReaction,
  });

  final List<ChatMessage> messages;
  final int? initialLastReadSeq;
  final bool isMultiParticipant;
  final ChatMessage? selectedMessage;
  final ScrollController scrollController;
  final bool loadingOlder;
  final ValueChanged<ChatMessage> onReply;
  final ValueChanged<ChatMessage> onSelect;
  final ValueChanged<ChatMessage> onDelete;
  final ValueChanged<ChatMessage> onRetry;
  final void Function(ChatMessage, String) onReaction;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final unreadIndex = firstUnreadMessageIndex(
      messages: messages,
      lastReadMessageSeq: initialLastReadSeq,
    );

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final previous = i == 0 ? null : messages[i - 1];

      if (i == 0 ||
          isDifferentCalendarDay(previous!.createdAt, message.createdAt)) {
        widgets.add(_DayDivider(date: message.createdAt));
      }
      if (i == unreadIndex) widgets.add(const _UnreadDivider());

      widgets.add(
        ChatBubble(
          key: ValueKey(message.id),
          message: message,
          isMultiParticipant: isMultiParticipant,
          showSender: startsNewSenderCluster(
            previous: previous,
            current: message,
          ),
          isSelected: selectedMessage?.id == message.id,
          onReply: onReply,
          onSelect: onSelect,
          onDelete: onDelete,
          onRetry: onRetry,
          onReactionSelected: onReaction,
        ),
      );
    }

    if (loadingOlder) {
      widgets.insert(
        0,
        const Padding(
          padding: EdgeInsets.all(14),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ChatTheme.matchDayCoral,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      itemCount: widgets.length,
      itemBuilder: (_, index) => widgets[widgets.length - 1 - index],
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final label =
        day == today
            ? 'Today'
            : day == today.subtract(const Duration(days: 1))
            ? 'Yesterday'
            : DateFormat('MMM d, y').format(local);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: Text(label, style: ChatTheme.timestamp())),
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(child: Divider(color: ChatTheme.matchDayCoral)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'NEW MESSAGES',
            style: TextStyle(
              color: ChatTheme.matchDayCoral,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: ChatTheme.matchDayCoral)),
      ],
    ),
  );
}

class _RequestBanner extends StatelessWidget {
  const _RequestBanner({required this.onAccept, required this.onDecline});
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    color: ChatTheme.warningSandBg,
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Message request. Reading this preview does not send a normal read receipt.',
            style: ChatTheme.bodySm(color: ChatTheme.warningSandText),
          ),
        ),
        TextButton(onPressed: onDecline, child: const Text('Decline')),
        const SizedBox(width: 4),
        FilledButton(onPressed: onAccept, child: const Text('Accept')),
      ],
    ),
  );
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.message,
    required this.onClose,
    required this.onReply,
    this.onEdit,
    this.onDelete,
  });

  final ChatMessage message;
  final VoidCallback onClose;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 60,
      decoration: const BoxDecoration(
        color: ChatTheme.pureSurface,
        border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          const Spacer(),
          IconButton(
            onPressed: onReply,
            tooltip: 'Reply',
            icon: const Icon(Icons.reply_rounded),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: ChatTheme.destructiveCoralText,
              ),
            ),
        ],
      ),
    ),
  );
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'No messages yet.\nStart the conversation.',
        textAlign: TextAlign.center,
        style: ChatTheme.bodyMd(color: ChatTheme.mutedStone),
      ),
    ),
  );
}
