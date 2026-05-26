import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/my_teams_view.dart';

/// Horizontal scroll of suggested team cards with a "+ Follow" affordance.
/// Used in the empty-state and following-only cases to seed discovery.
class SuggestedStrip extends StatelessWidget {
  const SuggestedStrip({super.key, required this.items});
  final List<SuggestedTeam> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _Card(item: items[i]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.item});
  final SuggestedTeam item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.crest.color,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              item.crest.mono,
              style: CkType.display(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.03,
                color: CkColors.paper,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.crest.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              item.meta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 11, color: CkColors.muted),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Text(
                '+ Follow',
                style: CkType.body(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
