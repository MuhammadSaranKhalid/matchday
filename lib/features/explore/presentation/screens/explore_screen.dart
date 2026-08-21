// Explore tab — unified search + discovery (docs/explore-feature-design.md).
//
// Flutter port of Explore.dc.html, v1 scope: artboards 04 (recents), 05
// (grouped results), 06 (loading), 07 (no results) and a browse state built
// from the live rail + recent teams + players.
//
// The design's proximity surfaces — the near-me pill, city facet chips,
// distance labels, and the "Teams near you" / sparse-widening sections
// (artboards 01, 02, 09) — are deliberately NOT built. No coordinates exist
// in the database yet, so they would rank an empty dimension and spend the
// one-shot iOS location prompt for nothing. They land with capture; the
// entities and rows already carry the fields.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/explore_results.dart';
import '../controllers/explore_controller.dart';
import '../controllers/recent_searches_controller.dart';
import '../providers/explore_providers.dart';
import '../state/explore_state.dart';
import '../widgets/explore_atoms.dart';
import '../widgets/explore_panels.dart';
import '../widgets/explore_rows.dart';
import '../widgets/explore_search_field.dart';
import '../widgets/live_match_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({
    super.key,
    this.onOpenTeam,
    this.onOpenProfile,
    this.onOpenMatch,
    this.onSeeAll,
    this.onCreateTeam,
  });

  /// Navigation is injected rather than resolved here so the screen stays
  /// route-agnostic and testable — the same pattern HomeFeedScreen uses.
  final ValueChanged<String>? onOpenTeam;
  final ValueChanged<String>? onOpenProfile;
  final ValueChanged<String>? onOpenMatch;
  final void Function(String query, ExploreCategory category)? onSeeAll;
  final VoidCallback? onCreateTeam;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _queryCtrl;
  late final FocusNode _focus;

  /// Groups show at most this many rows before deferring to "See all" —
  /// enough to judge relevance, short enough that three groups still fit on
  /// one screen.
  static const _previewCount = 3;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    ref
        .read(exploreControllerProvider.notifier)
        .setFocused(focused: _focus.hasFocus);
  }

  void _cancel() {
    _focus.unfocus();
    _queryCtrl.clear();
    ref.read(exploreControllerProvider.notifier).clearQuery();
  }

  void _submit(String q) {
    _queryCtrl.text = q;
    _queryCtrl.selection = TextSelection.collapsed(offset: q.length);
    _focus.unfocus();
    ref.read(exploreControllerProvider.notifier).submitQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    final notifier = ref.read(exploreControllerProvider.notifier);

    return ColoredBox(
      color: CkColors.paper,
      child: Column(
        children: [
          ExploreSearchField(
            controller: _queryCtrl,
            focusNode: _focus,
            focused: state.searchFocused,
            statusLine: _statusLine(state),
            onChanged: notifier.setQuery,
            onClear: () {
              _queryCtrl.clear();
              notifier.clearQuery();
            },
            onCancel: _cancel,
            onSubmitted: (_) => notifier.commitCurrentQuery(),
            loading: state.loading,
            statusMuted: state.loading,
          ),
          Expanded(
            child: RefreshIndicator(
              color: CkColors.ink,
              backgroundColor: CkColors.paper,
              onRefresh: () async {
                if (state.hasQuery) {
                  await notifier.retry();
                } else {
                  ref.invalidate(exploreBrowseProvider);
                  await ref.read(exploreBrowseProvider.future);
                }
              },
              child: _body(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  /// While a request is in flight the design replaces the count with
  /// "Refreshing results…" — the old count would contradict the incoming
  /// list. Otherwise: "6 RESULTS FOR “LAH” · ALL", pinned to the query the
  /// results are actually for so it never races ahead during the debounce.
  ///
  /// "· ALL" states the category scope, the counterpart to See-all's
  /// "TEAMS ONLY" pill. The design also appends a location scope; v1 has no
  /// location scope to state.
  String? _statusLine(ExploreState state) {
    if (!state.hasQuery) return null;
    if (state.loading) return 'Refreshing results…';
    if (state.resultsQuery.isEmpty) return null;
    final n = state.results.totalCount;
    return '$n ${n == 1 ? 'result' : 'results'} for '
            '“${state.resultsQuery}” · All'
        .toUpperCase();
  }

  Widget _body(ExploreState state, ExploreController notifier) {
    if (state.showRecents) return _recents(state);
    if (state.hasQuery) return _results(state, notifier);
    return _browse();
  }

  // ─── Recents (artboard 04) ─────────────────────────────────────────────────

  Widget _recents(ExploreState state) {
    final recents = ref.watch(recentSearchesProvider);
    final recentCtrl = ref.read(recentSearchesProvider.notifier);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.zero,
      children: [
        RecentSearchesPanel(
          recents: recents.value ?? const [],
          onTap: _submit,
          onRemove: recentCtrl.remove,
          onClearAll: recentCtrl.clearAll,
        ),
      ],
    );
  }

  // ─── Results (artboards 05 · 06 · 07) ──────────────────────────────────────

  Widget _results(ExploreState state, ExploreController notifier) {
    // An error with nothing retained is the only case that replaces the list;
    // otherwise the previous results stay put under the loading bar.
    if (state.error != null && state.results.isEmpty) {
      return ListView(
        children: [
          ExploreError(failure: state.error!, onRetry: notifier.retry),
        ],
      );
    }
    if (state.isNoResults) {
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          ExploreNoResults(
            query: state.resultsQuery.isEmpty
                ? state.query.trim()
                : state.resultsQuery,
            onClear: _cancel,
            onCreateTeam: widget.onCreateTeam,
          ),
        ],
      );
    }

    final r = state.results;
    final q = state.resultsQuery;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Retained results dim while the next query is in flight, so the
        // list reads as stale-but-present rather than current (artboard 06).
        Opacity(
          opacity: state.loading ? 0.45 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final category in r.nonEmptyCategories)
                ..._group(category, r, q),
              if (state.loading) const ExploreIncomingRow(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _group(
    ExploreCategory category,
    ExploreResults r,
    String q,
  ) {
    final total = r.countFor(category);
    final showSeeAll = total > _previewCount && widget.onSeeAll != null;
    return [
      ExploreSectionHeader(
        label: category.label,
        count: total,
        trailingLabel: showSeeAll ? 'See all ›' : null,
        onTrailingTap:
            showSeeAll ? () => widget.onSeeAll!(q, category) : null,
      ),
      ...switch (category) {
        ExploreCategory.teams => r.teams
            .take(_previewCount)
            .map((t) => TeamRow(
                  team: t,
                  query: q,
                  onTap: () => widget.onOpenTeam?.call(t.teamId.value),
                )),
        ExploreCategory.players => r.players
            .take(_previewCount)
            .map((p) => PlayerRow(
                  player: p,
                  query: q,
                  // Unclaimed players have no profile route to open — they
                  // are a record to claim, not a page to visit.
                  onTap: p.isUnclaimed || p.username == null
                      ? null
                      : () => widget.onOpenProfile?.call(p.username!),
                )),
        ExploreCategory.matches => r.matches
            .take(_previewCount)
            .map((m) => MatchRow(
                  match: m,
                  query: q,
                  onTap: () => widget.onOpenMatch?.call(m.matchId),
                )),
      },
    ];
  }

  // ─── Browse ────────────────────────────────────────────────────────────────

  Widget _browse() {
    final async = ref.watch(exploreBrowseProvider);

    return switch (async) {
      AsyncLoading() => ListView(
          padding: EdgeInsets.zero,
          children: const [
            ExploreSectionHeader(label: 'Live now'),
            ExploreRowSkeleton(),
            ExploreSectionHeader(label: 'Recently active'),
            ExploreRowSkeleton(),
          ],
        ),
      AsyncError(:final error) => ListView(
          children: [
            ExploreError(
              failure:
                  error is Failure ? error : UnknownFailure(error.toString()),
              onRetry: () => ref.invalidate(exploreBrowseProvider),
            ),
          ],
        ),
      AsyncData(:final value) => _browseList(value),
    };
  }

  Widget _browseList(ExploreBrowse b) {
    if (b.isEmpty) {
      return ListView(
        children: [ExploreBeTheFirst(onCreateTeam: widget.onCreateTeam)],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── LIVE NOW rail ──
        if (b.live.isNotEmpty) ...[
          const ExploreSectionHeader(label: 'Live now'),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              physics: const BouncingScrollPhysics(),
              itemCount: b.live.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => LiveMatchCard(
                match: b.live[i],
                onTap: () => widget.onOpenMatch?.call(b.live[i].matchId),
              ),
            ),
          ),
        ],
        // ── Recently active teams ──
        // Replaces the design's "Teams near you": ordering by recency is the
        // honest thing to do until coordinates exist.
        if (b.teams.isNotEmpty) ...[
          const ExploreSectionHeader(label: 'Recently active'),
          for (final t in b.teams)
            TeamRow(
              team: t,
              onTap: () => widget.onOpenTeam?.call(t.teamId.value),
            ),
        ],
        // ── Players to follow ──
        if (b.players.isNotEmpty) ...[
          const ExploreSectionHeader(label: 'Players to follow'),
          for (final p in b.players)
            PlayerRow(
              player: p,
              onTap: p.username == null
                  ? null
                  : () => widget.onOpenProfile?.call(p.username!),
            ),
        ],
      ],
    );
  }
}
