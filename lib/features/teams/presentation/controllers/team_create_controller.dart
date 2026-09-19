import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/error/failures.dart';
import '../../../location/domain/entities/geo_place.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/team_name.dart';
import '../providers/teams_providers.dart';
import '../state/team_create_state.dart';
import 'teams_list_controller.dart';

part 'team_create_controller.g.dart';

String? _blankToNull(String? v) {
  final t = v?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// Drives the five-step team-create wizard.
@riverpod
class TeamCreateController extends _$TeamCreateController {
  static const draftKey = 'team_create';
  Future<void> _pendingSave = Future.value();

  @override
  Future<TeamCreateState> build() async {
    final draft = await ref.read(wizardDraftStoreProvider).load(draftKey);
    if (draft == null) return const TeamCreateState();
    return _fromDraft(draft);
  }

  TeamCreateState? get _s => state.value;

  void _set(TeamCreateState next, {bool persist = true}) {
    state = AsyncData(next);
    if (persist && next.createdTeamId == null) _persist(next);
  }

  void setName(String v) => _mutate((s) => s.copyWith(name: v));
  void setType(TeamType t) => _mutate((s) => s.copyWith(type: t));
  void setPrivacy(TeamPrivacy p) => _mutate((s) => s.copyWith(privacy: p));
  void setTagline(String v) => _mutate((s) => s.copyWith(tagline: v));
  void setFoundedYear(String v) => _mutate((s) => s.copyWith(foundedYear: v));
  void setCity(String v) => setResolvedPlace(GeoPlace.manual(v));

  void setResolvedPlace(GeoPlace? place) => _mutate(
        (s) => s.copyWith(
          city: place?.city ?? place?.label ?? '',
          locationLabel: place?.label,
          district: place?.district,
          province: place?.province,
          postcode: place?.postcode,
          placeId: place?.placeId,
          latitude: place?.latitude,
          longitude: place?.longitude,
          countryCode: place?.countryCode,
        ),
      );

  void setArea(String v) => _mutate((s) => s.copyWith(area: v));
  void setHomeGround(String v) => _mutate((s) => s.copyWith(homeGround: v));
  void setColors(String primary, String secondary) =>
      _mutate((s) => s.copyWith(
            primaryColor: primary,
            secondaryColor: secondary,
          ));
  void setPrimaryColor(String hex) =>
      _mutate((s) => s.copyWith(primaryColor: hex));
  void setSecondaryColor(String hex) =>
      _mutate((s) => s.copyWith(secondaryColor: hex));
  void setMonogram(String value) =>
      _mutate((s) => s.copyWith(monogramOverride: value));
  void setCrestKind(CrestKind kind) => _mutate(
        (s) => s.copyWith(
          crestKind: kind,
          logoUrl: kind == CrestKind.upload ? s.logoUrl : null,
          logoName: kind == CrestKind.upload ? s.logoName : null,
          logoSize: kind == CrestKind.upload ? s.logoSize : null,
        ),
      );
  void setLogo({required String url, required String name, required int size}) =>
      _mutate(
        (s) => s.copyWith(
          crestKind: CrestKind.upload,
          logoUrl: url,
          logoName: name,
          logoSize: size,
        ),
      );
  void removeLogo() => _mutate(
        (s) => s.copyWith(
          crestKind: CrestKind.monogram,
          logoUrl: null,
          logoName: null,
          logoSize: null,
        ),
      );

  void _mutate(TeamCreateState Function(TeamCreateState) f) {
    final s = _s;
    if (s == null || s.submitting || s.createdTeamId != null) return;
    _set(f(s).copyWith(submitError: null));
  }

  void next() {
    final s = _s;
    if (s == null || s.submitting) return;
    if (s.step == TeamCreateStep.basics && !s.canContinueBasics) return;
    if (s.step == TeamCreateStep.home && !s.canContinueHome) return;
    final i = s.step.index;
    if (i < TeamCreateStep.values.length - 1) {
      _set(s.copyWith(step: TeamCreateStep.values[i + 1]));
    }
  }

  void back() {
    final s = _s;
    if (s == null || s.submitting) return;
    final i = s.step.index;
    if (i > 0) _set(s.copyWith(step: TeamCreateStep.values[i - 1]));
  }

  void goToStep(TeamCreateStep step) =>
      _mutate((s) => s.copyWith(step: step));

  Future<void> saveDraft() => _pendingSave;

  Future<void> submit() async {
    final s = _s;
    if (s == null || s.submitting || s.createdTeamId != null) return;
    if (!s.canSubmit) {
      _set(
        s.copyWith(
          submitError:
              'Add a team name and location, and check your founding year.',
        ),
      );
      return;
    }

    _set(
      s.copyWith(
        submitting: true,
        submitError: null,
        logoUploadError: null,
      ),
      persist: false,
    );

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
          city: _blankToNull(s.city),
          homeGround: _blankToNull(s.homeGround),
          label: _blankToNull(s.locationLabel ?? s.combinedCity),
          district: s.district,
          province: s.province,
          postcode: s.postcode,
          placeId: s.placeId,
          latitude: s.latitude,
          longitude: s.longitude,
          countryCode: s.countryCode,
          foundedYear: int.tryParse(s.foundedYear?.trim() ?? ''),
          primaryColor: s.primaryColor,
          secondaryColor: s.secondaryColor,
          tagline: _blankToNull(s.tagline),
          logoMonogram: _blankToNull(s.monogramOverride),
          crestKind: s.crestKind,
        );

    final current = _s;
    if (current == null) return;

    await result.fold(
      (failure) async => _set(
        current.copyWith(
          submitting: false,
          submitError: _friendlyError(failure),
        ),
        persist: false,
      ),
      (team) async {
        String? uploadError;
        if (current.crestKind == CrestKind.upload &&
            (current.logoUrl?.isNotEmpty ?? false)) {
          try {
            final file = File(current.logoUrl!);
            final bytes = await file.readAsBytes();
            final extension = file.path.split('.').last;
            final upload = await ref.read(teamsRepositoryProvider).uploadTeamLogo(
                  teamId: team.id,
                  bytes: bytes,
                  extension: extension,
                );
            if (upload.isLeft()) {
              uploadError =
                  'Your team is ready, but the logo could not be uploaded. Add it from team settings.';
            }
          } catch (_) {
            uploadError =
                'Your team is ready, but the logo file is unavailable. Add it from team settings.';
          }
        }

        await _pendingSave;
        await ref.read(wizardDraftStoreProvider).clear(draftKey);
        if (!ref.mounted) return;

        ref.invalidate(teamsListControllerProvider);
        _set(
          current.copyWith(
            submitting: false,
            createdTeamId: team.id.value,
            logoUploadError: uploadError,
          ),
          persist: false,
        );
      },
    );
  }

  void _persist(TeamCreateState s) {
    final store = ref.read(wizardDraftStoreProvider);
    final payload = <String, dynamic>{
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
      'locationLabel': s.locationLabel,
      'district': s.district,
      'province': s.province,
      'postcode': s.postcode,
      'placeId': s.placeId,
      'latitude': s.latitude,
      'longitude': s.longitude,
      'countryCode': s.countryCode,
    };
    _pendingSave = _pendingSave.then((_) => store.save(draftKey, payload));
  }

  Future<void> reset() async {
    state = const AsyncData(TeamCreateState());
    final store = ref.read(wizardDraftStoreProvider);
    await _pendingSave;
    await store.clear(draftKey);
  }

  static String _friendlyError(Failure failure) {
    if (failure is AuthFailure) {
      return 'Sign in again to create your team. Your draft is saved on this device.';
    }
    final message = failure.message.toLowerCase();
    if (message.contains('permission') || message.contains('row-level')) {
      return 'Team creation is unavailable for your account right now. Your draft is saved; please try again later.';
    }
    if (failure is NetworkFailure ||
        message.contains('socket') ||
        message.contains('connection')) {
      return 'Check your connection and try again. Your draft is saved on this device.';
    }
    return 'We couldn’t create your team. Your draft is saved. Please try again.';
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
        locationLabel: m['locationLabel'] as String?,
        district: m['district'] as String?,
        province: m['province'] as String?,
        postcode: m['postcode'] as String?,
        placeId: m['placeId'] as String?,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        countryCode: m['countryCode'] as String?,
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
