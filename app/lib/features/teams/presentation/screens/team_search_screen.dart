import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/place_facet.dart';
import '../../domain/entities/team_search_result.dart';
import '../controllers/team_search_controller.dart';
import '../providers/team_search_providers.dart';
import '../state/team_search_state.dart';
import '../widgets/team_crest.dart';

/// Team Search & Discovery.
///
/// Keeps the existing Matchday browse/search/near-me visual states while the
/// repository/controller remain the cleaned online-only search implementation.
class TeamSearchScreen extends ConsumerStatefulWidget {
  const TeamSearchScreen({super.key, this.onBell});
  final VoidCallback? onBell;

  @override
  ConsumerState<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends ConsumerState<TeamSearchScreen> {
  late final TextEditingController _query;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _sync(TeamSearchState state) {
    if (_query.text == state.query) return;
    _query.value = TextEditingValue(
      text: state.query,
      selection: TextSelection.collapsed(offset: state.query.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamSearchControllerProvider);
    final controller = ref.read(teamSearchControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync(state));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onBack: () => context.canPop() ? context.pop() : context.go('/teams'),
              onBell: widget.onBell,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: _SearchField(
                controller: _query,
                focusNode: _focus,
                loading: state.loading,
                onChanged: controller.setQuery,
                onClear: () {
                  _query.clear();
                  controller.setQuery('');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _FilterChip(
                    icon: Icons.near_me_outlined,
                    label: state.hasCenter && state.selectedFacetCity == null
                        ? 'Near me · ${state.radiusKm.toInt()} km'
                        : 'Near me',
                    selected: state.hasCenter && state.selectedFacetCity == null,
                    onTap: controller.toggleNearMe,
                  ),
                  if (state.selectedFacetCity != null) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.location_on_outlined,
                      label: state.selectedFacetCity!,
                      selected: true,
                      onTap: controller.clearCenter,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: CkColors.hairline),
            Expanded(
              child: RefreshIndicator(
                color: CkColors.ink,
                onRefresh: controller.retry,
                child: _Body(
                  state: state,
                  onFacet: controller.selectFacet,
                  onExpand: controller.expandRadius,
                  onRetry: controller.retry,
                  onTeam: (result) => context.push('/teams/${result.teamId.value}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.onBell});
  final VoidCallback onBack;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 2),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
            ),
            Expanded(
              child: Text(
                'Find Teams',
                textAlign: TextAlign.center,
                style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: onBell,
              icon: const Icon(Icons.notifications_none_rounded, color: CkColors.ink),
            ),
          ],
        ),
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.loading,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: CkType.body(fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: CkColors.muted),
            hintText: 'Search teams, cities or clubs',
            hintStyle: CkType.body(fontSize: 14, color: CkColors.muted),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  )
                : loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: CkColors.ink),
                        ),
                      )
                    : null,
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? CkColors.ink : CkColors.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? CkColors.ink : CkColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? CkColors.paper : CkColors.ink),
              const SizedBox(width: 5),
              Text(
                label,
                style: CkType.body(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? CkColors.paper : CkColors.ink,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.state,
    required this.onFacet,
    required this.onExpand,
    required this.onRetry,
    required this.onTeam,
  });
  final TeamSearchState state;
  final ValueChanged<PlaceFacet> onFacet;
  final Future<void> Function() onExpand;
  final Future<void> Function() onRetry;
  final ValueChanged<TeamSearchResult> onTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.error != null && state.results.isEmpty) {
      return _ErrorState(failure: state.error!, onRetry: onRetry);
    }
    if (state.isBrowsing) {
      return _BrowseState(onFacet: onFacet);
    }
    if (state.loading && state.results.isEmpty) {
      return const _SearchSkeleton();
    }
    if (state.results.isEmpty) {
      return _EmptyState(
        query: state.query,
        hasCenter: state.hasCenter,
        radiusKm: state.radiusKm,
        onExpand: state.hasCenter ? onExpand : null,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Text(
          state.query.trim().isNotEmpty
              ? 'SEARCH RESULTS'
              : state.selectedFacetCity != null
                  ? 'TEAMS IN ${state.selectedFacetCity!.toUpperCase()}'
                  : 'TEAMS NEAR YOU',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .10,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        for (final team in state.results)
          _TeamCard(result: team, onTap: () => onTeam(team)),
        if (state.hasCenter && state.query.trim().isEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async => onExpand(),
            child: Text('Search a wider area · ${state.radiusKm.toInt()} km'),
          ),
        ],
      ],
    );
  }
}

