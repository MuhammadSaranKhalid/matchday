import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:matchday/core/error/failures.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/core/widgets/v2/v2_kit.dart';
import 'package:matchday/features/messages/domain/entities/chat.dart';
import 'package:matchday/features/messages/domain/entities/message.dart';
import 'package:matchday/features/messages/presentation/controllers/message_thread_controller.dart';
import 'package:matchday/features/messages/presentation/providers/messages_providers.dart';
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

  /// Trailing debounce for draft autosave — fired 250ms after the last
  /// keystroke. Trade-off: the last ~250ms of typing is at risk if the OS
  /// kills the app inside that window. Acceptable for v1; a draft loss is
  /// minor compared to the perf cost of writing per keystroke.
  Timer? _draftSaveDebounce;

  // ─── Pagination state (ticket #35) ──────────────────────────────────────
  // The data source owns authoritative `hasMore` (it knows whether the
  // initial page came back full); the widget mirrors it locally so the
  // scroll trigger can short-circuit without an unnecessary method call on
  // every itemBuilder callback. Worst case on a stale local flag is one
  // no-op call that the data source rejects immediately.
  bool _hasMoreOlder = true;
  bool _isLoadingOlder = false;

  @override
  void initState() {
    super.initState();
    // Stamp last_read_at once the controller is built. Post-frame so the
    // provider has had a chance to materialise.
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
    // Don't clobber input the user typed between initState returning and
    // this async resuming. Their fresh keystrokes always win over a
    // restored draft.
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

  /// Find this chat in the inbox so the header has a name + crest. Falls
  /// back to a generic header while the inbox is still loading.
  ///
  /// `.select` narrows the watch to a single chat — the thread only
  /// rebuilds when its own header fields change, not when ANY chat in the
  /// inbox emits (e.g. an unread tick in some other chat). Dart 3 `switch`
  /// pattern matching on `AsyncValue` matches the convention used in every
  /// other screen (CLAUDE.md §6.2).
  Chat? _findChat() {
    return ref.watch(myChatsProvider.select((async) {
      return switch (async) {
        AsyncData(:final value) =>
          value.where((c) => c.id.value == widget.chatId).firstOrNull,
        _ => null,
      };
    }));
  }

  /// Fire-and-forget load-older trigger. Re-entrancy guarded by
  /// `_isLoadingOlder`; end-of-thread guarded by `_hasMoreOlder`. Failures
  /// keep `_hasMoreOlder = true` so the next scroll attempt naturally
  /// retries — no inline error UI for v1 (a banner during back-scroll would
  /// be more disruptive than helpful).
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
        (_) {
          // Transient failure — leave hasMore true so the user can retry
          // by scrolling.
        },
        (count) {
          // Page size = 50 on the data source side; a smaller return means
          // we've reached the start of the thread.
          if (count < 50) _hasMoreOlder = false;
        },
      );
    });
  }

  Future<void> _send() async {
    final text = _textController.text;
    // UX shortcut — when the field is visually blank or a send is already
    // in flight, skip the controller call entirely. `MessageBody.create`
    // also rejects empty strings (the canonical validation lives there) —
    // this guard just keeps us from issuing a no-op network round-trip
    // and from racing two sends. Don't add a length check here; that
    // belongs in MessageBody so the rule stays in one place.
    if (text.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _composerError = null;
    });
    final result =
        await ref.read(messageThreadProvider(widget.chatId).notifier).send(text);
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
        });
        _composerFocus.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // In reverse: true mode the bottom is offset 0, not
            // maxScrollExtent.
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
    );
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
                        scroll: _scrollController,
                        isLoadingOlder: _isLoadingOlder,
                        hasMoreOlder: _hasMoreOlder,
                        onLoadOlder: _onLoadOlder,
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              },
            ),
            _Composer(
              textController: _textController,
              focusNode: _composerFocus,
              onSend: _send,
              sending: _sending,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: V2Svg(
                V2Icons.chevronLeft,
                size: 22,
                color: CkColors.ink,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (chat?.isTeam == true)
            Crest(short: mono, color: color, size: 32, radius: 8)
          else if (chat?.displayAvatarUrl.isNotEmpty == true)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: chat!.displayAvatarUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Avatar(mono: mono, size: 32, tone: AvatarTone.ink),
                errorWidget: (_, __, ___) =>
                    Avatar(mono: mono, size: 32, tone: AvatarTone.ink),
              ),
            )
          else
            Avatar(mono: mono, size: 32, tone: AvatarTone.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.01,
              ),
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
    required this.scroll,
    required this.isLoadingOlder,
    required this.hasMoreOlder,
    required this.onLoadOlder,
  });

  final List<Message> messages;
  final ScrollController scroll;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final VoidCallback onLoadOlder;

  /// How many items from the top (in reverse-scroll terms, the highest
  /// itemBuilder index) before we kick off a load-more. Tuned so the
  /// network round-trip overlaps with the user's continued scroll instead
  /// of stalling at the boundary.
  static const _loadOlderThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(messages);
    // `reverse: true` is the canonical chat-app trick: the scroll axis is
    // reversed, so scrollOffset 0 IS the bottom. The user lands on the
    // newest message in the very first paint — no post-frame jumpTo and
    // therefore no flash of the oldest message (ticket #33).
    //
    // We keep `items` in chronological order (oldest first) so the day-
    // divider logic stays simple, and translate the index at access time:
    // i=0 (rendered at the bottom) reads the LAST chronological item.
    //
    // The load-older spinner renders as a virtual item at `i ==
    // items.length` (highest index = topmost in reverse mode). We bump
    // itemCount by 1 when loading so the spinner has somewhere to render
    // (ticket #35).
    final itemCount = items.length + (isLoadingOlder ? 1 : 0);
    return ListView.builder(
      controller: scroll,
      reverse: true,
      padding: const EdgeInsets.all(14),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        // Top-of-list spinner — present only while a load is in flight.
        if (isLoadingOlder && i == items.length) {
          return const _LoadOlderSpinner();
        }
        // Fire load-older when itemBuilder approaches the top
        // (`items.length - _loadOlderThreshold`). `addPostFrameCallback`
        // defers the setState out of the build phase; the state flags in
        // `_onLoadOlder` already debounce repeat triggers.
        if (hasMoreOlder &&
            !isLoadingOlder &&
            i >= items.length - _loadOlderThreshold) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadOlder());
        }
        return items[items.length - 1 - i];
      },
    );
  }

  /// Group messages by date — a `_DayDivider` separates each group.
  List<Widget> _buildItems(List<Message> msgs) {
    final out = <Widget>[];
    DateTime? lastDay;
    for (final m in msgs) {
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (lastDay == null || day != lastDay) {
        out.add(_DayDivider(_formatDay(day)));
        out.add(const SizedBox(height: 10));
        lastDay = day;
      }
      out.add(_Bubble(m));
      out.add(const SizedBox(height: 10));
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.muted,
          ),
        ),
      ),
    );
  }
}

