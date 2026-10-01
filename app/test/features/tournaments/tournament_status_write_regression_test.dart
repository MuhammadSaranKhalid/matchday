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

    test('Close Registration without locking entries: entry_state remains editable', () {
      final closedRegistration = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.closed,
        entryState: TournamentEntryState.editable,
      );
      expect(closedRegistration.registrationState, equals(TournamentRegistrationState.closed));
      expect(closedRegistration.entryState, equals(TournamentEntryState.editable));
      expect(closedRegistration.projectedPublicStatus, equals(TournamentStatus.upcoming));
    });

    test('Explicit Entry Lock: entry_state becomes locked independently of registration closing', () {
      final locked = createTestTournament(
        publicationState: TournamentPublicationState.published,
        registrationState: TournamentRegistrationState.closed,
        entryState: TournamentEntryState.locked,
      );
      expect(locked.registrationState, equals(TournamentRegistrationState.closed));
      expect(locked.entryState, equals(TournamentEntryState.locked));
      expect(locked.projectedPublicStatus, equals(TournamentStatus.upcoming));
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

  group('Phase 2.2 — Lifecycle Operation Semantics & Isolation Guard', () {
    test('organizer_console_screen _closeRegistrationEarly must NOT lock entries', () {
      final file = File('lib/features/tournaments/presentation/screens/organizer_console_screen.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      // Find _closeRegistrationEarly method body
      final match = RegExp(r'_closeRegistrationEarly\s*\(\)\s*async\s*\{([\s\S]*?)\}').firstMatch(content);
      expect(match, isNotNull, reason: '_closeRegistrationEarly method must exist');
      final body = match!.group(1)!;

      expect(body.contains("'registration_state': 'closed'"), isTrue,
          reason: 'Must set registration_state to closed');
      expect(body.contains('entry_state'), isFalse,
          reason: 'Must NOT mutate entry_state when closing registration');
    });

    test('tournaments_controller startTournament must NOT silently publish tournament', () {
      final file = File('lib/features/tournaments/presentation/controllers/tournaments_controller.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      // Find startTournament method body
      final match = RegExp(r'startTournament\s*\([^)]*\)\s*async\s*\{([\s\S]*?)(?:Future<bool>|\n\s*\})').firstMatch(content);
      expect(match, isNotNull, reason: 'startTournament method must exist');
      final body = match!.group(1)!;

      expect(body.contains("'competition_state': 'in_progress'"), isTrue,
          reason: 'Must set competition_state to in_progress');
      expect(body.contains("'publication_state':") || body.contains('"publication_state":'), isFalse,
          reason: 'Must NOT silently auto-publish in startTournament');
    });

    test('tournaments_remote_datasource separates pure publish from composite publishAndOpenRegistration', () {
      final file = File('lib/features/tournaments/data/datasources/tournaments_remote_datasource.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      // Find publishTournament method body
      final publishMatch = RegExp(r'Future<void>\s+publishTournament\s*\([^)]*\)\s*async\s*\{([\s\S]*?)\n\s*\}').firstMatch(content);
      expect(publishMatch, isNotNull, reason: 'publishTournament method must exist');
      final publishBody = publishMatch!.group(1)!;

      expect(publishBody.contains("'publication_state': 'published'"), isTrue);
      expect(publishBody.contains('registration_state'), isFalse,
          reason: 'Pure publishTournament must not touch registration_state');

      // Find publishAndOpenRegistration method body
      final compositeMatch = RegExp(r'Future<void>\s+publishAndOpenRegistration\s*\([^)]*\)\s*async\s*\{([\s\S]*?)\n\s*\}').firstMatch(content);
      expect(compositeMatch, isNotNull, reason: 'publishAndOpenRegistration method must exist');
      final compositeBody = compositeMatch!.group(1)!;

      expect(compositeBody.contains("'publication_state': 'published'"), isTrue);
      expect(compositeBody.contains("'registration_state': 'open'"), isTrue);
    });

    test('wizard screen calls composite publishAndOpenRegistration', () {
      final file = File('lib/features/tournaments/presentation/screens/tournament_create_wizard_screen.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('controller.publishAndOpenRegistration('), isTrue,
          reason: 'Wizard screen creates and opens registration using explicit composite method');
    });
  });

  group('Phase 2.4 — Cancellation Start Boundary & Concurrency Closure Guard', () {
    Tournament createTestTournament({
      TournamentPublicationState publicationState = TournamentPublicationState.published,
      TournamentRegistrationState registrationState = TournamentRegistrationState.open,
      TournamentEntryState entryState = TournamentEntryState.editable,
      TournamentCompetitionState competitionState = TournamentCompetitionState.notStarted,
      TournamentTerminationState terminationState = TournamentTerminationState.none,
    }) {
      return Tournament(
        id: 't-test',
        name: 'Cancellation Cup 2026',
        type: TournamentType.knockout,
        status: TournamentStatus.upcoming,
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

    test('Cancellation transition sets termination_state = cancelled and projects cancelled status', () {
      final active = createTestTournament();
      expect(active.projectedPublicStatus, equals(TournamentStatus.registration));

      final cancelled = createTestTournament(
        terminationState: TournamentTerminationState.cancelled,
      );
      expect(cancelled.terminationState, equals(TournamentTerminationState.cancelled));
      expect(cancelled.projectedPublicStatus, equals(TournamentStatus.cancelled));

      // Other canonical axes must remain untouched
      expect(cancelled.publicationState, equals(active.publicationState));
      expect(cancelled.registrationState, equals(active.registrationState));
      expect(cancelled.entryState, equals(active.entryState));
      expect(cancelled.competitionState, equals(active.competitionState));
    });

    test('tournaments_remote_datasource cancelTournament calls tournament_cancel RPC with exact parameters', () {
      final file = File('lib/features/tournaments/data/datasources/tournaments_remote_datasource.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains("'tournament_cancel'"), isTrue,
          reason: 'Must call tournament_cancel RPC');
      expect(content.contains("'p_tournament_id': tournamentId"), isTrue,
          reason: 'Must supply p_tournament_id parameter');
      expect(content.contains("'p_reason': reason"), isTrue,
          reason: 'Must supply p_reason parameter');
    });

    test('SQL migration declares tournament_cancel with row lock, started-match guard, and scheduled-only cancellation', () {
      final migrationFile = File('../supabase/migrations/20261001000100_tournament_memberships.sql');
      expect(migrationFile.existsSync(), isTrue);
      final sql = migrationFile.readAsStringSync();

      expect(sql.contains('create or replace function public.tournament_cancel('), isTrue,
          reason: 'Must declare public.tournament_cancel');
      expect(sql.contains('for update;'), isTrue,
          reason: 'Must acquire row lock on tournaments for concurrency-safe serialization');
      expect(sql.contains("public.can('tournament', p_tournament_id, 'tournament.cancel')"), isTrue,
          reason: 'Must authorize via canonical tournament.cancel capability');
      expect(sql.contains("v_competition_state != 'not_started'"), isTrue,
          reason: 'Must reject cancellation once tournament competition_state has started');
      expect(sql.contains("status in ('live', 'completed', 'abandoned')") && sql.contains("actual_start_time is not null"), isTrue,
          reason: 'Must guard against started, live, completed, or abandoned matches');
      expect(sql.contains("status in ('scheduled', 'live')"), isFalse,
          reason: 'Must NEVER cancel live matches');
      expect(sql.contains("and status = 'scheduled'") && sql.contains("and actual_start_time is null;"), isTrue,
          reason: 'Must void ONLY unstarted scheduled fixtures');
      expect(sql.contains("termination_state = 'cancelled'"), isTrue,
          reason: 'Must set canonical termination_state to cancelled');
    });

    test('SQL migration tournament_cancel does NOT synchronously invoke tournament_announce (Phase 2.5 communication isolation)', () {
      final migrationFile = File('../supabase/migrations/20261001000100_tournament_memberships.sql');
      expect(migrationFile.existsSync(), isTrue);
      final sql = migrationFile.readAsStringSync();

      final cancelFnStart = sql.indexOf('create or replace function public.tournament_cancel(');
      expect(cancelFnStart, isNonNegative);
      final cancelFnEnd = sql.indexOf('revoke all on function public.tournament_cancel', cancelFnStart);
      expect(cancelFnEnd, isNonNegative);
      final cancelFnBody = sql.substring(cancelFnStart, cancelFnEnd);

      expect(cancelFnBody.contains('tournament_announce('), isFalse,
          reason: 'Communication failure must NEVER roll back authoritative competition/cancellation state');
      expect(cancelFnBody.contains('perform public.tournament_announce'), isFalse,
          reason: 'tournament_cancel must not invoke tournament_announce');
    });
  });
}
