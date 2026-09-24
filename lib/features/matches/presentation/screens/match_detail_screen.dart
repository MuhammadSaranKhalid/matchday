// Match Detail — its own full-screen route (`/matches/:matchId`), mounted
// over the shell so the system back gesture works and the bottom nav is
// covered. Resolves the match by id from workspace providers (`myMatchesViewProvider` + `myTeams`),
// so it survives a refresh / deep link rather than depending on in-memory screen state.
//
// All per-match actions live here. Navigating into a sub-flow (scoring / start
// / scorecard) invalidates the view on return; withdrawing a challenge goes
// through [MatchDetailController] and pops back.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/match.dart';
import '../controllers/match_detail_controller.dart';
import '../controllers/match_room_controller.dart';
import '../providers/match_detail_provider.dart';
import '../providers/my_matches_providers.dart';
import 'match_start_screen.dart';
import '../state/match_room_state.dart';
import '../widgets/match_detail/pv_v2_match_detail.dart';
import '../widgets/match_room/match_room_body.dart';
import '../widgets/withdraw_sheet.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(matchRoomControllerProvider(matchId), (previous, next) {
      final room = next.value;
      final navigation = room?.navigation;
      if (navigation == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final target = switch (navigation) {
          MatchRoomNavigation.scoring => '/matches/$matchId/score',
          MatchRoomNavigation.result => '/matches/$matchId/result',
        };
        ref
            .read(matchRoomControllerProvider(matchId).notifier)
            .consumeNavigation();
        context.go(target);
      });
    });
    final roomAsync = ref.watch(matchRoomControllerProvider(matchId));
    if (roomAsync.hasValue) {
      final room = roomAsync.value!;
      final startPhase = room.snapshot.match.startPhase;
      if (startPhase == MatchStartPhase.toss ||
          startPhase == MatchStartPhase.lineup ||
          startPhase == MatchStartPhase.ready) {
        return MatchStartScreen(matchId: matchId, room: room);
      }
      return Scaffold(
        backgroundColor: CkColors.paper,
        body: MatchRoomBody(matchId: matchId, state: room),
      );
    }
    if (roomAsync.isLoading) {
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // A route can also represent a pending challenge, which has no canonical
    // Match Room yet. Fall back to the existing detail aggregate in that case.
    final detailAsync = ref.watch(matchDetailProvider(matchId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (detailAsync) {
        AsyncError(:final error) => _error(
          context,
          error is FailureWrapper ? error.failure.message : error.toString(),
          () => ref.invalidate(matchDetailProvider(matchId)),
        ),
        _ when detailAsync.hasValue && detailAsync.value != null =>
          PvMatchDetail(
            m: detailAsync.value!,
            onBack:
                () =>
                    context.canPop()
                        ? context.pop()
                        : context.go('/my/matches'),
            onAction: (id, action) => _onAction(context, ref, id, action),
          ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        _ => _notAvailable(context),
      },
    );
  }

  // ── actions ──
  void _onAction(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
  ) {
    switch (action) {
      case 'resume':
        _pushAndRefresh(context, ref, '/matches/$id/score');
      case 'start':
        _pushAndRefresh(context, ref, '/matches/$id');
      case 'scorecard':
      case 'view':
        _pushAndRefresh(context, ref, '/matches/$id/scorecard');
      case 'withdraw':
        _withdraw(context, ref, id);
      case 'cancel':
        _cancel(context, ref, id);
      case 'share':
        _comingSoon(context, 'Sharing match results is coming soon.');
    }
  }

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pushAndRefresh(
    BuildContext context,
    WidgetRef ref,
    String location,
  ) async {
    await context.push(location);
    if (context.mounted) ref.invalidate(myMatchesViewProvider);
  }

  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
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
        .read(matchDetailControllerProvider.notifier)
        .withdraw(requestId: requestId, note: result.note);
    if (!context.mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        // Controller already invalidated the workspace providers.
        if (context.canPop()) context.pop();
      },
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) async {
    // Destructive operations should require an explicit confirmation.
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cancel match?'),
            content: const Text(
              'This will cancel the confirmed match for both teams. '
              'This action cannot be treated as a normal Match Start step.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep match'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Cancel match'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final result = await ref
        .read(matchDetailControllerProvider.notifier)
        .cancelMatch(matchId: matchId);

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        // Cancellation removes this fixture from the confirmed schedule.
        //
        // Return to My Matches rather than leaving the user on a stale detail.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/my/matches');
        }
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
              onTap:
                  () =>
                      context.canPop()
                          ? context.pop()
                          : context.go('/my/matches'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '← My Matches',
                  style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Match not available',
              style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'It may have been withdrawn or removed.',
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
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
              onTap:
                  () =>
                      context.canPop()
                          ? context.pop()
                          : context.go('/my/matches'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '← My Matches',
                  style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load this match.",
              style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: CkType.body(fontSize: 12, color: CkColors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
