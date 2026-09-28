import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'team_page_visuals.dart';

enum TeamPageTab { posts, squad, matches, stats, about, recent }

String teamPageTabLabel(TeamPageTab tab) => switch (tab) {
      TeamPageTab.posts => 'Posts',
      TeamPageTab.squad => 'Squad',
      TeamPageTab.matches => 'Matches',
      TeamPageTab.stats => 'Stats',
      TeamPageTab.about => 'About',
      TeamPageTab.recent => 'Recent',
    };

class TeamPageTabs extends StatelessWidget {
  const TeamPageTabs({
    super.key,
    required this.items,
    required this.active,
    required this.onSelect,
    this.recentCount,
  });

  final List<TeamPageTab> items;
  final TeamPageTab active;
  final ValueChanged<TeamPageTab> onSelect;
  final int? recentCount;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in items)
                InkWell(
                  onTap: () => onSelect(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: tab == active
                              ? CkColors.ink
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          teamPageTabLabel(tab),
                          style: CkType.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tab == active
                                ? CkColors.ink
                                : CkColors.muted,
                          ),
                        ),
                        if (tab == TeamPageTab.recent &&
                            (recentCount ?? 0) > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: tab == active
                                  ? CkColors.ink
                                  : CkColors.cream,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$recentCount',
                              style: teamPageMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: tab == active
                                    ? CkColors.paper
                                    : CkColors.ink2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
