import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../domain/value_objects/message_body.dart';
import '../datasources/messages_remote_datasource.dart';

/// Online-only impl of the messages contract. Streams use `.handleError` +
/// [FailureWrapper] so typed failures survive the stream boundary; one-shot
/// writes return `Either<Failure, T>` directly.
class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);
  final MessagesRemoteDataSource _remote;

  // ─── Reads ────────────────────────────────────────────────────────────

  @override
  Stream<List<Chat>> watchMyChats() => _remote
      .watchMyChats()
      .map((dtos) => dtos.map((d) => d.toEntity()).toList(growable: false))
      .handleError(_throwAsFailure);

  @override
  Stream<List<Message>> watchMessages(ChatId chatId) => _remote
      .watchMessages(chatId.value)
      .map((dtos) => dtos.map((d) => d.toEntity()).toList(growable: false))
      .handleError(_throwAsFailure);

  // ─── Writes ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Message>> sendMessage(
    ChatId chatId,
    MessageBody body,
  ) async {
    try {
      final dto = await _remote.sendMessage(
        chatId: chatId.value,
        body: body.value,
      );
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  /// Stream-side translation: raw exception → typed [Failure] wrapped in
  /// [FailureWrapper] so it survives the reactive boundary.
  static Never _throwAsFailure(Object e) {
    if (e is UnauthorizedException) {
      throw FailureWrapper(AuthFailure(e.message));
    }
    if (e is ServerException) {
      throw FailureWrapper(ServerFailure(e.message));
    }
    throw FailureWrapper(UnknownFailure(e.toString()));
  }
}
