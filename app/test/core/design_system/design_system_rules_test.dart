import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Design System Governance & Drift Rules', () {
    test('no new custom button styleFrom calls outside design system', () {
      final featuresDir = Directory('lib/features');
      expect(featuresDir.existsSync(), isTrue);

      final styleFromPattern = RegExp(
        r'(FilledButton|OutlinedButton|ElevatedButton)\.styleFrom\(',
      );

      final filesWithViolations = <String, int>{};
      var totalCount = 0;

      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          final matches = styleFromPattern.allMatches(content).length;
          if (matches > 0) {
            final normalized = entity.path.replaceAll(r'\', '/');
            filesWithViolations[normalized] = matches;
            totalCount += matches;
          }
        }
      }

      // Frozen baseline of legacy .styleFrom() calls across lib/features/.
      // Rule: No new files may introduce .styleFrom(), and existing files may not increase their count.
      const frozenStyleFromBaseline = <String, int>{
        'lib/features/matches/presentation/screens/challenge_detail_screen.dart': 6,
        'lib/features/matches/presentation/widgets/match_start/stage_lineup.dart': 3,
        'lib/features/matches/presentation/widgets/match_start/stage_toss.dart': 1,
        'lib/features/matches/presentation/widgets/withdraw_sheet.dart': 1,
        'lib/features/messages/presentation/widgets/chat_composer.dart': 1,
        'lib/features/teams/presentation/widgets/add_player_sheet.dart': 1,
        'lib/features/teams/presentation/widgets/team_manage/announcements_manage_tab.dart': 1,
        'lib/features/teams/presentation/widgets/team_manage/roster_tab.dart': 2,
        'lib/features/teams/presentation/widgets/team_manage/settings_tab.dart': 1,
        'lib/features/teams/presentation/widgets/team_page/tabs/team_squad_tab.dart': 1,
        'lib/features/teams/presentation/widgets/team_page/team_page_join_request_sheet.dart': 1,
        'lib/features/tournaments/presentation/screens/organizer_console_screen.dart': 5,
        'lib/features/tournaments/presentation/screens/team_registration_sheet.dart': 4,
        'lib/features/tournaments/presentation/screens/tournament_announce_screen.dart': 1,
        'lib/features/tournaments/presentation/screens/tournament_fee_ledger_screen.dart': 1,
        'lib/features/tournaments/presentation/screens/tournament_officials_screen.dart': 2,
        'lib/features/tournaments/presentation/screens/tournament_people_screen.dart': 1,
        'lib/features/tournaments/presentation/screens/tournament_published_screen.dart': 2,
        'lib/features/tournaments/presentation/screens/tournament_registration_status_screen.dart': 4,
        'lib/features/tournaments/presentation/screens/tournament_requests_screen.dart': 5,
        'lib/features/tournaments/presentation/screens/tournament_settings_screen.dart': 1,
        'lib/features/tournaments/presentation/widgets/champion_moment_view.dart': 2,
        'lib/features/tournaments/presentation/widgets/ground_picker_sheet.dart': 1,
        'lib/features/tournaments/presentation/widgets/record_payment_sheet.dart': 2,
        'lib/features/tournaments/presentation/widgets/tournament_cancel_dialog.dart': 2,
        'lib/features/tournaments/presentation/widgets/tournament_live_ops_tab.dart': 4,
        'lib/features/tournaments/presentation/widgets/tournament_lock_dialog.dart': 1,
        'lib/features/tournaments/presentation/widgets/tournament_ops_sheets.dart': 2,
        'lib/features/tournaments/presentation/widgets/tournament_overview_tab.dart': 1,
        'lib/features/tournaments/presentation/widgets/tournament_publish_dialog.dart': 1,
        'lib/features/tournaments/presentation/widgets/tournament_registrations_tab.dart': 3,
        'lib/features/tournaments/presentation/widgets/tournament_seeding_tab.dart': 2,
        'lib/features/tournaments/presentation/widgets/tournament_stats_tab.dart': 1,
        'lib/features/tournaments/presentation/widgets/tournament_teams_tab.dart': 1,
        'lib/features/tournaments/presentation/widgets/tournament_wrap_up_tab.dart': 1,
      };

      const baselineCount = 69;
      final errors = <String>[];

      for (final entry in filesWithViolations.entries) {
        final allowed = frozenStyleFromBaseline[entry.key];
        if (allowed == null) {
          errors.add('NEW FILE with .styleFrom(): ${entry.key} (${entry.value} call(s))');
        } else if (entry.value > allowed) {
          errors.add('INCREASED .styleFrom() calls in ${entry.key}: expected <= $allowed, got ${entry.value}');
        }
      }

      if (totalCount > baselineCount) {
        errors.add('Total .styleFrom() count exceeded baseline: $totalCount > $baselineCount');
      }

      if (errors.isNotEmpty) {
        fail(
          'Button style drift detected in lib/features/:\n'
          '${errors.map((e) => '  • $e').join('\n')}\n'
          'Use ActionButton from package:matchday/core/design_system/design_system.dart instead.',
        );
      }
    });

    test('no feature-scoped ThemeData or ThemeExtension definitions', () {
      final featuresDir = Directory('lib/features');
      final themePattern = RegExp(r'ThemeData\(|ThemeExtension<');

      final violations = <String>[];
      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          if (themePattern.hasMatch(content)) {
            violations.add(entity.path.replaceAll(r'\', '/'));
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Features must not define independent ThemeData or ThemeExtension. '
            'All theme tokens must live in lib/core/design_system/.',
      );
    });

    test('no new feature-scoped theme classes (freezes legacy ChatTheme)', () {
      final featuresDir = Directory('lib/features');
      final classThemePattern = RegExp(r'class\s+([A-Za-z0-9_]+Theme)\b');

      final allowedLegacyThemeClasses = {'ChatTheme'};
      final violations = <String>[];

      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          for (final match in classThemePattern.allMatches(content)) {
            final className = match.group(1);
            if (className != null &&
                !allowedLegacyThemeClasses.contains(className)) {
              violations.add(
                '${entity.path.replaceAll(r'\', '/')}: class $className',
              );
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Do not introduce feature-scoped Theme classes. Consume AppTheme or design system tokens.',
      );
    });
  });
}
