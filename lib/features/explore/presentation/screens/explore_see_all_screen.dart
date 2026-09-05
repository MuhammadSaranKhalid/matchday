// "See all" drill-down — one category, full depth (artboard 08).
//
// Deliberately NOT a Material AppBar screen: the design keeps Explore's own
// search field at the top and states the active scope beneath it as an ink
// "TEAMS ONLY ✕" pill plus a red "← ALL RESULTS" escape. NN/g's scoped-search
// finding is that an unstated scope makes users conclude the app has nothing,
// so the scope row is load-bearing, not decoration.
//
// The design's third filter chip is a location facet ("Lahore ⌄"). v1 has no
// location scope, so only the two chips backed by real columns ship —
// `team_type` and `founded_year` — and they filter the already-fetched page
// client-side rather than pretending to be a server query.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/team_search_result.dart';
import '../../domain/entities/explore_results.dart';
import '../controllers/explore_see_all_controller.dart';
import '../widgets/explore_panels.dart';
import '../widgets/explore_rows.dart';
import '../widgets/explore_search_field.dart';

class ExploreSeeAllScreen extends ConsumerStatefulWidget {
  const ExploreSeeAllScreen({
    super.key,
    required this.query,
    required this.category,
    this.onOpenTeam,
    this.onOpenProfile,
    this.onOpenMatch,
    this.onOpenTournament,
  });

  final String query;
  final ExploreCategory category;
  final ValueChanged<String>? onOpenTeam;
  final ValueChanged<String>? onOpenProfile;
  final ValueChanged<String>? onOpenMatch;
  final ValueChanged<String>? onOpenTournament;

  @override
  ConsumerState<ExploreSeeAllScreen> createState() =>
      _ExploreSeeAllScreenState();
}

class _ExploreSeeAllScreenState extends ConsumerState<ExploreSeeAllScreen> {
  late final TextEditingController _queryCtrl;
  late final FocusNode _focus;

  /// Client-side narrowing over the fetched page. Null = chip inactive.
  String? _typeFilter;
  int? _decadeFilter;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.query);
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _back() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final provider = exploreSeeAllProvider(widget.query, widget.category);
    final async = ref.watch(provider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // The field is read-only here; tapping it returns to the full
            // search rather than opening a second editable surface.
            ExploreSearchField(
              controller: _queryCtrl,
              focusNode: _focus,
              focused: false,
              readOnly: true,
              onChanged: (_) {},
              onClear: _back,
              onCancel: _back,
              onSubmitted: (_) {},
              below: _ScopeRow(
                category: widget.category,
                onClearScope: _back,
              ),
            ),
            if (widget.category == ExploreCategory.teams)
              _FilterRow(
                results: async.value,
                typeFilter: _typeFilter,
                decadeFilter: _decadeFilter,
                onType: (v) => setState(() => _typeFilter = v),
                onDecade: (v) => setState(() => _decadeFilter = v),
              ),
            Expanded(
              child: switch (async) {
                AsyncLoading() => const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: ExploreRowSkeleton(count: 6),
                  ),
                AsyncError(:final error) => ListView(
                    children: [
                      ExploreError(
                        failure: error is Failure
                            ? error
                            : UnknownFailure(error.toString()),
                        onRetry: () => ref.invalidate(provider),
                      ),
                    ],
                  ),
                AsyncData(:final value) => _list(value),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(ExploreResults r) {
    final rows = switch (widget.category) {
      ExploreCategory.teams => _filteredTeams(r.teams)
          .map((t) => TeamRow(
                team: t,
                query: widget.query,
                onTap: () => widget.onOpenTeam?.call(t.teamId.value),
              ))
          .toList(),
      ExploreCategory.players => r.players
          .map((p) => PlayerRow(
                player: p,
                query: widget.query,
                onTap: p.isUnclaimed || p.username == null
                    ? null
                    : () => widget.onOpenProfile?.call(p.username!),
              ))
          .toList(),
      ExploreCategory.matches => r.matches
          .map((m) => MatchRow(
                match: m,
                query: widget.query,
                onTap: () => widget.onOpenMatch?.call(m.matchId),
              ))
          .toList(),
      ExploreCategory.tournaments => r.tournaments
          .map((t) => TournamentRow(
                tournament: t,
                query: widget.query,
                onTap: () => widget.onOpenTournament?.call(t.tournamentId),
              ))
          .toList(),
    };

    if (rows.isEmpty) {
      return ListView(
        children: [
          ExploreNoResults(query: widget.query, onClear: _back),
        ],
      );
    }

    final noun = switch (widget.category) {
      ExploreCategory.teams => rows.length == 1 ? 'team' : 'teams',
      ExploreCategory.players => rows.length == 1 ? 'player' : 'players',
      ExploreCategory.matches => rows.length == 1 ? 'match' : 'matches',
      ExploreCategory.tournaments =>
        rows.length == 1 ? 'tournament' : 'tournaments',
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            // The design reads "Sorted by distance"; without coordinates the
            // ordering is pure text relevance, and saying so is the honest
            // version of the same line.
            '${rows.length} $noun · Sorted by relevance'.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.muted,
            ),
          ),
        ),
        ...rows,
      ],
    );
  }

  Iterable<TeamSearchResult> _filteredTeams(List<TeamSearchResult> teams) =>
      teams.where((t) {
        if (_typeFilter != null && t.teamType != _typeFilter) return false;
        if (_decadeFilter != null) {
          final y = t.foundedYear;
          if (y == null || y - (y % 10) != _decadeFilter) return false;
        }
        return true;
      });
}

