import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/entities/team.dart';
import '../../domain/usecases/create_team.dart';
import '../providers/teams_providers.dart';
import '../state/team_create_state.dart';

part 'team_create_controller.g.dart';

/// Drives the 5-step team-create wizard. AsyncNotifier so [build] can restore a
/// persisted draft before the form seeds (mirrors OnboardingController).
@riverpod
class TeamCreateController extends _$TeamCreateController {
  static const _draftKey = 'team_create';

  @override
  Future<TeamCreateState> build() async {
    final draft = await ref.read(wizardDraftStoreProvider).load(_draftKey);
    if (draft == null) return const TeamCreateState();
    return _fromDraft(draft);
  }

  TeamCreateState? get _s => state.value;

  void _set(TeamCreateState next, {bool persist = true}) {
    state = AsyncData(next);
    if (persist && next.createdTeamId == null) _persist(next);
  }

  // ─── Field setters ────────────────────────────────────────────────────────

  void setName(String v) => _mutate((s) => s.copyWith(name: v));
  void setType(TeamType t) => _mutate((s) => s.copyWith(type: t));
  void setPrivacy(TeamPrivacy p) => _mutate((s) => s.copyWith(privacy: p));
  void setFoundedYear(String v) => _mutate((s) => s.copyWith(foundedYear: v));
  void setCity(String v) => _mutate((s) => s.copyWith(city: v));
  void setArea(String v) => _mutate((s) => s.copyWith(area: v));
  void setHomeGround(String v) => _mutate((s) => s.copyWith(homeGround: v));
  void setColors(String primary, String secondary) =>
      _mutate((s) => s.copyWith(primaryColor: primary, secondaryColor: secondary));

  void _mutate(TeamCreateState Function(TeamCreateState) f) {
    final s = _s;
    if (s == null) return;
    _set(f(s));
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void next() {
    final s = _s;
    if (s == null) return;
    final order = TeamCreateStep.values;
    final i = s.step.index;
    if (i < order.length - 1) _set(s.copyWith(step: order[i + 1]));
  }

  void back() {
    final s = _s;
    if (s == null) return;
    final i = s.step.index;
    if (i > 0) _set(s.copyWith(step: TeamCreateStep.values[i - 1]));
  }

  void goToStep(TeamCreateStep step) => _mutate((s) => s.copyWith(step: step));

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> submit() async {
    final s = _s;
    if (s == null || s.submitting) return;
    _set(s.copyWith(submitting: true, submitError: null), persist: false);

    final result = await ref.read(createTeamUseCaseProvider).call(
          CreateTeamParams(
            name: s.name,
            type: s.type,
            privacy: s.privacy,
            city: s.combinedCity,
            homeGround: s.homeGround,
            foundedYear: int.tryParse(s.foundedYear?.trim() ?? ''),
            primaryColor: s.primaryColor,
            secondaryColor: s.secondaryColor,
          ),
        );

    final current = _s;
    if (current == null) return;
    await result.fold(
      (failure) async => _set(
        current.copyWith(submitting: false, submitError: failure.message),
        persist: false,
      ),
      (team) async {
        await ref.read(wizardDraftStoreProvider).clear(_draftKey);
        _set(
          current.copyWith(submitting: false, createdTeamId: team.id.value),
          persist: false,
        );
      },
    );
  }

  // ─── Draft (de)serialization ────────────────────────────────────────────

  void _persist(TeamCreateState s) {
    ref.read(wizardDraftStoreProvider).save(_draftKey, {
      'step': s.step.name,
      'name': s.name,
      'type': s.type.wire,
      'privacy': s.privacy.wire,
      'foundedYear': s.foundedYear,
      'city': s.city,
      'area': s.area,
      'homeGround': s.homeGround,
      'primaryColor': s.primaryColor,
      'secondaryColor': s.secondaryColor,
    });
  }

  TeamCreateState _fromDraft(Map<String, dynamic> m) => TeamCreateState(
        step: TeamCreateStep.values.firstWhere(
          (e) => e.name == m['step'],
          orElse: () => TeamCreateStep.basics,
        ),
        name: m['name'] as String? ?? '',
        type: TeamType.fromWire(m['type'] as String?),
        privacy: TeamPrivacy.fromWire(m['privacy'] as String?),
        foundedYear: m['foundedYear'] as String?,
        city: m['city'] as String? ?? '',
        area: m['area'] as String? ?? '',
        homeGround: m['homeGround'] as String? ?? '',
        primaryColor: m['primaryColor'] as String? ?? '#338946',
        secondaryColor: m['secondaryColor'] as String? ?? '#E24A3F',
      );
}
