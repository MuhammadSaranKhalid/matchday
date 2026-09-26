import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/pending_post.dart';
import '../providers/posts_providers.dart';

/// Card rendered at the top of the feed for a post currently being uploaded/processed
/// on this client device.
class PendingPostCard extends ConsumerWidget {
  const PendingPostCard({
    super.key,
    required this.pendingPost,
  });

  final PendingPost pendingPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImages = pendingPost.localMediaPaths.isNotEmpty;
    final isFailed = pendingPost.status == PendingPostStatus.failed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed ? CkColors.red.withValues(alpha: 0.3) : CkColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isFailed)
                const Icon(Icons.error_outline, size: 16, color: CkColors.red)
              else
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(CkColors.ink),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  switch (pendingPost.status) {
                    PendingPostStatus.uploading => 'Uploading media...',
                    PendingPostStatus.publishing => 'Publishing post...',
                    PendingPostStatus.failed => pendingPost.errorMessage ?? 'Upload failed',
                  },
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isFailed ? CkColors.red : CkColors.muted,
                  ),
                ),
              ),
              if (isFailed) ...[
                TextButton(
                  onPressed: () => ref
                      .read(postsRepositoryProvider)
                      .retryPendingPost(pendingPost.postId),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Retry',
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(postsRepositoryProvider)
                      .discardPendingPost(pendingPost.postId),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Discard',
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CkColors.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if ((pendingPost.text ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pendingPost.text!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 13, color: CkColors.ink),
            ),
          ],
          if (hasImages) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pendingPost.localMediaPaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = pendingPost.localMediaPaths[index];
                  final file = File(path);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: file.existsSync()
                        ? Image.file(
                            file,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          )
                        : const ColoredBox(
                            color: CkColors.paper2,
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Icon(Icons.photo, color: CkColors.muted),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