/// Ink "TEAMS ONLY ✕" pill + red "← ALL RESULTS" escape.
class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.category, required this.onClearScope});

  final ExploreCategory category;
  final VoidCallback onClearScope;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onClearScope,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CkColors.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${category.label} only'.toUpperCase(),
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.06,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.close, size: 11, color: CkColors.paper),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onClearScope,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '← ALL RESULTS',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: CkColors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Type + Founded chips. Options are derived from the fetched page, so a chip
/// can never offer a value that yields nothing.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.results,
    required this.typeFilter,
    required this.decadeFilter,
    required this.onType,
    required this.onDecade,
  });

  final ExploreResults? results;
  final String? typeFilter;
  final int? decadeFilter;
  final ValueChanged<String?> onType;
  final ValueChanged<int?> onDecade;

  @override
  Widget build(BuildContext context) {
    final teams = results?.teams ?? const <TeamSearchResult>[];
    final types = teams
        .map((t) => t.teamType)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final decades = teams
        .map((t) => t.foundedYear)
        .whereType<int>()
        .map((y) => y - (y % 10))
        .toSet()
        .toList()
      ..sort();

    if (types.isEmpty && decades.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          if (types.isNotEmpty)
            _DropdownChip<String>(
              label: typeFilter == null
                  ? 'Type'
                  : typeFilter!.replaceAll('_', '-'),
              active: typeFilter != null,
              value: typeFilter,
              options: {
                for (final t in types) t: t.replaceAll('_', '-'),
              },
              onSelected: onType,
            ),
          if (types.isNotEmpty && decades.isNotEmpty) const SizedBox(width: 7),
          if (decades.isNotEmpty)
            _DropdownChip<int>(
              label: decadeFilter == null ? 'Founded' : '${decadeFilter}s',
              active: decadeFilter != null,
              value: decadeFilter,
              options: {for (final d in decades) d: '${d}s'},
              onSelected: onDecade,
            ),
        ],
      ),
    );
  }
}

/// A pill with a chevron that opens a menu; selecting the active value again
/// clears the filter.
class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.active,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final bool active;
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T?>(
        color: CkColors.surface,
        position: PopupMenuPosition.under,
        onSelected: (v) => onSelected(v == value ? null : v),
        itemBuilder: (_) => [
          for (final entry in options.entries)
            PopupMenuItem<T?>(
              value: entry.key,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: CkType.body(fontSize: 14),
                    ),
                  ),
                  if (entry.key == value)
                    const Icon(Icons.check, size: 15, color: CkColors.ink),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? CkColors.line : CkColors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: active ? CkColors.ink : CkColors.muted,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.keyboard_arrow_down,
                size: 13,
                color: active ? CkColors.ink : CkColors.muted,
              ),
            ],
          ),
        ),
      );
}
