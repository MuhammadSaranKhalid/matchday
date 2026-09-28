import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({
    super.key,
    required this.canAddPhoto,
    required this.onAddPhoto,
    required this.charCount,
  });

  final bool canAddPhoto;
  final VoidCallback onAddPhoto;
  final int charCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: canAddPhoto ? onAddPhoto : null,
            child: Row(
              children: [
                V2Svg(V2Icons.camera,
                    size: 18,
                    color: canAddPhoto ? CkColors.ink2 : CkColors.soft),
                const SizedBox(width: 8),
                Text('PHOTO',
                    style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                        color: canAddPhoto ? CkColors.ink2 : CkColors.soft)),
              ],
            ),
          ),
          const Spacer(),
          if (charCount > 0) ...[
            Text(
              '$charCount / 2000',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.10,
                color: charCount >= 2000 ? CkColors.amber : CkColors.soft,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Text('PUBLIC ▾',
              style: CkType.mono(
                  fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.08)),
        ],
      ),
    );
  }
}
