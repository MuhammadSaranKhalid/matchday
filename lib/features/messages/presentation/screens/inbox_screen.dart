import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:matchday/core/error/failures.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/core/widgets/v2/v2_kit.dart';
import 'package:matchday/features/messages/domain/entities/chat.dart';
import 'package:matchday/features/messages/presentation/providers/messages_providers.dart';
import 'package:matchday/features/messages/presentation/widgets/color_utils.dart';

/// Inbox tabs: All / Teams / DMs.
enum _InboxTab { all, teams, dms }

/// Inbox tab bar display flag.
const bool _kShowInboxTabs = true;



class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.onBell});

  final VoidCallback? onBell;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  _InboxTab _tab = _InboxTab.all;

  /// Cold-start refresh affordance. Time-bounded visual hint, NOT a
  /// strict "fetch is in flight" signal:
  ///
  ///   • Network faster than the 2-second timeout (common) → chip lingers
  ///     a beat after the data has actually painted. Mild but harmless.
  ///   • Network slower than the timeout (slow connection) → chip
  ///     DISAPPEARS while the refresh is still in flight. Trade-off
  ///     accepted: a stuck-looking spinner is worse than a brief one that
  ///     stops early. The cache renders immediately regardless.
  ///
  /// A precise version would `ref.listen(myChatsProvider, ...)` and clear
  /// on the second emission, but the time-bounded version is intentional
  /// for v1 — re-evaluate if real-user data shows the trade-off bites.
  bool _refreshing = true;
  Timer? _refreshTimeout;

  @override
  void initState() {
    super.initState();
    _refreshTimeout = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _refreshing = false);
    });
  }

  @override
  void dispose() {
    _refreshTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(myChatsProvider);
    // Show the chip only while we already have something to show AND the
    // timeout hasn't elapsed; never on top of the initial loading skeleton.
    final showRefreshChip = _refreshing && chatsAsync.hasValue;
    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: switch (chatsAsync) {
          AsyncData(:final value) => _Loaded(
              chats: value,
              tab: _tab,
              onTabChanged: (t) => setState(() => _tab = t),
              onBell: widget.onBell,
              refreshing: showRefreshChip,
            ),
          AsyncError(:final error) => _ErrorView(
              title: 'Messages',
              onBell: widget.onBell,
              message: _messageFor(error),
              onRetry: () => ref.invalidate(myChatsProvider),
            ),
          _ => _Skeleton(
              title: 'Messages',
              onBell: widget.onBell,
              tab: _tab,
              onTabChanged: (t) => setState(() => _tab = t),
            ),
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
    required this.tab,
    required this.onTabChanged,
    required this.onBell,
    this.refreshing = false,
  });

  final List<Chat> chats;
  final _InboxTab tab;
  final ValueChanged<_InboxTab> onTabChanged;
  final VoidCallback? onBell;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    // Tab filtering only kicks in when the tab row is visible. With it
    // hidden (`_kShowInboxTabs = false`), the inbox surfaces every chat
    // regardless of `tab`.
    final List<Chat> visible;
    final int teamsCount;
    final int dmsCount;
    if (_kShowInboxTabs) {
      final teamChats =
          chats.where((c) => c.kind == ChatKind.team).toList();
      final dmChats =
          chats.where((c) => c.kind == ChatKind.dm).toList();
      visible = switch (tab) {
        _InboxTab.all => chats,
        _InboxTab.teams => teamChats,
        _InboxTab.dms => dmChats,
      };
      teamsCount = teamChats.length;
      dmsCount = dmChats.length;
    } else {
      visible = chats;
      teamsCount = 0;
      dmsCount = 0;
    }

    return Column(
      children: [
        V2Header(
          title: 'Messages',
          onBell: onBell,
          refreshing: refreshing,
        ),
        if (_kShowInboxTabs)
          _TabRow(
            tab: tab,
            onChanged: onTabChanged,
            allCount: chats.length,
            teamsCount: teamsCount,
            dmsCount: dmsCount,
          ),
        Expanded(
          child: visible.isEmpty
              ? const _EmptyList()
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: visible.length,
                  itemBuilder: (context, i) => _ThreadRow(
                    chat: visible[i],
                    onOpen: () =>
                        context.go('/messages/${visible[i].id.value}'),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Tab row + chips ─────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tab,
    required this.onChanged,
    required this.allCount,
    required this.teamsCount,
    required this.dmsCount,
  });

  final _InboxTab tab;
  final ValueChanged<_InboxTab> onChanged;
  final int allCount;
  final int teamsCount;
  final int dmsCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        children: [
          _MTab(
            label: 'All',
            count: allCount,
            active: tab == _InboxTab.all,
            onTap: () => onChanged(_InboxTab.all),
          ),
          const SizedBox(width: 6),
          _MTab(
            label: 'Teams',
            count: teamsCount,
            active: tab == _InboxTab.teams,
            onTap: () => onChanged(_InboxTab.teams),
          ),
          const SizedBox(width: 6),
          _MTab(
            label: 'DMs',
            count: dmsCount,
            active: tab == _InboxTab.dms,
            onTap: () => onChanged(_InboxTab.dms),
          ),
        ],
      ),
    );
  }
}

