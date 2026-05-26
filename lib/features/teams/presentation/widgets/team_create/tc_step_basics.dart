import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/team.dart';
import '../../controllers/team_create_controller.dart';
import '../../state/team_create_state.dart';
import 'tc_atoms.dart';

/// Step 01 — Basics: name, team type tiles, founded year, privacy.
/// Faithful port of `TCStepBasics` in design/screens/TeamCreate.jsx.
class TcStepBasics extends StatelessWidget {
  const TcStepBasics({super.key, required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 18),
            child: Text(
              'Name your team.',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          const TcLabel('Team name'),
          TcInput(
            value: state.name,
            onChanged: controller.setName,
            maxLength: 50,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '3–50 characters · we\'ll use first letters as a crest',
                    style:
                        CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ),
                Text(
                  '${state.name.length}/50',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.02,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const TcLabel('Team type'),
          _TypeGrid(value: state.type, onChanged: controller.setType),
          const SizedBox(height: 16),
          _TaglineSection(state: state, controller: controller),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TcLabel('Founded'),
                    TcInput(
                      value: state.foundedYear ?? '',
                      onChanged: controller.setFoundedYear,
                      placeholder: '2019',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TcLabel('Privacy'),
                    _PrivacyToggle(
                        value: state.privacy, onChanged: controller.setPrivacy),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PrivacyExplainer(privacy: state.privacy),
        ],
      ),
    );
  }
}

class _TaglineSection extends StatelessWidget {
  const _TaglineSection({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'TAGLINE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· optional',
                style: CkType.body(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: CkColors.soft,
                ),
              ),
              const Spacer(),
              Text(
                '${state.tagline.length}/60',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        TcInput(
          value: state.tagline,
          onChanged: controller.setTagline,
          maxLength: 60,
          placeholder: 'e.g. Roar with the Lions.',
          textStyle: CkType.display(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.01,
          ).copyWith(
            fontStyle: state.tagline.isEmpty
                ? FontStyle.italic
                : FontStyle.normal,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'A short motto. Shows on your team page and scorecards.',
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ),
      ],
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.value, required this.onChanged});
  final TeamType value;
  final ValueChanged<TeamType> onChanged;

  static const _options = <(TeamType, String, String)>[
    (TeamType.club, 'Club', 'Persistent club with branding'),
    (TeamType.village, 'Village', 'Mohalla / community team'),
    (TeamType.casual, 'Casual', 'One-off for a tournament'),
    (TeamType.corporate, 'Corporate', 'Office / department'),
    (TeamType.school, 'School', 'School team'),
    (TeamType.university, 'University', 'Uni team'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final opt in _options)
          _TypeTile(
            label: opt.$2,
            subtitle: opt.$3,
            selected: value == opt.$1,
            onTap: () => onChanged(opt.$1),
          ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: selected ? CkColors.paper : CkColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: CkType.display(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style:
                  CkType.body(fontSize: 10, color: CkColors.muted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  const _PrivacyToggle({required this.value, required this.onChanged});
  final TeamPrivacy value;
  final ValueChanged<TeamPrivacy> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final p in TeamPrivacy.values) ...[
          if (p != TeamPrivacy.values.first) const SizedBox(width: 6),
          Expanded(child: _PrivacyBtn(privacy: p, value: value, onChanged: onChanged)),
        ],
      ],
    );
  }
}

class _PrivacyBtn extends StatelessWidget {
  const _PrivacyBtn({
    required this.privacy,
    required this.value,
    required this.onChanged,
  });
  final TeamPrivacy privacy;
  final TeamPrivacy value;
  final ValueChanged<TeamPrivacy> onChanged;

  String get _label =>
      privacy == TeamPrivacy.public ? 'Public' : 'Private';

  @override
  Widget build(BuildContext context) {
    final selected = value == privacy;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(privacy);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 49,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CkColors.paper : CkColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          _label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _PrivacyExplainer extends StatelessWidget {
  const _PrivacyExplainer({required this.privacy});
  final TeamPrivacy privacy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child:
                Icon(Icons.info_outline, size: 16, color: CkColors.ink2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: CkType.body(
                  fontSize: 11,
                  color: CkColors.ink2,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Private',
                    style: CkType.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' teams hide their roster from non-members and are invite-only. You can change this later.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
