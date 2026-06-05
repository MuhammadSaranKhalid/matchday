// Pavilion v2 — faithful Flutter port of the matchday v2 design prototype's
// `CkPavilion` (design_bundle/matchday/project/app/screens/Pavilion.jsx,
// framed in v2-IA.jsx as `V2PavilionPrev`).
//
// PRESENTATION-ONLY · MOCK DATA. No Riverpod, no backend, no repositories.
// Plain Stateful/Stateless widgets; nearly every button is inert (the few that
// drive navigation flip the local `view`, and the FAB toggles `createOpen`).
//
// v2 stripped Pavilion heavily: PvHome shows ONLY two zones — "Calendar ·
// upcoming" and "Yours". The Status / Library / Settings zones were removed.
// Create is a FAB → bottom sheet (Match / Team / Tournament / Post).
//
// Tokens / atoms come from circk_theme.dart + v2/v2_kit.dart.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_kit.dart';
import 'package:novex_clean_arch/features/posts/presentation/screens/composer_screen.dart';
import '../widgets/pavilion_library_screens.dart';
import '../widgets/pavilion_settings_screens.dart';
import '../widgets/pavilion_status_screens.dart';
import '../widgets/pavilion_yours_screens.dart';

// ── One-off colours used elsewhere in pavilion ─────────────────────────────
const _kBackdrop = Color(0x6B14120E); // rgba(20,18,14,0.42) Create backdrop
const _kGrabber = Color(0x2E14120E); // rgba(20,18,14,0.18) sheet grabber

class PavilionV2Screen extends StatefulWidget {
  const PavilionV2Screen({super.key, this.onBell});

  /// Invoked when the header bell is tapped (the app shell routes to
  /// Notifications). Inert if null.
  final VoidCallback? onBell;

  @override
  State<PavilionV2Screen> createState() => _PavilionV2ScreenState();
}

class _PavilionV2ScreenState extends State<PavilionV2Screen> {
  // 'home' | 'my-tournaments' | 'calendar' | various status/library/settings views.
  // 'my-matches' and 'my-teams' are now standalone routes (/pavilion/my-matches
  // and /teams) pushed over the shell — not in-screen sub-views.
  String _view = 'home';
  bool _createOpen = false;

  void _go(String v) => setState(() => _view = v);
  void _back() => setState(() => _view = 'home');

