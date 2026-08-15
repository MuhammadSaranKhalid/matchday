import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../domain/value_objects/message_body.dart';
import '../datasources/messages_local_datasource.dart';
import '../datasources/messages_remote_datasource.dart';

/// Online-only impl with a read-through local cache for inbox + threads
/// (ticket #23, paradigm C). Reads emit the cache value first for an
/// instant first frame, then layer network values on top. Writes go
/// network-first; the remote data source handles the cache write-through
/// internally so single-row patches don't get amplified into bulk writes.
///
/// Drafts are local-only — backed by drift, never touch the network.
class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote, this._local);
  final MessagesRemoteDataSource _remote;
  final MessagesLocalDataSource _local;

  // ─── Reads ────────────────────────────────────────────────────────────

  @override
  Stream<List<Chat>> watchMyChats() async* {
    // Cache emit — instant first frame on cold start. Safe to call even
    // when empty; consumers should handle an empty list (the screen already
    // has an "empty" branch).
    final cached = await _local.listChats();
    if (cached.isNotEmpty) yield cached;

    // Network emits the initial fetch followed by realtime-patched updates.
    // The remote data source handles cache write-through for each emission
    // so we don't need to do it here.
    yield* _remote
        .watchMyChats()
        .map((dtos) => dtos.map((d) => d.toEntity()).toList(growable: false))
        .handleError((Object e) => throw FailureWrapper(switch (e) {
              UnauthorizedException() => AuthFailure(e.message),
              NetworkException() => NetworkFailure(e.message),
              ServerException() => ServerFailure(e.message),
              _ => UnknownFailure(e.toString()),
            }));
  }

  @override
  Stream<List<Message>> watchMessages(ChatId chatId) async* {
    final cached = await _local.listMessages(chatId.value);
    if (cached.isNotEmpty) yield cached;

    yield* _remote
        .watchMessages(chatId.value)
        .map((dtos) => dtos.map((d) => d.toEntity()).toList(growable: false))
        .handleError((Object e) => throw FailureWrapper(switch (e) {
              UnauthorizedException() => AuthFailure(e.message),
              NetworkException() => NetworkFailure(e.message),
              ServerException() => ServerFailure(e.message),
              _ => UnknownFailure(e.toString()),
            }));
  }

  // ─── Writes ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Message>> sendMessage(
    ChatId chatId,
    MessageBody body, {
    String? replyToId,
  }) async {
    try {
      final dto = await _remote.sendMessage(
        chatId: chatId.value,
        body: body.value,
        replyToId: replyToId,
      );
      // The data source already wrote the message + own-send inbox patch
      // to the cache. We just clear the draft for this chat.
      await _local.deleteDraft(chatId.value);
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendImageMessage(
    ChatId chatId, {
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  }) async {
    try {
      final url = await _remote.uploadChatImage(
        bytes: Uint8List.fromList(imageBytes),
        extension: extension,
      );
      final dto = await _remote.sendMessage(
        chatId: chatId.value,
        body: (caption != null && caption.trim().isNotEmpty) ? caption.trim() : 'Photo',
        messageType: 'image',
        payload: {'media_url': url},
        replyToId: replyToId,
      );
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    ChatId chatId,
    MessageId messageId,
  ) async {
    try {
      await _remote.deleteMessage(
        chatId: chatId.value,
        messageId: messageId.value,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> loadOlderMessages(ChatId chatId) async {
    try {
      final count = await _remote.loadOlderMessages(chatId.value);
      return Right(count);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markRead(ChatId chatId) async {
    try {
      await _remote.markRead(chatId.value);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatId>> getOrCreateDmChat(String targetUserId) async {
    try {
      final chatIdStr = await _remote.getOrCreateDmChat(targetUserId);
      return Right(ChatId(chatIdStr));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }


  // ─── Drafts ───────────────────────────────────────────────────────────

  @override
  Future<String?> readDraft(ChatId chatId) =>
      _local.readDraft(chatId.value);

  @override
  Future<void> saveDraft(ChatId chatId, String body) =>
      _local.saveDraft(chatId.value, body);

  @override
  Future<void> deleteDraft(ChatId chatId) =>
      _local.deleteDraft(chatId.value);
}
