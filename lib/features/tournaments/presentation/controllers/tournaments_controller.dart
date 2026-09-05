import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../domain/draw/draw_plan.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/ground.dart';
import '../../domain/entities/match_official.dart';
import '../../domain/entities/tournament_awards.dart';
import '../../domain/entities/tournament_fee_entry.dart';
import '../../domain/ops/revised_target.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../providers/tournaments_providers.dart';

part 'tournaments_controller.g.dart';

@riverpod
class TournamentsController extends _$TournamentsController {
  @override
  FutureOr<void> build() {}

  // ─── Disposal guards ───────────────────────────────────────────────────────
  //
  // This notifier is autoDispose and screens dispatch actions through
  // `ref.read(...notifier)`. A call site that never *watches* the provider
  // lets Riverpod dispose it the moment the read completes — while the write
  // is still in flight. Touching `state` or `ref` after that throws
  // "Cannot use the Ref of tournamentsControllerProvider after it has been
  // disposed", the write lands but the refresh never fires, and the screen
  // silently goes stale. Every post-await touch goes through these.

  void _fail(Failure failure) {
    if (!ref.mounted) return;
    state = AsyncError(failure.message, StackTrace.current);
  }

  void _ok() {
    if (!ref.mounted) return;
    state = const AsyncData(null);
  }

  /// Runs provider invalidations only while the notifier is still alive.
  void _refresh(void Function() invalidations) {
    if (!ref.mounted) return;
    invalidations();
  }

