// The post composer — type and/or attach up to 4 photos (each picked → cropped
// → resized). Online-only: submitting inserts the post + uploads media to
// Supabase, then prepends it to the feed.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../controllers/composer_controller.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _text.text.trim().isNotEmpty ||
      ref.read(composerControllerProvider).photos.isNotEmpty;

  Future<void> _post() async {
    final post =
        await ref.read(composerControllerProvider.notifier).submit(_text.text);
    if (!mounted) return;
    if (post != null) {
      Navigator.of(context).pop();
    } else {
      final err = ref.read(composerControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err?.message ?? 'Could not post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(composerControllerProvider);
    final canPost = _canPost && !state.busy;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _header(canPost: canPost, busy: state.busy),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                children: [
                  TextField(
                    controller: _text,
                    autofocus: true,
                    maxLines: null,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration.collapsed(
                      hintText: 'What happened on the field?',
                      hintStyle:
                          CkType.body(fontSize: 16, height: 1.5, color: CkColors.soft),
                    ),
                    style:
                        CkType.body(fontSize: 16, height: 1.5, color: CkColors.ink),
                  ),
                  if (state.photos.isNotEmpty || state.canAddPhoto) ...[
                    const SizedBox(height: 16),
                    _PhotoStrip(
                      state: state,
                      onAdd: () =>
                          ref.read(composerControllerProvider.notifier).addPhoto(),
                      onRemove: (i) => ref
                          .read(composerControllerProvider.notifier)
                          .removePhoto(i),
                    ),
                  ],
                ],
              ),
            ),
            _toolbar(
              canAddPhoto: state.canAddPhoto && !state.busy,
              onAddPhoto: () =>
                  ref.read(composerControllerProvider.notifier).addPhoto(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({required bool canPost, required bool busy}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: busy ? null : () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text('Cancel',
                  style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CkColors.ink2)),
            ),
          ),
          Text('New post', style: CkType.display(fontSize: 15, fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: canPost ? _post : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: canPost ? CkColors.ink : CkColors.paper2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: CkColors.paper),
                    )
                  : Text('Post',
                      style: CkType.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: canPost ? CkColors.paper : CkColors.muted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar({required bool canAddPhoto, required VoidCallback onAddPhoto}) {
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
          Text('PUBLIC ▾',
              style: CkType.mono(
                  fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.08)),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.state,
    required this.onAdd,
    required this.onRemove,
  });

  final ComposerState state;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < state.photos.length; i++)
          _Thumb(
            file: state.photos[i].file,
            onRemove: () => onRemove(i),
            cover: i == 0,
          ),
        if (state.canAddPhoto)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CkColors.line),
              ),
              child: const Icon(Icons.add, color: CkColors.muted),
            ),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.file, required this.onRemove, this.cover = false});
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
