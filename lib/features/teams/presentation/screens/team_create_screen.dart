import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/team.dart';
import '../controllers/team_create_controller.dart';
import '../state/team_create_state.dart';
import '../utils/team_display.dart';
import '../widgets/team_create/ownership_sheet.dart';
import '../widgets/team_create/tc_atoms.dart';

/// Existing Matchday five-step team-creation visual flow.
///
/// The controller/data implementation underneath it is the cleaned one-shot
/// architecture; this screen deliberately keeps the established wizard
/// structure, surfaces and typography.
class TeamCreateScreen extends ConsumerWidget {
  const TeamCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(teamCreateControllerProvider, (previous, next) {
      final error = next.value?.submitError;
      if (error != null && previous?.value?.submitError != error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    });

    final async = ref.watch(teamCreateControllerProvider);
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (async) {
        AsyncData(:final value) when value.createdTeamId != null =>
          SafeArea(child: _DoneView(state: value)),
        AsyncData(:final value) => SafeArea(child: _Wizard(state: value)),
        _ => const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          ),
      },
    );
  }
}

class _Wizard extends ConsumerWidget {
  const _Wizard({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(teamCreateControllerProvider.notifier);
    final index = state.step.index;

    return Column(
      children: [
        _TopBar(
          step: index + 1,
          totalSteps: TeamCreateStep.values.length,
          onBack: () {
            if (index == 0) {
              context.pop();
            } else {
              controller.back();
            }
          },
          onSaveExit: () => _showSaveExit(
            context,
            step: index + 1,
            total: TeamCreateStep.values.length,
            onDiscard: () async {
              await controller.reset();
              if (context.mounted) context.pop();
            },
          ),
        ),
        _Progress(step: index + 1),
        Expanded(
          child: switch (state.step) {
            TeamCreateStep.basics => _Basics(
                state: state,
                controller: controller,
              ),
            TeamCreateStep.identity => _Identity(
                state: state,
                controller: controller,
              ),
            TeamCreateStep.home => _Home(
                state: state,
                controller: controller,
              ),
            TeamCreateStep.crest => _Crest(
                state: state,
                controller: controller,
              ),
            TeamCreateStep.review => _Review(
                state: state,
                onEdit: controller.goToStep,
                onOwnership: () => showTeamOwnershipSheet(context),
              ),
          },
        ),
        _Footer(state: state, controller: controller),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onSaveExit,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onSaveExit;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 14, 4),
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.chevron_left, size: 22, color: CkColors.ink),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'NEW TEAM · $step/$totalSteps',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .12,
                    color: CkColors.muted,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: onSaveExit,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(
                  'SAVE & EXIT',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .08,
                    color: CkColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});
  final int step;

  static const labels = ['BASICS', 'IDENTITY', 'HOME', 'CREST', 'REVIEW'];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: i < step ? CkColors.ink : CkColors.paper2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'STEP $step · ${labels[step - 1]}',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .10,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.controller});

  final TeamCreateState state;
  final TeamCreateController controller;

  bool get canContinue => switch (state.step) {
        TeamCreateStep.basics => state.canContinueBasics,
        TeamCreateStep.home => state.canContinueHome,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final isLast = state.step == TeamCreateStep.review;
    final disabled = state.submitting || !canContinue;
    final label = isLast
        ? (state.submitting ? 'Creating…' : 'Create team')
        : state.step == TeamCreateStep.crest
            ? 'Review'
            : 'Continue';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          if (state.step.index > 0) ...[
            InkWell(
              onTap: state.submitting ? null : controller.back,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Text(
                  'Back',
                  style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: InkWell(
              onTap: disabled
                  ? null
                  : isLast
                      ? controller.submit
                      : controller.next,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.ink.withValues(alpha: disabled ? .35 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: CkType.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLast ? Icons.check_rounded : Icons.arrow_forward,
                      size: 16,
                      color: CkColors.paper,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Basics extends StatelessWidget {
  const _Basics({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          const _StepTitle('Name your team.'),
          const TcLabel('Team name'),
          TcInput(
            value: state.name,
            onChanged: controller.setName,
            maxLength: 50,
            autofocus: state.name.isEmpty,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '3–50 characters · first letters become the default crest',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ),
              Text(
                '${state.name.length}/50',
                style: CkType.mono(fontSize: 10, color: CkColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const TcLabel('Team type'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.25,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              for (final type in TeamType.values)
                TcSelectTile(
                  title: _typeLabel(type),
                  selected: state.type == type,
                  onTap: () => controller.setType(type),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const TcLabel('Founded year'),
          TcInput(
            value: state.foundedYear ?? '',
            onChanged: controller.setFoundedYear,
            placeholder: 'Optional · e.g. 2022',
            keyboardType: TextInputType.number,
            maxLength: 4,
            hasError: state.foundedYearError != null,
          ),
          if (state.foundedYearError != null) ...[
            const SizedBox(height: 5),
            Text(
              state.foundedYearError!,
              style: CkType.body(fontSize: 11, color: CkColors.red),
            ),
          ],
          const SizedBox(height: 22),
          const TcLabel('Visibility'),
          Row(
            children: [
              Expanded(
                child: TcSelectTile(
                  title: 'Public',
                  subtitle: 'Discoverable',
                  selected: state.privacy == TeamPrivacy.public,
                  leading: const Icon(Icons.public_rounded, size: 20),
                  onTap: () => controller.setPrivacy(TeamPrivacy.public),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TcSelectTile(
                  title: 'Private',
                  subtitle: 'Invite-only',
                  selected: state.privacy == TeamPrivacy.private,
                  leading: const Icon(Icons.lock_outline_rounded, size: 20),
                  onTap: () => controller.setPrivacy(TeamPrivacy.private),
                ),
              ),
            ],
          ),
        ],
      );
}

class _Identity extends StatelessWidget {
  const _Identity({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          const _StepTitle('Give it a voice.'),
          const TcLabel('Tagline'),
          TcInput(
            value: state.tagline,
            onChanged: controller.setTagline,
            placeholder: 'Optional · e.g. One team, one dream',
            maxLength: 80,
          ),
          const SizedBox(height: 22),
          const TcLabel('Primary colour'),
          TcColorGrid(
            palette: kTeamCreatePalette,
            value: state.primaryColor,
            onChanged: controller.setPrimaryColor,
          ),
          const SizedBox(height: 22),
          const TcLabel('Secondary colour'),
          TcColorGrid(
            palette: kTeamCreatePalette,
            value: state.secondaryColor,
            onChanged: controller.setSecondaryColor,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: parseHexColor(state.primaryColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    state.monogram,
                    style: CkType.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: onColor(parseHexColor(state.primaryColor)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.name.trim().isEmpty ? 'Your team' : state.name,
                        style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      if (state.tagline.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '“${state.tagline.trim()}”',
                          style: CkType.body(fontSize: 12, color: CkColors.muted)
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _Home extends StatelessWidget {
  const _Home({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          const _StepTitle('Where do you play?'),
          const TcLabel('City / locality'),
          TcInput(
            value: state.city,
            onChanged: controller.setCity,
            placeholder: 'e.g. Lahore',
            hasError: !state.canContinueHome && state.city.isNotEmpty,
          ),
          const SizedBox(height: 16),
          const TcLabel('Area'),
          TcInput(
            value: state.area,
            onChanged: controller.setArea,
            placeholder: 'Optional · e.g. Johar Town',
          ),
          const SizedBox(height: 16),
          const TcLabel('Home ground'),
          TcInput(
            value: state.homeGround,
            onChanged: controller.setHomeGround,
            placeholder: 'Optional',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 19, color: CkColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Location helps nearby cricketers discover public teams. '
                    'Private teams remain invite-only.',
                    style: CkType.body(fontSize: 12, height: 1.4, color: CkColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _Crest extends StatelessWidget {
  const _Crest({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  Future<void> _pickLogo(BuildContext context) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (file == null) return;
    final size = await File(file.path).length();
    if (!context.mounted) return;
    if (size > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo must be 2 MB or smaller.')),
      );
      return;
    }
    controller.setLogo(url: file.path, name: file.name, size: size);
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          const _StepTitle('Choose your crest.'),
          Center(
            child: TcCrestPreview(
              crestKind: state.crestKind,
              primaryHex: state.primaryColor,
              monogram: state.monogram,
              logoPath: state.logoUrl,
              size: 132,
            ),
          ),
          const SizedBox(height: 24),
          const TcLabel('Style'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              for (final kind in CrestKind.values)
                TcSelectTile(
                  title: _crestLabel(kind),
                  selected: state.crestKind == kind,
                  onTap: () {
                    if (kind == CrestKind.upload) {
                      _pickLogo(context);
                    } else {
                      controller.setCrestKind(kind);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (state.crestKind != CrestKind.upload) ...[
            const TcLabel('Monogram'),
            TcInput(
              value: state.monogramOverride ?? '',
              onChanged: controller.setMonogram,
              placeholder: state.monogram,
              maxLength: 3,
              textAlign: TextAlign.center,
              textStyle: CkType.display(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ] else if (state.logoUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.logoName ?? 'Selected logo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickLogo(context),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

class _Review extends StatelessWidget {
  const _Review({
    required this.state,
    required this.onEdit,
    required this.onOwnership,
  });
  final TeamCreateState state;
  final ValueChanged<TeamCreateStep> onEdit;
  final VoidCallback onOwnership;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          const _StepTitle('Ready to take the field?'),
          Center(
            child: TcCrestPreview(
              crestKind: state.crestKind,
              primaryHex: state.primaryColor,
              monogram: state.monogram,
              logoPath: state.logoUrl,
              size: 104,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            state.name.trim(),
            textAlign: TextAlign.center,
            style: CkType.display(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          if (state.tagline.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '“${state.tagline.trim()}”',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 13, color: CkColors.muted)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              children: [
                _ReviewRow(
                  label: 'BASICS',
                  value: '${_typeLabel(state.type)} · ${state.privacy.wire}',
                  first: true,
                  onTap: () => onEdit(TeamCreateStep.basics),
                ),
                _ReviewRow(
                  label: 'IDENTITY',
                  value: 'Team colours · ${state.tagline.trim().isEmpty ? 'No tagline' : state.tagline.trim()}',
                  onTap: () => onEdit(TeamCreateStep.identity),
                ),
                _ReviewRow(
                  label: 'HOME',
                  value: [
                    state.combinedCity,
                    if (state.homeGround.trim().isNotEmpty) state.homeGround.trim(),
                  ].where((e) => e.isNotEmpty).join(' · '),
                  onTap: () => onEdit(TeamCreateStep.home),
                ),
                _ReviewRow(
                  label: 'CREST',
                  value: _crestLabel(state.crestKind),
                  onTap: () => onEdit(TeamCreateStep.crest),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onOwnership,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: CkColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'YO',
                      style: CkType.display(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You'll be the team owner",
                          style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You can add managers and transfer ownership later.',
                          style: CkType.body(fontSize: 11, color: CkColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline, size: 16, color: CkColors.muted),
                ],
              ),
            ),
          ),
          if (state.submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              state.submitError!,
              style: CkType.body(fontSize: 12, color: CkColors.red),
            ),
          ],
        ],
      );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.first = false,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool first;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: first ? null : const Border(top: BorderSide(color: CkColors.hairline)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  label,
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .10,
                    color: CkColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.east, size: 14, color: CkColors.muted),
            ],
          ),
        ),
      );
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    void openTeam() => context.pushReplacement('/teams/${state.createdTeamId}');

    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: IconButton(
              onPressed: openTeam,
              icon: const Icon(Icons.close_rounded, color: CkColors.ink),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TcCrestPreview(
                      crestKind: state.crestKind,
                      primaryHex: state.primaryColor,
                      monogram: state.monogram,
                      logoPath: state.logoUrl,
                      size: 130,
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: CkColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: CkColors.paper, width: 3),
                        ),
                        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${state.name.trim().isEmpty ? 'Your team' : state.name} is live.',
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.025,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You're all set as the team owner.",
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 15, color: CkColors.muted),
              ),
              if (state.logoUploadError != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.logoUploadError!,
                  textAlign: TextAlign.center,
                  style: CkType.body(fontSize: 12, color: CkColors.red),
                ),
              ],
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CkColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CkColors.line),
                ),
                child: Column(
                  children: [
                    _ReceiptRow('Type & visibility', '${_typeLabel(state.type)} · ${state.privacy.wire}'),
                    if (state.combinedCity.isNotEmpty)
                      _ReceiptRow('Location', state.combinedCity),
                    _ReceiptRow('Crest', _crestLabel(state.crestKind)),
                    const _ReceiptRow('Your role', 'Team Owner', last: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: CkColors.hairline)),
          ),
          child: InkWell(
            onTap: openTeam,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Open team page  →',
                style: CkType.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: CkType.body(fontSize: 13, color: CkColors.ink2))),
            Text(value, style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 18),
        child: Text(
          text,
          style: CkType.display(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -.025,
            height: 1.1,
          ),
        ),
      );
}

Future<void> _showSaveExit(
  BuildContext context, {
  required int step,
  required int total,
  required Future<void> Function() onDiscard,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: CkColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: CkColors.line, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Save your draft?',
              style: CkType.display(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "You're on step $step of $total. Your draft is saved automatically on this device.",
              style: CkType.body(fontSize: 13, color: CkColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, 'exit'),
              child: const Text('Save draft & exit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, 'continue'),
              child: const Text('Keep going'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, 'discard'),
              child: const Text('Discard changes', style: TextStyle(color: CkColors.red)),
            ),
          ],
        ),
      ),
    ),
  );

  if (!context.mounted) return;
  if (action == 'exit') {
    context.pop();
  } else if (action == 'discard') {
    await onDiscard();
  }
}

String _typeLabel(TeamType type) => switch (type) {
      TeamType.club => 'Club',
      TeamType.village => 'Village',
      TeamType.casual => 'Casual',
      TeamType.corporate => 'Corporate',
      TeamType.school => 'School',
      TeamType.university => 'University',
    };

String _crestLabel(CrestKind kind) => switch (kind) {
      CrestKind.monogram => 'Monogram',
      CrestKind.initials => 'Initials',
      CrestKind.shield => 'Shield',
      CrestKind.upload => 'Upload logo',
    };
