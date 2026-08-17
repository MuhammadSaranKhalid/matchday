// Architecture tests — the project's layer rules, machine-checkable.
//
// These encode the Clean Architecture rules from CLAUDE.md (as amended:
// NO use-case layer 2026-05-29, ONLINE-ONLY 2026-05-26) using dart_arch_test,
// which runs as plain `flutter test` — no analyzer plugin, so it coexists
// with the repo's pinned analyzer (custom_lint/riverpod_lint are disabled).
//
// NOTE: external-package purity (domain must not import flutter/riverpod/
// supabase/drift) is enforced by the .claude/settings.json grep hook +
// architecture-reviewer agent, because dart_arch_test selectors only match
// libraries INSIDE this package. The rules below cover internal structure.
//
// Run: flutter test test/architecture_test.dart
// Update a freeze baseline after fixing violations:
//   DART_ARCH_TEST_UPDATE_FREEZE=1 flutter test test/architecture_test.dart
import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DependencyGraph graph;

  setUpAll(() async {
    // flutter test runs from the package root (where pubspec.yaml lives).
    graph = await Collector.buildGraph(Directory.current.path);
  });

  group('layer direction (the Dependency Rule)', () {
    test('domain must not import data or presentation', () {
      shouldNotDependOn(
        filesMatching('features/*/domain/**'),
        union(
          filesMatching('features/*/data/**'),
          filesMatching('features/*/presentation/**'),
        ),
        graph,
      );
    });

    test('data must not import presentation', () {
      shouldNotDependOn(
        filesMatching('features/*/data/**'),
        filesMatching('features/*/presentation/**'),
        graph,
      );
    });

    test('domain must not import core widgets/theme (UI leaking inward)', () {
      shouldNotDependOn(
        filesMatching('features/*/domain/**'),
        union(
          filesMatching('core/widgets/**'),
          filesMatching('core/theme/**'),
        ),
        graph,
      );
    });
  });

  group('removed architecture must stay removed', () {
    test('no use-case layer (amendment 2026-05-29)', () {
      shouldNotExist(filesMatching('features/*/domain/usecases/**'), graph);
      shouldNotExist(filesMatching('core/usecase/**'), graph);
    });
  });

  group('graph hygiene', () {
    test('no import cycles anywhere in lib/', () {
      shouldBeFreeOfCycles(filesMatching('lib/**'), graph);
    });
  });

  group('cross-feature boundaries', () {
    // A feature's PRESENTATION may consume another feature's presentation
    // providers (existing precedent: v2_kit -> notifications/onboarding
    // providers), but reaching into another feature's DATA layer bypasses
    // its domain contract. Frozen: the first run records today's violations
    // as the baseline; CI fails only on NEW ones. Fix-forward, then refresh
    // the baseline with DART_ARCH_TEST_UPDATE_FREEZE=1.
    test('a feature must not import another feature\'s data layer (frozen)',
        () {
      freeze('cross_feature_data_imports', () {
        for (final feature in const [
          'auth',
          'follows',
          'home',
          'location',
          'matches',
          'messages',
          'notifications',
          'onboarding',
          'pavilion',
          'posts',
          'profile',
          'shell',
          'teams',
        ]) {
          shouldNotDependOn(
            filesMatching('features/$feature/**'),
            difference(
              filesMatching('features/*/data/**'),
              filesMatching('features/$feature/data/**'),
            ),
            graph,
          );
        }
      });
    });
  });
}
