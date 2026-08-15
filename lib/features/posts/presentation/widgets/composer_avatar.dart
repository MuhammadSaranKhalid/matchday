import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/post.dart';
import '../controllers/composer_controller.dart';

class ComposerAvatar extends ConsumerWidget {
  const ComposerAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(composerControllerProvider);

    if (state.authorContext == PostAuthorContext.teamManager) {
      final mono = state.entityMono ?? 'T';
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          mono,
          style: CkType.display(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: CkColors.paper,
          ),
        ),
      );
    }

    final p = ref.watch(myProfileProvider).value;
    final url = p?.avatarUrl;

    // Determine initials
    String initials = '?';
    if (p != null && (p.displayName?.isNotEmpty ?? false)) {
      final words = (p.displayName ?? '').trim().split(RegExp(r'\s+'));
      final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).join();
      initials =
          letters.isEmpty
              ? '?'
              : letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
    }

    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: CkColors.ink,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.hardEdge,
      child:
          url != null && url.isNotEmpty
              ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget(initials),
              )
              : _initialsWidget(initials),
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: CkType.display(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: CkColors.paper,
        ),
      ),
    );
  }
}
