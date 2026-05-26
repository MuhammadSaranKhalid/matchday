import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/team_create_state.dart';
import '../team_avatar.dart';
import 'tc_atoms.dart';

/// Step 05 — Review: hero card + summary rows that jump back to their step,
/// owner block, terms blurb.
class TcStepReview extends StatelessWidget {
  const TcStepReview({
    super.key,
    required this.state,
    required this.onJump,
    required this.onOwnershipTap,
  });

  final TeamCreateState state;
  final ValueChanged<TeamCreateStep> onJump;

  /// Tapping the owner block opens the ownership briefing overlay.
  final VoidCallback onOwnershipTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'Looks good?',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(
              'Tap any row to jump back and edit.',
              style: CkType.body(
                  fontSize: 13, color: CkColors.muted, height: 1.4),
            ),
          ),
          _HeroCard(state: state),
          const SizedBox(height: 14),
          _SummaryList(state: state, onJump: onJump),
          const SizedBox(height: 16),
          _OwnerBlock(onTap: onOwnershipTap),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "By creating this team you agree to Matchday's community "
              "guidelines. You'll be able to add players from the team page "
              'next.',
              style: CkType.body(
                  fontSize: 11, color: CkColors.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColor(state.primaryColor, fallback: CkColors.ink);
    final secondary =
        parseHexColor(state.secondaryColor, fallback: CkColors.paper);
    final fg = onColor(primary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              state.monogram,
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.03,
                color: onColor(secondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.name.trim().isEmpty
                      ? 'Your team name'
                      : state.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                    height: 1.05,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _eyebrow(state),
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
                if (state.tagline.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      '“${state.tagline}”',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.01,
                        height: 1.35,
                        color: fg.withValues(alpha: 0.9),
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _eyebrow(TeamCreateState s) {
    final parts = <String>[s.type.wire.toUpperCase()];
    final loc = [s.area, s.city]
        .where((p) => p.trim().isNotEmpty)
        .join(', ')
        .toUpperCase();
    if (loc.isNotEmpty) parts.add(loc);
    if ((s.foundedYear ?? '').trim().isNotEmpty) parts.add('EST. ${s.foundedYear}');
    return parts.join(' · ');
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.state, required this.onJump});
  final TeamCreateState state;
  final ValueChanged<TeamCreateStep> onJump;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        children: [
          _Row(
            label: 'BASICS',
            value: Text(
              [
                state.name.trim().isEmpty ? 'Unnamed' : state.name,
                state.type.wire,
                state.privacy.wire,
                'est. ${(state.foundedYear ?? '').trim().isEmpty ? '—' : state.foundedYear}'
              ].join(' · '),
              style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            onTap: () => onJump(TeamCreateStep.basics),
            isFirst: true,
          ),
          if (state.tagline.trim().isNotEmpty)
            _Row(
              label: 'TAGLINE',
              value: Text(
                '“${state.tagline}”',
                style: CkType.display(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.01,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              onTap: () => onJump(TeamCreateStep.basics),
            ),
          _Row(
            label: 'IDENTITY',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Swatch(hex: state.primaryColor),
                const SizedBox(width: 6),
                _Swatch(hex: state.secondaryColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Monogram "${state.monogram}"',
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(
                        fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            onTap: () => onJump(TeamCreateStep.identity),
          ),
          _Row(
            label: 'HOME',
            value: Text(
              [
                [state.area, state.city]
                    .where((p) => p.trim().isNotEmpty)
                    .join(', '),
                if (state.homeGround.trim().isNotEmpty) state.homeGround,
              ].where((s) => s.isNotEmpty).join(' · '),
              style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            onTap: () => onJump(TeamCreateStep.home),
          ),
          _Row(
            label: 'CREST',
            value: Text(
              state.crestKind == CrestKind.upload && state.logoUrl != null
                  ? 'Logo uploaded · ${state.logoName ?? 'logo'}'
                  : '${_kindLabel(state.crestKind)} style · auto-synced colors',
              style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            onTap: () => onJump(TeamCreateStep.crest),
          ),
        ],
      ),
    );
  }

  static String _kindLabel(CrestKind k) {
    switch (k) {
      case CrestKind.monogram:
        return 'Monogram';
      case CrestKind.initials:
        return 'Initials';
      case CrestKind.shield:
        return 'Shield';
      case CrestKind.upload:
        return 'Upload';
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.onTap,
    this.isFirst = false,
  });
  final String label;
  final Widget value;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(top: BorderSide(color: CkColors.hairline)),
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
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: value),
            const SizedBox(width: 8),
            const Icon(Icons.east, size: 14, color: CkColors.muted),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.hex});
  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: parseHexColor(hex, fallback: CkColors.ink),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CkColors.hairline),
      ),
    );
  }
}

class _OwnerBlock extends StatelessWidget {
  const _OwnerBlock({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              decoration: const BoxDecoration(
                color: CkColors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'YO',
                style: CkType.display(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.03,
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
                    style: CkType.body(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You can add co-managers and transfer ownership later.',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.info_outline, size: 16, color: CkColors.muted),
          ],
        ),
      ),
    );
  }
}
