import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_theme.dart';
import '../../domain/entities/message.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.onSendText,
    required this.onSendImage,
    required this.sending,
    this.replyingTo,
    this.onCancelReply,
    this.error,
    this.placeholder = 'Message...',
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final Future<void> Function() onSendText;
  final Future<void> Function(File imageFile) onSendImage;
  final bool sending;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final String? error;
  final String placeholder;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        await onSendImage(File(picked.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: ChatTheme.charcoalInk,
          ),
        );
      }
    }
  }

  void _showMediaPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: ChatTheme.pureSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SafeArea(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: ChatTheme.hairlineSand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: ChatTheme.charcoalInk,
                    size: 22,
                  ),
                  title: Text(
                    'Take Photo',
                    style: ChatTheme.bodyMd(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: ChatTheme.charcoalInk,
                    size: 22,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: ChatTheme.bodyMd(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: ChatTheme.pureSurface,
        border: Border(top: BorderSide(color: ChatTheme.hairlineSand)),
      ),
      child: SafeArea(
        top: false,
        bottom: bottomInset == 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quoted Reply Dock (Harmonized with Stitch design)
            if (replyingTo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: ChatTheme.softSandFill,
                  border: Border(
                    bottom: BorderSide(color: ChatTheme.hairlineSand),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 2.5,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ChatTheme.matchDayCoral,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ${replyingTo!.fromMe ? 'yourself' : (replyingTo!.senderDisplayName ?? 'Chat')}',
                            style: ChatTheme.metadata(
                              color: ChatTheme.matchDayCoral,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyingTo!.isImage ? '📷 Photo' : replyingTo!.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChatTheme.bodySm(color: ChatTheme.mutedStone),
                          ),
                        ],
                      ),
                    ),
                    if (onCancelReply != null)
                      GestureDetector(
                        onTap: onCancelReply,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ChatTheme.pureSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: ChatTheme.hairlineSand),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: ChatTheme.mutedStone,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Error notice if any
            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: ChatTheme.destructiveCoralBg,
                child: Text(
                  error!,
                  style: ChatTheme.bodySm(
                    color: ChatTheme.destructiveCoralText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Main Composer Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 44px Circular Attachment Plus Button
                  GestureDetector(
                    onTap: sending ? null : () => _showMediaPicker(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 24,
                        color: ChatTheme.charcoalInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Pill Input Envelope
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: ChatTheme.pureSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: ChatTheme.hairlineSand),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(36, 35, 31, 0.02),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              focusNode: focusNode,
                              enabled: !sending,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.newline,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2000),
                              ],
                              decoration: InputDecoration(
                                hintText: placeholder,
                                hintStyle: ChatTheme.bodyMd(color: ChatTheme.mutedStone),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                              ),
                              style: ChatTheme.bodyMd(color: ChatTheme.charcoalInk),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Voice Note Mic Icon
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Voice notes coming soon'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.mic_none_rounded,
                                size: 20,
                                color: ChatTheme.mutedStone,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 44px Circular Coral Send Action Button
                  GestureDetector(
                    onTap: sending ? null : onSendText,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: ChatTheme.matchDayCoral,
                        shape: BoxShape.circle,
                        boxShadow: ChatTheme.sendButtonShadow,
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ChatTheme.pureSurface,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              size: 21,
                              color: ChatTheme.pureSurface,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
