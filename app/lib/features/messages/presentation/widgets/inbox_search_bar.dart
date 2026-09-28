import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// Stitch-styled search bar for filtering messages and conversations.
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ChatTheme.softSandFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: ChatTheme.hairlineSand,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 19,
              color: ChatTheme.mutedStone,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: ChatTheme.bodyMd(color: ChatTheme.charcoalInk),
                cursorColor: ChatTheme.charcoalInk,
                cursorWidth: 1.5,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: hintText,
                  hintStyle: ChatTheme.bodyMd(color: ChatTheme.mutedStone),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
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
                      color: ChatTheme.hairlineSand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: ChatTheme.charcoalInk,
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
