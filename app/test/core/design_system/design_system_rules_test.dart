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

      // Baseline ratcheted down after Phase 5 (My Tournaments migration): 69 legacy occurrences.
      // New screens and features MUST use ActionButton instead of inventing custom button styles.
      const baselineCount = 69;

      if (totalCount > baselineCount) {
        final excess = totalCount - baselineCount;
        fail(
          'Detected $excess new .styleFrom() invocation(s) in lib/features/!\n'
          'Use ActionButton from package:matchday/core/design_system/design_system.dart instead.\n'
          'Current files with violations:\n'
          '${filesWithViolations.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}',
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
