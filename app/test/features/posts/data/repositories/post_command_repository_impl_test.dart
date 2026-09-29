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

class _MockRemote extends Mock implements PostsRemoteDataSource {}

class _MockLocal extends Mock implements PostsLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late List<PendingPost> stored;
  late PostCommandRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(File('fallback.jpg'));
    registerFallbackValue(
      PendingPost(postId: 'fallback', createdAt: DateTime(2026)),
    );
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    stored = [];
    repository = PostCommandRepositoryImpl(remote, local: local);
    when(
      () => remote.currentUserId,
    ).thenReturn('10000000-0000-4000-8000-000000000001');
    when(() => local.getPendingPosts()).thenAnswer((_) async => [...stored]);
    when(() => local.savePendingPost(any())).thenAnswer((call) async {
      final post = call.positionalArguments.single as PendingPost;
      stored.removeWhere((item) => item.postId == post.postId);
      stored.add(post);
    });
    when(() => local.removePendingPost(any())).thenAnswer((call) async {
      stored.removeWhere(
        (item) => item.postId == call.positionalArguments.single,
      );
    });
  });

  test(
    'persists command before create and publishes a text-only draft',
    () async {
      var persistedBeforeCreate = false;
      when(
        () => remote.createPostDraft(
          clientCommandId: any(named: 'clientCommandId'),
          publisherType: any(named: 'publisherType'),
          publisherId: any(named: 'publisherId'),
          postKind: any(named: 'postKind'),
          text: any(named: 'text'),
          mediaManifest: any(named: 'mediaManifest'),
        )).thenThrow(UnauthorizedException('nope'));

      final result = await repository.createPost(
        const PostDraft(text: 'hello'),
      );

      expect(result.isRight(), isTrue);
      expect(persistedBeforeCreate, isTrue);
      verify(
        () => remote.publishPost('20000000-0000-4000-8000-000000000001'),
      ).called(1);
      expect(stored, isEmpty);
    },
  );

  test('retains durable command when backend authentication fails', () async {
    when(
      () => remote.createPostDraft(
        clientCommandId: any(named: 'clientCommandId'),
        publisherType: any(named: 'publisherType'),
        publisherId: any(named: 'publisherId'),
        postKind: any(named: 'postKind'),
        text: any(named: 'text'),
        mediaManifest: any(named: 'mediaManifest'),
      ),
    ).thenThrow(const UnauthorizedException('nope'));

    final result = await repository.createPost(const PostDraft(text: 'hello'));

    expect(result.getLeft().toNullable(), isA<AuthFailure>());
    expect(stored.single.clientCommandId, isNotEmpty);
  });

  test('uploads at most two images concurrently then publishes once', () async {
    final directory = await Directory.systemTemp.createTemp('matchday-post-');
    addTearDown(() => directory.delete(recursive: true));
    final photos = <ProcessedPhoto>[];
    for (var index = 0; index < 3; index++) {
      final file = await File(
        '${directory.path}/$index.jpg',
      ).writeAsBytes([index]);
      photos.add(
        ProcessedPhoto(filePath: file.path, width: 10, height: 10, fileSize: 1),
      );
    }
    when(
      () => remote.createPostDraft(
        clientCommandId: any(named: 'clientCommandId'),
        publisherType: any(named: 'publisherType'),
        publisherId: any(named: 'publisherId'),
        postKind: any(named: 'postKind'),
        text: any(named: 'text'),
        mediaManifest: any(named: 'mediaManifest'),
      ),
    ).thenAnswer(
      (_) async => {
        'postId': '20000000-0000-4000-8000-000000000002',
        'media': List.generate(
          3,
          (index) => {
            'mediaId': '50000000-0000-4000-8000-00000000000$index',
            'position': index,
            'stagingPath': 'u/p/$index/source.jpg',
            'uploadToken': 'token-$index',
          },
        ),
      },
    );
    var active = 0;
    var maximumActive = 0;
    when(
      () => remote.uploadSignedMedia(
        stagingPath: any(named: 'stagingPath'),
        uploadToken: any(named: 'uploadToken'),
        file: any(named: 'file'),
      ),
    ).thenAnswer((_) async {
      active++;
      if (active > maximumActive) maximumActive = active;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      active--;
    });
    when(() => remote.publishPost(any())).thenAnswer((_) async => 'processing');
    when(
      () => remote.getPostProcessingStatus(any()),
    ).thenAnswer((_) async => 'failed');

    final result = await repository.createPost(
      PostDraft(text: 'photos', photos: photos),
    );
    expect(result.isRight(), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(maximumActive, 2);
    verify(
      () => remote.uploadSignedMedia(
        stagingPath: any(named: 'stagingPath'),
        uploadToken: any(named: 'uploadToken'),
        file: any(named: 'file'),
      ),
    ).called(3);
    verify(
      () => remote.publishPost('20000000-0000-4000-8000-000000000002'),
    ).called(1);
  });

  test(
    'recovery removes local source after backend reports published',
    () async {
      final file = await File(
        '${Directory.systemTemp.path}/matchday-ready.jpg',
      ).writeAsBytes([1]);
      stored.add(
        PendingPost(
          postId: '20000000-0000-4000-8000-000000000003',
          clientCommandId: '30000000-0000-4000-8000-000000000003',
          createdAt: DateTime(2026),
          status: PendingPostStatus.publishing,
          media: [
            PendingMediaItem(
              mediaId: '50000000-0000-4000-8000-000000000003',
              position: 0,
              localPath: file.path,
              stagingPath: 'u/p/m/source.jpg',
              uploaded: true,
            ),
          ],
        ),
      );
      when(
        () => remote.getPostProcessingStatus(any()),
      ).thenAnswer((_) async => 'published');

      await repository.recoverPendingPosts();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(stored, isEmpty);
      expect(await file.exists(), isFalse);
    },
  );

  test(
    'recovery exposes retry and discard state after processing failure',
    () async {
      stored.add(
        PendingPost(
          postId: '20000000-0000-4000-8000-000000000004',
          clientCommandId: '30000000-0000-4000-8000-000000000004',
          createdAt: DateTime(2026),
          status: PendingPostStatus.publishing,
          media: const [
            PendingMediaItem(
              mediaId: '50000000-0000-4000-8000-000000000004',
              position: 0,
              localPath: '',
              stagingPath: 'u/p/m/source.jpg',
              uploaded: true,
            ),
          ],
        ),
      );
      when(
        () => remote.getPostProcessingStatus(any()),
      ).thenAnswer((_) async => 'failed');

      await repository.recoverPendingPosts();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(stored.single.status, PendingPostStatus.failed);
      expect(stored.single.errorMessage, 'Image processing failed');
    },
  );

  test('rejects empty drafts and more than four photos', () async {
    final empty = await repository.createPost(const PostDraft(text: '   '));
    final tooMany = await repository.createPost(
      PostDraft(
        photos: List.generate(
          5,
          (_) => const ProcessedPhoto(
            filePath: 'x.jpg',
            width: 1,
            height: 1,
            fileSize: 1,
          ),
        ),
      ),
    );
    expect(empty.getLeft().toNullable(), isA<ValidationFailure>());
    expect(tooMany.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
