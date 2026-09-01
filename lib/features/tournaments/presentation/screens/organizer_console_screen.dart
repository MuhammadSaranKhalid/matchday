import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/scorer_candidate.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';
import '../widgets/tournament_cancel_dialog.dart';
import '../widgets/tournament_live_ops_tab.dart';
import '../widgets/tournament_lock_dialog.dart';
import '../widgets/tournament_ops_sheets.dart';
import '../widgets/tournament_registrations_tab.dart';
import '../widgets/tournament_seeding_tab.dart';
import '../widgets/tournament_wrap_up_tab.dart';

/// The organiser's console — artboards 24–28.
///
/// A pushed screen off the hub, never a tab: 56pt nav titled "Manage" with the
/// tournament name as the subtitle, then three tabs. The second tab's label
/// follows the format — "Fixtures & Seeds" for knockout, "Fixtures & Order"
/// for round robin and league — because in those two the pairings are fixed
/// and only the order is the organiser's to choose.
///
/// Only an organiser reaches any of it; a manager following a console link
/// lands on the public detail screen instead.
class OrganizerConsoleScreen extends ConsumerStatefulWidget {
  const OrganizerConsoleScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<OrganizerConsoleScreen> createState() =>
      _OrganizerConsoleScreenState();
}

class _OrganizerConsoleScreenState
    extends ConsumerState<OrganizerConsoleScreen>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState, not as a `late final` field: the cancelled
  // console returns before any TabBar mounts, so a lazy field would first be
  // constructed inside dispose() — where looking up TickerMode's ancestor is
  // unsafe.
  late final TabController _tabController;

  /// Approvals waiting out their undo window, keyed by registration id.
  ///
  /// Approving is one tap, so it is backed by a 5-second undo rather than a
  /// confirm dialog: approving the wrong club into a locked draw is as costly
  /// as declining one, but a dialog on every approval would make a queue of
  /// eight unbearable. The row disappears immediately and the write is held
  /// until the window closes.
  final Map<String, Timer> _pendingApprovals = {};
  final Set<String> _optimisticallyApproved = {};

  /// The bar currently offering an undo, closed when the window shuts.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undoBanner;

  /// Captured at approve time so a flush during dispose does not touch `ref`,
  /// which Riverpod forbids once the element is deactivated. The repository
  /// provider is keepAlive, so the reference outlives this screen.
  TournamentsRepository? _repoForFlush;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // Anything still inside its undo window when the screen goes away is
    // committed rather than silently dropped.
    final repo = _repoForFlush;
    for (final entry in _pendingApprovals.entries) {
      entry.value.cancel();
      if (repo != null) {
        unawaited(repo.approveRegistration(entry.key));
      }
    }
    _pendingApprovals.clear();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Registrations ─────────────────────────────────────────────────────────

  void _approve(TournamentRegistration reg) {
    _repoForFlush ??= ref.read(tournamentsRepositoryProvider);
    setState(() => _optimisticallyApproved.add(reg.registrationId));

    _pendingApprovals[reg.registrationId] = Timer(
      const Duration(seconds: 5),
      () async {
        _pendingApprovals.remove(reg.registrationId);
        // The window is shut; take the Undo away with it.
        _undoBanner?.close();
        _undoBanner = null;
        if (!mounted) return;
        await ref
            .read(tournamentsControllerProvider.notifier)
            .approveRegistration(widget.tournamentId, reg.registrationId);
        if (mounted) {
          setState(() => _optimisticallyApproved.remove(reg.registrationId));
        }
      },
    );

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    _undoBanner = messenger.showSnackBar(
      SnackBar(
        // Long duration on purpose: the controller below closes it the moment
        // the undo window expires, so the bar and the window share one clock.
        // Leaving it to SnackBar.duration let the bar outlive the window and
        // keep offering an Undo that no longer did anything.
        duration: const Duration(minutes: 1),
        content: Text('${reg.teamName ?? 'Team'} approved'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: CkColors.cream,
          onPressed: () {
            _pendingApprovals.remove(reg.registrationId)?.cancel();
            if (mounted) {
              setState(
                () => _optimisticallyApproved.remove(reg.registrationId),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _decline(TournamentRegistration reg) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CkColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CkRadii.md),
        ),
        title: Text(
          'Decline ${reg.teamName ?? 'this team'}?',
          style: CkType.display(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'They are told the reason, so make it something you would say '
              'to their manager.',
              style: CkType.body(
                fontSize: 12.5,
                height: 1.5,
                color: CkColors.ink2,
              ),
            ),
            const SizedBox(height: 12),
            CkTextField(
              controller: reason,
              label: 'Reason',
              hint: 'Draw is full for this season',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: CkColors.ink2),
            child: Text(
              'Keep it pending',
              style: CkType.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CkColors.ink2,
              ),
            ),
          ),
          // Red text on a ghost button — never a red fill. The colour has to
          // be on the Text as well: CkType.body defaults to ink and would
          // otherwise override the button's foreground, which is exactly how
          // these two ended up inverted on device.
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: CkColors.redInk),
            child: Text(
              'Decline',
              style: CkType.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CkColors.redInk,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(tournamentsControllerProvider.notifier).rejectRegistration(
            widget.tournamentId,
            reg.registrationId,
            reason.text.trim().isEmpty
                ? 'Registration declined by the organiser'
                : reason.text.trim(),
          );
    }
    reason.dispose();
  }

  Future<void> _togglePaid(TournamentRegistration reg) async {
    final isPaid = (reg.paymentStatus ?? '').toLowerCase() == 'paid';
    await ref.read(tournamentsControllerProvider.notifier).updatePaymentStatus(
          widget.tournamentId,
          reg.registrationId,
          isPaid ? 'unpaid' : 'paid',
        );
  }

  void _shareInvite(Tournament tournament) {
    context.push('/tournaments/${tournament.id}/published');
  }

  // ─── Fixtures ──────────────────────────────────────────────────────────────

  Future<void> _lockDraw(
    Tournament tournament,
    List<TournamentRegistration> ordered,
  ) async {
    final confirmed = await showLockDrawDialog(
      context,
      teamCount: ordered.length,
      playerCount: ordered.fold<int>(0, (s, r) => s + r.squad.length),
      hasWaitlist: false,
    );
    if (confirmed != true || !mounted) return;

    final slots = <FixtureSlotParams>[];
    final start = tournament.startDate ??
        DateTime.now().add(const Duration(days: 2));
    final grounds = tournament.venues.isEmpty
        ? ['Ground 1']
        : tournament.venues.map((v) => v.name).toList();
    const dayStarts = [9, 13, 18];

    final isKnockout = tournament.type == TournamentType.knockout ||
        tournament.type == TournamentType.doubleElimination;
    final roundLabel = switch (ordered.length) {
      <= 2 => 'Final',
      <= 4 => 'Semi-Final',
      <= 8 => 'Quarter-Final',
      _ => 'Round 1',
    };

    for (var i = 0; i < ordered.length ~/ 2; i++) {
      // Knockout pairs strongest against weakest; the flat formats pair off
      // the order as given.
      final a = ordered[isKnockout ? i : i * 2];
      final b = ordered[isKnockout ? ordered.length - 1 - i : i * 2 + 1];

      final ground = grounds[i % grounds.length];
      final hour = dayStarts[(i ~/ grounds.length) % dayStarts.length];

      slots.add(
        FixtureSlotParams(
          teamAId: a.teamId,
          teamBId: b.teamId,
          scheduledStartTime:
              DateTime(start.year, start.month, start.day, hour),
          venue: ground,
          round: isKnockout ? roundLabel : 'Round 1',
          bracketRoundNumber: 1,
          bracketMatchNumber: i + 1,
        ),
      );
    }

    final count = await ref
        .read(tournamentsControllerProvider.notifier)
        .generateAndPublishFixtures(
          tournamentId: widget.tournamentId,
          slots: slots,
        );

    if (!mounted) return;
    if (count != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Draw locked · $count fixture${count == 1 ? '' : 's'} live',
          ),
        ),
      );
      _tabController.animateTo(2);
    } else {
      final state = ref.read(tournamentsControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CkColors.redInk,
          content: Text(
            state.hasError ? '${state.error}' : 'Could not lock the draw.',
          ),
        ),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  /// "Closes in 2 days · 6 of 8 approved" — the cream banner heading the
  /// Registrations queue.
  String _statusLine(Tournament t, int approvedCount) {
    final parts = <String>[];

    final deadline = t.registrationDeadline;
    if (t.status == TournamentStatus.registration && deadline != null) {
      final days = deadline.difference(DateTime.now()).inDays;
      parts.add(
        days < 0
            ? 'Registration closed'
            : days == 0
                ? 'Closes today'
                : 'Closes in $days day${days == 1 ? '' : 's'}',
      );
    } else {
      parts.add(t.status.label);
    }

    if (t.maxTeams != null) {
      parts.add('$approvedCount of ${t.maxTeams} approved');
    } else if (approvedCount > 0) {
      parts.add('$approvedCount approved');
    }
    return parts.join(' · ');
  }

  /// "Fixtures & Seeds" for knockout, "Fixtures & Order" for the flat formats.
  String _fixturesTabLabel(Tournament t) =>
      t.type == TournamentType.knockout ||
              t.type == TournamentType.doubleElimination
          ? 'Fixtures & Seeds'
          : 'Fixtures & Order';

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final registrationsAsync =
        ref.watch(tournamentRegistrationsProvider(widget.tournamentId));

    // Watched, not read: the controller is autoDispose, and every action on
    // this screen is dispatched through `ref.read(...notifier)`. Without a
    // listener Riverpod disposes it mid-write, so the post-write invalidate
    // never runs and the list silently goes stale. Watching keeps it alive for
    // as long as the console is open, and gives us the in-flight flag.
    final busy = ref.watch(tournamentsControllerProvider).isLoading;

    return tournamentAsync.when(
      loading: () => const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: Text('$e')),
      ),
      data: (tournament) {
        // Artboard 27i — a cancelled cup keeps its tabs hidden: there is
        // nothing left to manage, so the screen is a record.
        if (tournament.status == TournamentStatus.cancelled) {
          return CancelledConsoleView(tournament: tournament);
        }

        final all = registrationsAsync.value ?? const <TournamentRegistration>[];
        final approvedNow = all.where((r) => r.isApproved).toList();
        // Optimistically-approved rows leave the queue immediately so the undo
        // window feels instant.
        final held = all
            .where((r) => _optimisticallyApproved.contains(r.registrationId))
            .toList();
        final approved = [...approvedNow, ...held];

        final pendingAll = all
            .where((r) =>
                r.isPending &&
                !_optimisticallyApproved.contains(r.registrationId))
            .toList();

        // Beyond capacity the draw is full, so the remainder waits.
        final capacity = tournament.maxTeams;
        final room = capacity == null
            ? pendingAll.length
            : (capacity - approved.length).clamp(0, pendingAll.length);
        final pending = pendingAll.take(room).toList();
        final waitlisted = pendingAll.skip(room).toList();

        return Scaffold(
          backgroundColor: CkColors.paper,
          appBar: AppBar(
            backgroundColor: CkColors.paper,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: CkColors.ink),
              onPressed: () => context.pop(),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Manage', style: CkType.display(fontSize: 17)),
                Text(
                  tournament.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(fontSize: 12, color: CkColors.muted),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: CkColors.ink),
                tooltip: 'Tournament actions',
                onPressed: () => _onConsoleMenu(tournament),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: CkColors.ink,
              unselectedLabelColor: CkColors.muted,
              indicatorColor: CkColors.red,
              indicatorWeight: 2,
              dividerColor: CkColors.hairline,
              labelStyle: CkType.display(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: CkType.display(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: CkColors.muted,
              ),
              tabs: [
                // The badge is what is owed, not a total: it counts the
                // applications waiting on the organiser. A tab with nothing
                // owed carries no badge at all.
                Tab(
                  child: _TabLabel(
                    label: 'Registrations',
                    badge: pending.isEmpty ? null : pending.length,
                  ),
                ),
                Tab(child: _TabLabel(label: _fixturesTabLabel(tournament))),
                Tab(
                  child: _TabLabel(
                    label: tournament.status == TournamentStatus.completed
                        ? 'Wrap Up'
                        : 'Live Ops',
                  ),
                ),
              ],
            ),
          ),
          body: registrationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (_) => TabBarView(
              controller: _tabController,
              children: [
                TournamentRegistrationsTab(
                  tournament: tournament,
                  statusLine: _statusLine(tournament, approved.length),
                  pending: pending,
                  approved: approved,
                  waitlisted: waitlisted,
                  onApprove: _approve,
                  onDecline: _decline,
                  onTogglePaid: _togglePaid,
                  onShare: () => _shareInvite(tournament),
                  onInviteTeams: () => _shareInvite(tournament),
                ),
                TournamentSeedingTab(
                  tournament: tournament,
                  approved: approved,
                  groundNames: tournament.venues.map((v) => v.name).toList(),
                  onLock: busy
                      ? null
                      : (ordered) => _lockDraw(tournament, ordered),
                ),
                _buildLiveOpsTab(tournament),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Tab 4: Live Ops (artboards 27, 27b, 27c, 28) ──────────────────────────

  Widget _buildLiveOpsTab(Tournament tournament) {
    // Once the final is scored, Live Ops becomes Wrap Up (artboard 27b).
    if (tournament.status == TournamentStatus.completed) {
      return TournamentWrapUpTab(tournament: tournament);
    }
    return TournamentLiveOpsTab(
      tournament: tournament,
      onMatchActions: _onMatchActions,
      onAssignScorer: _onAssignScorer,
    );
  }

  /// Surfaces whatever the controller last failed with. Ops actions are
  /// destructive enough that a silent no-op is the wrong outcome.
  void _reportIfFailed(bool ok, String successMessage) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      return;
    }
    final state = ref.read(tournamentsControllerProvider);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: CkColors.redInk,
        content: Text(
          state.hasError ? '${state.error}' : 'That did not go through.',
        ),
      ),
    );
  }

  Future<void> _onMatchActions(TournamentLiveMatch match) async {
    final action = await showMatchActionsMenu(context, match);
    if (action == null || !mounted) return;

    switch (action) {
      case MatchOpsAction.changeScorer:
        await _onAssignScorer(match);
      case MatchOpsAction.changeGroundOrTime:
        await _onReschedule(match);
      case MatchOpsAction.declareWalkover:
        await _onWalkover(match);
      case MatchOpsAction.overrideResult:
        await _onOverride(match);
      case MatchOpsAction.abandonMatch:
        await _onAbandon(match);
    }
  }

  Future<void> _onAssignScorer(TournamentLiveMatch match) async {
    final picked = await showModalBottomSheet<ScorerCandidate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: CkColors.ink.withValues(alpha: 0.32),
      builder: (ctx) => _ScorerPickerSheet(
        tournamentId: widget.tournamentId,
        match: match,
      ),
    );
    if (picked == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .assignScorer(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          userId: picked.userId,
        );
    _reportIfFailed(ok, '${picked.displayName} will score this match.');
  }

  Future<void> _onReschedule(TournamentLiveMatch match) async {
    final date = await showDatePicker(
      context: context,
      initialDate: match.scheduledStartTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(match.scheduledStartTime),
    );
    if (!mounted) return;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? match.scheduledStartTime.hour,
      time?.minute ?? match.scheduledStartTime.minute,
    );

    final venue = await _promptForText(
      title: 'Ground',
      hint: match.venue,
      initial: match.venue,
      confirmLabel: 'Save',
    );
    if (!mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .rescheduleMatch(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          startTime: start,
          venue: venue,
        );
    _reportIfFailed(ok, 'Fixture moved. Both teams are notified.');
  }

  Future<void> _onWalkover(TournamentLiveMatch match) async {
    final outcome = await showWalkoverSheet(context, match);
    if (outcome == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .declareWalkover(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          winnerTeamId: outcome.winnerTeamId,
          reason: outcome.reason,
        );
    _reportIfFailed(
      ok,
      '${match.displayNameFor(outcome.winnerTeamId)} awarded the walkover.',
    );
  }

  Future<void> _onOverride(TournamentLiveMatch match) async {
    final outcome = await showOverrideResultSheet(context, match);
    if (outcome == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .overrideResult(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          winnerTeamId: outcome.winnerTeamId,
          reason: outcome.reason,
        );
    _reportIfFailed(ok, 'Result overridden and recorded in the audit log.');
  }

  Future<void> _onAbandon(TournamentLiveMatch match) async {
    final outcome = await showAbandonMatchSheet(context, match);
    if (outcome == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .abandonMatch(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          mode: outcome.mode,
          rescheduleTo: outcome.rescheduleTo,
          reason: outcome.reason,
        );
    _reportIfFailed(
      ok,
      outcome.mode == AbandonMode.reschedule
          ? 'Match abandoned. The fixture is back as upcoming.'
          : 'No result recorded. Points split 1–1.',
    );
  }

  // ─── The console ⋮ menu (artboard 27c, left) ───────────────────────────────

  Future<void> _onConsoleMenu(Tournament tournament) async {
    final me = ref.read(currentUserStreamProvider).value;
    final isOwner = me != null && tournament.createdBy == me.id.value;
    final inRegistration = tournament.status == TournamentStatus.registration;
    final action = await showConsoleMenu(
      context,
      tournamentName: tournament.name,
      statusLine: tournament.status.label,
      inRegistration: inRegistration,
      drawLocked: !inRegistration && tournament.status != TournamentStatus.draft,
      isOwner: isOwner,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case ConsoleMenuAction.editSettings:
        context.push('/tournaments/${widget.tournamentId}/settings');
      case ConsoleMenuAction.sendAnnouncement:
        context.push('/tournaments/${widget.tournamentId}/announce');
      case ConsoleMenuAction.coOrganisers:
        context.push('/tournaments/${widget.tournamentId}/people');
      case ConsoleMenuAction.closeRegistrationEarly:
        await _closeRegistrationEarly();
      case ConsoleMenuAction.cancelTournament:
        if (!isOwner) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: CkColors.redInk,
              content: Text('Only the tournament creator can cancel it.'),
            ),
          );
          return;
        }
        await _confirmCancel(tournament);
    }
  }

  Future<void> _closeRegistrationEarly() async {
    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .updateTournament(widget.tournamentId, {
      'status': TournamentStatus.upcoming.wire,
    });
    _reportIfFailed(ok, 'Registration closed. Generate the draw when ready.');
  }

  Future<void> _confirmCancel(Tournament tournament) async {
    final confirmed = await showCancelTournamentDialog(
      context,
      tournament: tournament,
    );
    if (confirmed == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .cancelTournament(
          tournamentId: widget.tournamentId,
          reason: confirmed,
        );
    _reportIfFailed(ok, 'Tournament cancelled. Everyone has been notified.');
  }

  /// Small single-field prompt used by the reschedule flow for the ground.
  Future<String?> _promptForText({
    required String title,
    required String hint,
    required String initial,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CkColors.surface,
        title: Text(title, style: CkType.display(fontSize: 17)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: CkType.body(fontSize: 14),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CkColors.ink),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }
}

/// Picks who scores a fixture. Candidates come from one RPC — organisers plus
/// the managers of approved teams.
class _ScorerPickerSheet extends ConsumerWidget {
  const _ScorerPickerSheet({
    required this.tournamentId,
    required this.match,
  });

  final String tournamentId;
  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync =
        ref.watch(tournamentScorerCandidatesProvider(tournamentId));

    return Container(
      decoration: const BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(CkRadii.lg)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: CkColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assign a scorer', style: CkType.display(fontSize: 19)),
                  const SizedBox(height: 4),
                  Text(
                    '${match.teamAName ?? 'TBC'} v ${match.teamBName ?? 'TBC'}'
                    ' · ${match.venue}',
                    style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Flexible(
              child: peopleAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '$e',
                    style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                  ),
                ),
                data: (people) {
                  if (people.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      child: Text(
                        'Nobody to assign yet. Approve a team, or add a '
                        'co-organiser, and they will appear here.',
                        style: CkType.body(
                          fontSize: 12.5,
                          height: 1.5,
                          color: CkColors.muted,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: people.length,
                    itemBuilder: (_, i) {
                      final person = people[i];
                      final isCurrent = person.userId == match.scorerId;
                      return ListTile(
                        onTap: () => Navigator.pop(context, person),
                        title: Text(
                          person.displayName,
                          style: CkType.display(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isCurrent
                              ? '${person.roleLabel} · currently scoring'
                              : person.roleLabel,
                          style: CkType.body(
                            fontSize: 11.5,
                            color: isCurrent
                                ? CkColors.greenInk
                                : CkColors.muted,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: CkColors.greenInk,
                              )
                            : const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: CkColors.soft,
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tab label with an optional cream count badge.
class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, this.badge});

  final String label;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (badge != null) ...[
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: CkColors.creamBorder),
            ),
            child: Text(
              '$badge',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: CkColors.amberDark,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

