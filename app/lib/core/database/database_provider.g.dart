// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single AppDatabase instance for the app lifetime.
///
/// Drift's executor owns a background isolate; creating multiple
/// instances would open multiple connections to the same sqlite file.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Single AppDatabase instance for the app lifetime.
///
/// Drift's executor owns a background isolate; creating multiple
/// instances would open multiple connections to the same sqlite file.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Single AppDatabase instance for the app lifetime.
  ///
  /// Drift's executor owns a background isolate; creating multiple
  /// instances would open multiple connections to the same sqlite file.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// Shared wizard-draft persistence (onboarding, team-create, ...). Lives here
/// to keep DB-provider definitions in a `*_provider*.dart` file per Rule 5;
/// the [WizardDraftStore] class itself stays in `wizard_draft_store.dart`.

@ProviderFor(wizardDraftStore)
final wizardDraftStoreProvider = WizardDraftStoreProvider._();

/// Shared wizard-draft persistence (onboarding, team-create, ...). Lives here
/// to keep DB-provider definitions in a `*_provider*.dart` file per Rule 5;
/// the [WizardDraftStore] class itself stays in `wizard_draft_store.dart`.

final class WizardDraftStoreProvider
    extends
        $FunctionalProvider<
          WizardDraftStore,
          WizardDraftStore,
          WizardDraftStore
        >
    with $Provider<WizardDraftStore> {
  /// Shared wizard-draft persistence (onboarding, team-create, ...). Lives here
  /// to keep DB-provider definitions in a `*_provider*.dart` file per Rule 5;
  /// the [WizardDraftStore] class itself stays in `wizard_draft_store.dart`.
  WizardDraftStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wizardDraftStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wizardDraftStoreHash();

  @$internal
  @override
  $ProviderElement<WizardDraftStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WizardDraftStore create(Ref ref) {
    return wizardDraftStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WizardDraftStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WizardDraftStore>(value),
    );
  }
}

String _$wizardDraftStoreHash() => r'17a684ac3a43d03bb28c01d58fe2ab025dc164dc';
