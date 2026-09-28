import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/core/widgets/ck_push_nav.dart';

/// The four drawer-pushed "My …" screens share one nav. It had been
/// copy-pasted into two of them and re-invented in the other two, which is how
/// the titles ended up at three sizes with two different back buttons — so the
/// treatment is pinned here rather than left to each screen.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(theme: buildCirckTheme(), home: Scaffold(body: child)),
      );

  testWidgets('56pt bar, circular back, display-17 title', (tester) async {
    await pump(
      tester,
      CkPushNav(title: 'My Challenges', onBack: () {}),
    );

    expect(tester.getSize(find.byType(CkPushNav)).height, 56);

    final back = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(InkWell),
            matching: find.byType(Container),
          )
          .first,
    );
    final d = back.decoration! as BoxDecoration;
    expect(d.shape, BoxShape.circle);
    expect(d.color, CkColors.paper2);
    expect(tester.getSize(find.byType(InkWell).first), const Size(36, 36));

    expect(
      tester.widget<Text>(find.text('My Challenges')).style!.fontSize,
      17,
    );
  });

  testWidgets('back is wired', (tester) async {
    var backs = 0;
    await pump(tester, CkPushNav(title: 'X', onBack: () => backs++));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(backs, 1);
  });

  testWidgets('the trailing slot takes a create pill', (tester) async {
    var taps = 0;
    await pump(
      tester,
      CkPushNav(
        title: 'My Teams',
        onBack: () {},
        action: CkNavPill(label: 'Create', onTap: () => taps++),
      ),
    );

    expect(find.text('CREATE'), findsOneWidget);
    await tester.tap(find.text('CREATE'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('or a quiet count', (tester) async {
    await pump(
      tester,
      CkPushNav(
        title: 'My Challenges',
        onBack: () {},
        action: const CkNavCount('2 live'),
      ),
    );

    expect(find.text('2 LIVE'), findsOneWidget);
  });

  testWidgets('a long title ellipsises rather than overflowing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCirckTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: CkPushNav(
              title: 'My Extremely Long Screen Title That Will Not Fit',
              onBack: () {},
              action: CkNavPill(label: 'Create', onTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.textContaining('My Extremely'));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 1);
  });
}
