import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../controllers/team_create_controller.dart';
import '../../state/team_create_state.dart';
import 'tc_atoms.dart';

/// Step 04 — Crest: upload OR three generated styles.
class TcStepCrest extends StatelessWidget {
  const TcStepCrest({super.key, required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  bool get _hasLogo => state.crestKind == CrestKind.upload &&
      (state.logoUrl?.isNotEmpty ?? false);

  Future<void> _pickLogo(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    final size = await File(file.path).length();
    if (size > 2 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max 2 MB. Crop or compress and try again.')),
        );
      }
      return;
    }
    controller.setLogo(url: file.path, name: file.name, size: size);
  }

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
              'Set a crest.',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              "Upload your club's logo if you have one, or pick a generated "
              'style.',
              style: CkType.body(
                  fontSize: 13, color: CkColors.muted, height: 1.4),
            ),
          ),

          // Big preview centred.
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: TcCrestPreview(
                crestKind: state.crestKind,
                primaryHex: state.primaryColor,
                monogram: state.monogram,
                logoPath: state.logoUrl,
              ),
            ),
          ),

          const TcLabel('Your logo'),
          _hasLogo
              ? _UploadedRow(
                  state: state,
                  onReplace: () => _pickLogo(context),
                  onRemove: controller.removeLogo,
                )
              : _UploadPrompt(onTap: () => _pickLogo(context)),
          const SizedBox(height: 18),
          _Divider(hasLogo: _hasLogo),
          const SizedBox(height: 12),
          _GeneratedStyles(state: state, controller: controller, dim: _hasLogo),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _hasLogo
                  ? "Your uploaded logo will appear on scorecards, team pages "
                      "and the bracket. We'll auto-tint it to your team colors "
                      'where contrast is needed.'
                  : 'Crest auto-syncs with your team colors. You can replace '
                      'it with an upload anytime.',
              style:
                  CkType.body(fontSize: 11, color: CkColors.ink2, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPrompt extends StatelessWidget {
  const _UploadPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: CkColors.hairline),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.file_upload_outlined,
                    size: 18, color: CkColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload a logo',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'PNG, JPG or SVG · max 2 MB · transparent background '
                      'recommended',
                      style: CkType.body(
                          fontSize: 11, color: CkColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadedRow extends StatelessWidget {
  const _UploadedRow({
    required this.state,
    required this.onReplace,
    required this.onRemove,
  });
  final TeamCreateState state;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CkColors.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(4),
            child: state.logoUrl == null
                ? const SizedBox.shrink()
                : Image.file(File(state.logoUrl!), fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.logoName ?? 'team-logo.png',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: CkColors.greenSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'UPLOADED',
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08,
                          color: CkInk.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.logoSize == null ? '—' : '${(state.logoSize! / 1024).round()} KB'} '
                  '· auto-cropped square',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GhostBtn(label: 'Replace', onTap: onReplace),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: CkColors.hairline),
              ),
              child: const Icon(Icons.close, size: 13, color: CkColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.hasLogo});
  final bool hasLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: CkColors.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            hasLogo ? 'OR GENERATE ONE' : 'OR USE A GENERATED CREST',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: CkColors.hairline)),
      ],
    );
  }
}

class _GeneratedStyles extends StatelessWidget {
  const _GeneratedStyles({
    required this.state,
    required this.controller,
    required this.dim,
  });
  final TeamCreateState state;
  final TeamCreateController controller;
  final bool dim;

  static const _kinds = [
    (CrestKind.monogram, 'Monogram'),
    (CrestKind.initials, 'Initials'),
    (CrestKind.shield, 'Shield'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final entry in _kinds)
          TcSelectTile(
            title: entry.$2,
            selected: !dim && state.crestKind == entry.$1,
            dim: dim,
            onTap: () => controller.setCrestKind(entry.$1),
            leading: TcCrestPreview(
              crestKind: entry.$1,
              primaryHex: state.primaryColor,
              monogram: state.monogram,
              size: 26,
              radius: 7,
            ),
          ),
      ],
    );
  }
}

/// Dashed-border rectangle for the upload prompt.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: const BoxDecoration(color: CkColors.paper2),
          child: child,
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CkColors.soft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
