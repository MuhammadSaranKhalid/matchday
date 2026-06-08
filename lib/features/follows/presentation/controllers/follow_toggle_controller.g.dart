// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_toggle_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the follow/unfollow toggle for a single target.
///
/// The family key is `(targetTypeWire, targetId)` — plain strings to keep
/// Riverpod's family cache key serialisable without a custom [FollowTarget].
///
/// State: [AsyncValue<bool>]
///   AsyncLoading  — initial fetch or in-flight toggle
///   AsyncData(true)  — user is following
///   AsyncData(false) — user is not following
///   AsyncError  — initial fetch failed (widget should show a disabled button)
///
/// Bare `@riverpod` (autodispose) — the controller disposes when no widget
/// is subscribed, e.g. when the team page or profile page is popped.

@ProviderFor(FollowToggle)
final followToggleProvider = FollowToggleFamily._();

/// Manages the follow/unfollow toggle for a single target.
///
/// The family key is `(targetTypeWire, targetId)` — plain strings to keep
/// Riverpod's family cache key serialisable without a custom [FollowTarget].
///
/// State: [AsyncValue<bool>]
///   AsyncLoading  — initial fetch or in-flight toggle
///   AsyncData(true)  — user is following
///   AsyncData(false) — user is not following
///   AsyncError  — initial fetch failed (widget should show a disabled button)
///
/// Bare `@riverpod` (autodispose) — the controller disposes when no widget
/// is subscribed, e.g. when the team page or profile page is popped.
final class FollowToggleProvider
    extends $AsyncNotifierProvider<FollowToggle, bool> {
  /// Manages the follow/unfollow toggle for a single target.
  ///
  /// The family key is `(targetTypeWire, targetId)` — plain strings to keep
  /// Riverpod's family cache key serialisable without a custom [FollowTarget].
  ///
  /// State: [AsyncValue<bool>]
  ///   AsyncLoading  — initial fetch or in-flight toggle
  ///   AsyncData(true)  — user is following
  ///   AsyncData(false) — user is not following
  ///   AsyncError  — initial fetch failed (widget should show a disabled button)
  ///
  /// Bare `@riverpod` (autodispose) — the controller disposes when no widget
  /// is subscribed, e.g. when the team page or profile page is popped.
  FollowToggleProvider._({
    required FollowToggleFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'followToggleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followToggleHash();

  @override
  String toString() {
    return r'followToggleProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  FollowToggle create() => FollowToggle();

  @override
  bool operator ==(Object other) {
    return other is FollowToggleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followToggleHash() => r'ce99872c6c0284740e0a4215b319728cf6295555';

/// Manages the follow/unfollow toggle for a single target.
///
/// The family key is `(targetTypeWire, targetId)` — plain strings to keep
/// Riverpod's family cache key serialisable without a custom [FollowTarget].
///
/// State: [AsyncValue<bool>]
///   AsyncLoading  — initial fetch or in-flight toggle
///   AsyncData(true)  — user is following
///   AsyncData(false) — user is not following
///   AsyncError  — initial fetch failed (widget should show a disabled button)
///
/// Bare `@riverpod` (autodispose) — the controller disposes when no widget
/// is subscribed, e.g. when the team page or profile page is popped.

final class FollowToggleFamily extends $Family
    with
        $ClassFamilyOverride<
          FollowToggle,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          (String, String)
        > {
  FollowToggleFamily._()
    : super(
        retry: null,
        name: r'followToggleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the follow/unfollow toggle for a single target.
  ///
  /// The family key is `(targetTypeWire, targetId)` — plain strings to keep
  /// Riverpod's family cache key serialisable without a custom [FollowTarget].
  ///
  /// State: [AsyncValue<bool>]
  ///   AsyncLoading  — initial fetch or in-flight toggle
  ///   AsyncData(true)  — user is following
  ///   AsyncData(false) — user is not following
  ///   AsyncError  — initial fetch failed (widget should show a disabled button)
  ///
  /// Bare `@riverpod` (autodispose) — the controller disposes when no widget
  /// is subscribed, e.g. when the team page or profile page is popped.

  FollowToggleProvider call(String targetTypeWire, String targetId) =>
      FollowToggleProvider._(argument: (targetTypeWire, targetId), from: this);

  @override
  String toString() => r'followToggleProvider';
}

/// Manages the follow/unfollow toggle for a single target.
///
/// The family key is `(targetTypeWire, targetId)` — plain strings to keep
/// Riverpod's family cache key serialisable without a custom [FollowTarget].
///
/// State: [AsyncValue<bool>]
///   AsyncLoading  — initial fetch or in-flight toggle
///   AsyncData(true)  — user is following
///   AsyncData(false) — user is not following
///   AsyncError  — initial fetch failed (widget should show a disabled button)
///
/// Bare `@riverpod` (autodispose) — the controller disposes when no widget
/// is subscribed, e.g. when the team page or profile page is popped.

abstract class _$FollowToggle extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as (String, String);
  String get targetTypeWire => _$args.$1;
  String get targetId => _$args.$2;

  FutureOr<bool> build(String targetTypeWire, String targetId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
