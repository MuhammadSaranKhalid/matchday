import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';

/// Menu drawer — the matchday IA's CREX-style account hub, opened from the
/// [GlobalHeader] avatar. Full-screen overlay (not a slide-in drawer); back
/// arrow returns to the previous tab.
///
/// Sections, in order, from the design handoff prototype's `MenuOverlay`:
///
///   • Profile header row (avatar · name · @handle · View profile)
///   • MY STUFF       My matches · My teams (count) · My tournaments (count)
///   • ACTIVITY       Following · Saved · Rankings
///   • APP SETTINGS   Notifications · App theme · Language · Account & privacy
///   • Log out
///
/// Implemented destinations route to existing screens; the rest land on an
/// inline [_ComingSoonSubPage] placeholder until their features ship.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final teams = ref.watch(myTeamsProvider).value ?? const [];
    final teamCount = teams.length;
    const tournamentCount = 0; // Tournaments feature is in a follow-up ticket.

    return SubPage(
      title: 'Menu',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(
            name: profile?.displayName ?? 'Set your name',
            handle: profile?.username == null ? '' : '@${profile!.username}',
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 12),
          const _SectionLabel('My stuff'),
          _Row(
            icon: V2Icons.matches,
            label: 'My matches',
            onTap: () => context.push('/pavilion/my-matches'),
          ),
          _Row(
            icon: V2Icons.pavilion,
            label: 'My teams',
            trailing: teamCount > 0 ? '$teamCount' : null,
            onTap: () => context.push('/teams'),
          ),
          _Row(
            icon: V2Icons.trophy,
            label: 'My tournaments',
            trailing: tournamentCount > 0 ? '$tournamentCount' : null,
            onTap: () => context.push('/tournaments'),
          ),
          const _SectionLabel('Activity'),
          _Row(
            icon: V2Icons.follow,
            label: 'Following',
            onTap: () => _stub(context, 'Following'),
          ),
          _Row(
            icon: V2Icons.bookmark,
            label: 'Saved',
            onTap: () => _stub(context, 'Saved'),
          ),
          _Row(
            icon: V2Icons.rankings,
            label: 'Rankings',
            onTap: () => _stub(context, 'Rankings'),
          ),
          const _SectionLabel('App settings'),
          _Row(
            icon: V2Icons.bell,
            label: 'Notifications',
            onTap: () => context.push('/alerts'),
          ),
          _Row(
            icon: V2Icons.theme,
            label: 'App theme',
            trailing: 'Light',
            onTap: () => _stub(context, 'App theme'),
          ),
          _Row(
            icon: V2Icons.globe,
            label: 'Language',
            trailing: 'English',
            onTap: () => _stub(context, 'Language'),
          ),
          _Row(
            icon: V2Icons.lock,
            label: 'Account & privacy',
            onTap: () => _stub(context, 'Account & privacy'),
          ),
          const SizedBox(height: 8),
          _LogoutRow(
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              // Auth redirect handles navigation to /sign-in; no manual go.
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  void _stub(BuildContext context, String label) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ComingSoonSubPage(label: label),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.handle,
    required this.onTap,
  });
  final String name;
  final String handle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Avatar(mono: _initials(name), size: 48, tone: AvatarTone.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: CkType.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (handle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      style: CkType.body(fontSize: 13, color: CkColors.muted),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'View profile',
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CkColors.red,
                    ),
                  ),
                ],
              ),
            ),
            const V2Svg(
              V2Icons.chevronRight,
              size: 20,
              color: CkColors.soft,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '·';
    final parts = t.split(RegExp(r'\s+'));
    final b = StringBuffer(parts.first[0]);
    if (parts.length > 1) b.write(parts[1][0]);
    return b.toString().toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: SectionHeader(text.toUpperCase()),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final String icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            V2Svg(icon, size: 21, color: CkColors.ink2, strokeWidth: 1.8),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: CkType.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CkColors.ink,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: CkType.body(fontSize: 13, color: CkColors.muted),
              ),
              const SizedBox(width: 8),
            ],
            const V2Svg(
              V2Icons.chevronRight,
              size: 18,
              color: CkColors.soft,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            const V2Svg(
              V2Icons.logout,
              size: 20,
              color: CkColors.red,
              strokeWidth: 2,
            ),
            const SizedBox(width: 14),
            Text(
              'Log out',
              style: CkType.body(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CkColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline placeholder for Menu rows whose features haven't shipped yet.
/// Uses the shared [SubPage] chrome so back navigation matches the rest of
/// the menu hierarchy.
class _ComingSoonSubPage extends StatelessWidget {
  const _ComingSoonSubPage({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: label,
      eyebrow: 'MENU',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CkColors.hairline),
              ),
              child: const V2Svg(
                V2Icons.matches,
                size: 28,
                color: CkColors.ink2,
                strokeWidth: 1.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Coming soon',
              style: CkType.mono(fontSize: 10, color: CkColors.soft),
            ),
          ],
        ),
      ),
    );
  }
}