  @override
  Widget build(BuildContext context) {
    final isHome = _view == 'home';

    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                if (isHome)
                  _PvTitleStrip(onBell: widget.onBell)
                else
                  _PvHeader(title: _headerTitle, onBack: _back),
                Expanded(child: _buildBody()),
              ],
            ),

            // FAB — home only, hidden while the sheet is open.
            if (isHome && !_createOpen)
              Positioned(
                right: 18,
                bottom: 24,
                child: _Fab(onTap: () => setState(() => _createOpen = true)),
              ),

            // Create bottom sheet overlay.
            if (_createOpen)
              _CreateSheet(onClose: () => setState(() => _createOpen = false)),
          ],
        ),
      ),
    );
  }

  String get _headerTitle => switch (_view) {
        'my-tournaments' => 'My tournaments',
        'calendar' => 'Calendar',
        'status-invites' => 'Invites',
        'status-claims' => 'Claim requests',
        'status-drafts' => 'Drafts',
        'status-today' => "Today's fixture",
        'captain-duties' => 'Captain duties',
        'organizer-duties' => 'Organizer duties',
        'my-stats' => 'My stats',
        'achievements' => 'Achievements',
        'wallet' => 'Wallet',
        'library-saved' => 'Saved',
        'library-followed' => 'Followed',
        'library-scorer' => 'Scorer history',
        'settings-notifications' => 'Notifications',
        'settings-discoverability' => 'Discoverability',
        'settings-privacy' => 'Privacy & blocking',
        _ => 'Pavilion',
      };

  Widget _buildBody() {
    return switch (_view) {
      'my-tournaments' => const _PvMyTournaments(),
      'calendar' => const _PvCalendar(),
      'status-invites' => const PvStatusInvitesBody(),
      'status-claims' => const PvStatusClaimsBody(),
      'status-drafts' => const PvStatusDraftsBody(),
      'status-today' => const PvStatusTodayBody(),
      'captain-duties' => const PvCaptainDutiesBody(),
      'organizer-duties' => const PvOrganizerDutiesBody(),
      'my-stats' => const PvMyStatsBody(),
      'achievements' => const PvAchievementsBody(),
      'wallet' => const PvWalletBody(),
      'library-saved' => const PvLibrarySavedBody(),
      'library-followed' => const PvLibraryFollowedBody(),
      'library-scorer' => const PvLibraryScorerBody(),
      'settings-notifications' => const PvSettingsNotificationsBody(),
      'settings-discoverability' => const PvSettingsDiscoverabilityBody(),
      'settings-privacy' => const PvSettingsPrivacyBody(),
      _ => _PvHome(go: _go),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Atoms
// ═══════════════════════════════════════════════════════════════════════════

/// monoLabel: JetBrains Mono 10 / 700 / 0.10em uppercase, default muted.
TextStyle _monoLabel({Color color = CkColors.muted}) => CkType.mono(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.10,
      color: color,
    );

/// display(size): Inter Tight 700 / -0.025em / line-height 1.05.
TextStyle _display(double size, {Color color = CkColors.ink}) => CkType.display(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.025,
      height: 1.05,
      color: color,
    );

/// Pavilion's own home title strip (NOT the shared V2Header).
/// "Pavilion" left + two 36×36 circle icon buttons (search, bell w/ red dot).
class _PvTitleStrip extends StatelessWidget {
  const _PvTitleStrip({this.onBell});
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pavilion',
            style: CkType.display(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.025,
            ),
          ),
          Row(
            children: [
              const _CircleIconButton(icon: V2Icons.search),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: V2Icons.bell,
                showDot: true,
                onTap: onBell,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 36×36 round paper2 button with a hairline border and a stroked icon.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.showDot = false,
    this.onTap,
  });

  final String icon;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              child: V2Svg(icon, size: 16, color: CkColors.ink, strokeWidth: 1.8),
            ),
            if (showDot)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: CkColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.paper, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// PvHeader — back chevron + title.
/// padding 12 18; bottom hairline.
class _PvHeader extends StatelessWidget {
  const _PvHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: V2Svg(
                    V2Icons.chevronLeft,
                    size: 22,
                    color: CkColors.ink,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          Expanded(child: Text(title, style: _display(22))),
        ],
      ),
    );
  }
}

/// PvSectionH — mono label and optional "ACTION →".
class _PvSectionH extends StatelessWidget {
  const _PvSectionH(
    this.label, {
    this.action,
    this.onAction,
    this.accent,
  });

