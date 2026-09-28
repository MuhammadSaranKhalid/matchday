import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/blocked_account.dart';
import '../../domain/repositories/safety_repository.dart';
import '../datasources/safety_remote_datasource.dart';
class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this.remote);
  final SafetyRemoteDataSource remote;
  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try { return Right(await action()); }
    on AuthException { return const Left(AuthFailure('Please sign in again.')); }
    catch (_) { return const Left(ServerFailure('Unable to save this change. Please try again.')); }
  }
  @override
  Future<Either<Failure, List<BlockedAccount>>> blockedAccounts() => _run(() async => (await remote.blockedAccounts()).map((d) => d.toEntity()).toList());
  @override
  Future<Either<Failure, Unit>> block(String userId) => _run(() async { await remote.block(userId); return unit; });
  @override
  Future<Either<Failure, Unit>> unblock(String userId) => _run(() async { await remote.unblock(userId); return unit; });
  @override
  Future<Either<Failure, Unit>> report({required String kind, required String targetId, required String reason, required String details}) {
    if (!const ['user', 'post', 'comment', 'message'].contains(kind) || details.length > 2000 || !const ['Spam', 'Harassment or bullying', 'Hate or violence', 'Sexual content', 'Child safety', 'Other'].contains(reason)) {
      return Future.value(const Left(ValidationFailure('Choose a reason and keep details under 2,000 characters.')));
    }
    return _run(() async { await remote.report(kind: kind, targetId: targetId, reason: reason, details: details.trim()); return unit; });
  }
}
