import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';

class ComposerHeader extends StatelessWidget {
  const ComposerHeader({
    super.key,
    required this.canPost,
    required this.busy,
    required this.onPost,
    required this.onCancel,
  });

  final bool canPost;
  final bool busy;
  final VoidCallback onPost;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: busy ? null : onCancel,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text('Cancel',
                  style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CkColors.ink2)),
            ),
          ),
          Text('New post', style: CkType.display(fontSize: 15, fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: canPost ? onPost : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: canPost ? CkColors.ink : CkColors.paper2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: CkColors.paper),
                    )
                  : Text('Post',
                      style: CkType.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: canPost ? CkColors.paper : CkColors.muted)),
            ),
          ),
        ],
      ),
    );
  }
}
