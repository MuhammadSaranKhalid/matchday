import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_kit.dart';
import 'package:novex_clean_arch/features/follows/domain/entities/follow_direction.dart';
import 'package:novex_clean_arch/features/follows/domain/entities/follow_list_entry.dart';
import 'package:novex_clean_arch/features/follows/presentation/controllers/follow_toggle_controller.dart';
import 'package:novex_clean_arch/features/follows/presentation/providers/follows_providers.dart';

/// Followers / Following list screen.
///
/// Design source: `matchday-challenge/followers-screen.jsx`. Pushed as a
/// full-screen route from the profile (root navigator). The user's screen
/// title is the profile being viewed; the back chevron returns to the
/// profile.
///
/// Search is client-side over the loaded list (v1). The two tabs each
/// fetch from the `list-follow-list` edge function via
/// [followListProvider]. The tri-state Follow / Follow back / Following
/// button per row routes through the shared [followToggleProvider] so the
/// optimistic toggle is the same machinery used by the team-page button
/// (#50).
class FollowersListScreen extends ConsumerStatefulWidget {
  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.profileName,
    required this.profileUsername,
    this.initialTab = FollowDirection.followers,
  });

  /// The profile whose followers / following we're viewing.
  final String userId;

  /// Header title (the profile's display name).
  final String profileName;

  /// Header sub-title (the profile's @handle).
  final String profileUsername;

  /// Which tab opens first.
  final FollowDirection initialTab;

  @override
  ConsumerState<FollowersListScreen> createState() =>
      _FollowersListScreenState();
}

class _FollowersListScreenState extends ConsumerState<FollowersListScreen> {
  late FollowDirection _tab = widget.initialTab;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _switchTab(FollowDirection next) {
    if (next == _tab) return;
    setState(() {
      _tab = next;
      // Clear search when switching tabs — the placeholder text differs and
      // a query carried across tabs reads as a bug, not a feature.
      _searchController.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(followCountsProvider(widget.userId));
    final listAsync = ref.watch(
      followListProvider(widget.userId, _tab.wire),
    );

    final followers = countsAsync.value?.followers ?? 0;
    final following = countsAsync.value?.following ?? 0;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              name: widget.profileName,
              username: widget.profileUsername,
              onBack: () => Navigator.of(context).pop(),
            ),
            _BigCountTabs(
              tab: _tab,
              followers: followers,
              following: following,
              onSelect: _switchTab,
            ),
            const _HeaderDivider(),
            _SearchBar(
              controller: _searchController,
              tab: _tab,
              onChanged: (q) => setState(() => _query = q.trim()),
            ),
            Expanded(child: _Body(listAsync: listAsync, query: _query)),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.username,
    required this.onBack,
  });

  final String name;
  final String username;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Row(
        children: [
          _BackButton(onTap: onBack),
          Expanded(
            child: Column(
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.04,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          // Right spacer of the same width as the back button so the title
          // stays centered.
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: V2Svg(
            V2Icons.chevronLeft,
            size: 20,
            color: CkColors.ink,
            strokeWidth: 2.2,
          ),
        ),
      ),
    );
  }
}

// ─── Big-count tabs ───────────────────────────────────────────────────────────

class _BigCountTabs extends StatelessWidget {
  const _BigCountTabs({
    required this.tab,
    required this.followers,
    required this.following,
    required this.onSelect,
  });

