import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/format_preset.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/entities/match_pool_application.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/repositories/matches_repository.dart';
import '../../domain/usecases/accept_match_challenge_usecase.dart';
import '../../domain/usecases/complete_match_usecase.dart';
import '../../domain/usecases/counter_match_challenge_usecase.dart';
import '../../domain/usecases/decline_match_challenge_usecase.dart';
import '../../domain/usecases/get_match_challenge_usecase.dart';
import '../../domain/usecases/get_match_innings_state_usecase.dart';
import '../../domain/usecases/get_match_usecase.dart';
import '../../domain/usecases/list_format_presets_usecase.dart';
import '../../domain/usecases/list_innings_for_matches_usecase.dart';
import '../../domain/usecases/list_match_players_usecase.dart';
import '../../domain/usecases/list_my_match_challenges_usecase.dart';
import '../../domain/usecases/list_my_matches_usecase.dart';
import '../../domain/usecases/list_pool_applications_usecase.dart';
import '../../domain/usecases/record_ball_usecase.dart';
import '../../domain/usecases/record_match_toss_usecase.dart';
import '../../domain/usecases/send_match_challenge_usecase.dart';
import '../../domain/usecases/start_innings_usecase.dart';
import '../../domain/usecases/start_match_now_usecase.dart';
import '../../domain/usecases/submit_match_openers_usecase.dart';
import '../../domain/usecases/undo_last_ball_usecase.dart';
import '../../domain/usecases/watch_balls_usecase.dart';
import '../../domain/usecases/watch_match_innings_state_usecase.dart';
import '../../domain/usecases/watch_match_usecase.dart';
import '../../domain/usecases/withdraw_match_challenge_usecase.dart';
import 'match_pool_providers.dart';

part 'matches_providers.g.dart';

@Riverpod(keepAlive: true)
MatchesRepository matchesRepository(Ref ref) => MatchesRepositoryImpl(
      ref.watch(matchesRemoteDataSourceProvider),
      ref.watch(matchRequestsRemoteDataSourceProvider),
      ref.watch(formatPresetsRemoteDataSourceProvider),
    );

// ─── Domain Use Case Providers ──────────────────────────────────────────────

@riverpod
ListFormatPresetsUseCase listFormatPresetsUseCase(Ref ref) =>
    ListFormatPresetsUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
GetMatchUseCase getMatchUseCase(Ref ref) =>
    GetMatchUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
ListMyMatchesUseCase listMyMatchesUseCase(Ref ref) =>
    ListMyMatchesUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
ListInningsForMatchesUseCase listInningsForMatchesUseCase(Ref ref) =>
    ListInningsForMatchesUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
WatchMatchUseCase watchMatchUseCase(Ref ref) =>
    WatchMatchUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
RecordMatchTossUseCase recordMatchTossUseCase(Ref ref) =>
    RecordMatchTossUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
SubmitMatchOpenersUseCase submitMatchOpenersUseCase(Ref ref) =>
    SubmitMatchOpenersUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
StartMatchNowUseCase startMatchNowUseCase(Ref ref) =>
    StartMatchNowUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
SendMatchChallengeUseCase sendMatchChallengeUseCase(Ref ref) =>
    SendMatchChallengeUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
AcceptMatchChallengeUseCase acceptMatchChallengeUseCase(Ref ref) =>
    AcceptMatchChallengeUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
CounterMatchChallengeUseCase counterMatchChallengeUseCase(Ref ref) =>
    CounterMatchChallengeUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
DeclineMatchChallengeUseCase declineMatchChallengeUseCase(Ref ref) =>
    DeclineMatchChallengeUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
WithdrawMatchChallengeUseCase withdrawMatchChallengeUseCase(Ref ref) =>
    WithdrawMatchChallengeUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
GetMatchChallengeUseCase getMatchChallengeUseCase(Ref ref) =>
    GetMatchChallengeUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
ListMyMatchChallengesUseCase listMyMatchChallengesUseCase(Ref ref) =>
    ListMyMatchChallengesUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
ListMatchPlayersUseCase listMatchPlayersUseCase(Ref ref) =>
    ListMatchPlayersUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
GetMatchInningsStateUseCase getMatchInningsStateUseCase(Ref ref) =>
    GetMatchInningsStateUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
WatchMatchInningsStateUseCase watchMatchInningsStateUseCase(Ref ref) =>
    WatchMatchInningsStateUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
StartInningsUseCase startInningsUseCase(Ref ref) =>
    StartInningsUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
RecordBallUseCase recordBallUseCase(Ref ref) =>
    RecordBallUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
UndoLastBallUseCase undoLastBallUseCase(Ref ref) =>
    UndoLastBallUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
CompleteMatchUseCase completeMatchUseCase(Ref ref) =>
    CompleteMatchUseCase(ref.watch(matchesRepositoryProvider));

@riverpod
WatchBallsUseCase watchBallsUseCase(Ref ref) =>
    WatchBallsUseCase(ref.watch(matchesRepositoryProvider));

// ─── Query / State Providers (Consuming Domain Use Cases) ───────────────────

@riverpod
Future<List<FormatPreset>> formatPresets(Ref ref) async {
  final result = await ref.watch(listFormatPresetsUseCaseProvider)();
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

@riverpod
Future<Match?> match(Ref ref, String matchId) async {
  final result = await ref.watch(getMatchUseCaseProvider)(MatchId(matchId));
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}

@riverpod
Future<List<Match>> myMatches(Ref ref) async {
  final result = await ref.watch(listMyMatchesUseCaseProvider)();
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}

@riverpod
Stream<Match?> liveMatch(Ref ref, String matchId) =>
    ref.watch(watchMatchUseCaseProvider)(MatchId(matchId));

@riverpod
Future<List<MatchPlayer>> matchPlayers(Ref ref, String matchId) async {
  final result =
      await ref.watch(listMatchPlayersUseCaseProvider)(MatchId(matchId));
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

@riverpod
Stream<MatchInningsState?> liveInningsState(
  Ref ref,
  String matchId,
  int inningsNumber,
) =>
    ref.watch(watchMatchInningsStateUseCaseProvider)(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );

@riverpod
Stream<List<Ball>> liveBalls(
  Ref ref,
  String matchId,
  int inningsNumber,
) =>
    ref.watch(watchBallsUseCaseProvider)(MatchId(matchId), inningsNumber);

@riverpod
Future<List<MatchRequest>> myMatchChallenges(Ref ref) async {
  final result = await ref.watch(listMyMatchChallengesUseCaseProvider)();
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

@riverpod
Future<MatchRequest?> matchChallenge(Ref ref, String requestId) async {
  final result = await ref
      .watch(getMatchChallengeUseCaseProvider)(MatchRequestId(requestId));
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}

@riverpod
Future<List<MatchPoolApplication>> poolApplications(
  Ref ref,
  String requestId,
) async {
  final result = await ref
      .watch(listPoolApplicationsUseCaseProvider)(MatchRequestId(requestId));
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}
