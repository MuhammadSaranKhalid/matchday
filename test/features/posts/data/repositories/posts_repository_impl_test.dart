import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/posts/data/datasources/posts_remote_datasource.dart';
import 'package:matchday/features/posts/data/repositories/posts_repository_impl.dart';
import 'package:matchday/features/posts/domain/entities/post_draft.dart';

ProcessedPhoto _photo() =>
    ProcessedPhoto(file: File('x.webp'), blurhash: 'L', width: 1, height: 1);

class _MockRemote extends Mock implements PostsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late PostsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = PostsRepositoryImpl(remote);
  });

  test('getFeed maps ServerException → ServerFailure', () async {
    when(() => remote.getFeed(limit: any(named: 'limit'), before: any(named: 'before')))
        .thenThrow(ServerException('boom'));
    final result = await repo.getFeed();
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });

  test('createPost maps UnauthorizedException → AuthFailure', () async {
    when(() => remote.insertPost(any()))
        .thenThrow(UnauthorizedException('nope'));
    final result = await repo.createPost(const PostDraft(text: 'hi'));
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<AuthFailure>());
    // Text-only post: no media upload attempted.
    verifyNever(() => remote.uploadMedia(any(), any()));
  });

  test('createPost rejects an empty draft (no text, no photos)', () async {
    final result = await repo.createPost(const PostDraft(text: '   '));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => remote.insertPost(any()));
  });

  test('createPost rejects text over 2000 chars', () async {
    final result = await repo.createPost(PostDraft(text: 'a' * 2001));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => remote.insertPost(any()));
  });

  test('createPost rejects more than 4 photos', () async {
    final result = await repo
        .createPost(PostDraft(photos: List.generate(5, (_) => _photo())));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => remote.insertPost(any()));
  });
}
