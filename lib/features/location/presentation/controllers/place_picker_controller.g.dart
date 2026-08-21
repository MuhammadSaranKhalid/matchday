// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_picker_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives one place-autocomplete field.
///
/// Keyed by [field] so two pickers on the same screen (say a team's city and
/// its home ground) keep independent state and independent billing sessions.
///
/// Session tokens: Google bills autocomplete keystrokes as one session when
/// they share a token and that token is passed to the eventual details call.
/// A new token is minted after every resolution — reusing one across
/// selections is billed as separate sessions anyway and muddies analytics.

@ProviderFor(PlacePicker)
final placePickerProvider = PlacePickerFamily._();

/// Drives one place-autocomplete field.
///
/// Keyed by [field] so two pickers on the same screen (say a team's city and
/// its home ground) keep independent state and independent billing sessions.
///
/// Session tokens: Google bills autocomplete keystrokes as one session when
/// they share a token and that token is passed to the eventual details call.
/// A new token is minted after every resolution — reusing one across
/// selections is billed as separate sessions anyway and muddies analytics.
final class PlacePickerProvider
    extends $NotifierProvider<PlacePicker, PlacePickerState> {
  /// Drives one place-autocomplete field.
  ///
  /// Keyed by [field] so two pickers on the same screen (say a team's city and
  /// its home ground) keep independent state and independent billing sessions.
  ///
  /// Session tokens: Google bills autocomplete keystrokes as one session when
  /// they share a token and that token is passed to the eventual details call.
  /// A new token is minted after every resolution — reusing one across
  /// selections is billed as separate sessions anyway and muddies analytics.
  PlacePickerProvider._({
    required PlacePickerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placePickerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placePickerHash();

  @override
  String toString() {
    return r'placePickerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlacePicker create() => PlacePicker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacePickerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlacePickerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlacePickerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placePickerHash() => r'93cfb1bf5b35b7cf72300de7c5b610405b967420';

/// Drives one place-autocomplete field.
///
/// Keyed by [field] so two pickers on the same screen (say a team's city and
/// its home ground) keep independent state and independent billing sessions.
///
/// Session tokens: Google bills autocomplete keystrokes as one session when
/// they share a token and that token is passed to the eventual details call.
/// A new token is minted after every resolution — reusing one across
/// selections is billed as separate sessions anyway and muddies analytics.

final class PlacePickerFamily extends $Family
    with
        $ClassFamilyOverride<
          PlacePicker,
          PlacePickerState,
          PlacePickerState,
          PlacePickerState,
          String
        > {
  PlacePickerFamily._()
    : super(
        retry: null,
        name: r'placePickerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives one place-autocomplete field.
  ///
  /// Keyed by [field] so two pickers on the same screen (say a team's city and
  /// its home ground) keep independent state and independent billing sessions.
  ///
  /// Session tokens: Google bills autocomplete keystrokes as one session when
  /// they share a token and that token is passed to the eventual details call.
  /// A new token is minted after every resolution — reusing one across
  /// selections is billed as separate sessions anyway and muddies analytics.

  PlacePickerProvider call(String field) =>
      PlacePickerProvider._(argument: field, from: this);

  @override
  String toString() => r'placePickerProvider';
}

/// Drives one place-autocomplete field.
///
/// Keyed by [field] so two pickers on the same screen (say a team's city and
/// its home ground) keep independent state and independent billing sessions.
///
/// Session tokens: Google bills autocomplete keystrokes as one session when
/// they share a token and that token is passed to the eventual details call.
/// A new token is minted after every resolution — reusing one across
/// selections is billed as separate sessions anyway and muddies analytics.

abstract class _$PlacePicker extends $Notifier<PlacePickerState> {
  late final _$args = ref.$arg as String;
  String get field => _$args;

  PlacePickerState build(String field);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlacePickerState, PlacePickerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlacePickerState, PlacePickerState>,
              PlacePickerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
