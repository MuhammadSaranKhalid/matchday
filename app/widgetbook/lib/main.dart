import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

import 'foundations/colors.dart';
import 'foundations/spacing.dart';
import 'foundations/typography.dart';
import 'patterns/bottom_sheet.dart';
import 'patterns/empty_state.dart';
import 'patterns/error_state.dart';
import 'patterns/headers.dart';
import 'patterns/segmented_control.dart';
import 'primitives/badge.dart';
import 'primitives/button.dart';
import 'primitives/chip.dart';
import 'primitives/icon_button.dart';
import 'primitives/search_field.dart';
import 'primitives/surface.dart';
import 'primitives/text_field.dart';

void main() {
  runApp(const MatchdayWidgetbookApp());
}

class MatchdayWidgetbookApp extends StatelessWidget {
  const MatchdayWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookCategory(
          name: 'Foundations',
          children: [
            buildColorsComponent(),
            buildTypographyComponent(),
            buildSpacingComponent(),
          ],
        ),
        WidgetbookCategory(
          name: 'Primitives',
          children: [
            buildButtonComponent(),
            buildIconButtonComponent(),
            buildBadgeComponent(),
            buildChipComponent(),
            buildTextFieldComponent(),
            buildSearchFieldComponent(),
            buildSurfaceComponent(),
          ],
        ),
        WidgetbookCategory(
          name: 'Patterns',
          children: [
            buildEmptyStateComponent(),
            buildErrorStateComponent(),
            buildBottomSheetComponent(),
            buildHeadersComponent(),
            buildSegmentedControlComponent(),
          ],
        ),
      ],
      addons: [
        ThemeAddon<ThemeData>(
          themes: [
            WidgetbookTheme(
              name: 'Light',
              data: AppTheme.light,
            ),
          ],
          themeBuilder: (context, theme, child) => Theme(
            data: theme,
            child: Scaffold(
              backgroundColor: Palette.paper,
              body: child,
            ),
          ),
        ),
      ],
    );
  }
}
