import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/repositories/photo_picker.dart';
import '../datasources/comments_remote_datasource.dart';
import 'photo_processor.dart';
import 'posts_local_datasource.dart';
import 'posts_remote_datasource.dart';

part 'posts_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
PostsRemoteDataSource postsRemoteDataSource(Ref ref) =>
    PostsRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
PostsLocalDataSource postsLocalDataSource(Ref ref) =>
    PostsLocalDataSourceImpl();

@Riverpod(keepAlive: true)
CommentsRemoteDataSource commentsRemoteDataSource(Ref ref) =>
    CommentsRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
PhotoPicker photoPicker(Ref ref) => const PhotoProcessor();
