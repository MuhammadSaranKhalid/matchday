import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';

part 'recent_searches_controller.g.dart';

/// Device-local search history for the Explore tab.
///
/// Backed by [WizardDraftStore] (the shared `wizard_drafts` drift table),
/// NOT by a new table and NOT by the network. Three reasons this is the right
/// home rather than an architectural exception:
///   - Search history is transient *presentation* state, not domain data —
///     exactly the case CLAUDE.md §6.5 sanctions a controller reaching for
///     `wizardDraftStoreProvider` directly, with no repository in between.
///   - `AppDatabase.clear()` wipes it on sign-out. For search history that is
///     a privacy feature, not a limitation: user B must never see user A's
///     searches on a shared device.
///   - It adds no dependency. `shared_preferences` is not in the pubspec, and
///     the analyzer constraint conflict documented in CLAUDE.md §4 makes
///     adding packages more expensive than it looks.
///
/// Reads and writes are best-effort — a lost history is a minor annoyance,
/// never an `Either<Failure, _>` the user has to handle.
@riverpod
class RecentSearches extends _$RecentSearches {
  /// Single key: the table is wiped on sign-out, so there is no cross-user
  /// leakage to guard against with a per-user suffix.
  static const _key = 'explore_recent_searches';

  static const _payloadField = 'queries';

  /// Deep enough to be useful, shallow enough that the list never pushes the
  /// suggestion chips off screen.
  static const _maxEntries = 8;

  @override
  Future<List<String>> build() async {
    final draft = await ref.read(wizardDraftStoreProvider).load(_key);
    final raw = draft?[_payloadField];
    if (raw is! List) return const [];
    return raw.whereType<String>().take(_maxEntries).toList();
  }

  /// Records a submitted query. Most-recent-first, case-insensitively
  /// de-duplicated so retyping the same search reorders rather than repeats.
  Future<void> record(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final current = state.value ?? const <String>[];
    final next = <String>[
      q,
      ...current.where((e) => e.toLowerCase() != q.toLowerCase()),
    ].take(_maxEntries).toList();

    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> remove(String query) async {
    final current = state.value ?? const <String>[];
    final next = current.where((e) => e != query).toList();
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> clearAll() async {
    state = const AsyncData(<String>[]);
    await ref.read(wizardDraftStoreProvider).clear(_key);
  }

  Future<void> _persist(List<String> queries) =>
      ref.read(wizardDraftStoreProvider).save(_key, {_payloadField: queries});
}
