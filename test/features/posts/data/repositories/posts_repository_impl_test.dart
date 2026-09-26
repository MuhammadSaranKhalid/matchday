import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/posts/data/datasources/posts_local_datasource.dart';
import 'package:matchday/features/posts/data/datasources/posts_remote_datasource.dart';
import 'package:matchday/features/posts/data/repositories/posts_repository_impl.dart';
import 'package:matchday/features/posts/domain/entities/pending_post.dart';
import 'package:matchday/features/posts/domain/entities/post_draft.dart';
import 'package:mocktail/mocktail.dart';

ProcessedPhoto _photo() =>
    ProcessedPhoto(file: File('x.jpg'), blurhash: '', width: 100, height: 100);

class _MockRemote extends Mock implements PostsRemoteDataSource {}
class _MockLocal extends Mock implements PostsLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late PostsRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(PendingPost(
      postId: 'p1',
      text: 't',
      localMediaPaths: const [],
      status: PendingPostStatus.uploading,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(File('x.jpg'));
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repo = PostsRepositoryImpl(remote, local: local);

    when(() => remote.currentUserId).thenReturn('usr_1');
    when(() => local.savePendingPost(any())).thenAnswer((_) async {});
    when(() => local.removePendingPost(any())).thenAnswer((_) async {});
  });

  test('getHomeFeed maps ServerException → ServerFailure', () async {
    when(() => remote.getHomeFeed(
          mode: any(named: 'mode'),
          filter: any(named: 'filter'),
          targetId: any(named: 'targetId'),
          cursorPublishedAt: any(named: 'cursorPublishedAt'),
          cursorPostId: any(named: 'cursorPostId'),
          limit: any(named: 'limit'),
        )).thenThrow(ServerException('boom'));

    final result = await repo.getHomeFeed();
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });

  test('createPost maps UnauthorizedException → AuthFailure', () async {
    when(() => remote.beginPostPublish(
          publisherType: any(named: 'publisherType'),
          publisherId: any(named: 'publisherId'),
          postKind: any(named: 'postKind'),
          text: any(named: 'text'),
          expectedMediaCount: any(named: 'expectedMediaCount'),
          mediaItems: any(named: 'mediaItems'),
        )).thenThrow(UnauthorizedException('nope'));

    final result = await repo.createPost(const PostDraft(text: 'hi'));
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<AuthFailure>());
    verifyNever(() => remote.uploadStagingMedia(
          stagingPath: any(named: 'stagingPath'),
          file: any(named: 'file'),
        ));
  });

  test('createPost rejects an empty draft (no text, no photos)', () async {
    final result = await repo.createPost(const PostDraft(text: '   '));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => remote.beginPostPublish(
          publisherType: any(named: 'publisherType'),
          publisherId: any(named: 'publisherId'),
          postKind: any(named: 'postKind'),
          text: any(named: 'text'),
          expectedMediaCount: any(named: 'expectedMediaCount'),
        ));
  });

  test('createPost rejects text over 2000 chars', () async {
    final result = await repo.createPost(PostDraft(text: 'a' * 2001));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => remote.beginPostPublish(
          publisherType: any(named: 'publisherType'),
          publisherId: any(named: 'publisherId'),
          postKind: any(named: 'postKind'),
          text: any(named: 'text'),
          expectedMediaCount: any(named: 'expectedMediaCount'),
        ));
  });

  test('createPost rejects more than 4 photos', () async {
    final result = await repo
        .createPost(PostDraft(photos: List.generate(5, (_) => _photo())));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => remote.beginPostPublish(
          publisherType: any(named: 'publisherType'),
          publisherId: any(named: 'publisherId'),
          postKind: any(named: 'postKind'),
          text: any(named: 'text'),
          expectedMediaCount: any(named: 'expectedMediaCount'),
        ));
  });
}
