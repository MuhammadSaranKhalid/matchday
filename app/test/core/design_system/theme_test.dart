import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:matchday/core/theme/circk_theme.dart';

void main() {
  group('AppTheme and ThemeExtensions', () {
    test('buildAppTheme includes LayoutTokens and TextTokens', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, Palette.paper);

      final layout = theme.extension<LayoutTokens>();
      expect(layout, isNotNull);
      expect(layout!.screenGutter, Spacing.md);
      expect(layout.controlRadius, Radii.control);
      expect(layout.minimumTapTarget, Sizing.minimumTapTarget);

      final textTokens = theme.extension<TextTokens>();
      expect(textTokens, isNotNull);
      expect(textTokens!.metadata.fontFamily, 'JetBrains Mono');
      expect(textTokens.score.fontSize, 18);
    });

    test('buildCirckTheme delegates to buildAppTheme and preserves tokens', () {
      // ignore: deprecated_member_use_from_same_package
      final theme = buildCirckTheme();
      final layout = theme.extension<LayoutTokens>();
      expect(layout, isNotNull);
      expect(layout!.screenGutter, 16);

      // Verify CkColors compatibility facade
      expect(CkColors.ink, Palette.ink);
      expect(CkColors.red, Palette.red);
      expect(CkColors.paper, Palette.paper);

      // Verify CkRadii compatibility facade
      expect(CkRadii.md, Radii.md);
      expect(CkRadii.lg, Radii.lg);
    });

    test('LayoutTokens copyWith and lerp', () {
      const original = LayoutTokens.light;
      final modified = original.copyWith(screenGutter: 24);
      expect(modified.screenGutter, 24);
      expect(modified.screenBottom, original.screenBottom);

      final lerped = original.lerp(modified, 0.5);
      expect(lerped.screenGutter, 20);

      // Lerp with null returns this
      expect(original.lerp(null, 0.5), original);
    });

    test('TextTokens copyWith and lerp', () {
      const original = TextTokens.light;
      final modified = original.copyWith(
        score: const TextStyle(fontSize: 24),
      );
      expect(modified.score.fontSize, 24);
      expect(modified.metric, original.metric);

      final lerped = original.lerp(modified, 0.5);
      expect(lerped.score.fontSize, 21);

      // Lerp with null returns this
      expect(original.lerp(null, 0.5), original);
    });

    testWidgets('DesignSystemThemeContext extension retrieves tokens in widget tree',
        (tester) async {
      late LayoutTokens inspectedLayout;
      late TextTokens inspectedTextTokens;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              inspectedLayout = context.layout;
              inspectedTextTokens = context.textTokens;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(inspectedLayout.screenGutter, 16);
      expect(inspectedTextTokens.metadata.fontFamily, 'JetBrains Mono');
    });
  });
}
