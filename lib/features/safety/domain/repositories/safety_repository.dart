import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/blocked_account.dart';

abstract class SafetyRepository {
  Future<Either<Failure, List<BlockedAccount>>> blockedAccounts();
  Future<Either<Failure, Unit>> block(String userId);
  Future<Either<Failure, Unit>> unblock(String userId);
  Future<Either<Failure, Unit>> report({required String kind, required String targetId, required String reason, required String details});
}
