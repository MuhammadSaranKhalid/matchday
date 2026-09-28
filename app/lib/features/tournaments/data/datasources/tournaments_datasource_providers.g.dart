// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournaments_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tournamentsRemoteDataSource)
final tournamentsRemoteDataSourceProvider =
    TournamentsRemoteDataSourceProvider._();

final class TournamentsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TournamentsRemoteDataSource,
          TournamentsRemoteDataSource,
          TournamentsRemoteDataSource
        >
    with $Provider<TournamentsRemoteDataSource> {
  TournamentsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tournamentsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tournamentsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TournamentsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TournamentsRemoteDataSource create(Ref ref) {
    return tournamentsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TournamentsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TournamentsRemoteDataSource>(value),
    );
  }
}

String _$tournamentsRemoteDataSourceHash() =>
    r'775e1a7e054cc8e40c8a22c2beaff50c8b0824b1';

/// Returns the abstract type: the wizard and settings screen depend on the
/// contract, not on the image_picker/cropper stack behind it.

@ProviderFor(tournamentArtworkPicker)
final tournamentArtworkPickerProvider = TournamentArtworkPickerProvider._();

/// Returns the abstract type: the wizard and settings screen depend on the
/// contract, not on the image_picker/cropper stack behind it.

final class TournamentArtworkPickerProvider
    extends
        $FunctionalProvider<
          TournamentArtworkPicker,
          TournamentArtworkPicker,
          TournamentArtworkPicker
        >
    with $Provider<TournamentArtworkPicker> {
  /// Returns the abstract type: the wizard and settings screen depend on the
  /// contract, not on the image_picker/cropper stack behind it.
  TournamentArtworkPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tournamentArtworkPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tournamentArtworkPickerHash();

  @$internal
  @override
  $ProviderElement<TournamentArtworkPicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TournamentArtworkPicker create(Ref ref) {
    return tournamentArtworkPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TournamentArtworkPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TournamentArtworkPicker>(value),
    );
  }
}

String _$tournamentArtworkPickerHash() =>
    r'e33abea5aebe39cc9e93e17b1002d6d4a6ad78c2';
