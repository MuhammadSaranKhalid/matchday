import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// "My teams" header — back chevron, title (with optional `· N` count), and
/// subtitle. No search affordance, no notification bell.
class MyTeamsHeader extends StatelessWidget {
  const MyTeamsHeader({
    super.key,
    required this.count,
    this.subtitle,
    this.onBack,
  });

  /// Total active teams — shown as a mono `· N` next to the title.
  final int count;
  final String? subtitle;

  /// Optional back chevron at the leading edge (used when the screen is
  /// pushed full-screen over the shell).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            _BackBtn(onTap: onBack!)
          else
            const SizedBox(width: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'My teams',
                      style: CkType.display(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.025,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· $count',
                        style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.10,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.chevron_left, size: 22, color: CkColors.ink),
      ),
    );
  }
}
