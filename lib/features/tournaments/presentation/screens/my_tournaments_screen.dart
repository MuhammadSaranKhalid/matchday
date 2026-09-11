import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_push_nav.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/my_tournament_entry.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournaments_providers.dart';
import '../widgets/hub_tournament_cards.dart';
import '../widgets/tournament_shimmers.dart';

/// My Tournaments — artboards 02–05.
///
/// Reached from the drawer, so it is a pushed screen: a 56pt nav and no bottom
/// tabs. Urgency is entirely cream — deadlines, pending counts, the amber
/// timer glyph. The only red is a LIVE pill and its score.
class MyTournamentsScreen extends ConsumerStatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  ConsumerState<MyTournamentsScreen> createState() =>
      _MyTournamentsScreenState();
}

enum _Relation { organizing, playing, following }

class _MyTournamentsScreenState extends ConsumerState<MyTournamentsScreen> {
  _Relation _relation = _Relation.organizing;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserStreamProvider).value?.id.value;
    final mineAsync = ref.watch(myTournamentsProvider);
    final playingAsync = ref.watch(myPlayingTournamentsProvider);
    final draftAsync = ref.watch(tournamentDraftStreamProvider);

    final all = mineAsync.value ?? const <Tournament>[];
    final playing = playingAsync.value ?? const <MyTournamentEntry>[];
    final draft = draftAsync.value;

    final organizing = userId == null
        ? const <Tournament>[]
        : all
            .where((t) =>
                t.isOrganizedBy(userId) && t.status != TournamentStatus.draft)
            .toList();
    final drafts = userId == null
        ? const <Tournament>[]
        : all
            .where((t) =>
                t.isOrganizedBy(userId) && t.status == TournamentStatus.draft)
            .toList();
    final following = userId == null
        ? all
        : all.where((t) => !t.isOrganizedBy(userId)).toList();

    final loading = mineAsync.isLoading && !mineAsync.hasValue;

    // Single-relationship rule: with nothing in any bucket the segmented
    // control is not rendered at all — three empty tabs would be three dead
    // ends — and the nav loses its Create pill, because the body owns that CTA.
    final isFirstRun = !loading &&
        organizing.isEmpty &&
        drafts.isEmpty &&
        playing.isEmpty &&
        following.isEmpty &&
        (draft == null || draft.isEmpty);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _Nav(showCreate: !isFirstRun),
            if (!isFirstRun)
              _Segmented(
                relation: _relation,
                organizingCount: organizing.length + drafts.length,
                playingCount: playing.length,
                followingCount: following.length,
                onChanged: (r) => setState(() => _relation = r),
              ),
            Expanded(
              child: loading
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        TournamentCardShimmer(),
                        SizedBox(height: 12),
                        TournamentCardShimmer(),
                      ],
                    )
                  : isFirstRun
                      ? const _FirstRun()
                      : _body(
                          organizing: organizing,
                          drafts: drafts,
                          playing: playing,
                          following: following,
                          localDraft: draft,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body({
    required List<Tournament> organizing,
    required List<Tournament> drafts,
    required List<MyTournamentEntry> playing,
    required List<Tournament> following,
    required Map<String, dynamic>? localDraft,
  }) =>
      switch (_relation) {
        _Relation.organizing => _OrganizingList(
            tournaments: organizing,
            drafts: drafts,
            localDraft: localDraft,
          ),
        _Relation.playing => _PlayingList(entries: playing),
        _Relation.following => _FollowingList(tournaments: following),
      };
}

// ─── Chrome ──────────────────────────────────────────────────────────────────

class _Nav extends StatelessWidget {
  const _Nav({required this.showCreate});

  final bool showCreate;

  @override
  Widget build(BuildContext context) {
    return CkPushNav(
      title: 'My Tournaments',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/home'),
      action: showCreate
          ? CkNavPill(
              label: 'Create',
              onTap: () => context.push('/tournaments/create'),
            )
          : null,
    );
  }
}

/// A recessed segmented control, not a TabBar — the hub switches a filter,
/// it does not navigate.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.relation,
    required this.organizingCount,
    required this.playingCount,
    required this.followingCount,
    required this.onChanged,
  });

  final _Relation relation;
  final int organizingCount;
  final int playingCount;
  final int followingCount;
  final ValueChanged<_Relation> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(CkRadii.sm),
        ),
        child: Row(
          children: [
            _segment('Organizing ($organizingCount)', _Relation.organizing),
            _segment('Playing ($playingCount)', _Relation.playing),
            _segment('Following ($followingCount)', _Relation.following),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, _Relation value) {
    final selected = relation == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: selected
              ? BoxDecoration(
                  color: CkColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A281E0F),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                )
              : null,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text.toUpperCase(),
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
          ),
        ),
      );
}

