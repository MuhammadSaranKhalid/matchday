import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// The "you" surface — artboard **2b · Nothing on the right**.
///
/// > Pure navigation. Every row is icon, label, chevron — no state at all.
///
/// That sentence is the whole specification, and it is a deliberate reversal:
/// the panel used to carry a live-match card, per-row subtitles, and badges
/// counting upcoming fixtures, open challenges and squads. All of it is gone.
/// A menu that reports is a menu you have to *read*; this one you only have to
/// aim at. The counts still exist — they live on the screens that own them,
/// one tap deeper.
///
/// The glyphs are the canvas's own, drawn to one family: a 24 optical box,
/// 1.9 stroke, round caps and joins, outline only, no fills. They are rendered
/// from the artboard's exact path data rather than redrawn as Flutter icons,
/// because "same optical box, same stroke, same corner language" is a property
/// of the set — approximating any one glyph breaks the family.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final user = ref.watch(supabaseClientProvider).auth.currentUser;

    final name = profile?.displayName ?? profile?.username ?? '';
    // The canvas puts the email under the name, not "@handle · role · city".
    // It is the one line that says *which account you are signed into*, which
    // is the question this block exists to answer.
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            const _Hairline(),
            _Identity(
              name: name,
              email: email,
              avatarUrl: profile?.avatarUrl,
              onTap: () => context.push('/profile'),
            ),
            const _Hairline(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const [
                  _Eyebrow('Yours'),
                  _MenuRow(
                    icon: _MenuGlyphs.matches,
                    label: 'My Matches',
                    route: '/my/matches',
                  ),
                  _MenuRow(
                    icon: _MenuGlyphs.teams,
                    label: 'My Teams',
                    route: '/my/teams',
                  ),
                  _MenuRow(
                    icon: _MenuGlyphs.challenges,
                    label: 'My Challenges',
                    route: '/my/pool-requests',
                  ),
                  _MenuRow(
                    icon: _MenuGlyphs.tournaments,
                    label: 'My Tournaments',
                    route: '/my/tournaments',
                  ),

                  _GroupRule(),
                  _Eyebrow('Activity'),
                  // TODO(menu): no screen behind this row yet — see the note
                  // in the PR. It is drawn live in 2b, so it is drawn live
                  // here, but it has nowhere to go until that surface exists.
                  _MenuRow(
                    icon: _MenuGlyphs.invites,
                    label: 'Invites & requests',
                  ),
                  _MenuRow(
                    icon: _MenuGlyphs.notifications,
                    label: 'Notifications',
                    route: '/notifications',
                  ),
                  _MenuRow(
                    icon: _MenuGlyphs.saved,
                    label: 'Saved',
                    route: '/saved',
                  ),

                  _GroupRule(),
                  _Eyebrow('Account'),
                  _MenuRow(
                    icon: _MenuGlyphs.settings,
                    label: 'Settings',
                    route: '/settings',
                  ),
                  // The one exception to "nothing on the right", and it earns
                  // it by replacing the chevron rather than joining it: a row
                  // that says Soon is not a destination.
                  _MenuRow(
                    icon: _MenuGlyphs.help,
                    label: 'Help & Support',
                    soon: true,
                  ),
                ],
              ),
            ),
            const _Hairline(),
            const _SignOut(),
          ],
        ),
      ),
    );
  }
}

// ─── Chrome ─────────────────────────────────────────────────────────────────

/// 2b draws its own 38pt back button and a 25pt title, rather than the 56dp
/// [CkPushNav] every other pushed route wears. Menu is the one page whose
/// title *is* the page, so the canvas gives it the larger setting.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _MenuGlyphs.svg(
                _MenuGlyphs.back,
                size: 18,
                color: CkColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Menu',
            style: CkType.display(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: CkColors.hairline);
}

/// The rule that opens a new group. Carries the canvas's 10pt of air above it
/// so the sections breathe without a spacer widget.
class _GroupRule extends StatelessWidget {
  const _GroupRule();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 10),
        child: _Hairline(),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
      child: Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

// ─── Identity ───────────────────────────────────────────────────────────────

class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onTap,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onTap;

  /// "Muhammad Saran" → "MS". Two letters, or one when there is only one word.
  String get _initials {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                // A pale slate ground, so a monogram reads as a portrait slot
                // rather than as another paper chip.
                color: const Color(0xFFDCE6EE),
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              alignment: Alignment.center,
              child: url == null || url.isEmpty
                  ? Text(
                      _initials,
                      style: CkType.display(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink2,
                      ),
                    )
                  : Image.network(
                      url,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        _initials,
                        style: CkType.display(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink2,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(
                      fontSize: 13,
                      color: const Color(0xFF6E6658),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _MenuGlyphs.svg(
              _MenuGlyphs.chevron,
              size: 17,
              color: CkColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rows ───────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.route,
    this.soon = false,
  });

  final String icon;
  final String label;

  /// Null means the row is drawn but goes nowhere yet.
  final String? route;

  /// Renders the row muted with a Soon pill where the chevron would be.
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final r = route;

    return InkWell(
      onTap: soon || r == null ? null : () => context.push(r),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _MenuGlyphs.svg(
                icon,
                size: 22,
                color: soon ? CkColors.soft : CkColors.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: soon ? CkColors.muted : CkColors.ink,
                  ),
                ),
              ),
              if (soon)
                const _SoonPill()
              else
                _MenuGlyphs.svg(
                  _MenuGlyphs.chevron,
                  size: 17,
                  color: CkColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoonPill extends StatelessWidget {
  const _SoonPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Text(
        'SOON',
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.09,
          color: CkColors.amberDark,
        ),
      ),
    );
  }
}

