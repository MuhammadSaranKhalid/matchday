import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../state/my_teams_view.dart';
import 'crest_palette.dart';

/// Direct invite from a captain. Each card is a decision — Accept / Decline
/// within thumb reach. Cream "INVITE" eyebrow + inviter name + team headline
/// + role/city sub.
class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.invite});
  final InviteEntry invite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniCrest(crest: invite.crest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Chip(
                          label: 'INVITE',
                          bg: CkColors.cream,
                          fg: CkInk.amber,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            invite.fromName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.10,
                              color: CkColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${invite.fromName} invited you to ${invite.crest.name}.',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${invite.role}${invite.crest.city == null ? '' : ' · ${invite.crest.city}'}',
                      style: CkType.body(
                        fontSize: 12,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PrimaryBtn(label: 'Accept', onTap: () {}),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GhostBtn(label: 'Decline', onTap: () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCrest extends StatelessWidget {
  const _MiniCrest({required this.crest});
  final CrestStyle crest;

  Widget _mono() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: crest.color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          crest.mono,
          style: CkType.display(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
            color: CkColors.paper,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (crest.logoUrl == null || crest.logoUrl!.isEmpty) return _mono();
    final memW = (40 * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        color: CkColors.paper2,
        child: CachedNetworkImage(
          imageUrl: crest.logoUrl!,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          memCacheWidth: memW,
          errorWidget: (_, __, ___) => _mono(),
          placeholder: (_, __) => _mono(),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: fg,
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: CkColors.paper,
          ),
        ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CkColors.ink,
          ),
        ),
      ),
    );
  }
}
