// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(postsRemoteDataSource)
final postsRemoteDataSourceProvider = PostsRemoteDataSourceProvider._();

final class PostsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          PostsRemoteDataSource,
          PostsRemoteDataSource,
          PostsRemoteDataSource
        >
    with $Provider<PostsRemoteDataSource> {
  PostsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<PostsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PostsRemoteDataSource create(Ref ref) {
    return postsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostsRemoteDataSource>(value),
    );
  }
}

String _$postsRemoteDataSourceHash() =>
    r'fc2a1ba6b774cbe01bb26a9a77ce890fba04419b';

@ProviderFor(commentsRemoteDataSource)
final commentsRemoteDataSourceProvider = CommentsRemoteDataSourceProvider._();

final class CommentsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          CommentsRemoteDataSource,
          CommentsRemoteDataSource,
          CommentsRemoteDataSource
        >
    with $Provider<CommentsRemoteDataSource> {
  CommentsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<CommentsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CommentsRemoteDataSource create(Ref ref) {
    return commentsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommentsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommentsRemoteDataSource>(value),
    );
  }
}

String _$commentsRemoteDataSourceHash() =>
    r'5873364a62ba53ad87fd8e491614b8f209813878';

@ProviderFor(photoPicker)
final photoPickerProvider = PhotoPickerProvider._();

final class PhotoPickerProvider
    extends $FunctionalProvider<PhotoPicker, PhotoPicker, PhotoPicker>
    with $Provider<PhotoPicker> {
  PhotoPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoPickerHash();

  @$internal
  @override
  $ProviderElement<PhotoPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoPicker create(Ref ref) {
    return photoPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoPicker>(value),
    );
  }
}

String _$photoPickerHash() => r'72f4456ae6d1aaeb034680e55cb5899663762616';
