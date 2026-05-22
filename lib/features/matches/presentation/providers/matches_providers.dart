import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/matches_repository.dart';
import '../../domain/usecases/accept_match.dart';
import '../../domain/usecases/complete_match.dart';
import '../../domain/usecases/create_match_request.dart';
import '../../domain/usecases/decline_match.dart';
import '../../domain/usecases/get_current_innings.dart';
import '../../domain/usecases/get_match.dart';
import '../../domain/usecases/list_my_matches.dart';
import '../../domain/usecases/record_ball.dart';
import '../../domain/usecases/start_match.dart';
import '../../domain/usecases/watch_balls.dart';
import '../../domain/usecases/watch_innings.dart';

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
GetCurrentInnings getCurrentInningsUseCase(Ref ref) =>
    GetCurrentInnings(ref.watch(matchesRepositoryProvider));

/// The latest innings for a match (one-shot; the spectator then streams it).
@riverpod
Future<Innings?> currentInnings(Ref ref, String matchId) async {
  final result =
      await ref.watch(getCurrentInningsUseCaseProvider).call(MatchId(matchId));
  return result.fold((f) => throw FailureWrapper(f), (i) => i);
}

@riverpod
AcceptMatch acceptMatchUseCase(Ref ref) =>
    AcceptMatch(ref.watch(matchesRepositoryProvider));

@riverpod
DeclineMatch declineMatchUseCase(Ref ref) =>
    DeclineMatch(ref.watch(matchesRepositoryProvider));

@riverpod
StartMatch startMatchUseCase(Ref ref) =>
    StartMatch(ref.watch(matchesRepositoryProvider));

@riverpod
CompleteMatch completeMatchUseCase(Ref ref) =>
    CompleteMatch(ref.watch(matchesRepositoryProvider));

@riverpod
RecordBall recordBallUseCase(Ref ref) =>
    RecordBall(ref.watch(matchesRepositoryProvider));

@riverpod
WatchBalls watchBallsUseCase(Ref ref) =>
    WatchBalls(ref.watch(matchesRepositoryProvider));

@riverpod
WatchInnings watchInningsUseCase(Ref ref) =>
    WatchInnings(ref.watch(matchesRepositoryProvider));

/// Live deliveries for an innings (realtime).
@riverpod
Stream<List<Ball>> balls(Ref ref, String inningsId) =>
    ref.watch(watchBallsUseCaseProvider).call(InningsId(inningsId));

/// Live innings state (realtime).
@riverpod
Stream<Innings?> liveInnings(Ref ref, String inningsId) =>
    ref.watch(watchInningsUseCaseProvider).call(InningsId(inningsId));

/// One-shot fetch of a single match (for the request screen). Throws a
/// [FailureWrapper] on error so the UI can show it via AsyncError.
@riverpod
Future<Match?> match(Ref ref, String matchId) async {
  final result =
      await ref.watch(getMatchUseCaseProvider).call(MatchId(matchId));
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}

/// Matches involving the user's teams (for the MATCH tab's requests section).
@riverpod
Future<List<Match>> myMatches(Ref ref) async {
  final result =
      await ref.watch(listMyMatchesUseCaseProvider).call(const NoParams());
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}
