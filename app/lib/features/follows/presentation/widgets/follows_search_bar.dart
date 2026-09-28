import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../domain/entities/follow_direction.dart';

/// Clean, sleek search bar for filtering followers/following without nested borders.
class FollowsSearchBar extends StatelessWidget {
  const FollowsSearchBar({
    super.key,
    required this.controller,
    required this.tab,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FollowDirection tab;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final placeholder = tab == FollowDirection.followers
        ? 'Search followers...'
        : 'Search following...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CkColors.line.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const V2Svg(
              V2Icons.search,
              size: 16,
              color: CkColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: CkType.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CkColors.ink,
                ),
                cursorColor: CkColors.ink,
                cursorWidth: 1.5,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: placeholder,
                  hintStyle: CkType.body(
                    fontSize: 14,
                    color: CkColors.muted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: Icon(
                        Icons.cancel,
                        size: 16,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
