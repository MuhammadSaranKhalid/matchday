import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../controllers/team_page_controller.dart';
import '../widgets/team_page/team_page_body.dart';

/// Public team page at `/teams/:teamId`.
///
/// The existing Matchday visual language is preserved, but the page consumes
/// the real domain state directly. There is no duplicate viewer enum, fixture
/// model or adapter layer between [TeamPageController] and the UI.
class TeamPageScreen extends ConsumerWidget {
  const TeamPageScreen({super.key, required this.teamId});
  final String teamId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/teams');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamPageControllerProvider(teamId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (async) {
        AsyncData(value: final page?) => SafeArea(
            top: false,
            child: TeamPageBody(
              teamId: teamId,
              page: page,
              onBack: () => _back(context),
            ),
          ),
        AsyncData(value: null) => _Message(
            title: 'Team not found',
            body: 'This team is unavailable or you do not have access to it.',
            onBack: () => _back(context),
          ),
        AsyncError(:final error) => _Message(
            title: 'Could not load team',
            body: failureMessageOf(error),
            onBack: () => _back(context),
            onRetry: () => ref.invalidate(teamPageControllerProvider(teamId)),
          ),
        _ => const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          ),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    required this.onBack,
    this.onRetry,
  });
  final String title;
  final String body;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: CkType.body(fontSize: 13, color: CkColors.muted),
                ),
                const SizedBox(height: 12),
                if (onRetry != null)
                  TextButton(onPressed: onRetry, child: const Text('Try again')),
                TextButton(onPressed: onBack, child: const Text('Go back')),
              ],
            ),
          ),
        ),
      );
}
