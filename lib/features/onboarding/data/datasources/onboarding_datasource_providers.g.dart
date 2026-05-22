// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(onboardingRemoteDataSource)
final onboardingRemoteDataSourceProvider =
    OnboardingRemoteDataSourceProvider._();

final class OnboardingRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          OnboardingRemoteDataSource,
          OnboardingRemoteDataSource,
          OnboardingRemoteDataSource
        >
    with $Provider<OnboardingRemoteDataSource> {
  OnboardingRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<OnboardingRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingRemoteDataSource create(Ref ref) {
    return onboardingRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingRemoteDataSource>(value),
    );
  }
}

String _$onboardingRemoteDataSourceHash() =>
    r'73cda2a0f71185760d5def18ce7d1745001442e9';
