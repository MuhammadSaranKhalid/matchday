import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../controllers/team_create_controller.dart';
import '../../state/team_create_state.dart';
import 'tc_atoms.dart';

/// Step 03 — Home: city + area + ground + stripe-pattern map placeholder.
class TcStepHome extends StatelessWidget {
  const TcStepHome({super.key, required this.state, required this.controller});
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
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              'Where do you play?',
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
              'Helps players nearby find you and disambiguates teams with '
              'similar names.',
              style: CkType.body(
                  fontSize: 13, color: CkColors.muted, height: 1.4),
            ),
          ),
          const TcLabel('City'),
          TcInput(value: state.city, onChanged: controller.setCity),
          const SizedBox(height: 14),
          const TcLabel('Area / mohalla / locality'),
          TcInput(
            value: state.area,
            onChanged: controller.setArea,
            placeholder: 'Model Town',
          ),
          const SizedBox(height: 14),
          const TcLabel('Home ground (optional)'),
          TcInput(
            value: state.homeGround,
            onChanged: controller.setHomeGround,
            placeholder: 'Gaddafi B Ground',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 22),
            child: Text(
              'Free text — no need to be a registered venue.',
              style: CkType.body(fontSize: 11, color: CkColors.muted),
            ),
          ),
          _MapPlaceholder(state: state),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        state.area.trim().isNotEmpty || state.city.trim().isNotEmpty;
    final lineCity = hasLocation
        ? [state.area.trim(), state.city.trim()]
            .where((s) => s.isNotEmpty)
            .join(', ')
        : '—';
    return Container(
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _StripePainter(),
            size: const Size(double.infinity, double.infinity),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, size: 22, color: CkColors.red),
                const SizedBox(height: 6),
                Text(
                  lineCity,
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MAP PREVIEW',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = CkColors.paper2;
    const stripe = 8.0;
    const period = 16.0;
    // Draw 135deg stripes.
    final diag = size.width + size.height;
    for (var d = -size.height; d < diag; d += period) {
      final path = Path()
        ..moveTo(d, 0)
        ..lineTo(d + size.height, size.height)
        ..lineTo(d + size.height - stripe, size.height)
        ..lineTo(d - stripe, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