  final String label;
  final String? action;
  final VoidCallback? onAction;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(),
              style: _monoLabel(color: accent ?? CkColors.muted)),
          if (action != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Text(
                '${action!.toUpperCase()} →',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// PvCard — paper card, hairline border, optional 3px coloured left accent.
class _PvCard extends StatelessWidget {
  const _PvCard({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    // Rounded corners come from the ClipRRect, not the BoxDecoration: a
    // non-uniform Border (the 3px coloured left accent) cannot be combined
    // with a borderRadius on the decoration itself.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CkColors.paper,
          border: Border(
            top: const BorderSide(color: CkColors.hairline),
            right: const BorderSide(color: CkColors.hairline),
            bottom: const BorderSide(color: CkColors.hairline),
            left: BorderSide(
              color: accent ?? CkColors.hairline,
              width: accent != null ? 3 : 1,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// PvRow — full-width button row: 36×36 glyph tile + title/sub + meta + chevron.
class _PvRow extends StatelessWidget {
  const _PvRow({
    required this.glyph,
    required this.title,
    this.sub,
    this.meta,
    this.onTap,
  });

  final String glyph;
  final String title;
  final String? sub;
  final String? meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                glyph,
                style: const TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub!,
                        style: CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                    ),
                ],
              ),
            ),
            if (meta != null) ...[
              const SizedBox(width: 8),
              Text(
                meta!,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: CkColors.muted,
                ),
              ),
            ],
            const SizedBox(width: 8),
            const V2Svg(
              V2Icons.chevronRight,
              size: 14,
              color: CkColors.muted,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

enum _PvPillKind { def, red, amber, green, soft, ink }

/// PvPill — mono uppercase chip in one of six tones.
class _PvPill extends StatelessWidget {
  const _PvPill(this.label, {this.kind = _PvPillKind.def});

  final String label;
  final _PvPillKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      _PvPillKind.def => (CkColors.paper2, CkColors.ink2, CkColors.hairline),
      _PvPillKind.red => (CkColors.red, Colors.white, null),
      _PvPillKind.amber => (CkColors.amber, CkInk.amber, null),
      _PvPillKind.green => (CkColors.green, Colors.white, null),
      _PvPillKind.soft => (CkColors.cream, CkInk.amber, null),
      _PvPillKind.ink => (CkColors.ink, CkColors.paper, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: fg,
        ),
      ),
    );
  }
}

/// PvSwitch — 38×22 toggle. Kept faithful to the JSX though Pavilion v2's home
/// no longer uses it (lives in the removed Settings zone); ported per the task.
// ignore: unused_element
class _PvSwitch extends StatelessWidget {
  // ignore: unused_element_parameter
  const _PvSwitch({required this.on, this.onChange});

  final bool on;
  final ValueChanged<bool>? onChange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange == null ? null : () => onChange!(!on),
      child: Container(
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(2),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          // off track — oklch(0.85 0.005 85)
          color: on ? CkColors.ink : const Color(0xFFD6D4CF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: CkColors.paper,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000), // rgba(0,0,0,0.15)
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME
// ═══════════════════════════════════════════════════════════════════════════

class _PvHome extends StatelessWidget {
  const _PvHome({required this.go});
  final void Function(String) go;

  static const _fixtures = [
    (d: 'TUE', n: 14, t: 'Lions vs Eagles', s: '18:30 · QF · Model Town', live: true),
    (d: 'SAT', n: 18, t: 'Lions vs DHA', s: '15:00 · Group · Gulberg', live: false),
    (d: 'SUN', n: 19, t: 'Practice match', s: '07:00 · Home ground', live: false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _PvSectionH(
          'Calendar · upcoming',
          action: 'See all',
          onAction: () => go('calendar'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              for (var i = 0; i < _fixtures.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _FixtureButton(f: _fixtures[i], onTap: () => go('calendar')),
              ],
            ],
          ),
        ),
        const _PvSectionH('Yours'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              _PvRow(
                glyph: '◉',
                title: 'My matches',
                sub: '3 confirmed · 142 past',
                meta: '3',
                onTap: () => context.go('/pavilion/my-matches'),
              ),
              const SizedBox(height: 6),
              _PvRow(
                glyph: '⚑',
                title: 'My teams',
                sub: '3 teams · 1 captained',
                meta: '3',
                onTap: () => context.push('/teams'),
              ),
              const SizedBox(height: 6),
              _PvRow(
                glyph: '♛',
                title: 'My tournaments',
                sub: '2 organizing · 1 playing',
                meta: '3',
                onTap: () => go('my-tournaments'),
              ),
            ],
          ),
        ),

        // ── Needs you (status drill-downs) ──
        const _PvSectionH('Needs you'),
        _PvRowGroup(go: go, rows: const [
          (glyph: '✉', title: 'Invites', sub: '2 team · 1 tournament', view: 'status-invites'),
          (glyph: '⊕', title: 'Claim requests', sub: '1 pending', view: 'status-claims'),
          (glyph: '✎', title: 'Drafts', sub: '3 unfinished', view: 'status-drafts'),
          (glyph: '◉', title: "Today's fixture", sub: 'Lions vs Eagles · 18:30', view: 'status-today'),
        ]),

        // ── Duties ──
        const _PvSectionH('Captain · organizer'),
        _PvRowGroup(go: go, rows: const [
          (glyph: '✦', title: 'Captain duties', sub: 'Lahore Lions', view: 'captain-duties'),
          (glyph: '♛', title: 'Organizer duties', sub: "Spring Cup '26", view: 'organizer-duties'),
        ]),

        // ── Stats & rewards ──
        const _PvSectionH('Stats & rewards'),
        _PvRowGroup(go: go, rows: const [
          (glyph: '📊', title: 'My stats', sub: 'Career · form · wagon', view: 'my-stats'),
          (glyph: '🏆', title: 'Achievements', sub: '9 unlocked', view: 'achievements'),
          (glyph: '₨', title: 'Wallet', sub: '₨ 12,500 available', view: 'wallet'),
        ]),

        // ── Library ──
        const _PvSectionH('Library'),
        _PvRowGroup(go: go, rows: const [
          (glyph: '🔖', title: 'Saved', sub: 'Posts · matches · tours', view: 'library-saved'),
          (glyph: '♡', title: 'Followed', sub: 'Players · teams · tournaments', view: 'library-followed'),
          (glyph: '✓', title: 'Scorer history', sub: '38 matches scored', view: 'library-scorer'),
        ]),

        // ── Settings ──
        const _PvSectionH('Settings'),
        _PvRowGroup(go: go, rows: const [
          (glyph: '🔔', title: 'Notifications', sub: 'Match · social · roles', view: 'settings-notifications'),
          (glyph: '🔍', title: 'Discoverability', sub: 'Search · suggestions', view: 'settings-discoverability'),
          (glyph: '🔒', title: 'Privacy & blocking', sub: 'Muted · blocked · reports', view: 'settings-privacy'),
        ]),
      ],
    );
  }
}

