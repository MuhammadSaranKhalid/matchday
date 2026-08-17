// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_feed_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchesFeed)
final matchesFeedProvider = MatchesFeedProvider._();

final class MatchesFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<MatchesFeedState>,
          MatchesFeedState,
          FutureOr<MatchesFeedState>
        >
    with $FutureModifier<MatchesFeedState>, $FutureProvider<MatchesFeedState> {
  MatchesFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchesFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchesFeedHash();

  @$internal
  @override
  $FutureProviderElement<MatchesFeedState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MatchesFeedState> create(Ref ref) {
    return matchesFeed(ref);
  }
}

String _$matchesFeedHash() => r'f900a133566da5aa1fda175308cbe60828b33bd2';
