import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/util/surface_mode.dart';

TextStyle teamPageMono({
  double fontSize = 10,
  FontWeight fontWeight = FontWeight.w600,
  Color color = CkColors.muted,
}) =>
    CkType.mono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.08,
      color: color,
    );

class TeamPageIconButton extends StatelessWidget {
  const TeamPageIconButton({
    super.key,
    required this.icon,
    required this.mode,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final CkSurfaceMode mode;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final foreground = mode.isInk ? CkColors.ink : Colors.white;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mode.isInk
                ? CkColors.ink.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 20, color: foreground),
        ),
      ),
    );
  }
}

class TeamPageVerifiedTick extends StatelessWidget {
  const TeamPageVerifiedTick({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(
        Icons.verified_rounded,
        size: 15,
        color: color,
      );
}

class TeamPageLivePulse extends StatelessWidget {
  const TeamPageLivePulse({super.key, this.color = Colors.white});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class TeamPageEmptyTile extends StatelessWidget {
  const TeamPageEmptyTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.hairline),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 24, color: CkColors.muted),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CkType.display(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
        ],
      );
}

class TeamPageSectionHeader extends StatelessWidget {
  const TeamPageSectionHeader({
    super.key,
    required this.label,
    this.count,
  });
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 7),
        child: Text(
          count == null ? label.toUpperCase() : '${label.toUpperCase()} · $count',
          style: teamPageMono(),
        ),
      );
}

class TeamPageGroundPainter extends CustomPainter {
  const TeamPageGroundPainter({this.color = Colors.white});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 318, height: 228),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22,
    );
    final thin = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(Rect.fromCenter(center: c, width: 224, height: 158), thin);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 26, height: 96),
        const Radius.circular(3),
      ),
      thin,
    );
  }

  @override
  bool shouldRepaint(TeamPageGroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
