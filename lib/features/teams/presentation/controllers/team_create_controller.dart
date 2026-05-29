import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/team_name.dart';
import '../providers/teams_providers.dart';
import '../state/team_create_state.dart';

part 'team_create_controller.g.dart';

String? _blankToNull(String? v) {
  final t = v?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

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
  void setTagline(String v) => _mutate((s) => s.copyWith(tagline: v));
  void setFoundedYear(String v) => _mutate((s) => s.copyWith(foundedYear: v));
  void setCity(String v) => _mutate((s) => s.copyWith(city: v));
  void setArea(String v) => _mutate((s) => s.copyWith(area: v));
  void setHomeGround(String v) => _mutate((s) => s.copyWith(homeGround: v));
  void setColors(String primary, String secondary) =>
      _mutate((s) => s.copyWith(primaryColor: primary, secondaryColor: secondary));
  void setPrimaryColor(String hex) =>
      _mutate((s) => s.copyWith(primaryColor: hex));
  void setSecondaryColor(String hex) =>
      _mutate((s) => s.copyWith(secondaryColor: hex));
  void setMonogram(String value) =>
      _mutate((s) => s.copyWith(monogramOverride: value));
  void setCrestKind(CrestKind kind) => _mutate((s) => s.copyWith(
        crestKind: kind,
        // Picking a generated style clears any uploaded logo.
        logoUrl: kind == CrestKind.upload ? s.logoUrl : null,
        logoName: kind == CrestKind.upload ? s.logoName : null,
        logoSize: kind == CrestKind.upload ? s.logoSize : null,
      ));
  void setLogo({required String url, required String name, required int size}) =>
      _mutate((s) => s.copyWith(
            crestKind: CrestKind.upload,
            logoUrl: url,
            logoName: name,
            logoSize: size,
          ));
  void removeLogo() => _mutate((s) => s.copyWith(
        crestKind: CrestKind.monogram,
        logoUrl: null,
        logoName: null,
        logoSize: null,
      ));

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

    final nameRes = TeamName.create(s.name);
    if (nameRes.isLeft()) {
      _set(
        s.copyWith(
          submitting: false,
          submitError: nameRes.getLeft().toNullable()!.message,
        ),
        persist: false,
      );
      return;
    }

    final result = await ref.read(teamsRepositoryProvider).createTeam(
          name: nameRes.getRight().toNullable()!,
          type: s.type,
          privacy: s.privacy,
          city: _blankToNull(s.combinedCity),
          homeGround: _blankToNull(s.homeGround),
          foundedYear: int.tryParse(s.foundedYear?.trim() ?? ''),
          primaryColor: s.primaryColor,
          secondaryColor: s.secondaryColor,
          tagline: _blankToNull(s.tagline),
          logoMonogram: _blankToNull(s.monogramOverride),
        );

    final current = _s;
    if (current == null) return;
    await result.fold(
      (failure) async => _set(
        current.copyWith(submitting: false, submitError: failure.message),
        persist: false,
      ),
      (team) async {
        // If the user uploaded a logo, push it to Storage and patch
        // logo_url. Soft-failure: a failed upload still proceeds to the
        // Done screen — the user can replace it from the team page.
        if (current.crestKind == CrestKind.upload &&
            (current.logoUrl?.isNotEmpty ?? false)) {
          final file = File(current.logoUrl!);
          final bytes = await file.readAsBytes();
          final dot = file.path.lastIndexOf('.');
          final extension = dot >= 0 && dot < file.path.length - 1
              ? file.path.substring(dot + 1)
              : 'jpg';
          await ref.read(teamsRepositoryProvider).uploadTeamLogo(
                teamId: team.id,
                bytes: bytes,
                extension: extension,
              );
        }
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
      'tagline': s.tagline,
      'foundedYear': s.foundedYear,
      'city': s.city,
      'area': s.area,
      'homeGround': s.homeGround,
      'primaryColor': s.primaryColor,
      'secondaryColor': s.secondaryColor,
      'crestKind': s.crestKind.name,
      'monogramOverride': s.monogramOverride,
      'logoUrl': s.logoUrl,
      'logoName': s.logoName,
      'logoSize': s.logoSize,
    });
  }

  /// Resets the wizard so a freshly successful submit can be followed by
  /// "Create another team" from the Done screen.
  void reset() {
    state = const AsyncData(TeamCreateState());
    ref.read(wizardDraftStoreProvider).clear(_draftKey);
  }

  TeamCreateState _fromDraft(Map<String, dynamic> m) => TeamCreateState(
        step: TeamCreateStep.values.firstWhere(
          (e) => e.name == m['step'],
          orElse: () => TeamCreateStep.basics,
        ),
        name: m['name'] as String? ?? '',
        type: TeamType.fromWire(m['type'] as String?),
        privacy: TeamPrivacy.fromWire(m['privacy'] as String?),
        tagline: m['tagline'] as String? ?? '',
        foundedYear: m['foundedYear'] as String?,
        city: m['city'] as String? ?? '',
        area: m['area'] as String? ?? '',
        homeGround: m['homeGround'] as String? ?? '',
        primaryColor: m['primaryColor'] as String? ?? '#338946',
        secondaryColor: m['secondaryColor'] as String? ?? '#FDFAF4',
        crestKind: CrestKind.values.firstWhere(
          (e) => e.name == m['crestKind'],
          orElse: () => CrestKind.monogram,
        ),
        monogramOverride: m['monogramOverride'] as String?,
        logoUrl: m['logoUrl'] as String?,
        logoName: m['logoName'] as String?,
        logoSize: m['logoSize'] as int?,
      );
}
