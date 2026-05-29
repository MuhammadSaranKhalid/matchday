import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/repositories/matches_repository.dart';

part 'matches_providers.g.dart';

@Riverpod(keepAlive: true)
MatchesRepository matchesRepository(Ref ref) =>
    MatchesRepositoryImpl(ref.watch(matchesRemoteDataSourceProvider));

/// One-shot fetch of a single match (for the request screen). Throws a
/// [FailureWrapper] on error so the UI can show it via AsyncError.
@riverpod
Future<Match?> match(Ref ref, String matchId) async {
  final result =
      await ref.watch(matchesRepositoryProvider).getMatch(MatchId(matchId));
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}

/// Matches involving the user's teams (for the MATCH tab's requests section).
@riverpod
Future<List<Match>> myMatches(Ref ref) async {
  final result = await ref.watch(matchesRepositoryProvider).listMyMatches();
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}

// ─── Match Start (2-phone flow) ────────────────────────────────────────────

/// Live match-row updates (broadcast channel). Each subscription opens its
/// own channel; keep usage to one consumer per route (the Match Start
/// screen + the spectator scoreboard).
@riverpod
Stream<Match?> liveMatch(Ref ref, String matchId) =>
    ref.watch(matchesRepositoryProvider).watchMatch(MatchId(matchId));

// ─── Live scoring ──────────────────────────────────────────────────────────

/// Live deliveries for (matchId, inningsNumber) via the broadcast channel.
/// `inningsNumber` is read off the match row; spectators + scorers both
/// subscribe to the same stream.
@riverpod
Stream<List<Ball>> liveBalls(
  Ref ref,
  String matchId,
  int inningsNumber,
) =>
    ref
        .watch(matchesRepositoryProvider)
        .watchBalls(MatchId(matchId), inningsNumber);

// ─── Match Requests (challenge handshake) ──────────────────────────────────

@riverpod
Future<List<MatchRequest>> myMatchChallenges(Ref ref) async {
  final result =
      await ref.watch(matchesRepositoryProvider).listMyMatchChallenges();
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

@riverpod
Future<MatchRequest?> matchChallenge(Ref ref, String requestId) async {
  final result = await ref
      .watch(matchesRepositoryProvider)
      .getMatchChallenge(MatchRequestId(requestId));
  return result.fold((f) => throw FailureWrapper(f), (m) => m);
}
