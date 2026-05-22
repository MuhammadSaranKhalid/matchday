import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/create_match_request.dart';
import '../providers/matches_providers.dart';
import '../state/match_setup_state.dart';

part 'match_setup_controller.g.dart';

/// Drives the 6-step match-setup wizard for a given team A. AsyncNotifier so
/// [build] restores a persisted draft first (mirrors the other wizards).
@riverpod
class MatchSetupController extends _$MatchSetupController {
  String get _draftKey => 'match_setup:${_teamAId.value}';
  late TeamId _teamAId;

  @override
  Future<MatchSetupState> build(String teamAId) async {
    _teamAId = TeamId(teamAId);
    final draft = await ref.read(wizardDraftStoreProvider).load(_draftKey);
    if (draft == null) return const MatchSetupState();
    return _fromDraft(draft);
  }

  MatchSetupState? get _s => state.value;

  void _set(MatchSetupState next, {bool persist = true}) {
    state = AsyncData(next);
    if (persist && next.createdMatchId == null) _persist(next);
  }

  void _mutate(MatchSetupState Function(MatchSetupState) f) {
    final s = _s;
    if (s == null) return;
    _set(f(s));
  }

  // ─── Field setters ────────────────────────────────────────────────────────

  void pickOpponent(String id, String name) =>
      _mutate((s) => s.copyWith(opponentId: id, opponentName: name));
  void setOvers(int v) => _mutate(
      (s) => s.copyWith(overs: v, maxOversPerBowler: (v / 5).ceil()));
  void setPlayersPerTeam(int v) => _mutate((s) => s.copyWith(playersPerTeam: v));
  void setBallType(MatchBallType b) => _mutate((s) => s.copyWith(ballType: b));
  void setMaxOversPerBowler(int v) =>
      _mutate((s) => s.copyWith(maxOversPerBowler: v));
  void setWhen(DateTime w) => _mutate((s) => s.copyWith(when: w));
  void setVenueGround(String v) => _mutate((s) => s.copyWith(venueGround: v));
  void setVenueCity(String v) => _mutate((s) => s.copyWith(venueCity: v));

  void togglePlayer(String playerId) {
    final s = _s;
    if (s == null) return;
    final next = Set<String>.from(s.selectedPlayers);
    var captain = s.captainId;
    var keeper = s.keeperId;
    if (next.contains(playerId)) {
      next.remove(playerId);
      if (captain == playerId) captain = null;
      if (keeper == playerId) keeper = null;
    } else {
      if (next.length >= s.playersPerTeam) return; // at capacity
      next.add(playerId);
    }
    _set(s.copyWith(
      selectedPlayers: next,
      captainId: captain,
      keeperId: keeper,
    ));
  }

  void setCaptain(String playerId) => _mutate((s) => s.copyWith(
        captainId: s.captainId == playerId ? null : playerId,
      ));
  void setKeeper(String playerId) => _mutate((s) => s.copyWith(
        keeperId: s.keeperId == playerId ? null : playerId,
      ));

  // ─── Navigation ───────────────────────────────────────────────────────────

  void next() {
    final s = _s;
    if (s == null) return;
    final order = MatchSetupStep.values;
    final i = s.step.index;
    if (i < order.length - 1) _set(s.copyWith(step: order[i + 1]));
  }

  void back() {
    final s = _s;
    if (s == null) return;
    final i = s.step.index;
    if (i > 0) _set(s.copyWith(step: MatchSetupStep.values[i - 1]));
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> submit() async {
    final s = _s;
    if (s == null || s.submitting || s.opponentId == null) return;
    _set(s.copyWith(submitting: true, submitError: null), persist: false);

    final result = await ref.read(createMatchRequestUseCaseProvider).call(
          CreateMatchRequestParams(
            teamAId: _teamAId,
            teamBId: TeamId(s.opponentId!),
            format: s.format,
            squad: s.selectedPlayers.toList(),
            captain: s.captainId!,
            keeper: s.keeperId,
            venue: Venue(
              ground: s.venueGround.trim(),
              city: s.venueCity.trim().isEmpty ? null : s.venueCity.trim(),
            ),
            scheduledStartTime: s.when,
          ),
        );

    final current = _s;
    if (current == null) return;
    await result.fold(
      (failure) async => _set(
        current.copyWith(submitting: false, submitError: failure.message),
        persist: false,
      ),
      (match) async {
        await ref.read(wizardDraftStoreProvider).clear(_draftKey);
        _set(
          current.copyWith(submitting: false, createdMatchId: match.id.value),
          persist: false,
        );
      },
    );
  }

  // ─── Draft (de)serialization ────────────────────────────────────────────

  void _persist(MatchSetupState s) {
    ref.read(wizardDraftStoreProvider).save(_draftKey, {
      'step': s.step.name,
      'opponentId': s.opponentId,
      'opponentName': s.opponentName,
      'overs': s.overs,
      'playersPerTeam': s.playersPerTeam,
      'ballType': s.ballType.wire,
      'maxOversPerBowler': s.maxOversPerBowler,
      'when': s.when?.toIso8601String(),
      'venueGround': s.venueGround,
      'venueCity': s.venueCity,
      'selectedPlayers': s.selectedPlayers.toList(),
      'captainId': s.captainId,
      'keeperId': s.keeperId,
    });
  }

  MatchSetupState _fromDraft(Map<String, dynamic> m) => MatchSetupState(
        step: MatchSetupStep.values.firstWhere(
          (e) => e.name == m['step'],
          orElse: () => MatchSetupStep.type,
        ),
        opponentId: m['opponentId'] as String?,
        opponentName: m['opponentName'] as String?,
        overs: (m['overs'] as num?)?.toInt() ?? 20,
        playersPerTeam: (m['playersPerTeam'] as num?)?.toInt() ?? 11,
        ballType: MatchBallType.fromWire(m['ballType'] as String?),
        maxOversPerBowler: (m['maxOversPerBowler'] as num?)?.toInt() ?? 4,
        when: m['when'] != null ? DateTime.tryParse(m['when'] as String) : null,
        venueGround: m['venueGround'] as String? ?? '',
        venueCity: m['venueCity'] as String? ?? '',
        selectedPlayers:
            ((m['selectedPlayers'] as List?)?.cast<String>() ?? const [])
                .toSet(),
        captainId: m['captainId'] as String?,
        keeperId: m['keeperId'] as String?,
      );
}
