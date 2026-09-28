import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../providers/match_pool_providers.dart';

/// The board's facet row — `Pool.dc.html` artboard 01.
///
/// Selected reads as ink-on-paper; the rest sit back on paper-2 so the row
/// states the current cut of the board at a glance rather than presenting
/// four equal buttons.
class PoolFacetBar extends StatelessWidget {
  const PoolFacetBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final PoolFacet selected;
  final ValueChanged<PoolFacet> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
      child: Row(
        children: [
          for (final facet in PoolFacet.values) ...[
            _Chip(
              label: facet.label,
              active: facet == selected,
              onTap: () => onSelect(facet),
            ),
            if (facet != PoolFacet.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? CkColors.ink : CkColors.hairline),
        ),
        child: Text(
          label.toUpperCase(),
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.06,
            color: active ? CkColors.paper : CkColors.muted,
          ),
        ),
      ),
    );
  }
}
