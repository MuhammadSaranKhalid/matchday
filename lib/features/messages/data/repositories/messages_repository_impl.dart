import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote_datasource.dart';

/// Online-only impl of the messages read contract. Translates raw exceptions
/// to `Failure`s wrapped in [FailureWrapper] so they survive the stream
/// boundary, per the matches feature's established pattern.
class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);
  final MessagesRemoteDataSource _remote;

  @override
  Stream<List<Chat>> watchMyChats() => _remote
      .watchMyChats()
      .map((dtos) => dtos.map((d) => d.toEntity()).toList(growable: false))
      .handleError((Object e) {
        if (e is UnauthorizedException) {
          throw FailureWrapper(AuthFailure(e.message));
        }
        if (e is ServerException) {
          throw FailureWrapper(ServerFailure(e.message));
        }
        throw FailureWrapper(UnknownFailure(e.toString()));
      });
}
