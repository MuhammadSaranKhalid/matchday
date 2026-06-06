import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/messages_datasource_providers.dart';
import '../../data/repositories/messages_repository_impl.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/messages_repository.dart';

part 'messages_providers.g.dart';

@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) =>
    MessagesRepositoryImpl(ref.watch(messagesRemoteDataSourceProvider));

/// The chat inbox as a fan-out stream: one upstream subscription, many UI
/// consumers. Per CLAUDE.md §5.3, intermediate `@riverpod Stream` providers
/// belong here rather than in a controller — the inbox screen has no write
/// path in part 1 of the rollout.
@riverpod
Stream<List<Chat>> myChats(Ref ref) =>
    ref.watch(messagesRepositoryProvider).watchMyChats();
