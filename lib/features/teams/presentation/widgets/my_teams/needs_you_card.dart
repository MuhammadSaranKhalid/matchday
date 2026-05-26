import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/my_teams_view.dart';
import 'role_pill.dart';

/// "STATUS · WHAT NEEDS YOU" banner sits above every other section when the
/// user has captain decisions, claim approvals, or pending invites.
/// Each item is a card with a left-border accent (red / amber / ink) and
/// 0–N action buttons (first is primary, rest are ghost).
class NeedsYouSection extends StatelessWidget {
  const NeedsYouSection({super.key, required this.items});
  final List<NeedsYouItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'STATUS · WHAT NEEDS YOU',
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.10,
                    color: CkColors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CkColors.ink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${items.length}',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.paper,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _NeedsYouCard(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _NeedsYouCard extends StatelessWidget {
  const _NeedsYouCard({required this.item});
  final NeedsYouItem item;

  Color get _accent {
    switch (item.tone) {
      case NeedsYouTone.red:
        return CkColors.red;
      case NeedsYouTone.amber:
        return CkColors.amber;
      case NeedsYouTone.ink:
        return CkColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Flutter disallows borderRadius with non-uniform border colors, so the
    // accent left edge is rendered as an inner stripe clipped to the
    // rounded corners rather than as a border side.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: _accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: _CardBody(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.item});
  final NeedsYouItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (RolePill.hasSpec(item.role)) ...[
              RolePill(role: item.role),
              const SizedBox(width: 6),
            ],
            if (item.subTag != null)
              Flexible(
                child: Text(
                  item.subTag!,
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
          item.title,
          style: CkType.display(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.body,
          style: CkType.body(fontSize: 12, color: CkColors.ink2),
        ),
        if (item.actions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < item.actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _ActionBtn(action: item.actions[i], primary: i == 0),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.action, required this.primary});
  final NeedsYouAction action;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: primary ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        action.label,
        style: CkType.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primary ? CkColors.paper : CkColors.ink,
        ),
      ),
    );
    if (action.onTap == null) return pill;
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(999),
      child: pill,
    );
  }
}
