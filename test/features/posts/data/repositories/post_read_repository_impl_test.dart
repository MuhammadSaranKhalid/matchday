import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/posts/data/datasources/posts_remote_datasource.dart';
import 'package:matchday/features/posts/data/repositories/post_read_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements PostsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late PostReadRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = PostReadRepositoryImpl(remote);
  });

  test('getHomeFeed maps ServerException → ServerFailure', () async {
    when(() => remote.getHomeFeed(
          filter: any(named: 'filter'),
          cursorPublishedAt: any(named: 'cursorPublishedAt'),
          cursorPostId: any(named: 'cursorPostId'),
          limit: any(named: 'limit'),
        )).thenThrow(ServerException('boom'));

    final result = await repo.getHomeFeed();
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });
}
