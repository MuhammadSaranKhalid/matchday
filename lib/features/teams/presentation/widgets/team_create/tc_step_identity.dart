import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/team.dart';
import '../../controllers/team_create_controller.dart';
import '../../state/team_create_state.dart';
import '../team_avatar.dart';
import 'tc_atoms.dart';

/// Step 02 — Identity: live preview + primary + secondary swatches + monogram.
class TcStepIdentity extends StatelessWidget {
  const TcStepIdentity(
      {super.key, required this.state, required this.controller});
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
              'Your colors.',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          _LivePreview(state: state),
          const SizedBox(height: 22),
          const TcLabel('Primary'),
          TcColorGrid(
            palette: kTeamCreatePalette,
            value: state.primaryColor,
            onChanged: controller.setPrimaryColor,
          ),
          const SizedBox(height: 18),
          const TcLabel('Secondary / accent'),
          TcColorGrid(
            palette: kTeamCreatePalette,
            value: state.secondaryColor,
            onChanged: controller.setSecondaryColor,
          ),
          const SizedBox(height: 14),
          const TcLabel('Monogram'),
          TcInput(
            value: state.monogram,
            onChanged: controller.setMonogram,
            maxLength: 3,
            textAlign: TextAlign.center,
            maxWidth: 120,
            textStyle: CkType.display(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColor(state.primaryColor, fallback: CkColors.ink);
    final secondary =
        parseHexColor(state.secondaryColor, fallback: CkColors.paper);
    final fg = onColor(primary);

    return Container(
      height: 168,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Faint pitch motif bottom-right.
          Positioned(
            right: -40,
            bottom: -44,
            child: Opacity(
              opacity: 0.18,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _PitchMotif(stroke: fg),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      state.monogram,
                      style: CkType.display(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                        color: onColor(secondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.02,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${state.type.label.toUpperCase()}'
                          '${state.city.trim().isEmpty ? '' : ' · ${state.city.toUpperCase()}'}',
                          style: CkType.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.06,
                            color: fg.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.tagline.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      '“${state.tagline}”',
                      style: CkType.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.01,
                        height: 1.3,
                        color: fg.withValues(alpha: 0.85),
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                'PREVIEW · KIT',
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PitchMotif extends CustomPainter {
  _PitchMotif({required this.stroke});
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 190, height: 120),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 110, height: 68),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: c, width: 32, height: 120),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

extension on TeamType {
  String get label {
    switch (this) {
      case TeamType.club:
        return 'Club';
      case TeamType.village:
        return 'Village';
      case TeamType.casual:
        return 'Casual';
      case TeamType.corporate:
        return 'Corporate';
      case TeamType.school:
        return 'School';
      case TeamType.university:
        return 'University';
    }
  }
}
