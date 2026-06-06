import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_kit.dart';
import 'package:novex_clean_arch/features/messages/domain/entities/chat.dart';
import 'package:novex_clean_arch/features/messages/presentation/providers/messages_providers.dart';

/// V1 inbox tabs. The schema only has team chats — DMs is permanently 0
/// until `chat_type` grows a `'dm'` value (tracked in ticket #7's follow-ups).
enum _InboxTab { all, teams, dms }

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key, this.onBell});

  final VoidCallback? onBell;

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _InboxTab _tab = _InboxTab.all;

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(myChatsProvider);
    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: chatsAsync.when(
          loading: () => _Skeleton(
            title: 'Messages',
            onBell: widget.onBell,
            tab: _tab,
            onTabChanged: (t) => setState(() => _tab = t),
          ),
          error: (e, _) => _ErrorView(
            title: 'Messages',
            onBell: widget.onBell,
            message: _messageFor(e),
            onRetry: () => ref.invalidate(myChatsProvider),
          ),
          data: (chats) => _Loaded(
            chats: chats,
            tab: _tab,
            onTabChanged: (t) => setState(() => _tab = t),
            onBell: widget.onBell,
          ),
        ),
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
  });

  final List<Chat> chats;
  final _InboxTab tab;
  final ValueChanged<_InboxTab> onTabChanged;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    final teamChats = chats.where((c) => c.kind == ChatKind.team).toList();
    final dmChats = const <Chat>[]; // v1: no DMs in schema yet
    final visible = switch (tab) {
      _InboxTab.all => chats,
      _InboxTab.teams => teamChats,
      _InboxTab.dms => dmChats,
    };
    final activeCount = chats.where((c) => !c.isEmpty).length;
    final unreadCount = chats.fold<int>(0, (a, c) => a + c.unreadCount);

    return Column(
      children: [
        V2Header(
          title: 'Messages',
          sub: '$activeCount active · $unreadCount unread',
          onBell: onBell,
        ),
        _TabRow(
          tab: tab,
          onChanged: onTabChanged,
          allCount: chats.length,
          teamsCount: teamChats.length,
          dmsCount: dmChats.length,
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
    final mono = chat.teamLogoMonogram?.toUpperCase() ?? _deriveMono(chat.name);
    final color = _parseHexColor(chat.teamPrimaryColorHex, CkColors.ink);
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
                          chat.name,
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
                  '${chat.unreadCount}',
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
        V2Header(title: title, sub: '…', onBell: onBell),
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Hex string ("#RRGGBB", "RRGGBB", "RRGGBBAA") → Color, with [fallback]
/// returned for any null/empty/malformed input. The teams schema stores
/// `team_colors->>'primary'` as a free-text hex so input is untrusted.
Color _parseHexColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return fallback;
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(v);
}

/// Derive a 1–2 letter monogram from a team name when `logo_monogram` is
/// null. Mirrors the "AB" convention used elsewhere in the kit: first letter
/// of the first word + first letter of the last word (or first two letters
/// for single-word names).
String _deriveMono(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return '?';
  final parts = clean.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    final w = parts[0];
    return w.substring(0, w.length.clamp(1, 2)).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
