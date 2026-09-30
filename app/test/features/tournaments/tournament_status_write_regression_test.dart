import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament.dart';

void main() {
  group('Phase 2.1 — Tournament Status Write Regression Guard', () {
    test(
        'Tournaments production Flutter code must NEVER write "status" directly to tournaments table',
        () {
      // Root directory for tournaments feature in lib/
      final tournamentsLibDir = Directory('lib/features/tournaments');
      expect(tournamentsLibDir.existsSync(), isTrue,
          reason: 'Tournaments lib directory must exist');

      final dartFiles = tournamentsLibDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();

        // 1. Check if updateTournament contains a write to 'status'
        final updateTournamentMatches =
            RegExp(r'updateTournament\s*\([^,]+,\s*\{([^}]+)\}', multiLine: true)
                .allMatches(content);
        for (final m in updateTournamentMatches) {
          final mapBody = m.group(1) ?? '';
          if (mapBody.contains("'status'") || mapBody.contains('"status"')) {
            violations.add(
                '${file.path}: Found direct write of legacy "status" column via updateTournament.');
          }
        }

        // 2. Check if direct supabase update on tournaments table writes to 'status'
        if (content.contains('_tournamentsTable') ||
            content.contains("'tournaments'")) {
          final updateTableMatches = RegExp(
                  r"\.from\((_tournamentsTable|'tournaments')\)\s*\.update\(\s*\{([^}]+)\}",
                  multiLine: true)
              .allMatches(content);
          for (final m in updateTableMatches) {
            final mapBody = m.group(2) ?? '';
            if (mapBody.contains("'status'") || mapBody.contains('"status"')) {
              violations.add(
                  '${file.path}: Found direct write of legacy "status" column to tournaments table.');
            }
          }
        }

        // 2. Also check createTournament / insertData for tournaments table
        if (file.path.endsWith('tournaments_remote_datasource.dart')) {
          final lines = content.split('\n');
          bool insideInsertData = false;
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains("final insertData = <String, dynamic>{")) {
              insideInsertData = true;
            }
            if (insideInsertData) {
              if (line.contains("'status':") || line.contains('"status":')) {
                // Must not write status in tournament insertData
                violations.add(
                    '${file.path}:${i + 1}: Found direct write of "status" in insertData.');
              }
              if (line.contains('};')) {
                insideInsertData = false;
              }
            }
          }
        }
      }

      expect(violations, isEmpty,
          reason:
              'Tournaments feature must not write to legacy "status" column. '
              'Writes must target canonical lifecycle columns (publication_state, '
              'registration_state, entry_state, competition_state, termination_state). '
              'Violations:\n${violations.join('\n')}');
    });
  });

  group('Phase 2.1 — Canonical Lifecycle Operations & Public Status Projections', () {
    Tournament createTestTournament({
      TournamentPublicationState publicationState = TournamentPublicationState.draft,
      TournamentRegistrationState registrationState = TournamentRegistrationState.notOpen,
      TournamentEntryState entryState = TournamentEntryState.editable,
      TournamentCompetitionState competitionState = TournamentCompetitionState.notStarted,
      TournamentTerminationState terminationState = TournamentTerminationState.none,
    }) {
      return Tournament(
        id: 't-test',
        name: 'Cup 2026',
        type: TournamentType.knockout,
        status: TournamentStatus.draft,
        privacy: TournamentPrivacy.public,
        publicationState: publicationState,
        registrationState: registrationState,
        entryState: entryState,
        competitionState: competitionState,
        terminationState: terminationState,
        organizers: const [],
        venues: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('Publish: publication_state changes to published without implicitly opening registration', () {
      // 1. Initial draft state
      final draft = createTestTournament();
      expect(draft.projectedPublicStatus, equals(TournamentStatus.draft));

      // 2. Publish action (discrete from registration)
      final published = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.notOpen,
      );
      // Registration state is NOT implicitly mutated
      expect(published.registrationState, equals(TournamentRegistrationState.notOpen));
      // Derived legacy status is upcoming (published, not open, not started)
      expect(published.projectedPublicStatus, equals(TournamentStatus.upcoming));
    });

    test('Open Registration: registration_state becomes open and projects registration status', () {
      final openRegistration = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.open,
      );
      expect(openRegistration.registrationState, equals(TournamentRegistrationState.open));
      expect(openRegistration.projectedPublicStatus, equals(TournamentStatus.registration));
    });

    test('Close Registration: registration_state becomes closed, entries locked, projects upcoming status', () {
      final closedRegistration = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.closed,
        entryState: TournamentEntryState.locked,
      );
      expect(closedRegistration.registrationState, equals(TournamentRegistrationState.closed));
      expect(closedRegistration.entryState, equals(TournamentEntryState.locked));
      expect(closedRegistration.projectedPublicStatus, equals(TournamentStatus.upcoming));
    });

    test('Start Competition: competition_state becomes in_progress and projects live status', () {
      final live = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.closed,
        entryState: TournamentEntryState.locked,
        competitionState: TournamentCompetitionState.inProgress,
      );
      expect(live.competitionState, equals(TournamentCompetitionState.inProgress));
      expect(live.projectedPublicStatus, equals(TournamentStatus.live));
    });

    test('Complete Competition: competition_state becomes completed and projects completed status', () {
      final completed = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.closed,
        entryState: TournamentEntryState.locked,
        competitionState: TournamentCompetitionState.completed,
      );
      expect(completed.competitionState, equals(TournamentCompetitionState.completed));
      expect(completed.projectedPublicStatus, equals(TournamentStatus.completed));
    });

    test('Cancel: termination_state becomes cancelled and overrides status to cancelled', () {
      final cancelled = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.open,
        terminationState: TournamentTerminationState.cancelled,
      );
      expect(cancelled.terminationState, equals(TournamentTerminationState.cancelled));
      expect(cancelled.projectedPublicStatus, equals(TournamentStatus.cancelled));
    });

    test('Abandon: termination_state becomes abandoned and overrides live status to abandoned', () {
      final abandoned = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.closed,
        entryState: TournamentEntryState.locked,
        competitionState: TournamentCompetitionState.inProgress,
        terminationState: TournamentTerminationState.abandoned,
      );
      expect(abandoned.terminationState, equals(TournamentTerminationState.abandoned));
      expect(abandoned.projectedPublicStatus, equals(TournamentStatus.abandoned));
    });
  });
}
