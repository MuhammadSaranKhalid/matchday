import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildEmptyStateComponent() {
  return WidgetbookComponent(
    name: 'EmptyState',
    useCases: [
      WidgetbookUseCase(
        name: 'First Run',
        builder: (context) {
          return EmptyState(
            kind: EmptyStateKind.firstRun,
            icon: Icons.sports_cricket,
            title: 'No tournaments yet',
            description: 'Create your first tournament to get started with live brackets.',
            primaryAction: StateAction(
              label: 'Create tournament',
              onPressed: () {},
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'First Run + Two Actions',
        builder: (context) {
          return EmptyState(
            kind: EmptyStateKind.firstRun,
            icon: Icons.group_work_outlined,
            title: 'No teams registered',
            description: 'Invite squads to your league or register a new team.',
            primaryAction: StateAction(
              label: 'Invite teams',
              onPressed: () {},
            ),
            secondaryAction: StateAction(
              label: 'Browse directory',
              onPressed: () {},
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Section Empty',
        builder: (context) {
          return const EmptyState(
            kind: EmptyStateKind.section,
            title: 'No upcoming fixtures',
            description: 'Scheduled matches will show up here.',
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Filtered Empty',
        builder: (context) {
          return EmptyState(
            kind: EmptyStateKind.filtered,
            title: 'No matches found',
            description: 'No live matches matched your selected status and date filters.',
            primaryAction: StateAction(
              label: 'Reset filters',
              onPressed: () {},
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Passive Empty',
        builder: (context) {
          return const EmptyState(
            kind: EmptyStateKind.passive,
            title: 'No activity to report',
            description: 'Stats update in real-time once play starts.',
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Long Text',
        builder: (context) {
          return EmptyState(
            kind: EmptyStateKind.firstRun,
            icon: Icons.info_outline,
            title: 'No historical statistics available for this selected player profile',
            description:
                'This player has not participated in any verified club matches, leagues, or tournaments registered on the Matchday network yet.',
            primaryAction: StateAction(
              label: 'View active leaderboard',
              onPressed: () {},
            ),
          );
        },
      ),
    ],
  );
}
