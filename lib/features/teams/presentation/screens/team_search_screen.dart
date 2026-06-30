// Search tab — Team Search & Discovery (docs/search-feature-design.md, Slice 3).
//
// Faithful Flutter port of `design/app/screens/matchday-challenge/Search.html`'s
// five controller states (A Browse · B Searching · C Near-me · D Sparse · E
// Permission denied). The controller / repo / edge functions are already
// wired — this file just renders.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../domain/entities/place_facet.dart';
import '../../domain/entities/team_search_result.dart';
import '../controllers/team_search_controller.dart';
import '../providers/team_search_providers.dart';
import '../state/team_search_state.dart';

class TeamSearchScreen extends ConsumerStatefulWidget {
  const TeamSearchScreen({super.key});

  @override
  ConsumerState<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends ConsumerState<TeamSearchScreen> {
  late final TextEditingController _queryCtrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncFieldFrom(TeamSearchState state) {
    // Keep the text-field in sync when the controller resets (e.g. clearCentre
    // returns to browse). User typing already updates state via setQuery, so
    // skip when they match.
    if (_queryCtrl.text != state.query) {
      _queryCtrl.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamSearchControllerProvider);
    final notifier = ref.read(teamSearchControllerProvider.notifier);

    // Mirror controller-driven query changes back into the field (e.g. when
    // a facet chip selection clears the query). Cheap; runs on rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFieldFrom(state));

    final isNearMe = state.hasCenter && state.selectedFacetCity == null;
    final hasQuery = state.query.trim().isNotEmpty;
    final isPermDenied = state.error is PermissionFailure && !state.hasCenter;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ====== SEARCH HEADER ======
            // Faithful port of design_handoff_matchday §5 — back arrow next
            // to the search field, no separate "Search" title bar.
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 14, 8),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: V2Svg(
                        V2Icons.chevronLeft,
                        size: 20,
                        color: CkColors.ink,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _SearchField(
                      controller: _queryCtrl,
                      focusNode: _focus,
                      onChanged: notifier.setQuery,
                      onClear: () {
                        _queryCtrl.clear();
                        notifier.setQuery('');
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ====== NEAR-ME PILL ======
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: _NearMePill(
                      on: isNearMe,
                      onTap: notifier.toggleNearMe,
                    ),
                  ),
                  // ====== PERMISSION BANNER (state E) ======
                  if (isPermDenied) ...[
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: _PermissionBanner(),
                    ),
                  ],
                  // ====== FACET ROW / RADIUS CHIP ======
                  // Hidden while a name query is active (state B).
                  if (!hasQuery) _FacetsBlock(
                    state: state,
                    onSelectFacet: notifier.selectFacet,
                    onClearCenter: notifier.clearCenter,
                  ),
                  // ====== RESULTS ======
                  _ResultsBlock(
                    state: state,
                    onExpand: notifier.expandRadius,
                    onRetry: notifier.retry,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search input ────────────────────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onFocus() => setState(() {});
  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: focused ? CkColors.surface : CkColors.paper2,
        border: Border.all(
          color: focused ? CkColors.ink : CkColors.hairline,
          width: focused ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
          children: [
            const V2Svg(V2Icons.search, size: 18, color: CkColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: CkType.body(fontSize: 14),
                cursorColor: CkColors.ink,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search teams',
                  hintStyle:
                      CkType.body(fontSize: 14, color: CkColors.muted),
                ),
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: widget.onClear,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: V2Svg(V2Icons.close,
                      size: 18, color: CkColors.muted),
                ),
              ),
          ],
        ),
    );
  }
}

// ─── Near-me pill ────────────────────────────────────────────────────────────

