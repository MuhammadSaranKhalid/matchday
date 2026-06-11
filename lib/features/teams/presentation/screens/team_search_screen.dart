// Search tab — placeholder for Team Search & Discovery
// (docs/search-feature-design.md, Slice 3).
//
// PRESENTATION-ONLY. The real screen (debounced search box, near-me toggle,
// city facet chips, results list) ships with search Slice 3; this placeholder
// exists so the Search tab (D9: nav order Home · Search · Matches · Messages ·
// Pavilion) has a destination from day one. The search field is inert.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

class TeamSearchScreen extends StatelessWidget {
  const TeamSearchScreen({super.key, this.onBell});

  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            V2Header(title: 'Search', onBell: onBell),
            // Inert search field — visual placeholder until Slice 3 wires the
            // real TeamSearchController.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  border: Border.all(color: CkColors.hairline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const V2Svg(V2Icons.search,
                        size: 18, color: CkColors.muted),
                    const SizedBox(width: 8),
                    Text(
                      'Search teams',
                      style:
                          CkType.body(fontSize: 13, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const V2Svg(V2Icons.search,
                          size: 36, color: CkColors.soft),
                      const SizedBox(height: 14),
                      Text(
                        'Find teams near you',
                        style: CkType.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Team search & discovery is coming soon — search by '
                        'name, browse by city, or find teams around you.',
                        textAlign: TextAlign.center,
                        style: CkType.body(
                          fontSize: 12.5,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
