import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// Clean top header for the Followers/Following screen.
class FollowsHeader extends StatelessWidget {
  const FollowsHeader({
    super.key,
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
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
          ),
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
          // Spacer for centering title
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}