// ─── Organizing (artboard 02) ────────────────────────────────────────────────

class _OrganizingList extends ConsumerWidget {
  const _OrganizingList({
    required this.tournaments,
    required this.drafts,
    required this.localDraft,
  });

  final List<Tournament> tournaments;
  final List<Tournament> drafts;
  final Map<String, dynamic>? localDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tournaments.isEmpty && drafts.isEmpty && localDraft == null) {
      return const _BucketEmpty(
        title: 'Nothing to organise yet',
        body: 'Run a weekend cup for your club and it will appear here with '
            'its applications, draw and matchday controls.',
        action: 'Create a Tournament',
        route: '/tournaments/create',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (tournaments.isNotEmpty) ...[
          const _Eyebrow('Organizing (active)'),
          for (final t in tournaments) ...[
            _OrganizingCard(tournament: t),
            const SizedBox(height: 12),
          ],
        ],
        if (drafts.isNotEmpty || localDraft != null) ...[
          const SizedBox(height: 8),
          _Eyebrow(
            'Drafts (${drafts.length + (localDraft == null ? 0 : 1)})',
          ),
          if (localDraft != null) _LocalDraftCard(draft: localDraft!),
          for (final t in drafts) ...[
            const SizedBox(height: 12),
            HubCard(
              name: t.name,
              meta: 'Last edited ${_ago(t.updatedAt)}',
              pill: const HubStatusPill(
                status: TournamentStatus.draft,
                dashed: true,
              ),
              dashed: true,
              onTap: () => context.push('/tournaments/create'),
              sections: const [
                HubFooter(note: 'Not published', action: 'Resume Setup'),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _OrganizingCard extends ConsumerWidget {
  const _OrganizingCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tournament;
    final isLive = t.status == TournamentStatus.live;
    // Only a live cup pays for the extra read; the board is what carries the
    // featured match and its score.
    final board = isLive
        ? ref.watch(tournamentLiveBoardProvider(t.id)).value
        : null;
    final featured = board
        ?.where((m) => m.isLive)
        .cast<TournamentLiveMatch?>()
        .firstWhere((_) => true, orElse: () => null);
    final regsAsync = ref.watch(tournamentRegistrationsProvider(t.id));
    final regs = regsAsync.value ?? const [];
    final approved = regs.where((r) => r.isApproved).length;
    // Only what fits in the draw is actionable; the rest are waitlisted. The
    // console badge counts the same way, and the two must agree.
    final pendingAll = regs.where((r) => r.isPending).length;
    final pending = t.maxTeams == null
        ? pendingAll
        : (t.maxTeams! - approved).clamp(0, pendingAll);
    final paid = regs
        .where((r) =>
            r.isApproved && (r.paymentStatus ?? '').toLowerCase() == 'paid')
        .length;

    final chips = <Widget>[
      if (t.status == TournamentStatus.registration &&
          t.registrationDeadline != null)
        HubCreamChip(
          icon: Icons.schedule,
          label: _closesIn(t.registrationDeadline!),
        ),
      if (pending > 0)
        HubCreamChip(
          label: pending == 1
              ? '1 application waiting'
              : '$pending applications waiting',
        ),
    ];

    return HubCard(
      name: t.name,
      meta: _meta(t),
      pill: HubStatusPill(status: t.status),
      onTap: () => context.push('/tournaments/${t.id}/console'),
      sections: [
        if (isLive)
          HubLiveStrip(
            matchup: featured == null
                ? 'Matches in progress'
                : '${featured.displayNameFor(featured.teamAId)} v '
                    '${featured.displayNameFor(featured.teamBId)}',
            score: _liveScore(featured) ?? 'LIVE',
          )
        else if (t.maxTeams != null)
          HubProgress(
            label: 'Teams approved',
            value: approved,
            total: t.maxTeams!,
          ),
        if (chips.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        HubFooter(
          note: isLive && board != null
              ? _liveNote(board)
              : hubFeeNote(t, paidCount: (t.entryFee ?? 0) > 0 ? paid : null),
          action: 'Manage Console',
        ),
      ],
    );
  }
}

/// The unpublished wizard draft held in local storage.
class _LocalDraftCard extends StatelessWidget {
  const _LocalDraftCard({required this.draft});

  final Map<String, dynamic> draft;

  @override
  Widget build(BuildContext context) {
    final step = (draft['step'] as int? ?? 0) + 1;
    final name = (draft['name'] as String?)?.trim();

    return HubCard(
      name: name == null || name.isEmpty ? 'Untitled tournament' : name,
      meta: 'Not published yet',
      pill: const HubStatusPill(status: TournamentStatus.draft, dashed: true),
      dashed: true,
      onTap: () => context.push('/tournaments/create'),
      sections: [
        HubFooter(
          note: '$step of 6 steps complete',
          action: 'Resume Setup',
        ),
      ],
    );
  }
}

// ─── Playing (artboard 03) ───────────────────────────────────────────────────

class _PlayingList extends StatelessWidget {
  const _PlayingList({required this.entries});

  final List<MyTournamentEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _BucketEmpty(
        title: 'Not playing in any cups',
        body: 'Register one of your teams into an open tournament and it will '
            'show up here with your fixtures and squad state.',
        action: 'Find Tournaments',
        route: '/explore',
      );
    }

    final current = entries.where((e) => e.isCurrent).toList();
    final awaiting = entries.where((e) => e.isAwaitingApproval).toList();
    final past = entries.where((e) => e.isPast).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (current.isNotEmpty) ...[
          const _Eyebrow('Currently playing'),
          for (final e in current) ...[
            _PlayingCard(entry: e),
            const SizedBox(height: 12),
          ],
        ],
        if (awaiting.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Eyebrow('Awaiting approval (${awaiting.length})'),
          for (final e in awaiting) ...[
            _PlayingCard(entry: e),
            const SizedBox(height: 12),
          ],
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Eyebrow('Past (${past.length})'),
          for (final e in past) ...[
            _PlayingCard(entry: e),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _PlayingCard extends StatelessWidget {
  const _PlayingCard({required this.entry});

  final MyTournamentEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = entry.tournament;
    final reg = entry.registration;

    return HubCard(
      name: t.name,
      meta: _meta(t),
      pill: HubStatusPill(status: t.status),
      // No Manage Console anywhere on this card: that verb belongs to
      // organisers and is hidden here, not disabled.
      onTap: () => context.push('/tournaments/${t.id}'),
      sections: [
        if (entry.isAwaitingApproval)
          _AwaitingBody(entry: entry)
        else
          HubPlayingBody(entry: entry),
        if (entry.isPast)
          HubFooter(
            note: '${reg.teamName ?? 'Your team'} · '
                '${t.status == TournamentStatus.completed ? 'completed' : t.status.label}',
          ),
      ],
    );
  }
}

class _AwaitingBody extends StatelessWidget {
  const _AwaitingBody({required this.entry});

  final MyTournamentEntry entry;

  @override
  Widget build(BuildContext context) {
    final reg = entry.registration;
    final fee = entry.tournament.entryFee ?? 0;
    final money = NumberFormat.decimalPattern();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const HubNeutralChip(label: 'Submitted · under review'),
            if (fee > 0 &&
                (reg.paymentStatus ?? '').toLowerCase() != 'paid')
              const HubCreamChip(label: 'Pending payment'),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Squad of ${reg.squad.length} submitted ${_ago(reg.registeredAt)}.'
          '${fee > 0 ? ' The organiser marks the PKR ${money.format(fee)} fee as paid once you hand it over.' : ''}',
          style: CkType.body(
            fontSize: 11.5,
            height: 1.5,
            color: CkColors.muted,
          ),
        ),
      ],
    );
  }
}

// ─── Following (artboard 04) ─────────────────────────────────────────────────

class _FollowingList extends StatelessWidget {
  const _FollowingList({required this.tournaments});

  final List<Tournament> tournaments;

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return const _BucketEmpty(
        title: 'Not following any cups',
        body: 'Follow a tournament to keep its live scores and standings in '
            'one place.',
        action: 'Browse Tournaments',
        route: '/explore',
      );
    }

    final liveAndUpcoming = tournaments
        .where((t) => t.status != TournamentStatus.completed)
        .toList();
    final done = tournaments
        .where((t) => t.status == TournamentStatus.completed)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (liveAndUpcoming.isNotEmpty) ...[
          const _Eyebrow('Live & upcoming'),
          for (final t in liveAndUpcoming) ...[
            _FollowingCard(tournament: t),
            const SizedBox(height: 12),
          ],
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _Eyebrow('Completed'),
          for (final t in done) ...[
            _FollowingCard(tournament: t),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 8),
        // The discovery nudge sits after the list, so it never competes with
        // content.
        const _DiscoveryNudge(),
      ],
    );
  }
}

class _FollowingCard extends StatelessWidget {
  const _FollowingCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final t = tournament;

    return HubCard(
      name: t.name,
      meta: _meta(t),
      pill: HubStatusPill(status: t.status),
      onTap: () => context.push('/tournaments/${t.id}'),
      // A spectator sees no verbs at all — the card carries only what is
      // happening.
      sections: [
        if (t.status == TournamentStatus.live)
          const HubLiveStrip(matchup: 'Matches in progress', score: 'LIVE')
        else
          HubFooter(note: _followingNote(t)),
      ],
    );
  }

  String _followingNote(Tournament t) {
    final fmt = DateFormat('d MMM');
    return switch (t.status) {
      TournamentStatus.registration => t.registrationDeadline == null
          ? 'Registration open'
          : 'Registration closes ${fmt.format(t.registrationDeadline!)}',
      TournamentStatus.upcoming => t.startDate == null
          ? 'Starting soon'
          : 'Starts ${fmt.format(t.startDate!)} · '
              '${t.approvedTeamsCount}${t.maxTeams == null ? '' : '/${t.maxTeams}'} teams in',
      TournamentStatus.completed => 'Completed',
      _ => t.status.label,
    };
  }
}

