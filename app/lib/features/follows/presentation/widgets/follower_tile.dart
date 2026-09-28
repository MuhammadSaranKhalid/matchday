import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/follow_list_entry.dart';
import '../controllers/follow_toggle_controller.dart';

/// Single row item in the Followers/Following list.
class FollowerTile extends ConsumerWidget {
  const FollowerTile({
    super.key,
    required this.entry,
    this.onTapProfile,
  });

  final FollowListEntry entry;
  final ValueChanged<String>? onTapProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggle = ref.watch(
      followToggleProvider('user', entry.userId.value),
    );
    // Optimistic toggle value or fallback to server value
    final isFollowing = toggle.value ?? entry.youFollow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleProfileTap(context),
            child: _TileAvatar(name: entry.displayName, userId: entry.userId.value),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleProfileTap(context),
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
          ),
          const SizedBox(width: 12),
          _TileButton(
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

  void _handleProfileTap(BuildContext context) {
    if (onTapProfile != null) {
      onTapProfile!(entry.username);
    } else if (entry.username.isNotEmpty) {
      Navigator.of(context, rootNavigator: true).pushNamed('/u/${entry.username}');
    }
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

class _TileAvatar extends StatelessWidget {
  const _TileAvatar({required this.name, required this.userId});
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

class _TileButton extends StatelessWidget {
  const _TileButton({
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
      label = 'Following';
      bg = CkColors.paper;
      fg = CkColors.ink;
      border = Border.all(color: CkColors.line);
      shadow = null;
    } else if (entry.theyFollowYou) {
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
