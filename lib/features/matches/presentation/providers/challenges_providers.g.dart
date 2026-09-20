// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenges_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds the Challenges queue — `Challenges.dc.html`.
///
/// Sorted nearest-to-expiry first on BOTH tabs. That ordering is the design's
/// primary urgency device: "the list is sorted by time-to-die, so the top row
/// is always the one about to go — position carries the urgency for free, and
/// no row needs to shout."

@ProviderFor(challengesView)
final challengesViewProvider = ChallengesViewProvider._();

/// Builds the Challenges queue — `Challenges.dc.html`.
///
/// Sorted nearest-to-expiry first on BOTH tabs. That ordering is the design's
/// primary urgency device: "the list is sorted by time-to-die, so the top row
/// is always the one about to go — position carries the urgency for free, and
/// no row needs to shout."

final class ChallengesViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChallengesView>,
          ChallengesView,
          FutureOr<ChallengesView>
        >
    with $FutureModifier<ChallengesView>, $FutureProvider<ChallengesView> {
  /// Builds the Challenges queue — `Challenges.dc.html`.
  ///
  /// Sorted nearest-to-expiry first on BOTH tabs. That ordering is the design's
  /// primary urgency device: "the list is sorted by time-to-die, so the top row
  /// is always the one about to go — position carries the urgency for free, and
  /// no row needs to shout."
  ChallengesViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challengesViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challengesViewHash();

  @$internal
  @override
  $FutureProviderElement<ChallengesView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChallengesView> create(Ref ref) {
    return challengesView(ref);
  }
}

String _$challengesViewHash() => r'cf2f74582b9c9299cb9424ea65c87842804ac67f';