class _NearMePill extends StatelessWidget {
  const _NearMePill({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: on ? CkColors.ink : CkColors.paper2,
          border: Border.all(
            color: on ? CkColors.ink : CkColors.hairline,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            V2Svg(
              V2Icons.pin,
              size: 16,
              color: on ? CkColors.paper : CkColors.ink,
              filled: on,
            ),
            const SizedBox(width: 7),
            Text(
              'Near me',
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? CkColors.paper : CkColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Facets / radius chip ────────────────────────────────────────────────────

class _FacetsBlock extends ConsumerWidget {
  const _FacetsBlock({
    required this.state,
    required this.onSelectFacet,
    required this.onClearCenter,
  });

  final TeamSearchState state;
  final ValueChanged<PlaceFacet> onSelectFacet;
  final VoidCallback onClearCenter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Centre present → single "Within X km" radius chip (state C/D).
    if (state.hasCenter) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 9),
              child: _Eyebrow(text: 'Area'),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _Chip(
                label: state.selectedFacetCity != null
                    ? state.selectedFacetCity!
                    : 'Within ${state.radiusKm.toInt()} km',
                selected: true,
                onTap: onClearCenter,
              ),
            ),
          ],
        ),
      );
    }

    // Browse — "BROWSE BY CITY" facets from the edge function.
    final facetsAsync = ref.watch(placeFacetsProvider(null));
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 9),
            child: _Eyebrow(text: 'Browse by city'),
          ),
          SizedBox(
            height: 36,
            child: facetsAsync.when(
              loading: () => _FacetsSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (facets) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: facets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = facets[i];
                  return _Chip(
                    label: f.city,
                    trailing: '(${f.teamCount})',
                    onTap: () => onSelectFacet(f),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacetsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => Container(
        width: 84,
        decoration: BoxDecoration(
          color: CkColors.paper2,
          border: Border.all(color: CkColors.hairline),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.trailing,
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? CkColors.red : CkColors.ink;
    final bg = selected ? CkColors.redSoft : CkColors.paper2;
    final border = selected ? CkColors.red : CkColors.hairline;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: CkType.body(fontSize: 13, color: fg),
            ),
            if (selected) ...[
              const SizedBox(width: 7),
              const V2Svg(V2Icons.close, size: 14, color: CkColors.red),
            ] else if (trailing != null) ...[
              const SizedBox(width: 7),
              Text(
                trailing!,
                style: CkType.mono(fontSize: 11, color: CkColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Permission banner (state E) ─────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: CkColors.redSoft,
        borderRadius: BorderRadius.circular(CkRadii.md),
      ),
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
      child: Stack(
        children: [
          Positioned(
            left: -13,
            top: -12,
            bottom: -12,
            child: Container(width: 3, color: CkColors.red),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1, right: 11),
                child: V2Svg(V2Icons.pin, size: 18, color: CkColors.red),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow location to find teams near you',
                      style: CkType.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO(search slice 3): wire to a settings-opener
                          // (e.g. permission_handler.openAppSettings()) once
                          // the dep ships. Inert placeholder for now matches
                          // the design contract.
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: CkColors.paper,
                          foregroundColor: CkColors.ink,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          side: const BorderSide(color: CkColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: CkType.body(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Open settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Results ─────────────────────────────────────────────────────────────────

class _ResultsBlock extends StatelessWidget {
  const _ResultsBlock({
    required this.state,
    required this.onExpand,
    required this.onRetry,
  });

  final TeamSearchState state;
  final VoidCallback onExpand;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Eyebrow label switches: pure browse → RECENT; everything else → RESULTS.
    final label = state.isBrowsing ? 'Recent' : 'Results';

    // Spinner shows alongside the eyebrow whenever a request is in flight.
    final showSpinner = state.loading;

    // Sparse-area CTA: near-me / facet on with ≤1 result and not loading.
    // Hidden when a name query is being typed (its own loading + results
    // pattern, not "sparse area").
    final showSparseCta = state.hasCenter &&
        !state.loading &&
        state.query.trim().isEmpty &&
        state.results.length <= 1 &&
        state.error == null;

    // Non-permission failures (network / server / unknown) → inline retry row,
    // shown when we have no usable results to lean on. PermissionFailure is
    // handled by the banner above and intentionally skipped here.
    final showErrorRow = state.error != null &&
        state.error is! PermissionFailure &&
        state.results.isEmpty &&
        !state.loading;

    final centerCity = state.selectedFacetCity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Eyebrow(text: label),
              if (showSpinner) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CkColors.ink,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Empty-but-not-sparse states (e.g. zero hits on a query) → small
          // muted line so the layout isn't blank.
          if (state.results.isEmpty && !state.loading && !showSparseCta &&
              !showErrorRow)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                state.query.trim().isEmpty
                    ? 'No teams to show yet.'
                    : 'No teams match "${state.query.trim()}".',
                style:
                    CkType.body(fontSize: 13, color: CkColors.muted),
              ),
            ),
          // Results
          ...state.results.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ResultCard(result: r, centerCity: centerCity),
            ),
          ),
          if (showSparseCta) _SparseCta(
            radiusKm: state.radiusKm,
            count: state.results.length,
            onExpand: onExpand,
          ),
          if (showErrorRow) _ErrorRow(
            failure: state.error!,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: CkType.mono(fontSize: 11, color: CkColors.muted),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.centerCity});

  final TeamSearchResult result;
  final String? centerCity;

  @override
  Widget build(BuildContext context) {
    final crestColor = _parseHex(result.primaryColor) ?? CkColors.ink;
    final mono = (result.logoMonogram ?? _monogramOf(result.name)).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: CkColors.surface,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(CkRadii.lg),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Crest(
            short: mono.length > 2 ? mono.substring(0, 2) : mono,
            color: crestColor,
            logoUrl: result.logoUrl,
            size: 44,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        result.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (result.isVerified) ...[
                      const SizedBox(width: 5),
                      const V2Svg(
                        V2Icons.check,
                        size: 14,
                        color: CkColors.red,
                        strokeWidth: 2.4,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                _SubLine(result: result, centerCity: centerCity),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const V2Svg(V2Icons.chevronRight,
              size: 18, color: CkColors.soft),
        ],
      ),
    );
  }
}

class _SubLine extends StatelessWidget {
  const _SubLine({required this.result, required this.centerCity});

  final TeamSearchResult result;
  final String? centerCity;

  @override
  Widget build(BuildContext context) {
    final city = result.city;
    final band = _distanceBand(result, centerCity);
    // "{city} · {band}". When the band already names the city ("in Lahore"),
    // show the band alone to avoid "Lahore · in Lahore" (matches the
    // Search.html prototype's tweak).
    if (band == null) {
      return Text(
        city ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CkType.body(fontSize: 12.5, color: CkColors.muted),
      );
    }
    if (band.mono) {
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style:
              CkType.body(fontSize: 12.5, color: CkColors.muted),
          children: [
            if (city != null) TextSpan(text: '$city · '),
            TextSpan(
              text: band.text,
              style:
                  CkType.mono(fontSize: 11, color: CkColors.muted),
            ),
          ],
        ),
      );
    }
    return Text(
      band.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CkType.body(fontSize: 12.5, color: CkColors.muted),
    );
  }
}

class _Band {
  const _Band(this.text, {required this.mono});
  final String text;
  final bool mono;
}

_Band? _distanceBand(TeamSearchResult r, String? centerCity) {
  if (r.distanceKm == null) return null;
  // City match → "in {city}" (plain). NEVER a literal km.
  if (centerCity != null && r.city != null && r.city == centerCity) {
    return _Band('in ${r.city}', mono: false);
  }
  // Otherwise → "~{X} KM" rounded to nearest 5 (mono slot).
  final r5 = (r.distanceKm! / 5).round() * 5;
  return _Band('~$r5 KM', mono: true);
}

class _SparseCta extends StatelessWidget {
  const _SparseCta({
    required this.radiusKm,
    required this.count,
    required this.onExpand,
  });

  final double radiusKm;
  final int count;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final next = (radiusKm * 2).clamp(25.0, 200.0).toInt();
    final atCeiling = next <= radiusKm.toInt();
    final headline = count == 0
        ? 'No teams within ${radiusKm.toInt()} km'
        : 'Only 1 team within ${radiusKm.toInt()} km';

    return DottedBorderCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const V2Svg(V2Icons.pin, size: 24, color: CkColors.soft),
            const SizedBox(height: 10),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: CkType.display(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              atCeiling ? 'Already at the widest area.' : 'Try a wider area',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
            if (!atCeiling) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: onExpand,
                  style: FilledButton.styleFrom(
                    backgroundColor: CkColors.ink,
                    foregroundColor: CkColors.paper,
                    minimumSize: const Size.fromHeight(44),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text('Expand to $next km'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper2,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(CkRadii.md),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              switch (failure) {
                NetworkFailure() => "You're offline.",
                ServerFailure() => 'Search is having a moment.',
                _ => 'Something went wrong.',
              },
              style: CkType.body(fontSize: 13, color: CkColors.ink2),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: CkColors.ink,
              textStyle: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Bits ────────────────────────────────────────────────────────────────────

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var v = hex.trim();
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  if (v.length != 8) return null;
  final n = int.tryParse(v, radix: 16);
  return n == null ? null : Color(n);
}

String _monogramOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '·';
  final parts = t.split(RegExp(r'\s+'));
  final b = StringBuffer(parts.first[0]);
  if (parts.length > 1) b.write(parts[1][0]);
  return b.toString();
}

/// Dashed-border surround for the sparse-area CTA card.
class DottedBorderCard extends StatelessWidget {
  const DottedBorderCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: CkColors.hairline,
        radius: CkRadii.lg,
        dash: 5,
        gap: 4,
        strokeWidth: 1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CkRadii.lg),
        child: Container(
          color: CkColors.surface,
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dash,
    required this.gap,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap ||
      old.strokeWidth != strokeWidth;
}
