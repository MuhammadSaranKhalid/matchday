import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
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

// ─── Match players (per-match XI) ──────────────────────────────────────────

/// The full playing XI for a match (both sides, in batting order where
/// set). Reads from match_players, the per-match polymorphism boundary.
/// Powers bowler / batter / fielder pickers and lineup displays. Returns
/// an empty list if the lineup hasn't been materialised yet.
@riverpod
Future<List<MatchPlayer>> matchPlayers(Ref ref, String matchId) async {
  final result = await ref
      .watch(matchesRepositoryProvider)
      .listMatchPlayers(MatchId(matchId));
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

// ─── Live scoring ──────────────────────────────────────────────────────────

/// Live (match, innings) state — striker / non-striker / bowler trio +
/// running totals + optimistic-lock version. Subscribes to the
/// `match:<id>:state` broadcast channel and emits on every
/// `innings_state_updated` event. The scoring screen reads the live trio
/// from here; the spectator scoreboard reads the running totals.
@riverpod
Stream<MatchInningsState?> liveInningsState(
  Ref ref,
  String matchId,
  int inningsNumber,
) =>
    ref.watch(matchesRepositoryProvider).watchMatchInningsState(
          matchId: MatchId(matchId),
          inningsNumber: inningsNumber,
        );

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
