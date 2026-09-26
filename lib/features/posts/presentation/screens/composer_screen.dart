// The post composer — type and/or attach up to 4 photos (each picked → cropped
// → resized). Online-only: submitting inserts the post + uploads media to
// Supabase, then prepends it to the feed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../controllers/composer_controller.dart';
import '../widgets/composer_avatar.dart';
import '../widgets/composer_header.dart';
import '../widgets/composer_photo_strip.dart';
import '../widgets/composer_toolbar.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({
    super.key,
    this.initialPublisher = PostPublisherSelection.user,
  });

  final PostPublisherSelection initialPublisher;

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
        ref.read(composerControllerProvider.notifier).setPublisher(widget.initialPublisher);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nav = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final post = await ref
        .read(composerControllerProvider.notifier)
        .submit(_text.text);
    if (!mounted) return;

    if (post != null) {
      HapticFeedback.lightImpact();
      nav.pop();
    } else {
      final err = ref.read(composerControllerProvider).error;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            err?.message ?? 'Could not create post. Please try again.',
          ),
          backgroundColor: CkColors.ink,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(composerControllerProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            ComposerHeader(
              busy: state.busy,
              canPost: _text.text.trim().isNotEmpty || state.photos.isNotEmpty,
              onPost: _submit,
              onCancel: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IdentitySelector(
                      publisher: state.publisher,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ComposerAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _text,
                                focusNode: _focusNode,
                                autofocus: true,
                                maxLines: null,
                                maxLength: 1000,
                                buildCounter:
                                    (
                                      _, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) => null,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: state.publisher.type != PostPublisherType.user
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
                    if (state.photos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ComposerPhotoStrip(
                        state: state,
                        onAdd: () => ref
                            .read(composerControllerProvider.notifier)
                            .addPhoto(),
                        onRemove: (i) => ref
                            .read(composerControllerProvider.notifier)
                            .removePhoto(i),
                      ),
                    ],
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
    required this.publisher,
  });

  final PostPublisherSelection publisher;

  @override
  Widget build(BuildContext context) {
    if (publisher.type == PostPublisherType.user) return const SizedBox.shrink();

    final name = publisher.name ?? (publisher.type == PostPublisherType.team ? 'Team' : 'Tournament');
    final badgeLabel = publisher.type == PostPublisherType.team ? 'TEAM' : 'TOURNAMENT';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                badgeLabel,
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
