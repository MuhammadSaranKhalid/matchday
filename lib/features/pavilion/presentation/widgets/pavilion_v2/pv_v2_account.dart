// Pavilion v2 — Account sheet.
//
// The profile header is wired to the real `myProfileProvider`
// (name · @username · player role · city). The grouped rows below are still
// mock — most (Stats / Wallet / Achievements / Scorer / Settings) have no
// backend, and Saved / Following have tables but no Flutter feature yet — so
// every row just toasts for now.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../onboarding/presentation/providers/onboarding_providers.dart';
import 'pv_v2_data.dart';
import 'pv_v2_kit.dart';
import 'pv_v2_map.dart';

class PvAccountSheet extends ConsumerWidget {
  const PvAccountSheet({super.key, required this.onClose, required this.onToast});

  final VoidCallback onClose;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final name = profile?.displayName ?? profile?.username ?? 'Your profile';
    final roleLabel = playerRoleLabel(profile?.playerProfile?.role);
    final line = [
      if (profile?.username != null && profile!.username!.isNotEmpty) '@${profile.username}',
      if (roleLabel.isNotEmpty) roleLabel,
      if (profile?.city != null && profile!.city!.isNotEmpty) profile.city!,
    ].join(' · ');

    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // header bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: CkColors.hairline)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PvIcon(PvIcons.back, size: 18, color: CkColors.ink, sw: 2),
                          const SizedBox(width: 4),
                          Text('Pavilion',
                              style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('ACCOUNT', style: pvMono(9, color: CkColors.muted)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // profile header (real)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Row(
                      children: [
                        Avatar(mono: initialsOf(name), size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CkType.display(
                                      fontSize: 20, fontWeight: FontWeight.w700)),
                              if (line.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(line,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          CkType.body(fontSize: 12.5, color: CkColors.muted)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final grp in kPvAccount) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                      child: Text(grp.group, style: pvMono(10, color: CkColors.muted)),
                    ),
                    for (final it in grp.items) _row(it),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onToast('Signed out'),
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CkColors.paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: CkColors.hairline),
                            ),
                            child: Text('Sign out',
                                style: CkType.body(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: CkColors.red)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text('MATCHDAY · v2.0',
                              style: pvMono(9, color: CkColors.muted)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(PvAccountItem it) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onToast(it.title),
      child: Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CkColors.hairline),
              ),
              child: PvIcon.named(it.icon, size: 16, color: CkColors.ink2, sw: 1.8),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(it.title,
                      style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600)),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(it.sub,
                        style: CkType.body(fontSize: 11.5, color: CkColors.muted)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const PvIcon(PvIcons.next, size: 15, color: CkColors.muted, sw: 2),
          ],
        ),
      ),
    );
  }
}
