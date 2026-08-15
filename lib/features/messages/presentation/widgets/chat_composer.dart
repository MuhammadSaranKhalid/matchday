import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/circk_theme.dart';
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
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final Future<void> Function() onSendText;
  final Future<void> Function(File imageFile) onSendImage;
  final bool sending;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final String? error;

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
          SnackBar(content: Text('Failed to pick photo: $e')),
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
        return Container(
          decoration: const BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: CkColors.ink),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: CkColors.ink),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        6,
        12,
        MediaQuery.of(context).viewPadding.bottom + 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply banner if active
          if (replyingTo != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: CkColors.red, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Replying to ${replyingTo!.fromMe ? 'yourself' : (replyingTo!.senderDisplayName ?? 'User')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CkColors.red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          replyingTo!.isImage ? '📷 Photo' : replyingTo!.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onCancelReply != null)
                    GestureDetector(
                      onTap: onCancelReply,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 16, color: CkColors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                error!,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.05,
                  color: CkColors.red,
                ),
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment picker button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: sending ? null : () => _showMediaPicker(context),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8, bottom: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: CkColors.ink,
                  ),
                ),
              ),

              // Text Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    enabled: !sending,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2000),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Message…',
                      hintStyle: CkType.body(fontSize: 13.5, color: CkColors.muted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      isDense: true,
                    ),
                    style: CkType.body(fontSize: 13.5, color: CkColors.ink),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              SizedBox(
                width: 38,
                height: 38,
                child: GestureDetector(
                  onTap: sending ? null : onSendText,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: CkColors.ink,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: sending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CkColors.paper,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: CkColors.paper,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
