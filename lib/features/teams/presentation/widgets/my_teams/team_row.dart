import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/my_teams_view.dart';
import 'crest_palette.dart';
import 'role_pill.dart';

/// Swiss-army row used by every team-list section (captain/vc/playing/manage/
/// draft/scorer/pending/archived/following). Crest on the left (with optional
/// notification badge), name + verified tick + role pill, mono meta line with
/// optional jersey number and inline LIVE pill, chevron on the right.
///
/// Archived rows render with a dim opacity, a dashed crest, and no chevron
/// (controllable via [withChevron]).
class TeamRow extends StatelessWidget {
  const TeamRow({
    super.key,
    required this.vm,
    this.isFirst = false,
    this.withChevron = true,
    this.onTap,
  });

  final TeamRowVm vm;

  /// When true skips the top hairline divider (used by the first row in a section).
  final bool isFirst;

  /// Archived rows pass false — they are present but quiet.
  final bool withChevron;
  final VoidCallback? onTap;

  bool get _inactive =>
      vm.role == MyTeamsRole.archived || vm.role == MyTeamsRole.pending;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: _inactive ? 0.74 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            border: isFirst
                ? null
                : const Border(top: BorderSide(color: CkColors.hairline)),
          ),
          child: Row(
            children: [
              _CrestWithBadge(
                  crest: vm.crest, dim: vm.role == MyTeamsRole.archived, badge: vm.notifCount),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vm.crest.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.display(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ),
                        if (vm.verified) ...[
                          const SizedBox(width: 6),
                          const VerifiedTick(),
                        ],
                        if (RolePill.hasSpec(vm.role)) ...[
                          const SizedBox(width: 6),
                          RolePill(role: vm.role),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    _MetaLine(vm: vm),
                  ],
                ),
              ),
              if (withChevron) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 18, color: CkColors.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CrestWithBadge extends StatelessWidget {
  const _CrestWithBadge({required this.crest, required this.dim, this.badge});
  final CrestStyle crest;
  final bool dim;
  final int? badge;

  bool get _showImage =>
      !dim && (crest.logoUrl != null && crest.logoUrl!.isNotEmpty);

  Widget _monoTile() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: dim ? CkColors.paper2 : crest.color,
          borderRadius: BorderRadius.circular(11),
          border: dim
              ? Border.all(color: CkColors.line, style: BorderStyle.solid)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          crest.mono,
          style: CkType.display(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
            color: dim ? CkColors.muted : CkColors.paper,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tile = _showImage
        ? ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 44,
              height: 44,
              color: CkColors.paper2,
              child: Image.network(
                crest.logoUrl!,
                fit: BoxFit.cover,
                width: 44,
                height: 44,
                errorBuilder: (_, __, ___) => _monoTile(),
                loadingBuilder: (ctx, child, progress) =>
                    progress == null ? child : _monoTile(),
              ),
            ),
          )
        : _monoTile();
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (badge != null && badge! > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.paper, width: 2),
                ),
                child: Text(
                  '$badge',
                  style: CkType.display(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.vm});
  final TeamRowVm vm;

  @override
  Widget build(BuildContext context) {
    final style = CkType.mono(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.02,
      color: CkColors.muted,
    );
    final parts = <Widget>[];
    if (vm.jersey != null) {
      parts.add(Text('#${vm.jersey}', style: style));
      parts.add(_dot(style));
    }
    parts.add(Flexible(
      child: Text(
        vm.meta ?? vm.crest.city ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    ));
    if (vm.live) {
      parts.add(_dot(style));
      parts.add(const LivePill());
    }
    return Row(children: parts);
  }

  Widget _dot(TextStyle style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('·', style: style),
      );
}