class _MTab extends StatelessWidget {
  const _MTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? CkColors.paper : CkColors.ink2;
    final base = CkType.mono(
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.10,
      color: fg,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text.rich(
          TextSpan(
            style: base,
            children: [
              TextSpan(text: label.toUpperCase()),
              TextSpan(
                text: ' · $count',
                style: base.copyWith(
                  fontWeight: FontWeight.w500,
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Row ─────────────────────────────────────────────────────────────────────

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.chat, required this.onOpen});

  final Chat chat;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount > 0;
    final mono = chat.displayMonogram;
    final color = parseHexColor(chat.teamPrimaryColorHex, CkColors.ink);
    final time = chat.lastMessageAt == null
        ? ''
        : timeago.format(chat.lastMessageAt!, locale: 'en_short');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.kind == ChatKind.team)
              Crest(short: mono, color: color, size: 42, radius: 11)
            else if (chat.displayAvatarUrl.isNotEmpty)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: chat.displayAvatarUrl,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Avatar(mono: mono, size: 42, tone: AvatarTone.ink),
                  errorWidget: (_, __, ___) =>
                      Avatar(mono: mono, size: 42, tone: AvatarTone.ink),
                ),
              )
            else
              Avatar(mono: mono, size: 42, tone: AvatarTone.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          chat.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 6),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: CkType.mono(
                            fontSize: 9,
                            color: unread ? CkColors.red : CkColors.muted,
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text.rich(
                      _previewSpan(chat, unread: unread),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  // The `list-my-chats` edge fn caps its unread count at 100
                  // (LIMIT 100 in the inner subquery — bounded scan even for
                  // heavy chats with thousands of unread). Render the cap as
                  // "99+" so the badge isn't misread as an exact count
                  // (ticket #37).
                  chat.unreadCount >= 100 ? '99+' : '${chat.unreadCount}',
                  style: CkType.display(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextSpan _previewSpan(Chat c, {required bool unread}) {
    final isEmpty = c.lastMessagePreview == null || c.lastMessagePreview!.isEmpty;
    final base = CkType.body(
      fontSize: 12.5,
      height: 1.4,
      color: unread ? CkColors.ink : CkColors.muted,
      fontWeight: FontWeight.w400,
    ).copyWith(
      fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
    );
    if (isEmpty) {
      return TextSpan(text: 'No messages yet', style: base);
    }
    if (c.lastMessageFromMe) {
      return TextSpan(
        style: base,
        children: [
          TextSpan(
            text: 'You:',
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' ${c.lastMessagePreview}'),
        ],
      );
    }
    return TextSpan(text: c.lastMessagePreview, style: base);
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton({
    required this.title,
    required this.onBell,
    required this.tab,
    required this.onTabChanged,
  });

  final String title;
  final VoidCallback? onBell;
  final _InboxTab tab;
  final ValueChanged<_InboxTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        V2Header(title: title, onBell: onBell),
        if (_kShowInboxTabs)
          _TabRow(
            tab: tab,
            onChanged: onTabChanged,
            allCount: 0,
            teamsCount: 0,
            dmsCount: 0,
          ),
        const Expanded(
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'No chats yet.\nJoin a team and a chat will appear here.',
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.title,
    required this.onBell,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final VoidCallback? onBell;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        V2Header(title: title, sub: 'something went wrong', onBell: onBell),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: CkType.body(
                      fontSize: 13,
                      color: CkColors.ink,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

