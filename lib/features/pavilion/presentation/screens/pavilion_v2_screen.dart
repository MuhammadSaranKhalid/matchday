// Pavilion v2 — "Your workspace" (wired to real data).
//
// The Matches lane and Teams lane are fed from the real feature providers
// (`myMatchesViewProvider`, `myTeams`); the Account header reads
// `myProfileProvider`. Tournaments stays mock (no Flutter feature yet). This
// screen is a presentation-only AGGREGATION view (CLAUDE.md §6.6): it watches
// other features' providers and maps them into the Pv* widget models via
// pv_v2_map.dart — no domain/data layer of its own.
//
// Actions route to the flows that exist (Resume→/score, Start→/start,
// Scorecard→/scorecard, Withdraw→withdrawMatchChallenge, Schedule match→
// /challenge, Create team→/teams/create). Backend-less actions are dropped.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../widgets/pavilion_v2/pv_v2_data.dart';
import '../widgets/pavilion_v2/pv_v2_kit.dart';
import '../widgets/pavilion_v2/pv_v2_lanes.dart';
import '../widgets/pavilion_v2/pv_v2_map.dart';

class PavilionV2Screen extends ConsumerStatefulWidget {
  const PavilionV2Screen({super.key, this.onBell});

  /// Retained for router compatibility. Pavilion v2 has no header bell — the
  /// header is a workspace title + avatar (→ Account). Currently unused.
  final VoidCallback? onBell;

  @override
  ConsumerState<PavilionV2Screen> createState() => _PavilionV2ScreenState();
}

class _PavilionV2ScreenState extends ConsumerState<PavilionV2Screen> {
  PvSeg _seg = PvSeg.matches;
  String? _toast;
  int _toastSeq = 0;

