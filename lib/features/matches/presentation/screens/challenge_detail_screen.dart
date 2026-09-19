import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/domain/entities/team_membership.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_pool_application.dart';
import '../../domain/entities/match_request.dart';
import '../providers/match_pool_providers.dart';
import '../providers/matches_feed_providers.dart';
import '../providers/matches_providers.dart';
import '../providers/my_matches_providers.dart';
import '../widgets/host/host_detail_view.dart';
import '../widgets/host/host_sheets.dart';
import '../widgets/pool/pool_challenge_card.dart';
import '../widgets/withdraw_sheet.dart';

/// Receiver-side detail. Shows the sender's proposed terms, the head-to-head
/// proxy line, and a sticky bottom reply bar with Decline / Accept.
/// (Counter flow temporarily disabled — see commented-out blocks below.)
class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState
    extends ConsumerState<ChallengeDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchChallengeProvider(widget.requestId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: CkColors.ink)),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (req) => req == null
              ? const Center(child: Text('Challenge not found'))
              : _body(req),
        ),
      ),
    );
  }

  Widget _body(MatchRequest req) {
    final from = ref.watch(teamProvider(req.fromTeamId.value)).value;
    final to = req.toTeamId == null
        ? null
        : ref.watch(teamProvider(req.toTeamId!.value)).value;

    final memberships =
        ref.watch(currentUserTeamMembershipsProvider).value ??
            const <TeamMembership>[];
    final actingTeams = [
      for (final membership in memberships)
        if (membership.relationship.canSendChallenge) membership.team,
    ];
    final viewerIsSender = actingTeams.any((t) => t.id == req.fromTeamId);
    final isOpenPool = req.toTeamId == null;

    final actionable = req.isPending;

    // Watch applications if it's an open pool post
    final appsAsync = isOpenPool
        ? ref.watch(poolApplicationsProvider(req.id.value))
        : const AsyncValue.data(<MatchPoolApplication>[]);

    final applications = appsAsync.value ?? const <MatchPoolApplication>[];

    // The host's own open challenge is `Pool.dc.html` artboards 14 / 15 — a
    // screen of its own shape, not this one with different copy. The applicant
    // side still renders below until section D is ported.
    if (isOpenPool && viewerIsSender) {
      return HostDetailView(
        request: req,
        applications: applications,
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/my/pool-requests'),
        onShare: () => _onShareCode(req),
        onWithdraw: () => _onWithdrawChallenge(req, applications),
        onOpenApplicant: (app) => context.push(
          '/challenges/${req.id.value}/applicants/${app.id}',
        ),
      );
    }

    final myAppliedTeamIds = actingTeams.map((t) => t.id).toSet();
    final hasAlreadyApplied = applications.any(
      (app) =>
          myAppliedTeamIds.contains(app.applicantTeamId) &&
          app.status == PoolApplicationStatus.pending,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/my/matches'),
          kicker: viewerIsSender
              ? (isOpenPool ? 'OPEN CHALLENGE POSTED' : 'CHALLENGE SENT')
              : (isOpenPool ? 'OPEN MATCH POOL' : 'INCOMING CHALLENGE'),
          title: viewerIsSender
              ? (isOpenPool ? 'Open Pool Broadcast' : 'To ${to?.name ?? 'a team'}')
              : (isOpenPool
                  ? 'Challenge from ${from?.name ?? 'Open Challenger'}'
                  : 'From ${from?.name ?? 'a team'}'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            children: [
              _Hero(
                req: req,
                from: from,
                to: to,
                viewerIsSender: viewerIsSender,
                isOpenPool: isOpenPool,
              ),
              const _SectionLabel('Match spec'),
              _Spec(req: req),
              if (req.message != null && req.message!.isNotEmpty) ...[
                _SectionLabel(viewerIsSender
                    ? 'Your note'
                    : 'Note from ${_firstName(from?.name)}'),
                _Note(text: req.message!, sentAt: req.createdAt),
              ],
              // For Poster of Open Pool: Show Applicants List
              if (isOpenPool && viewerIsSender) ...[
                _SectionLabel('Applicants (${applications.length})'),
                if (applications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CkColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CkColors.hairline),
                    ),
                    child: Text(
                      'No teams have applied yet. Interested captains will appear here.',
                      style: CkType.body(fontSize: 13, color: CkColors.muted),
                    ),
                  )
                else
                  ...applications.map(
                    (app) => _ApplicantCard(
                      application: app,
                      isPoster: true,
                      req: req,
                      busy: _busy,
                      onAccept: () => _onAcceptApplication(app, req),
                      onReject: () => _onRejectApplication(app),
                    ),
                  ),
              ],
              if (!actionable) ...[
                const SizedBox(height: 14),
                _StatusBanner(status: req.status),
              ],
            ],
          ),
        ),
        if (actionable && viewerIsSender)
          _WithdrawBar(busy: _busy, onWithdraw: () => _onWithdraw(req))
        else if (actionable && isOpenPool)
          _ApplyBar(
            busy: _busy,
            hasAlreadyApplied: hasAlreadyApplied,
            onApply: () => _onApplyToPool(req),
          )
        else if (actionable)
          _ReplyBar(
            busy: _busy,
            isOpenPool: false,
            onDecline: () => _onDecline(req),
            onAccept: () => _onAcceptDirect(req),
          ),
      ],
    );
  }

  String _firstName(String? teamName) {
    if (teamName == null || teamName.isEmpty) return 'sender';
    return teamName.split(' ').first;
  }

  Future<void> _onApplyToPool(MatchRequest req) async {
    final memberships =
        ref.read(currentUserTeamMembershipsProvider).value ??
            const <TeamMembership>[];
    final eligibleTeams = [
      for (final membership in memberships)
        if (membership.relationship.canSendChallenge &&
            membership.team.id != req.fromTeamId)
          membership.team,
    ];
    if (eligibleTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to create or manage a team to apply.')),
      );
      return;
    }

    Team? selectedTeam;
    if (eligibleTeams.length == 1) {
      selectedTeam = eligibleTeams.first;
    } else {
      selectedTeam = await showModalBottomSheet<Team>(
        context: context,
        backgroundColor: CkColors.paper,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CkColors.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Your Team',
                    style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Which team are you applying with?',
                    style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: eligibleTeams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = eligibleTeams[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: CkColors.hairline),
                          ),
                          leading: Crest(
                            short: _short(t, fallback: 'TM'),
                            color: _teamColor(t.primaryColor),
                            size: 36,
                          ),
                          title: Text(
                            t.name,
                            style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            t.homeGround ?? 'Local Club',
                            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: CkColors.ink),
                          onTap: () => Navigator.of(ctx).pop(t),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (selectedTeam == null || !mounted) return;
    }

    final noteController = TextEditingController();
    final shouldApply = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Apply to Match Pool',
              style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Apply to play against ${ref.read(teamProvider(req.fromTeamId.value)).value?.name ?? 'host'} with ${selectedTeam!.name}. The host captain will review and accept.',
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Optional message to host captain',
                hintText: 'e.g. We have our full squad ready on time!',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Submit Application'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (shouldApply != true || !mounted) return;

    setState(() => _busy = true);
    final result = await ref.read(matchPoolRepositoryProvider).applyToMatchPool(
          requestId: req.id,
          teamId: selectedTeam.id,
          message: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted! Host captain has been notified.')),
        );
        ref.invalidate(poolApplicationsProvider(req.id.value));
        ref.invalidate(matchesFeedProvider);
      },
    );
  }

  Future<void> _onAcceptApplication(
    MatchPoolApplication app,
    MatchRequest req,
  ) async {
    final appTeam = ref.read(teamProvider(app.applicantTeamId.value)).value;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Accept Applicant & Lock Match?',
              style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Accepting ${appTeam?.name ?? 'this team'} will immediately create the match fixture and automatically reject all other pending applications for this post.',
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.green,
                      foregroundColor: CkColors.paper,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Accept & Lock Match'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    final result = await ref.read(matchPoolRepositoryProvider).acceptPoolApplication(
          applicationId: app.id,
        );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (matchId) {
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(myMatchesViewProvider);
        ref.invalidate(matchesFeedProvider);
        ref.invalidate(poolApplicationsProvider(req.id.value));
        ref.invalidate(matchChallengeProvider(req.id.value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match created successfully!')),
        );
        context.go('/matches/${matchId.value}');
      },
    );
  }

  Future<void> _onRejectApplication(MatchPoolApplication app) async {
    setState(() => _busy = true);
    final result = await ref.read(matchPoolRepositoryProvider).rejectPoolApplication(
          applicationId: app.id,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(poolApplicationsProvider(app.requestId));
      },
    );
  }

  Future<void> _onAcceptDirect(MatchRequest req) async {
    final fromTeam = ref.read(teamProvider(req.fromTeamId.value)).value;
    final toTeam = req.toTeamId == null
        ? null
        : ref.read(teamProvider(req.toTeamId!.value)).value;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AcceptConfirmSheet(
        fromName: fromTeam?.name ?? 'Them',
        toName: toTeam?.name ?? 'You',
        startTime: req.effectiveStartTime,
        venue: req.effectiveVenue,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await ref
        .read(matchesRepositoryProvider)
        .acceptMatchChallenge(
          requestId: req.id,
          toTeamId: toTeam?.id,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(myMatchesViewProvider);
        ref.invalidate(matchesFeedProvider);
        context.go('/my/matches');
      },
    );
  }

  Future<void> _onDecline(MatchRequest req) async {
    final picked = await showModalBottomSheet<_DeclineResult>(
      context: context,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => const _DeclineSheet(),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(matchesRepositoryProvider).declineMatchChallenge(
          requestId: req.id,
          decisionReason: picked.reason,
          decisionNote: picked.note,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        context.go('/my/matches');
      },
    );
  }

  /// Artboard 14/15 header action — hand the code to a captain directly.
  Future<void> _onShareCode(MatchRequest req) async {
    final code = req.shareCode;
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This challenge has no share code.')),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text: 'Join our match on matchday — share code $code',
      ),
    );
  }

  /// Artboard 19. Distinct from [_onWithdraw]: that sheet is the sender
  /// withdrawing a *targeted* challenge, this one pulls an open challenge off
  /// the board and has to say how many applicants it strands.
  Future<void> _onWithdrawChallenge(
    MatchRequest req,
    List<MatchPoolApplication> applications,
  ) async {
    final hostTeam = ref.read(teamProvider(req.fromTeamId.value)).value;
    final pending = applications
        .where((a) => a.status == PoolApplicationStatus.pending)
        .length;

    final summary = [
      if (req.proposedFormat?.oversPerInnings case final o? when o > 0)
        '$o ov',
      if (req.proposedStartTime case final start?)
        poolStartLabel(start).replaceFirst(' · ', ' '),
      if (pending > 0) '$pending pending',
    ].join(' · ');

    final confirmed = await showWithdrawChallengeSheet(
      context,
      hostTeam: hostTeam,
      summary: summary,
      pendingApplicants: pending,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final res = await ref
        .read(matchesRepositoryProvider)
        .withdrawMatchChallenge(requestId: req.id);
    if (!mounted) return;
    setState(() => _busy = false);

    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(myChallengesProvider);
        ref.invalidate(matchChallengeProvider(widget.requestId));
        context.canPop() ? context.pop() : context.go('/my/pool-requests');
      },
    );
  }

  Future<void> _onWithdraw(MatchRequest req) async {
    final to = req.toTeamId == null
        ? null
        : ref.read(teamProvider(req.toTeamId!.value)).value;
    final result = await showModalBottomSheet<WithdrawResult>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WithdrawSheet(opponentName: to?.name),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    final res = await ref.read(matchesRepositoryProvider).withdrawMatchChallenge(
          requestId: req.id,
          decisionNote: result.note,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(myMatchesViewProvider);
        ref.invalidate(matchChallengeProvider(widget.requestId));
        context.canPop()
            ? context.pop()
            : context.go('/my/matches');
      },
    );
  }
}

