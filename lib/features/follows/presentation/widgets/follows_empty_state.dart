import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';

/// Clean empty and error state presentations for the follows list.
class FollowsEmptyState extends StatelessWidget {
  const FollowsEmptyState({
    super.key,
    required this.query,
    required this.sourceWasEmpty,
  });

  final String query;
  final bool sourceWasEmpty;

  @override
  Widget build(BuildContext context) {
    final message = sourceWasEmpty
        ? 'Nothing here yet.'
        : 'No one matches "$query".';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, size: 40, color: CkColors.soft),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 13.5, color: CkColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class FollowsErrorState extends StatelessWidget {
  const FollowsErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 36, color: CkColors.soft),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 13, color: CkColors.ink, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CkColors.line),
                  ),
                  child: Text(
                    'Try again',
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
