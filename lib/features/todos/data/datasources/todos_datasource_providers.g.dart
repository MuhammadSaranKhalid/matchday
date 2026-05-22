// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lives in its own file so the sync provider and the repository
/// provider can both depend on these without creating an import cycle.
///
/// (The pending-ops queue datasource moved to core/sync — it's shared by
/// every offline feature, not todos-specific.)

@ProviderFor(todosLocalDataSource)
final todosLocalDataSourceProvider = TodosLocalDataSourceProvider._();

/// Lives in its own file so the sync provider and the repository
/// provider can both depend on these without creating an import cycle.
///
/// (The pending-ops queue datasource moved to core/sync — it's shared by
/// every offline feature, not todos-specific.)

final class TodosLocalDataSourceProvider
    extends
        $FunctionalProvider<
          TodosLocalDataSource,
          TodosLocalDataSource,
          TodosLocalDataSource
        >
    with $Provider<TodosLocalDataSource> {
  /// Lives in its own file so the sync provider and the repository
  /// provider can both depend on these without creating an import cycle.
  ///
  /// (The pending-ops queue datasource moved to core/sync — it's shared by
  /// every offline feature, not todos-specific.)
  TodosLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todosLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todosLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<TodosLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TodosLocalDataSource create(Ref ref) {
    return todosLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodosLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodosLocalDataSource>(value),
    );
  }
}

String _$todosLocalDataSourceHash() =>
    r'805c2e4be43f9134acb4b776332ee4ff17abf149';

@ProviderFor(todosRemoteDataSource)
final todosRemoteDataSourceProvider = TodosRemoteDataSourceProvider._();

final class TodosRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TodosRemoteDataSource,
          TodosRemoteDataSource,
          TodosRemoteDataSource
        >
    with $Provider<TodosRemoteDataSource> {
  TodosRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todosRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todosRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TodosRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TodosRemoteDataSource create(Ref ref) {
    return todosRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodosRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodosRemoteDataSource>(value),
    );
  }
}

String _$todosRemoteDataSourceHash() =>
    r'68ab03318b03f28b7756874546b5a26933919cc2';
