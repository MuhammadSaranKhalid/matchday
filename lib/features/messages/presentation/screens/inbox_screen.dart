import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../domain/entities/chat.dart';
import '../providers/messages_providers.dart';
import '../widgets/color_utils.dart';
import '../widgets/inbox_search_bar.dart';
import '../widgets/inbox_shimmer_skeleton.dart';
import '../widgets/new_message_sheet.dart';

/// Inbox tabs: All / Teams / DMs.
enum _InboxTab { all, teams, dms }

/// Inbox tab bar display flag.
const bool _kShowInboxTabs = true;

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.onBell, this.showBack = false});

  final VoidCallback? onBell;
  final bool showBack;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  _InboxTab _tab = _InboxTab.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(myChatsProvider);
    final showRefreshChip = _refreshing && chatsAsync.hasValue;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: switch (chatsAsync) {
          AsyncData(:final value) => _Loaded(
              chats: value,
              tab: _tab,
              onTabChanged: (t) => setState(() => _tab = t),
              onBell: widget.onBell,
              showBack: widget.showBack,
              refreshing: showRefreshChip,
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              onRefresh: () async {
                ref.invalidate(myChatsProvider);
                await ref.read(myChatsProvider.future);
              },
            ),
          AsyncError(:final error) => _ErrorView(
              title: 'Messages',
              onBell: widget.onBell,
              showBack: widget.showBack,
              message: _messageFor(error),
              onRetry: () => ref.invalidate(myChatsProvider),
            ),
          _ => _Skeleton(
              title: 'Messages',
              onBell: widget.onBell,
              showBack: widget.showBack,
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
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    this.refreshing = false,
    this.showBack = false,
  });

  final List<Chat> chats;
  final _InboxTab tab;
  final ValueChanged<_InboxTab> onTabChanged;
  final VoidCallback? onBell;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final bool refreshing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final teamChats = chats.where((c) => c.kind == ChatKind.team).toList();
    final dmChats = chats.where((c) => c.kind == ChatKind.dm).toList();

    final teamsHasUnread = teamChats.any((c) => c.unreadCount > 0);
    final dmsHasUnread = dmChats.any((c) => c.unreadCount > 0);

    // Tab filtering
    final List<Chat> tabFiltered = switch (tab) {
      _InboxTab.all => chats,
      _InboxTab.teams => teamChats,
      _InboxTab.dms => dmChats,
    };

    // Search query filtering
    final cleanQuery = searchQuery.trim().toLowerCase();
    final List<Chat> visible = cleanQuery.isEmpty
        ? tabFiltered
        : tabFiltered.where((c) {
            final nameMatch = c.displayName.toLowerCase().contains(cleanQuery);
            final usernameMatch =
                (c.dmOtherUserUsername ?? '').toLowerCase().contains(cleanQuery);
            final msgMatch =
                (c.lastMessagePreview ?? '').toLowerCase().contains(cleanQuery);
            return nameMatch || usernameMatch || msgMatch;
          }).toList();

    return Column(
      children: [
        V2Header(
          title: 'Messages',
          onBell: onBell,
          refreshing: refreshing,
          showMessages: false,
          showBack: showBack,
        ),
        InboxSearchBar(
          controller: searchController,
          onChanged: onSearchChanged,
          onClear: () => onSearchChanged(''),
        ),
        if (_kShowInboxTabs)
          _TabRow(
            tab: tab,
            onChanged: onTabChanged,
            allCount: chats.length,
            teamsCount: teamChats.length,
            dmsCount: dmChats.length,
            teamsHasUnread: teamsHasUnread,
            dmsHasUnread: dmsHasUnread,
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: CkColors.ink,
            backgroundColor: CkColors.paper,
            child: visible.isEmpty
                ? _EmptyList(
                    tab: tab,
                    isSearching: cleanQuery.isNotEmpty,
                    query: cleanQuery,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 78,
                      color: CkColors.hairline,
                    ),
                    itemBuilder: (context, i) => _ThreadRow(
                      chat: visible[i],
                      onOpen: () =>
                          context.push('/messages/${visible[i].id.value}'),
                    ),
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
    this.teamsHasUnread = false,
    this.dmsHasUnread = false,
  });

  final _InboxTab tab;
  final ValueChanged<_InboxTab> onChanged;
  final int allCount;
  final int teamsCount;
  final int dmsCount;
  final bool teamsHasUnread;
  final bool dmsHasUnread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Row(
        children: [
          _MTab(
            label: 'All',
            count: allCount,
            active: tab == _InboxTab.all,
            onTap: () => onChanged(_InboxTab.all),
          ),
          const SizedBox(width: 8),
          _MTab(
            label: 'Teams',
            count: teamsCount,
            hasUnreadPip: teamsHasUnread,
            active: tab == _InboxTab.teams,
            onTap: () => onChanged(_InboxTab.teams),
          ),
          const SizedBox(width: 8),
          _MTab(
            label: 'DMs',
            count: dmsCount,
            hasUnreadPip: dmsHasUnread,
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
    this.hasUnreadPip = false,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  final bool hasUnreadPip;

  @override
  Widget build(BuildContext context) {
    final fg = active ? CkColors.paper : CkColors.ink;
    final base = CkType.mono(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
      color: fg,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? CkColors.ink : CkColors.line.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                style: base,
                children: [
                  TextSpan(text: label.toUpperCase()),
                  TextSpan(
                    text: ' · $count',
                    style: base.copyWith(
                      fontWeight: FontWeight.w500,
                      color: fg.withValues(alpha: active ? 0.7 : 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (hasUnreadPip && !active) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: CkColors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
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

    return Material(
      color: CkColors.paper,
      child: InkWell(
        onTap: onOpen,
        splashColor: CkColors.ink.withValues(alpha: 0.05),
        highlightColor: CkColors.ink.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar or Crest
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (chat.kind == ChatKind.team)
                    Crest(short: mono, color: color, size: 48, radius: 14)
                  else if (chat.displayAvatarUrl.isNotEmpty)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: chat.displayAvatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Avatar(mono: mono, size: 48, tone: AvatarTone.ink),
                        errorWidget: (_, __, ___) =>
                            Avatar(mono: mono, size: 48, tone: AvatarTone.ink),
                      ),
                    )
                  else
                    Avatar(mono: mono, size: 48, tone: AvatarTone.ink),
                  // Small team pip badge on DM or vice-versa
                  if (chat.isTeam)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: CkColors.paper,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: CkColors.ink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.groups,
                            size: 10,
                            color: CkColors.paper,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Thread info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chat.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.display(
                              fontSize: 14.5,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: -0.01,
                              color: CkColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: CkType.mono(
                              fontSize: 9.5,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w400,
                              color: unread ? CkColors.red : CkColors.muted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            _previewSpan(chat, unread: unread),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 19),
                            height: 19,
                            padding: const EdgeInsets.symmetric(horizontal: 5.5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CkColors.red,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              chat.unreadCount >= 100
                                  ? '99+'
                                  : '${chat.unreadCount}',
                              style: CkType.display(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: CkColors.paper,
                              ),
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

  TextSpan _previewSpan(Chat c, {required bool unread}) {
    final isEmpty =
        c.lastMessagePreview == null || c.lastMessagePreview!.isEmpty;
    final base = CkType.body(
      fontSize: 12.5,
      height: 1.35,
      color: unread ? CkColors.ink : CkColors.muted,
      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
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
            text: 'You: ',
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              color: unread ? CkColors.ink : CkColors.ink2,
            ),
          ),
          TextSpan(text: c.lastMessagePreview),
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
    this.showBack = false,
  });

  final String title;
  final VoidCallback? onBell;
  final _InboxTab tab;
  final ValueChanged<_InboxTab> onTabChanged;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        V2Header(
          title: title,
          onBell: onBell,
          showMessages: false,
          showBack: showBack,
        ),
        InboxSearchBar(
          controller: TextEditingController(),
          onChanged: (_) {},
        ),
        if (_kShowInboxTabs)
          _TabRow(
            tab: tab,
            onChanged: onTabChanged,
            allCount: 0,
            teamsCount: 0,
            dmsCount: 0,
          ),
        const Expanded(
          child: InboxShimmerSkeleton(),
        ),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.tab,
    this.isSearching = false,
    this.query = '',
  });

  final _InboxTab tab;
  final bool isSearching;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const V2Svg(
                V2Icons.search,
                size: 36,
                color: CkColors.muted,
              ),
              const SizedBox(height: 14),
              Text(
                'No conversations found',
                style: CkType.display(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No chats match "$query". Check for spelling or start a new message.',
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 13,
                  color: CkColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final (icon, title, desc, ctaLabel, VoidCallback cta) = switch (tab) {
      _InboxTab.teams => (
          V2Icons.pavilion,
          'No team chats yet',
          'Join or create a cricket team to coordinate matches and strategy.',
          'Discover Teams',
          () => context.go('/search'),
        ),
      _InboxTab.dms => (
          V2Icons.messages,
          'No direct messages yet',
          'Send a direct message to teammates, friends, and players.',
          'New Message',
          () => NewMessageSheet.show(context),
        ),
      _InboxTab.all => (
          V2Icons.messages,
          'Your Inbox is quiet',
          'Start a direct message or join a team chat to start messaging.',
          'Start a Conversation',
          () => NewMessageSheet.show(context),
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.line),
              ),
              child: V2Svg(
                icon,
                size: 28,
                color: CkColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: CkType.display(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: CkColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cta,
              style: ElevatedButton.styleFrom(
                backgroundColor: CkColors.ink,
                foregroundColor: CkColors.paper,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                ctaLabel,
                style: CkType.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
            ),
          ],
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
    this.showBack = false,
  });

  final String title;
  final VoidCallback? onBell;
  final String message;
  final VoidCallback onRetry;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        V2Header(
          title: title,
          sub: 'something went wrong',
          onBell: onBell,
          showMessages: false,
          showBack: showBack,
        ),
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
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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