  final FollowDirection tab;
  final int followers;
  final int following;
  final ValueChanged<FollowDirection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          _Tab(
            value: followers,
            label: 'FOLLOWERS',
            active: tab == FollowDirection.followers,
            onTap: () => onSelect(FollowDirection.followers),
          ),
          _Tab(
            value: following,
            label: 'FOLLOWING',
            active: tab == FollowDirection.following,
            onTap: () => onSelect(FollowDirection.following),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.value,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final int value;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Overlap the section's hairline divider by 1px so the active underline
    // visually replaces it under the active tab — matches the design's
    // marginBottom:-1 in `followers-screen.jsx`.
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? CkColors.ink : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: CkType.display(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.03,
                  height: 1.1,
                  color: active ? CkColors.ink : CkColors.ink2,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: active ? CkColors.ink : CkColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: CkColors.hairline);
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.tab,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FollowDirection tab;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final placeholder =
        tab == FollowDirection.followers ? 'Search followers' : 'Search following';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 15, color: CkColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: placeholder,
                  hintStyle: CkType.body(fontSize: 14, color: CkColors.soft),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: CkType.body(fontSize: 14, color: CkColors.ink),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.close, size: 14, color: CkColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Body / list ──────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.listAsync, required this.query});

  final AsyncValue<List<FollowListEntry>> listAsync;
  final String query;

  @override
  Widget build(BuildContext context) {
    return switch (listAsync) {
      AsyncData(:final value) => _renderList(value),
      AsyncError(:final error) => _ErrorBody(
          message: error is FailureWrapper
              ? error.failure.message
              : error.toString(),
        ),
      _ => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
    };
  }

  Widget _renderList(List<FollowListEntry> all) {
    final q = query.toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all
            .where((e) =>
                e.displayName.toLowerCase().contains(q) ||
                e.username.toLowerCase().contains(q))
            .toList();
    if (filtered.isEmpty) {
      return _EmptyBody(query: query, sourceWasEmpty: all.isEmpty);
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: CkColors.hairline,
      ),
      itemBuilder: (context, i) => _FollowerRow(entry: filtered[i]),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.query, required this.sourceWasEmpty});

  final String query;
  final bool sourceWasEmpty;

  @override
  Widget build(BuildContext context) {
    final message = sourceWasEmpty
        ? 'Nothing here yet.'
        : 'No one matches "$query".';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: CkType.body(fontSize: 13, color: CkColors.muted),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: CkType.body(fontSize: 13, color: CkColors.ink, height: 1.5),
        ),
      ),
    );
  }
}

// ─── Row ──────────────────────────────────────────────────────────────────────

class _FollowerRow extends ConsumerWidget {
  const _FollowerRow({required this.entry});
  final FollowListEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggle = ref.watch(
      followToggleProvider('user', entry.userId.value),
    );
    // Local view-state — start from the row's own server-side flag, then
    // swap in the toggle provider's optimistic value as soon as it
    // produces one. Avoids a flash of the stale row-level flag right
    // after the user taps the button.
    final isFollowing = toggle.value ?? entry.youFollow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          _RowAvatar(name: entry.displayName, userId: entry.userId.value),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.01,
                        ),
                      ),
                    ),
                    if (entry.isMutual) ...const [
                      SizedBox(width: 6),
                      _FollowsYouTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${entry.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.04,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RowButton(
            entry: entry,
            isFollowing: isFollowing,
            onTap: () => ref
                .read(followToggleProvider('user', entry.userId.value).notifier)
                .toggle(),
          ),
        ],
      ),
    );
  }
}

class _FollowsYouTag extends StatelessWidget {
  const _FollowsYouTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'FOLLOWS YOU',
        style: CkType.mono(
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

/// 42×42 round avatar with per-user color + initials. The design uses
/// arbitrary hex colors per row; we derive a stable color from the user's
/// id so the same user always paints the same shade across sessions.
class _RowAvatar extends StatelessWidget {
  const _RowAvatar({required this.name, required this.userId});
  final String name;
  final String userId;

  static const _palette = <Color>[
    Color(0xFF3563B6),
    Color(0xFF2F7D54),
    Color(0xFF7A4A2A),
    Color(0xFFC98A2B),
    Color(0xFF3A8F8F),
    Color(0xFF5B53A6),
    Color(0xFFA8552E),
    Color(0xFF6A6F2A),
  ];

  Color _colorFor() {
    var hash = 0;
    for (final code in userId.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colorFor(),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials(),
        style: CkType.display(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RowButton extends StatelessWidget {
  const _RowButton({
    required this.entry,
    required this.isFollowing,
    required this.onTap,
  });

  final FollowListEntry entry;
  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;
    final Border? border;
    final List<BoxShadow>? shadow;

    if (isFollowing) {
      // Paper + line border + ink text. "Following" — your relationship to
      // them is established.
      label = 'Following';
      bg = CkColors.paper;
      fg = CkColors.ink;
      border = Border.all(color: CkColors.line);
      shadow = null;
    } else if (entry.theyFollowYou) {
      // They follow you; you don't follow them yet. Distinct "Follow back"
      // CTA in red with a soft red shadow per the design.
      label = 'Follow back';
      bg = CkColors.red;
      fg = Colors.white;
      border = null;
      shadow = const [
        BoxShadow(
          color: Color(0x3DDC4D32),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ];
    } else {
      // Plain Follow CTA.
      label = 'Follow';
      bg = CkColors.red;
      fg = Colors.white;
      border = null;
      shadow = const [
        BoxShadow(
          color: Color(0x42DC4D32),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
          boxShadow: shadow,
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}