// ─── Sign out ───────────────────────────────────────────────────────────────

class _SignOut extends ConsumerWidget {
  const _SignOut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: InkWell(
        onTap: () => _confirm(context, ref),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MenuGlyphs.svg(
                _MenuGlyphs.signOut,
                size: 17,
                color: CkColors.red,
              ),
              const SizedBox(width: 9),
              Text(
                'Sign out',
                style: CkType.display(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: CkColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        buttonPadding: EdgeInsets.zero,
        actionsAlignment: MainAxisAlignment.end,
        title: Text('Sign out', style: CkType.display(fontSize: 18)),
        content: Text(
          'Are you sure you want to sign out of Matchday?',
          style: CkType.body(
            fontSize: 13.5,
            height: 1.5,
            color: CkColors.ink2,
          ),
        ),
        actions: [
          _DialogAction(
            label: 'Cancel',
            style: CkType.body(fontSize: 13, color: CkColors.muted),
            onTap: () => Navigator.of(dialogCtx).pop(),
          ),
          const SizedBox(width: 8),
          _DialogAction(
            label: 'Sign out',
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CkColors.red,
            ),
            onTap: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(label, style: style),
      ),
    );
  }
}

// ─── Glyphs ─────────────────────────────────────────────────────────────────

/// The artboard's glyph set, verbatim.
///
/// Held as SVG path data and rendered through `flutter_svg` rather than
/// redrawn as `CustomPainter`s or swapped for Material icons. The canvas's
/// claim is that the set reads clean *because* every glyph obeys the same
/// three rules — one optical box, one stroke weight, one corner language — so
/// the fidelity that matters is between the glyphs, not in any one of them.
/// Transcribing the paths keeps that property by construction.
abstract final class _MenuGlyphs {
  static const back = '<path d="M14 6l-6 6 6 6M8.5 12H20"/>';
  static const chevron = '<path d="M9.5 5.5l6.5 6.5-6.5 6.5"/>';

  /// A versus pair, not a bat and stumps: two chevrons facing off across a
  /// bat's line.
  static const matches = '<path d="M9.2 7.4L5.6 12l3.6 4.6M14.8 7.4L18.4 12'
      'l-3.6 4.6M13.2 3.8L10.8 20.2"/>';

  /// Two people, one behind the other. The shield the panel used to carry
  /// moved off Teams — a squad is people, not a badge.
  static const teams = '<circle cx="9.2" cy="8.6" r="3.4"/>'
      '<path d="M3.4 19.4c0-3.2 2.6-5.2 5.8-5.2s5.8 2 5.8 5.2"/>'
      '<path d="M16 6.2a3.2 3.2 0 0 1 0 6M18.2 19.4c0-2.4-.9-4.1-2.6-4.9"/>';

  /// A flag on a pole, replacing the old crosshair.
  static const challenges = '<path d="M6 21V3.6M6 4.4h12l-2.8 4.4L18 13.2H6"/>';

  static const tournaments = '<path d="M7 3.8h10v5.4a5 5 0 0 1-10 0z"/>'
      '<path d="M12 14.6v4M7.8 20.6h8.4"/>';

  static const invites =
      '<rect x="3.2" y="5.6" width="17.6" height="12.8" rx="1.6"/>'
      '<path d="M3.6 6.4L12 13l8.4-6.6"/>';

  static const notifications =
      '<path d="M6.2 10.4a5.8 5.8 0 0 1 11.6 0v4.2l1.8 2.6H4.4l1.8-2.6z"/>'
      '<path d="M10.2 20.2h3.6"/>';

  static const saved = '<path d="M6.2 3.6h11.6v17l-5.8-4.4-5.8 4.4z"/>';

  static const settings = '<path d="M21.1 9.7L21.1 14.3L18.8 14.5L17.5 16.6'
      'L18.5 18.8L14.6 21L13.3 19.1L10.8 19.1L9.4 21L5.5 18.8L6.5 16.6L5.2 14.5'
      'L2.9 14.3L2.9 9.7L5.2 9.5L6.5 7.4L5.5 5.2L9.4 3L10.8 4.9L13.3 4.9L14.6 3'
      'L18.5 5.2L17.5 7.4L18.8 9.5Z"/><circle cx="12" cy="12" r="3"/>';

  static const help = '<circle cx="12" cy="12" r="8.6"/>'
      '<path d="M9.8 9.4a2.3 2.3 0 1 1 3.3 2.1c-.7.4-1.1 1-1.1 1.8'
      'M12 16.6h.01"/>';

  static const signOut =
      '<path d="M14.4 4.2H7.6A2.4 2.4 0 0 0 5.2 6.6v10.8a2.4 2.4 0 0 0 2.4 '
      '2.4h6.8M16.4 8.4L20 12l-3.6 3.6M11.4 12H20"/>';

  /// Wraps a body in the family's shared frame. Every glyph is drawn on the
  /// same 24 box at 1.9, outline only — that sameness is the whole point, so
  /// it lives here rather than at each call site.
  static Widget svg(
    String body, {
    required double size,
    required Color color,
  }) {
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
      'viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="1.9" '
      'stroke-linecap="round" stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
    );
  }
}
