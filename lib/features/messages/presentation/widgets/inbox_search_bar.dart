import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// Clean, sleek search bar for filtering messages and conversations.
class InboxSearchBar extends StatelessWidget {
  const InboxSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.hintText = 'Search chats, people, teams...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CkColors.line.withValues(alpha: 0.7),
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
                  hintText: hintText,
                  hintStyle: CkType.body(
                    fontSize: 13.5,
                    color: CkColors.muted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                    onClear?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: CkColors.hairline,
                      shape: BoxShape.circle,
                    ),
                    child: const V2Svg(
                      V2Icons.close,
                      size: 12,
                      color: CkColors.ink,
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
