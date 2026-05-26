import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/team_create_state.dart';
import '../team_avatar.dart';
import 'tc_atoms.dart';

/// Step 06 — Team is live. Confetti hero crest, "{name} is live.", receipt,
/// next-steps stack, "Create another team" link.
class TcDone extends StatelessWidget {
  const TcDone({
    super.key,
    required this.state,
    this.onAddPlayers,
    this.onOpenTeam,
    this.onScheduleFriendly,
    this.onRegisterTournament,
    this.onCreateAnother,
  });

  final TeamCreateState state;
  final VoidCallback? onAddPlayers;
  final VoidCallback? onOpenTeam;
  final VoidCallback? onScheduleFriendly;
  final VoidCallback? onRegisterTournament;
  final VoidCallback? onCreateAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CkColors.paper,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar: "TEAM CREATED" eyebrow right-aligned.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    'TEAM CREATED',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.12,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _Confetti(
                            primaryHex: state.primaryColor),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF281E0F)
                                    .withValues(alpha: 0.18),
                                offset: const Offset(0, 12),
                                blurRadius: 36,
                              ),
                            ],
                          ),
                          child: TcCrestPreview(
                            crestKind: state.crestKind,
                            primaryHex: state.primaryColor,
                            monogram: state.monogram,
                            logoPath: state.logoUrl,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '${state.name.trim().isEmpty ? 'Your team' : state.name} is live.',
                    textAlign: TextAlign.center,
                    style: CkType.display(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.03,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You're the owner. Next: add your squad.",
                    textAlign: TextAlign.center,
                    style: CkType.body(
                        fontSize: 14,
                        color: CkColors.muted,
                        height: 1.4),
                  ),
                  if (state.tagline.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Text(
                        '“${state.tagline}”',
                        textAlign: TextAlign.center,
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.01,
                          height: 1.4,
                          color: CkColors.ink2,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _Receipt(state: state),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'WHAT NEXT',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.10,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
                  _NextRow(
                    primary: true,
                    label: 'Add players',
                    sub: 'Up to 25 · search, SMS, or unclaimed',
                    icon: Icons.person_add_alt_1,
                    onTap: onAddPlayers,
                  ),
                  const SizedBox(height: 8),
                  _NextRow(
                    label: 'Open team page',
                    sub: 'See your public profile',
                    icon: Icons.east,
                    onTap: onOpenTeam,
                  ),
                  const SizedBox(height: 8),
                  _NextRow(
                    label: 'Schedule a friendly',
                    sub: 'Challenge another team',
                    icon: Icons.calendar_month,
                    onTap: onScheduleFriendly,
                  ),
                  const SizedBox(height: 8),
                  _NextRow(
                    label: 'Register for a tournament',
                    sub: 'Find one near ${state.city.trim().isEmpty ? 'you' : state.city}',
                    icon: Icons.emoji_events,
                    onTap: onRegisterTournament,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onCreateAnother,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Center(
                  child: Text(
                    '← CREATE ANOTHER TEAM',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        children: [
          _ReceiptRow(
            iconColor: CkColors.green,
            label: 'Team profile created',
            detail: '${state.type.wire} · ${state.privacy.wire}',
            isFirst: true,
          ),
          _ReceiptRow(
            iconColor: CkColors.green,
            label: 'Located in',
            detail: [state.area, state.city]
                .where((p) => p.trim().isNotEmpty)
                .join(', '),
          ),
          _ReceiptRow(
            iconColor: CkColors.green,
            label: state.crestKind == CrestKind.upload
                ? 'Logo uploaded'
                : 'Crest set',
            detail: state.crestKind == CrestKind.upload
                ? (state.logoName ?? 'team-logo.png')
                : '${_kindLabel(state.crestKind)} style',
          ),
          const _ReceiptRow(
            iconColor: CkColors.muted,
            iconIsDot: true,
            label: 'Squad pending',
            detail: 'Add players from the team page',
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

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.iconColor,
    required this.label,
    required this.detail,
    this.iconIsDot = false,
    this.isFirst = false,
  });

  final Color iconColor;
  final String label;
  final String detail;
  final bool iconIsDot;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Icon(
              iconIsDot ? Icons.circle_outlined : Icons.check_rounded,
              size: iconIsDot ? 12 : 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CkType.body(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextRow extends StatelessWidget {
  const _NextRow({
    required this.label,
    required this.sub,
    required this.icon,
    this.primary = false,
    this.onTap,
  });

  final String label;
  final String sub;
  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary
                    ? CkColors.paper.withValues(alpha: 0.12)
                    : CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon,
                  size: 16, color: primary ? CkColors.paper : CkColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary ? CkColors.paper : CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: CkType.body(
                      fontSize: 11,
                      color: primary
                          ? CkColors.paper.withValues(alpha: 0.7)
                          : CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: primary
                  ? CkColors.paper.withValues(alpha: 0.7)
                  : CkColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti({required this.primaryHex});
  final String primaryHex;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColor(primaryHex, fallback: CkColors.ink);
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter:
            _ConfettiPainter(palette: [primary, CkColors.amber, CkColors.ink]),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.palette});
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <(double, double, double, int)>[
      (0.10, 0.18, 4, 0),
      (0.22, 0.62, 3, 1),
      (0.38, 0.08, 5, 2),
      (0.55, 0.78, 4, 0),
      (0.78, 0.34, 3, 1),
      (0.92, 0.12, 4, 2),
      (0.18, 0.84, 3, 0),
      (0.68, 0.58, 5, 1),
      (0.46, 0.92, 3, 2),
      (0.04, 0.48, 4, 1),
    ];
    for (final p in positions) {
      final paint = Paint()..color = palette[p.$4 % palette.length];
      canvas.drawCircle(
        Offset(size.width * p.$1, size.height * p.$2),
        p.$3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
