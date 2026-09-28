// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cricket_player_profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the [CricketPlayerProfile] for [userId].
///
/// Returns `null` when the user has no Cricket-specific profile attributes.
/// Player identity itself is represented by `player_sports`.
/// Throws [FailureWrapper] on network/server errors so the UI can pattern-match
/// `AsyncError` normally.

@ProviderFor(cricketPlayerProfile)
final cricketPlayerProfileProvider = CricketPlayerProfileFamily._();

/// Fetches the [CricketPlayerProfile] for [userId].
///
/// Returns `null` when the user has no Cricket-specific profile attributes.
/// Player identity itself is represented by `player_sports`.
/// Throws [FailureWrapper] on network/server errors so the UI can pattern-match
/// `AsyncError` normally.

final class CricketPlayerProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<CricketPlayerProfile?>,
          CricketPlayerProfile?,
          FutureOr<CricketPlayerProfile?>
        >
    with
        $FutureModifier<CricketPlayerProfile?>,
        $FutureProvider<CricketPlayerProfile?> {
  /// Fetches the [CricketPlayerProfile] for [userId].
  ///
  /// Returns `null` when the user has no Cricket-specific profile attributes.
  /// Player identity itself is represented by `player_sports`.
  /// Throws [FailureWrapper] on network/server errors so the UI can pattern-match
  /// `AsyncError` normally.
  CricketPlayerProfileProvider._({
    required CricketPlayerProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cricketPlayerProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cricketPlayerProfileHash();

  @override
  String toString() {
    return r'cricketPlayerProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CricketPlayerProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CricketPlayerProfile?> create(Ref ref) {
    final argument = this.argument as String;
    return cricketPlayerProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CricketPlayerProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cricketPlayerProfileHash() =>
    r'53090d1985ba4e6c58c9588ca682ef0c35e93dc9';

/// Fetches the [CricketPlayerProfile] for [userId].
///
/// Returns `null` when the user has no Cricket-specific profile attributes.
/// Player identity itself is represented by `player_sports`.
/// Throws [FailureWrapper] on network/server errors so the UI can pattern-match
/// `AsyncError` normally.

final class CricketPlayerProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CricketPlayerProfile?>, String> {
  CricketPlayerProfileFamily._()
    : super(
        retry: null,
        name: r'cricketPlayerProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches the [CricketPlayerProfile] for [userId].
  ///
  /// Returns `null` when the user has no Cricket-specific profile attributes.
  /// Player identity itself is represented by `player_sports`.
  /// Throws [FailureWrapper] on network/server errors so the UI can pattern-match
  /// `AsyncError` normally.

  CricketPlayerProfileProvider call(String userId) =>
      CricketPlayerProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'cricketPlayerProfileProvider';
}
