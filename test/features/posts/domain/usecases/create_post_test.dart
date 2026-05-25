import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/posts/domain/entities/post.dart';
import 'package:novex_clean_arch/features/posts/domain/entities/post_draft.dart';
import 'package:novex_clean_arch/features/posts/domain/repositories/posts_repository.dart';
import 'package:novex_clean_arch/features/posts/domain/usecases/create_post.dart';

class _MockPostsRepo extends Mock implements PostsRepository {}

ProcessedPhoto _photo() =>
    ProcessedPhoto(file: File('x.webp'), blurhash: 'L', width: 1, height: 1);

Post _post() => Post(
      id: const PostId('p1'),
      authorId: 'u1',
      authorContext: PostAuthorContext.personal,
      type: PostType.text,
      text: 'hi',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late _MockPostsRepo repo;
  late CreatePost useCase;

  setUpAll(() => registerFallbackValue(const PostDraft()));
  setUp(() {
    repo = _MockPostsRepo();
    useCase = CreatePost(repo);
  });

  test('rejects an empty draft (no text, no photos) without hitting the repo',
      () async {
    final result = await useCase(const PostDraft(text: '   '));
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.createPost(any()));
  });

  test('rejects text over 2000 chars', () async {
    final result = await useCase(PostDraft(text: 'a' * 2001));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.createPost(any()));
  });

  test('rejects more than 4 photos', () async {
    final result =
        await useCase(PostDraft(photos: List.generate(5, (_) => _photo())));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.createPost(any()));
  });

  test('forwards a valid photo-only draft (trimmed null text) to the repo',
      () async {
    when(() => repo.createPost(any()))
        .thenAnswer((_) async => Right(_post()));
    final result = await useCase(PostDraft(photos: [_photo()]));
    expect(result.isRight(), isTrue);
    final captured =
        verify(() => repo.createPost(captureAny())).captured.single as PostDraft;
    expect(captured.text, isNull);
    expect(captured.photos.length, 1);
  });

  test('trims valid text before forwarding', () async {
    when(() => repo.createPost(any()))
        .thenAnswer((_) async => Right(_post()));
    await useCase(const PostDraft(text: '  hello  '));
    final captured =
        verify(() => repo.createPost(captureAny())).captured.single as PostDraft;
    expect(captured.text, 'hello');
  });
}
