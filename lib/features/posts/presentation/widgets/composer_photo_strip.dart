import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';
import '../controllers/composer_controller.dart';

class ComposerPhotoStrip extends StatelessWidget {
  const ComposerPhotoStrip({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onRemove,
  });

  final ComposerState state;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: state.photos.length + (state.canAddPhoto ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i < state.photos.length) {
            return _Thumb(
              file: state.photos[i].file,
              onRemove: () => onRemove(i),
              cover: i == 0,
            );
          }
          // Trailing "add more" tile (appears only alongside existing photos,
          // hidden at the 4-photo cap).
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CkColors.line),
              ),
              child: const Icon(Icons.add, color: CkColors.muted),
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.file,
    required this.onRemove,
    this.cover = false,
  });
  final File file;
  final VoidCallback onRemove;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(file, width: 84, height: 84, fit: BoxFit.cover),
          ),
          if (cover)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('COVER',
                    style: CkType.mono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: Colors.white)),
              ),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
