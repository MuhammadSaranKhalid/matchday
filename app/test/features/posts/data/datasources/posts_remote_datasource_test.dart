import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matchday/features/posts/data/datasources/posts_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'creates a draft through authenticated REST with the client command ID',
    () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'postId': '20000000-0000-4000-8000-000000000001',
            'status': 'draft',
            'media': <Object>[],
          }),
          201,
        );
      });
      final remote = PostsRemoteDataSource(
        SupabaseClient('https://example.supabase.co', 'publishable-key'),
        backendBaseUrl: 'https://api.matchday.test',
        httpClient: client,
        accessTokenProvider: () => 'user-jwt',
      );

      await remote.createPostDraft(
        clientCommandId: '30000000-0000-4000-8000-000000000001',
        publisherType: 'user',
        publisherId: '10000000-0000-4000-8000-000000000001',
        postKind: 'standard',
        text: 'hello',
      );

      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'https://api.matchday.test/api/v1/posts');
      expect(captured.headers['authorization'], 'Bearer user-jwt');
      expect(
        (jsonDecode(captured.body) as Map<String, dynamic>)['clientCommandId'],
        '30000000-0000-4000-8000-000000000001',
      );
    },
  );

  test(
    'uploads bytes directly using the server-issued path and token',
    () async {
      String? path;
      String? token;
      final file = await File(
        '${Directory.systemTemp.path}/signed-upload.jpg',
      ).writeAsBytes([1, 2, 3]);
      addTearDown(() => file.delete());
      final remote = PostsRemoteDataSource(
        SupabaseClient('https://example.supabase.co', 'publishable-key'),
        signedUpload: (valuePath, valueToken, _) async {
          path = valuePath;
          token = valueToken;
        },
      );

      await remote.uploadSignedMedia(
        stagingPath: 'user/post/media/source.jpg',
        uploadToken: 'signed-token',
        file: file,
      );

      expect(path, 'user/post/media/source.jpg');
      expect(token, 'signed-token');
    },
  );

  test('publish and status use their single REST endpoints', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add('${request.method} ${request.url.path}');
      return http.Response(
        jsonEncode({
          'status': request.method == 'GET' ? 'published' : 'processing',
        }),
        200,
      );
    });
    final remote = PostsRemoteDataSource(
      SupabaseClient('https://example.supabase.co', 'publishable-key'),
      backendBaseUrl: 'https://api.matchday.test',
      httpClient: client,
      accessTokenProvider: () => 'user-jwt',
    );

    expect(await remote.publishPost('post-id'), 'processing');
    expect(await remote.getPostProcessingStatus('post-id'), 'published');
    expect(paths, [
      'POST /api/v1/posts/post-id/publish',
      'GET /api/v1/posts/post-id/status',
    ]);
  });
}
