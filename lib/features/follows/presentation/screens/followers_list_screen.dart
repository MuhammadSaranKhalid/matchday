import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/follow_direction.dart';
import '../../domain/entities/follow_list_entry.dart';
import '../providers/follows_providers.dart';
import '../widgets/widgets.dart';

/// Followers / Following list screen.
///
/// Designed with Clean Architecture and modular presentation widgets:
/// - [FollowsHeader]: Navigation header with profile name and @handle
/// - [FollowsCountTabs]: Active count tabs with animated selection
/// - [FollowsSearchBar]: Debounced/filtered search
/// - [FollowerTile]: Individual user row with avatar, name, handle, and follow actions
/// - [FollowsShimmerSkeleton]: Skeleton loading placeholder
/// - [FollowsEmptyState] & [FollowsErrorState]: Visual states
class FollowersListScreen extends ConsumerStatefulWidget {
  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.profileName,
    required this.profileUsername,
    this.initialTab = FollowDirection.followers,
  });

  /// The profile whose followers / following we're viewing.
  final String userId;

  /// Header title (the profile's display name).
  final String profileName;

  /// Header sub-title (the profile's @handle).
  final String profileUsername;

  /// Which tab opens first.
  final FollowDirection initialTab;

  @override
  ConsumerState<FollowersListScreen> createState() =>
      _FollowersListScreenState();
}

class _FollowersListScreenState extends ConsumerState<FollowersListScreen> {
  late FollowDirection _tab = widget.initialTab;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _switchTab(FollowDirection next) {
    if (next == _tab) return;
    setState(() {
      _tab = next;
      // Clear search when switching tabs
      _searchController.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(followCountsProvider(widget.userId));
    final listAsync = ref.watch(
      followListProvider(widget.userId, _tab.wire),
    );

    final followers = countsAsync.value?.followers ?? 0;
    final following = countsAsync.value?.following ?? 0;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FollowsHeader(
              name: widget.profileName,
              username: widget.profileUsername,
              onBack: () => Navigator.of(context).pop(),
            ),
            FollowsCountTabs(
              tab: _tab,
              followers: followers,
              following: following,
              onSelect: _switchTab,
            ),
            FollowsSearchBar(
              controller: _searchController,
              tab: _tab,
              onChanged: (q) => setState(() => _query = q.trim()),
            ),
            Expanded(
              child: _buildListBody(context, listAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    AsyncValue<List<FollowListEntry>> listAsync,
  ) {
    return listAsync.when(
      data: (entries) => _buildFilteredList(entries),
      error: (error, _) => FollowsErrorState(
        message: error is FailureWrapper
            ? error.failure.message
            : error.toString(),
        onRetry: () =>
            ref.invalidate(followListProvider(widget.userId, _tab.wire)),
      ),
      loading: () => const FollowsShimmerSkeleton(),
    );
  }

  Widget _buildFilteredList(List<FollowListEntry> all) {
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((e) {
            return e.displayName.toLowerCase().contains(q) ||
                e.username.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return FollowsEmptyState(query: _query, sourceWasEmpty: all.isEmpty);
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: CkColors.hairline,
      ),
      itemBuilder: (context, i) => FollowerTile(entry: filtered[i]),
    );
  }
}
