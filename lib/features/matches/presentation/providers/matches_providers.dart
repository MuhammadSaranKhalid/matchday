import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../data/datasources/matches_local_datasource.dart';
import '../../data/datasources/matches_datasource_providers.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/format_preset.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_batsman_stats.dart';
import '../../domain/entities/match_bowler_stats.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/entities/match_pool_application.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/entities/match_wicket.dart';
import '../../domain/repositories/matches_repository.dart';

part 'matches_providers.g.dart';

@Riverpod(keepAlive: true)
MatchesRepository matchesRepository(Ref ref) => MatchesRepositoryImpl(
      ref.watch(matchesRemoteDataSourceProvider),
      ref.watch(matchRequestsRemoteDataSourceProvider),
      ref.watch(formatPresetsRemoteDataSourceProvider),
      ref.watch(matchesLocalDataSourceProvider),
    );

/// The active format presets from the backend catalog (the setup picker reads
/// this instead of a hardcoded list).
@riverpod
Future<List<FormatPreset>> formatPresets(Ref ref) async {
  final result =
      await ref.watch(matchesRepositoryProvider).listFormatPresets();
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

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
///
/// Watching [appResumeCountProvider] rebuilds the subscription whenever the
/// app returns to the foreground — a backgrounded socket is often a zombie,
/// so reconnecting is the only reliable way to know the state is current.
@riverpod
Stream<Match?> liveMatch(Ref ref, String matchId) {
  ref.watch(appResumeCountProvider);
  return ref.watch(matchesRepositoryProvider).watchMatch(MatchId(matchId));
}

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
) {
  ref.watch(appResumeCountProvider);
  return ref.watch(matchesRepositoryProvider).watchMatchInningsState(
        matchId: MatchId(matchId),
        inningsNumber: inningsNumber,
      );
}

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

/// Whether this device may record deliveries for (match, innings).
///
/// Asks the server rather than deriving it, so the UI gate is the same rule
/// the write path enforces. Re-evaluated on resume and whenever the match row
/// changes — control passes to the other side at the innings break, and the
/// answer flips at exactly that moment.
@riverpod
Future<bool> canScoreInnings(
  Ref ref,
  String matchId,
  int inningsNumber,
) async {
  ref.watch(appResumeCountProvider);
  // Re-ask when the match row moves: the toss decides who bats, and the
  // innings break hands scoring to the other team.
  ref.watch(liveMatchProvider(matchId));

  final result = await ref.watch(matchesRepositoryProvider).canScoreInnings(
        matchId: MatchId(matchId),
        inningsNumber: inningsNumber,
      );
  // Fail closed: if we cannot establish permission, show the read-only
  // scoreboard rather than controls whose taps the server would reject.
  return result.getOrElse((_) => false);
}

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

/// Applications received for an open pool challenge.
@riverpod
Future<List<MatchPoolApplication>> poolApplications(
  Ref ref,
  String requestId,
) async {
  final result = await ref
      .watch(matchesRepositoryProvider)
      .listPoolApplications(MatchRequestId(requestId));
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

// ─── Materialized Scorecards & Wickets ──────────────────────────────────────

/// Materialized batting scorecard for an innings (O(1) fast paint).
@riverpod
Future<List<MatchBatsmanStats>> batsmanScorecard(
  Ref ref,
  String inningsId,
) async {
  final result =
      await ref.watch(matchesRepositoryProvider).getBatsmanStats(inningsId);
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

/// Materialized bowling scorecard for an innings (O(1) fast paint).
@riverpod
Future<List<MatchBowlerStats>> bowlerScorecard(
  Ref ref,
  String inningsId,
) async {
  final result =
      await ref.watch(matchesRepositoryProvider).getBowlerStats(inningsId);
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}

/// Wickets fallen for an innings (fall of wickets timeline).
@riverpod
Future<List<MatchWicket>> inningsWickets(
  Ref ref,
  String inningsId,
) async {
  final result =
      await ref.watch(matchesRepositoryProvider).getWickets(inningsId);
  return result.fold((f) => throw FailureWrapper(f), (list) => list);
}
