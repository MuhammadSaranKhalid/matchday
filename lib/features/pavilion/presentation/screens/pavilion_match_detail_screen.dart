// Match Detail — its own full-screen route (`/pavilion/match/:id`), mounted
// over the shell so the system back gesture works and the bottom nav is
// covered. Resolves the match by id from the same workspace providers the
// Pavilion renders (`myMatchesViewProvider` + `myTeams`), so it survives a
// refresh / deep link rather than depending on in-memory screen state.
//
// All per-match actions live here. Navigating into a sub-flow (scoring / start
// / scorecard) invalidates the view on return; withdrawing a challenge goes
// through [PavilionController] and pops back to the Pavilion.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';
import '../../../matches/presentation/widgets/withdraw_sheet.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../controllers/pavilion_controller.dart';
import '../widgets/pavilion_v2/pv_v2_data.dart';
import '../widgets/pavilion_v2/pv_v2_map.dart';
import '../widgets/pavilion_v2/pv_v2_match_detail.dart';

class PavilionMatchDetailScreen extends ConsumerWidget {
  const PavilionMatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserStreamProvider).value?.id.value;
    final teamsAsync = ref.watch(myTeamsProvider);
    final matchesAsync = ref.watch(myMatchesViewProvider);

    // Resolve the match by id from the mapped workspace list (same mapping the
    // Pavilion uses). Awaiting challenges resolve too (by request id).
    final view = matchesAsync.value;
    PvMatch? match;
    if (view != null) {
      final pvTeams = pvTeamsFromTeams(teamsAsync.value ?? const [], userId: userId);
      final meFallback = pvTeams.isNotEmpty ? pvTeams.first.crest : kPvUnknownCrest;
      for (final m in pvMatchesFromView(view, meFallback: meFallback)) {
        if (m.id == matchId) {
          match = m;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (matchesAsync) {
        AsyncError(:final error) => _error(
            context,
            error is FailureWrapper ? error.failure.message : error.toString(),
            () => ref.invalidate(myMatchesViewProvider),
          ),
        AsyncData() when match != null => PvMatchDetail(
            m: match,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/pavilion'),
            onAction: (id, action) => _onAction(context, ref, id, action),
          ),
        // Loaded but empty — on a cold load / refresh, auth + data settle a
        // frame or two after first build. Wait, don't declare the match gone.
        AsyncData(:final value) when value.isEmpty =>
          const Center(child: CircularProgressIndicator()),
        // The workspace is populated but this id isn't in it (withdrawn / stale
        // link). Show a calm message — never auto-navigate away.
        AsyncData() => _notAvailable(context),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  // ── actions ──
  void _onAction(BuildContext context, WidgetRef ref, String id, String action) {
    switch (action) {
      case 'resume':
        _pushAndRefresh(context, ref, '/matches/$id/score');
      case 'start':
      case 'lineup':
      case 'viewlineup':
        _pushAndRefresh(context, ref, '/matches/$id/start');
      case 'scorecard':
      case 'view':
        _pushAndRefresh(context, ref, '/matches/$id/scorecard');
      case 'withdraw':
        _withdraw(context, ref, id);
    }
  }

  Future<void> _pushAndRefresh(
      BuildContext context, WidgetRef ref, String location) async {
    await context.push(location);
    if (context.mounted) ref.invalidate(myMatchesViewProvider);
  }

  Future<void> _withdraw(
      BuildContext context, WidgetRef ref, String requestId) async {
    final result = await showModalBottomSheet<WithdrawResult>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WithdrawSheet(),
    );
    if (result == null || !context.mounted) return;
    final res = await ref
        .read(pavilionControllerProvider.notifier)
        .withdraw(requestId: requestId, note: result.note);
    if (!context.mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        // Controller already invalidated the workspace providers.
        if (context.canPop()) context.pop();
      },
    );
  }

  /// Shown when the workspace is loaded and populated but this match id isn't
  /// in it (withdrawn / stale deep link). Never auto-navigates — the user
  /// chooses to back out.
  Widget _notAvailable(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/pavilion'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('← Pavilion',
                    style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Match not available',
                style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('It may have been withdrawn or removed.',
                style: CkType.body(fontSize: 12.5, color: CkColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context, String message, VoidCallback onRetry) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/pavilion'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('← Pavilion',
                    style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            Text("Couldn't load this match.",
                style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, style: CkType.body(fontSize: 12, color: CkColors.muted)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
