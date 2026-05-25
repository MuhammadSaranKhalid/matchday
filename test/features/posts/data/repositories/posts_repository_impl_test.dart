import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/exceptions.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/posts/data/datasources/posts_remote_datasource.dart';
import 'package:novex_clean_arch/features/posts/data/repositories/posts_repository_impl.dart';
import 'package:novex_clean_arch/features/posts/domain/entities/post_draft.dart';

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
}
