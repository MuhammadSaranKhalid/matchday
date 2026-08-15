import 'package:flutter/material.dart';

import '../../theme/circk_theme.dart';
import '../v2/v2_kit.dart';

/// Identity passed when opening a team crest from the feed.
class TeamMeta {
  const TeamMeta({
    required this.name,
    required this.mono,
    required this.color,
  });

  final String name;
  final String mono;
  final Color color;
}

/// Team Page — opened by tapping a team crest in the feed (header + Posts/Squad/Matches/About tabs + next-match / last-result / recruitment cards).
class TeamPage extends StatelessWidget {
  const TeamPage({super.key, required this.team});
  final TeamMeta team;

  @override
  Widget build(BuildContext context) {
    final color = team.color;
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: Column(
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: V2Svg(
                        V2Icons.chevronLeft,
                        size: 22,
                        color: CkColors.paper,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          team.mono,
                          style: CkType.display(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: CkColors.paper,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: CkType.display(
                                fontSize: 24,
                                height: 1.1,
                                color: CkColors.paper,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '14 ACTIVE · 142 MATCHES · EST. 2024',
                              style: CkType.mono(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ).copyWith(letterSpacing: 0.9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 14,
                        child: _hdrBtn(
                          'Follow',
                          bg: CkColors.paper,
                          fg: CkColors.ink,
                          w: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 10,
                        child: _hdrBtn(
                          'Message',
                          bg: Colors.transparent,
                          fg: CkColors.paper,
                          w: FontWeight.w600,
                          border: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CkColors.hairline)),
            ),
            child: Row(
              children: [
                _tab('POSTS', active: true),
                const SizedBox(width: 14),
                _tab('SQUAD'),
                const SizedBox(width: 14),
                _tab('MATCHES'),
                const SizedBox(width: 14),
                _tab('ABOUT'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              children: [
                _infoCard(
                  label: 'NEXT MATCH',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs Karachi Eagles',
                        style: CkType.display(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fri 30 May · 6 PM · Model Town',
                        style: CkType.body(
                          fontSize: 12,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _infoCard(
                  label: 'LAST RESULT',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Crest(
                            short: team.mono,
                            color: color,
                            size: 22,
                            radius: 5,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '142/6',
                            style: CkType.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CkColors.ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '119/9',
                            style: CkType.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CkColors.muted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Crest(
                            short: 'KC',
                            color: Color(0xFF2E3E63),
                            size: 22,
                            radius: 5,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: CkColors.redSoft,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'Won by 23 runs',
                          style: CkType.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8C2218),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _infoCard(
                  label: 'RECRUITMENT',
                  surface: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Right-arm fast bowler needed',
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ages 18-28 · tape ball · apply by Wed',
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
          ),
        ],
      ),
    );
  }

  Widget _hdrBtn(
    String label, {
    required Color bg,
    required Color fg,
    required FontWeight w,
    bool border = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border
            ? Border.all(color: Colors.white.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: CkType.body(fontSize: 13, fontWeight: w, color: fg),
      ),
    );
  }

  Widget _tab(String label, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: active
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: CkColors.ink, width: 2)),
            )
          : null,
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? CkColors.ink : CkColors.muted,
        ),
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required Widget child,
    bool surface = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surface ? CkColors.surface : CkColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CkType.mono(fontSize: 9, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
