import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/domain/entities/match.dart';
import '../../data/datasources/tournaments_datasource_providers.dart';
import '../../data/repositories/tournaments_repository_impl.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/ground.dart';
import '../../domain/entities/match_official.dart';
import '../../domain/entities/my_tournament_entry.dart';
import '../../domain/entities/scorer_candidate.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_awards.dart';
import '../../domain/entities/tournament_fee_entry.dart';
import '../../domain/entities/tournament_leader.dart';
import '../../domain/entities/tournament_organizer.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/entities/tournament_standing.dart';
import '../../domain/repositories/tournaments_repository.dart';

part 'tournaments_providers.g.dart';

@Riverpod(keepAlive: true)
TournamentsRepository tournamentsRepository(Ref ref) {
  return TournamentsRepositoryImpl(
    remote: ref.watch(tournamentsRemoteDataSourceProvider),
  );
}

@riverpod
Future<Tournament> tournamentDetail(Ref ref, String tournamentId) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getTournament(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tournament) => tournament,
  );
}

@riverpod
Future<List<Tournament>> myTournaments(Ref ref) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getMyTournaments();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tournaments) => tournaments,
  );
}

@riverpod
Future<List<Tournament>> discoverTournaments(
  Ref ref, {
  TournamentType? type,
  TournamentStatus? status,
  String? city,
}) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getDiscoverTournaments(
    type: type,
    status: status,
    city: city,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tournaments) => tournaments,
  );
}

@riverpod
Future<List<TournamentRegistration>> tournamentRegistrations(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getTournamentRegistrations(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (registrations) => registrations,
  );
}

@riverpod
Future<List<Match>> tournamentFixtures(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getTournamentFixtures(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (fixtures) => fixtures,
  );
}

@riverpod
Stream<List<TournamentStanding>> tournamentStandingsStream(
  Ref ref,
  String tournamentId,
) {
  final repo = ref.watch(tournamentsRepositoryProvider);
  return repo.watchStandings(tournamentId);
}

@riverpod
Future<TournamentAwards> tournamentAwards(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getSuggestedAwards(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (awards) => awards,
  );
}

/// The organiser's Live Ops board (artboard 27). Autodispose so leaving the
/// console drops the poll; the console re-arms it on the Live Ops tab.
@riverpod
Future<List<TournamentLiveMatch>> tournamentLiveBoard(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getLiveBoard(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (board) => board,
  );
}

/// The hub's "Playing" bucket: every registration belonging to a team the
/// user manages. Reads the teams feature through its presentation providers,
/// which is the sanctioned cross-feature seam.
@riverpod
Future<List<MyTournamentEntry>> myPlayingTournaments(Ref ref) async {
  final teams = await ref.watch(myTeamsProvider.future);
  final ids = teams.map((t) => t.id.value).toList();
  if (ids.isEmpty) return const [];

  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getMyPlayingEntries(ids);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (entries) => entries,
  );
}

/// Ground picker results. Autodispose and keyed by the query so typing does
/// not accumulate subscriptions.
@riverpod
Future<List<Ground>> groundSearch(
  Ref ref, {
  String? query,
  double? latitude,
  double? longitude,
}) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.searchGrounds(
    query: query,
    latitude: latitude,
    longitude: longitude,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (grounds) => grounds,
  );
}

/// The grounds a tournament actually uses, in display order.
@riverpod
Future<List<Ground>> tournamentGrounds(Ref ref, String tournamentId) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getTournamentGrounds(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (grounds) => grounds,
  );
}

/// Who the organiser can appoint to score a fixture.
@riverpod
Future<List<ScorerCandidate>> tournamentScorerCandidates(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getScorerCandidates(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (people) => people,
  );
}

@riverpod
Stream<Map<String, dynamic>?> tournamentDraftStream(Ref ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(wizardDraftStoreProvider).watch('tournament_create:${user.id.value}');
}

/// The fee ledger for one cup (artboard 24c). Organiser-only on the server,
/// so a manager who reaches the route gets an error rather than an empty list.
@riverpod
Future<List<TournamentFeeEntry>> tournamentFeeLedger(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getFeeLedger(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (entries) => entries,
  );
}

/// Everyone already appointed to one fixture (artboard 27j).
@riverpod
Future<List<MatchOfficial>> matchOfficials(Ref ref, String matchId) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getMatchOfficials(matchId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (officials) => officials,
  );
}

/// Everyone who *could* be appointed to one fixture (artboard 27j).
@riverpod
Future<List<OfficialCandidate>> officialCandidates(
  Ref ref, {
  required String tournamentId,
  required String matchId,
}) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getOfficialCandidates(
    tournamentId: tournamentId,
    matchId: matchId,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (candidates) => candidates,
  );
}

/// The cup's orange- and purple-cap boards (artboards 10, 11, 15).
@riverpod
Future<TournamentLeaderboards> tournamentLeaderboards(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getLeaderboards(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (boards) => boards,
  );
}

/// The organiser's track record (artboard 09).
@riverpod
Future<TournamentOrganizer?> tournamentOrganizer(
  Ref ref,
  String tournamentId,
) async {
  final repo = ref.watch(tournamentsRepositoryProvider);
  final result = await repo.getOrganizer(tournamentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (organizer) => organizer,
  );
}
