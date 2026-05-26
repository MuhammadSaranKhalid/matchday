import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../state/my_teams_view.dart';

/// Multi-variant role pill (OWNER / CAPTAIN / VC / WK / MANAGER / FOLLOWING
/// / PENDING / ARCHIVED / SUSPENDED / DRAFT / SCORER). PLAYER renders no
/// chip — players are the default in a "You play" section.
class RolePill extends StatelessWidget {
  const RolePill({super.key, required this.role});
  final MyTeamsRole role;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(role);
    if (spec == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(4),
        border: spec.border == null
            ? null
            : Border.all(color: spec.border!, width: 1),
      ),
      child: Text(
        spec.label,
        style: CkType.mono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: spec.fg,
        ),
      ),
    );
  }

  /// True when [role] renders a visible pill. PLAYER returns false.
  static bool hasSpec(MyTeamsRole role) => _specFor(role) != null;

  static _RoleSpec? _specFor(MyTeamsRole role) {
    switch (role) {
      case MyTeamsRole.owner:
        return const _RoleSpec(bg: CkColors.ink, fg: CkColors.paper, label: 'OWNER');
      case MyTeamsRole.captain:
        return const _RoleSpec(
            bg: CkColors.paper, fg: CkColors.ink, label: 'CAPTAIN', border: CkColors.line);
      case MyTeamsRole.vc:
        return const _RoleSpec(bg: CkColors.cream, fg: CkInk.amber, label: 'VICE-CAPTAIN');
      case MyTeamsRole.wk:
        return const _RoleSpec(bg: CkColors.cream, fg: CkInk.amber, label: 'WK');
      case MyTeamsRole.manager:
        return const _RoleSpec(
            bg: CkColors.paper2, fg: CkColors.ink2, label: 'MANAGER', border: CkColors.hairline);
      case MyTeamsRole.player:
        return null;
      case MyTeamsRole.following:
        return const _RoleSpec(
            bg: CkColors.paper2, fg: CkColors.muted, label: 'FOLLOWING', border: CkColors.hairline);
      case MyTeamsRole.pending:
        return const _RoleSpec(bg: CkColors.cream, fg: CkInk.amber, label: 'AWAITING APPROVAL');
      case MyTeamsRole.archived:
        return const _RoleSpec(
            bg: CkColors.paper2, fg: CkColors.muted, label: 'ARCHIVED', border: CkColors.hairline);
      case MyTeamsRole.suspended:
        return const _RoleSpec(bg: CkColors.redSoft, fg: CkInk.red, label: 'SUSPENDED');
      case MyTeamsRole.draft:
        return const _RoleSpec(
            bg: CkColors.cream, fg: CkInk.amber, label: 'DRAFT · NOT PUBLISHED');
      case MyTeamsRole.scorer:
        return const _RoleSpec(
            bg: CkColors.paper2, fg: CkColors.ink2, label: 'SCORER', border: CkColors.hairline);
    }
  }
}

class _RoleSpec {
  const _RoleSpec({
    required this.bg,
    required this.fg,
    required this.label,
    this.border,
  });
  final Color bg;
  final Color fg;
  final String label;
  final Color? border;
}

/// Small green checkmark used next to verified team names.
class VerifiedTick extends StatelessWidget {
  const VerifiedTick({super.key, this.size = 11});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CheckPainter()),
    );
  }
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CkColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.55)
      ..lineTo(size.width * 0.42, size.height * 0.78)
      ..lineTo(size.width * 0.86, size.height * 0.28);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Red pill with a pulsing white dot — "LIVE" by default. Used inline in
/// team-row meta lines and on the inverted Today card.
class LivePill extends StatefulWidget {
  const LivePill({super.key, this.label = 'LIVE'});
  final String label;

  @override
  State<LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 2, 6, 2),
        decoration: BoxDecoration(
          color: CkColors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_c),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: CkColors.paper,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: CkType.mono(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.paper,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
