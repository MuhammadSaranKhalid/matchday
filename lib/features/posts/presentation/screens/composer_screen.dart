// The post composer — type and/or attach up to 4 photos (each picked → cropped
// → resized). Online-only: submitting inserts the post + uploads media to
// Supabase, then prepends it to the feed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/post.dart';
import '../controllers/composer_controller.dart';
import '../widgets/composer_avatar.dart';
import '../widgets/composer_header.dart';
import '../widgets/composer_photo_strip.dart';
import '../widgets/composer_toolbar.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({
    super.key,
    this.initialAuthorContext = PostAuthorContext.personal,
    this.initialEntityId,
    this.initialEntityName,
    this.initialEntityMono,
  });

  final PostAuthorContext initialAuthorContext;
  final String? initialEntityId;
  final String? initialEntityName;
  final String? initialEntityMono;

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _text = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(composerControllerProvider.notifier).setIdentity(
              authorContext: widget.initialAuthorContext,
              contextEntityId: widget.initialEntityId,
              entityName: widget.initialEntityName,
              entityMono: widget.initialEntityMono,
            );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    // Explicitly set identity before submit to guarantee payload has contextEntityId
    ref.read(composerControllerProvider.notifier).setIdentity(
          authorContext: widget.initialAuthorContext,
          contextEntityId: widget.initialEntityId,
          entityName: widget.initialEntityName,
          entityMono: widget.initialEntityMono,
        );
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
    final canPost = (_text.text.trim().isNotEmpty || state.photos.isNotEmpty) &&
        !state.busy &&
        !state.photos.any((p) => p.hashPending);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            ComposerHeader(
              canPost: canPost,
              busy: state.busy,
              onPost: _post,
              onCancel: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // Massive UX win: tapping anywhere in the composer space focuses the text field
                  FocusScope.of(context).requestFocus(_focusNode);
                },
                child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                children: [
                  // Media-first composer: photos on top, caption below
                  // (only after the first photo — no empty placeholder).
                  if (state.photos.isNotEmpty) ...[
                    ComposerPhotoStrip(
                      state: state,
                      onAdd: () =>
                          ref.read(composerControllerProvider.notifier).addPhoto(),
                      onRemove: (int i) => ref
                          .read(composerControllerProvider.notifier)
                          .removePhoto(i),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ComposerAvatar(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _IdentitySelector(
                              state: state,
                              initialAuthorContext: widget.initialAuthorContext,
                              initialEntityName: widget.initialEntityName,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _text,
                              focusNode: _focusNode,
                              autofocus: true,
                              maxLines: null,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2000),
                              ],
                              onChanged: (_) => setState(() {}),
                              // Borderless caption (social-composer norm) — explicit
                              // none on every state so the theme's focused outline can't
                              // bleed in via autofocus.
                              decoration: InputDecoration(
                                isCollapsed: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText:
                                    state.authorContext ==
                                            PostAuthorContext.teamManager
                                        ? 'Share an announcement, trial, or match update...'
                                        : 'What happened on the field?',
                                hintStyle: CkType.body(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: CkColors.soft,
                                ),
                              ),
                              style: CkType.body(
                                fontSize: 16,
                                height: 1.5,
                                color: CkColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ComposerToolbar(
              canAddPhoto: state.canAddPhoto && !state.busy,
              charCount: _text.text.length,
              onAddPhoto: () =>
                  ref.read(composerControllerProvider.notifier).addPhoto(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentitySelector extends StatelessWidget {
  const _IdentitySelector({
    required this.state,
    required this.initialAuthorContext,
    required this.initialEntityName,
  });

  final ComposerState state;
  final PostAuthorContext initialAuthorContext;
  final String? initialEntityName;

  @override
  Widget build(BuildContext context) {
    final isTeam = state.authorContext == PostAuthorContext.teamManager ||
        initialAuthorContext == PostAuthorContext.teamManager;
    if (!isTeam) return const SizedBox.shrink();

    final name = state.entityName ?? initialEntityName ?? 'Team';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Posting as: ',
              style: CkType.mono(
                fontSize: 11,
                color: CkColors.muted,
              ),
            ),
            Text(
              name,
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CkColors.ink,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'TEAM',
                style: CkType.mono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


