import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../providers/messages_providers.dart';

/// Modal bottom sheet to search players and start a new direct message conversation.
class NewMessageSheet extends ConsumerStatefulWidget {
  const NewMessageSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewMessageSheet(),
    );
  }

  @override
  ConsumerState<NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends ConsumerState<NewMessageSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _loading = false;
  String _query = '';
  List<_PlayerSearchResult> _results = [];
  String? _startingChatWithUserId;

  @override
  void initState() {
    super.initState();
    _fetchSuggestedPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSuggestedPlayers([String query = '']) async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      var req = supabase
          .from('profiles')
          .select('user_id, display_name, username, profile_photo_url, is_verified');


      if (query.trim().isNotEmpty) {
        final q = query.trim().replaceAll('@', '');
        req = req.or('display_name.ilike.%$q%,username.ilike.%$q%');
      }

      final data = await req.limit(20);
      if (mounted) {
        final rows = (data as List)
            .map((r) => _PlayerSearchResult.fromJson(Map<String, dynamic>.from(r as Map)))
            .where((p) => p.userId != currentUserId)
            .toList();
        setState(() {
          _results = rows;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _fetchSuggestedPlayers(value);
    });
  }

  Future<void> _startChatWith(_PlayerSearchResult player) async {
    if (_startingChatWithUserId != null) return;
    setState(() => _startingChatWithUserId = player.userId);

    try {
      final repo = ref.read(messagesRepositoryProvider);
      final res = await repo.getOrCreateDmChat(player.userId);
      if (!mounted) return;

      res.fold(
        (failure) {
          setState(() => _startingChatWithUserId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: CkColors.red,
            ),
          );
        },
        (chatId) {
          Navigator.of(context).pop();
          context.push('/messages/${chatId.value}');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _startingChatWithUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: CkColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CkColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Message',
                  style: CkType.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const V2Svg(
                    V2Icons.close,
                    size: 18,
                    color: CkColors.ink,
                  ),
                ),
              ],
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CkColors.line.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  const V2Svg(
                    V2Icons.search,
                    size: 16,
                    color: CkColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      style: CkType.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CkColors.ink,
                      ),
                      cursorColor: CkColors.ink,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search player name or @username...',
                        hintStyle: CkType.body(
                          fontSize: 13.5,
                          color: CkColors.muted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const V2Svg(
                        V2Icons.close,
                        size: 14,
                        color: CkColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: CkColors.hairline),
          // List of players
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No players found'
                              : 'No players match "$_query"',
                          style: CkType.body(
                            fontSize: 13.5,
                            color: CkColors.muted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 72,
                          color: CkColors.hairline,
                        ),
                        itemBuilder: (context, i) {
                          final p = _results[i];
                          final isStartingThis =
                              _startingChatWithUserId == p.userId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 4,
                            ),
                            leading: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: p.avatarUrl!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Avatar(
                                        mono: _mono(p.displayName),
                                        size: 44,
                                        tone: AvatarTone.ink,
                                      ),
                                      errorWidget: (_, __, ___) => Avatar(
                                        mono: _mono(p.displayName),
                                        size: 44,
                                        tone: AvatarTone.ink,
                                      ),
                                    ),
                                  )
                                : Avatar(
                                    mono: _mono(p.displayName),
                                    size: 44,
                                    tone: AvatarTone.ink,
                                  ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    p.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CkType.display(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: CkColors.ink,
                                    ),
                                  ),
                                ),
                                if (p.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: CkColors.amber,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '@${p.username}',
                              style: CkType.body(
                                fontSize: 12.5,
                                color: CkColors.muted,
                              ),
                            ),
                            trailing: isStartingThis
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const V2Svg(
                                    V2Icons.chevronRight,
                                    size: 18,
                                    color: CkColors.muted,
                                  ),
                            onTap: isStartingThis
                                ? null
                                : () => _startChatWith(p),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  static String _mono(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final w = parts[0];
      return w.substring(0, w.length.clamp(1, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _PlayerSearchResult {
  const _PlayerSearchResult({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory _PlayerSearchResult.fromJson(Map<String, dynamic> json) {
    return _PlayerSearchResult(
      userId: json['user_id'] as String,
      displayName: (json['display_name'] as String?) ?? 'Player',
      username: (json['username'] as String?) ?? '',
      avatarUrl: json['profile_photo_url'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
    );
  }

  final String userId;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isVerified;
}
