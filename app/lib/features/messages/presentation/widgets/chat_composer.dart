import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'chat_theme.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onImagePressed,
    this.replyingTo,
    this.onCancelReply,
    this.enabled = true,
    this.sending = false,
    this.placeholder = 'Message...',
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onImagePressed;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;
  final bool enabled;
  final bool sending;
  final String placeholder;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ChatTheme.clubhouseCanvas,
        border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        replyingTo == null ? 8 : 6,
        12,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null) ...[
            Row(
              children: [
                Container(
                  width: 3,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ChatTheme.matchDayCoral,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replying to ${replyingTo!.fromMe ? 'yourself' : (replyingTo!.senderDisplayName ?? 'user')}',
                        style: ChatTheme.badge(color: ChatTheme.matchDayCoral),
                      ),
                      Text(
                        replyingTo!.isImage
                            ? '📷 Photo'
                            : (replyingTo!.body ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onCancelReply,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: ChatTheme.mutedStone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: enabled && !sending ? onImagePressed : null,
                tooltip: 'Send photo',
                icon: const Icon(Icons.image_outlined),
                color: ChatTheme.charcoalInk,
                disabledColor: ChatTheme.mutedStone,
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 42, maxHeight: 120),
                  decoration: BoxDecoration(
                    color: ChatTheme.softSandFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ChatTheme.hairlineSand),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled && !sending,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: ChatTheme.bodyMd(),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: ChatTheme.bodyMd(color: ChatTheme.mutedStone),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 42,
                child: FilledButton(
                  onPressed: enabled && !sending ? onSend : null,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: ChatTheme.matchDayCoral,
                    disabledBackgroundColor: ChatTheme.hairlineSand,
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ChatTheme.pureSurface,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorText!,
                style: ChatTheme.bodySm(color: ChatTheme.destructiveCoralText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