/// A padded column of PvRows for a Home zone (each row navigates via [go]).
class _PvRowGroup extends StatelessWidget {
  const _PvRowGroup({required this.rows, required this.go});
  final List<({String glyph, String title, String sub, String view})> rows;
  final void Function(String) go;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _PvRow(
              glyph: rows[i].glyph,
              title: rows[i].title,
              sub: rows[i].sub,
              onTap: () => go(rows[i].view),
            ),
          ],
        ],
      ),
    );
  }
}

class _FixtureButton extends StatelessWidget {
  const _FixtureButton({required this.f, this.onTap});

  final ({String d, int n, String t, String s, bool live}) f;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f.d,
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: CkColors.muted,
                      )),
                  Text(
                    '${f.n}',
                    style: CkType.display(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 28, color: CkColors.hairline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f.t,
                      style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(f.s,
                        style: CkType.body(fontSize: 11, color: CkColors.muted)),
                  ),
                ],
              ),
            ),
            if (f.live) ...[
              const SizedBox(width: 8),
              const _PvPill('Today', kind: _PvPillKind.red),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MY TOURNAMENTS
// ═══════════════════════════════════════════════════════════════════════════

class _PvMyTournaments extends StatelessWidget {
  const _PvMyTournaments();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: const [
        _PvSectionH('Organizing · 2', accent: CkColors.green),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              _TournamentCard(
                name: "Spring Cup '26",
                sub: '8 teams · 18 fixtures · QF stage',
                accent: CkColors.green,
                live: true,
              ),
              SizedBox(height: 8),
              _TournamentCard(
                name: 'Friday League',
                sub: '6 teams · weekly · Friday nights',
                accent: CkColors.green,
                live: false,
              ),
            ],
          ),
        ),
        _PvSectionH('Playing · 1'),
        Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: _TournamentCard(
            name: 'Mohalla T10 Winter',
            sub: 'With Old Boys · group stage · 2W 1L',
            accent: null,
            live: false,
          ),
        ),
      ],
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.name,
    required this.sub,
    required this.accent,
    required this.live,
  });

  final String name;
  final String sub;
  final Color? accent;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return _PvCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(name,
                    style: CkType.display(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (live) ...[
                const SizedBox(width: 8),
                const _PvPill('Live', kind: _PvPillKind.red),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(sub,
                style: CkType.body(fontSize: 12, color: CkColors.muted)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CALENDAR (populated)
// ═══════════════════════════════════════════════════════════════════════════

class _PvCalendar extends StatelessWidget {
  const _PvCalendar();

  // d -> dot colour
  static const Map<int, Color> _eventDays = {
    14: CkColors.red,
    18: CkColors.green,
    19: CkColors.amber,
    22: CkColors.green,
    28: CkColors.red,
  };

  static const _agenda = [
    (d: 'TUE 14', t: 'Lions vs Eagles', s: '18:30 · QF · Model Town', k: CkColors.red),
    (d: 'SAT 18', t: 'Lions vs DHA United', s: '15:00 · Group · Gulberg', k: CkColors.green),
    (d: 'SUN 19', t: 'Practice match', s: '07:00 · Home ground', k: CkColors.amber),
    (d: 'SUN 22', t: 'Lions vs Mohalla Kings', s: '16:00 · Group · DHA', k: CkColors.green),
    (d: 'SAT 28', t: 'Spring Cup · FINAL', s: '18:00 · Model Town · Pitch 1', k: CkColors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('March 2026', style: _display(18)),
                  const Row(
                    children: [
                      _MonthArrow(glyph: '‹'),
                      SizedBox(width: 6),
                      _MonthArrow(glyph: '›'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _MonthGrid(eventDays: _eventDays),
            ],
          ),
        ),
        const _PvSectionH('Agenda · upcoming'),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
            children: [
              for (var i = 0; i < _agenda.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _AgendaCard(e: _agenda[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.glyph});
  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Text(glyph,
          style: CkType.body(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CkColors.ink,
          )),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.eventDays});
  final Map<int, Color> eventDays;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      children: [
        Row(
          children: [
            for (final l in labels)
              Expanded(
                child: Center(
                  child: Text(l,
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.10,
                        color: CkColors.muted,
                      )),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 30,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, i) {
            final d = i + 1;
            final selected = d == 14;
            final dot = selected ? null : eventDays[d];
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? CkColors.ink : CkColors.paper,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: selected ? CkColors.ink : CkColors.hairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$d',
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? CkColors.paper : CkColors.ink,
                      )),
                  if (dot != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration:
                            BoxDecoration(color: dot, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.e});
  final ({String d, String t, String s, Color k}) e;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border(
          top: const BorderSide(color: CkColors.hairline),
          right: const BorderSide(color: CkColors.hairline),
          bottom: const BorderSide(color: CkColors.hairline),
          left: BorderSide(color: e.k, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Text(e.d.toUpperCase(),
                style: _monoLabel(color: CkColors.ink)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.t,
                    style:
                        CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(e.s,
                      style: CkType.body(fontSize: 11, color: CkColors.muted)),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FAB + Create bottom sheet
// ═══════════════════════════════════════════════════════════════════════════

class _Fab extends StatelessWidget {
  const _Fab({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: CkColors.ink),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000), // 0 8px 24px -6px rgba(0,0,0,0.35)
              blurRadius: 24,
              spreadRadius: -6,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x2E000000), // 0 2px 6px rgba(0,0,0,0.18)
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const V2Svg(
          V2Icons.plus,
          size: 22,
          color: CkColors.paper,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet({required this.onClose});
  final VoidCallback onClose;

  static const _options = [
    (
      t: 'Match',
      s: 'Friendly · league · cup match — live or post-match scoring',
      icon: '◉',
      accent: CkColors.red
    ),
    (
      t: 'Team',
      s: 'Club, village or one-off side · 5-step setup',
      icon: '⚑',
      accent: CkColors.ink
    ),
    (
      t: 'Tournament',
      s: 'Knockout · round-robin · league · 8-step setup',
      icon: '♛',
      accent: CkColors.amber
    ),
    (
      t: 'Post',
      s: 'Text or photo · announcement · recruitment',
      icon: '✎',
      accent: CkColors.green
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Dim, tappable backdrop.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: const ColoredBox(color: _kBackdrop),
            ),
          ),
          // Bottom sheet.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: CkColors.hairline)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x2E000000), // 0 -12px 40px -8px rgba(0,0,0,0.18)
                    blurRadius: 40,
                    spreadRadius: -8,
                    offset: Offset(0, -12),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grabber.
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _kGrabber,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    // Header.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Create',
                              style: CkType.display(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.025,
                              )),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onClose,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text('CLOSE',
                                  style: CkType.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.08,
                                    color: CkColors.muted,
                                  )),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Options.
                    for (var i = 0; i < _options.length; i++)
                      _CreateOption(
                        o: _options[i],
                        topBorder: i == 0,
                        onTap: () {
                          onClose();
                          switch (_options[i].t) {
                            case 'Post':
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ComposerScreen(),
                                ),
                              );
                            case 'Team':
                              context.push('/teams/create');
                          }
                        },
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

class _CreateOption extends StatelessWidget {
  const _CreateOption({required this.o, required this.topBorder, this.onTap});

  final ({String t, String s, String icon, Color accent}) o;
  final bool topBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: topBorder
                ? const BorderSide(color: CkColors.hairline)
                : BorderSide.none,
            bottom: const BorderSide(color: CkColors.hairline),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: o.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                o.icon,
                style: const TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(o.t,
                      style: CkType.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.005,
                      )),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(o.s,
                        style: CkType.body(
                          fontSize: 12,
                          height: 1.4,
                          color: CkColors.muted,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const V2Svg(
              V2Icons.chevronRight,
              size: 16,
              color: CkColors.muted,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
