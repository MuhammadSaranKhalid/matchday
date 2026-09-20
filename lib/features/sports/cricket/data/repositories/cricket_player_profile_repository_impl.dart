import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/entities/cricket_player_profile.dart';
import '../../domain/repositories/cricket_player_profile_repository.dart';
import '../datasources/cricket_player_profile_remote_datasource.dart';

part 'cricket_player_profile_repository_impl.g.dart';

/// Implements [CricketPlayerProfileRepository].
///
/// Catches raw datasource exceptions and maps them to typed [Failure]s.
/// Business rule: a missing row is not an error — it means the user has no
/// Cricket player identity yet.
class CricketPlayerProfileRepositoryImpl
    implements CricketPlayerProfileRepository {
  CricketPlayerProfileRepositoryImpl(this._remote);

  final CricketPlayerProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, CricketPlayerProfile?>> getByUserId(
    CricketPlayerUserId userId,
  ) async {
    try {
      final dto = await _remote.fetchByUserId(userId.value);
      return Right(dto?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

@Riverpod(keepAlive: true)
CricketPlayerProfileRemoteDataSource cricketPlayerProfileRemoteDataSource(
  Ref ref,
) =>
    CricketPlayerProfileRemoteDataSource(
      ref.watch(supabaseClientProvider),
    );

@Riverpod(keepAlive: true)
CricketPlayerProfileRepository cricketPlayerProfileRepository(
  Ref ref,
) =>
    CricketPlayerProfileRepositoryImpl(
      ref.watch(cricketPlayerProfileRemoteDataSourceProvider),
    );