// ─── Bubble ──────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble(this.message);
  final Message message;

  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final me = message.fromMe;
    final isDeleted = message.isDeleted;
    final senderName = message.senderDisplayName ?? 'Deleted user';
    final time = _timeFmt.format(message.createdAt.toLocal()).toLowerCase();

    final bg = me ? CkColors.ink : CkColors.paper2;
    final fg = me ? CkColors.paper : CkColors.ink;

    final bodyStyle = CkType.body(
      fontSize: 13,
      height: 1.4,
      color: fg,
    ).copyWith(fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal);

    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Column(
          crossAxisAlignment:
              me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!me)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  senderName,
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                    color: CkColors.muted,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isDeleted ? 'Message deleted' : message.body,
                style: bodyStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                message.isEdited ? '$time · edited' : time,
                style: CkType.mono(fontSize: 8.5, color: CkColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Composer ────────────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.textController,
    required this.focusNode,
    required this.onSend,
    required this.sending,
    required this.error,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final Future<void> Function() onSend;
  final bool sending;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        MediaQuery.of(context).viewPadding.bottom + 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                error!,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.05,
                  color: CkColors.red,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: !sending,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(2000),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Message…',
                    hintStyle: CkType.body(fontSize: 13, color: CkColors.muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: CkColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: CkColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: CkColors.ink),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: CkType.body(fontSize: 13, color: CkColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: sending ? null : onSend,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: CkColors.ink,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: sending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CkColors.paper,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: CkColors.paper,
                            size: 18,
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

/// Top-of-list spinner shown while older messages are loading
/// (ticket #35). Small, centered, low visual weight — the user shouldn't
/// be distracted by a heavy banner during back-scroll.
class _LoadOlderSpinner extends StatelessWidget {
  const _LoadOlderSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: CkColors.muted,
          ),
        ),
      ),
    );
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'No messages yet.\nSay hi.',
          textAlign: TextAlign.center,
          style: CkType.body(
            fontSize: 13,
            color: CkColors.muted,
            height: 1.5,
          ),
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
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

