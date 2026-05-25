import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/ck_screen_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../../onboarding/domain/entities/player_profile.dart';
import '../../../onboarding/domain/entities/profile.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';

/// The PAVILION tab: profile hub (Pavilion.jsx). Phase 1 shows the profile
/// header + "Yours" (teams/matches) + Settings (sign out). The Status /
/// Calendar / Tournaments / Wallet / Achievements / Library zones are v1.1.
class PavilionScreen extends ConsumerWidget {
  const PavilionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final teams = ref.watch(myTeamsProvider).value ?? const <Team>[];
    final matches = ref.watch(myMatchesProvider).value ?? const <Match>[];

    return CkScreenScaffold(
      title: 'Pavilion',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: 18),
          _sectionLabel('YOURS'),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.shield_outlined,
            title: 'My teams',
            sub: teams.isEmpty ? 'No teams yet' : '${teams.length} team${teams.length == 1 ? '' : 's'}',
            onTap: () => context.go('/matches'),
          ),
          _Tile(
            icon: Icons.sports_cricket_outlined,
            title: 'My matches',
            sub: _matchesSummary(matches),
            onTap: () => context.go('/matches'),
          ),
          const SizedBox(height: 18),
          _sectionLabel('SETTINGS'),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            sub: 'End your session on this device',
            danger: true,
            onTap: () => _signOut(context, ref),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text('CIRCK v0.1 · ENGLISH',
                style: CkType.mono(fontSize: 9, color: CkColors.soft)),
          ),
        ],
      ),
    );
  }

  String _matchesSummary(List<Match> matches) {
    if (matches.isEmpty) return 'No matches yet';
    final pending = matches.where((m) => m.status == MatchStatus.pending).length;
    final live = matches.where((m) => m.status == MatchStatus.live).length;
    final done = matches.where((m) => m.status == MatchStatus.completed).length;
    return [
      if (pending > 0) '$pending pending',
      if (live > 0) '$live live',
      if (done > 0) '$done completed',
    ].join(' · ').ifEmpty('${matches.length} total');
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CkColors.paper,
        title: Text('Sign out?', style: CkType.display(fontSize: 18)),
        content: Text('You can sign back in any time.',
            style: CkType.body(fontSize: 14, color: CkColors.ink2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm != true) return;
    // On success the auth stream emits null and the router redirects to /sign-in.
    await ref.read(signOutUseCaseProvider).call(const NoParams());
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: CkType.mono(fontSize: 11, color: CkColors.muted));
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? '—';
    final username = profile?.username;
    final city = profile?.city;
    final player = profile?.playerProfile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.lg),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: CkColors.ink, shape: BoxShape.circle),
                child: Text(_initials(name),
                    style: CkType.display(fontSize: 20, color: CkColors.paper)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (username != null) '@$username',
                        if (city != null && city.isNotEmpty) city,
                      ].join(' · '),
                      style: CkType.body(fontSize: 13, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (player != null && player.hasAny) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (player.role != null) _chip(_roleLabel(player.role!)),
                if (player.battingStyle != null)
                  _chip(_battingLabel(player.battingStyle!)),
                if (player.bowlingStyle != null)
                  _chip(_bowlingLabel(player.bowlingStyle!)),
                for (final ball in player.preferredBallTypes)
                  _chip('${_ballLabel(ball)} ball'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((w) => w[0]).join().toUpperCase();
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: CkColors.cream,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: CkType.body(
                fontSize: 12, fontWeight: FontWeight.w600, color: CkColors.ink2)),
      );

  String _roleLabel(PlayerRole r) => switch (r) {
        PlayerRole.batter => 'Batter',
        PlayerRole.bowler => 'Bowler',
        PlayerRole.allRounder => 'All-rounder',
        PlayerRole.wicketKeeper => 'Keeper',
      };
  String _battingLabel(BattingStyle b) =>
      b == BattingStyle.rightHand ? 'Right-hand bat' : 'Left-hand bat';
  String _bowlingLabel(BowlingStyle b) => switch (b) {
        BowlingStyle.rightArmFast => 'Right-arm fast',
        BowlingStyle.rightArmMedium => 'Right-arm medium',
        BowlingStyle.rightArmSpin => 'Right-arm spin',
        BowlingStyle.leftArmFast => 'Left-arm fast',
        BowlingStyle.leftArmSpin => 'Left-arm spin',
        BowlingStyle.doesntBowl => "Doesn't bowl",
      };
  String _ballLabel(BallType b) => switch (b) {
        BallType.leather => 'Leather',
        BallType.tape => 'Tape',
        BallType.tennis => 'Tennis',
      };
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? CkColors.red : CkColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: danger ? CkColors.redSoft : CkColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: CkType.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: danger ? CkColors.red : CkColors.ink)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: CkType.body(fontSize: 12, color: CkColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: CkColors.soft),
            ],
          ),
        ),
      ),
    );
  }
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
