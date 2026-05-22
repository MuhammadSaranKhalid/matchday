import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/matches_repository.dart';
import '../../domain/usecases/accept_match.dart';
import '../../domain/usecases/create_match_request.dart';
import '../../domain/usecases/decline_match.dart';
import '../../domain/usecases/get_match.dart';
import '../../domain/usecases/list_my_matches.dart';
import '../../domain/usecases/start_match.dart';

part 'matches_providers.g.dart';

@Riverpod(keepAlive: true)
MatchesRepository matchesRepository(Ref ref) =>
    MatchesRepositoryImpl(ref.watch(matchesRemoteDataSourceProvider));

@riverpod
CreateMatchRequest createMatchRequestUseCase(Ref ref) =>
    CreateMatchRequest(ref.watch(matchesRepositoryProvider));

@riverpod
ListMyMatches listMyMatchesUseCase(Ref ref) =>
    ListMyMatches(ref.watch(matchesRepositoryProvider));

@riverpod
GetMatch getMatchUseCase(Ref ref) =>
    GetMatch(ref.watch(matchesRepositoryProvider));

@riverpod
AcceptMatch acceptMatchUseCase(Ref ref) =>
    AcceptMatch(ref.watch(matchesRepositoryProvider));

@riverpod
DeclineMatch declineMatchUseCase(Ref ref) =>
    DeclineMatch(ref.watch(matchesRepositoryProvider));

@riverpod
StartMatch startMatchUseCase(Ref ref) =>
    StartMatch(ref.watch(matchesRepositoryProvider));

/// One-shot fetch of a single match (for the request screen). Throws a
/// [FailureWrapper] on error so the UI can show it via AsyncError.
@riverpod
Future<Match?> match(Ref ref, String matchId) async {
  final result =
      await ref.read(getMatchUseCaseProvider).call(MatchId(matchId));
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}

/// Matches involving the user's teams (for the MATCH tab's requests section).
@riverpod
Future<List<Match>> myMatches(Ref ref) async {
  final result =
      await ref.read(listMyMatchesUseCaseProvider).call(const NoParams());
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}