class _DiscoveryNudge extends StatelessWidget {
  const _DiscoveryNudge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Looking for local cups to join?',
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Find tournaments taking registrations near you.',
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => context.push('/explore'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CkColors.ink,
              side: const BorderSide(color: CkColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CkRadii.sm),
              ),
            ),
            child: Text(
              'Browse',
              style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty states ────────────────────────────────────────────────────────────

/// Artboard 05 — nothing in any bucket.
class _FirstRun extends StatelessWidget {
  const _FirstRun();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'No tournaments yet',
            textAlign: TextAlign.center,
            style: CkType.display(fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            'Run a weekend cup for your club, or follow one nearby. Everything '
            'you organise, play in or follow will collect here.',
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 13.5,
              height: 1.55,
              color: CkColors.muted,
            ),
          ),
          const Spacer(),
          // The one place the sticky bar carries a second action; the
          // secondary is a hairline ghost, never a second fill.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/tournaments/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CkColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CkRadii.md),
                ),
              ),
              child: Text(
                'Create a Tournament',
                style: CkType.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CkColors.paper,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/explore'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CkColors.ink,
                side: const BorderSide(color: CkColors.line),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CkRadii.md),
                ),
              ),
              child: Text(
                'Browse Public Tournaments',
                style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One bucket empty while others have content — quieter than first run.
class _BucketEmpty extends StatelessWidget {
  const _BucketEmpty({
    required this.title,
    required this.body,
    required this.action,
    required this.route,
  });

  final String title;
  final String body;
  final String action;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: CkType.display(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                height: 1.55,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => context.push(route),
              style: OutlinedButton.styleFrom(
                foregroundColor: CkColors.ink,
                side: const BorderSide(color: CkColors.line),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CkRadii.sm),
                ),
              ),
              child: Text(
                action,
                style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

/// The featured match's current score — the innings actually batting.
String? _liveScore(TournamentLiveMatch? match) {
  if (match == null || match.inningsLines.isEmpty) return null;
  final latest = match.inningsLines.reduce(
    (a, b) => b.inningsNumber > a.inningsNumber ? b : a,
  );
  return latest.scoreText;
}

/// "3 grounds today · 2 scorers unassigned" — what the organiser owes today.
String _liveNote(List<TournamentLiveMatch> board) {
  final grounds = board.where((m) => m.isLive).map((m) => m.venue).toSet().length;
  final unassigned = board.where((m) => m.needsScorer).length;
  return [
    '$grounds ground${grounds == 1 ? '' : 's'} today',
    if (unassigned > 0)
      '$unassigned scorer${unassigned == 1 ? '' : 's'} unassigned',
  ].join(' · ');
}

/// "Model Town Ground · T20 Knockout" — venue, format, size.
String? _meta(Tournament t) {
  final bits = <String>[
    if (t.venues.isNotEmpty)
      t.venues.first.name
    else if (t.city != null)
      t.city!,
    '${t.maxOvers} ov ${t.type.label}',
    if (t.approvedTeamsCount > 0) '${t.approvedTeamsCount} teams',
  ];
  return bits.isEmpty ? null : bits.join(' · ');
}

String _closesIn(DateTime deadline) {
  final days = deadline.difference(DateTime.now()).inDays;
  if (days < 0) return 'Registration closed';
  if (days == 0) return 'Closes today';
  return 'Closes in $days day${days == 1 ? '' : 's'}';
}

String _ago(DateTime when) {
  final d = DateTime.now().difference(when);
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'yesterday';
  return '${d.inDays} days ago';
}
