import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryPaths = [
    'supabase/functions/record-ball/repositories/match_repository.ts',
    'supabase/functions/cricket-match-action/repositories/match_team_repository.ts',
  ];

  for (final path in repositoryPaths) {
    test('$path leaves participant materialization to the database', () {
      final source = File(path).readAsStringSync();
      final advanceWinner = source.substring(source.indexOf('advanceWinner('));

      // Updating match_teams fires the canonical participant-sync trigger.
      // Edge code must not duplicate that invariant using mutable team rosters.
      expect(
        advanceWinner,
        isNot(contains('insert into public.match_players')),
      );
      expect(advanceWinner, isNot(contains('materializeSide(')));
    });
  }
}
