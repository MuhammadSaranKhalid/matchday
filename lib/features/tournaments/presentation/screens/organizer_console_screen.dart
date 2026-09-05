import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/draw/draw_plan.dart';
import '../../domain/entities/scorer_candidate.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/ops/revised_target.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Registrations ─────────────────────────────────────────────────────────

  void _shareInvite(Tournament tournament) {
    context.push('/tournaments/${tournament.id}/published');
  }

  // ─── Fixtures ──────────────────────────────────────────────────────────────

  /// The grounds the draw is spread across, in display order.
  ///
  /// `tournament_grounds` rows are the authoritative list — `venues` is the
  /// deprecated jsonb mirror the create wizard still writes so older reads
  /// keep working. Falling back to it keeps tournaments created before
  /// grounds became rows schedulable.
  List<String> _groundNames(Tournament tournament) {
    final rows = ref.read(tournamentGroundsProvider(widget.tournamentId)).value;
    if (rows != null && rows.isNotEmpty) {
      return rows.map((g) => g.name).toList();
    }
    return tournament.venues.map((v) => v.name).toList();
  }

  /// Publishes the exact plan the seeding tab previewed.
  ///
  /// The plan arrives from the tab rather than being rebuilt here, so there is
  /// no second construction that could disagree with what the organiser was
  /// shown. This method used to carry its own pairing loop that emitted round
  /// one only, with every fixture stamped `bracketRoundNumber: 1` — so a
  /// knockout had quarter-finals and no semis, and a round robin published
  /// n/2 of its n(n-1)/2 fixtures while the tab above it promised the full
  /// number.
  Future<void> _lockDraw(
    Tournament tournament,
    List<TournamentRegistration> ordered,
    DrawPlan plan,
  ) async {
    final unsupported = plan.unsupported;
    if (unsupported != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$unsupported draws are not supported yet.'),
        ),
      );
      return;
    }
    if (plan.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough teams to draw a fixture.')),
      );
      return;
    }

    final confirmed = await showLockDrawDialog(
      context,
      teamCount: ordered.length,
      playerCount: ordered.fold<int>(0, (s, r) => s + r.squad.length),
      hasWaitlist: false,
      fixtureCount: plan.fixtures.length,
      roundCount: plan.roundCount,
      lastDate: plan.lastDate,
    );
    if (confirmed != true || !mounted) return;

    final count = await ref
        .read(tournamentsControllerProvider.notifier)
        .generateAndPublishFixtures(
          tournamentId: widget.tournamentId,
          plan: plan,
          // Position in this list becomes `seed_number`, written in the same
          // transaction as the draw.
          seedOrder: ordered.map((r) => r.teamId).toList(),
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

  /// Artboard 24e — the first tab is "Teams" at every stage. It was
  /// "Registrations" while the cup was open, but the applications queue has
  /// moved out to the nav-bar inbox, so what remains is always a roster.
  String _peopleTabLabel(Tournament t) => 'Teams';

  /// "Fixtures" when draw is locked; "Fixtures & Seeds" for knockout, "Fixtures & Order" for flat formats.
  String _fixturesTabLabel(Tournament t) {
    if (t.status != TournamentStatus.draft &&
        t.status != TournamentStatus.registration) {
      return 'Fixtures';
    }
    return t.type == TournamentType.knockout ||
            t.type == TournamentType.doubleElimination
        ? 'Fixtures & Seeds'
        : 'Fixtures & Order';
  }

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
        final approved = all.where((r) => r.isApproved).toList();
        final pendingAll = all.where((r) => r.isPending).toList();

        // Artboard 24f — there is no cap on teams: the header counts rather
        // than rations, and byes cover an odd number of approved sides. The
        // capacity-based waitlist that used to split this queue is gone.
        final pending = pendingAll;

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
              // Artboard 24e — requests move to a badged inbox icon beside the
              // overflow menu, reachable from all three tabs.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.inbox_outlined, color: CkColors.ink),
                    tooltip: 'Requests inbox',
                    onPressed: () => context
                        .push('/tournaments/${widget.tournamentId}/requests'),
                  ),
                  if (pendingAll.isNotEmpty)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4ECDD),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFDED0AC)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${pendingAll.length}',
                            style: CkType.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8C5311),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
                // Artboard 24e — no badge here. What is owed is counted once,
                // on the nav-bar inbox icon, which is reachable from all three
                // tabs; badging the tab as well said it twice.
                Tab(text: _peopleTabLabel(tournament)),
                Tab(text: _fixturesTabLabel(tournament)),
                Tab(
                  text: tournament.status == TournamentStatus.completed
                      ? 'Wrap Up'
                      : 'Live Ops',
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
                  onShare: () => _shareInvite(tournament),
                  onInviteTeams: () => _shareInvite(tournament),
                ),
                TournamentSeedingTab(
                  tournament: tournament,
                  approved: approved,
                  groundNames: _groundNames(tournament),
                  onLock: busy
                      ? null
                      : (ordered, plan) =>
                          _lockDraw(tournament, ordered, plan),
                  onGoToLiveOps: () => _tabController.animateTo(2),
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
      onStartMatch: _onStartMatch,
      onQuickPin: _onQuickPin,
      onReschedule: _onReschedule,
      onStartSecondInnings: _onStartSecondInnings,
      onAutoAssignScorers: _onAutoAssignScorers,
      onOpenScorer: _onOpenScorer,
    );
  }

  /// Artboard 27L — the live card's "Open Scorer". Scoring itself belongs to
  /// the matches feature; the console only points at it.
  void _onOpenScorer(TournamentLiveMatch match) {
    context.push('/matches/${match.matchId}/scoring');
  }

  /// Artboard 27L — the innings-break card's one action. The handover itself
  /// belongs to the scoring flow, which is where this hands off to; the
  /// console does not compute or record anything about the second innings.
  void _onStartSecondInnings(TournamentLiveMatch match) {
    context.push('/matches/${match.matchId}/start');
  }

  void _onStartMatch(TournamentLiveMatch match) {
    context.push('/matches/${match.matchId}/start');
  }

  Future<void> _onQuickPin(TournamentLiveMatch match) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: CkColors.ink.withValues(alpha: 0.32),
      builder: (ctx) => _ScorerPinHandoverSheet(match: match),
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
      case MatchOpsAction.assignOfficials:
        context.push(
          '/tournaments/${widget.tournamentId}/live/${match.matchId}/officials',
        );
      case MatchOpsAction.changeScorer:
        await _onAssignScorer(match);
      case MatchOpsAction.changeGroundOrTime:
        await _onReschedule(match);
      case MatchOpsAction.reviseConditions:
        await _onReviseConditions(match);
      case MatchOpsAction.launchSuperOver:
        await _onSuperOver(match);
      case MatchOpsAction.declareWalkover:
        await _onWalkover(match);
      case MatchOpsAction.overrideResult:
        await _onOverride(match);
      case MatchOpsAction.abandonMatch:
        await _onAbandon(match);
    }
  }

  // ─── Match-law ops (artboards 27m, 28b, 28c) ──────────────────────────────

  /// Builds the stoppage from what the board already knows. The board carries
  /// each innings' runs, wickets and legal balls, which is everything the
  /// calculator needs — no second fetch, and no arithmetic invented here.
  StoppageContext _stoppageFor(TournamentLiveMatch match) {
    final lines = [...match.inningsLines]
      ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final first = lines.firstOrNull;
    final latest = lines.lastOrNull;
    final inningsNumber = latest?.inningsNumber ?? 1;
    final chasing = inningsNumber >= 2 ? latest : null;

    final tournament =
        ref.read(tournamentDetailProvider(widget.tournamentId)).value;
    final originalOvers = tournament?.maxOvers ?? 20;

    return StoppageContext(
      originalOvers: originalOvers,
      originalQuota: RevisedTargetCalculator.quotaFor(originalOvers),
      inningsNumber: inningsNumber,
      firstInningsRuns: inningsNumber >= 2 ? first?.runs : null,
      chasingRuns: chasing?.runs ?? 0,
      chasingWickets: chasing?.wickets ?? 0,
      chasingLegalBalls: latest?.legalBalls ?? 0,
    );
  }

  Future<void> _onReviseConditions(TournamentLiveMatch match) async {
    final outcome = await showReviseConditionsSheet(
      context,
      match: match,
      stoppage: _stoppageFor(match),
    );
    if (outcome == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .reviseMatchConditions(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          revisedOvers: outcome.revisedOvers,
          bowlerQuota: outcome.bowlerQuota,
          revisedTarget: outcome.revisedTarget,
          method: outcome.method,
          reason: outcome.reason,
        );
    _reportIfFailed(
      ok,
      'Match reduced to ${outcome.revisedOvers} overs a side. '
      'Both captains and the scorer are notified.',
    );
  }

  Future<void> _onSuperOver(TournamentLiveMatch match) async {
    final outcome = await showSuperOverSheet(context, match: match);
    if (outcome == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .triggerSuperOver(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          batsFirstTeamId: outcome.batsFirstTeamId,
        );
    _reportIfFailed(
      ok,
      '${match.displayNameFor(outcome.batsFirstTeamId)} bats first in the '
      'super over.',
    );
  }

  Future<void> _onAutoAssignScorers() async {
    final filled = await ref
        .read(tournamentsControllerProvider.notifier)
        .autoAssignScorers(widget.tournamentId);
    if (!mounted) return;

    if (filled == null) {
      _reportIfFailed(false, '');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          filled == 0
              // Zero is a real answer, and it reads differently from a
              // failure — nobody was free, so say so.
              ? 'Nobody was free to take an unassigned fixture. Assign them '
                  'by hand from each card.'
              : filled == 1
                  ? 'One fixture now has a scorer.'
                  : '$filled fixtures now have a scorer.',
        ),
      ),
    );
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
    final tournament =
        ref.read(tournamentDetailProvider(widget.tournamentId)).asData?.value;
    final groundNames =
        tournament != null ? _groundNames(tournament) : <String>[];

    final result = await showModalBottomSheet<_RescheduleResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: CkColors.ink.withValues(alpha: 0.32),
      builder: (ctx) => _RescheduleMatchSheet(
        match: match,
        availableGrounds: groundNames.isEmpty
            ? [match.venue, 'Ground 1 · Model Town Club', 'Ground 2 · LCCA Ground']
            : groundNames,
      ),
    );
    if (result == null || !mounted) return;

    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .rescheduleMatch(
          tournamentId: widget.tournamentId,
          matchId: match.matchId,
          startTime: result.startTime,
          venue: result.venue,
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
      hasEntryFee: (tournament.entryFee ?? 0) > 0,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case ConsoleMenuAction.editSettings:
        context.push('/tournaments/${widget.tournamentId}/settings');
      case ConsoleMenuAction.feeLedger:
        context.push('/tournaments/${widget.tournamentId}/fees');
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

// ─── Artboard 27c-2: Sheet — Reschedule match ────────────────────────────────

class _RescheduleResult {
  const _RescheduleResult({required this.startTime, required this.venue});
  final DateTime startTime;
  final String venue;
}

class _RescheduleMatchSheet extends StatefulWidget {
  const _RescheduleMatchSheet({
    required this.match,
    required this.availableGrounds,
  });

  final TournamentLiveMatch match;
  final List<String> availableGrounds;

  @override
  State<_RescheduleMatchSheet> createState() => _RescheduleMatchSheetState();
}

class _RescheduleMatchSheetState extends State<_RescheduleMatchSheet> {
  late DateTime _selectedDate = DateTime(
    widget.match.scheduledStartTime.year,
    widget.match.scheduledStartTime.month,
    widget.match.scheduledStartTime.day,
  );
  late TimeOfDay _selectedTime =
      TimeOfDay.fromDateTime(widget.match.scheduledStartTime);
  late String _selectedGround = widget.availableGrounds.isNotEmpty
      ? (widget.availableGrounds.contains(widget.match.venue)
          ? widget.match.venue
          : widget.availableGrounds.first)
      : widget.match.venue;

  late final List<DateTime> _quickDates = _generateQuickDates();

  List<DateTime> _generateQuickDates() {
    final base = widget.match.scheduledStartTime;
    final list = <DateTime>[];
    list.add(DateTime(base.year, base.month, base.day));
    list.add(DateTime(base.year, base.month, base.day).add(const Duration(days: 1)));
    list.add(DateTime(base.year, base.month, base.day).add(const Duration(days: 7)));
    return list;
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _addExternalVenue() async {
    final controller = TextEditingController();
    final venue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CkColors.surface,
        title: Text('Add External Venue', style: CkType.display(fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Model Town Ground 3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: CkColors.ink,
              foregroundColor: CkColors.paper,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (venue != null && venue.isNotEmpty) {
      setState(() {
        if (!widget.availableGrounds.contains(venue)) {
          widget.availableGrounds.add(venue);
        }
        _selectedGround = venue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM');
    final match = widget.match;
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:'
        '${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: CkColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Change ground or time',
                style: CkType.display(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${match.round ?? 'Match'} · ${match.teamAName ?? 'Team A'} v ${match.teamBName ?? 'Team B'}',
                style: CkType.body(fontSize: 12, color: CkColors.muted),
              ),

              // Match date
              const SizedBox(height: 16),
              Text(
                'MATCH DATE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 7),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final d in _quickDates) ...[
                      InkWell(
                        onTap: () => setState(() => _selectedDate = d),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: DateUtils.isSameDay(_selectedDate, d)
                                ? CkColors.ink
                                : CkColors.paper,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: DateUtils.isSameDay(_selectedDate, d)
                                  ? CkColors.ink
                                  : CkColors.hairline,
                            ),
                          ),
                          child: Text(
                            dateFmt.format(d),
                            style: CkType.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DateUtils.isSameDay(_selectedDate, d)
                                  ? CkColors.paper
                                  : CkColors.ink2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 7),
              GestureDetector(
                onTap: _pickCustomDate,
                child: Text(
                  'Custom date… (${dateFmt.format(_selectedDate)})',
                  style: CkType.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),

              // Start time
              const SizedBox(height: 16),
              Text(
                'START TIME',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 7),
              InkWell(
                onTap: _pickCustomTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: CkColors.muted),
                      const SizedBox(width: 10),
                      Text(
                        timeStr,
                        style: CkType.mono(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'PKT',
                        style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in const ['09:00', '13:30', '15:00', '18:00']) ...[
                      InkWell(
                        onTap: () {
                          final parts = preset.split(':');
                          setState(() {
                            _selectedTime = TimeOfDay(
                              hour: int.parse(parts[0]),
                              minute: int.parse(parts[1]),
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: timeStr == preset ? CkColors.ink : CkColors.paper,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: timeStr == preset ? CkColors.ink : CkColors.hairline,
                            ),
                          ),
                          child: Text(
                            preset == '18:00' ? '18:00 night' : preset,
                            style: CkType.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: timeStr == preset ? CkColors.paper : CkColors.ink2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),

              // Select ground
              const SizedBox(height: 16),
              Text(
                'SELECT GROUND',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < widget.availableGrounds.length; i++) ...[
                      InkWell(
                        onTap: () => setState(() => _selectedGround = widget.availableGrounds[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedGround == widget.availableGrounds[i]
                                ? CkColors.paper
                                : Colors.transparent,
                            border: const Border(bottom: BorderSide(color: CkColors.hairline)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedGround == widget.availableGrounds[i]
                                        ? CkColors.ink
                                        : CkColors.soft,
                                    width: _selectedGround == widget.availableGrounds[i] ? 5 : 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.availableGrounds[i],
                                  style: CkType.display(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CkColors.ink,
                                  ),
                                ),
                              ),
                              if (i == 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CkColors.greenSurface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: CkColors.greenBorder),
                                  ),
                                  child: Text(
                                    'NO CLASHES',
                                    style: CkType.mono(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.08,
                                      color: CkColors.greenInk,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    InkWell(
                      onTap: _addExternalVenue,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: CkColors.soft),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.add, size: 10, color: CkColors.muted),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Add external venue',
                              style: CkType.display(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CkColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Push notification disclaimer callout
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: CkColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.creamBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: CkColors.amberDark),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Both team captains and assigned umpires will receive a push notification with the updated schedule.',
                        style: CkType.body(fontSize: 11.5, height: 1.45, color: CkColors.ink),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom buttons: Cancel + Save New Schedule
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 104,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CkColors.hairline),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: CkType.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final finalDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _selectedTime.hour,
                            _selectedTime.minute,
                          );
                          Navigator.of(context).pop(
                            _RescheduleResult(
                              startTime: finalDateTime,
                              venue: _selectedGround,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CkColors.ink,
                          foregroundColor: CkColors.paper,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save New Schedule',
                          style: CkType.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CkColors.paper,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Artboard 27j-2: Scorer PIN handover (Organiser side) ────────────────────

class _ScorerPinHandoverSheet extends StatefulWidget {
  const _ScorerPinHandoverSheet({required this.match});

  final TournamentLiveMatch match;

  @override
  State<_ScorerPinHandoverSheet> createState() => _ScorerPinHandoverSheetState();
}

class _ScorerPinHandoverSheetState extends State<_ScorerPinHandoverSheet> {
  late String _code = _generateCode();

  String _generateCode() {
    final hash = widget.match.matchId.hashCode.abs();
    return (hash % 9000 + 1000).toString();
  }

  void _regenerate() {
    setState(() {
      final rand = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
      _code = rand.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final timeStr =
        '${match.scheduledStartTime.hour.toString().padLeft(2, '0')}:'
        '${match.scheduledStartTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: CkColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '${match.round ?? 'Match'} digital scorer handover',
              style: CkType.display(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${match.teamAName ?? 'Team A'} v ${match.teamBName ?? 'Team B'}',
              style: CkType.body(fontSize: 12, color: CkColors.muted),
            ),
            const SizedBox(height: 3),
            Text(
              '$timeStr · ${match.venue}',
              style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w700, color: CkColors.ink),
            ),

            const SizedBox(height: 16),
            Text(
              '4-DIGIT MATCH CODE',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 9),

            // 4 Large Cream Monospace Boxes (Artboard 27j-2)
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  Expanded(
                    child: Container(
                      height: 74,
                      decoration: BoxDecoration(
                        color: CkColors.cream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CkColors.creamBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        i < _code.length ? _code[i] : '•',
                        style: CkType.mono(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Scorer enters this 4-digit code on their Matchday app to unlock live ball-by-ball scoring for this match. Code expires at the toss.',
              style: CkType.body(fontSize: 11.5, height: 1.5, color: CkColors.muted),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: CkColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CkColors.hairline),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code, size: 16, color: CkColors.ink),
                        const SizedBox(width: 7),
                        Text(
                          'Share QR',
                          style: CkType.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: CkColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: CkColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CkColors.hairline),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share, size: 16, color: CkColors.ink),
                        const SizedBox(width: 7),
                        Text(
                          'WhatsApp',
                          style: CkType.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: CkColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: CkColors.ink),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Organiser control remains yours. You can revoke scoring rights or take over the match at any time from Live Ops.',
                      style: CkType.body(fontSize: 11.5, height: 1.5, color: CkColors.ink2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 104,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CkColors.hairline),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600, color: CkColors.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _regenerate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CkColors.ink,
                        foregroundColor: CkColors.paper,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Regenerate Code',
                        style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600, color: CkColors.paper),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

