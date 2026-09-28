import 'package:flutter/material.dart';

import '../../../../../matches/domain/entities/match.dart';
import '../team_page_visuals.dart';

/// Keeps the established Stats tab in the UI without inventing statistics
/// that the current backend does not expose yet.
class TeamStatsTab extends StatelessWidget {
  const TeamStatsTab({super.key, required this.matches});
  final List<Match> matches;

  @override
  Widget build(BuildContext context) {
    final completed = matches.where((match) => match.status.isPast).length;
    return TeamPageEmptyTile(
      icon: Icons.bar_chart_rounded,
      title: completed == 0 ? 'No team stats yet' : 'Detailed team stats are coming',
      body: completed == 0
          ? 'Stats will build from completed Matchday scorecards.'
          : '$completed completed match${completed == 1 ? '' : 'es'} are on record. Player and team aggregates will appear here when the stats backend is connected.',
    );
  }
}