// ─── Atoms ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.kicker,
    required this.title,
  });
  final VoidCallback onBack;
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.only(top: 2, right: 8, bottom: 4, left: 0),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: CkColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kicker.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: CkColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Faithful port of the design's match hero: header strip with red
/// CHALLENGE pill + date/time mono, 3-col crest row (team / vs / team)
/// with team-name + "captain" caption underneath, and the H2H footnote
/// row split by a 1px dashed top border.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.req,
    required this.from,
    required this.to,
    this.viewerIsSender = false,
    this.isOpenPool = false,
  });
  final MatchRequest req;
  final Team? from;
  final Team? to;

  /// When true, the "You" label sits on the from-team (left) column and the
  /// opponent goes right. Receiver view (false) keeps the original layout.
  final bool viewerIsSender;
  final bool isOpenPool;

  @override
  Widget build(BuildContext context) {
    final start = req.effectiveStartTime;
    final expiry = req.status == MatchRequestStatus.countered
        ? req.counterExpiresAt
        : (req.proposalExpiresAt ?? req.codeExpiresAt);
    final expiresLabel = expiry == null
        ? (isOpenPool ? 'OPEN MATCH POOL' : 'CHALLENGE')
        : (isOpenPool
            ? 'OPEN POOL · EXPIRES ${_humanRemaining(expiry)}'
            : 'CHALLENGE · EXPIRES ${_humanRemaining(expiry)}');
    final whenLabel = start == null
        ? ''
        : '${_dowShort(start)} ${start.day} · ${_hhmm(start)}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Header strip — red/green pill left, mono date right.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: CkColors.paper2,
              border: Border(
                bottom: BorderSide(color: CkColors.hairline),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOpenPool ? CkColors.green : CkColors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      expiresLabel,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  whenLabel.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          // Crest row — 3 columns: team / vs / team.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: _CrestColumn(
                    team: from,
                    fallback: 'A',
                    overrideName: viewerIsSender ? 'You' : null,
                    captain: viewerIsSender ? 'You · cap' : 'Captain',
                  ),
                ),
                Text(
                  'vs',
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CkColors.muted,
                    letterSpacing: -0.025,
                  ),
                ),
                Expanded(
                  child: _CrestColumn(
                    team: to,
                    fallback: isOpenPool ? '?' : 'B',
                    overrideName: viewerIsSender
                        ? (isOpenPool ? 'Open Pool' : null)
                        : (isOpenPool ? 'Open Slot (You)' : 'You'),
                    captain: viewerIsSender
                        ? (isOpenPool ? 'Anyone' : 'Captain')
                        : 'Your Team',
                  ),
                ),
              ],
            ),
          ),
          // H2H footnote — dashed top border, ink2 + mono.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: CkColors.hairline,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: CkType.body(
                        fontSize: 11.5,
                        color: CkColors.ink2,
                      ),
                      children: const [
                        TextSpan(text: 'Head-to-head · '),
                        TextSpan(
                          text: 'First meeting',
                          style: TextStyle(
                            color: CkColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'NEW RIVAL',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrestColumn extends StatelessWidget {
  const _CrestColumn({
    required this.team,
    required this.fallback,
    required this.captain,
    this.overrideName,
  });
  final Team? team;
  final String fallback;
  final String captain;
  final String? overrideName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _teamColor(team?.primaryColor),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            _short(team, fallback: fallback),
            style: CkType.display(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CkColors.paper,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          overrideName ?? team?.name ?? 'Team',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.display(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          captain,
          style: CkType.body(fontSize: 11, color: CkColors.muted),
        ),
      ],
    );
  }
}

/// Spec list — 5 rows separated by 1px hairline, mono key (60px wide) +
/// body value. Mirrors the design's bordered card.
class _Spec extends StatelessWidget {
  const _Spec({required this.req});
  final MatchRequest req;

  @override
  Widget build(BuildContext context) {
    final f = req.effectiveFormat;
    final start = req.effectiveStartTime;
    final rows = <(String, String)>[
      if (f != null)
        (
          'Format',
          'T${f.oversPerInnings} · ${_ballName(f.ballType)} · '
              '${f.maxOversPerBowler} ov/bowler',
        ),
      if (start != null) ('When', '${_human(start)} PKT'),
      if (req.effectiveVenue != null) ('Venue', req.effectiveVenue!),
      const ('Stakes', 'Friendly · no pot'),
      const ('Type', 'Friendly'),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                border: Border(
                  bottom: i < rows.length - 1
                      ? const BorderSide(color: CkColors.hairline)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        rows[i].$1.toUpperCase(),
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: CkType.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

/// Sender's note — paper2 card with 3px red left border, italic quote,
/// mono SENT timestamp footer.
class _Note extends StatelessWidget {
  const _Note({required this.text, required this.sentAt});
  final String text;
  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    // Non-uniform border (red left stripe) → round via ClipRRect, NOT a
    // borderRadius on the BoxDecoration (which throws at paint time for a
    // non-uniform border and blanks the note).
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: CkColors.paper2,
          border: Border(
            left: BorderSide(color: CkColors.red, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$text"',
              style: CkType.body(
                fontSize: 13.5,
                color: CkColors.ink,
                height: 1.5,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            Text(
              'SENT ${_hhmm(sentAt)}'.toUpperCase(),
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final MatchRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchRequestStatus.accepted => ('Accepted — match created.', CkColors.green),
      MatchRequestStatus.declined => ('Declined.', CkColors.red),
      MatchRequestStatus.cancelled => ('Withdrawn by sender.', CkColors.muted),
      MatchRequestStatus.expired => ('Expired — too late to act.', CkColors.muted),
      _ => ('No longer actionable.', CkColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

/// Sticky bar for open pool browsing captains: "Apply to Play →" or "Application Pending".
class _ApplyBar extends StatelessWidget {
  const _ApplyBar({
    required this.busy,
    required this.hasAlreadyApplied,
    required this.onApply,
  });
  final bool busy;
  final bool hasAlreadyApplied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: hasAlreadyApplied
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.hairline,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 18, color: CkColors.muted),
                  const SizedBox(width: 8),
                  Text(
                    'Application Pending Host Review',
                    style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700, color: CkColors.muted),
                  ),
                ],
              ),
            )
          : _ReplyButton(
              label: 'Apply to Play →',
              onTap: busy ? null : onApply,
              primary: true,
              busy: busy,
            ),
    );
  }
}

/// Card showing an applicant team for the open pool host.
class _ApplicantCard extends ConsumerWidget {
  const _ApplicantCard({
    required this.application,
    required this.isPoster,
    required this.req,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final MatchPoolApplication application;
  final bool isPoster;
  final MatchRequest req;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamProvider(application.applicantTeamId.value)).value;
    final isPending = application.status == PoolApplicationStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: application.status == PoolApplicationStatus.accepted
              ? CkColors.green
              : CkColors.hairline,
          width: application.status == PoolApplicationStatus.accepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Crest(
                short: _short(team, fallback: 'TM'),
                color: _teamColor(team?.primaryColor),
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team?.name ?? 'Team Applicant',
                      style: CkType.display(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team?.homeGround ?? 'Local Club',
                      style: CkType.body(fontSize: 12, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: application.status == PoolApplicationStatus.accepted
                      ? CkColors.green.withValues(alpha: 0.12)
                      : application.status == PoolApplicationStatus.rejected
                          ? CkColors.red.withValues(alpha: 0.12)
                          : CkColors.ink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  application.status == PoolApplicationStatus.accepted
                      ? 'ACCEPTED'
                      : application.status == PoolApplicationStatus.rejected
                          ? 'DECLINED'
                          : 'APPLICANT',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: application.status == PoolApplicationStatus.accepted
                        ? CkColors.green
                        : application.status == PoolApplicationStatus.rejected
                            ? CkColors.red
                            : CkColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (application.message != null && application.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CkColors.hairline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '“${application.message}”',
                style: CkType.body(fontSize: 12.5, color: CkColors.ink).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (isPoster && isPending && req.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CkColors.red,
                      side: const BorderSide(color: CkColors.hairline),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: busy ? null : onReject,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.green,
                      foregroundColor: CkColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: busy ? null : onAccept,
                    child: const Text(
                      'Accept & Lock Match',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Sticky reply bar — Decline (red text) + ink-filled Accept (or single Claim Match button for open pool).
class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.busy,
    required this.onDecline,
    required this.onAccept,
    this.isOpenPool = false,
  });
  final bool busy;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final bool isOpenPool;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          if (!isOpenPool) ...[
            Expanded(
              flex: 10,
              child: _ReplyButton(
                label: 'Decline',
                onTap: busy ? null : onDecline,
                foreground: CkColors.red,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: isOpenPool ? 1 : 16,
            child: _ReplyButton(
              label: isOpenPool ? 'Accept & Claim Match →' : 'Accept →',
              onTap: busy ? null : onAccept,
              primary: true,
              busy: busy,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky sender bar — a single ghost-red "Withdraw challenge" button shown
/// while the sender's own request is still pending/countered.
class _WithdrawBar extends StatelessWidget {
  const _WithdrawBar({required this.busy, required this.onWithdraw});
  final bool busy;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: _ReplyButton(
        label: 'Withdraw challenge',
        onTap: busy ? null : onWithdraw,
        foreground: CkColors.red,
      ),
    );
  }
}

class _ReplyButton extends StatelessWidget {
  const _ReplyButton({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.busy = false,
    this.foreground = CkColors.ink,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool busy;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? CkColors.ink : CkColors.paper;
    final fg = primary ? CkColors.paper : foreground;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: primary
              ? null
              : Border.all(color: CkColors.line, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CkColors.paper,
                ),
              )
            : Text(
                label,
                style: CkType.body(
                  fontSize: primary ? 14 : 13,
                  fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
      ),
    );
  }
}

/// Accept Challenge Flow · Step 5 confirmation sheet. Green "FINAL STEP"
/// pill, display headline, body copy explaining the 12h renegotiation
/// window, stacked Yes-accept (primary) + Cancel (ghost) buttons.
class _AcceptConfirmSheet extends StatelessWidget {
  const _AcceptConfirmSheet({
    required this.fromName,
    required this.toName,
    required this.startTime,
    required this.venue,
  });

  final String fromName;
  final String toName;
  final DateTime? startTime;
  final String? venue;

  @override
  Widget build(BuildContext context) {
    final headline = 'Accept $fromName vs $toName?';
    final timeLabel = startTime == null
        ? ''
        : '${_dowShort(startTime!)} ${startTime!.day} · ${_hhmm(startTime!)}';
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: CkColors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FINAL STEP',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.paper,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                headline,
                style: CkType.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Both teams will be committed. Captains can renegotiate '
                'up to 12h before the toss — after that the slot is yours.',
                style: CkType.body(
                  fontSize: 13.5,
                  color: CkColors.ink2,
                  height: 1.5,
                ),
              ),
              if (startTime != null || venue != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    border: Border.all(color: CkColors.hairline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (timeLabel.isNotEmpty)
                        Text(timeLabel,
                            style: CkType.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.02,
                            )),
                      if (venue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            venue!,
                            style: CkType.body(
                                fontSize: 12, color: CkColors.muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CkColors.ink,
                    foregroundColor: CkColors.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      startTime == null
                          ? 'Yes, accept ✓'
                          : 'Yes, accept · $timeLabel ✓',
                      style: CkType.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: CkColors.muted,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Format a "human remaining" label like "47H" / "3D" / "12M" for the
/// CHALLENGE pill. Falls back to "expired" past zero.
String _humanRemaining(DateTime expiry) {
  final remaining = expiry.difference(DateTime.now());
  if (remaining.isNegative) return 'EXPIRED';
  if (remaining.inHours < 1) return '${remaining.inMinutes}M';
  if (remaining.inHours < 48) return '${remaining.inHours}H';
  return '${remaining.inDays}D';
}

String _dowShort(DateTime t) =>
    const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][t.weekday - 1];

class _DeclineResult {
  const _DeclineResult({required this.reason, this.note});
  final DeclineReason reason;
  final String? note;
}

class _DeclineSheet extends StatefulWidget {
  const _DeclineSheet();

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  DeclineReason _selected = DeclineReason.busy;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: CkColors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('DECLINE',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: CkColors.paper,
                      )),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Why are you passing?',
                style: CkType.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                ),
              ),
              const SizedBox(height: 14),
              for (final r in DeclineReason.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selected = r),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        border: Border.all(
                          color: _selected == r
                              ? CkColors.ink
                              : CkColors.hairline,
                          width: _selected == r ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(
                          _selected == r
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color:
                              _selected == r ? CkColors.ink : CkColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r.label,
                              style: CkType.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ]),
                    ),
                  ),
                ),
              if (_selected == DeclineReason.other) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional note',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: CkColors.hairline),
                    ),
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CkColors.red,
                    foregroundColor: CkColors.paper,
                  ),
                  onPressed: () => Navigator.of(context).pop(_DeclineResult(
                    reason: _selected,
                    note: _noteCtrl.text.trim().isEmpty
                        ? null
                        : _noteCtrl.text.trim(),
                  )),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Decline & send reason'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

String _short(Team? t, {required String fallback}) {
  if (t == null) return fallback;
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  final letters = t.name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join();
  return letters.isEmpty ? fallback : letters.toUpperCase();
}

Color _teamColor(String? hex) {
  if (hex == null || hex.isEmpty) return CkColors.muted;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(0xFF000000 | n);
  } else if (cleaned.length == 8) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(n);
  }
  return CkColors.muted;
}

String _dow(DateTime t) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _ballName(MatchBallType b) {
  switch (b) {
    case MatchBallType.leather:
      return 'Hardball';
    case MatchBallType.tape:
      return 'Tape ball';
    case MatchBallType.tennis:
      return 'Tennis';
  }
}

String _human(DateTime t) => '${_dow(t)} ${t.day} · ${_hhmm(t)}';
