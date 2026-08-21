// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_searches_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(RecentSearches)
final recentSearchesProvider = RecentSearchesProvider._();

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
final class RecentSearchesProvider
    extends $AsyncNotifierProvider<RecentSearches, List<String>> {
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
  RecentSearchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchesHash();

  @$internal
  @override
  RecentSearches create() => RecentSearches();
}

String _$recentSearchesHash() => r'ab3ca5ed682c412b3d2976fc2cb4cde06e4e3192';

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

abstract class _$RecentSearches extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