class _BrowseState extends ConsumerWidget {
  const _BrowseState({required this.onFacet});
  final ValueChanged<PlaceFacet> onFacet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facets = ref.watch(placeFacetsProvider(null));
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          'DISCOVER TEAMS',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .10,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Find cricket communities around you.',
          style: CkType.display(fontSize: 23, fontWeight: FontWeight.w700, letterSpacing: -.025),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: CkColors.ink, shape: BoxShape.circle),
                child: const Icon(Icons.near_me_rounded, size: 18, color: CkColors.paper),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Use your location', style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Tap Near me above to discover teams around your current area.', style: CkType.body(fontSize: 11.5, color: CkColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'BROWSE BY CITY',
          style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .10, color: CkColors.muted),
        ),
        const SizedBox(height: 10),
        switch (facets) {
          AsyncData(:final value) when value.isNotEmpty => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final facet in value)
                  InkWell(
                    onTap: facet.hasCenter ? () => onFacet(facet) : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      child: Text(
                        '${facet.city} · ${facet.teamCount}',
                        style: CkType.body(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          AsyncLoading() => const LinearProgressIndicator(minHeight: 2, color: CkColors.ink),
          _ => Text('Search by team name above.', style: CkType.body(fontSize: 12.5, color: CkColors.muted)),
        },
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.result, required this.onTap});
  final TeamSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TeamCrest(
                    name: result.name,
                    primaryColor: result.primaryColor,
                    logoUrl: result.logoUrl,
                    monogram: result.logoMonogram,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                result.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CkType.display(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (result.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.verified_rounded, size: 13, color: CkColors.green),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          [
                            if (result.metaLine.isNotEmpty) result.metaLine,
                            if (result.distanceKm != null) '${result.distanceKm!.round()} km away',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.mono(fontSize: 10.5, color: CkColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: CkColors.muted),
                ],
              ),
            ),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.hasCenter,
    required this.radiusKm,
    this.onExpand,
  });
  final String query;
  final bool hasCenter;
  final double radiusKm;
  final Future<void> Function()? onExpand;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(30, 90, 30, 32),
        children: [
          const Icon(Icons.search_off_rounded, size: 42, color: CkColors.muted),
          const SizedBox(height: 12),
          Text(
            query.trim().isNotEmpty ? 'No teams match “${query.trim()}”' : 'No teams found nearby',
            textAlign: TextAlign.center,
            style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            hasCenter
                ? 'Try widening the search radius or searching by name.'
                : 'Try another name or location.',
            textAlign: TextAlign.center,
            style: CkType.body(fontSize: 13, color: CkColors.muted),
          ),
          if (onExpand != null) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: () async => onExpand!(),
                child: Text('Expand beyond ${radiusKm.toInt()} km'),
              ),
            ),
          ],
        ],
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.failure, required this.onRetry});
  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 90, 28, 32),
        children: [
          const Icon(Icons.location_off_outlined, size: 42, color: CkColors.muted),
          const SizedBox(height: 12),
          Text(
            failure is PermissionFailure ? 'Location is unavailable' : 'Could not search teams',
            textAlign: TextAlign.center,
            style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            failure.message,
            textAlign: TextAlign.center,
            style: CkType.body(fontSize: 13, color: CkColors.muted),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () async => onRetry(),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CkColors.hairline),
              ),
            ),
        ],
      );
}
