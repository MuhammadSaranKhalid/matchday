import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/posts/data/datasources/posts_local_datasource.dart';
import 'package:matchday/features/posts/data/datasources/posts_remote_datasource.dart';
import 'package:matchday/features/posts/data/repositories/post_command_repository_impl.dart';
import 'package:matchday/features/posts/domain/entities/pending_post.dart';
import 'package:matchday/features/posts/domain/entities/post_draft.dart';
import 'package:mocktail/mocktail.dart';

ProcessedPhoto _photo() =>
    const ProcessedPhoto(filePath: 'x.jpg', width: 100, height: 100, fileSize: 1024);

class _MockRemote extends Mock implements PostsRemoteDataSource {}
class _MockLocal extends Mock implements PostsLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late PostCommandRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(PendingPost(
      postId: 'p1',
      text: 't',
      media: const [],
      status: PendingPostStatus.uploading,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(File('x.jpg'));
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repo = PostCommandRepositoryImpl(remote, local: local);

    when(() => remote.currentUserId).thenReturn('usr_1');
    when(() => local.savePendingPost(any())).thenAnswer((_) async {});
    when(() => local.removePendingPost(any())).thenAnswer((_) async {});
  });

  test('createPost maps UnauthorizedException → AuthFailure', () async {
    when(() => remote.beginPostPublish(
          publisherType: any(named: 'publisherType'),
          publisherId: any(named: 'publisherId'),
          postKind: any(named: 'postKind'),
          text: any(named: 'text'),
          expectedMediaCount: any(named: 'expectedMediaCount'),
          visibility: any(named: 'visibility'),
          idempotencyKey: any(named: 'idempotencyKey'),
          mediaManifest: any(named: 'mediaManifest'),
        )).thenThrow(const UnauthorizedException('nope'));

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

  test('acknowledgePublishedLocally removes pending post without calling abandonPostPublish', () async {
    when(() => local.getPendingPosts()).thenAnswer((_) async => [
          PendingPost(
            postId: 'p1',
            text: 'text',
            media: const [],
            status: PendingPostStatus.uploading,
            createdAt: DateTime.now(),
          ),
        ]);
    when(() => local.removePendingPost('p1')).thenAnswer((_) async {});

    await repo.acknowledgePublishedLocally('p1');

    verify(() => local.removePendingPost('p1')).called(1);
    verifyNever(() => remote.abandonPostPublish(any()));
  });

  test('discardPendingPost calls abandonPostPublish on remote and removes from local', () async {
    when(() => local.getPendingPosts()).thenAnswer((_) async => [
          PendingPost(
            postId: 'p1',
            text: 'text',
            media: const [],
            status: PendingPostStatus.failed,
            createdAt: DateTime.now(),
          ),
        ]);
    when(() => remote.abandonPostPublish('p1')).thenAnswer((_) async {});
    when(() => local.removePendingPost('p1')).thenAnswer((_) async {});

    await repo.discardPendingPost('p1');

    verify(() => remote.abandonPostPublish('p1')).called(1);
    verify(() => local.removePendingPost('p1')).called(1);
  });

  test('discardPendingPost while offline marks cancelRequested and retains local record', () async {
    when(() => local.getPendingPosts()).thenAnswer((_) async => [
          PendingPost(
            postId: 'p_offline',
            text: 'text',
            media: const [],
            status: PendingPostStatus.uploading,
            createdAt: DateTime.now(),
          ),
        ]);
    when(() => remote.abandonPostPublish('p_offline'))
        .thenThrow(const SocketException('No internet'));

    await repo.discardPendingPost('p_offline');

    // Should have saved with cancelRequested
    verify(() => local.savePendingPost(any(
          that: predicate<PendingPost>(
              (p) => p.status == PendingPostStatus.cancelRequested),
        ))).called(1);
    // Should NOT have removed the local record because remote failed
    verifyNever(() => local.removePendingPost('p_offline'));
  });

  test('recoverPendingPosts retries cancellation for cancelRequested posts', () async {
    when(() => local.getPendingPosts()).thenAnswer((_) async => [
          PendingPost(
            postId: 'p_cancel',
            text: 'text',
            media: const [],
            status: PendingPostStatus.cancelRequested,
            createdAt: DateTime.now(),
          ),
        ]);
    when(() => remote.abandonPostPublish('p_cancel')).thenAnswer((_) async {});
    when(() => local.removePendingPost('p_cancel')).thenAnswer((_) async {});

    await repo.recoverPendingPosts();

    verify(() => remote.abandonPostPublish('p_cancel')).called(1);
    verify(() => local.removePendingPost('p_cancel')).called(1);
  });
}