  final ScrollController _scroll = ScrollController();
  final List<PvTournament> _tours = seedTournaments(); // mock — no feature yet

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _flash(String message) {
    setState(() => _toast = message);
    final seq = ++_toastSeq;
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && seq == _toastSeq) setState(() => _toast = null);
    });
  }

  void _setSeg(PvSeg s) {
    setState(() => _seg = s);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  // ── actions ──
  // The Today hero carries the one urgent action (resume / start); every other
  // per-match action lives on the Match Detail route, which a card tap opens.
  void _onMatchAction(String id, String action) {
    switch (action) {
      case 'resume':
        _pushAndRefresh('/matches/$id/score');
      case 'start':
        _pushAndRefresh('/matches/$id/start');
    }
  }

  Future<void> _pushAndRefresh(String location) async {
    await context.push(location);
    if (mounted) ref.invalidate(myMatchesViewProvider);
  }

  void _onCreate() {
    switch (_seg) {
      case PvSeg.matches:
        context.push('/challenge');
      case PvSeg.teams:
        context.push('/teams/create');
      case PvSeg.tournaments:
        _flash('Tournaments coming soon');
    }
  }

  PvMatch? _heroOf(List<PvMatch> ms) {
    for (final m in ms) {
      if (m.phase == PvPhase.live) return m;
    }
    for (final m in ms) {
      if (m.phase == PvPhase.startsSoon) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserStreamProvider).value?.id.value;
    final teamsAsync = ref.watch(myTeamsProvider);
    final matchesAsync = ref.watch(myMatchesViewProvider);

    final pvTeams = pvTeamsFromTeams(
      teamsAsync.value ?? const [],
      userId: userId,
    );
    final meFallback =
        pvTeams.isNotEmpty ? pvTeams.first.crest : kPvUnknownCrest;

    final view = matchesAsync.value;
    final matches =
        view != null
            ? pvMatchesFromView(view, meFallback: meFallback)
            : const <PvMatch>[];

    final matchesBadge = view?.sent.length ?? 0;
    final toursBadge = _tours.fold<int>(0, (a, t) => a + t.needs);

    // Pavilion is a full-screen route over the shell (it gave up its nav tab
    // to the Pool on 2026-08-21), so — unlike the other v2 tab screens — it
    // owns its Scaffold and header. The bottom inset is handled by the FAB
    // offset below rather than by SafeArea, so the lanes can scroll under it.
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            V2Header(
              title: 'Pavilion',
              sub: 'Your workspace',
              showBack: true,
              // Pop back to whatever opened Pavilion (normally the Management
              // sheet's caller); fall back to Home on a cold load / deep link
              // where nothing is below, so this is never a dead end.
              onBack:
                  () => context.canPop() ? context.pop() : context.go('/home'),
              showMessages: false,
              showManagement: false,
              onBell: () => context.push('/notifications'),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _segmented(
                        matchesBadge: matchesBadge,
                        toursBadge: toursBadge,
                      ),
                      Expanded(
                        child: switch (_seg) {
                          PvSeg.matches => switch (matchesAsync) {
                            AsyncError(:final error) => _errorView(
                              error,
                              () => ref.invalidate(myMatchesViewProvider),
                            ),
                            AsyncData() => _matchesBody(matches),
                            _ => _loading(),
                          },
                          PvSeg.teams => switch (teamsAsync) {
                            AsyncError(:final error) => _errorView(
                              error,
                              () => ref.invalidate(myTeamsProvider),
                            ),
                            AsyncData() => _teamsBody(pvTeams),
                            _ => _loading(),
                          },
                          PvSeg.tournaments => _scroller(
                            PvToursLane(
                              tournaments: _tours,
                              onOpen: (t) => _flash('Opening ${t.name}…'),
                              onSchedule:
                                  (_) => _flash('Tournaments coming soon'),
                            ),
                          ),
                        },
                      ),
                    ],
                  ),

                  Positioned(
                    right: 16,
                    bottom: 18 + bottomInset,
                    child: _fab(),
                  ),

                  if (_toast != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 74 + bottomInset,
                      child: _toastPill(_toast!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── bodies ──
  Widget _scroller(Widget child) => SingleChildScrollView(
    controller: _scroll,
    padding: const EdgeInsets.only(top: 10, bottom: 96),
    child: child,
  );

  Widget _matchesBody(List<PvMatch> matches) {
    final hero = _heroOf(matches);
    return _scroller(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PvOverview(
            matches: matches,
            tournaments: _tours,
            onAction: _onMatchAction,
            onSegment: _setSeg,
            onOpenMatch: (id) => context.go('/pavilion/match/$id'),
          ),
          PvMatchesLane(
            matches: matches,
            // `go` (not `push`) so the URL becomes /pavilion/match/:id and a
            // refresh restores the page with a working back — matching the
            // my-matches route's pattern.
            onOpen: (m) => context.go('/pavilion/match/${m.id}'),
            onCreate: _onCreate,
            hideIds: hero != null ? {hero.id} : const {},
          ),
        ],
      ),
    );
  }

  Widget _teamsBody(List<PvTeam> teams) {
    if (teams.isEmpty) {
      return _scroller(
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No teams yet',
                style: CkType.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create a club or village side, or accept a captain’s invite to '
                'join one. Use ＋ Create team below.',
                style: CkType.body(
                  fontSize: 12.5,
                  height: 1.45,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _scroller(
      PvTeamsLane(
        teams: teams,
        onOpen: (t) => context.push('/teams/${t.id}'),
        onResolve: (t, need) => _flash(need),
      ),
    );
  }

  Widget _loading() => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: CircularProgressIndicator(),
    ),
  );

  Widget _errorView(Object e, VoidCallback onRetry) {
    final message = e is FailureWrapper ? e.failure.message : e.toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Couldn't load this.",
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
    );
  }

  // ── segmented control ──
  Widget _segmented({required int matchesBadge, required int toursBadge}) {
    int badge(PvSeg s) => switch (s) {
      PvSeg.matches => matchesBadge,
      PvSeg.teams => 0, // no team-invite backend yet
      PvSeg.tournaments => toursBadge,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            for (final s in PvSeg.values)
              Expanded(child: _segButton(s, badge(s))),
          ],
        ),
      ),
    );
  }

  Widget _segButton(PvSeg s, int badge) {
    final on = _seg == s;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _setSeg(s),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: on ? CkColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              on
                  ? const [
                    BoxShadow(
                      color: Color(0x1A28200F),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.label,
              style: CkType.body(
                fontSize: 12.5,
                fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                color: on ? CkColors.ink : CkColors.muted,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 15),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? CkColors.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badge',
                  style: pvMono(
                    8.5,
                    color: on ? CkColors.ink2 : CkColors.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── FAB ──
  Widget _fab() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onCreate,
      child: Container(
        height: 44,
        padding: const EdgeInsets.only(left: 16, right: 18),
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x7328120E),
              blurRadius: 22,
              spreadRadius: -6,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PvIcon(
              PvIcons.plus,
              size: 18,
              color: CkColors.paper,
              sw: 2.4,
            ),
            const SizedBox(width: 8),
            Text(
              _seg.createLabel,
              style: CkType.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CkColors.paper,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── toast ──
  Widget _toastPill(String message) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4728120E),
              blurRadius: 28,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PvIcon(
              PvIcons.check,
              size: 16,
              color: CkColors.paper,
              sw: 2.6,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: CkType.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CkColors.paper,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
