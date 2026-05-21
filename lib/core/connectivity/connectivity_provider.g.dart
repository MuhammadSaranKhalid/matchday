// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream of online/offline status.
///
/// `connectivity_plus` returns a list of active interfaces; we collapse
/// that to a single bool — any interface other than `none` counts as
/// online. This is a heuristic; actual reachability is verified by the
/// sync service when it tries to push.

@ProviderFor(isOnline)
final isOnlineProvider = IsOnlineProvider._();

/// Stream of online/offline status.
///
/// `connectivity_plus` returns a list of active interfaces; we collapse
/// that to a single bool — any interface other than `none` counts as
/// online. This is a heuristic; actual reachability is verified by the
/// sync service when it tries to push.

final class IsOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Stream of online/offline status.
  ///
  /// `connectivity_plus` returns a list of active interfaces; we collapse
  /// that to a single bool — any interface other than `none` counts as
  /// online. This is a heuristic; actual reachability is verified by the
  /// sync service when it tries to push.
  IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return isOnline(ref);
  }
}

String _$isOnlineHash() => r'42210c7695e7cc09c50230d3bfb48d06f1056e2b';