  Future<Tournament?> createTournament(CreateTournamentParams params) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.createTournament(params);
    return result.fold(
      (failure) {
        _fail(failure);
        return null;
      },
      (tournament) {
        _ok();
        _refresh(() {
          ref.invalidate(myTournamentsProvider);
        });
        return tournament;
      },
    );
  }

  Future<bool> updateTournament(
      String tournamentId, Map<String, dynamic> updates) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.updateTournament(tournamentId, updates);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentDetailProvider(tournamentId));
        });
        return true;
      },
    );
  }

  Future<bool> publishTournament(String tournamentId) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.publishTournament(tournamentId);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentDetailProvider(tournamentId));
          ref.invalidate(myTournamentsProvider);
        });
        return true;
      },
    );
  }

  Future<bool> startTournament(String tournamentId) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.updateTournament(tournamentId, {
      'status': TournamentStatus.live.wire,
    });
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentDetailProvider(tournamentId));
          ref.invalidate(myTournamentsProvider);
        });
        return true;
      },
    );
  }

  Future<bool> completeTournament(String tournamentId) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.updateTournament(tournamentId, {
      'status': TournamentStatus.completed.wire,
    });
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentDetailProvider(tournamentId));
          ref.invalidate(myTournamentsProvider);
        });
        return true;
      },
    );
  }

  Future<TournamentRegistration?> registerTeam({
    required String tournamentId,
    required String teamId,
    required List<String> squadPlayerIds,
    String? message,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.registerTeam(
      tournamentId: tournamentId,
      teamId: teamId,
      squadPlayerIds: squadPlayerIds,
      message: message,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return null;
      },
      (reg) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
          ref.invalidate(tournamentDetailProvider(tournamentId));
        });
        return reg;
      },
    );
  }

  Future<bool> approveRegistration(
      String tournamentId, String registrationId) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.approveRegistration(registrationId);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
          ref.invalidate(tournamentDetailProvider(tournamentId));
        });
        return true;
      },
    );
  }

  Future<bool> rejectRegistration(
      String tournamentId, String registrationId, String reason) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.rejectRegistration(registrationId, reason);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
          ref.invalidate(tournamentDetailProvider(tournamentId));
        });
        return true;
      },
    );
  }

  Future<bool> withdrawRegistration(
      String tournamentId, String registrationId) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.withdrawRegistration(registrationId);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
        });
        return true;
      },
    );
  }

  Future<bool> updatePaymentStatus(
    String tournamentId,
    String registrationId,
    String paymentStatus,
  ) async {
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.updatePaymentStatus(registrationId, paymentStatus);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
        });
        return true;
      },
    );
  }

  Future<bool> assignTeamGroup({
    required String tournamentId,
    required String registrationId,
    required String? groupId,
  }) async {
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.assignTeamGroup(
      registrationId: registrationId,
      groupId: groupId,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
          ref.invalidate(tournamentStandingsStreamProvider(tournamentId));
        });
        return true;
      },
    );
  }

  Future<bool> assignMultipleTeamsGroup({
    required String tournamentId,
    required List<String> registrationIds,
    required String? groupId,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.assignMultipleTeamsGroup(
      registrationIds: registrationIds,
      groupId: groupId,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
          ref.invalidate(tournamentStandingsStreamProvider(tournamentId));
        });
        return true;
      },
    );
  }

  Future<bool> autoDistributeGroups({
    required String tournamentId,
    required List<String> groupNames,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.autoDistributeGroups(
      tournamentId: tournamentId,
      groupNames: groupNames,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentRegistrationsProvider(tournamentId));
          ref.invalidate(tournamentStandingsStreamProvider(tournamentId));
        });
        return true;
      },
    );
  }

  /// Returns the number of fixtures published, or null on failure.
  Future<int?> generateAndPublishFixtures({
    required String tournamentId,
    required DrawPlan plan,
    List<String> seedOrder = const [],
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.generateAndPublishFixtures(
      tournamentId: tournamentId,
      plan: plan,
      seedOrder: seedOrder,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return null;
      },
      (count) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentDetailProvider(tournamentId));
          ref.invalidate(tournamentFixturesProvider(tournamentId));
          ref.invalidate(tournamentLiveBoardProvider(tournamentId));
          ref.invalidate(myTournamentsProvider);
        });
        return count;
      },
    );
  }

  Future<bool> confirmAwards(
    String tournamentId,
    TournamentAwards awards,
  ) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.confirmAwards(tournamentId, awards);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refresh(() {
          ref.invalidate(tournamentDetailProvider(tournamentId));
          ref.invalidate(tournamentAwardsProvider(tournamentId));
        });
        return true;
      },
    );
  }

  // ─── Artwork ──────────────────────────────────────────────────────────────

  /// Uploads artwork for an existing tournament. Returns false on failure —
  /// callers on the publish path treat that as non-fatal, since the cup is
  /// already live by then and matchday falls back to the seam pattern.
  Future<bool> uploadArtwork({
    required String tournamentId,
    File? banner,
    File? logo,
  }) async {
    if (banner == null && logo == null) return true;
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.uploadArtwork(
      tournamentId: tournamentId,
      banner: banner,
      logo: logo,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _refresh(() {
          ref.invalidate(tournamentDetailProvider(tournamentId));
          ref.invalidate(myTournamentsProvider);
        });
        return true;
      },
    );
  }

  // ─── Grounds ──────────────────────────────────────────────────────────────

  /// Returns the created ground, or null if it failed.
  Future<Ground?> createGround({
    required String name,
    String? city,
    double? latitude,
    double? longitude,
    GroundSurface? surface,
    bool hasFloodlights = false,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.createGround(
      name: name,
      city: city,
      latitude: latitude,
      longitude: longitude,
      surface: surface,
      hasFloodlights: hasFloodlights,
      notes: notes,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return null;
      },
      (ground) {
        _ok();
        // A new ground must show up in the very next search.
        _refresh(() {
          ref.invalidate(groundSearchProvider);
        });
        return ground;
      },
    );
  }

  Future<bool> setTournamentGrounds({
    required String tournamentId,
    required List<String> groundIds,
  }) async {
    final ok = await _run(
      tournamentId,
      (repo) => repo.setTournamentGrounds(
        tournamentId: tournamentId,
        groundIds: groundIds,
      ),
    );
    if (ok) ref.invalidate(tournamentGroundsProvider(tournamentId));
    return ok;
  }

  // ─── Live Ops (artboards 27, 27c–g, 28) ────────────────────────────────────

  /// Every ground-ops action lands on the same three surfaces, so they share
  /// one refresh: the board itself, the fixture list, and the standings the
  /// action just moved.
  void _refreshOps(String tournamentId) {
    ref.invalidate(tournamentLiveBoardProvider(tournamentId));
    ref.invalidate(tournamentFixturesProvider(tournamentId));
    ref.invalidate(tournamentDetailProvider(tournamentId));
  }

  Future<bool> _run(
    String tournamentId,
    Future<Either<Failure, void>> Function(TournamentsRepository repo) action,
  ) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await action(repo);
    return result.fold(
      (failure) {
        _fail(failure);
        return false;
      },
      (_) {
        _ok();
        _refreshOps(tournamentId);
        return true;
      },
    );
  }

  Future<bool> assignScorer({
    required String tournamentId,
    required String matchId,
    required String userId,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.assignScorer(matchId: matchId, userId: userId),
      );

  Future<bool> rescheduleMatch({
    required String tournamentId,
    required String matchId,
    required DateTime startTime,
    String? venue,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.rescheduleMatch(
          matchId: matchId,
          startTime: startTime,
          venue: venue,
        ),
      );

  Future<bool> abandonMatch({
    required String tournamentId,
    required String matchId,
    required AbandonMode mode,
    DateTime? rescheduleTo,
    String? reason,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.abandonMatch(
          matchId: matchId,
          mode: mode,
          rescheduleTo: rescheduleTo,
          reason: reason,
        ),
      );

  Future<bool> declareWalkover({
    required String tournamentId,
    required String matchId,
    required String winnerTeamId,
    String? reason,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.declareWalkover(
          matchId: matchId,
          winnerTeamId: winnerTeamId,
          reason: reason,
        ),
      );

  Future<bool> overrideResult({
    required String tournamentId,
    required String matchId,
    required String winnerTeamId,
    required String reason,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.overrideResult(
          matchId: matchId,
          winnerTeamId: winnerTeamId,
          reason: reason,
        ),
      );

  Future<bool> setCoOrganizer({
    required String tournamentId,
    required String userId,
    required bool add,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.setCoOrganizer(
          tournamentId: tournamentId,
          userId: userId,
          add: add,
        ),
      );

  /// Returns the number of people reached, or null if the send failed.
  Future<int?> sendAnnouncement({
    required String tournamentId,
    required String message,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.sendAnnouncement(
      tournamentId: tournamentId,
      message: message,
    );
    return result.fold(
      (failure) {
        _fail(failure);
        return null;
      },
      (count) {
        _ok();
        return count;
      },
    );
  }

  Future<bool> cancelTournament({
    required String tournamentId,
    required String reason,
  }) async {
    final ok = await _run(
      tournamentId,
      (repo) => repo.cancelTournament(tournamentId, reason),
    );
    if (ok) ref.invalidate(myTournamentsProvider);
    return ok;
  }

  // ─── Fee ledger (artboard 24c) ──────────────────────────────────────────────

  Future<bool> recordPayment({
    required String tournamentId,
    required String registrationId,
    required double amountPaid,
    PaymentChannel? channel,
    String? reference,
  }) async {
    final ok = await _run(
      tournamentId,
      (repo) => repo.recordPayment(
        registrationId: registrationId,
        amountPaid: amountPaid,
        channel: channel,
        reference: reference,
      ),
    );
    if (ok && ref.mounted) {
      ref.invalidate(tournamentFeeLedgerProvider(tournamentId));
      // The registrations tab shows the same "Paid" chip off payment_status.
      ref.invalidate(tournamentRegistrationsProvider(tournamentId));
    }
    return ok;
  }

  // ─── Match officials (artboard 27j) ─────────────────────────────────────────

  Future<bool> assignOfficial({
    required String tournamentId,
    required String matchId,
    required String userId,
    required OfficialRole role,
  }) async {
    final ok = await _run(
      tournamentId,
      (repo) =>
          repo.assignOfficial(matchId: matchId, userId: userId, role: role),
    );
    if (ok && ref.mounted) ref.invalidate(matchOfficialsProvider(matchId));
    return ok;
  }

  Future<bool> removeOfficial({
    required String tournamentId,
    required String matchId,
    required OfficialRole role,
  }) async {
    final ok = await _run(
      tournamentId,
      (repo) => repo.removeOfficial(matchId: matchId, role: role),
    );
    if (ok && ref.mounted) ref.invalidate(matchOfficialsProvider(matchId));
    return ok;
  }

  // ─── Matchday-morning ops (artboards 27k, 27m, 28b, 28c) ────────────────────

  /// Returns how many fixtures were filled, or null if the call failed.
  /// Zero is a real answer — nobody was free — and reads differently from
  /// a failure, so the screen can say so.
  Future<int?> autoAssignScorers(String tournamentId) async {
    state = const AsyncLoading();
    final repo = ref.read(tournamentsRepositoryProvider);
    final result = await repo.autoAssignScorers(tournamentId);
    return result.fold(
      (failure) {
        _fail(failure);
        return null;
      },
      (count) {
        _ok();
        _refreshOps(tournamentId);
        return count;
      },
    );
  }

  Future<bool> reviseMatchConditions({
    required String tournamentId,
    required String matchId,
    required int revisedOvers,
    required int bowlerQuota,
    int? revisedTarget,
    TargetMethod method = TargetMethod.runRate,
    String? reason,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.reviseMatchConditions(
          matchId: matchId,
          revisedOvers: revisedOvers,
          bowlerQuota: bowlerQuota,
          revisedTarget: revisedTarget,
          method: method,
          reason: reason,
        ),
      );

  Future<bool> triggerSuperOver({
    required String tournamentId,
    required String matchId,
    required String batsFirstTeamId,
  }) =>
      _run(
        tournamentId,
        (repo) => repo.triggerSuperOver(
          matchId: matchId,
          batsFirstTeamId: batsFirstTeamId,
        ),
      );
}
